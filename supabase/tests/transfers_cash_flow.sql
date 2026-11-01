-- pgTAP: record_transfer + void_transfer + account_balance + cash_flow_summary.
-- Langkah 12A. F5-01-A s.d. F5-04-A APPROVED 2026-11-01.

begin;
select plan(16);

-- ============ Fixtures ============
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','a@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"A"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','d@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"D"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now());

-- ============ Auth as owner ============
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- Grab seeded account ids
create temp table _acc as
select id, name from public.accounts
where business_id = 'a0000000-0000-0000-0000-000000000000';

-- ============ 1-3: functions exist ============
select has_function('public','record_transfer','record_transfer exists');
select has_function('public','void_transfer','void_transfer exists');
select has_function('public','account_balance','account_balance exists');

-- ============ 4: initial balance = 0 for all seeded accounts ============
select is(
  public.account_balance((select id from _acc where name = 'Kas Tunai')),
  0::bigint, 'initial balance = 0');

-- ============ 5-6: record income + expense ============
select public.record_transaction(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'income', 10000, 'Penjualan',
  p_account_id := (select id from _acc where name = 'Kas Tunai')
);

select public.record_transaction(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'expense', 3000, 'Bensin',
  p_account_id := (select id from _acc where name = 'Kas Tunai')
);

select is(
  public.account_balance((select id from _acc where name = 'Kas Tunai')),
  7000::bigint, 'balance after income - expense = 7000');

-- ============ 7-9: transfer ============
select lives_ok(
  $$select public.record_transfer(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from _acc where name = 'Kas Tunai'),
    (select id from _acc where name = 'Rekening Bank'),
    4000, p_description := 'pindah ke bank'
  )$$, 'transfer 4000 kas -> bank');

select is(
  public.account_balance((select id from _acc where name = 'Kas Tunai')),
  3000::bigint, 'kas balance after transfer = 3000');

select is(
  public.account_balance((select id from _acc where name = 'Rekening Bank')),
  4000::bigint, 'bank balance after transfer = 4000');

-- ============ 10: transfer same account ============
select throws_ok(
  $$select public.record_transfer(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from _acc where name = 'Kas Tunai'),
    (select id from _acc where name = 'Kas Tunai'),
    100, p_description := 'x'
  )$$, '22023','SAME_ACCOUNT','same account raises');

-- ============ 11: void transfer ============
select lives_ok(
  $$select public.void_transfer(
    (select id from public.transfers
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and status = 'confirmed' limit 1),
    'salah transfer'
  )$$, 'void transfer succeeds');

-- ============ 12-13: balances after void ============
select is(
  public.account_balance((select id from _acc where name = 'Kas Tunai')),
  7000::bigint, 'kas balance after void = 7000');

select is(
  public.account_balance((select id from _acc where name = 'Rekening Bank')),
  0::bigint, 'bank balance after void = 0');

-- ============ 14: void transfer twice ============
select throws_ok(
  $$select public.void_transfer(
    (select id from public.transfers
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and status = 'cancelled' limit 1),
    'again'
  )$$, '22023','ALREADY_CANCELLED','void twice raises');

-- ============ 15: account_balance as-of past date ============
-- (p_as_of = '2000-01-01' should return 0 — semua transaksi terjadi setelahnya)
select is(
  public.account_balance(
    (select id from _acc where name = 'Kas Tunai'),
    '2000-01-01'::date
  ),
  0::bigint, 'balance as-of 2000-01-01 = 0');

-- ============ 16-17: cash_flow_summary ============
-- income = 10000 (no payment recorded), expense = 3000, payments = 0
-- net = 10000 - 3000 + 0 = 7000
select is(
  (public.cash_flow_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date,
    current_date
  )->>'income')::bigint,
  10000::bigint, 'cash_flow.income = 10000');

select is(
  (public.cash_flow_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date,
    current_date
  )->>'net')::bigint,
  7000::bigint, 'cash_flow.net = 7000');

select * from finish();
rollback;

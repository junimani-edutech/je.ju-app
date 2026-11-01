-- pgTAP: record_transaction + void_transaction (Langkah 12A).
-- F5-01-A s.d. F5-04-A APPROVED 2026-11-01.

begin;
select plan(17);

-- ============ Fixtures ============
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','a@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"A"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','d@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"D"}'),
  ('00000000-0000-0000-0000-000000000000','e1111111-1111-1111-1111-111111111111','authenticated','authenticated','e@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"E"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','e1111111-1111-1111-1111-111111111111','viewer','active',now());

-- ============ 1-2: functions exist ============
select has_function('public','record_transaction','record_transaction exists');
select has_function('public','void_transaction','void_transaction exists');

-- ============ Auth as owner ============
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- ============ 3-4: record income happy path ============
select lives_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'income', 5000, 'Penjualan tunai'
  )$$, 'record income 5000');

select is(
  (select amount::bigint from public.transactions
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and type = 'income' and reversal_of_transaction_id is null limit 1),
  5000::bigint, 'income amount = 5000');

-- ============ 5: audit log ============
select is(
  (select count(*)::int from public.audit_logs
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and action = 'transaction.recorded'),
  1, 'audit log written for income');

-- ============ 6-7: idempotency ============
select lives_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'expense', 1000, 'Beli kopi',
    p_idempotency_key := 'exp-1'
  )$$, 'record expense with idempotency_key');

select lives_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'expense', 1000, 'Beli kopi',
    p_idempotency_key := 'exp-1'
  )$$, 'record expense again (idempotent)');

-- ============ 8: idempotent -> 1 row ============
select is(
  (select count(*)::int from public.transactions
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and idempotency_key = 'exp-1'),
  1, 'idempotent -> 1 row');

-- ============ 9: invalid type ============
select throws_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'other', 100, 'X'
  )$$, '22023','TYPE_INVALID','invalid type raises');

-- ============ 10: invalid amount ============
select throws_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'income', 0, 'X'
  )$$, '22023','AMOUNT_INVALID','amount=0 raises');

-- ============ 11: description required ============
select throws_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'income', 100, '   '
  )$$, '22023','DESCRIPTION_REQUIRED','blank description raises');

-- ============ 12: viewer cannot record ============
set local request.jwt.claim.sub = 'e1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"e1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'income', 100, 'X'
  )$$, '28000','NOT_A_MEMBER','viewer cannot record');

-- ============ 13: non-member cannot record ============
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.record_transaction(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'income', 100, 'X'
  )$$, '28000','NOT_A_MEMBER','non-member cannot record');

-- ============ 14-15: void income ============
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.void_transaction(
    (select id from public.transactions
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and type = 'income' and reversal_of_transaction_id is null limit 1),
    'salah input'
  )$$, 'void income succeeds');

select is(
  (select count(*)::int from public.transactions
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and reversal_of_transaction_id is not null),
  1, 'one reversal row created');

-- ============ 16: void twice ============
select throws_ok(
  $$select public.void_transaction(
    (select id from public.transactions
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and type = 'income' and reversal_of_transaction_id is null limit 1),
    'again'
  )$$, '22023','ALREADY_VOIDED','void twice raises');

-- ============ 17: void reversal ============
select throws_ok(
  $$select public.void_transaction(
    (select id from public.transactions
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and reversal_of_transaction_id is not null limit 1),
    'try'
  )$$, '22023','CANNOT_VOID_REVERSAL','void reversal raises');

select * from finish();
rollback;

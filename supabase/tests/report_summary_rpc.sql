-- pgTAP: report_summary (Langkah 13B).

begin;
select plan(13);

-- ============ Fixtures ============
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}'),
  ('00000000-0000-0000-0000-000000000000','e1111111-1111-1111-1111-111111111111','authenticated','authenticated','viewer@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Viewer"}'),
  ('00000000-0000-0000-0000-000000000000','f1111111-1111-1111-1111-111111111111','authenticated','authenticated','stranger@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Stranger"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','e1111111-1111-1111-1111-111111111111','viewer','active',now());

-- ============ 1: function exists ============
select has_function('public','report_summary','RPC report_summary exists');

-- ============ Auth as owner: seed data ============
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- 1 order total 10000
select public.create_order(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  null, current_date, null, null,
  0, 0, 0,
  '[{"description":"Item","quantity":1,"unit_price":10000,"discount_amount":0}]'::jsonb
);

-- 1 payment 5000
select public.record_payment(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  (select id from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  5000
);

-- 1 income 2000 + 1 expense 500
select public.record_transaction(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'income', 2000, 'extra income'
);
select public.record_transaction(
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'expense', 500, 'misc expense'
);

-- ============ 2: viewer can read ============
set local request.jwt.claim.sub = 'e1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"e1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )$$, 'viewer can call report_summary');

-- ============ 3: stranger rejected ============
set local request.jwt.claim.sub = 'f1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"f1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )$$, '28000','NOT_A_MEMBER','stranger rejected');

-- ============ Switch back to owner ============
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- ============ 4: empty future period ============
select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    '2099-01-01'::date,
    '2099-12-31'::date
  )->>'orders_count')::int,
  0, 'future period: orders_count = 0');

-- ============ 5-7: orders ============
select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'orders_count')::int,
  1, 'current period: orders_count = 1');

select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'orders_total')::bigint,
  10000::bigint, 'orders_total = 10000');

select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'payments_received')::bigint,
  5000::bigint, 'payments_received = 5000');

-- ============ 8-9: income/expense ============
select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'income')::bigint,
  2000::bigint, 'income = 2000');

select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'expense')::bigint,
  500::bigint, 'expense = 500');

-- ============ 10-11: payments_net + cash_flow_net ============
select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'payments_net')::bigint,
  5000::bigint, 'payments_net = 5000');

select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'cash_flow_net')::bigint,
  6500::bigint, 'cash_flow_net = 2000 - 500 + 5000 = 6500');

-- ============ 12: receivables_remaining ============
select is(
  (public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->>'receivables_remaining')::bigint,
  5000::bigint, 'receivables_remaining = 5000 (10000 - 5000)');

-- ============ 13: balance_by_account is array ============
select is(
  jsonb_typeof(public.report_summary(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    current_date, current_date
  )->'balance_by_account'),
  'array', 'balance_by_account is a JSON array');

select * from finish();
rollback;

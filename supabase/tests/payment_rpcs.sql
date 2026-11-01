-- pgTAP: record_payment + void_payment (Langkah 11A).
-- Q3-A, Q4-A, E-01-A, Q8-A approved 2026-11-01.

begin;
select plan(25);

-- ============================================================
-- Fixtures
-- ============================================================
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','a@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"A"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','b@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"B"}'),
  ('00000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','authenticated','authenticated','c@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"C"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','d@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"D"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A'),
  ('b0000000-0000-0000-0000-000000000000','Biz B');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','cashier','active',now()),
  ('a0000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','viewer','active',now()),
  ('b0000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','owner','active',now());

-- Create one order in Biz A: total 10000
insert into public.orders (
  business_id, order_number, order_date,
  subtotal_amount, discount_amount, additional_fee_amount, shipping_amount,
  total_amount, paid_amount, currency, payment_status, status, order_status_id
) select
  'a0000000-0000-0000-0000-000000000000',
  '20261101-001',
  current_date,
  10000, 0, 0, 0,
  10000, 0, 'IDR', 'unpaid', 'active',
  (select id from public.order_statuses
   where business_id = 'a0000000-0000-0000-0000-000000000000' and code = 'draft')
returning id;

-- ============================================================
-- 1-2: functions exist
-- ============================================================
select has_function('public','record_payment','RPC record_payment exists');
select has_function('public','void_payment','RPC void_payment exists');

-- ============================================================
-- 3-4: seed default payment data (Q8-A)
-- ============================================================
select is(
  (select count(*)::int from public.payment_methods
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  3, 'seed creates 3 payment_methods'
);
select is(
  (select count(*)::int from public.accounts
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  3, 'seed creates 3 accounts'
);

-- ============================================================
-- Set auth as user_a (owner biz_a)
-- ============================================================
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- ============================================================
-- 5: record 5000 happy path
-- ============================================================
select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    5000
  )$$,
  'record 5000 payment'
);

-- 6: paid_amount = 5000
select is(
  (select paid_amount::bigint from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  5000::bigint, 'paid_amount = 5000'
);

-- 7: payment_status = partial
select is(
  (select payment_status from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  'partial', 'payment_status = partial'
);

-- 8: record another 5000
select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    5000
  )$$,
  'record 5000 more'
);

-- 9: payment_status = paid
select is(
  (select payment_status from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  'paid', 'payment_status = paid'
);

-- 10: record 1000 overpay
select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    1000
  )$$,
  'record 1000 overpay'
);

-- 11: payment_status = overpaid
select is(
  (select payment_status from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  'overpaid', 'payment_status = overpaid'
);

-- ============================================================
-- 12-14: idempotency
-- ============================================================
select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    500,
    p_idempotency_key := 'key-1'
  )$$,
  'idempotency: first call'
);
select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    500,
    p_idempotency_key := 'key-1'
  )$$,
  'idempotency: second call'
);
select is(
  (select count(*)::int from public.payments
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and idempotency_key = 'key-1'),
  1, 'idempotency: only 1 payment row'
);

-- ============================================================
-- 15: cashier can record
-- ============================================================
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    100
  )$$,
  'cashier can record payment'
);

-- ============================================================
-- 16: viewer cannot record
-- ============================================================
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    100
  )$$,
  '28000','NOT_A_MEMBER',
  'viewer cannot record payment'
);

-- ============================================================
-- 17: non-member cannot record
-- ============================================================
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    100
  )$$,
  '28000','NOT_A_MEMBER',
  'non-member cannot record payment'
);

-- ============================================================
-- 18: invalid amount
-- ============================================================
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    0
  )$$,
  '22023','AMOUNT_INVALID','amount=0 raises AMOUNT_INVALID'
);

-- ============================================================
-- 19: invalid payment method
-- ============================================================
select throws_ok(
  $$select public.record_payment(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    (select id from public.orders where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
    100,
    p_payment_method_id := 'b0000000-0000-0000-0000-000000000000'::uuid
  )$$,
  '22023','PAYMENT_METHOD_INVALID','invalid payment_method_id raises'
);

-- ============================================================
-- 20: void happy path
-- ============================================================
select lives_ok(
  $$select public.void_payment(
    (select id from public.payments
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and idempotency_key = 'key-1' limit 1),
    'double entry'
  )$$,
  'void payment succeeds'
);

-- 21: paid_amount decreases
select is(
  (select paid_amount::bigint from public.orders
    where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  11100::bigint,
  'paid_amount after void = 11100'
);

-- 22: void twice -> ALREADY_VOIDED
select throws_ok(
  $$select public.void_payment(
    (select id from public.payments
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and idempotency_key = 'key-1' limit 1),
    'again'
  )$$,
  '22023','ALREADY_VOIDED','void twice raises ALREADY_VOIDED'
);

-- 23: void a reversal -> CANNOT_VOID_REVERSAL
select throws_ok(
  $$select public.void_payment(
    (select id from public.payments
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and reversal_of_payment_id is not null limit 1),
    'try to reverse a reversal'
  )$$,
  '22023','CANNOT_VOID_REVERSAL','void reversal raises CANNOT_VOID_REVERSAL'
);

-- 24: void with no reason -> REASON_REQUIRED
select throws_ok(
  $$select public.void_payment(
    (select id from public.payments
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and idempotency_key is null
        and reversal_of_payment_id is null limit 1),
    ''
  )$$,
  '22023','REASON_REQUIRED','void without reason raises REASON_REQUIRED'
);

-- 25: void by viewer -> NOT_A_MEMBER
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.void_payment(
    (select id from public.payments
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and idempotency_key is null
        and reversal_of_payment_id is null limit 1),
    'viewer attempt'
  )$$,
  '28000','NOT_A_MEMBER','viewer cannot void payment'
);

select * from finish();
rollback;

-- pgTAP: upsert_order_with_items + upsert_payment (offline sync RPCs).
-- Langkah 15C-2b.

begin;
select plan(15);

-- ============ Fixtures ============
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','viewer@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Viewer"}'),
  ('00000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','authenticated','authenticated','stranger@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Stranger"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','viewer','active',now());

-- ============ 1-2: functions exist ============
select has_function('public','upsert_order_with_items','upsert_order_with_items exists');
select has_function('public','upsert_payment','upsert_payment exists');

-- ============ Auth as owner ============
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

-- Test 3: create order dengan ID + order_number klien
select lives_ok(
  $$select public.upsert_order_with_items(
    p_id := '11110000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_number := 'OFFLINE-001',
    p_items := '[{"description":"Item A","quantity":1,"unit_price":5000,"discount_amount":0}]'::jsonb
  )$$, 'create offline order');

-- Test 4: order_number persis
select is(
  (select order_number from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  'OFFLINE-001', 'order_number preserved');

-- Test 5: total_amount = 5000
select is(
  (select total_amount::bigint from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  5000::bigint, 'total_amount = 5000');

-- Test 6: upsert dengan 2 item -> total 10000
select lives_ok(
  $$select public.upsert_order_with_items(
    p_id := '11110000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_number := 'OFFLINE-001',
    p_items := '[
      {"description":"Item A","quantity":1,"unit_price":5000,"discount_amount":0},
      {"description":"Item B","quantity":1,"unit_price":5000,"discount_amount":0}
    ]'::jsonb
  )$$, 'upsert order with 2 items');

-- Test 7: total = 10000
select is(
  (select total_amount::bigint from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  10000::bigint, 'total_amount after upsert = 10000');

-- Test 8: items = 2 (bukan 3 — replace, bukan append)
select is(
  (select count(*)::int from public.order_items
   where order_id = '11110000-0000-0000-0000-000000000001'),
  2, 'items count = 2 (replaced)');

-- Test 9: catat payment 5000
select lives_ok(
  $$select public.upsert_payment(
    p_id := '22220000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_id := '11110000-0000-0000-0000-000000000001'::uuid,
    p_amount := 5000
  )$$, 'record payment 5000');

-- Test 10: paid_amount = 5000
select is(
  (select paid_amount::bigint from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  5000::bigint, 'paid_amount = 5000');

-- Test 11: payment_status = partial
select is(
  (select payment_status from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  'partial', 'payment_status = partial');

-- Test 12: upsert payment lagi (idempoten, amount sama)
select lives_ok(
  $$select public.upsert_payment(
    p_id := '22220000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_id := '11110000-0000-0000-0000-000000000001'::uuid,
    p_amount := 5000
  )$$, 'upsert_payment idempotent');

select is(
  (select paid_amount::bigint from public.orders where id = '11110000-0000-0000-0000-000000000001'),
  5000::bigint, 'paid_amount still 5000 after idempotent upsert');

-- Test 13: viewer tidak boleh upsert_order
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated","email":"viewer@t.local"}';

select throws_ok(
  $$select public.upsert_order_with_items(
    p_id := '99990000-0000-0000-0000-000000000099'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_number := 'OFFLINE-VIEWER',
    p_items := '[{"description":"X","quantity":1,"unit_price":1000,"discount_amount":0}]'::jsonb
  )$$, '28000','NOT_A_MEMBER','viewer cannot upsert order');

-- Test 14: stranger tidak boleh upsert_payment
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated","email":"stranger@t.local"}';

select throws_ok(
  $$select public.upsert_payment(
    p_id := '99990000-0000-0000-0000-000000000098'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_order_id := '11110000-0000-0000-0000-000000000001'::uuid,
    p_amount := 1000
  )$$, '28000','NOT_A_MEMBER','stranger cannot upsert payment');

select * from finish();
rollback;

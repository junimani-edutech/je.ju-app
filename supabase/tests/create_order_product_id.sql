-- pgTAP: create_order + upsert_order_with_items dengan product_id.
-- Fase 12.1.

begin;
select plan(6);

-- Fixtures
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A'),
  ('b0000000-0000-0000-0000-000000000000','Biz B');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now());

insert into public.products (id, business_id, name, price) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc','a0000000-0000-0000-0000-000000000000','Kopi',15000),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd','b0000000-0000-0000-0000-000000000000','Teh',10000);

set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

-- 1: create_order dengan product_id valid
select lives_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"Kopi","quantity":1,"unit_price":15000,"discount_amount":0,"product_id":"cccccccc-cccc-cccc-cccc-cccccccccccc"}]'::jsonb
  )$$, 'create_order with product_id'
);

-- 2: product_id tersimpan di order_items
select is(
  (select product_id from public.order_items
   where business_id = 'a0000000-0000-0000-0000-000000000000' limit 1),
  'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
  'product_id saved via create_order'
);

-- 3: cross-business product_id ditolak
select throws_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"Teh","quantity":1,"unit_price":10000,"discount_amount":0,"product_id":"dddddddd-dddd-dddd-dddd-dddddddddddd"}]'::jsonb
  )$$, '22023','PRODUCT_INVALID','reject cross-business product_id'
);

-- 4: backward compat — tanpa product_id tetap jalan
select lives_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"Manual","quantity":1,"unit_price":5000,"discount_amount":0}]'::jsonb
  )$$, 'create_order without product_id still works'
);

-- 5: upsert_order_with_items dengan product_id
select lives_ok(
  $$select public.upsert_order_with_items(
    '11110000-0000-0000-0000-000000000001'::uuid,
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'OFFLINE-001',
    p_items := '[{"description":"Kopi","quantity":1,"unit_price":15000,"discount_amount":0,"product_id":"cccccccc-cccc-cccc-cccc-cccccccccccc"}]'::jsonb
  )$$, 'upsert_order_with_items with product_id'
);

-- 6: product_id tersimpan via upsert
select is(
  (select product_id from public.order_items
   where order_id = '11110000-0000-0000-0000-000000000001' limit 1),
  'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
  'product_id saved via upsert_order_with_items'
);

select * from finish();
rollback;

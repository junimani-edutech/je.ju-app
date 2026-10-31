-- pgTAP: create_order RPC (Langkah 10A, Q5-A).

begin;
select plan(11);

-- ============================================================
-- Fixtures
-- ============================================================
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000', 'a1111111-1111-1111-1111-111111111111', 'authenticated','authenticated','a@t.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User A"}'),
  ('00000000-0000-0000-0000-000000000000', 'b1111111-1111-1111-1111-111111111111', 'authenticated','authenticated','b@t.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User B"}'),
  ('00000000-0000-0000-0000-000000000000', 'c1111111-1111-1111-1111-111111111111', 'authenticated','authenticated','c@t.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User C"}'),
  ('00000000-0000-0000-0000-000000000000', 'd1111111-1111-1111-1111-111111111111', 'authenticated','authenticated','d@t.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User D"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000', 'Biz A'),
  ('b0000000-0000-0000-0000-000000000000', 'Biz B');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000', 'a1111111-1111-1111-1111-111111111111', 'owner',  'active', now()),
  ('b0000000-0000-0000-0000-000000000000', 'b1111111-1111-1111-1111-111111111111', 'owner',  'active', now()),
  ('a0000000-0000-0000-0000-000000000000', 'd1111111-1111-1111-1111-111111111111', 'viewer', 'active', now());

-- 1
select has_function('public', 'create_order', 'RPC create_order exists');

-- 2
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, 'first',
    0, 0, 0,
    '[{"description":"Item 1","quantity":2,"unit_price":10000,"discount_amount":0}]'::jsonb
  )$$,
  'user_a creates first order'
);

-- 3
select is(
  (select order_number from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000'
   order by created_at asc limit 1),
  to_char(current_date, 'YYYYMMDD') || '-001',
  'first order_number is YYYYMMDD-001'
);

-- 4
select is(
  (select total_amount::bigint from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000'
   order by created_at asc limit 1),
  20000::bigint,
  'total_amount = 20000'
);

-- 5
select lives_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"Item 2","quantity":1,"unit_price":5000,"discount_amount":0}]'::jsonb
  )$$,
  'user_a creates second order'
);

-- 6
select is(
  (select array_agg(order_number order by order_number)
   from public.orders
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  array[
    to_char(current_date, 'YYYYMMDD') || '-001',
    to_char(current_date, 'YYYYMMDD') || '-002'
  ],
  'biz_a has exactly -001 and -002'
);

-- 7
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.create_order(
    'b0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"Item B","quantity":1,"unit_price":1000,"discount_amount":0}]'::jsonb
  )$$,
  'user_b creates first order in biz_b'
);

-- 8
select is(
  (select order_number from public.orders
   where business_id = 'b0000000-0000-0000-0000-000000000000' limit 1),
  to_char(current_date, 'YYYYMMDD') || '-001',
  'biz_b first order_number is 001'
);

-- 9
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"X","quantity":1,"unit_price":1,"discount_amount":0}]'::jsonb
  )$$,
  '28000', 'NOT_A_MEMBER',
  'user_c (no membership) cannot create order'
);

-- 10
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[{"description":"X","quantity":1,"unit_price":1,"discount_amount":0}]'::jsonb
  )$$,
  '28000', 'NOT_A_MEMBER',
  'viewer cannot create order'
);

-- 11
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, null,
    0, 0, 0,
    '[]'::jsonb
  )$$,
  '22023', 'ITEMS_REQUIRED',
  'empty items raises ITEMS_REQUIRED'
);

select * from finish();
rollback;

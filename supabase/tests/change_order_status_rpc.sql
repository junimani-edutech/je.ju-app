-- pgTAP: change_order_status + cancel_order RPC (Langkah 10B-1).

begin;
select plan(12);

-- ============================================================
-- Fixtures
-- ============================================================
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','a@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"A"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','b@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"B"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','d@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"D"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000', 'Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','viewer','active',now());

-- 1
select has_function('public','change_order_status','RPC change_order_status exists');
-- 2
select has_function('public','cancel_order','RPC cancel_order exists');

-- ============================================================
-- Create an order as user_a
-- ============================================================
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.create_order(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    null, current_date, null, 'order for status test',
    0, 0, 0,
    '[{"description":"X","quantity":1,"unit_price":1000,"discount_amount":0}]'::jsonb
  )$$,
  'user_a creates order'
);

-- 3
select lives_ok(
  $$select public.change_order_status(
    (select id from public.orders
      where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
    (select id from public.order_statuses
      where business_id='a0000000-0000-0000-0000-000000000000' and code='process' limit 1),
    'mulai proses'
  )$$,
  'change_order_status to process succeeds'
);

-- 4
select is(
  (select count(*)::int from public.order_status_history),
  1,
  'one history row created'
);

-- 5
select is(
  (select string_agg(
            coalesce(fs.code,'-') || '->' || coalesce(ts.code,'-'),
            ',' order by h.changed_at)
   from public.order_status_history h
   left join public.order_statuses fs on fs.id = h.from_status_id
   left join public.order_statuses ts on ts.id = h.to_status_id),
  'draft->process',
  'history shows draft->process'
);

-- 6
select throws_ok(
  $$select public.change_order_status(
    (select id from public.orders
      where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
    (select id from public.order_statuses
      where business_id='a0000000-0000-0000-0000-000000000000' and code='cancelled' limit 1),
    null
  )$$,
  '22023','USE_CANCEL_ORDER',
  'change to cancelled rejected'
);

-- ============================================================
-- cancel_order: happy path
-- ============================================================
select lives_ok(
  $$select public.cancel_order(
    (select id from public.orders
      where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
    'pelanggan batal'
  )$$,
  'cancel_order succeeds'
);

-- 7
select is(
  (select status from public.orders
    where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
  'cancelled',
  'order status = cancelled'
);

-- 8
select is(
  (select cancel_reason from public.orders
    where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
  'pelanggan batal',
  'cancel_reason recorded'
);

-- 9
select throws_ok(
  $$select public.cancel_order(
    (select id from public.orders
      where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
    null
  )$$,
  '22023','ALREADY_CANCELLED',
  'cancel on already cancelled rejects'
);

-- ============================================================
-- viewer cannot change / cancel
-- ============================================================
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- 10
select throws_ok(
  $$select public.change_order_status(
    (select id from public.orders
      where business_id='a0000000-0000-0000-0000-000000000000' limit 1),
    (select id from public.order_statuses
      where business_id='a0000000-0000-0000-0000-000000000000' and code='done' limit 1),
    null
  )$$,
  '28000','NOT_A_MEMBER',
  'viewer cannot change status'
);

select * from finish();
rollback;

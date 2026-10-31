-- pgTAP: default order_statuses seeding (Q1 APPROVED).

begin;
select plan(6);

-- Test 1: insert business -> trigger fires.
insert into public.businesses (id, name) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Biz C');

select is(
  (select count(*)::int from public.order_statuses
   where business_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  4,
  'trigger seeds 4 statuses'
);

select is(
  (select string_agg(code, ',' order by sort_order)
   from public.order_statuses
   where business_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  'draft,process,done,cancelled',
  'codes are draft,process,done,cancelled in sort_order'
);

select is(
  (select count(*)::int from public.order_statuses
   where business_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
     and is_final = true),
  2,
  'exactly 2 final statuses (done, cancelled)'
);

select is(
  (select name from public.order_statuses
   where business_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
     and code = 'done'),
  'Selesai',
  'done status has name Selesai'
);

-- Test 5: insert kedua business -> dapat 4 statuses sendiri.
insert into public.businesses (id, name) values
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Biz D');

select is(
  (select count(*)::int from public.order_statuses
   where business_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  4,
  'second business also gets 4 statuses'
);

-- Test 6: unique (business_id, code) tetap terjaga.
select throws_ok(
  $$insert into public.order_statuses (business_id, name, code, sort_order, is_final)
    values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Dup Draft', 'draft', 0, false)$$,
  '23505',
  null,
  'duplicate code per business rejected by unique constraint'
);

select * from finish();
rollback;

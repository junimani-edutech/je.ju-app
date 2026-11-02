-- pgTAP: upsert_transaction + upsert_transfer (offline sync RPCs).
-- Langkah 15C-3b.

begin;
select plan(11);

insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','viewer@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Viewer"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','viewer','active',now());

select has_function('public','upsert_transaction','upsert_transaction exists');
select has_function('public','upsert_transfer','upsert_transfer exists');

set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

-- Test 3: upsert income transaction 5000
select lives_ok(
  $$select public.upsert_transaction(
    p_id := '31000000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_type := 'income',
    p_amount := 5000,
    p_description := 'Penjualan offline'
  )$$, 'upsert income transaction 5000');

-- Test 4: count = 1
select is(
  (select count(*)::int from public.transactions
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  1, 'transaction count = 1');

-- Test 5: upsert again (idempoten)
select lives_ok(
  $$select public.upsert_transaction(
    p_id := '31000000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_type := 'income',
    p_amount := 5000,
    p_description := 'Penjualan offline'
  )$$, 'upsert income idempotent');

select is(
  (select count(*)::int from public.transactions
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  1, 'transaction count still 1');

-- Test 6: upsert transfer 3000 kas->bank (akun dari seed Q8-A)
select lives_ok(
  $$select public.upsert_transfer(
    p_id := '41000000-0000-0000-0000-000000000001'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_from_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Kas Tunai' limit 1),
    p_to_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Rekening Bank' limit 1),
    p_amount := 3000,
    p_description := 'pindah ke bank'
  )$$, 'upsert transfer 3000');

-- Test 7: transfer count = 1
select is(
  (select count(*)::int from public.transfers
   where business_id = 'a0000000-0000-0000-0000-000000000000'),
  1, 'transfer count = 1');

-- Test 8: same account raises
select throws_ok(
  $$select public.upsert_transfer(
    p_id := '41000000-0000-0000-0000-000000000002'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_from_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Kas Tunai' limit 1),
    p_to_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Kas Tunai' limit 1),
    p_amount := 1000
  )$$, '22023','SAME_ACCOUNT','same account rejected');

-- Test 9: viewer cannot upsert_transaction
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated","email":"viewer@t.local"}';

select throws_ok(
  $$select public.upsert_transaction(
    p_id := '31000000-0000-0000-0000-000000000099'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_type := 'income',
    p_amount := 1000,
    p_description := 'viewer attempt'
  )$$, '28000','NOT_A_MEMBER','viewer cannot upsert transaction');

-- Test 10: viewer cannot upsert_transfer
select throws_ok(
  $$select public.upsert_transfer(
    p_id := '41000000-0000-0000-0000-000000000099'::uuid,
    p_business_id := 'a0000000-0000-0000-0000-000000000000'::uuid,
    p_from_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Kas Tunai' limit 1),
    p_to_account_id := (select id from public.accounts
      where business_id = 'a0000000-0000-0000-0000-000000000000'
        and name = 'Rekening Bank' limit 1),
    p_amount := 1000
  )$$, '28000','NOT_A_MEMBER','viewer cannot upsert transfer');

select * from finish();
rollback;

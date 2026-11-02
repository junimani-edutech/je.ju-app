-- pgTAP: invitations RPC (Langkah 14A-4).
begin;
select plan(18);

insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','admin@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Admin"}'),
  ('00000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','authenticated','authenticated','cashier@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Cashier"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','stranger@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Stranger"}'),
  ('00000000-0000-0000-0000-000000000000','e1111111-1111-1111-1111-111111111111','authenticated','authenticated','newuser@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Newuser"}'),
  ('00000000-0000-0000-0000-000000000000','f1111111-1111-1111-1111-111111111111','authenticated','authenticated','another@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Another"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','admin','active',now()),
  ('a0000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','cashier','active',now());

select has_function('public','create_invitation','create_invitation exists');
select has_function('public','revoke_invitation','revoke_invitation exists');
select has_function('public','accept_invitation','accept_invitation exists');
select has_function('public','list_business_members','list_business_members exists');

-- Test 5: stranger cannot create
set local role authenticated;
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'stranger@t.local';
set local request.jwt.claims = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated","email":"stranger@t.local"}';

select throws_ok(
  $$select public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'x@t.local', 'viewer')$$,
  '28000','NOT_A_MEMBER','stranger cannot create');

-- Test 6: owner cannot invite self
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'owner@t.local';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

select throws_ok(
  $$select public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'owner@t.local', 'viewer')$$,
  '22023','CANNOT_INVITE_SELF','owner cannot invite self');

-- Test 7: existing member rejected
select throws_ok(
  $$select public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'admin@t.local', 'viewer')$$,
  '22023','EMAIL_ALREADY_MEMBER','existing member rejected');

-- Test 8: cashier cannot create
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'cashier@t.local';
set local request.jwt.claims = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated","email":"cashier@t.local"}';

select throws_ok(
  $$select public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'x@t.local', 'viewer')$$,
  '28000','NOT_AUTHORIZED','cashier cannot create');

-- Test 9: admin cannot create admin
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'admin@t.local';
set local request.jwt.claims = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated","email":"admin@t.local"}';

select throws_ok(
  $$select public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'x@t.local', 'admin')$$,
  '22023','ROLE_NOT_ALLOWED','admin cannot create admin');

-- Test 10: owner creates for newuser (viewer) - happy
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'owner@t.local';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

select is(
  (select count(*)::int from public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'newuser@t.local', 'viewer')),
  1, 'owner creates invitation');

-- Capture token for later tests
create temp table _tok as
  select token from public.business_invitations
  where business_id = 'a0000000-0000-0000-0000-000000000000'
    and lower(email) = 'newuser@t.local';

-- Test 11: idempotent - same email returns same token
select is(
  (select token from public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'newuser@t.local', 'viewer')),
  (select token from _tok limit 1),
  'create twice returns same token');

-- Test 12: owner creates for another (cashier)
select is(
  (select count(*)::int from public.create_invitation('a0000000-0000-0000-0000-000000000000'::uuid, 'another@t.local', 'cashier')),
  1, 'owner creates second invitation');

-- Test 13: owner revokes second invitation - happy
select lives_ok(
  $$select public.revoke_invitation(
    (select id from public.business_invitations
     where business_id = 'a0000000-0000-0000-0000-000000000000'
       and lower(email) = 'another@t.local' limit 1))$$,
  'owner revokes invitation');

-- Test 14: revoke again -> INVITATION_NOT_PENDING
select throws_ok(
  $$select public.revoke_invitation(
    (select id from public.business_invitations
     where business_id = 'a0000000-0000-0000-0000-000000000000'
       and lower(email) = 'another@t.local' limit 1))$$,
  '22023','INVITATION_NOT_PENDING','revoke non-pending fails');

-- Test 15: wrong email cannot accept (stranger tries)
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'stranger@t.local';
set local request.jwt.claims = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated","email":"stranger@t.local"}';

select throws_ok(
  $$select public.accept_invitation((select token from _tok limit 1))$$,
  '28000','EMAIL_MISMATCH','wrong email cannot accept');

-- Test 16: newuser accepts - happy
set local request.jwt.claim.sub = 'e1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'newuser@t.local';
set local request.jwt.claims = '{"sub":"e1111111-1111-1111-1111-111111111111","role":"authenticated","email":"newuser@t.local"}';

select is(
  public.accept_invitation((select token from _tok limit 1)),
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'newuser accepts invitation');

-- Test 17: accept again - idempotent
select is(
  public.accept_invitation((select token from _tok limit 1)),
  'a0000000-0000-0000-0000-000000000000'::uuid,
  'accept twice returns same biz');

-- Test 18: owner lists members
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claim.email = 'owner@t.local';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated","email":"owner@t.local"}';

select is(
  (select count(*)::int from public.list_business_members('a0000000-0000-0000-0000-000000000000'::uuid)),
  4, 'list_business_members returns 4 members');

select * from finish();
rollback;

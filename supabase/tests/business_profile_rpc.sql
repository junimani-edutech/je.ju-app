-- pgTAP: update_business_profile (Langkah 13A).

begin;
select plan(13);

-- ============ Fixtures ============
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','authenticated','authenticated','owner@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Owner"}'),
  ('00000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','authenticated','authenticated','admin@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Admin"}'),
  ('00000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','authenticated','authenticated','viewer@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Viewer"}'),
  ('00000000-0000-0000-0000-000000000000','d1111111-1111-1111-1111-111111111111','authenticated','authenticated','stranger@t.local',now(),now(),now(),'{"provider":"email"}','{"full_name":"Stranger"}');

insert into public.businesses (id, name) values
  ('a0000000-0000-0000-0000-000000000000','Biz A');

insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('a0000000-0000-0000-0000-000000000000','a1111111-1111-1111-1111-111111111111','owner','active',now()),
  ('a0000000-0000-0000-0000-000000000000','b1111111-1111-1111-1111-111111111111','admin','active',now()),
  ('a0000000-0000-0000-0000-000000000000','c1111111-1111-1111-1111-111111111111','viewer','active',now());

-- ============ 1-2: function exists ============
select has_function('public','update_business_profile','RPC exists');

set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- ============ 2: owner can update basic profile ============
select lives_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'Toko Baru',
    'Toko Baru CV',
    'owner@example.com',
    '+6281234567890',
    'Jl. Merdeka No.1',
    'Asia/Makassar'
  )$$, 'owner can update profile');

-- ============ 3-7: fields persisted ============
select is((select name from public.businesses where id = 'a0000000-0000-0000-0000-000000000000'),
  'Toko Baru', 'name updated');
select is((select legal_name from public.businesses where id = 'a0000000-0000-0000-0000-000000000000'),
  'Toko Baru CV', 'legal_name updated');
select is((select contact_email from public.businesses where id = 'a0000000-0000-0000-0000-000000000000'),
  'owner@example.com', 'contact_email updated');
select is((select address from public.businesses where id = 'a0000000-0000-0000-0000-000000000000'),
  'Jl. Merdeka No.1', 'address updated');
select is((select timezone from public.businesses where id = 'a0000000-0000-0000-0000-000000000000'),
  'Asia/Makassar', 'timezone updated');

-- ============ 8: empty name rejected ============
select throws_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    '', null, null, null, null, 'Asia/Jakarta'
  )$$, '22023','NAME_REQUIRED','empty name rejected');

-- ============ 9: empty timezone rejected ============
select throws_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'X', null, null, null, null, ''
  )$$, '22023','TIMEZONE_REQUIRED','empty timezone rejected');

-- ============ 10: admin can update ============
set local request.jwt.claim.sub = 'b1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"b1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'Toko Admin', null, null, null, null, 'Asia/Jakarta'
  )$$, 'admin can update profile');

-- ============ 11: viewer rejected ============
set local request.jwt.claim.sub = 'c1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"c1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'Hack', null, null, null, null, 'Asia/Jakarta'
  )$$, '28000','NOT_A_MEMBER','viewer cannot update');

-- ============ 12: non-member rejected ============
set local request.jwt.claim.sub = 'd1111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"d1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$select public.update_business_profile(
    'a0000000-0000-0000-0000-000000000000'::uuid,
    'Hack', null, null, null, null, 'Asia/Jakarta'
  )$$, '28000','NOT_A_MEMBER','stranger cannot update');

-- ============ 13: audit log written ============
-- Reset role agar RLS pada audit_logs (hanya owner/admin yang bisa select)
-- tidak memblokir query dari test user stranger.
reset role;
set local request.jwt.claim.sub = '';
set local request.jwt.claims    = '{}';

select is(
  (select count(*)::int from public.audit_logs
   where business_id = 'a0000000-0000-0000-0000-000000000000'
     and action = 'business.profile_updated'),
  2, 'two profile_updated audit logs written');

select * from finish();
rollback;

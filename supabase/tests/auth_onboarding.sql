-- pgTAP: auth & onboarding (Fase 1 / Langkah 7A)
-- Self-contained, diakhiri rollback.

begin;

select plan(17);

-- ============================================================
-- 1. Struktur
-- ============================================================
select has_function('public', 'handle_new_user', 'trigger function handle_new_user exists');
select has_function('public', 'create_business_with_owner', 'RPC create_business_with_owner exists');
select has_trigger('auth', 'users', 'on_auth_user_created', 'trigger on_auth_user_created exists on auth.users');

-- ============================================================
-- 2. Trigger profil: signup user_a
-- ============================================================
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111111',
  'authenticated', 'authenticated', 'user_a@test.local', now(),
  now(), now(),
  '{"provider":"email"}',
  '{"full_name":"User A"}'
);

select is(
  (select count(*)::int from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  1,
  'trigger creates profile row for new user'
);

select is(
  (select full_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'User A',
  'profile.full_name extracted from raw_user_meta_data'
);

-- ============================================================
-- 3. RPC: user_a membuat business
-- ============================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$select public.create_business_with_owner('Toko A', 'Asia/Jakarta')$$,
  'user_a can call create_business_with_owner'
);

select is(
  (select count(*)::int from public.businesses),
  1,
  'user_a sees their 1 business after RPC'
);

select is(
  (select name from public.businesses limit 1),
  'Toko A',
  'business name matches input'
);

select is(
  (select currency from public.businesses limit 1),
  'IDR',
  'currency is IDR (D-07)'
);

select is(
  (select count(*)::int from public.business_members),
  1,
  'exactly 1 member row created'
);

select is(
  (select role::text from public.business_members limit 1),
  'owner',
  'creator is owner'
);

select is(
  (select user_id::text from public.business_members limit 1),
  '11111111-1111-1111-1111-111111111111',
  'member user_id matches creator'
);

-- ============================================================
-- 4. Validasi RPC
-- ============================================================
select throws_ok(
  $$select public.create_business_with_owner('', 'Asia/Jakarta')$$,
  '22023', 'NAME_REQUIRED',
  'empty name raises NAME_REQUIRED'
);

select throws_ok(
  $$select public.create_business_with_owner('X', '')$$,
  '22023', 'TIMEZONE_REQUIRED',
  'empty timezone raises TIMEZONE_REQUIRED'
);

-- ============================================================
-- 5. Multi-business (D-01): user_a bisa buat bisnis kedua
-- ============================================================
select lives_ok(
  $$select public.create_business_with_owner('Toko A2', 'Asia/Makassar')$$,
  'user_a can create second business (D-01 multi-business)'
);

select is(
  (select count(*)::int from public.businesses),
  2,
  'user_a now sees 2 businesses'
);

-- ============================================================
-- 6. Simulasi tidak login → RPC harus raise NOT_AUTHENTICATED
-- ============================================================
reset role;
set local request.jwt.claim.sub = '';
set local request.jwt.claims = '{}';

select throws_ok(
  $$select public.create_business_with_owner('X', 'Asia/Jakarta')$$,
  '28000', 'NOT_AUTHENTICATED',
  'create_business_with_owner raises NOT_AUTHENTICATED when no jwt'
);

select * from finish();
rollback;

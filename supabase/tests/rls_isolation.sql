-- pgTAP RLS isolation test (Fase 1 / Langkah 6)
-- Self-contained: fixtures dibuat di dalam transaksi tes, rollback di akhir.
-- Tujuan: membuktikan user tanpa keanggotaan tidak bisa membaca/menulis data business lain.

begin;

select plan(13);

-- ============================================================
-- FIXTURES (rolled back di akhir)
-- ============================================================

-- Test users di auth.users.
-- Kolom `confirmed_at` adalah generated column — JANGAN di-insert.
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'user_a@test.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User A"}'),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'user_b@test.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User B"}'),
  ('00000000-0000-0000-0000-000000000000', '33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'user_c@test.local', now(), now(), now(), '{"provider":"email"}', '{"full_name":"User C"}')
on conflict (id) do nothing;

-- Profil (tidak ada trigger otomatis di migration kita, jadi manual)
insert into public.profiles (id, full_name) values
  ('11111111-1111-1111-1111-111111111111', 'User A'),
  ('22222222-2222-2222-2222-222222222222', 'User B'),
  ('33333333-3333-3333-3333-333333333333', 'User C')
on conflict (id) do nothing;

-- Businesses
insert into public.businesses (id, name) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Biz A'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Biz B')
on conflict (id) do nothing;

-- Membership: user_a → Biz A, user_b → Biz B. user_c → tidak jadi member apa pun.
insert into public.business_members (business_id, user_id, role, status, joined_at) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'owner', 'active', now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'owner', 'active', now())
on conflict do nothing;

-- Customers (satu per bisnis, untuk uji isolasi)
insert into public.customers (id, business_id, name) values
  ('c0000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Customer A'),
  ('c0000002-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Customer B')
on conflict (id) do nothing;

-- ============================================================
-- TES STRUKTUR
-- ============================================================
select has_table('public', 'businesses', 'table businesses exists');
select has_table('public', 'customers',  'table customers exists');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.customers'::regclass),
  'RLS enabled on customers'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.businesses'::regclass),
  'RLS enabled on businesses'
);

-- ============================================================
-- TES ISOLASI — sebagai user_a
-- ============================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (select count(*)::int from public.businesses),
  1,
  'User A sees exactly 1 business (their own)'
);

select is(
  (select count(*)::int from public.customers),
  1,
  'User A sees exactly 1 customer (their own)'
);

-- ============================================================
-- TES ISOLASI — sebagai user_b
-- ============================================================
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims    = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is(
  (select count(*)::int from public.businesses),
  1,
  'User B sees exactly 1 business (their own)'
);

-- ============================================================
-- TES ISOLASI — sebagai user_c (tanpa keanggotaan)
-- ============================================================
set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
set local request.jwt.claims    = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';

select is(
  (select count(*)::int from public.businesses),
  0,
  'User C (no membership) sees 0 businesses'
);

select is(
  (select count(*)::int from public.customers),
  0,
  'User C (no membership) sees 0 customers'
);

-- ============================================================
-- TES WRITE — user_a mencoba insert ke Biz B
-- ============================================================
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok(
  $$insert into public.customers (business_id, name)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Hacked')$$,
  '42501',
  null,
  'User A cannot insert customer into biz_b (RLS violation)'
);


-- ============================================================
-- TES UPDATE / DELETE ISOLATION — user_a mencoba menyentuh biz_b
-- ============================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims    = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- Percobaan update customer biz_b (bukan milik user_a). RLS menolak → 0 rows.
update public.customers
   set name = 'Hacked A'
 where id = 'c0000002-0000-0000-0000-000000000002';

-- Percobaan delete customer biz_b. RLS menolak → 0 rows.
delete from public.customers
 where id = 'c0000002-0000-0000-0000-000000000002';

-- Update customer milik user_a sendiri (harus berhasil).
update public.customers
   set name = 'Customer A Updated'
 where id = 'c0000001-0000-0000-0000-000000000001';

-- Verifikasi sebagai postgres (bypass RLS) agar bisa membaca kedua baris.
reset role;
set local request.jwt.claim.sub = '';
set local request.jwt.claims    = '{}';

select is(
  (select name from public.customers
   where id = 'c0000002-0000-0000-0000-000000000002'),
  'Customer B',
  'User A update on biz_b customer has no effect (RLS blocked)'
);

select is(
  (select count(*)::int from public.customers
   where id = 'c0000002-0000-0000-0000-000000000002'),
  1,
  'User A delete on biz_b customer has no effect (row still exists)'
);

select is(
  (select name from public.customers
   where id = 'c0000001-0000-0000-0000-000000000001'),
  'Customer A Updated',
  'User A can update own customer'
);

select * from finish();

rollback;

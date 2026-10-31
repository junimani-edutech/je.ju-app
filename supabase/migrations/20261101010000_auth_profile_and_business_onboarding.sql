-- Migration: auth_profile_and_business_onboarding
-- Fase 1 / Langkah 7A
-- Menambah:
--   1. Trigger on_auth_user_created → auto-create public.profiles
--   2. Generic updated_at trigger untuk profiles, businesses, business_members
--   3. RPC public.create_business_with_owner (SECURITY DEFINER, atomik)
-- Catatan: order_statuses, payment_methods, categories, accounts TIDAK di-seed
--          karena Q1 dan seed default belum diputuskan (lihat DATABASE_SCHEMA.md).

-- =========================================================
-- 1. Auto-create profile saat signup
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_new_user() from anon;
revoke all on function public.handle_new_user() from authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- =========================================================
-- 2. updated_at trigger (dipakai profil & business)
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_businesses_updated_at on public.businesses;
create trigger trg_businesses_updated_at
before update on public.businesses
for each row execute function public.set_updated_at();

drop trigger if exists trg_business_members_updated_at on public.business_members;
create trigger trg_business_members_updated_at
before update on public.business_members
for each row execute function public.set_updated_at();

-- =========================================================
-- 3. RPC create_business_with_owner
-- =========================================================

create or replace function public.create_business_with_owner(
  p_name text,
  p_timezone text default 'Asia/Jakarta'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_business_id uuid;
  v_name text := btrim(coalesce(p_name, ''));
  v_tz text := btrim(coalesce(p_timezone, ''));
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if length(v_name) = 0 then
    raise exception 'NAME_REQUIRED' using errcode = '22023';
  end if;

  if length(v_tz) = 0 then
    raise exception 'TIMEZONE_REQUIRED' using errcode = '22023';
  end if;

  insert into public.businesses (name, timezone, currency)
  values (v_name, v_tz, 'IDR')
  returning id into v_business_id;

  insert into public.business_members (business_id, user_id, role, status, joined_at)
  values (v_business_id, v_uid, 'owner', 'active', now());

  return v_business_id;
end;
$$;

-- Hanya authenticated yang boleh call
revoke all on function public.create_business_with_owner(text, text) from public;
revoke all on function public.create_business_with_owner(text, text) from anon;
grant execute on function public.create_business_with_owner(text, text) to authenticated;

-- =========================================================
-- End of migration 20261101010000
-- =========================================================

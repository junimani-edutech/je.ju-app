-- Migration: RPC update_business_profile.
-- Fase 6 / Langkah 13A. F6-03-A APPROVED 2026-11-01.
-- Tidak menyentuh currency (D-07 tetap IDR).

create or replace function public.update_business_profile(
  p_business_id uuid,
  p_name text,
  p_legal_name text default null,
  p_contact_email text default null,
  p_contact_phone text default null,
  p_address text default null,
  p_timezone text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := btrim(coalesce(p_name, ''));
  v_tz text := btrim(coalesce(p_timezone, ''));
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid
      and status = 'active'
      and role in ('owner','admin')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  if length(v_name) = 0 then
    raise exception 'NAME_REQUIRED' using errcode = '22023';
  end if;

  if length(v_tz) = 0 then
    raise exception 'TIMEZONE_REQUIRED' using errcode = '22023';
  end if;

  update public.businesses set
    name = v_name,
    legal_name = nullif(btrim(coalesce(p_legal_name, '')), ''),
    contact_email = nullif(btrim(coalesce(p_contact_email, '')), ''),
    contact_phone = nullif(btrim(coalesce(p_contact_phone, '')), ''),
    address = nullif(btrim(coalesce(p_address, '')), ''),
    timezone = v_tz
    where id = p_business_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'business.profile_updated', 'businesses', p_business_id,
    jsonb_build_object('name', v_name, 'timezone', v_tz));
end;
$$;

revoke all on function public.update_business_profile(uuid, text, text, text, text, text, text) from public, anon;
grant execute on function public.update_business_profile(uuid, text, text, text, text, text, text) to authenticated;

-- Migration: create_invitation + revoke_invitation RPC.
-- Fase 7 / Langkah 14A-2. F7-01 manual link APPROVED.

create or replace function public.create_invitation(
  p_business_id uuid,
  p_email text,
  p_role public.business_role
) returns table (invitation_id uuid, token text, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_caller_role public.business_role;
  v_token text;
  v_new_id uuid;
  v_expires timestamptz;
  v_existing_id uuid;
  v_existing_token text;
  v_existing_expires timestamptz;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if length(v_email) = 0 then
    raise exception 'EMAIL_REQUIRED' using errcode = '22023';
  end if;

  select role into v_caller_role
  from public.business_members
  where business_id = p_business_id
    and user_id = v_uid and status = 'active';

  if v_caller_role is null then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;
  if v_caller_role not in ('owner','admin') then
    raise exception 'NOT_AUTHORIZED' using errcode = '28000';
  end if;

  if v_caller_role = 'admin' and p_role in ('owner','admin') then
    raise exception 'ROLE_NOT_ALLOWED' using errcode = '22023';
  end if;
  if v_caller_role = 'owner' and p_role = 'owner' then
    raise exception 'ROLE_NOT_ALLOWED' using errcode = '22023';
  end if;

  if lower(auth.email()) = v_email then
    raise exception 'CANNOT_INVITE_SELF' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.business_members bm
    join auth.users u on u.id = bm.user_id
    where bm.business_id = p_business_id
      and lower(u.email) = v_email
      and bm.status = 'active'
  ) then
    raise exception 'EMAIL_ALREADY_MEMBER' using errcode = '22023';
  end if;

  select bi.id, bi.token, bi.expires_at
    into v_existing_id, v_existing_token, v_existing_expires
  from public.business_invitations bi
  where bi.business_id = p_business_id
    and lower(bi.email) = v_email
    and bi.status = 'pending'
    and bi.expires_at > now()
  limit 1;

  if v_existing_id is not null then
    return query select v_existing_id, v_existing_token, v_existing_expires;
    return;
  end if;

  v_token := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_expires := now() + interval '7 days';

  insert into public.business_invitations (
    business_id, email, role, token, status, invited_by, expires_at
  ) values (
    p_business_id, v_email, p_role, v_token, 'pending', v_uid, v_expires
  ) returning id into v_new_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'invitation.created', 'business_invitations', v_new_id,
    jsonb_build_object('email', v_email, 'role', p_role::text));

  return query select v_new_id, v_token, v_expires;
end;
$$;

create or replace function public.revoke_invitation(
  p_invitation_id uuid
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_business_id uuid;
  v_status text;
  v_caller_role public.business_role;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select business_id, status into v_business_id, v_status
  from public.business_invitations where id = p_invitation_id;
  if v_business_id is null then
    raise exception 'INVITATION_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_status <> 'pending' then
    raise exception 'INVITATION_NOT_PENDING' using errcode = '22023';
  end if;

  select role into v_caller_role
  from public.business_members
  where business_id = v_business_id
    and user_id = v_uid and status = 'active';
  if v_caller_role is null or v_caller_role not in ('owner','admin') then
    raise exception 'NOT_AUTHORIZED' using errcode = '28000';
  end if;

  update public.business_invitations
  set status = 'revoked', revoked_at = now(), revoked_by = v_uid
  where id = p_invitation_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (v_business_id, v_uid, 'invitation.revoked', 'business_invitations', p_invitation_id, '{}'::jsonb);
end;
$$;

revoke all on function public.create_invitation(uuid, text, public.business_role) from public, anon;
grant execute on function public.create_invitation(uuid, text, public.business_role) to authenticated;

revoke all on function public.revoke_invitation(uuid) from public, anon;
grant execute on function public.revoke_invitation(uuid) to authenticated;

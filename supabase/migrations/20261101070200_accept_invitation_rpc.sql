-- Migration: accept_invitation RPC.
-- Fase 7 / Langkah 14A-3. Flow: token -> cek email -> insert member -> mark accepted.

create or replace function public.accept_invitation(
  p_token text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_email text;
  v_inv record;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if p_token is null or length(btrim(p_token)) = 0 then
    raise exception 'TOKEN_REQUIRED' using errcode = '22023';
  end if;
  v_email := lower(coalesce(auth.email(), ''));

  select * into v_inv from public.business_invitations
  where token = btrim(p_token) limit 1;

  if v_inv.id is null then
    raise exception 'INVITATION_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_inv.status = 'accepted' and v_inv.accepted_by = v_uid then
    return v_inv.business_id;
  end if;

  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED' using errcode = '22023';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_NOT_PENDING' using errcode = '22023';
  end if;

  if v_inv.expires_at <= now() then
    update public.business_invitations set status = 'expired'
    where id = v_inv.id;
    raise exception 'INVITATION_EXPIRED' using errcode = '22023';
  end if;

  if lower(v_inv.email) <> v_email then
    raise exception 'EMAIL_MISMATCH' using errcode = '28000';
  end if;

  if exists (
    select 1 from public.business_members
    where business_id = v_inv.business_id
      and user_id = v_uid
      and status = 'active'
  ) then
    update public.business_invitations set
      status = 'accepted', accepted_at = now(), accepted_by = v_uid
    where id = v_inv.id;
    return v_inv.business_id;
  end if;

  insert into public.business_members (
    business_id, user_id, role, status, joined_at, invited_by, invited_at
  ) values (
    v_inv.business_id, v_uid, v_inv.role, 'active', now(),
    v_inv.invited_by, v_inv.created_at
  );

  update public.business_invitations set
    status = 'accepted', accepted_at = now(), accepted_by = v_uid
  where id = v_inv.id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (v_inv.business_id, v_uid, 'invitation.accepted', 'business_invitations', v_inv.id,
    jsonb_build_object('role', v_inv.role::text));

  return v_inv.business_id;
end;
$$;

revoke all on function public.accept_invitation(text) from public, anon;
grant execute on function public.accept_invitation(text) to authenticated;

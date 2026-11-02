-- Migration: business_invitations table + RLS + list_business_members RPC.
-- Fase 7 / Langkah 14A-1. F7-01 manual link APPROVED.

create table if not exists public.business_invitations (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  email text not null,
  role public.business_role not null,
  token text not null unique,
  status text not null default 'pending'
    check (status in ('pending','accepted','revoked','expired')),
  invited_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id),
  revoked_at timestamptz,
  revoked_by uuid references auth.users(id)
);

create index if not exists idx_invitations_business on public.business_invitations(business_id);
create index if not exists idx_invitations_token on public.business_invitations(token);
create index if not exists idx_invitations_email on public.business_invitations(business_id, email);

alter table public.business_invitations enable row level security;

drop policy if exists invitations_select on public.business_invitations;
create policy invitations_select on public.business_invitations
  for select using (
    public.is_business_member(business_id, array['owner','admin']::public.business_role[])
  );

create or replace function public.list_business_members(p_business_id uuid)
returns table (
  user_id uuid,
  email text,
  full_name text,
  avatar_url text,
  role public.business_role,
  status public.member_status,
  joined_at timestamptz,
  is_self boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.business_members bm
    where bm.business_id = p_business_id
      and bm.user_id = auth.uid() and bm.status = 'active'
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  return query
  select bm.user_id, u.email::text, p.full_name, p.avatar_url,
         bm.role, bm.status, bm.joined_at,
         (bm.user_id = auth.uid()) as is_self
  from public.business_members bm
  left join auth.users u on u.id = bm.user_id
  left join public.profiles p on p.id = bm.user_id
  where bm.business_id = p_business_id
  order by
    case bm.role
      when 'owner' then 0
      when 'admin' then 1
      when 'cashier' then 2
      when 'order_staff' then 3
      when 'viewer' then 4
      else 5
    end,
    bm.created_at;
end;
$$;

revoke all on function public.list_business_members(uuid) from public, anon;
grant execute on function public.list_business_members(uuid) to authenticated;

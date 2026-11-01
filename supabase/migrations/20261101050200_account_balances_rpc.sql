-- Migration: bulk account_balances(p_business_id) untuk dashboard.
-- Langkah 12A-3. Hindari N+1 query per akun.

create or replace function public.account_balances(p_business_id uuid)
returns table (account_id uuid, account_name text, balance bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'active'
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  return query
  select a.id, a.name, public.account_balance(a.id)
  from public.accounts a
  where a.business_id = p_business_id
    and a.status = 'active'
  order by a.name;
end;
$$;

revoke all on function public.account_balances(uuid) from public, anon;
grant execute on function public.account_balances(uuid) to authenticated;

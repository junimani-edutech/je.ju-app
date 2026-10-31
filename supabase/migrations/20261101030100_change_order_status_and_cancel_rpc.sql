-- Migration: change_order_status + cancel_order RPC (Langkah 10B-1).
-- Keduanya SECURITY DEFINER, atomik, menulis ke order_status_history.
-- change_order_status menolak target status 'cancelled' -> wajib pakai cancel_order.

create or replace function public.change_order_status(
  p_order_id uuid,
  p_to_status_id uuid,
  p_notes text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_biz uuid;
  v_from_status_id uuid;
  v_to_biz uuid;
  v_to_code text;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select business_id, order_status_id
    into v_biz, v_from_status_id
    from public.orders where id = p_order_id;
  if v_biz is null then
    raise exception 'ORDER_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = v_biz and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier','order_staff')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id, code into v_to_biz, v_to_code
    from public.order_statuses where id = p_to_status_id;
  if v_to_biz is null or v_to_biz <> v_biz then
    raise exception 'STATUS_NOT_FOUND' using errcode = '22023';
  end if;
  if v_to_code = 'cancelled' then
    raise exception 'USE_CANCEL_ORDER' using errcode = '22023';
  end if;

  update public.orders
    set order_status_id = p_to_status_id
    where id = p_order_id;

  insert into public.order_status_history (
    business_id, order_id, from_status_id, to_status_id, changed_by, notes
  ) values (
    v_biz, p_order_id, v_from_status_id, p_to_status_id, v_uid, p_notes
  );
end;
$$;

revoke all on function public.change_order_status(uuid, uuid, text) from public;
revoke all on function public.change_order_status(uuid, uuid, text) from anon;
grant execute on function public.change_order_status(uuid, uuid, text) to authenticated;

create or replace function public.cancel_order(
  p_order_id uuid,
  p_reason text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_biz uuid;
  v_from_status_id uuid;
  v_status text;
  v_cancelled_id uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  select business_id, order_status_id, status
    into v_biz, v_from_status_id, v_status
    from public.orders where id = p_order_id;
  if v_biz is null then
    raise exception 'ORDER_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_status = 'cancelled' then
    raise exception 'ALREADY_CANCELLED' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = v_biz and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier','order_staff')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select id into v_cancelled_id
    from public.order_statuses
    where business_id = v_biz and code = 'cancelled'
    limit 1;

  update public.orders set
    status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = v_uid,
    cancel_reason = p_reason,
    order_status_id = coalesce(v_cancelled_id, order_status_id)
    where id = p_order_id;

  insert into public.order_status_history (
    business_id, order_id, from_status_id, to_status_id, changed_by, notes
  ) values (
    v_biz, p_order_id, v_from_status_id, v_cancelled_id, v_uid,
    coalesce(p_reason, 'Order cancelled')
  );
end;
$$;

revoke all on function public.cancel_order(uuid, text) from public;
revoke all on function public.cancel_order(uuid, text) from anon;
grant execute on function public.cancel_order(uuid, text) to authenticated;

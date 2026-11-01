-- Migration: record_payment + void_payment RPC (Langkah 11A).
-- Q3-A: satu payment -> satu order.
-- Q4-A: refund = payment baru dengan reversal_of_payment_id.
-- E-01-A: recompute paid_amount & payment_status di dalam RPC.

-- Helper: hitung paid_amount order dari payments (confirmed, + normal - reversal).
create or replace function public.order_paid_amount(p_order_id uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(
    case
      when status = 'confirmed' and reversal_of_payment_id is null then amount
      when status = 'confirmed' and reversal_of_payment_id is not null then -amount
      else 0
    end
  ), 0)::bigint
  from public.payments where order_id = p_order_id;
$$;

-- Helper: hitung payment_status dari paid_amount + total order.
create or replace function public.order_payment_status(p_order_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when v_paid <= 0 then 'unpaid'
    when v_paid < v_total then 'partial'
    when v_paid = v_total then 'paid'
    else 'overpaid'
  end
  from (
    select public.order_paid_amount(p_order_id) as v_paid,
           coalesce((select total_amount from public.orders where id = p_order_id), 0) as v_total
  ) t;
$$;

revoke all on function public.order_paid_amount(uuid) from public;
revoke all on function public.order_paid_amount(uuid) from anon;
grant execute on function public.order_paid_amount(uuid) to authenticated;

revoke all on function public.order_payment_status(uuid) from public;
revoke all on function public.order_payment_status(uuid) from anon;
grant execute on function public.order_payment_status(uuid) to authenticated;

-- RPC: record_payment
create or replace function public.record_payment(
  p_business_id uuid,
  p_order_id uuid,
  p_amount bigint,
  p_payment_method_id uuid default null,
  p_account_id uuid default null,
  p_payment_date date default null,
  p_reference text default null,
  p_notes text default null,
  p_idempotency_key text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_id uuid;
  v_payment_id uuid;
  v_order_biz uuid;
  v_order_status text;
  v_method_biz uuid;
  v_account_biz uuid;
  v_paid bigint;
  v_new_status text;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'AMOUNT_INVALID' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id, status into v_order_biz, v_order_status
    from public.orders where id = p_order_id;
  if v_order_biz is null or v_order_biz <> p_business_id then
    raise exception 'ORDER_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_order_status = 'cancelled' then
    raise exception 'ORDER_CANCELLED' using errcode = '22023';
  end if;

  if p_payment_method_id is not null then
    select business_id into v_method_biz
      from public.payment_methods where id = p_payment_method_id;
    if v_method_biz is null or v_method_biz <> p_business_id then
      raise exception 'PAYMENT_METHOD_INVALID' using errcode = '22023';
    end if;
  end if;

  if p_account_id is not null then
    select business_id into v_account_biz
      from public.accounts where id = p_account_id;
    if v_account_biz is null or v_account_biz <> p_business_id then
      raise exception 'ACCOUNT_INVALID' using errcode = '22023';
    end if;
  end if;

  if p_idempotency_key is not null then
    select id into v_existing_id
      from public.payments
      where business_id = p_business_id
        and idempotency_key = p_idempotency_key
      limit 1;
    if v_existing_id is not null then
      return v_existing_id;
    end if;
  end if;

  insert into public.payments (
    business_id, order_id, amount, currency, payment_date,
    payment_method_id, account_id, reference, notes,
    status, idempotency_key, confirmed_at, confirmed_by, created_by
  ) values (
    p_business_id, p_order_id, p_amount, 'IDR',
    coalesce(p_payment_date, current_date),
    p_payment_method_id, p_account_id, p_reference, p_notes,
    'confirmed', p_idempotency_key, now(), v_uid, v_uid
  ) returning id into v_payment_id;

  v_paid := public.order_paid_amount(p_order_id);
  v_new_status := public.order_payment_status(p_order_id);

  update public.orders
    set paid_amount = v_paid, payment_status = v_new_status
    where id = p_order_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'payment.recorded', 'payments', v_payment_id,
    jsonb_build_object('order_id', p_order_id, 'amount', p_amount));

  return v_payment_id;
end;
$$;

revoke all on function public.record_payment(uuid, uuid, bigint, uuid, uuid, date, text, text, text) from public;
revoke all on function public.record_payment(uuid, uuid, bigint, uuid, uuid, date, text, text, text) from anon;
grant execute on function public.record_payment(uuid, uuid, bigint, uuid, uuid, date, text, text, text) to authenticated;

-- RPC: void_payment
create or replace function public.void_payment(
  p_payment_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_biz uuid;
  v_order_id uuid;
  v_amount bigint;
  v_status text;
  v_reversal_of uuid;
  v_reversal_id uuid;
  v_existing_reversal uuid;
  v_paid bigint;
  v_new_status text;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'REASON_REQUIRED' using errcode = '22023';
  end if;

  select business_id, order_id, amount, status, reversal_of_payment_id
    into v_biz, v_order_id, v_amount, v_status, v_reversal_of
    from public.payments where id = p_payment_id;
  if v_biz is null then
    raise exception 'PAYMENT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_status <> 'confirmed' then
    raise exception 'PAYMENT_NOT_CONFIRMED' using errcode = '22023';
  end if;

  if v_reversal_of is not null then
    raise exception 'CANNOT_VOID_REVERSAL' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = v_biz
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select id into v_existing_reversal
    from public.payments where reversal_of_payment_id = p_payment_id limit 1;
  if v_existing_reversal is not null then
    raise exception 'ALREADY_VOIDED' using errcode = '22023';
  end if;

  insert into public.payments (
    business_id, order_id, amount, currency, payment_date,
    payment_method_id, account_id, reference, notes,
    status, confirmed_at, confirmed_by, created_by,
    reversal_of_payment_id
  ) values (
    v_biz, v_order_id, v_amount, 'IDR', current_date,
    null, null, null, 'Reversal: ' || btrim(p_reason),
    'confirmed', now(), v_uid, v_uid,
    p_payment_id
  ) returning id into v_reversal_id;

  v_paid := public.order_paid_amount(v_order_id);
  v_new_status := public.order_payment_status(v_order_id);

  update public.orders
    set paid_amount = v_paid, payment_status = v_new_status
    where id = v_order_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (v_biz, v_uid, 'payment.voided', 'payments', v_reversal_id,
    jsonb_build_object('original_payment_id', p_payment_id,
                       'amount', v_amount, 'reason', p_reason));

  return v_reversal_id;
end;
$$;

revoke all on function public.void_payment(uuid, text) from public;
revoke all on function public.void_payment(uuid, text) from anon;
grant execute on function public.void_payment(uuid, text) to authenticated;

-- Migration: upsert_payment — untuk sync offline.
-- Menerima ID klien (idempotent by PK). Recompute order totals.

create or replace function public.upsert_payment(
  p_id uuid,
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
  v_order_biz uuid;
  v_order_status text;
  v_existing_biz uuid;
  v_existing_order uuid;
  v_existing_reversal uuid;
  v_method_biz uuid;
  v_account_biz uuid;
  v_has_reversal boolean;
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

  select business_id, order_id, reversal_of_payment_id
    into v_existing_biz, v_existing_order, v_existing_reversal
    from public.payments where id = p_id;

  if v_existing_biz is not null then
    if v_existing_biz <> p_business_id then
      raise exception 'PAYMENT_BUSINESS_MISMATCH' using errcode = '22023';
    end if;
    if v_existing_order <> p_order_id then
      raise exception 'PAYMENT_ORDER_MISMATCH' using errcode = '22023';
    end if;
    if v_existing_reversal is not null then
      raise exception 'CANNOT_EDIT_REVERSAL' using errcode = '22023';
    end if;
    select exists (
      select 1 from public.payments where reversal_of_payment_id = p_id
    ) into v_has_reversal;
    if v_has_reversal then
      raise exception 'PAYMENT_ALREADY_REVERSED' using errcode = '22023';
    end if;
  end if;

  insert into public.payments (
    id, business_id, order_id, amount, currency, payment_date,
    payment_method_id, account_id, reference, notes,
    status, idempotency_key, confirmed_at, confirmed_by, created_by
  ) values (
    p_id, p_business_id, p_order_id, p_amount, 'IDR',
    coalesce(p_payment_date, current_date),
    p_payment_method_id, p_account_id, p_reference, p_notes,
    'confirmed', p_idempotency_key, now(), v_uid, v_uid
  )
  on conflict (id) do update set
    amount = excluded.amount,
    payment_date = excluded.payment_date,
    payment_method_id = excluded.payment_method_id,
    account_id = excluded.account_id,
    reference = excluded.reference,
    notes = excluded.notes,
    updated_at = now();

  v_paid := public.order_paid_amount(p_order_id);
  v_new_status := public.order_payment_status(p_order_id);
  update public.orders
    set paid_amount = v_paid, payment_status = v_new_status
    where id = p_order_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'payment.upserted', 'payments', p_id,
    jsonb_build_object('order_id', p_order_id, 'amount', p_amount));

  return p_id;
end;
$$;

revoke all on function public.upsert_payment(uuid, uuid, uuid, bigint, uuid, uuid, date, text, text, text) from public, anon;
grant execute on function public.upsert_payment(uuid, uuid, uuid, bigint, uuid, uuid, date, text, text, text) to authenticated;

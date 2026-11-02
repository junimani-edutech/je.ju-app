-- Migration: upsert_order_with_items — untuk sync offline.
-- Menerima ID + order_number dari klien (idempotent by PK).
-- Tidak generate order_number sendiri, tidak pakai advisory lock.

create or replace function public.upsert_order_with_items(
  p_id uuid,
  p_business_id uuid,
  p_order_number text,
  p_customer_id uuid default null,
  p_order_date date default null,
  p_due_date date default null,
  p_discount_amount bigint default 0,
  p_additional_fee_amount bigint default 0,
  p_shipping_amount bigint default 0,
  p_notes text default null,
  p_order_status_id uuid default null,
  p_items jsonb default '[]'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_biz uuid;
  v_existing_status text;
  v_subtotal bigint;
  v_total bigint;
  v_count int;
  v_status_id uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_order_number is null or length(btrim(p_order_number)) = 0 then
    raise exception 'ORDER_NUMBER_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier','order_staff')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id, status into v_existing_biz, v_existing_status
    from public.orders where id = p_id;
  if v_existing_biz is not null then
    if v_existing_biz <> p_business_id then
      raise exception 'ORDER_BUSINESS_MISMATCH' using errcode = '22023';
    end if;
    if v_existing_status = 'cancelled' then
      raise exception 'ORDER_CANCELLED' using errcode = '22023';
    end if;
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'ITEMS_INVALID' using errcode = '22023';
  end if;
  v_count := jsonb_array_length(p_items);
  if v_count = 0 then
    raise exception 'ITEMS_REQUIRED' using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_items) it
    where length(btrim(coalesce(it->>'description',''))) = 0
       or coalesce((it->>'quantity')::numeric, 0) <= 0
       or coalesce((it->>'unit_price')::bigint, -1) < 0
       or coalesce((it->>'discount_amount')::bigint, 0) < 0
  ) then
    raise exception 'ITEM_INVALID' using errcode = '22023';
  end if;

  select coalesce(sum(
    round((it->>'quantity')::numeric * (it->>'unit_price')::bigint)::bigint
    - coalesce((it->>'discount_amount')::bigint, 0)
  ), 0) into v_subtotal
  from jsonb_array_elements(p_items) it;

  v_total := v_subtotal
    - coalesce(p_discount_amount, 0)
    + coalesce(p_additional_fee_amount, 0)
    + coalesce(p_shipping_amount, 0);
  if v_total < 0 then
    raise exception 'INVALID_TOTAL' using errcode = '22023';
  end if;

  if p_order_status_id is not null then
    if not exists (
      select 1 from public.order_statuses
      where id = p_order_status_id and business_id = p_business_id
    ) then
      raise exception 'STATUS_INVALID' using errcode = '22023';
    end if;
    v_status_id := p_order_status_id;
  else
    select id into v_status_id from public.order_statuses
      where business_id = p_business_id and code = 'draft' limit 1;
  end if;

  insert into public.orders (
    id, business_id, order_number, customer_id, order_date, due_date,
    subtotal_amount, discount_amount, additional_fee_amount, shipping_amount,
    total_amount, paid_amount, currency, notes, order_status_id,
    payment_status, status, created_by
  ) values (
    p_id, p_business_id, btrim(p_order_number), p_customer_id,
    coalesce(p_order_date, current_date), p_due_date,
    v_subtotal, coalesce(p_discount_amount, 0),
    coalesce(p_additional_fee_amount, 0), coalesce(p_shipping_amount, 0),
    v_total, 0, 'IDR', p_notes, v_status_id,
    'unpaid', 'active', v_uid
  )
  on conflict (id) do update set
    order_number = excluded.order_number,
    customer_id = excluded.customer_id,
    order_date = excluded.order_date,
    due_date = excluded.due_date,
    subtotal_amount = excluded.subtotal_amount,
    discount_amount = excluded.discount_amount,
    additional_fee_amount = excluded.additional_fee_amount,
    shipping_amount = excluded.shipping_amount,
    total_amount = excluded.total_amount,
    notes = excluded.notes,
    order_status_id = excluded.order_status_id,
    updated_at = now();

  delete from public.order_items where order_id = p_id;

  insert into public.order_items (
    business_id, order_id, position, description, quantity,
    unit_price, discount_amount, line_total
  )
  select
    p_business_id, p_id, (row_number() over ()) - 1,
    it->>'description',
    (it->>'quantity')::numeric,
    (it->>'unit_price')::bigint,
    coalesce((it->>'discount_amount')::bigint, 0),
    round((it->>'quantity')::numeric * (it->>'unit_price')::bigint)::bigint
      - coalesce((it->>'discount_amount')::bigint, 0)
  from jsonb_array_elements(p_items) it;

  if v_existing_biz is not null then
    update public.orders o set
      paid_amount = public.order_paid_amount(o.id),
      payment_status = public.order_payment_status(o.id)
      where o.id = p_id;
  end if;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'order.upserted', 'orders', p_id,
    jsonb_build_object('order_number', p_order_number, 'total', v_total));

  return p_id;
end;
$$;

revoke all on function public.upsert_order_with_items(uuid, uuid, text, uuid, date, date, bigint, bigint, bigint, text, uuid, jsonb) from public, anon;
grant execute on function public.upsert_order_with_items(uuid, uuid, text, uuid, date, date, bigint, bigint, bigint, text, uuid, jsonb) to authenticated;

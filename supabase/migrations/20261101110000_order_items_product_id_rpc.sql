-- Migration: create_order + upsert_order_with_items terima product_id per item.
-- Fase 12.1.

-- =========================================================
-- 1. create_order (online)
-- =========================================================
create or replace function public.create_order(
  p_business_id uuid,
  p_customer_id uuid default null,
  p_order_date date default null,
  p_due_date date default null,
  p_notes text default null,
  p_discount_amount bigint default 0,
  p_additional_fee_amount bigint default 0,
  p_shipping_amount bigint default 0,
  p_items jsonb default '[]'::jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_order_id uuid;
  v_order_number text;
  v_seq int;
  v_subtotal bigint := 0;
  v_total bigint;
  v_draft_status_id uuid;
  v_item jsonb;
  v_qty numeric;
  v_price bigint;
  v_disc bigint;
  v_desc text;
  v_product_id uuid;
  v_line bigint;
  v_count int;
  v_i int;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier','order_staff')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'ITEMS_REQUIRED' using errcode = '22023';
  end if;

  v_count := jsonb_array_length(p_items);

  for v_i in 0..v_count-1 loop
    v_item := p_items->v_i;
    v_desc := v_item->>'description';
    v_qty  := (v_item->>'quantity')::numeric;
    v_price:= (v_item->>'unit_price')::bigint;
    v_disc := coalesce((v_item->>'discount_amount')::bigint, 0);

    if (v_item ? 'product_id') and (v_item->>'product_id') is not null
       and length(v_item->>'product_id') > 0 then
      v_product_id := (v_item->>'product_id')::uuid;
      if not exists (
        select 1 from public.products
        where id = v_product_id and business_id = p_business_id
      ) then
        raise exception 'PRODUCT_INVALID' using errcode = '22023';
      end if;
    end if;

    if v_desc is null or length(btrim(v_desc)) = 0 then
      raise exception 'ITEM_DESCRIPTION_REQUIRED' using errcode = '22023';
    end if;
    if v_qty is null or v_qty <= 0 then
      raise exception 'ITEM_QUANTITY_INVALID' using errcode = '22023';
    end if;
    if v_price is null or v_price < 0 then
      raise exception 'ITEM_UNIT_PRICE_INVALID' using errcode = '22023';
    end if;
    if v_disc < 0 then
      raise exception 'ITEM_DISCOUNT_INVALID' using errcode = '22023';
    end if;

    v_line := round(v_qty * v_price)::bigint - v_disc;
    if v_line < 0 then
      raise exception 'ITEM_DISCOUNT_INVALID' using errcode = '22023';
    end if;

    v_subtotal := v_subtotal + v_line;
  end loop;

  v_total := v_subtotal
    - coalesce(p_discount_amount, 0)
    + coalesce(p_additional_fee_amount, 0)
    + coalesce(p_shipping_amount, 0);

  if v_total < 0 then
    raise exception 'INVALID_TOTAL' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(
    hashtext('order_seq:' || p_business_id::text),
    hashtext(to_char(current_date, 'YYYYMMDD'))
  );

  select coalesce(max(substring(order_number from 10)::int), 0) + 1
  into v_seq
  from public.orders
  where business_id = p_business_id
    and order_number like to_char(current_date, 'YYYYMMDD') || '-%';

  v_order_number := to_char(current_date, 'YYYYMMDD')
    || '-' || lpad(v_seq::text, 3, '0');

  select id into v_draft_status_id
  from public.order_statuses
  where business_id = p_business_id and code = 'draft'
  limit 1;

  if v_draft_status_id is null then
    select id into v_draft_status_id
    from public.order_statuses
    where business_id = p_business_id
    order by sort_order
    limit 1;
  end if;

  insert into public.orders (
    business_id, order_number, customer_id, order_date, due_date,
    subtotal_amount, discount_amount, additional_fee_amount, shipping_amount,
    total_amount, paid_amount, currency, notes, order_status_id,
    payment_status, status, created_by
  ) values (
    p_business_id, v_order_number, p_customer_id,
    coalesce(p_order_date, current_date), p_due_date,
    v_subtotal, coalesce(p_discount_amount, 0),
    coalesce(p_additional_fee_amount, 0), coalesce(p_shipping_amount, 0),
    v_total, 0, 'IDR', p_notes, v_draft_status_id,
    'unpaid', 'active', v_uid
  ) returning id into v_order_id;

  for v_i in 0..v_count-1 loop
    v_item := p_items->v_i;
    v_desc := v_item->>'description';
    v_qty  := (v_item->>'quantity')::numeric;
    v_price:= (v_item->>'unit_price')::bigint;
    v_disc := coalesce((v_item->>'discount_amount')::bigint, 0);
    v_line := round(v_qty * v_price)::bigint - v_disc;

    if (v_item ? 'product_id') and (v_item->>'product_id') is not null
       and length(v_item->>'product_id') > 0 then
      v_product_id := (v_item->>'product_id')::uuid;
    else
      v_product_id := null;
    end if;

    insert into public.order_items (
      business_id, order_id, product_id, position, description, quantity,
      unit_price, discount_amount, line_total
    ) values (
      p_business_id, v_order_id, v_product_id, v_i, v_desc, v_qty,
      v_price, v_disc, v_line
    );
  end loop;

  return v_order_id;
end;
$$;

revoke all on function public.create_order(uuid, uuid, date, date, text, bigint, bigint, bigint, jsonb) from public, anon;
grant execute on function public.create_order(uuid, uuid, date, date, text, bigint, bigint, bigint, jsonb) to authenticated;

-- =========================================================
-- 2. upsert_order_with_items (offline sync)
-- =========================================================
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
  v_item jsonb;
  v_qty numeric;
  v_price bigint;
  v_disc bigint;
  v_desc text;
  v_product_id uuid;
  v_line bigint;
  v_i int;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if p_order_number is null or length(btrim(p_order_number)) = 0 then
    raise exception 'ORDER_NUMBER_REQUIRED' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id and user_id = v_uid and status = 'active'
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

  -- Validate each item incl product_id
  for v_i in 0..v_count-1 loop
    v_item := p_items->v_i;
    v_desc := v_item->>'description';
    v_qty := (v_item->>'quantity')::numeric;
    v_price := (v_item->>'unit_price')::bigint;
    v_disc := coalesce((v_item->>'discount_amount')::bigint, 0);

    if (v_item ? 'product_id') and (v_item->>'product_id') is not null
       and length(v_item->>'product_id') > 0 then
      v_product_id := (v_item->>'product_id')::uuid;
      if not exists (
        select 1 from public.products
        where id = v_product_id and business_id = p_business_id
      ) then
        raise exception 'PRODUCT_INVALID' using errcode = '22023';
      end if;
    end if;

    if v_desc is null or length(btrim(v_desc)) = 0 then
      raise exception 'ITEM_DESCRIPTION_REQUIRED' using errcode = '22023';
    end if;
    if v_qty is null or v_qty <= 0 then
      raise exception 'ITEM_QUANTITY_INVALID' using errcode = '22023';
    end if;
    if v_price is null or v_price < 0 then
      raise exception 'ITEM_UNIT_PRICE_INVALID' using errcode = '22023';
    end if;
    if v_disc < 0 then
      raise exception 'ITEM_DISCOUNT_INVALID' using errcode = '22023';
    end if;
  end loop;

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

  for v_i in 0..v_count-1 loop
    v_item := p_items->v_i;
    v_desc := v_item->>'description';
    v_qty  := (v_item->>'quantity')::numeric;
    v_price:= (v_item->>'unit_price')::bigint;
    v_disc := coalesce((v_item->>'discount_amount')::bigint, 0);
    v_line := round(v_qty * v_price)::bigint - v_disc;

    if (v_item ? 'product_id') and (v_item->>'product_id') is not null
       and length(v_item->>'product_id') > 0 then
      v_product_id := (v_item->>'product_id')::uuid;
    else
      v_product_id := null;
    end if;

    insert into public.order_items (
      business_id, order_id, product_id, position, description, quantity,
      unit_price, discount_amount, line_total
    ) values (
      p_business_id, p_id, v_product_id, v_i, v_desc, v_qty,
      v_price, v_disc, v_line
    );
  end loop;

  if v_existing_biz is not null then
    update public.orders o set
      paid_amount = public.order_paid_amount(o.id),
      payment_status = public.order_payment_status(o.id)
      where o.id = p_id;
  end if;

  return p_id;
end;
$$;

revoke all on function public.upsert_order_with_items(uuid, uuid, text, uuid, date, date, bigint, bigint, bigint, text, uuid, jsonb) from public, anon;
grant execute on function public.upsert_order_with_items(uuid, uuid, text, uuid, date, date, bigint, bigint, bigint, text, uuid, jsonb) to authenticated;

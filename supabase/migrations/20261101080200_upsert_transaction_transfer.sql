-- Migration: upsert_transaction + upsert_transfer — untuk sync offline.
-- Menerima ID klien (idempotent by PK). Tidak menyentuh RPC online.

create or replace function public.upsert_transaction(
  p_id uuid,
  p_business_id uuid,
  p_type text,
  p_amount bigint,
  p_description text,
  p_category_id uuid default null,
  p_account_id uuid default null,
  p_transaction_date date default null,
  p_reference text default null,
  p_idempotency_key text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_biz uuid;
  v_existing_reversal uuid;
  v_cat_biz uuid;
  v_cat_type text;
  v_acc_biz uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if p_type is null or p_type not in ('income','expense') then
    raise exception 'TYPE_INVALID' using errcode = '22023';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'AMOUNT_INVALID' using errcode = '22023';
  end if;
  if p_description is null or length(btrim(p_description)) = 0 then
    raise exception 'DESCRIPTION_REQUIRED' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id, reversal_of_transaction_id
    into v_existing_biz, v_existing_reversal
    from public.transactions where id = p_id;
  if v_existing_biz is not null then
    if v_existing_biz <> p_business_id then
      raise exception 'TXN_BUSINESS_MISMATCH' using errcode = '22023';
    end if;
    if v_existing_reversal is not null then
      raise exception 'CANNOT_EDIT_REVERSAL' using errcode = '22023';
    end if;
  end if;

  if p_category_id is not null then
    select business_id, type into v_cat_biz, v_cat_type
      from public.categories where id = p_category_id;
    if v_cat_biz is null or v_cat_biz <> p_business_id then
      raise exception 'CATEGORY_INVALID' using errcode = '22023';
    end if;
    if v_cat_type <> p_type then
      raise exception 'CATEGORY_TYPE_MISMATCH' using errcode = '22023';
    end if;
  end if;
  if p_account_id is not null then
    select business_id into v_acc_biz
      from public.accounts where id = p_account_id;
    if v_acc_biz is null or v_acc_biz <> p_business_id then
      raise exception 'ACCOUNT_INVALID' using errcode = '22023';
    end if;
  end if;

  insert into public.transactions (
    id, business_id, type, category_id, account_id, amount, currency,
    transaction_date, description, reference, status, idempotency_key, created_by
  ) values (
    p_id, p_business_id, p_type, p_category_id, p_account_id, p_amount, 'IDR',
    coalesce(p_transaction_date, current_date),
    btrim(p_description), p_reference, 'confirmed', p_idempotency_key, v_uid
  )
  on conflict (id) do update set
    type = excluded.type,
    category_id = excluded.category_id,
    account_id = excluded.account_id,
    amount = excluded.amount,
    transaction_date = excluded.transaction_date,
    description = excluded.description,
    reference = excluded.reference,
    updated_at = now();

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'transaction.upserted', 'transactions', p_id,
    jsonb_build_object('type', p_type, 'amount', p_amount));

  return p_id;
end;
$$;

revoke all on function public.upsert_transaction(uuid, uuid, text, bigint, text, uuid, uuid, date, text, text) from public, anon;
grant execute on function public.upsert_transaction(uuid, uuid, text, bigint, text, uuid, uuid, date, text, text) to authenticated;

create or replace function public.upsert_transfer(
  p_id uuid,
  p_business_id uuid,
  p_from_account_id uuid,
  p_to_account_id uuid,
  p_amount bigint,
  p_transfer_date date default null,
  p_description text default null,
  p_idempotency_key text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_biz uuid;
  v_existing_status text;
  v_from_biz uuid;
  v_to_biz uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'AMOUNT_INVALID' using errcode = '22023';
  end if;
  if p_from_account_id = p_to_account_id then
    raise exception 'SAME_ACCOUNT' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id into v_from_biz
    from public.accounts where id = p_from_account_id;
  if v_from_biz is null or v_from_biz <> p_business_id then
    raise exception 'FROM_ACCOUNT_INVALID' using errcode = '22023';
  end if;
  select business_id into v_to_biz
    from public.accounts where id = p_to_account_id;
  if v_to_biz is null or v_to_biz <> p_business_id then
    raise exception 'TO_ACCOUNT_INVALID' using errcode = '22023';
  end if;

  select business_id, status into v_existing_biz, v_existing_status
    from public.transfers where id = p_id;
  if v_existing_biz is not null then
    if v_existing_biz <> p_business_id then
      raise exception 'TRANSFER_BUSINESS_MISMATCH' using errcode = '22023';
    end if;
    if v_existing_status <> 'confirmed' then
      raise exception 'TRANSFER_NOT_EDITABLE' using errcode = '22023';
    end if;
  end if;

  insert into public.transfers (
    id, business_id, from_account_id, to_account_id, amount, currency,
    transfer_date, description, status, idempotency_key, created_by
  ) values (
    p_id, p_business_id, p_from_account_id, p_to_account_id, p_amount, 'IDR',
    coalesce(p_transfer_date, current_date),
    nullif(btrim(coalesce(p_description, '')), ''),
    'confirmed', p_idempotency_key, v_uid
  )
  on conflict (id) do update set
    from_account_id = excluded.from_account_id,
    to_account_id = excluded.to_account_id,
    amount = excluded.amount,
    transfer_date = excluded.transfer_date,
    description = excluded.description,
    updated_at = now();

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'transfer.upserted', 'transfers', p_id,
    jsonb_build_object('from', p_from_account_id, 'to', p_to_account_id, 'amount', p_amount));

  return p_id;
end;
$$;

revoke all on function public.upsert_transfer(uuid, uuid, uuid, uuid, bigint, date, text, text) from public, anon;
grant execute on function public.upsert_transfer(uuid, uuid, uuid, uuid, bigint, date, text, text) to authenticated;

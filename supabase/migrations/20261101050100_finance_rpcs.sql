-- Migration: RPC transaksi & transfer + helper saldo akun + cash flow summary.
-- Fase 5 / Langkah 12A. F5-01-A s.d. F5-04-A APPROVED 2026-11-01.

-- =========================================================
-- 1. record_transaction
-- =========================================================
create or replace function public.record_transaction(
  p_business_id uuid,
  p_type text,
  p_amount bigint,
  p_description text,
  p_category_id uuid default null,
  p_account_id uuid default null,
  p_transaction_date date default null,
  p_reference text default null,
  p_attachment_url text default null,
  p_idempotency_key text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_id uuid;
  v_new_id uuid;
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

  if p_idempotency_key is not null then
    select id into v_existing_id
      from public.transactions
      where business_id = p_business_id
        and idempotency_key = p_idempotency_key
      limit 1;
    if v_existing_id is not null then
      return v_existing_id;
    end if;
  end if;

  insert into public.transactions (
    business_id, type, category_id, account_id, amount, currency,
    transaction_date, description, reference, attachment_url,
    status, idempotency_key, created_by
  ) values (
    p_business_id, p_type, p_category_id, p_account_id, p_amount, 'IDR',
    coalesce(p_transaction_date, current_date),
    btrim(p_description), p_reference, p_attachment_url,
    'confirmed', p_idempotency_key, v_uid
  ) returning id into v_new_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'transaction.recorded', 'transactions', v_new_id,
    jsonb_build_object('type', p_type, 'amount', p_amount));

  return v_new_id;
end;
$$;

revoke all on function public.record_transaction(uuid, text, bigint, text, uuid, uuid, date, text, text, text) from public, anon;
grant execute on function public.record_transaction(uuid, text, bigint, text, uuid, uuid, date, text, text, text) to authenticated;

-- =========================================================
-- 2. void_transaction
-- =========================================================
create or replace function public.void_transaction(
  p_transaction_id uuid,
  p_reason text
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_biz uuid;
  v_type text;
  v_amount bigint;
  v_status text;
  v_cat_id uuid;
  v_acc_id uuid;
  v_is_reversal boolean;
  v_existing_reversal uuid;
  v_reversal_id uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'REASON_REQUIRED' using errcode = '22023';
  end if;

  select business_id, type, amount, status, category_id, account_id,
         (reversal_of_transaction_id is not null)
    into v_biz, v_type, v_amount, v_status, v_cat_id, v_acc_id, v_is_reversal
    from public.transactions where id = p_transaction_id;
  if v_biz is null then
    raise exception 'TRANSACTION_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_status <> 'confirmed' then
    raise exception 'TRANSACTION_NOT_CONFIRMED' using errcode = '22023';
  end if;
  if v_is_reversal then
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
    from public.transactions where reversal_of_transaction_id = p_transaction_id limit 1;
  if v_existing_reversal is not null then
    raise exception 'ALREADY_VOIDED' using errcode = '22023';
  end if;

  insert into public.transactions (
    business_id, type, category_id, account_id, amount, currency,
    transaction_date, description, reference, status, created_by,
    reversal_of_transaction_id
  ) values (
    v_biz, v_type, v_cat_id, v_acc_id, v_amount, 'IDR',
    current_date, 'Reversal: ' || btrim(p_reason), null, 'confirmed', v_uid,
    p_transaction_id
  ) returning id into v_reversal_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (v_biz, v_uid, 'transaction.voided', 'transactions', v_reversal_id,
    jsonb_build_object('original_transaction_id', p_transaction_id,
                       'amount', v_amount, 'reason', p_reason));

  return v_reversal_id;
end;
$$;

revoke all on function public.void_transaction(uuid, text) from public, anon;
grant execute on function public.void_transaction(uuid, text) to authenticated;

-- =========================================================
-- 3. record_transfer
-- =========================================================
create or replace function public.record_transfer(
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
  v_existing_id uuid;
  v_new_id uuid;
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

  if p_idempotency_key is not null then
    select id into v_existing_id
      from public.transfers
      where business_id = p_business_id
        and idempotency_key = p_idempotency_key
      limit 1;
    if v_existing_id is not null then
      return v_existing_id;
    end if;
  end if;

  insert into public.transfers (
    business_id, from_account_id, to_account_id, amount, currency,
    transfer_date, description, status, idempotency_key, created_by
  ) values (
    p_business_id, p_from_account_id, p_to_account_id, p_amount, 'IDR',
    coalesce(p_transfer_date, current_date),
    nullif(btrim(coalesce(p_description, '')), ''),
    'confirmed', p_idempotency_key, v_uid
  ) returning id into v_new_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (p_business_id, v_uid, 'transfer.recorded', 'transfers', v_new_id,
    jsonb_build_object('from', p_from_account_id, 'to', p_to_account_id, 'amount', p_amount));

  return v_new_id;
end;
$$;

revoke all on function public.record_transfer(uuid, uuid, uuid, bigint, date, text, text) from public, anon;
grant execute on function public.record_transfer(uuid, uuid, uuid, bigint, date, text, text) to authenticated;

-- =========================================================
-- 4. void_transfer
-- =========================================================
create or replace function public.void_transfer(
  p_transfer_id uuid,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_biz uuid;
  v_status text;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'REASON_REQUIRED' using errcode = '22023';
  end if;

  select business_id, status into v_biz, v_status
    from public.transfers where id = p_transfer_id;
  if v_biz is null then
    raise exception 'TRANSFER_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_status <> 'confirmed' then
    raise exception 'ALREADY_CANCELLED' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = v_biz
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  update public.transfers set
    status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = v_uid,
    cancel_reason = btrim(p_reason)
    where id = p_transfer_id;

  insert into public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  values (v_biz, v_uid, 'transfer.voided', 'transfers', p_transfer_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

revoke all on function public.void_transfer(uuid, text) from public, anon;
grant execute on function public.void_transfer(uuid, text) to authenticated;

-- =========================================================
-- 5. account_balance
-- =========================================================
create or replace function public.account_balance(
  p_account_id uuid,
  p_as_of date default null
) returns bigint
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_biz uuid;
  v_initial bigint;
  v_inc bigint;
  v_exp bigint;
  v_tin bigint;
  v_tout bigint;
  v_pay bigint;
begin
  select business_id, initial_balance into v_biz, v_initial
    from public.accounts where id = p_account_id;
  if v_biz is null then
    raise exception 'ACCOUNT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = v_biz
      and user_id = auth.uid() and status = 'active'
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select coalesce(sum(
    case when reversal_of_transaction_id is null then amount else -amount end
  ), 0) into v_inc
  from public.transactions
  where account_id = p_account_id
    and type = 'income' and status = 'confirmed'
    and (p_as_of is null or transaction_date <= p_as_of);

  select coalesce(sum(
    case when reversal_of_transaction_id is null then amount else -amount end
  ), 0) into v_exp
  from public.transactions
  where account_id = p_account_id
    and type = 'expense' and status = 'confirmed'
    and (p_as_of is null or transaction_date <= p_as_of);

  select coalesce(sum(amount), 0) into v_tin
  from public.transfers
  where to_account_id = p_account_id
    and (
      status = 'confirmed'
      or (status = 'cancelled' and p_as_of is not null
          and cancelled_at::date > p_as_of)
    )
    and (p_as_of is null or transfer_date <= p_as_of);

  select coalesce(sum(amount), 0) into v_tout
  from public.transfers
  where from_account_id = p_account_id
    and (
      status = 'confirmed'
      or (status = 'cancelled' and p_as_of is not null
          and cancelled_at::date > p_as_of)
    )
    and (p_as_of is null or transfer_date <= p_as_of);

  select coalesce(sum(
    case when reversal_of_payment_id is null then amount else -amount end
  ), 0) into v_pay
  from public.payments
  where account_id = p_account_id
    and status = 'confirmed'
    and (p_as_of is null or payment_date <= p_as_of);

  return (v_initial + v_inc - v_exp + v_tin - v_tout + v_pay)::bigint;
end;
$$;

revoke all on function public.account_balance(uuid, date) from public, anon;
grant execute on function public.account_balance(uuid, date) to authenticated;

-- =========================================================
-- 6. cash_flow_summary
-- =========================================================
create or replace function public.cash_flow_summary(
  p_business_id uuid,
  p_from date,
  p_to date
) returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_inc bigint;
  v_exp bigint;
  v_pay bigint;
begin
  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = auth.uid() and status = 'active'
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select coalesce(sum(
    case when reversal_of_transaction_id is null then amount else -amount end
  ), 0) into v_inc
  from public.transactions
  where business_id = p_business_id
    and type = 'income' and status = 'confirmed'
    and transaction_date between p_from and p_to;

  select coalesce(sum(
    case when reversal_of_transaction_id is null then amount else -amount end
  ), 0) into v_exp
  from public.transactions
  where business_id = p_business_id
    and type = 'expense' and status = 'confirmed'
    and transaction_date between p_from and p_to;

  select coalesce(sum(
    case when reversal_of_payment_id is null then amount else -amount end
  ), 0) into v_pay
  from public.payments
  where business_id = p_business_id
    and status = 'confirmed'
    and payment_date between p_from and p_to;

  return jsonb_build_object(
    'income', v_inc,
    'expense', v_exp,
    'payments_net', v_pay,
    'net', (v_inc - v_exp + v_pay)
  );
end;
$$;

revoke all on function public.cash_flow_summary(uuid, date, date) from public, anon;
grant execute on function public.cash_flow_summary(uuid, date, date) to authenticated;

-- =========================================================
-- End migration 0501
-- =========================================================

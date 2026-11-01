-- Migration: fix void_payment untuk menyalin payment_method_id & account_id
-- dari payment asli ke payment reversal.
-- F5-04-A APPROVED 2026-11-01.
--
-- Alasan: void payment harus mengembalikan dana ke akun yang sama
-- dengan yang menerima payment asli. Tanpa ini, formula saldo akun
-- (F5-03-A) salah hitung.
--
-- Signature TIDAK berubah. Hanya body.

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
  v_method_id uuid;
  v_account_id uuid;
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

  select business_id, order_id, amount, status, reversal_of_payment_id,
         payment_method_id, account_id
    into v_biz, v_order_id, v_amount, v_status, v_reversal_of,
         v_method_id, v_account_id
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

  -- Reversal: salin method_id & account_id dari payment asli.
  insert into public.payments (
    business_id, order_id, amount, currency, payment_date,
    payment_method_id, account_id, reference, notes,
    status, confirmed_at, confirmed_by, created_by,
    reversal_of_payment_id
  ) values (
    v_biz, v_order_id, v_amount, 'IDR', current_date,
    v_method_id, v_account_id, null, 'Reversal: ' || btrim(p_reason),
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
                       'amount', v_amount, 'reason', p_reason,
                       'account_id', v_account_id,
                       'payment_method_id', v_method_id));

  return v_reversal_id;
end;
$$;

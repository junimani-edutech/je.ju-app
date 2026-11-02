-- Migration: RPC report_summary untuk laporan Fase 6.
-- F6-02-A APPROVED 2026-11-01 (rekap default = bulan berjalan; range dari UI).

create or replace function public.report_summary(
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
  v_orders_count int;
  v_orders_total bigint;
  v_payments_received bigint;
  v_receivables_remaining bigint;
  v_flow jsonb;
  v_balances jsonb;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'active'
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  if p_from is null or p_to is null or p_from > p_to then
    raise exception 'DATE_RANGE_INVALID' using errcode = '22023';
  end if;

  -- Orders (non-cancelled) dalam rentang.
  select count(*), coalesce(sum(total_amount), 0)
    into v_orders_count, v_orders_total
  from public.orders
  where business_id = p_business_id
    and status <> 'cancelled'
    and order_date between p_from and p_to;

  -- Payments received dalam rentang (confirmed net of reversals).
  select coalesce(sum(
    case when reversal_of_payment_id is null then amount else -amount end
  ), 0)
    into v_payments_received
  from public.payments
  where business_id = p_business_id
    and status = 'confirmed'
    and payment_date between p_from and p_to;

  -- Receivables: snapshot order aktif (unpaid/partial).
  select coalesce(sum(total_amount - paid_amount), 0)
    into v_receivables_remaining
  from public.orders
  where business_id = p_business_id
    and status <> 'cancelled'
    and payment_status in ('unpaid', 'partial');

  -- Cash flow ringkas.
  v_flow := public.cash_flow_summary(p_business_id, p_from, p_to);

  -- Saldo akun (snapshot saat ini).
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'account_id', ab.account_id,
        'account_name', ab.account_name,
        'balance', ab.balance
      ) order by ab.account_name
    ),
    '[]'::jsonb
  )
    into v_balances
  from public.account_balances(p_business_id) ab;

  return jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'orders_count', v_orders_count,
    'orders_total', v_orders_total,
    'payments_received', v_payments_received,
    'receivables_remaining', v_receivables_remaining,
    'income', (v_flow->>'income')::bigint,
    'expense', (v_flow->>'expense')::bigint,
    'payments_net', (v_flow->>'payments_net')::bigint,
    'cash_flow_net', (v_flow->>'net')::bigint,
    'balance_by_account', v_balances
  );
end;
$$;

revoke all on function public.report_summary(uuid, date, date) from public, anon;
grant execute on function public.report_summary(uuid, date, date) to authenticated;

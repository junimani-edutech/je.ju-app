CREATE OR REPLACE FUNCTION public.cash_flow_summary(
  p_business_id uuid,
  p_from date,
  p_to date
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
  v_income bigint;
  v_expense bigint;
  v_payments_net bigint;
  v_net bigint;
  v_omzet_kotor bigint;
  v_total_ongkir bigint;
  v_omzet_bersih bigint;
  v_laba_kotor bigint;
  v_piutang bigint;
  v_cash_in_hand bigint;
BEGIN
  -- OLD METRICS (backward compat untuk ReportSummary)
  SELECT COALESCE(SUM(amount), 0) INTO v_income
  FROM transactions
  WHERE business_id = p_business_id AND type = 'income' AND status = 'confirmed'
    AND transaction_date BETWEEN p_from AND p_to;
  
  SELECT COALESCE(SUM(amount), 0) INTO v_expense
  FROM transactions
  WHERE business_id = p_business_id AND type = 'expense' AND status = 'confirmed'
    AND transaction_date BETWEEN p_from AND p_to;
  
  -- payments_net = confirmed payments - reversals
  SELECT COALESCE(SUM(
    CASE WHEN reversal_of_payment_id IS NULL THEN amount ELSE -amount END
  ), 0) INTO v_payments_net
  FROM payments
  WHERE business_id = p_business_id AND status = 'confirmed'
    AND payment_date BETWEEN p_from AND p_to;
  
  v_net := v_income + v_payments_net - v_expense;
  
  -- NEW v2.0 METRICS
  SELECT COALESCE(SUM(total_amount), 0), COALESCE(SUM(shipping_amount), 0)
  INTO v_omzet_kotor, v_total_ongkir
  FROM orders
  WHERE business_id = p_business_id AND status = 'active'
    AND order_date BETWEEN p_from AND p_to;
  
  v_omzet_bersih := v_omzet_kotor - v_total_ongkir;
  v_laba_kotor := v_omzet_bersih - v_expense;
  
  SELECT COALESCE(SUM(total_amount - paid_amount), 0) INTO v_piutang
  FROM orders
  WHERE business_id = p_business_id AND status = 'active'
    AND payment_status IN ('unpaid', 'partial')
    AND order_date BETWEEN p_from AND p_to;
  
  v_cash_in_hand := v_payments_net + v_income - v_expense;
  
  RETURN jsonb_build_object(
    'income', v_income,
    'expense', v_expense,
    'payments_net', v_payments_net,
    'net', v_net,
    'omzet_kotor', v_omzet_kotor,
    'total_ongkir', v_total_ongkir,
    'omzet_bersih', v_omzet_bersih,
    'laba_kotor', v_laba_kotor,
    'piutang', v_piutang,
    'cash_in_hand', v_cash_in_hand
  );
END;
$$;

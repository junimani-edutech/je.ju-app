-- =====================================================
-- FASE 1.5a: Excess Payment System (Clean, No Double-Count)
-- =====================================================

-- 1. Tabel history kelebihan bayar (TERPISAH dari transactions)
CREATE TABLE IF NOT EXISTS public.payment_excesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  payment_id uuid NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  amount bigint NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'kept_as_income' 
    CHECK (status IN ('kept_as_income', 'refunded', 'reversed')),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_excesses_business_date 
  ON payment_excesses(business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_excesses_payment 
  ON payment_excesses(payment_id);

-- 2. Kolom applied_amount di payments (nullable, backward-compatible)
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS applied_amount bigint;

-- Backfill: data lama dianggap applied = amount (tidak ada excess)
UPDATE public.payments 
  SET applied_amount = amount 
  WHERE applied_amount IS NULL;

-- 3. RLS untuk payment_excesses
ALTER TABLE public.payment_excesses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "excesses_select" ON public.payment_excesses;
CREATE POLICY "excesses_select" ON public.payment_excesses FOR SELECT USING (
  business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "excesses_insert" ON public.payment_excesses;
CREATE POLICY "excesses_insert" ON public.payment_excesses FOR INSERT WITH CHECK (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

-- 4. Update order_paid_amount: gunakan applied_amount (COALESCE untuk backward compat)
CREATE OR REPLACE FUNCTION public.order_paid_amount(p_order_id uuid)
RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(
    CASE
      WHEN status = 'confirmed' AND reversal_of_payment_id IS NULL 
        THEN COALESCE(applied_amount, amount)
      WHEN status = 'confirmed' AND reversal_of_payment_id IS NOT NULL 
        THEN -COALESCE(applied_amount, amount)
      ELSE 0
    END
  ), 0)::bigint
  FROM public.payments WHERE order_id = p_order_id;
$$;

-- 5. Update order_payment_status: hapus status 'overpaid' (order tetap 'paid')
CREATE OR REPLACE FUNCTION public.order_payment_status(p_order_id uuid)
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN v_paid <= 0 THEN 'unpaid'
    WHEN v_paid < v_total THEN 'partial'
    ELSE 'paid'
  END
  FROM (
    SELECT public.order_paid_amount(p_order_id) as v_paid,
           COALESCE((SELECT total_amount FROM public.orders WHERE id = p_order_id), 0) as v_total
  ) t;
$$;

-- 6. Update record_payment: hitung applied & excess
CREATE OR REPLACE FUNCTION public.record_payment(
  p_business_id uuid,
  p_order_id uuid,
  p_amount bigint,
  p_payment_method_id uuid DEFAULT NULL,
  p_account_id uuid DEFAULT NULL,
  p_payment_date date DEFAULT NULL,
  p_reference text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_existing_id uuid;
  v_payment_id uuid;
  v_order_biz uuid;
  v_order_status text;
  v_order_total bigint;
  v_sisa bigint;
  v_applied bigint;
  v_excess bigint;
  v_method_biz uuid;
  v_account_biz uuid;
  v_paid bigint;
  v_new_status text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED' USING errcode = '28000';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'AMOUNT_INVALID' USING errcode = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.business_members
    WHERE business_id = p_business_id AND user_id = v_uid
      AND status = 'active' AND role IN ('owner','admin','cashier')
  ) THEN
    RAISE EXCEPTION 'NOT_A_MEMBER' USING errcode = '28000';
  END IF;

  SELECT business_id, status, total_amount 
    INTO v_order_biz, v_order_status, v_order_total
    FROM public.orders WHERE id = p_order_id;
  IF v_order_biz IS NULL OR v_order_biz <> p_business_id THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND' USING errcode = 'P0002';
  END IF;
  IF v_order_status = 'cancelled' THEN
    RAISE EXCEPTION 'ORDER_CANCELLED' USING errcode = '22023';
  END IF;

  IF p_payment_method_id IS NOT NULL THEN
    SELECT business_id INTO v_method_biz FROM public.payment_methods WHERE id = p_payment_method_id;
    IF v_method_biz IS NULL OR v_method_biz <> p_business_id THEN
      RAISE EXCEPTION 'PAYMENT_METHOD_INVALID' USING errcode = '22023';
    END IF;
  END IF;

  IF p_account_id IS NOT NULL THEN
    SELECT business_id INTO v_account_biz FROM public.accounts WHERE id = p_account_id;
    IF v_account_biz IS NULL OR v_account_biz <> p_business_id THEN
      RAISE EXCEPTION 'ACCOUNT_INVALID' USING errcode = '22023';
    END IF;
  END IF;

  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_existing_id FROM public.payments
      WHERE business_id = p_business_id AND idempotency_key = p_idempotency_key LIMIT 1;
    IF v_existing_id IS NOT NULL THEN
      RETURN v_existing_id;
    END IF;
  END IF;

  -- Hitung sisa tagihan & split applied/excess
  SELECT GREATEST(0, v_order_total - public.order_paid_amount(p_order_id)) INTO v_sisa;
  v_applied := LEAST(p_amount, v_sisa);
  v_excess := p_amount - v_applied;

  -- Insert payment
  INSERT INTO public.payments (
    business_id, order_id, amount, applied_amount, currency, payment_date,
    payment_method_id, account_id, reference, notes,
    status, idempotency_key, confirmed_at, confirmed_by, created_by
  ) VALUES (
    p_business_id, p_order_id, p_amount, v_applied, 'IDR',
    COALESCE(p_payment_date, current_date),
    p_payment_method_id, p_account_id, p_reference, p_notes,
    'confirmed', p_idempotency_key, now(), v_uid, v_uid
  ) RETURNING id INTO v_payment_id;

  -- Catat excess ke tabel terpisah (jika ada)
  IF v_excess > 0 THEN
    INSERT INTO public.payment_excesses (
      business_id, payment_id, order_id, amount, status, notes
    ) VALUES (
      p_business_id, v_payment_id, p_order_id, v_excess, 'kept_as_income',
      'Kelebihan bayar dari payment ' || v_payment_id::text
    );
  END IF;

  -- Update order
  v_paid := public.order_paid_amount(p_order_id);
  v_new_status := public.order_payment_status(p_order_id);
  UPDATE public.orders SET paid_amount = v_paid, payment_status = v_new_status WHERE id = p_order_id;

  -- Audit
  INSERT INTO public.audit_logs (business_id, actor_id, action, entity_type, entity_id, payload)
  VALUES (p_business_id, v_uid, 'payment.recorded', 'payments', v_payment_id,
    jsonb_build_object('order_id', p_order_id, 'amount', p_amount, 'applied', v_applied, 'excess', v_excess));

  RETURN v_payment_id;
END;
$$;

-- 7. Update cash_flow_summary: pisahkan cash vs applied, tambah total_excess
CREATE OR REPLACE FUNCTION public.cash_flow_summary(
  p_business_id uuid, p_from date, p_to date
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
  v_income bigint;
  v_expense bigint;
  v_payments_cash bigint;
  v_payments_applied bigint;
  v_net bigint;
  v_omzet_kotor bigint;
  v_total_ongkir bigint;
  v_omzet_bersih bigint;
  v_laba_kotor bigint;
  v_piutang bigint;
  v_cash_in_hand bigint;
  v_total_excess bigint;
BEGIN
  SELECT COALESCE(SUM(amount),0) INTO v_income FROM transactions
    WHERE business_id=p_business_id AND type='income' AND status='confirmed'
      AND transaction_date BETWEEN p_from AND p_to;
  SELECT COALESCE(SUM(amount),0) INTO v_expense FROM transactions
    WHERE business_id=p_business_id AND type='expense' AND status='confirmed'
      AND transaction_date BETWEEN p_from AND p_to;
  
  -- Cash: pakai amount (uang fisik masuk). Applied: pakai applied_amount (masuk pesanan)
  SELECT COALESCE(SUM(CASE WHEN reversal_of_payment_id IS NULL THEN amount ELSE -amount END),0),
         COALESCE(SUM(CASE WHEN reversal_of_payment_id IS NULL THEN COALESCE(applied_amount,amount) ELSE -COALESCE(applied_amount,amount) END),0)
    INTO v_payments_cash, v_payments_applied
    FROM payments WHERE business_id=p_business_id AND status='confirmed'
      AND payment_date BETWEEN p_from AND p_to;
  
  v_net := v_income + v_payments_applied - v_expense;
  
  SELECT COALESCE(SUM(total_amount),0), COALESCE(SUM(shipping_amount),0)
    INTO v_omzet_kotor, v_total_ongkir
    FROM orders WHERE business_id=p_business_id AND status='active'
      AND order_date BETWEEN p_from AND p_to;
  
  v_omzet_bersih := v_omzet_kotor - v_total_ongkir;
  v_laba_kotor := v_omzet_bersih - v_expense;
  
  SELECT COALESCE(SUM(total_amount - paid_amount),0) INTO v_piutang
    FROM orders WHERE business_id=p_business_id AND status='active'
      AND payment_status IN ('unpaid','partial') AND order_date BETWEEN p_from AND p_to;
  
  v_cash_in_hand := v_payments_cash + v_income - v_expense;
  
  -- Excess: hanya yang payment-nya confirmed (bukan reversal)
  SELECT COALESCE(SUM(pe.amount),0) INTO v_total_excess
    FROM payment_excesses pe
    JOIN payments p ON p.id = pe.payment_id
    WHERE pe.business_id=p_business_id 
      AND pe.status='kept_as_income'
      AND p.reversal_of_payment_id IS NULL
      AND pe.created_at::date BETWEEN p_from AND p_to;
  
  RETURN jsonb_build_object(
    'income', v_income, 'expense', v_expense,
    'payments_net', v_payments_applied, 'net', v_net,
    'omzet_kotor', v_omzet_kotor, 'total_ongkir', v_total_ongkir,
    'omzet_bersih', v_omzet_bersih, 'laba_kotor', v_laba_kotor,
    'piutang', v_piutang, 'cash_in_hand', v_cash_in_hand,
    'total_excess', v_total_excess
  );
END;
$$;

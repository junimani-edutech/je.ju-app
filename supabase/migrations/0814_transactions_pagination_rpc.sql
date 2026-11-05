CREATE INDEX IF NOT EXISTS idx_transactions_search 
  ON transactions (business_id, transaction_date DESC);

CREATE OR REPLACE FUNCTION list_transactions_page(
  p_business_id uuid,
  p_type text DEFAULT NULL,
  p_search text DEFAULT NULL,
  p_account_id uuid DEFAULT NULL,
  p_period text DEFAULT NULL,
  p_page int DEFAULT 0,
  p_page_size int DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
  v_offset int := p_page * p_page_size;
  v_items jsonb;
  v_total bigint;
  v_from date;
  v_to date;
BEGIN
  -- Hitung range tanggal berdasarkan periode
  IF p_period = 'this_month' THEN
    v_from := date_trunc('month', CURRENT_DATE)::date;
    v_to := CURRENT_DATE;
  ELSIF p_period = 'last_month' THEN
    v_from := (date_trunc('month', CURRENT_DATE) - interval '1 month')::date;
    v_to := (date_trunc('month', CURRENT_DATE) - interval '1 day')::date;
  END IF;
  
  -- Hitung total
  SELECT COUNT(*) INTO v_total
  FROM transactions t
  WHERE t.business_id = p_business_id
    AND (p_type IS NULL OR t.type = p_type)
    AND (p_account_id IS NULL OR t.account_id = p_account_id)
    AND (v_from IS NULL OR t.transaction_date >= v_from)
    AND (v_to IS NULL OR t.transaction_date <= v_to)
    AND (p_search IS NULL OR p_search = '' OR t.description ILIKE '%' || p_search || '%');
  
  -- Ambil data halaman
  SELECT jsonb_agg(row_json) INTO v_items
  FROM (
    SELECT jsonb_build_object(
      'id', t.id,
      'business_id', t.business_id,
      'type', t.type,
      'amount', t.amount,
      'currency', t.currency,
      'transaction_date', t.transaction_date,
      'description', t.description,
      'status', t.status,
      'created_at', t.created_at,
      'category_id', t.category_id,
      'account_id', t.account_id,
      'reference', t.reference,
      'reversal_of_transaction_id', t.reversal_of_transaction_id
    ) as row_json
    FROM transactions t
    WHERE t.business_id = p_business_id
      AND (p_type IS NULL OR t.type = p_type)
      AND (p_account_id IS NULL OR t.account_id = p_account_id)
      AND (v_from IS NULL OR t.transaction_date >= v_from)
      AND (v_to IS NULL OR t.transaction_date <= v_to)
      AND (p_search IS NULL OR p_search = '' OR t.description ILIKE '%' || p_search || '%')
    ORDER BY t.transaction_date DESC, t.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) sub;
  
  RETURN jsonb_build_object(
    'items', COALESCE(v_items, '[]'::jsonb),
    'total', v_total,
    'page', p_page,
    'has_more', (v_offset + p_page_size) < v_total
  );
END;
$$;

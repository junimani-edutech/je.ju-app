CREATE INDEX IF NOT EXISTS idx_orders_number_search ON orders (business_id, order_number);

CREATE OR REPLACE FUNCTION list_orders_page(
  p_business_id uuid,
  p_status_code text DEFAULT NULL,
  p_search text DEFAULT NULL,
  p_special_filter text DEFAULT NULL,
  p_page int DEFAULT 0,
  p_page_size int DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
  v_offset int := p_page * p_page_size;
  v_orders jsonb;
  v_total bigint;
  v_status_id uuid;
  v_include_cancelled boolean := (p_status_code = 'cancelled');
BEGIN
  IF p_status_code IS NOT NULL AND p_status_code NOT IN ('all', 'cancelled') THEN
    SELECT id INTO v_status_id
    FROM order_statuses
    WHERE business_id = p_business_id AND code = p_status_code
    LIMIT 1;
  END IF;
  
  SELECT COUNT(*) INTO v_total
  FROM orders o
  LEFT JOIN customers c ON c.id = o.customer_id
  WHERE o.business_id = p_business_id
    AND (
      (v_include_cancelled = true AND o.status = 'cancelled')
      OR (v_include_cancelled = false AND o.status = 'active')
    )
    AND (v_status_id IS NULL OR o.order_status_id = v_status_id)
    AND (p_search IS NULL OR p_search = '' OR 
         o.order_number ILIKE '%' || p_search || '%' OR
         o.notes ILIKE '%' || p_search || '%' OR
         c.name ILIKE '%' || p_search || '%')
    AND (
      p_special_filter IS NULL 
      OR (p_special_filter = 'deadline' 
          AND o.due_date = CURRENT_DATE
          AND o.order_status_id NOT IN (SELECT id FROM order_statuses WHERE business_id = p_business_id AND code = 'done'))
      OR (p_special_filter = 'late' 
          AND o.due_date < CURRENT_DATE
          AND o.order_status_id NOT IN (SELECT id FROM order_statuses WHERE business_id = p_business_id AND code = 'done'))
    );
  
  SELECT jsonb_agg(row_json) INTO v_orders
  FROM (
    SELECT jsonb_build_object(
      'id', o.id,
      'business_id', o.business_id,
      'order_number', o.order_number,
      'customer_id', o.customer_id,
      'customer_name', c.name,
      'order_date', o.order_date,
      'due_date', o.due_date,
      'subtotal_amount', o.subtotal_amount,
      'discount_amount', o.discount_amount,
      'additional_fee_amount', o.additional_fee_amount,
      'shipping_amount', o.shipping_amount,
      'total_amount', o.total_amount,
      'paid_amount', o.paid_amount,
      'currency', o.currency,
      'notes', o.notes,
      'order_status_id', o.order_status_id,
      'payment_status', o.payment_status,
      'status', o.status,
      'created_at', o.created_at,
      'updated_at', o.updated_at
    ) as row_json
    FROM orders o
    LEFT JOIN customers c ON c.id = o.customer_id
    WHERE o.business_id = p_business_id
      AND (
        (v_include_cancelled = true AND o.status = 'cancelled')
        OR (v_include_cancelled = false AND o.status = 'active')
      )
      AND (v_status_id IS NULL OR o.order_status_id = v_status_id)
      AND (p_search IS NULL OR p_search = '' OR 
           o.order_number ILIKE '%' || p_search || '%' OR
           o.notes ILIKE '%' || p_search || '%' OR
           c.name ILIKE '%' || p_search || '%')
      AND (
        p_special_filter IS NULL 
        OR (p_special_filter = 'deadline' 
            AND o.due_date = CURRENT_DATE
            AND o.order_status_id NOT IN (SELECT id FROM order_statuses WHERE business_id = p_business_id AND code = 'done'))
        OR (p_special_filter = 'late' 
            AND o.due_date < CURRENT_DATE
            AND o.order_status_id NOT IN (SELECT id FROM order_statuses WHERE business_id = p_business_id AND code = 'done'))
      )
    ORDER BY o.order_date DESC, o.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) sub;
  
  RETURN jsonb_build_object(
    'items', COALESCE(v_orders, '[]'::jsonb),
    'total', v_total,
    'page', p_page,
    'has_more', (v_offset + p_page_size) < v_total
  );
END;
$$;

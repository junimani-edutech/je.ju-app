CREATE OR REPLACE FUNCTION get_business_backup(p_business_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'exported_at', now(),
    'app_version', '1.1.0',
    'business', (SELECT jsonb_agg(b) FROM businesses b WHERE id = p_business_id),
    'customers', (SELECT jsonb_agg(c) FROM customers c WHERE business_id = p_business_id),
    'orders', (SELECT jsonb_agg(o) FROM orders o WHERE business_id = p_business_id),
    'order_items', (SELECT jsonb_agg(oi) FROM order_items oi JOIN orders o ON o.id = oi.order_id WHERE o.business_id = p_business_id),
    'products', (SELECT jsonb_agg(p) FROM products p WHERE business_id = p_business_id),
    'payments', (SELECT jsonb_agg(p) FROM payments p WHERE business_id = p_business_id),
    'transactions', (SELECT jsonb_agg(t) FROM transactions t WHERE business_id = p_business_id),
    'transfers', (SELECT jsonb_agg(t) FROM transfers t WHERE business_id = p_business_id),
    'inventory_items', (SELECT jsonb_agg(i) FROM inventory_items i WHERE business_id = p_business_id),
    'order_statuses', (SELECT jsonb_agg(s) FROM order_statuses s WHERE business_id = p_business_id)
  ) INTO result;
  
  RETURN result;
END;
$$;

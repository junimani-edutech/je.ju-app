CREATE OR REPLACE FUNCTION get_top_products(p_business_id uuid, p_limit int DEFAULT 10)
RETURNS TABLE(product_id uuid, description text, total_qty numeric, total_revenue bigint)
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT 
    oi.product_id,
    oi.description,
    SUM(oi.quantity) as total_qty,
    SUM(oi.line_total)::bigint as total_revenue
  FROM order_items oi
  JOIN orders o ON o.id = oi.order_id
  WHERE o.business_id = p_business_id
    AND o.status != 'cancelled'
    AND oi.product_id IS NOT NULL
  GROUP BY oi.product_id, oi.description
  ORDER BY total_qty DESC
  LIMIT p_limit;
$$;

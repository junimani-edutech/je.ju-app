CREATE OR REPLACE FUNCTION get_sales_by_staff(
  p_business_id uuid,
  p_from date,
  p_to date
)
RETURNS TABLE(
  actor_id uuid,
  actor_name text,
  orders_count bigint,
  orders_total bigint,
  orders_paid bigint
)
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.created_by,
    COALESCE(p.full_name, p.email, 'Sistem/Tidak Diketahui')::text,
    COUNT(o.id)::bigint,
    COALESCE(SUM(o.total_amount), 0)::bigint,
    COALESCE(SUM(o.paid_amount), 0)::bigint
  FROM public.orders o
  LEFT JOIN public.profiles p ON p.id = o.created_by
  WHERE o.business_id = p_business_id
    AND o.status != 'cancelled'
    AND o.order_date BETWEEN p_from AND p_to
  GROUP BY o.created_by, p.full_name, p.email
  ORDER BY 4 DESC;
END;
$$;

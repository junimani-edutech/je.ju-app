CREATE INDEX IF NOT EXISTS idx_customers_name_search ON customers (business_id, name);

CREATE OR REPLACE FUNCTION list_customers_page(
  p_business_id uuid,
  p_search text DEFAULT NULL,
  p_include_archived boolean DEFAULT false,
  p_page int DEFAULT 0,
  p_page_size int DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE
  v_offset int := p_page * p_page_size;
  v_items jsonb;
  v_total bigint;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM customers c
  WHERE c.business_id = p_business_id
    AND (
      (p_include_archived = true AND c.status = 'archived')
      OR (p_include_archived = false AND c.status = 'active')
    )
    AND (p_search IS NULL OR p_search = '' OR
         c.name ILIKE '%' || p_search || '%' OR
         c.phone ILIKE '%' || p_search || '%' OR
         c.email ILIKE '%' || p_search || '%');
  
  SELECT jsonb_agg(row_json) INTO v_items
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'business_id', c.business_id,
      'name', c.name,
      'phone', c.phone,
      'email', c.email,
      'address', c.address,
      'notes', c.notes,
      'status', c.status,
      'created_at', c.created_at,
      'updated_at', c.updated_at
    ) as row_json
    FROM customers c
    WHERE c.business_id = p_business_id
      AND (
        (p_include_archived = true AND c.status = 'archived')
        OR (p_include_archived = false AND c.status = 'active')
      )
      AND (p_search IS NULL OR p_search = '' OR
           c.name ILIKE '%' || p_search || '%' OR
           c.phone ILIKE '%' || p_search || '%' OR
           c.email ILIKE '%' || p_search || '%')
    ORDER BY c.name ASC
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

CREATE OR REPLACE FUNCTION list_products_page(
  p_business_id uuid,
  p_search text DEFAULT NULL,
  p_category text DEFAULT NULL,
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
  FROM products p
  WHERE p.business_id = p_business_id
    AND (
      (p_include_archived = true AND p.status = 'archived')
      OR (p_include_archived = false AND p.status = 'active')
    )
    AND (p_search IS NULL OR p_search = '' OR p.name ILIKE '%' || p_search || '%')
    AND (p_category IS NULL OR p_category = '' OR p_category = 'Semua' OR p.category = p_category);
  
  SELECT jsonb_agg(row_json) INTO v_items
  FROM (
    SELECT jsonb_build_object(
      'id', p.id,
      'business_id', p.business_id,
      'name', p.name,
      'price', p.price,
      'description', p.description,
      'category', p.category,
      'status', p.status,
      'created_at', p.created_at,
      'updated_at', p.updated_at
    ) as row_json
    FROM products p
    WHERE p.business_id = p_business_id
      AND (
        (p_include_archived = true AND p.status = 'archived')
        OR (p_include_archived = false AND p.status = 'active')
      )
      AND (p_search IS NULL OR p_search = '' OR p.name ILIKE '%' || p_search || '%')
      AND (p_category IS NULL OR p_category = '' OR p_category = 'Semua' OR p.category = p_category)
    ORDER BY p.name ASC
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

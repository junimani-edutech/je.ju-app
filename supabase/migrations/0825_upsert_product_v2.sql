CREATE OR REPLACE FUNCTION upsert_product(
  p_id uuid,
  p_business_id uuid,
  p_name text,
  p_price bigint,
  p_description text DEFAULT NULL,
  p_status text DEFAULT 'active',
  p_category text DEFAULT 'Umum',
  p_category_id uuid DEFAULT NULL
)
RETURNS products
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_product products;
BEGIN
  IF p_id IS NULL OR p_id = '00000000-0000-0000-0000-000000000000'::uuid THEN
    INSERT INTO products (business_id, name, price, description, status, category, category_id)
    VALUES (p_business_id, p_name, p_price, p_description, p_status, p_category, p_category_id)
    RETURNING * INTO v_product;
  ELSE
    UPDATE products
    SET name = p_name,
        price = p_price,
        description = p_description,
        status = p_status,
        category = p_category,
        category_id = p_category_id,
        updated_at = now()
    WHERE id = p_id AND business_id = p_business_id
    RETURNING * INTO v_product;
  END IF;
  RETURN v_product;
END;
$$;

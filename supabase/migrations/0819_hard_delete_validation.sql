-- Fungsi cek apakah produk bisa dihapus permanen (tidak dipakai di order_items)
CREATE OR REPLACE FUNCTION can_hard_delete_product(p_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (SELECT 1 FROM order_items WHERE product_id = p_id);
$$;

-- Fungsi cek apakah pelanggan bisa dihapus permanen (tidak punya pesanan)
CREATE OR REPLACE FUNCTION can_hard_delete_customer(p_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (SELECT 1 FROM orders WHERE customer_id = p_id);
$$;

GRANT EXECUTE ON FUNCTION can_hard_delete_product(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION can_hard_delete_customer(uuid) TO authenticated;

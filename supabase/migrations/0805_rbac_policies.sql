-- Helper: Cek apakah user punya role tertentu di bisnis tertentu
-- PERBAIKAN: Menambahkan ::text pada kolom role untuk mencocokkan dengan parameter text[]
CREATE OR REPLACE FUNCTION has_business_role(p_business_id uuid, p_roles text[])
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM business_members
    WHERE business_id = p_business_id AND user_id = auth.uid() AND role::text = ANY(p_roles)
  );
$$;

-- Terapkan ke tabel Orders (Contoh, terapkan juga ke tabel lain)
DROP POLICY IF EXISTS "orders_insert_writer" ON orders;
CREATE POLICY "orders_insert_writer" ON orders FOR INSERT WITH CHECK (
  has_business_role(business_id, ARRAY['owner', 'admin', 'cashier', 'order_staff'])
);

DROP POLICY IF EXISTS "orders_delete_admin" ON orders;
CREATE POLICY "orders_delete_admin" ON orders FOR DELETE USING (
  has_business_role(business_id, ARRAY['owner', 'admin'])
);

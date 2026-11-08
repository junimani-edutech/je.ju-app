-- 1. Tabel kategori produk
CREATE TABLE IF NOT EXISTS public.product_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text DEFAULT '#607D8B',
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(business_id, name)
);

CREATE INDEX IF NOT EXISTS idx_product_categories_business 
  ON product_categories(business_id, sort_order, name);

-- 2. Kolom category_id di products
ALTER TABLE public.products 
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.product_categories(id) ON DELETE SET NULL;

-- 3. Seed kategori default (dari kategori hardcoded lama)
INSERT INTO public.product_categories (business_id, name, sort_order)
SELECT b.id, cat.name, cat.ord
FROM businesses b
CROSS JOIN (VALUES 
  ('Umum', 1), 
  ('Cuci Kering', 2), 
  ('Cuci Setrika', 3), 
  ('Setrika', 4), 
  ('Bed Cover', 5), 
  ('Sepatu', 6), 
  ('Lainnya', 7)
) AS cat(name, ord)
WHERE NOT EXISTS (
  SELECT 1 FROM product_categories pc 
  WHERE pc.business_id = b.id AND pc.name = cat.name
);

-- 4. Backfill: link category_id untuk produk lama
UPDATE products p
SET category_id = pc.id
FROM product_categories pc
WHERE p.business_id = pc.business_id
  AND p.category = pc.name
  AND p.category_id IS NULL;

-- 5. Trigger cascade rename
CREATE OR REPLACE FUNCTION sync_product_category_name()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    UPDATE products 
    SET category = NEW.name 
    WHERE category_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_product_category ON product_categories;
CREATE TRIGGER trg_sync_product_category
  AFTER UPDATE ON product_categories
  FOR EACH ROW EXECUTE FUNCTION sync_product_category_name();

-- 6. RLS
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "prod_cat_select" ON product_categories;
CREATE POLICY "prod_cat_select" ON product_categories FOR SELECT USING (
  business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "prod_cat_insert" ON product_categories;
CREATE POLICY "prod_cat_insert" ON product_categories FOR INSERT WITH CHECK (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

DROP POLICY IF EXISTS "prod_cat_update" ON product_categories;
CREATE POLICY "prod_cat_update" ON product_categories FOR UPDATE USING (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

DROP POLICY IF EXISTS "prod_cat_delete" ON product_categories;
CREATE POLICY "prod_cat_delete" ON product_categories FOR DELETE USING (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin'))
);

-- Tabel kategori inventaris
CREATE TABLE IF NOT EXISTS public.inventory_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  color text DEFAULT '#607D8B',
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(business_id, name)
);

CREATE INDEX IF NOT EXISTS idx_inv_categories_business 
  ON inventory_categories(business_id, sort_order, name);

-- Kolom category_id (nullable untuk backward compat)
ALTER TABLE public.inventory_items 
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.inventory_categories(id) ON DELETE SET NULL;

-- RLS
ALTER TABLE public.inventory_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inv_cat_select" ON public.inventory_categories;
CREATE POLICY "inv_cat_select" ON public.inventory_categories FOR SELECT USING (
  business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "inv_cat_insert" ON public.inventory_categories;
CREATE POLICY "inv_cat_insert" ON public.inventory_categories FOR INSERT WITH CHECK (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

DROP POLICY IF EXISTS "inv_cat_update" ON public.inventory_categories;
CREATE POLICY "inv_cat_update" ON public.inventory_categories FOR UPDATE USING (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

DROP POLICY IF EXISTS "inv_cat_delete" ON public.inventory_categories;
CREATE POLICY "inv_cat_delete" ON public.inventory_categories FOR DELETE USING (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin'))
);

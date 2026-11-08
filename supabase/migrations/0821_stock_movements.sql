-- =====================================================
-- v1.2: Stock Movement System (Foundation)
-- Prinsip: current_stock = SUM(quantity) dari movements
-- =====================================================

-- 1. Tabel
CREATE TABLE IF NOT EXISTS public.stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  inventory_item_id uuid NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  movement_type text NOT NULL CHECK (movement_type IN ('initial','purchase','usage','waste','adjustment','return')),
  quantity numeric NOT NULL CHECK (quantity != 0),
  notes text,
  reference_id uuid,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_movements_business_date 
  ON stock_movements(business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_movements_item_date 
  ON stock_movements(inventory_item_id, created_at DESC);

-- 2. RLS
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "movements_select" ON stock_movements;
CREATE POLICY "movements_select" ON stock_movements FOR SELECT USING (
  business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "movements_insert" ON stock_movements;
CREATE POLICY "movements_insert" ON stock_movements FOR INSERT WITH CHECK (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin','cashier'))
);

DROP POLICY IF EXISTS "movements_delete" ON stock_movements;
CREATE POLICY "movements_delete" ON stock_movements FOR DELETE USING (
  business_id IN (SELECT business_id FROM business_members 
    WHERE user_id = auth.uid() AND status='active' AND role IN ('owner','admin'))
);

-- 3. Trigger: recalculate current_stock dari SUM movements
CREATE OR REPLACE FUNCTION public.update_stock_from_movement()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item_id uuid;
BEGIN
  v_item_id := COALESCE(NEW.inventory_item_id, OLD.inventory_item_id);
  
  UPDATE inventory_items 
  SET current_stock = COALESCE((
    SELECT SUM(quantity) FROM stock_movements WHERE inventory_item_id = v_item_id
  ), 0)
  WHERE id = v_item_id;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_movement ON stock_movements;
CREATE TRIGGER trg_stock_movement
  AFTER INSERT OR UPDATE OR DELETE ON stock_movements
  FOR EACH ROW EXECUTE FUNCTION public.update_stock_from_movement();

-- 4. Backfill: stok existing → 1 movement 'initial'
INSERT INTO stock_movements (business_id, inventory_item_id, movement_type, quantity, notes)
SELECT 
  ii.business_id, 
  ii.id, 
  'initial', 
  ii.current_stock,
  'Stok awal saat migrasi ke sistem Stock Movement'
FROM inventory_items ii
WHERE ii.current_stock != 0
  AND NOT EXISTS (
    SELECT 1 FROM stock_movements sm WHERE sm.inventory_item_id = ii.id
  );

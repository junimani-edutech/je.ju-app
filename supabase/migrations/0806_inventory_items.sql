CREATE TABLE IF NOT EXISTS inventory_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name text NOT NULL,
    category text,
    unit text NOT NULL DEFAULT 'Pcs', -- Liter, Kg, Pcs, Pack, dll.
    current_stock numeric NOT NULL DEFAULT 0,
    min_stock numeric NOT NULL DEFAULT 0,
    price_per_unit bigint NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "inventory_select" ON inventory_items FOR SELECT USING (
    business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid())
);
CREATE POLICY "inventory_insert" ON inventory_items FOR INSERT WITH CHECK (
    business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'cashier'))
);
CREATE POLICY "inventory_update" ON inventory_items FOR UPDATE USING (
    business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin', 'cashier'))
);
CREATE POLICY "inventory_delete" ON inventory_items FOR DELETE USING (
    business_id IN (SELECT business_id FROM business_members WHERE user_id = auth.uid() AND role IN ('owner', 'admin'))
);

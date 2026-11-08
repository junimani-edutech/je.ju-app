-- 1. Seed kategori default untuk semua bisnis yang belum punya
INSERT INTO inventory_categories (business_id, name, sort_order)
SELECT b.id, cat.name, cat.ord
FROM businesses b
CROSS JOIN (VALUES 
  ('Deterjen', 1), 
  ('Pewangi', 2), 
  ('Pembersih', 3), 
  ('Plastik', 4), 
  ('Lainnya', 5)
) AS cat(name, ord)
WHERE NOT EXISTS (
  SELECT 1 FROM inventory_categories ic 
  WHERE ic.business_id = b.id AND ic.name = cat.name
);

-- 2. Backfill: item yang punya category text tapi belum punya category_id
UPDATE inventory_items ii
SET category_id = ic.id
FROM inventory_categories ic
WHERE ii.business_id = ic.business_id
  AND ii.category = ic.name
  AND ii.category_id IS NULL;

-- 3. Trigger: sync name ke items saat kategori di-rename
CREATE OR REPLACE FUNCTION sync_category_name_to_items()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    UPDATE inventory_items 
    SET category = NEW.name 
    WHERE category_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_category_name ON inventory_categories;
CREATE TRIGGER trg_sync_category_name
  AFTER UPDATE ON inventory_categories
  FOR EACH ROW EXECUTE FUNCTION sync_category_name_to_items();

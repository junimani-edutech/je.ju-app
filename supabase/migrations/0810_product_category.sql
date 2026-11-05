-- Tambah kolom category ke tabel products
ALTER TABLE products ADD COLUMN IF NOT EXISTS category text DEFAULT 'Umum';

-- Index untuk performa filter
CREATE INDEX IF NOT EXISTS idx_products_category ON products(business_id, category);

-- Seed kategori default untuk bisnis laundry (opsional, hanya contoh)
UPDATE products SET category = 'Umum' WHERE category IS NULL;

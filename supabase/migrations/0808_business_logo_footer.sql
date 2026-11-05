-- 1. Tambah kolom di businesses
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS receipt_footer text;

-- 2. Buat storage bucket untuk logo (public)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('business-logos', 'business-logos', true)
ON CONFLICT (id) DO NOTHING;

-- 3. RLS untuk bucket (siapa saja bisa baca, hanya user login yang bisa upload)
DROP POLICY IF EXISTS "Public read logos" ON storage.objects;
CREATE POLICY "Public read logos" ON storage.objects FOR SELECT USING (bucket_id = 'business-logos');

DROP POLICY IF EXISTS "Auth users can upload logos" ON storage.objects;
CREATE POLICY "Auth users can upload logos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'business-logos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth users can update logos" ON storage.objects;
CREATE POLICY "Auth users can update logos" ON storage.objects FOR UPDATE USING (bucket_id = 'business-logos' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth users can delete logos" ON storage.objects;
CREATE POLICY "Auth users can delete logos" ON storage.objects FOR DELETE USING (bucket_id = 'business-logos' AND auth.role() = 'authenticated');

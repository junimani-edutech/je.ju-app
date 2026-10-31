# CHANGELOG.md

## 2026-11-01

### Added
- `docs/REQUIREMENTS.md` dari spesifikasi JeJu v1.0.
- `AGENTS.md` sebagai aturan kerja AI.
- `DECISIONS.md` sebagai daftar keputusan proyek.
- `CURRENT_STATE.md` sebagai status proyek.
- `CHANGELOG.md` sebagai log perubahan.
- `MASTER_BLUEPRINT.md` sebagai stub blueprint awal.

### Changed
- Tidak ada.

### Removed
- Tidak ada.

### Tests
- Belum ada kode aplikasi. Tidak ada tes yang dijalankan.


## 2026-11-01 — Fase 1: Flutter init

### Added
- Flutter project `jeju_app` di root repo (org `com.jeju`).
- Platform: android, ios, web, linux, macos, windows.
- Dependensi: `supabase_flutter`, `flutter_dotenv`.
- `lib/main.dart` dengan `JeJuApp` (Material 3, seed green).
- `test/widget_test.dart` dasar.
- `.env.example` dan entri `.gitignore` untuk `.env`/`supabase/.temp/`.
- Struktur folder: `lib/core/{config,constants,theme}`, `lib/features`, `lib/shared/widgets`.

### Changed
- `CURRENT_STATE.md` diperbarui ke Fase 1.
- `DECISIONS.md` sebelumnya diperbarui (D-01/02/03/04/07 APPROVED).

### Tests
- `dart format lib test` — lihat log terminal.
- `flutter analyze` — lihat log terminal.
- `flutter test` — lihat log terminal.
- Tidak ada klaim lulus tanpa log yang sesuai.

## 2026-11-01 — Fase 1: Supabase lokal + verifikasi migration

### Added
- Supabase CLI 2.122.0 terpasang di Codespace.
- `supabase/config.toml` dan `supabase/.gitignore` via `supabase init`.
- `psql` (postgresql-client-16) terpasang.

### Changed
- `20261101000000_initial_schema.sql` diverifikasi dapat diapply via `supabase db reset`.
- `CURRENT_STATE.md` diperbarui ke akhir Fase 1.

### Verified (lokal)
- `tables_total = 15`, `tables_rls_on = 15`
- `policy_total = 34`
- `is_business_member` = security definer (`prosecdef = true`)
- `business_role` = owner/admin/cashier/order_staff/viewer
- `member_status` = invited/active/suspended/removed
- Semua tabel tenant memiliki minimal 1 policy

### Tests
- `supabase db reset` sukses (output disalin dari terminal pengguna).
- Verifikasi via psql dijalankan oleh pengguna dan sesuai kriteria.

### Notes
- Warning `no files matched pattern: supabase/seed.sql` bukan error; seed.sql belum dibuat.

## 2026-11-01 — Fase 1: pgTAP RLS isolation test (Langkah 6)

### Added
- `supabase/tests/rls_isolation.sql` — pgTAP test self-contained untuk isolasi RLS.
  - 10 assertion: 2 tabel, 2 RLS-enabled, 3 isolasi select, 1 write isolation, dst.
  - Fixture di dalam transaksi, diakhiri `rollback`.

### Tests
- `supabase test db` — All tests successful (10 tests), sesuai output terminal pengguna.
- Tidak ada klaim lulus tanpa log yang sesuai.

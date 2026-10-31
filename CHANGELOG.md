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

## 2026-11-01 — Fase 1: auth backend & onboarding (Langkah 7A)

### Added
- Migration `20261101010000_auth_profile_and_business_onboarding.sql`:
  - Trigger `on_auth_user_created` → auto-create `public.profiles` (SECURITY DEFINER).
  - `public.set_updated_at()` trigger untuk `profiles`, `businesses`, `business_members`.
  - RPC `public.create_business_with_owner(p_name, p_timezone)` SECURITY DEFINER, atomik.
  - Grant EXECUTE hanya ke `authenticated`.
- Tes `supabase/tests/auth_onboarding.sql` (17 pgTAP assertions).

### Changed
- Tidak mengubah migration 0000.
- Tidak menambah seed default saat bisnis baru (menunggu Q1).

### Tests
- `supabase db reset` — apply 2 migration, sukses (log terminal pengguna).
- `supabase test db` — 2 file tes, 27 tests, `All tests successful`.

### Notes
- RPC idempotency belum ada; UI Langkah 7B wajib disable submit selama request.
- Seed `order_statuses`/`payment_methods`/`categories`/`accounts` default belum.

## 2026-11-01 — Fase 1: Flutter auth UI + onboarding (Langkah 7B)

### Added
- `lib/core/models/app_user.dart`.
- `lib/core/auth/{auth_service,supabase_auth_service}.dart`.
- `lib/core/business/{business_service,supabase_business_service}.dart`.
- `lib/core/providers.dart` (authService, businessService, authState, hasBusiness).
- `lib/router/app_router.dart` (go_router + redirect auth & onboarding).
- `lib/app.dart` (JeJuApp ConsumerWidget).
- `lib/features/auth/{sign_in_screen,sign_up_screen}.dart`.
- `lib/features/onboarding/onboarding_screen.dart`.
- `lib/features/home/home_screen.dart`.
- Dependensi: `flutter_riverpod`, `go_router`.
- `test/fake/fake_services.dart` (reusable fakes).
- `test/features/auth/auth_flow_test.dart` (4 tests).
- `test/features/onboarding/onboarding_test.dart` (3 tests).

### Changed
- `lib/main.dart` di-rewrite: load `.env`, init Supabase, override providers.
- `test/widget_test.dart` diganti smoke test (unauthenticated → sign-in).
- Riverpod 3.x: `AsyncValue.valueOrNull` → `.value`.
- `Supabase.initialize(anonKey:...)` di-suppress deprecation sampai kita bump SDK.
- Asersi onboarding_test: `find.text('Buat Usaha')` dari `findsOneWidget` → `findsWidgets`
  karena AppBar dan tombol berbagi teks yang sama.

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 8 tests passed (1 smoke + 4 auth + 3 onboarding).
- `supabase test db` (Langkah 7A) tetap 27 tests PASS; migration baru tidak berubah.

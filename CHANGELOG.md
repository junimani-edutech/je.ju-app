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

## 2026-11-01 — Fase 3: kerangka UI + adaptive app shell (Langkah 8)

### Added
- `lib/core/theme/app_theme.dart` (light + dark, seed `#2E7D32`).
- `lib/core/theme/theme_mode_provider.dart` (Riverpod 3.x `NotifierProvider`).
- `lib/shared/widgets/coming_soon_screen.dart` (placeholder reusable).
- `lib/shared/widgets/app_shell.dart` (adaptive NavigationBar / NavigationRail).
- `lib/features/dashboard/dashboard_screen.dart` (ringkasan placeholder).
- `lib/features/customers/customers_screen.dart`.
- `lib/features/orders/orders_screen.dart`.
- `lib/features/payments/payments_screen.dart`.
- `lib/features/reports/reports_screen.dart`.
- `lib/features/settings/settings_screen.dart` (sign out di sini).
- `lib/features/more/more_screen.dart` (menu ke Pembayaran/Laporan/Pengaturan/SignOut).
- `test/features/shell/navigation_test.dart` (5 tests: 3 mobile, 2 wide).

### Changed
- `lib/router/app_router.dart` di-rewrite: `StatefulShellRoute.indexedStack` dengan 4 branch, redirect diperluas.
- `lib/app.dart` pakai `AppTheme` + `themeModeProvider`.
- `test/features/onboarding/onboarding_test.dart` test #3: assertion pindah dari `HomeScreen` (`Selamat datang, <email>`) ke `DashboardScreen` (`Ringkasan` + email).
- `AGENTS.md` ditambah bagian "Frontend conventions (Flutter / Riverpod)".

### Removed
- `lib/features/home/home_screen.dart` (placeholder yang digantikan `DashboardScreen`).

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 13 tests passed (1 smoke + 4 auth + 3 onboarding + 5 navigasi).
- `supabase test db` (Langkah 7A) tetap 27 tests PASS; tidak ada perubahan backend.

## 2026-11-01 — Fase 4: Pelanggan + Q1 default order statuses (Langkah 9)

### Added
- Migration `20261101020000_created_by_triggers.sql`.
- Migration `20261101020100_seed_order_statuses_on_business_create.sql` (Q1 APPROVED) + backfill.
- Test `supabase/tests/order_statuses_seed.sql` (6 tests).
- `lib/core/models/business.dart`, `lib/core/models/business_member.dart`.
- `BusinessService.listMyBusinesses()`, `getMemberForCurrentUser(businessId)`.
- `currentBusinessProvider` dan `currentMemberProvider`.
- Fitur Customers lengkap (model, service, notifier, form sheet, list tile, screen).
- Widget test `test/features/customers/customers_screen_test.dart` (6 tests).

### Changed
- `test/widget_test.dart` pakai `FakeAuthService`/`FakeBusinessService` dari `test/fake/`.
- `test/fake/fake_services.dart`: `FakeBusinessService` implement 2 method baru; tambah `FakeCustomersService`.
- `main.dart`: override `customersServiceProvider`.
- `supabase/tests/rls_isolation.sql`: plan 10 → 13, tambah update/delete isolation.
- `docs/DATABASE_SCHEMA.md`: Q1 ditandai **APPROVED**.

### Removed
- Placeholder `CustomersScreen` lama.

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 19 tests passed.
- `supabase test db` — Files=3, Tests=36, Result: PASS.

## 2026-11-01 — Fase 4: Pelanggan + Q1 default order statuses (Langkah 9)

### Added
- Migration `20261101020000_created_by_triggers.sql`.
- Migration `20261101020100_seed_order_statuses_on_business_create.sql` (Q1 APPROVED) + backfill.
- Test `supabase/tests/order_statuses_seed.sql` (6 tests).
- `lib/core/models/business.dart`, `lib/core/models/business_member.dart`.
- `BusinessService.listMyBusinesses()`, `getMemberForCurrentUser(businessId)`.
- `currentBusinessProvider` dan `currentMemberProvider`.
- Fitur Customers lengkap (model, service, notifier, form sheet, list tile, screen).
- Widget test `test/features/customers/customers_screen_test.dart` (6 tests).

### Changed
- `test/widget_test.dart` pakai `FakeAuthService`/`FakeBusinessService` dari `test/fake/`.
- `test/fake/fake_services.dart`: `FakeBusinessService` implement 2 method baru; tambah `FakeCustomersService`.
- `main.dart`: override `customersServiceProvider`.
- `supabase/tests/rls_isolation.sql`: plan 10 → 13, tambah update/delete isolation.
- `docs/DATABASE_SCHEMA.md`: Q1 ditandai **APPROVED**.

### Removed
- Placeholder `CustomersScreen` lama.

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 19 tests passed.
- `supabase test db` — Files=3, Tests=36, Result: PASS.

## 2026-11-01 — Fase 4: Pesanan (Langkah 10)

### Added
- Migration `20261101030000_create_order_rpc.sql`: RPC `create_order` + `orders` updated_at trigger. Format `order_number` Q5-A (`YYYYMMDD-NNN` per bisnis/hari, advisory lock + unique).
- Migration `20261101030100_change_order_status_and_cancel_rpc.sql`: RPC `change_order_status` (menolak `cancelled`, harus via `cancel_order`) + `cancel_order` (menolak `ALREADY_CANCELLED`), keduanya menulis `order_status_history` atomik.
- pgTAP `create_order_rpc.sql` (11 test) + `change_order_status_rpc.sql` (12 test).
- `lib/features/orders/order.dart` (Order, OrderItem, OrderStatus, OrderItemInput).
- `lib/features/orders/orders_service.dart` + `supabase_orders_service.dart`.
- `lib/features/orders/orders_providers.dart` (`ordersServiceProvider`, `ordersProvider`, `orderStatusesProvider`).
- UI: `OrdersScreen` (tab filter, empty/loading/error), `OrderFormSheet` (item dinamis, subtotal real-time), `OrderListTile`, `OrderDetailSheet` (change status & cancel dialog).
- Widget test `test/features/orders/orders_screen_test.dart` (7 test).
- `test/fake/fake_services.dart`: `FakeOrdersService`.

### Changed
- `lib/main.dart`: override `ordersServiceProvider` di `ProviderScope`.
- `test/features/shell/navigation_test.dart`: pakai `OrdersScreen` nyata (bukan placeholder) + override `ordersServiceProvider` & `customersServiceProvider`.
- `docs/DATABASE_SCHEMA.md`: bagian RPC + format `order_number` Q5-A.
- `AGENTS.md`: konvensi pgTAP (hindari `order by created_at` di satu transaksi).

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 26 tests passed (1 smoke + 4 auth + 3 onboarding + 5 navigasi + 6 customers + 7 orders).
- `supabase test db` — Files=5, Tests=59, Result: PASS.

## 2026-11-01 — Fase 4: Pembayaran (Langkah 11)

### Added
- Migration `20261101040000_seed_payment_methods_and_accounts.sql`: seed default `payment_methods` (Cash/Transfer Bank/E-Wallet) + `accounts` (Kas Tunai/Rekening Bank/E-Wallet) saat bisnis dibuat (Q8-A) + backfill.
- Migration `20261101040100_record_void_payment_rpcs.sql`: RPC `record_payment`, `void_payment`, helper `order_paid_amount`, `order_payment_status`. Q3-A (satu payment per order), Q4-A (refund = payment baru + `reversal_of_payment_id`), E-01-A (recompute di RPC).
- pgTAP `payment_rpcs.sql` (25 tests): seed, happy path, idempotency, overpay, void, void-twice, void-reversal, role validation.
- Data layer: `lib/features/payments/{payment,payments_service,supabase_payments_service,payments_providers}.dart`. Model `Payment` (dengan `signedAmount`), `PaymentMethod`, `Account`. `paymentsControllerProvider` (`record`, `voidPayment`) + invalidate `paymentsForOrderProvider` & `ordersProvider`.
- UI: `PaymentFormSheet` (nominal default sisa tagihan, metode/akun optional), `PaymentListTile` (badge Reversal), `PaymentsSection` (list + tombol Catat/Void, role-gated, sembunyi saat cancelled).
- `OrderDetailSheet` reaktif terhadap `ordersProvider` (`liveOrder`) + menampilkan `PaymentsSection`. Field `_kv('Dibayar', ...)` baru.
- Widget test `test/features/payments/payments_test.dart` (5 tests).

### Changed
- `lib/main.dart`: override `paymentsServiceProvider` di `ProviderScope`.
- `lib/features/orders/widgets/order_detail_sheet.dart`: rewrite — `liveOrder`, `PaymentsSection`, tombol Void/Catat.
- `test/fake/fake_services.dart`: `FakePaymentsService` (record/void/list, in-memory).
- `docs/DATABASE_SCHEMA.md`: RPC `record_payment`, `void_payment`, helper, seed default.
- `AGENTS.md`: bagian "Flutter dialog & controller pitfalls".

### Fixed
- Crash `A TextEditingController was used after being disposed` di `payments_section.dart` / `order_detail_sheet.dart` saat dialog close. Root cause: `dispose()` pada controller yang dibuat di method sebelum dialog selesai animasi close. Fix: hapus `dispose()` (leak minor, dicatat sebagai technical debt).

### Tests
- `flutter analyze` — No issues found.
- `flutter test` — 31 tests passed.
- `supabase test db` — Files=6, Tests=84, Result: PASS.

### Known limitations (technical debt)
- Idempotency key belum dipakai di UI form (hanya disable tombol).
- `FakeOrdersService` tidak merecompute `paid_amount` (Supabase asli RPC melakukannya).
- Controller di dialog one-shot tidak di-dispose.
- Dialog change status / cancel order belum punya widget test.

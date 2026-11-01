# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 5 — Keuangan (selesai). Siap masuk Fase 6 (Laporan/Pengaturan/Ekspor).

## Sudah selesai

- Fase 1: skema, auth backend, auth UI, onboarding.
- Fase 2: RLS + pgTAP isolasi.
- Fase 3: app shell adaptif + theme light/dark.
- Fase 4 — Pelanggan, Pesanan, Pembayaran.
- **Fase 5 — Keuangan:**
  - Migration 0500: fix `void_payment` menyalin `payment_method_id` & `account_id` (F5-04-A).
  - Migration 0501: RPC `record_transaction`, `void_transaction`, `record_transfer`, `void_transfer`, helper `account_balance`, `cash_flow_summary` (F5-01-A, F5-02-A, F5-03-A).
  - Migration 0502: RPC `account_balances` (bulk untuk dashboard).
  - Data layer: models `Transaction`, `Transfer`, `Category`, `AccountBalance`, `CashFlowSummary`; services `TransactionsService`, `TransfersService` + impl Supabase.
  - Providers: `transactionsProvider`, `transfersProvider`, `financeCategoriesProvider`, `financeAccountsProvider`, `accountBalancesProvider`, `cashFlowSummaryProvider`.
  - UI: `TransactionsScreen` (3 tab: Semua/Masuk/Keluar), `TransfersScreen`, dashboard dengan stat cards + balance cards.
  - Widget test finance: 6 tests.
  - pgTAP: `transactions_rpcs.sql` (17), `transfers_cash_flow.sql` (16).
- **Total: 37 Flutter tests + 119 pgTAP tests.**

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- A-01..A-08, U-01..U-07, C-01..C-08: APPROVED.
- Q1, Q5-A: APPROVED.
- Q3-A, Q4-A, E-01-A, Q8-A: APPROVED.
- **F5-01-A, F5-02-A, F5-03-A, F5-04-A: APPROVED.**

## Pertanyaan terbuka (untuk Fase 6)

- **F6-01**: format ekspor awal — PDF saja, CSV saja, atau keduanya? Default: **keduanya**.
- **F6-02**: rekap laporan default — bulan berjalan atau last 30 days? Default: **bulan berjalan**.
- **F6-03**: setting nama bisnis / logo — form field saja atau upload logo? Default: **form field saja**, upload ditunda.
- **F6-04**: kustom kolom pelanggan (requirements 5.8) — Fase 6 atau tunda? Default: **tunda**.
- Q2 (profiles readable by members) — Fase 7.
- Q6, Q7 — saat laporan/audit.

## Belum dimulai

- Fase 6: Pengaturan (nama/logo bisnis), Laporan (pesanan/tagihan/pembayaran/pemasukan/pengeluaran/saldo/arus kas/laba), Ekspor PDF/CSV.
- Fase 7: Tim/audit (multi-business UI, undangan anggota).
- Fase 8: Offline/sync.
- Fase 9: Validasi/rilis.

## Technical debt

- Controller `TextEditingController` di dialog one-shot (`_void`) tidak di-dispose (leak minor).
- Idempotency key belum dipakai di UI form.
- `FakeOrdersService` tidak merecompute `paid_amount`.
- Dialog change status/cancel order belum ada widget test.
- **Form submit transfers belum ada widget test** (butuh dropdown manipulation).
- **`PaymentsScreen`** masih placeholder — akan diisi daftar semua payments di Fase 6 (Laporan).
- Pagination/server-side search ditunda ke Fase 6.
- Multi-business UI ditunda ke Fase 7.
- Tidak ada refetch otomatis dashboard setelah payment void lintas domain (invalidasi manual dari controller).

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi.
- Rumus laba operasional belum final.

## Langkah berikutnya

1. Putuskan F6-01..F6-04.
2. Langkah 13: Fase 6 — Pengaturan, Laporan, Ekspor.

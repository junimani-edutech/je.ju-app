# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 4 — Pelanggan, Pesanan, dan Pembayaran (selesai). Siap masuk Fase 5 (Keuangan).

## Sudah selesai

- Fase 1: skema, auth backend, auth UI, onboarding.
- Fase 2: RLS + pgTAP isolasi.
- Fase 3: app shell adaptif + theme light/dark.
- Fase 4 — Pelanggan (Langkah 9): migration 0200/0201, fitur CRUD + archive/restore.
- Fase 4 — Pesanan (Langkah 10): RPC `create_order` (format `YYYYMMDD-NNN`), `change_order_status`, `cancel_order`. UI list/form/detail/change-status/cancel.
- **Fase 4 — Pembayaran (Langkah 11):**
  - Migration 0400: seed default `payment_methods` + `accounts` saat bisnis dibuat (Q8-A).
  - Migration 0401: RPC `record_payment` + `void_payment` + helper `order_paid_amount` / `order_payment_status` (Q3-A satu payment per order, Q4-A refund = reversal, E-01-A recompute di RPC).
  - Data layer: `Payment`, `PaymentMethod`, `Account`, `PaymentsService` + `SupabasePaymentsService`, `paymentsControllerProvider` (mutasi + invalidate).
  - UI: `PaymentsSection` di `OrderDetailSheet`, `PaymentFormSheet`, `PaymentListTile` (badge Reversal), void dialog.
  - `OrderDetailSheet` reaktif terhadap `ordersProvider` (liveOrder) agar `paid_amount`/`payment_status` update setelah record/void.
  - Widget test payments: 5 tests.
  - pgTAP `payment_rpcs.sql`: 25 tests.
- Total: 31 Flutter tests + 84 pgTAP tests.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- A-01..A-08: APPROVED.
- U-01..U-07: APPROVED.
- C-01..C-08: APPROVED.
- Q1: APPROVED.
- Q5-A: APPROVED.
- **Q3-A: APPROVED** (satu payment per order).
- **Q4-A: APPROVED** (refund = payment baru dengan `reversal_of_payment_id`).
- **E-01-A: APPROVED** (recompute di RPC).
- **Q8-A: APPROVED** (seed payment_methods & accounts saat bisnis dibuat).

## Pertanyaan terbuka (sisa)

- **F5-01** (auto-jurnal payment → transactions income?) — diputuskan di awal Fase 5.
- **F5-02** (transfer pakai idempotency_key?) — diputuskan di awal Fase 5.
- **F5-03** (saldo akun: computed atau cache?) — diputuskan di awal Fase 5.
- **Q2** (profiles readable by members) — Fase 7.
- **Q6** (ongkir dibebankan vs biaya aktual) — Fase 6.
- **Q7** (retensi audit_logs) — Fase 7.

## Belum dimulai

- Fase 5: Keuangan (transactions income/expense, transfers, saldo akun, arus kas).
- Fase 6: Pengaturan/laporan/ekspor + PDF/CSV.
- Fase 7: Tim/audit (multi-business UI).
- Fase 8: Offline/sync.
- Fase 9: Validasi/rilis.

## Technical debt

- Controller `TextEditingController` di dialog one-shot (`_void`, `_changeStatus`, `_cancelOrder`) tidak di-dispose (leak minor). Alternatif: ubah jadi `StatefulWidget` dialog.
- Idempotency key belum dipakai di UI form (hanya disable tombol selama loading). Akan disiapkan bersama offline (Fase 8).
- `FakeOrdersService` tidak merecompute `paid_amount` setelah payment record/void (di Supabase asli RPC melakukannya).
- Widget test untuk dialog change status / cancel order belum ada.
- Pagination / server-side search ditunda ke Fase 6.
- Race condition `create_order`/`record_payment` diuji via advisory lock + unique, bukan concurrent stress test.
- `order_number` memakai tanggal server, bukan zona waktu bisnis.
- Multi-business UI (memilih bisnis aktif) ditunda ke Fase 7.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi di Codespaces Linux.
- Rumus laba operasional belum final.

## Langkah berikutnya

1. Putuskan **F5-01**, **F5-02**, **F5-03**.
2. Langkah 12: Fase 5 — Keuangan (transactions, transfers, saldo akun, arus kas).

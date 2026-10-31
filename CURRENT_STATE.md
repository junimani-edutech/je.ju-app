# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 4 — Pelanggan & Pesanan (selesai). Siap masuk Fase 4-Pembayaran.

## Sudah selesai

- Fase 1: skema, auth backend, auth UI, onboarding.
- Fase 2: RLS + pgTAP isolasi.
- Fase 3: app shell adaptif + theme light/dark + placeholder 6 modul.
- Fase 4 — Pelanggan (Langkah 9):
  - Migration 0200 (`set_created_by`), 0201 (seed order_statuses, Q1 APPROVED).
  - Model Business/BusinessMember, `currentBusinessProvider`, `currentMemberProvider`.
  - Fitur Customers lengkap (list, search, tab aktif/arsip, form, archive/restore).
- Fase 4 — Pesanan (Langkah 10):
  - Migration 0300: RPC `create_order` + `orders` updated_at trigger. Format `order_number` Q5-A (`YYYYMMDD-NNN` per bisnis/hari). Advisory lock + unique.
  - Migration 0301: RPC `change_order_status` + `cancel_order`, tulis `order_status_history` atomik. `change_order_status` menolak target `cancelled` (harus via `cancel_order`).
  - Data layer: `Order`, `OrderItem`, `OrderStatus`, `OrderItemInput`, `OrdersService` + `SupabaseOrdersService`, `OrdersNotifier` + `ordersProvider` + `orderStatusesProvider`.
  - UI: `OrdersScreen` (tab filter Semua/Draft/Proses/Selesai/Dibatalkan, empty/loading/error states, FAB role-gated), `OrderFormSheet` (baris item dinamis, subtotal real-time), `OrderListTile`, `OrderDetailSheet` (item list, change status dialog, cancel dialog).
  - Widget test Orders: 7 tests.
  - pgTAP: `create_order_rpc` (11), `change_order_status_rpc` (12).
- Total: 26 Flutter tests + 59 pgTAP tests.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- A-01..A-08: APPROVED.
- U-01..U-07: APPROVED.
- C-01..C-08: APPROVED.
- **Q1: APPROVED** (seed default order_statuses).
- **Q5-A: APPROVED** (format `order_number` `YYYYMMDD-NNN` per bisnis per hari).

## Pertanyaan terbuka (sisa)

- **Q3** (satu payment multi-order?) — **blocker Fase 4-Pembayaran**.
- **Q4** (representasi refund: payment baru dengan `reversal_of_payment_id` atau amount negatif?) — **blocker Fase 4-Pembayaran**.
- **Q2** (profiles readable by members) — Fase 7.
- **Q6** (ongkir dibebankan vs biaya aktual) — saat modul Laporan / Fase 6.
- **Q7** (retensi audit_logs) — Fase 7.

## Belum dimulai

- Fase 4 — **Pembayaran** (payments, void/reversal, alokasi ke order, update `paid_amount`/`payment_status`). **Blocker Q3 & Q4.**
- Fase 5: Keuangan (transactions, accounts, transfers). **Blockers Q3 & Q4** (karena payment adalah sumber pemasukan).
- Fase 6: Pengaturan/laporan/ekspor.
- Fase 7: Tim/audit (multi-business UI).
- Fase 8: Offline/sync.
- Fase 9: Validasi/rilis.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi.
- Race condition `create_order` (advisory lock) tidak diuji concurrent di pgTAP.
- `order_number` memakai tanggal server, bukan zona waktu bisnis.
- Pagination/server-side search Pelanggan & Pesanan ditunda ke Fase 6.
- Change status dialog & cancel dialog belum dicakup widget test (hanya flow utama).

## Langkah berikutnya

1. Putuskan **Q3** dan **Q4**.
2. Langkah 11: Fase 4-Pembayaran.

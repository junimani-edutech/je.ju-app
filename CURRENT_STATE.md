# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-02

## Fase saat ini

Fase 8 — Offline & Sync (selesai). Siap masuk Fase 9 (Validasi/Rilis).

## Sudah selesai

- Fase 1–7: fondasi, auth, UI shell, pelanggan, pesanan, pembayaran, keuangan, pengaturan, laporan, ekspor, tim & undangan.
- **Fase 8 — Offline & Sync:**
  - Dependency: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `connectivity_plus`, `path_provider`, `uuid`, `path`; dev: `drift_dev`, `build_runner`.
  - Skema lokal Drift: 10 tabel mirror + `sync_queue`.
  - Migration 0800: `upsert_order_with_items`.
  - Migration 0801: `upsert_payment`.
  - Migration 0802: `upsert_transaction` + `upsert_transfer`.
  - Local repos: customers, orders, payments, transactions, transfers.
  - Sync queue repository + `SyncService` (flush berkala + retry).
  - Dispatchers: customers, orders, payments, transactions, transfers + composite.
  - Offline wrappers: `Offline{Orders,Payments,Transactions,Transfers,Customers}Service`.
  - UI: `SyncQueueBadge` di Dashboard AppBar + `SyncStatusScreen` di `/app/more/sync`.
  - Bootstrap: `SyncBootstrap` (start/stop periodic sync saat auth berubah).
  - pgTAP: `upsert_rpcs.sql` (15), `upsert_transfer_txn_rpcs.sql` (11).
  - Unit test lokal: sync queue (5), local orders/payments (4), local finance repos (4).

**Total: 68 Flutter tests + 189 pgTAP tests.**

## Keputusan

- D-01..D-04, D-07: APPROVED.
- A-01..A-08, U-01..U-07, C-01..C-08: APPROVED.
- Q1, Q5-A, Q3-A, Q4-A, Q8-A, E-01-A: APPROVED.
- F5-01-A..F5-04-A: APPROVED.
- F6-01 (revised B2), F6-02-A, F6-03-A, F6-04-A: APPROVED.
- D-05: APPROVED (revised) — CSV + XLSX, PDF ditunda.
- F7-01 (manual link), F7-02..F7-04, Q2: APPROVED.
- **F8-01..F8-05: APPROVED (Default A)** — Drift, tanpa enkripsi, server-wins untuk master, partial offline (auth + void/change status online-only), idempotency key wajib.

## Pertanyaan terbuka (untuk Fase 9)

- F9-01 — Strategi build & signing iOS (butuh macOS runner atau GitHub Actions).
- F9-02 — Strategi build native Windows (butuh Windows runner).
- F9-03 — Backup/restore PostgreSQL untuk production (pgsql dump + restore drill).
- F9-04 — SMTP untuk email undangan (ganti manual link dengan `inviteUserByEmail`).
- F9-05 — Deployment Supabase production vs self-hosted.
- F9-06 — PDF invoice/struk (D-05 revisi sebelumnya).

## Technical debt

- Enkripsi lokal tidak aktif (F8-02-A). Migrasi ke `sqlcipher` disarankan sebelum produksi.
- Persistent selection multi-business (`shared_preferences`) belum — reset ke bisnis pertama saat refresh.
- Void/change status online-only (bukan offline).
- Controller `TextEditingController` di dialog one-shot tidak di-dispose.
- Web download via `dart:html` (deprecated).
- `PaymentsScreen` masih placeholder.
- Custom columns (req 5.8) ditunda.
- Pagination/server-side search ditunda.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi.
- Rumus laba operasional belum final (D-02).
- Offline: void/status change/undo wajib online.

## Langkah berikutnya

1. Putuskan F9-01..F9-06.
2. Langkah 16: Fase 9 — Validasi & Rilis.

# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 4 — Pelanggan (selesai). Pesanan siap dimulai.

## Sudah selesai

- Fase 1: skema, auth backend, auth UI, onboarding.
- Fase 2: RLS + pgTAP isolasi.
- Fase 3: app shell adaptif + theme light/dark + placeholder 6 modul.
- **Fase 4 — Pelanggan:**
  - Migration 0200: trigger `set_created_by` untuk customers/orders/payments/transactions/transfers.
  - Migration 0201: seed default `order_statuses` saat bisnis dibuat (Q1 APPROVED).
  - Model: `Business`, `BusinessMember`.
  - `BusinessService`: `listMyBusinesses` + `getMemberForCurrentUser`.
  - `currentBusinessProvider` (bisnis pertama; multi-business UI = Fase 7).
  - `currentMemberProvider` (role user aktif).
  - Fitur Customers: model, service (abstract + Supabase), `CustomersNotifier`, form sheet, list tile, `CustomersScreen` dengan search + tab Aktif/Arsip + role-based aksi.
  - Widget test: 6 tests.
  - pgTAP: diperluas dengan update/delete isolation.
  - Total: 19 Flutter test + 36 pgTAP test.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.
- A-01..A-08: APPROVED.
- U-01..U-07: APPROVED.
- **C-01..C-08: APPROVED.**
- **Q1: APPROVED.**

## Pertanyaan terbuka (sisa)

Q2–Q7 di `docs/DATABASE_SCHEMA.md` **belum diputuskan**:
- Q2 (profiles readable by members) → Fase 7.
- Q3 (satu payment multi-order?) → **sebelum Fase 5**.
- Q4 (refund representation) → **sebelum Fase 5**.
- Q5 (format order_number) → **sebelum Fase 4-Pesanan**.
- Q6 (ongkir dibebankan vs biaya aktual) → Fase 4-Pesanan.
- Q7 (retensi audit_logs) → Fase 7.

## Belum dimulai

- Fase 4 — **Pesanan** (Customers done → Orders → Order Items → Payments → History). **Blocker: Q5** harus diputuskan dulu.
- Fase 5: Keuangan. **Blocker: Q3 & Q4**.
- Fase 6: Pengaturan/laporan/ekspor.
- Fase 7: Tim/audit (multi-business UI).
- Fase 8: Offline/sync.
- Fase 9: Validasi/rilis.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi di Codespaces Linux.
- Rumus laba operasional belum final.
- Pagination/server-side search Pelanggan ditunda ke Fase 6.
- Multi-business UI ditunda ke Fase 7 (saat ini hanya bisnis pertama).

## Langkah berikutnya

1. Putuskan **Q5** (format `order_number`) sebelum modul Pesanan.
2. Langkah 10: Fase 4 — Pesanan.

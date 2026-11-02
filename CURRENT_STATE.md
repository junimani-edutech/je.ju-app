# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-02

## Fase saat ini

Fase 6 — Pengaturan, Laporan, Ekspor (selesai). Siap masuk Fase 7 (Tim/Audit).

## Sudah selesai

- Fase 1: skema, auth backend, auth UI, onboarding.
- Fase 2: RLS + pgTAP isolasi.
- Fase 3: app shell adaptif + theme light/dark.
- Fase 4: Pelanggan, Pesanan, Pembayaran.
- Fase 5: Keuangan (transactions, transfers, saldo, cash flow).
- Fase 6 — Pengaturan, Laporan, Ekspor:
  - Migration 0600: RPC `update_business_profile`.
  - Migration 0601: RPC `report_summary`.
  - Model `Business` diperluas (`legalName`, `contactEmail`, `contactPhone`, `address`).
  - `BusinessService.updateProfile`.
  - `ReportService` + `reportSummaryProvider`.
  - `ExportService` + `DefaultExportService` (CSV + XLSX).
  - Web download handler + stub non-web.
  - UI: `SettingsScreen` rewrite, `ReportsScreen` rewrite.
  - pgTAP: `business_profile_rpc.sql` (13), `report_summary_rpc.sql` (13).
  - Widget test: settings (4), reports (4), export (2).

**Total: 47 Flutter tests + 145 pgTAP tests.**

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- A-01..A-08, U-01..U-07, C-01..C-08: APPROVED.
- Q1, Q5-A: APPROVED.
- Q3-A, Q4-A, E-01-A, Q8-A: APPROVED.
- F5-01-A s/d F5-04-A: APPROVED.
- F6-01 (revised B2), F6-02-A, F6-03-A, F6-04-A: APPROVED.
- D-05: APPROVED (revised 2026-11-01) — CSV + XLSX, PDF ditunda.

## Pertanyaan terbuka (Fase 7)

- F7-01 — Mekanisme undangan anggota (default: email link via Supabase Auth `inviteUserByEmail`).
- F7-02 — Alur penerimaan undangan (default: link -> signup -> auto-join business via parameter `business_id`).
- F7-03 — Multi-business UI (default: dropdown di AppBar, wajib D-01).
- F7-04 — Audit log viewer di UI (default: tidak, backend + admin query).
- Q2 — `profiles` readable by member (default: ya, hanya `full_name` + `avatar_url`).
- Q7 — Retensi audit_logs.

## Technical debt

- Controller `TextEditingController` di dialog one-shot tidak di-dispose.
- Idempotency key belum dipakai di UI form.
- `FakeOrdersService` tidak merecompute `paid_amount`.
- `PaymentsScreen` masih placeholder.
- `ExportService.paymentsCsv` belum punya tombol UI.
- Web download via `dart:html` (deprecated; migrasi ke `package:web` di Fase 7+).
- Mobile file save native (`path_provider`/`share_plus`) ditunda.
- Tidak ada widget test untuk dialog change status/cancel order/void payment/void transfer.
- Custom columns (requirements 5.8) ditunda (F6-04-A).
- Pagination/server-side search ditunda.
- Multi-business UI ditunda.

## Batas yang diakui

- Supabase lokal (Docker), belum remote.
- Build iOS & native Windows belum diverifikasi.
- Rumus laba operasional belum final (D-02).

## Langkah berikutnya

1. Putuskan F7-01..F7-04 + Q2.
2. Langkah 14: Fase 7 — Tim/Audit.

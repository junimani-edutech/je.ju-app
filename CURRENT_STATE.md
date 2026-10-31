# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 3 — Kerangka UI (selesai). App shell adaptif + placeholder per modul terpasang dan teruji.

## Sudah selesai

- Docs: `docs/REQUIREMENTS.md`, `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- Tata kelola: `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- Migration 0000: skema 15 tabel, 34 policy, helper `is_business_member`.
- Migration 0100: trigger `on_auth_user_created`, `set_updated_at`, RPC `create_business_with_owner`.
- pgTAP: 27 tests PASS (rls_isolation + auth_onboarding).
- Flutter auth UI + onboarding (Langkah 7B): 8 widget tests PASS.
- **Fase 3 — Kerangka UI (Langkah 8):**
  - `AppTheme` (light + dark, seed `#2E7D32`), `themeModeProvider` (NotifierProvider).
  - `ComingSoonScreen` reusable.
  - `AppShell` adaptif: `NavigationBar` 4 tab (mobile) / `NavigationRail` 6 entri (wide ≥ 720px).
  - 7 layar: Dashboard, Customers, Orders, Payments, Reports, Settings, More (placeholder).
  - Router `StatefulShellRoute.indexedStack` dengan 4 branch.
  - Widget test navigasi: mobile + wide.
  - `HomeScreen` lama dihapus (digantikan `DashboardScreen`).

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.
- A-01..A-08: APPROVED.
- U-01..U-07: APPROVED (nav adaptif, 4 tab mobile, rename home→dashboard, light+dark, ComingSoon, Lainnya sebagai halaman, Material icons).

## Pertanyaan terbuka (dari DATABASE_SCHEMA.md)

Q1 s.d. Q7 belum diputuskan. **Q1 adalah blocker** saat masuk Fase 4 (pesanan).

## Belum dimulai

- Fase 4: Pelanggan, Pesanan, Item, Status, Pembayaran, Riwayat.
- Fase 5: Keuangan (pemasukan/pengeluaran, akun, transfer).
- Fase 6: Pengaturan/laporan/ekspor.
- Fase 7: Tim/audit.
- Fase 8: Offline/sync.
- Fase 9: Validasi/rilis.
- Seed default (order_statuses, dll) saat bisnis baru — menunggu Q1.
- Nama bisnis aktif di AppBar — butuh `currentBusinessProvider` (Fase 4).
- Toggle tema manual + persistensi (Fase 6).

## Batas yang diakui

- Verifikasi memakai Supabase lokal (Docker), belum remote.
- Build iOS dan native Windows belum diverifikasi di Codespaces Linux.
- Rumus laba operasional belum final.
- Test navigasi memakai fake service (tidak menyentuh Supabase).

## Langkah berikutnya

1. **Langkah 9: Fase 4 — Pelanggan dulu (Customer CRUD)**, sebelum Pesanan.
   - Q1 perlu diputuskan sebelum modul Pesanan.
   - Modul Pelanggan bisa jalan tanpa Q1.
2. Setelah Pelanggan: Pesanan → Pembayaran.

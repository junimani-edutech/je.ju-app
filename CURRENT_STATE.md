# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 1/2 transisi selesai. Flutter auth UI + onboarding berfungsi dan teruji.
Siap masuk Fase 3: kerangka UI (dashboard shell).

## Sudah selesai

- Docs: `docs/REQUIREMENTS.md`, `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- Tata kelola: `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- Migration 0000: skema awal 15 tabel, RLS 34 policy, helper `is_business_member`.
- Migration 0100: trigger `on_auth_user_created`, `set_updated_at`, RPC `create_business_with_owner`.
- Tes pgTAP: `rls_isolation.sql` (10) + `auth_onboarding.sql` (17) = 27 tests, PASS.
- Flutter auth UI + onboarding (Langkah 7B):
  - Services: `AuthService`, `BusinessService` (abstract + Supabase impls).
  - Providers: `authStateProvider`, `hasBusinessProvider`.
  - Screens: SignIn, SignUp, Onboarding, Home.
  - Router: `go_router` dengan redirect auth + onboarding.
  - Widget test: 8 tests (1 smoke + 4 auth + 3 onboarding), PASS.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.
- A-01..A-08: APPROVED.

## Pertanyaan terbuka (dari DATABASE_SCHEMA.md)

Q1 s.d. Q7 belum diputuskan. **Q1 adalah blocker** saat masuk Fase 4 (pesanan).

## Belum dimulai

- Fase 3: kerangka UI (dashboard shell, navigasi, tema).
- Fase 4–9: pesanan, keuangan, laporan, tim, offline, rilis.
- Seed default (order_statuses, dll) saat bisnis baru — menunggu Q1.
- Idempotency RPC create_business — belum.
- Uji reaktivitas router terhadap perubahan auth mid-sesi — akan diuji saat kerangka UI stabil.

## Batas yang diakui

- Verifikasi memakai Supabase lokal (Docker), belum remote.
- Build iOS dan native Windows belum diverifikasi di Codespaces Linux.
- Rumus laba operasional belum final.

## Langkah berikutnya

1. **Langkah 8: Fase 3 — kerangka UI** (theme, bottom nav, drawer, dashboard shell).
2. Putuskan Q1 sebelum Fase 4 (pesanan).

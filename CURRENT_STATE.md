# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 1/2 transisi. Flutter OK, Supabase lokal OK, migration (2 file) OK, RLS behavior teruji,
auth backend (trigger profil + RPC create business) terpasang dan teruji.

## Sudah selesai

- Docs: `docs/REQUIREMENTS.md`, `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- Tata kelola: `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- Migration 0000: skema awal 15 tabel, RLS 34 policy, helper `is_business_member`.
- Migration 0100: trigger `on_auth_user_created`, `set_updated_at`, RPC `create_business_with_owner`.
- Tes pgTAP:
  - `rls_isolation.sql` (10 tests) — isolasi per business.
  - `auth_onboarding.sql` (17 tests) — trigger profil, RPC, validasi, multi-business, not-authenticated.
- D-01, D-02, D-03, D-04, D-07 APPROVED.
- A-01..A-08 APPROVED (auth method, email-only, onboarding, dll).
- Flutter `jeju_app`, `flutter analyze`/`test` lulus.

## Sedang dikerjakan

- Siap masuk Langkah 7B: Flutter auth UI + onboarding screen.

## Belum dimulai

- Langkah 7B: UI auth + onboarding, Riverpod, go_router.
- Fase 3: kerangka UI dashboard.
- Fase 4–5: pesanan, keuangan.
- Fase 6–9: laporan, tim, offline, rilis.
- Q1–Q7 di DATABASE_SCHEMA.md belum diputuskan.
- Seed default (order_statuses, payment_methods, categories, accounts) saat bisnis baru — menunggu Q1.
- Idempotency RPC create_business — belum.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.
- A-01..A-08: APPROVED (email-only, no OAuth, no email confirm di lokal, onboarding wajib, timezone default Asia/Jakarta, currency IDR, no invite, RPC-based create, Riverpod, go_router).

## Batas yang diakui

- Verifikasi memakai Supabase lokal (Docker), belum remote.
- pgTAP hanya menguji `select`/`insert` di RLS, plus trigger & RPC. Skenario `update`/`delete` menyusul.
- Seed default saat bisnis baru belum ada (menunggu Q1).
- Rumus laba operasional belum final.
- Build iOS dan native Windows belum diverifikasi.

## Langkah berikutnya

1. Langkah 7B: Flutter — init Supabase, Riverpod, go_router, AuthGate, SignIn/SignUp, Onboarding.
2. Setelah itu: Fase 3 kerangka UI.

# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 1 — Fondasi selesai. Flutter OK, Supabase lokal OK, migration terverifikasi, RLS behavior teruji.

## Sudah selesai

- `docs/REQUIREMENTS.md`, `AGENTS.md`, `DECISIONS.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- `supabase/migrations/20261101000000_initial_schema.sql` — terverifikasi via `supabase db reset`.
- D-01, D-02, D-03, D-04, D-07 APPROVED (2026-11-01).
- Flutter `jeju_app` (android/ios/web/linux/macos/windows). `flutter analyze` no issues; `flutter test` all passed.
- Supabase CLI 2.122.0 + `psql` 16.15 terpasang. `supabase start`/`db reset` sukses.
- Verifikasi schema: 15 tabel, 15 RLS aktif, 34 policy, helper `is_business_member` security definer, enum benar.
- **Langkah 6: pgTAP RLS isolation test.** `supabase test db` — 10 tests passed (lihat CHANGELOG).

## Sedang dikerjakan

- Belum. Siap Langkah 7: auth dasar + onboarding business.

## Belum dimulai

- Auth UI dan alur join business.
- Kerangka UI (Fase 3).
- Modul pesanan, pembayaran, keuangan, laporan.
- Offline/sync.
- Build & test per platform (iOS/Windows belum diverifikasi di Codespaces Linux).

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.

## Pertanyaan terbuka (dari DATABASE_SCHEMA.md)

Q1 s.d. Q7 belum diputuskan. Lihat `docs/DATABASE_SCHEMA.md` bagian "Pertanyaan terbuka".

## Batas yang diakui

- Semua verifikasi memakai Supabase lokal (Docker), belum remote.
- pgTAP hanya menguji `select`/`insert` RLS. Skenario `update`/`delete` menyusul.
- Rumus laba operasional belum final.
- Build iOS dan native Windows belum diverifikasi.

## Langkah berikutnya

1. Langkah 7: auth dasar (sign up / sign in / join business) + onboarding business pertama.
2. Setup trigger `on_auth_user_created` untuk auto-create profile.

# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 1 — Fondasi selesai. Flutter init OK, Supabase lokal OK, migration terverifikasi.

## Sudah selesai

- `docs/REQUIREMENTS.md` dari spesifikasi PDF.
- Tata kelola: `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- `supabase/migrations/20261101000000_initial_schema.sql` — terverifikasi via `supabase db reset`.
- D-01, D-02, D-03, D-04, D-07 disetujui (2026-11-01).
- Flutter `jeju_app` (org `com.jeju`, android/ios/web/linux/macos/windows).
- Dependensi: `supabase_flutter`, `flutter_dotenv`.
- `lib/main.dart` + `test/widget_test.dart`.
- `flutter analyze` no issues; `flutter test` all passed.
- Supabase CLI 2.122.0 terpasang. `supabase start` + `supabase db reset` sukses di Codespaces.
- Verifikasi schema: 15 tabel, 15 RLS aktif, 34 policy, helper `is_business_member` security definer, enum benar.

## Sedang dikerjakan

- Belum. Siap Langkah 6: uji isolasi RLS dengan pgTAP.

## Belum dimulai

- Seed data uji (`supabase/seed.sql`).
- Uji perilaku RLS lintas business (pgTAP).
- Auth dasar (sign up / sign in / join business).
- Kerangka UI (Fase 3).
- Modul pesanan, pembayaran, keuangan, laporan.
- Offline/sync.
- Build & test per platform (iOS/Windows tidak bisa diverifikasi di Codespaces Linux).

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED.
- D-05, D-06, D-08: PROPOSED.

## Pertanyaan terbuka (dari DATABASE_SCHEMA.md)

Q1 s.d. Q7 belum diputuskan. Lihat `docs/DATABASE_SCHEMA.md` bagian "Pertanyaan terbuka".

## Batas yang diakui

- Verifikasi memakai Supabase lokal (Docker), belum remote.
- Belum ada uji perilaku RLS (apakah user A bisa/bisa-tidak membaca data user B). Itu Langkah 6.
- Rumus laba operasional belum final.
- Build iOS dan native Windows belum diverifikasi.

## Langkah berikutnya

1. Langkah 6: tambah `supabase/seed.sql` untuk uji + pgTAP test RLS isolasi.
2. Langkah 7: auth dasar dan onboarding business.

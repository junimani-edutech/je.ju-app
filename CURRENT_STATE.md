# CURRENT_STATE.md — Status Proyek JeJu

Terakhir diperbarui: 2026-11-01

## Fase saat ini

Fase 1 — Fondasi (Flutter init selesai; Supabase belum tersambung).

## Sudah selesai

- `docs/REQUIREMENTS.md` dari spesifikasi PDF.
- Dokumen tata kelola: `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `MASTER_BLUEPRINT.md`.
- `docs/DATABASE_SCHEMA.md` (DRAFT v0.1).
- `supabase/migrations/20261101000000_initial_schema.sql` (DRAFT, belum dijalankan).
- D-01, D-02, D-03, D-04, D-07 disetujui.
- Proyek Flutter terinisialisasi di root repo:
  - Package: `jeju_app`, org `com.jeju`.
  - Platform yang di-generate: android, ios, web, linux, macos, windows.
  - Dependensi awal: `supabase_flutter`, `flutter_dotenv`.
  - `.env.example` dan `.gitignore` untuk secrets.
  - `lib/main.dart` dengan `JeJuApp`, `test/widget_test.dart`.
- Verifikasi: `dart format`, `flutter analyze`, `flutter test` — lihat CHANGELOG untuk hasil nyata.

## Sedang dikerjakan

- Belum ada. Siap masuk Fase 2 (Supabase + migration + RLS test).

## Belum dimulai

- Supabase project (user harus membuat).
- Menjalankan migration dan menguji RLS isolasi.
- Auth dasar, business/anggota.
- Kerangka UI (Fase 3).
- Modul pesanan, pembayaran, keuangan, laporan.
- Offline/sync.
- Build & test per platform.

## Keputusan

- D-01, D-02, D-03, D-04, D-07: APPROVED (2026-11-01).
- D-05, D-06, D-08: PROPOSED.

## Batas yang diakui

- Build iOS dan build native Windows tidak dapat diverifikasi di Codespaces Linux.
- Migration SQL belum dijalankan di Supabase mana pun.
- `docs/DATABASE_SCHEMA.md` masih DRAFT; pertanyaan Q1–Q7 belum diputuskan.

## Langkah berikutnya

1. User membuat Supabase project + mengisi `.env`.
2. Jalankan migration `20261101000000_initial_schema.sql`.
3. Uji isolasi RLS dasar.

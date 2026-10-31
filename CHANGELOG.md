# CHANGELOG.md

## 2026-11-01

### Added
- `docs/REQUIREMENTS.md` dari spesifikasi JeJu v1.0.
- `AGENTS.md` sebagai aturan kerja AI.
- `DECISIONS.md` sebagai daftar keputusan proyek.
- `CURRENT_STATE.md` sebagai status proyek.
- `CHANGELOG.md` sebagai log perubahan.
- `MASTER_BLUEPRINT.md` sebagai stub blueprint awal.

### Changed
- Tidak ada.

### Removed
- Tidak ada.

### Tests
- Belum ada kode aplikasi. Tidak ada tes yang dijalankan.


## 2026-11-01 — Fase 1: Flutter init

### Added
- Flutter project `jeju_app` di root repo (org `com.jeju`).
- Platform: android, ios, web, linux, macos, windows.
- Dependensi: `supabase_flutter`, `flutter_dotenv`.
- `lib/main.dart` dengan `JeJuApp` (Material 3, seed green).
- `test/widget_test.dart` dasar.
- `.env.example` dan entri `.gitignore` untuk `.env`/`supabase/.temp/`.
- Struktur folder: `lib/core/{config,constants,theme}`, `lib/features`, `lib/shared/widgets`.

### Changed
- `CURRENT_STATE.md` diperbarui ke Fase 1.
- `DECISIONS.md` sebelumnya diperbarui (D-01/02/03/04/07 APPROVED).

### Tests
- `dart format lib test` — lihat log terminal.
- `flutter analyze` — lihat log terminal.
- `flutter test` — lihat log terminal.
- Tidak ada klaim lulus tanpa log yang sesuai.

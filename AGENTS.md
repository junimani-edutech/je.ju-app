# AGENTS.md — Aturan Kerja AI

Dokumen ini mengikat AI yang bekerja pada repository JeJu.

## Urutan membaca sebelum coding

1. `AGENTS.md`
2. `MASTER_BLUEPRINT.md`
3. `docs/REQUIREMENTS.md`
4. `CURRENT_STATE.md`
5. `DECISIONS.md`
6. Spesifikasi relevan lain, misalnya `DATABASE_SCHEMA.md`, `OFFLINE_SYNC.md`, `UI_UX_SPEC.md`.

Jika ada konflik, urutan acuan:
`DECISIONS.md` yang disetujui → `docs/REQUIREMENTS.md` terbaru → `MASTER_BLUEPRINT.md` → asumsi AI.
Konflik harus dilaporkan, bukan ditebak.

## Sebelum coding

AI wajib melaporkan:
- pemahaman tugas;
- konflik atau risiko;
- daftar file yang akan dibuat/diubah/dihapus beserta alasannya;
- apakah tugas menyentuh arsitektur, keamanan, atau rumus uang.

Jika menyentuh arsitektur, keamanan, atau rumus uang, AI harus berhenti dan meminta persetujuan.

## Saat coding

- Periksa file aktual. Jangan mengarang file atau menganggap fitur sudah ada.
- Kelompokkan perubahan satu fase per filepath agar file tidak bolak-balik diedit pada fase yang sama.
- Jangan menghapus fitur berfungsi tanpa persetujuan.
- Perubahan database wajib memakai migration.
- Jangan memasukkan secret, service-role key, atau kredensial ke klien/repository.
- Validasi di klien dan server; server tetap otoritas data dan akses.
- Gunakan `business_id` dan validasi keanggotaan pada setiap operasi.
- Aktifkan RLS pada tabel yang terekspos API.
- Uang memakai integer rupiah untuk IDR atau numeric presisi; jangan floating-point.
- Status pesanan dan status pembayaran berbeda.
- Pembayaran pesanan tidak boleh dihitung dua kali sebagai pemasukan umum.
- Transfer internal bukan pendapatan/beban.
- Transaksi terkonfirmasi tidak dihapus diam-diam; koreksi memakai reversal/cancel dengan audit.
- Offline penuh tidak boleh dijanjikan sebelum keamanan, konflik, dan sinkronisasi multi-perangkat lulus tes.

## Setelah edit fase selesai

- Jalankan format, analyze, dan tes relevan.
- Laporkan hasil yang benar-benar terjadi. Jangan melaporkan tes lulus jika tidak dijalankan.
- Perbarui `CURRENT_STATE.md`.
- Perbarui `CHANGELOG.md`.
- Jika ada keputusan baru, catat di `DECISIONS.md` dengan status yang benar.

## Batas platform

Codespaces Linux tidak menggantikan macOS/Xcode untuk signing/build iOS atau lingkungan Windows untuk menguji build native Windows. Klaim dukungan platform hanya setelah build/test terbukti.

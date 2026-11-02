# DECISIONS.md — Keputusan Proyek

Status keputusan:
- `PROPOSED` = usulan, belum disetujui, tidak boleh dianggap final.
- `APPROVED` = disetujui dan menjadi acuan.
- `REJECTED` = ditolak.
- `SUPERSEDED` = digantikan keputusan lain.

Urutan acuan jika ada konflik:
`DECISIONS.md` yang disetujui → `docs/REQUIREMENTS.md` terbaru → `MASTER_BLUEPRINT.md` → asumsi AI.

## Daftar keputusan

| ID | Keputusan | Default sementara | Status | Menyentuh | Disetujui pada |
|---|---|---|---|---|---|
| D-01 | Satu pengguna dapat bergabung ke beberapa usaha? | Ya, dengan isolasi data per usaha. | APPROVED | Arsitektur, keamanan | 2026-11-01 |
| D-02 | Metode pengakuan pendapatan? | Pisahkan kas masuk dan laba sampai aturan disetujui. | APPROVED | Rumus uang | 2026-11-01 |
| D-03 | Buat transaksi offline? | Ya untuk operasi yang ditentukan; transaksi uang bisa menunggu konfirmasi. | APPROVED | Arsitektur, keamanan | 2026-11-01 |
| D-04 | Hapus transaksi terkonfirmasi? | Tidak; gunakan reversal/cancel dengan audit. | APPROVED | Keamanan, audit | 2026-11-01 |
| D-05 | Ekspor awal? | PDF dan CSV; XLSX setelah diuji. | **APPROVED (revised)** | Fitur | 2026-11-01 |
| D-06 | Batas pengguna/data dan biaya cloud? | Tetapkan setelah estimasi pemakaian dan pemeriksaan kuota. | PROPOSED | Biaya/operasional | — |
| D-07 | Multi-currency? | Tidak untuk versi awal; IDR. | APPROVED | Rumus uang, arsitektur | 2026-11-01 |
| D-08 | Retensi data lokal setelah akses dicabut? | Tetapkan kebijakan; batasi cache sensitif. | PROPOSED | Keamanan/privasi | — |

## Catatan approval

- Approval D-02 hanya menetapkan pemisahan kas vs laba. **Rumus laba operasional belum final** dan harus disetujui sebelum dipakai untuk keputusan usaha.
- Approval D-03 mengizinkan transaksi offline untuk operasi yang ditentukan. Daftar operasi pasti dan teknologi lokal tetap harus ditulis di `OFFLINE_SYNC.md` sebelum fase offline.
- Approval D-04 menetapkan transaksi terkonfirmasi tidak dihapus. Implementasi reversal/cancel + audit akan ditulis di skema dan modul.
- Approval D-07 mengunci IDR untuk versi awal. Skema memakai `char(3)` dengan check `currency = 'IDR'`.

## Perubahan status

- 2026-11-01: D-05 diubah menjadi **APPROVED (revised)**. Scope: **CSV + XLSX**, **tanpa PDF**. Ini menyimpang dari requirements asli §5.9 (PDF diprioritaskan). Alasan: permintaan pengguna; PDF ditunda ke fase berikutnya (butuh library `pdf` + setup sign/watermark yang tidak mendesak).



- 2026-11-01: D-01, D-02, D-03, D-04, D-07 diubah dari PROPOSED menjadi APPROVED atas persetujuan pengguna.
- D-05, D-06, D-08 tetap PROPOSED.

## Aturan

- Default sementara tidak boleh diam-diam dianggap final.
- Perubahan status menjadi `APPROVED` harus dicatat dengan tanggal dan alasan.
- Jika keputusan berubah, keputusan lama ditandai `SUPERSEDED`, bukan dihapus.

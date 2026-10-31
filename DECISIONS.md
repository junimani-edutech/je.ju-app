# DECISIONS.md — Keputusan Proyek

Status keputusan:
- `PROPOSED` = usulan, belum disetujui, tidak boleh dianggap final.
- `APPROVED` = disetujui dan menjadi acuan.
- `REJECTED` = ditolak.
- `SUPERSEDED` = digantikan keputusan lain.

Urutan acuan jika ada konflik:
`DECISIONS.md` yang disetujui → `docs/REQUIREMENTS.md` terbaru → `MASTER_BLUEPRINT.md` → asumsi AI.

## Daftar keputusan terbuka

| ID | Keputusan | Default sementara | Status | Menyentuh | Perlu persetujuan sebelum |
|---|---|---|---|---|---|
| D-01 | Satu pengguna dapat bergabung ke beberapa usaha? | Ya, dengan isolasi data per usaha. | PROPOSED | Arsitektur, keamanan | Skema database/auth |
| D-02 | Metode pengakuan pendapatan? | Pisahkan kas masuk dan laba sampai aturan disetujui. | PROPOSED | Rumus uang | Laporan laba/arus kas |
| D-03 | Buat transaksi offline? | Ya untuk operasi yang ditentukan; transaksi uang bisa menunggu konfirmasi. | PROPOSED | Arsitektur, keamanan | Fase offline/sync |
| D-04 | Hapus transaksi terkonfirmasi? | Tidak; gunakan reversal/cancel dengan audit. | PROPOSED | Keamanan, audit | Modul pembayaran/keuangan |
| D-05 | Ekspor awal? | PDF dan CSV; XLSX setelah diuji. | PROPOSED | Fitur | Fase laporan |
| D-06 | Batas pengguna/data dan biaya cloud? | Tetapkan setelah estimasi pemakaian dan pemeriksaan kuota. | PROPOSED | Biaya/operasional | Sebelum produksi |
| D-07 | Multi-currency? | Tidak untuk versi awal; IDR. | PROPOSED | Rumus uang, arsitektur | Skema keuangan |
| D-08 | Retensi data lokal setelah akses dicabut? | Tetapkan kebijakan; batasi cache sensitif. | PROPOSED | Keamanan/privasi | Fase offline/sync |

## Catatan

- Default sementara tidak boleh diam-diam dianggap final.
- Perubahan status menjadi `APPROVED` harus dicatat dengan tanggal dan alasan.
- Jika keputusan berubah, keputusan lama ditandai `SUPERSEDED`, bukan dihapus.

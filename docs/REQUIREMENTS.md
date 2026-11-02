# JE.JU — REQUIREMENTS SPECIFICATION

Versi 1.0 • 31 Oktober 2026

Dokumen kebutuhan produk untuk aplikasi pengelolaan pesanan dan keuangan usaha. Disiapkan sebagai acuan AI dalam pengembangan melalui GitHub Codespaces.

Platform sasaran: Android, iOS, web, dan PC/desktop. Dukungan setiap platform harus dibuktikan melalui pengujian.

Arsitektur awal: Flutter + Dart, Supabase/PostgreSQL, GitHub, GitHub Codespaces, dan AI sebagai asisten coding.

Status: draft kerja untuk validasi kebutuhan. Keputusan terbuka tidak boleh diasumsikan diam-diam oleh AI.

## 1. Tujuan dan ruang lingkup

JeJu membantu usaha mengelola pesanan, pelanggan, pembayaran, pemasukan, pengeluaran, akun keuangan, laporan, dan kerja tim. Aplikasi dirancang agar aktivitas tertentu tetap berjalan saat offline, lalu disinkronkan ke cloud ketika koneksi tersedia.

### Tujuan

- Mencatat pesanan dan status pengerjaan dengan riwayat perubahan.
- Mencatat pembayaran dan pengeluaran tanpa penghitungan ganda.
- Menyediakan ringkasan keuangan dan laporan yang dapat disesuaikan.
- Mendukung beberapa pengguna dengan peran berbeda.
- Mendukung offline, antrean sinkronisasi, backup, dan pemulihan data.

### Di luar ruang lingkup versi awal

- Manajemen stok lengkap dan FIFO; direncanakan untuk tahap berikutnya.
- Integrasi langsung ke DANA, bank, GoSend, Maxim, Shopee, atau penyedia eksternal.
- Akuntansi pajak penuh, payroll, multi-currency, dan e-faktur.
- Sinkronisasi peer-to-peer tanpa cloud.

Pencatatan metode pembayaran tidak sama dengan integrasi otomatis ke penyedia pembayaran.

## 2. Prinsip produk

- Cloud menjadi sumber data bersama; database lokal menyimpan cache dan antrean offline.
- Data setiap usaha harus terisolasi dari usaha lain.
- Transaksi keuangan terkonfirmasi tidak boleh dihapus diam-diam; koreksi memakai pembatalan/reversal dengan audit.
- Perubahan skema database dilakukan melalui migration yang tercatat.
- Pengaturan khusus tidak boleh menjalankan SQL atau kode arbitrer.
- Pembaruan harus mempertahankan data lama dan menyediakan backup/pemulihan yang diuji.

## 3. Platform dan arsitektur

| Komponen | Kebutuhan |
|---|---|
| Klien | Flutter + Dart; UI responsif untuk ponsel, tablet, web, dan desktop. |
| Backend | Supabase/PostgreSQL untuk autentikasi, database, kebijakan akses, dan storage bila diperlukan. |
| Kode | GitHub repository sebagai sumber resmi; gunakan branch dan commit. |
| Lingkungan | GitHub Codespaces untuk coding, analisis, dan tes dari browser. |
| Asisten AI | AI memakai konteks yang diberikan; jangan menganggap otomatis mengetahui repository. |
| Lokal | Database lokal dan antrean sinkronisasi; teknologi final diputuskan di spesifikasi teknis. |
| Laporan | Query terdefinisi dengan filter dan ekspor yang diizinkan. |

Batas platform: Codespaces Linux tidak menggantikan macOS/Xcode untuk signing/build iOS atau lingkungan Windows untuk menguji build native Windows.

## 4. Pengguna dan hak akses

| Peran | Hak akses minimum |
|---|---|
| Owner/Pemilik | Akses penuh pada usaha miliknya; anggota, pengaturan, data, laporan, ekspor, dan pencabutan akses. |
| Admin usaha | Mengelola operasional/pengaturan sesuai izin; tidak otomatis dapat mengambil alih kepemilikan. |
| Kasir/Keuangan | Pembayaran, pemasukan, pengeluaran, akun, dan laporan sesuai izin. |
| Staf pesanan | Mengelola pesanan/pelanggan sesuai izin; tidak otomatis mendapat akses penuh ke keuangan. |
| Viewer | Melihat data yang diizinkan tanpa mengubahnya. |

Hak akses harus diterapkan di antarmuka dan backend/database. Menyembunyikan tombol saja bukan pengamanan.

## 5. Modul fungsional

### 5.1 Autentikasi dan usaha

- Masuk/keluar dengan autentikasi yang dipilih; bergabung ke usaha melalui mekanisme aman.
- Setiap operasi memvalidasi keanggotaan dan `business_id`. Satu pengguna dapat menjadi anggota beberapa usaha bila desain final mendukungnya.

### 5.2 Dashboard

- Ringkasan pesanan, pembayaran diterima, sisa tagihan, pemasukan, pengeluaran, dan arus kas berdasarkan periode.
- Menampilkan periode, zona waktu, dan status sinkronisasi; angka konsisten dengan laporan.

### 5.3 Pelanggan

- Tambah, lihat, ubah, cari, dan arsipkan pelanggan; kontak minimum yang diperlukan, alamat/catatan opsional.
- Data pelanggan yang terkait transaksi tidak dihapus permanen secara sembarangan.

### 5.4 Pesanan

- Nomor unik, pelanggan, tanggal, item/uraian, kuantitas, harga, diskon, ongkir/biaya, catatan, dan status.
- Status pengerjaan terpisah dari status pembayaran; perubahan status memiliki riwayat waktu dan pelaku.
- Item sederhana dapat dicatat; pengelolaan stok penuh belum termasuk.

### 5.5 Pembayaran

- Pembayaran penuh/sebagian, tanggal, nominal, metode, referensi, akun tujuan, dan catatan.
- Satu pesanan dapat menerima beberapa pembayaran; koreksi memiliki alasan dan jejak audit.
- Gunakan ID unik/idempotensi untuk mencegah pembayaran tercatat dua kali.

### 5.6 Pemasukan dan pengeluaran

- Transaksi non-pesanan mencatat kategori, tanggal, nominal, akun/metode, deskripsi, lampiran opsional, dan pembuat.
- Pembayaran pesanan tidak dihitung ulang sebagai pemasukan umum; transaksi terkonfirmasi tidak dihapus tanpa jejak.

### 5.7 Akun dan transfer

- Akun kas, rekening, dan e-wallet sebagai tempat saldo operasional.
- Transfer mengurangi saldo sumber dan menambah saldo tujuan; tidak diklasifikasikan sebagai pemasukan/beban.

### 5.8 Pengaturan

- Nama/logo/kontak usaha, tema/warna dalam batas yang disediakan, kategori, metode pembayaran, status yang diizinkan, kolom khusus bertipe aman.
- Kategori yang sudah dipakai diarsipkan. Pengaturan tidak boleh diam-diam mengubah rumus keuangan inti.

### 5.9 Laporan dan ekspor

- Laporan pesanan, tagihan, pembayaran, pemasukan, pengeluaran, saldo akun, arus kas, dan laba operasional sederhana.
- Filter tanggal, kategori, status, pelanggan, dan akun; template laporan dapat disimpan oleh pengguna berwenang.
- PDF dan CSV menjadi prioritas; XLSX ditambahkan setelah library dan kompatibilitas diuji.

**Addendum 2026-11-01 (D-05 revised):** Prioritas ekspor **direvisi**. Implementasi Fase 6 menghasilkan **CSV + XLSX**; **PDF ditunda** ke fase berikutnya. Alasan: permintaan pengguna, PDF butuh library `pdf` + setup tambahan (sign/watermark) yang tidak mendesak. Lihat `DECISIONS.md` D-05.

### 5.10 Tim dan audit

- Undangan anggota, peran, pencabutan akses, dan audit tindakan sensitif.

### 5.11 Offline dan sinkronisasi

- Tampilkan status online/offline dan antrean sinkronisasi.
- Operasi offline yang diizinkan masuk antrean lokal, retry dengan ID unik, dan divalidasi server.
- Konflik ditangani per tipe data; pembayaran terkonfirmasi tidak memakai last-write-wins.

### 5.12 Backup dan pemulihan

- Sediakan backup/ekspor dan prosedur restore yang diuji.
- Validasi file dan versi skema sebelum pemulihan; pembaruan besar harus punya checkpoint dan pengujian migrasi.

## 6. Aturan keuangan

| Istilah | Definisi kebutuhan |
|---|---|
| Subtotal | Jumlah item sebelum diskon dan biaya tambahan. |
| Total pesanan | Subtotal - diskon + biaya tambahan yang dibebankan. |
| Pembayaran valid | Pembayaran yang belum dibatalkan/reversal dan memenuhi aturan konfirmasi. |
| Sisa tagihan | Total pesanan - total pembayaran valid yang dialokasikan; kelebihan bayar tetap harus terdeteksi. |
| Arus kas bersih | Kas masuk valid - kas keluar valid; transfer internal tidak masuk hitungan. |
| Laba operasional sederhana | Pendapatan diakui - beban diakui pada periode; tidak otomatis sama dengan arus kas. |

### Aturan wajib

- Gunakan integer rupiah untuk IDR atau numeric desimal presisi; jangan gunakan floating-point untuk uang.
- Status pesanan dan pembayaran berbeda.
- Pembayaran pesanan tidak boleh dihitung dua kali.
- Transfer internal bukan pendapatan atau beban.
- Koreksi mencatat pelaku, waktu, alasan, dan transaksi asal.
- Aturan laba harus menetapkan perlakuan uang muka, refund, ongkir, biaya, dan pengakuan pendapatan sebelum dianggap final.

## 7. Offline dan sinkronisasi

| Kondisi | Perilaku yang diharapkan |
|---|---|
| Online | Operasi disimpan ke backend setelah validasi akses dan data. |
| Offline | Data lokal tersedia dibaca; operasi yang diizinkan masuk antrean dan ditandai belum tersinkron. |
| Koneksi kembali | Operasi dikirim ulang dengan ID unik; server mencegah duplikasi. |
| Edit bersamaan | Konflik dideteksi dan ditangani sesuai tipe data; konflik uang tidak ditimpa diam-diam. |
| Pembayaran belum dikonfirmasi | Tampilkan status menunggu sinkronisasi/konfirmasi, bukan final. |
| Akses dicabut | Server menolak operasi berikutnya; sesi/cache sensitif ditangani sesuai kebijakan. |

Teknologi database lokal, enkripsi lokal, retensi cache, dan algoritme konflik harus ditetapkan pada `OFFLINE_SYNC.md` sebelum fase offline.

## 8. Keamanan dan privasi

- Aktifkan RLS pada semua tabel yang terekspos melalui API.
- Pastikan `business_id` sesuai dengan keanggotaan pengguna pada setiap operasi.
- Jangan pernah menaruh service-role key atau secret backend di aplikasi klien/repository.
- Validasi di klien dan server; server tetap otoritas data dan akses.
- Gunakan storage privat untuk lampiran dan tautan akses terbatas bila diperlukan.
- Batasi ekspor berdasarkan peran; audit tindakan sensitif.
- Sediakan pencabutan akses/sesi dan uji akses lintas usaha.
- Hindari mengumpulkan data pribadi yang tidak diperlukan.

## 9. Kebutuhan nonfungsional

| Aspek | Target awal |
|---|---|
| Kemudahan | Navigasi konsisten, validasi formulir, pesan error jelas. |
| Responsif | Layak di ponsel/tablet; layout web/desktop dirancang untuk ukuran layar terkait. |
| Kinerja | Pencarian, filter, pagination untuk daftar besar; target numerik ditetapkan setelah baseline. |
| Keandalan | Idempotensi operasi keuangan, error dapat dipulihkan, status sinkronisasi terlihat. |
| Pemeliharaan | Kode modular, migration terurut, dokumentasi dan tes otomatis. |
| Portabilitas | Klaim dukungan platform hanya setelah build/test terbukti. |
| Biaya | Utamakan tier rendah selama memadai; pantau kuota dan siapkan ekspor/migrasi. |
| Aksesibilitas | Kontras, label kontrol, ukuran teks, dan alur yang mudah dipahami. |

## 10. Kriteria penerimaan

- Pengguna tanpa keanggotaan tidak dapat membaca/mengubah data usaha.
- Pesanan, pembayaran sebagian, sisa tagihan, pembatalan, dan riwayat menghasilkan angka konsisten.
- Pembayaran pesanan tidak terhitung ganda dalam laporan pemasukan.
- Transfer tidak mengubah total pendapatan/beban.
- Filter laporan dan ekspor mengikuti izin pengguna.
- Operasi offline yang didukung bertahan setelah aplikasi ditutup dan dibuka kembali.
- Sinkronisasi ulang tidak membuat pesanan/pembayaran duplikat.
- Konflik penting ditandai dan diselesaikan dengan aturan eksplisit.
- Migrasi versi baru tidak menghilangkan data lama dalam pengujian.
- Setelah semua edit pada fase selesai, jalankan format/analyze/tes relevan; jangan melaporkan tes lulus jika tidak dijalankan.

## 11. Roadmap

| Fase | Hasil |
|---|---|
| 0 — Spesifikasi | Requirements, arsitektur, skema, aturan keuangan, keamanan, offline/sync, UI/UX, tes, keputusan terbuka. |
| 1 — Fondasi | Repository, Codespaces, Flutter, struktur folder, instruksi AI, tes dasar. |
| 2 — Backend | Auth, usaha/anggota, RLS, migration, tes isolasi. |
| 3 — Kerangka UI | Navigasi, tema, state management, layer dasar. |
| 4 — Pesanan | Pelanggan, pesanan, item, status, pembayaran, riwayat. |
| 5 — Keuangan | Pemasukan/pengeluaran, akun, transfer, saldo dan arus kas. |
| 6 — Pengaturan/laporan | Kategori, kolom khusus, template, PDF/CSV lalu XLSX. |
| 7 — Tim/audit | Undangan, peran, pencabutan akses, audit. |
| 8 — Offline/sync | Database lokal, antrean, retry, idempotensi, konflik, multi-device. |
| 9 — Validasi/rilis | Build dan tes platform, backup/restore, dokumentasi distribusi. |

## 12. Kontrak kerja AI

- Baca `AGENTS.md`, `MASTER_BLUEPRINT.md`, `REQUIREMENTS.md`, `CURRENT_STATE.md`, `DECISIONS.md`, dan spesifikasi relevan sebelum coding.
- Periksa file aktual; jangan mengarang file atau menganggap fitur sudah ada.
- Sebelum coding, laporkan pemahaman, konflik, dan daftar file dibuat/diubah/dihapus beserta alasannya.
- Kelompokkan perubahan satu fase per filepath agar file tidak bolak-balik diedit pada fase yang sama.
- Jangan menghapus fitur berfungsi tanpa persetujuan; perubahan database harus memakai migration.
- Jangan memasukkan secret ke klien atau commit.
- Jalankan format, analyze, tes relevan setelah seluruh edit fase selesai; laporkan hasil yang benar-benar terjadi.
- Perbarui `CURRENT_STATE.md` dan `CHANGELOG.md` saat pekerjaan fase selesai.
- Jika keputusan menyentuh arsitektur, keamanan, atau rumus uang, berhenti dan minta persetujuan.

## 13. Keputusan terbuka

| ID | Keputusan | Default sementara |
|---|---|---|
| D-01 | Satu pengguna dapat bergabung ke beberapa usaha? | Ya, dengan isolasi data per usaha. |
| D-02 | Metode pengakuan pendapatan? | Pisahkan kas masuk dan laba sampai aturan disetujui. |
| D-03 | Buat transaksi offline? | Ya untuk operasi yang ditentukan; transaksi uang bisa menunggu konfirmasi. |
| D-04 | Hapus transaksi terkonfirmasi? | Tidak; gunakan reversal/cancel dengan audit. |
| D-05 | Ekspor awal? | PDF dan CSV; XLSX setelah diuji. |
| D-06 | Batas pengguna/data dan biaya cloud? | Tetapkan setelah estimasi pemakaian dan pemeriksaan kuota. |
| D-07 | Multi-currency? | Tidak untuk versi awal; IDR. |
| D-08 | Retensi data lokal setelah akses dicabut? | Tetapkan kebijakan; batasi cache sensitif. |

## 14. Batas dokumen dan langkah berikutnya

- Dokumen ini menetapkan kebutuhan awal, bukan bukti aplikasi sudah dibangun atau diuji.
- Skema tabel/indeks ditulis rinci di `DATABASE_SCHEMA.md`.
- Rumus laba harus divalidasi sebelum dipakai untuk keputusan usaha.
- Kuota layanan cloud dan biaya deployment harus diperiksa saat implementasi.
- Android, iOS, Windows, dan web harus diuji secara terpisah.
- Offline penuh tidak boleh dijanjikan sebelum keamanan, konflik, dan sinkronisasi multi-perangkat lulus tes.

Urutan acuan jika ada konflik: keputusan yang disetujui di `DECISIONS.md` → spesifikasi kebutuhan terbaru → blueprint induk → asumsi AI. Konflik harus dilaporkan, bukan ditebak.

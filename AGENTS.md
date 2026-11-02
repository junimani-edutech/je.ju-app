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

## Frontend conventions (Flutter / Riverpod)

- Gunakan **Riverpod 3.x**. `StateProvider` dan `StateNotifierProvider` sudah dihapus/di-deprecate; jangan dipakai untuk kode baru.
- State mutable sederhana: `NotifierProvider<XNotifier, T>(XNotifier.new)`.
- Stream dari service: `StreamProvider<T>`.
- Future sekali ambil: `FutureProvider<T>`.
- State async yang bisa dimutasi: `AsyncNotifierProvider`.
- Semua provider di `lib/core/providers.dart` atau file provider per fitur.
- Widget yang memakai `ref.watch`/`ref.read` adalah `ConsumerWidget` / `ConsumerStatefulWidget`.
- Untuk widget test, override `authServiceProvider`/`businessServiceProvider` dengan fake di `test/fake/`.
- `find.text(...)` di widget test rapuh jika teks muncul di >1 konteks (mis. AppBar + tombol, atau label NavigationBar + konten). Prefer `find.byKey`, `find.descendant(of: ..., matching: ...)`, atau `findsWidgets` sesuai konteks.
- Breakpoint adaptif UI: **720 logical pixels** (di bawah: mobile, di atas/sama: wide).
- Test viewport default Flutter adalah 800×600 (wide). Untuk menguji mobile, set `tester.view.physicalSize = Size(400, 800)` dan `devicePixelRatio = 1.0`, dengan `addTearDown` untuk reset.

## Test conventions (pgTAP & Flutter)

- Di pgTAP, semua query dalam satu file test berjalan dalam satu transaksi (satu `begin/rollback`). Artinya `now()`/`created_at` **identik** untuk semua baris yang di-insert. Jangan pakai `order by created_at` untuk tie-break. Pakai `id`, `order_number`, atau cek eksistensi via `array_agg` / `count(*)`.
- Untuk multi-row assertions (mis. "dua order_number ada"), gunakan `array_agg(col order by col)` + `is(..., array[...], ...)` — deterministik dan mudah dibaca.
- Jangan andalkan `unique` untuk membuktikan nilai — verifikasi nilai secara eksplisit.

## Flutter dialog & controller pitfalls

- **Jangan** `dispose()` `TextEditingController` yang dibuat di dalam method setelah dialog/sheet close. Dialog masih dalam animasi close ~150ms ketika method selesai, sehingga widget masih memakai controller di frame berikutnya → crash "A TextEditingController was used after being disposed".
- Untuk dialog one-shot: biarkan controller sampai GC, atau gunakan `TextFormField` + capture variable lokal, atau buat dialog sebagai `StatefulWidget` terpisah dengan controller di `State`.
- Controller yang merupakan field `State` (mis. `late final TextEditingController x`) **tetap** di-dispose di `State.dispose()`. Aman karena lifecycle-nya dikelola State.

## Konvensi patch kode (pelajaran Langkah 14)

- Sebelum patch Python `replace()` pada file yang pernah diformat `dart format`, tampilkan 5-8 baris sekitar blok target via `grep -n -A N` atau `sed -n`. Pattern harus presisi, bukan tebakan.
- Heredoc (`cat > file <<EOF`) dengan isi >1.5 KB sering terpotong di terminal Codespaces. Untuk file baru yang panjang, gunakan `printf %sn ...` chunked (5-10 baris per chunk) dengan penutup bersih.
- Kalau memindahkan provider yang punya banyak consumer, jangan buat file baru yang mengimport `core/providers.dart` (siklus). Cukup ubah definisi di tempat.
- `gen_random_bytes` butuh pgcrypto di schema `extensions` — bukan search_path `public`. Pakai `gen_random_uuid()` x2 untuk token 256-bit.
- Saat mendefinisikan `RETURNS TABLE`, kualifikasi kolom dalam SQL dengan alias tabel (`alias.kolom`) — kalau tidak, akan ambigu dengan OUT parameter.

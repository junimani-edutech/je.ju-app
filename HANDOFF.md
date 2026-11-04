# HANDOFF.md — Konteks Proyek JeJu

> **Cara pakai:**
> - Jika kamu (AI baru) punya akses ke repo ini: cukup baca file ini + `AGENTS.md`, `DECISIONS.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `docs/REQUIREMENTS.md`, `docs/DATABASE_SCHEMA.md`.
> - Jika tidak punya akses repo: seluruh konteks yang dibutuhkan ada di dokumen ini. Setelah membaca, konfirmasi pemahaman + konflik + daftar file sebelum menulis kode.

**Terakhir diperbarui:** 2026-11-04
**Versi:** v1.0.0 (code complete, menunggu deploy final)
**Repo:** `github.com/junimani-edutech/je.ju-app` (branch `main`)
**Working directory di Codespace:** `/workspaces/je.ju-app`

---

## 1. Identitas Proyek

**JeJu** adalah aplikasi pengelolaan pesanan dan keuangan untuk **UMKM Indonesia**. Tujuan:
- Mencatat pesanan + status pengerjaan (dengan riwayat).
- Mencatat pembayaran tanpa double-count.
- Menyediakan rekap keuangan, arus kas, dan laporan.
- Multi-user dengan peran (owner/admin/cashier/order_staff/viewer).
- **Offline-first**: read data lokal, write transaksi tertentu, sync saat online.

**Di luar scope v1.0.0** (sengaja ditunda):
- Manajemen stok/inventori lengkap + FIFO
- Integrasi langsung DANA/bank/GoSend/Shopee
- Multi-currency (IDR saja)
- Akuntansi pajak, payroll, e-faktur
- Sinkronisasi peer-to-peer

---

## 2. Tech Stack

| Layer | Teknologi |
|---|---|
| Frontend | Flutter 3.47.9 stable + Dart 3.13.7 |
| State mgmt | Riverpod 3.x (BUKAN 2.x — `StateProvider` sudah dihapus) |
| Routing | `go_router` (StatefulShellRoute.indexedStack) |
| UI | Material 3, adaptive (bottom nav < 720px, rail ≥ 720px) |
| Chart | `fl_chart` |
| PDF | `pdf` + `printing` |
| Backend | Supabase (PostgreSQL 17) |
| Auth | Supabase Auth (email/password) |
| Local DB | Drift (SQLite) + `drift_flutter` |
| Sync | Custom queue + `connectivity_plus` |
| Deploy Web | Netlify (drag-drop `build/web` zip) |
| Deploy DB | Supabase Cloud (`supabase db push`) |
| CI/CD | Manual (Codespace) — CI otomatis belum |
| Ekspor | CSV + XLSX (`csv`, `excel`); PDF ditunda untuk laporan |

**Kredensial:** Semua rahasia di `.env` (gitignored). Hanya `SUPABASE_URL` dan `SUPABASE_ANON_KEY` (anon key aman di klien karena RLS). **JANGAN PERNAH** masukkan `service_role` key ke klien atau repo.

---

## 3. Aturan Kerja AI (WAJIB)

Baca `AGENTS.md` di repo. Ringkasannya:

1. **Baca dulu sebelum coding**: AGENTS.md → MASTER_BLUEPRINT.md → docs/REQUIREMENTS.md → CURRENT_STATE.md → DECISIONS.md.
2. **Laporkan sebelum coding**: pemahaman, konflik, daftar file yang akan dibuat/diubah/dihapus beserta alasannya.
3. **Berhenti dan minta persetujuan** jika menyentuh: arsitektur, keamanan, atau rumus uang.
4. **Jangan hapus fitur berfungsi** tanpa persetujuan eksplisit.
5. **Migration untuk perubahan DB** — jangan edit migration lama, buat file baru.
6. **Jangan commit secret**, service-role key, atau kredensial produksi.
7. **Setelah edit**: `dart format`, `flutter analyze`, `flutter test`, `supabase test db` (kalau menyentuh DB).
8. **Jangan klaim test lulus** jika tidak dijalankan.
9. **Update `CURRENT_STATE.md` + `CHANGELOG.md`** setelah fase selesai.

**Urutan acuan konflik:** `DECISIONS.md` APPROVED → `docs/REQUIREMENTS.md` → `MASTER_BLUEPRINT.md` → asumsi AI.

---

## 4. Struktur Folder


---


```bash
cd "$(git rev-parse --show-toplevel)"

cat >> HANDOFF.md <<'HANDOFF_EOF'

---

## 5. Keputusan yang Sudah Disetujui (APPROVED)

Semua keputusan di bawah ini sudah disetujui pemilik proyek. Detail lengkap di `DECISIONS.md`.

| ID | Keputusan | Status |
|---|---|---|
| **D-01** | Multi-business per user (isolasi per `business_id`) | APPROVED |
| **D-02** | Pisahkan kas masuk dan laba (rumus laba belum final) | APPROVED |
| **D-03** | Transaksi offline untuk operasi terpilih; pembayaran bisa pending | APPROVED |
| **D-04** | Transaksi terkonfirmasi tidak dihapus; reversal + audit | APPROVED |
| **D-07** | IDR saja untuk v1.0 | APPROVED |
| **D-05** (revised) | Ekspor CSV + XLSX; PDF ditunda | APPROVED |
| **A-01..A-08** | Auth email/password, no OAuth, no email confirm lokal, onboarding wajib, timezone default `Asia/Jakarta`, no invite di v1.0, RPC-based create_business, Riverpod, go_router | APPROVED |
| **U-01..U-07** | Breakpoint 720px, 4 bottom tab (Dashboard/Pesanan/Pelanggan/Lainnya), light+dark, Material icons, ComingSoon placeholder, More menu sebagai halaman | APPROVED |
| **C-01..C-08** | CurrentBusiness = bisnis pertama, archive customers, client-side search, field min (name wajib), write role owner/admin/cashier/order_staff, trigger set_created_by, currentMemberProvider, default list Aktif | APPROVED |
| **Q1** | Seed `order_statuses` otomatis (`draft`, `process`, `done`, `cancelled`) saat bisnis dibuat | APPROVED |
| **Q5-A** | Format `order_number` = `YYYYMMDD-NNN` per bisnis per hari, server-side + advisory lock | APPROVED |
| **Q3-A** | Satu payment → satu order (multi-order payment ditunda) | APPROVED |
| **Q4-A** | Refund = payment baru + `reversal_of_payment_id` | APPROVED |
| **E-01-A** | Recompute `paid_amount` di RPC (bukan trigger) | APPROVED |
| **Q8-A** | Seed `payment_methods` + `accounts` otomatis saat bisnis dibuat | APPROVED |
| **F5-01..F5-04** | Payments & transactions terpisah (tidak double-count); transfer idempotent; saldo akun computed (tidak cache); void_payment copy account_id + payment_method_id | APPROVED |
| **F6-01 (revised)** | Ekspor CSV + XLSX (tanpa PDF) | APPROVED |
| **F6-02..F6-04** | Rekap default bulan berjalan; form field bisnis saja (no logo); custom columns ditunda | APPROVED |
| **F7-01..F7-04** | Undangan manual link (bukan email SMTP); alur accept via token; multi-business dropdown di Dashboard; audit viewer UI ditunda | APPROVED |
| **Q2** | Profiles readable by co-member (via RPC `list_business_members`) | APPROVED |
| **F8-01..F8-05** | Drift SQLite; tanpa enkripsi lokal (v1.0); server-wins master data + custom merge transaksi; write pelanggan/pesanan/pembayaran/transaksi/transfer/produk (auth & void/change status online-only); idempotency key wajib | APPROVED |
| **P-01..P-04** | `product_id` di `order_items`; no seed produk; ProductPicker bottom sheet; harga/deskripsi bisa diedit setelah pilih | APPROVED |

---

## 6. Riwayat Fase (Chronological)

### Fase 1 — Fondasi (commits `62dc3d1` → `32213d0`)
- 20 migration SQL (schema 16 tabel + RPC + RLS + seed).
- Auth backend (trigger profil, RPC create_business).
- Auth UI (SignIn, SignUp, Onboarding).
- 8 Flutter + 27 pgTAP tests.

### Fase 2 — RLS Isolasi
- pgTAP verifikasi isolasi per business.

### Fase 3 — App Shell Adaptif (`ba98f9c`)
- Bottom nav (< 720px) + Rail (≥ 720px).
- Theme light + dark.
- 5 Flutter tests.

### Fase 4 — Pelanggan, Pesanan, Pembayaran (`66c6eae` → `059ad7e`)
- Migration 0200: set_created_by triggers.
- Migration 0201: seed order_statuses (Q1).
- Migration 0300: RPC create_order + updated_at trigger.
- Migration 0301: change_order_status + cancel_order.
- Migration 0400: seed payment methods + accounts (Q8-A).
- Migration 0401: record_payment + void_payment + helpers.
- Migration 0500: fix void_payment copy account_id.
- UI: CustomersScreen, OrdersScreen, PaymentsScreen (dulu placeholder).
- 18 Flutter + 45 pgTAP tests.

### Fase 5 — Keuangan (`f0f240e`)
- Migration 0501: finance RPCs (transactions, transfers, account_balance, cash_flow_summary).
- Migration 0502: account_balances (bulk).
- UI: TransactionsScreen, TransfersScreen, dashboard cards.
- 6 Flutter + 33 pgTAP.

### Fase 6 — Pengaturan, Laporan, Ekspor (`7e0ecce`)
- Migration 0600: update_business_profile.
- Migration 0601: report_summary.
- UI: SettingsScreen (profil bisnis), ReportsScreen (summary + export CSV/XLSX).
- 10 Flutter + 26 pgTAP.

### Fase 7 — Tim & Undangan (`5906011`)
- Migration 0700: business_invitations table + RLS.
- Migration 0701: create_invitation + revoke_invitation.
- Migration 0702: accept_invitation.
- UI: MembersScreen, InviteDialog, AcceptInviteScreen.
- Multi-business: CurrentBusinessNotifier + BusinessSelectorButton.
- 8 Flutter + 18 pgTAP.

### Fase 8 — Offline & Sync (`d7f5790`)
- Drift SQLite dengan 10 tabel mirror + `sync_queue`.
- SyncService (periodic 30s, retry, backoff).
- Wrapper Offline* (6 services).
- Migration 0800: upsert_order_with_items.
- Migration 0801: upsert_payment.
- Migration 0802: upsert_transaction + upsert_transfer.
- kIsWeb guard untuk web.
- 17 Flutter + 11 pgTAP tests.

### Fase 9 — Deploy (tanpa commit khusus)
- Deploy web ke **Netlify** (drag-drop `build/web` zip). Vercel dicoba tapi rumit (Flutter butuh install SDK di build server) → diputuskan pakai Netlify.
- Supabase Cloud: `supabase link + db push` — berhasil.

### Fase 11 — Master Produk (belum commit)
- Migration 1100: tabel `products` + RLS + RPC upsert_product + kolom `order_items.product_id`.
- Model + service (Supabase + Offline + Fake).
- Drift `ProductsTable` + LocalProductsRepo + ProductsDispatcher.
- UI: ProductsScreen (tab Aktif/Arsip), ProductFormSheet, ProductPicker bottom sheet.
- Integrasi picker ke OrderFormSheet.

### Fase 12 — Polish P0 + P1 (belum commit)
- 12.1: `product_id` end-to-end (migration + Dart + test).
- 12.2: `PaymentsScreen` real (list semua payment + void + tab filter).
- 12.3: Date range picker di ReportsScreen (tab Kustom).
- 12.4: Tab Arsip di ProductsScreen.
- 12.5: Search di Orders + Transactions.
- 12.6: Offline UX polish (`formatError` + `showErrorSnack`).

**Total: 19+ commit, 71 Flutter tests, 195 pgTAP tests, ~25k baris kode.**

---

## 7. State Terkini (paling penting untuk AI baru)

### ✅ Selesai
- Semua 12 fase code complete.
- `flutter analyze` → **No issues found!**
- `flutter test` → **+71: All tests passed!**
- `supabase test db` → **Files=14, Tests=195, PASS**
- Supabase Cloud sudah punya semua migration (via `supabase db push`).
- Aplikasi web berjalan di URL Netlify.

### ⚠️ Belum selesai
1. **Commit v1.0.0 belum dilakukan** — Fase 11 + 12 masih **uncommitted** di working directory.
2. **Build web final saat ini SIGTERM** — `dart2js` dengan `-O4` + tanpa swap di Codespace → OOM spike. Solusi: pakai `--dart2js-optimization O1`. Build sebelumnya berhasil dengan default (14 MB zip), masalah ini transient.
3. **Deploy final belum** — `web.zip` terakhir mungkin sudah tidak up-to-date dengan kode Fase 12. Perlu build ulang (dengan O1) → zip → upload Netlify.

### Yang harus dilakukan AI baru (kalau melanjutkan)

---

## 8. Konvensi Kode Penting

### Riverpod 3.x
- **JANGAN** pakai `StateProvider` atau `StateNotifierProvider` (sudah dihapus/deprecate).
- Pakai `NotifierProvider` untuk state mutable, `StreamProvider` untuk stream, `FutureProvider` untuk future sekali-ambil, `AsyncNotifierProvider` untuk state async yang bisa dimutasi.
- **PENTING**: `AsyncNotifier` sudah punya method bawaan `update(...)`. Kalau perlu method kustom, **rename** jadi `updateXxx` (mis. `updateProduct`) untuk hindari `invalid_override`.

### Drift
- Setelah ubah schema (add column, add table), **WAJIB** `dart run build_runner build --delete-conflicting-outputs`.
- Bump `schemaVersion` di `app_database.dart` + tambah `MigrationStrategy` (`onUpgrade` dengan `addColumn`).
- **Patch script Python yang kompleks ke file yang sudah di-`dart format` sering MISS.** Untuk file kompleks: full rewrite lebih aman daripada patch parsial.

### pgTAP
- `plan(N)` harus **persis match** jumlah assertion. Kalau tambah assertion, bump plan.
- Satu file test = satu transaksi (`begin/rollback`). `now()`/`created_at` identik untuk semua baris di dalam satu file → **jangan pakai `order by created_at` untuk tie-break**. Pakai `id`, `order_number`, atau `array_agg`.
- Setelah edit SQL, jalankan `supabase db reset` **DULU** sebelum `supabase test db` — kalau tidak, migration baru tidak di-apply ke DB lokal.

### Supabase CLI
- `supabase db push` push ke **cloud** (butuh `--linked` atau jawab Yes).
- `supabase db reset` reset **lokal** (apply semua migration).
- `supabase test db` jalankan pgTAP di **lokal**.
- Login: `supabase login` (Personal Access Token).

### Codespace (heredoc)
- **Heredoc `cat > file <<'EOF' ... EOF` > 1.5 KB sering terpotong** saat di-paste ke terminal Codespace.
- **Solusi**: pakai `printf '%s\n' 'baris1' 'baris2' ...` chunked (5-10 baris per chunk), atau pecah `cat` jadi 3-4 chunk append.
- Jangan pakai `<<EOF` untuk file panjang.

### Web build
- **Wajib** `.env` ada + `pubspec.yaml` `assets: - .env` (kalau pakai `flutter_dotenv`) **ATAU** pakai `--dart-define-from-file=.env` (lebih recommended, tidak butuh asset bundle).
- `--no-wasm-dry-run` mempercepat + hindari warning WAsm (Wasm tidak diaktifkan).
- `--dart2js-optimization O1` untuk hemat RAM (~30%).
- `--dart-define-from-file=.env` inject `SUPABASE_URL` + `SUPABASE_ANON_KEY` ke bundle.

### kIsWeb guard
- Semua `Offline*Service` di-wrap dengan `if (kIsWeb) return Supabase*Service(...)` di `main.dart`.
- `appDatabaseProvider` melempar `UnsupportedError` di web (intentional — SQLite tidak jalan native di browser tanpa setup Wasm).
- `SyncBootstrap` return `child` langsung kalau `kIsWeb`.

### Uang
- SQL: `bigint`. Dart: `int`. **TIDAK ADA** `double`/`float` untuk amount.

### Error/Empty states
- Pakai `ErrorState` dan `EmptyState` dari `lib/shared/widgets/app_states.dart`.
- Pakai `SkeletonList` dari `skeleton_loader.dart` (bukan `CircularProgressIndicator` di list).
- `showErrorSnack(context, e)` untuk snackbar error yang ramah (offline → pesan jelas).

---

## 9. Known Issues & Workarounds

| Isu | Dampak | Workaround |
|---|---|---|
| Build web SIGTERM (OOM spike) | Build web gagal di Codespace | `--dart2js-optimization O1` + `--no-wasm-dry-run`; atau restart Codespace; atau build lokal di laptop |
| Void/cancel/changeStatus online-only | Gagal saat offline | Sudah ada UX offline yang jelas (`showErrorSnack`) |
| Search client-side | Lambat jika >1000 data | Server-side search + pagination ditunda ke v1.1 |
| No pagination di list | Sama | Idem |
| iOS/Windows build belum diuji | Belum bisa diklaim | Butuh macOS/Windows runner (Fase 13+) |
| Backup otomatis belum ada | Risiko kehilangan data | Manual `pg_dump` + `supabase db dump` |
| Push notification belum ada | Pengingat jatuh tempo belum otomatis | Manual via WhatsApp link (`wa.me`) — belum diimplementasi |

---

## 10. Langkah Selanjutnya (Roadmap v1.1)

Prioritas saran setelah v1.0.0 live:

1. **Dashboard "Produk Terlaris"** — data `product_id` di `order_items` sudah siap, tinggal query agregasi.
2. **Pengingat jatuh tempo via WhatsApp** — `https://wa.me/<phone>?text=<encoded>`.
3. **Laporan Laba Rugi PDF** — pakai `pdf` + `printing` yang sudah ada.
4. **Audit log viewer UI** — backend sudah catat, tinggal halaman.
5. **Pagination server-side** — untuk orders, payments, transactions.
6. **Pengingat otomatis via WA/email** — perlu SMTP atau WA Business API.
7. **Backup/restore script** — `pg_dump` + drill.
8. **iOS & Windows build** — via GitHub Actions dengan runner macOS/Windows.

---

## 11. File Referensi di Repo

Kalau kamu (AI baru) punya akses repo, baca juga:

- `AGENTS.md` — aturan kerja lengkap
- `DECISIONS.md` — semua keputusan + status
- `CURRENT_STATE.md` — status terkini
- `CHANGELOG.md` — riwayat lengkap per fase
- `docs/REQUIREMENTS.md` — spesifikasi lengkap dari PDF asli
- `docs/DATABASE_SCHEMA.md` — skema tabel + RPC + RLS + formula
- `MASTER_BLUEPRINT.md` — blueprint (masih draft)

---

## 12. Kontak & Akses

- **Pemilik:** `junimani-edutech` (GitHub) / `junimanifanaliloi29@gmail.com`
- **Supabase project ref:** `hlsxxozzyfbkuocnameu` (URL: `https://hlsxxozzyfbkuocnameu.supabase.co`)
- **Netlify:** drag-drop `build/web` zip ke `app.netlify.com/drop`. URL stabil jika sudah pernah deploy.
- **Anon key:** ada di `.env` lokal. **JANGAN** dimasukkan ke dokumen ini.

---

## 13. Cara Verifikasi Sebelum Klaim Selesai

Sebelum kamu (AI baru) klaim "selesai", jalankan **semua** ini dan laporkan hasil nyata:

```bash
dart format lib test
flutter analyze                  # harus "No issues found!"
flutter test                     # harus "All tests passed!" (target ≥71)
supabase db reset                # apply semua migration lokal
supabase test db                 # harus PASS (target ≥195)
flutter build web --release --dart-define-from-file=.env \
  --no-wasm-dry-run --dart2js-optimization O1
# Berhasil → build/web terisi
```

Jangan klaim test lulus kalau tidak dijalankan. Jangan klaim build sukses kalau tidak melihat `✓ Built build/web`.

---

**Selamat melanjutkan!** JeJu sudah sampai di v1.0.0 code-complete. Tinggal build + deploy final, lalu masuk v1.1.

---

## 14. Fase 13–18: UI Revamp, RBAC, Dashboard Interaktif & Deep Link (Nov 2026)

### ✅ Fitur Baru & Perbaikan
1. **Infrastruktur & Routing (Netlify Fix)**
   - Menambahkan `web/_redirects` (`/* /index.html 200`) untuk memperbaiki error 404 Netlify.
   - Mengaktifkan `usePathUrlStrategy()` di `main.dart` (URL tanpa `/#/`).
   - Redirect login di `app_router.dart` menyimpan parameter `?redirect=...` agar pengguna kembali ke halaman awal setelah login.
2. **UI/UX Premium**
   - Merombak total `SignInScreen` dengan desain "Aurora Soft Gradient" (efek blur, kartu melayang, glow button).
   - Branding baru: **PayNote**, sub-judul *powered by JeJu-App*.
   - Menyeragamkan navigasi Web (`AppShell`) dan Mobile menjadi 4 tab: Dashboard, Pesanan, Pelanggan, Lainnya.
3. **Keamanan (RBAC)**
   - Membuat function SQL `has_business_role` dan menerapkan RLS ketat di tabel `orders`, dll.
   - Membuat `AppPermission` dan `PermissionGuard` di Flutter.
   - Menu "Pengaturan" dan "Anggota & Undangan" disembunyikan dari role selain Owner/Admin.
4. **Dashboard Interaktif**
   - Kartu ringkasan (Pemasukan, Pengeluaran, Pembayaran, Arus Kas) kini *clickable* (drill-down) dan mengirim filter ke halaman transaksi via URL query params.
   - Widget `CashFlowChart` baru: Grafik batang *mirrored* (hijau ke atas, merah ke bawah) yang lebih informatif.
5. **Fitur Pengeluaran**
   - Form `ExpenseFormSheet` tersambung ke `transactionsProvider` (Supabase).
   - Dropdown sumber dana (Kas/Bank) dinamis mengambil dari `accountBalancesProvider`.
6. **Perbaikan Alur Undangan**
   - `AcceptInviteScreen` kini memiliki form inline (Email + Password).
   - Pengguna yang diundang bisa langsung mendaftar, login, dan menerima undangan dalam satu klik tanpa harus membuka email konfirmasi (karena `Confirm email` di Supabase sudah dimatikan).
   - Penanganan error `EMAIL_MISMATCH` dan `email_not_confirmed` yang ramah.
7. **Penanganan Web vs Mobile**
   - Fitur "Status Sinkronisasi" hanya muncul di Mobile.
   - Jika diakses paksa via URL di Web, `SyncStatusScreen` menampilkan pesan "Fitur Khusus Mobile" alih-alih layar merah error SQLite.

### ⚠️ Catatan Penting untuk Fase Selanjutnya (v1.1)
- Kategori pengeluaran saat ini digabung ke dalam kolom `description` (misal: "Bahan Baku - Beli telur"). Perlu dibuat tabel kategori terpisah di masa depan.
- Fitur pagination untuk daftar transaksi dan pesanan belum ada (masih memuat semua data).


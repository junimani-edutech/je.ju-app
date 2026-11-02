# DATABASE_SCHEMA.md — Skema Database JeJu

Status: **DRAFT v0.1** (2026-11-01)
Dokumen ini bukan final. Skema akan berubah selama implementasi dan pengujian.

## Keputusan yang mendasari

Mengacu pada `DECISIONS.md`:
- D-01 APPROVED: multi-usaha per pengguna, isolasi per `business_id`.
- D-02 APPROVED: pisahkan kas masuk dan laba; rumus laba belum final.
- D-03 APPROVED: transaksi offline diizinkan untuk operasi tertentu; pembayaran bisa pending.
- D-04 APPROVED: transaksi terkonfirmasi tidak dihapus; reversal/cancel + audit.
- D-07 APPROVED: IDR saja untuk versi awal.

## Konvensi umum

- Primary key: `id uuid` default `gen_random_uuid()`.
- Tabel tenant wajib punya `business_id uuid not null`.
- Timestamps: `created_at`, `updated_at` (timestamptz).
- Actor: `created_by` (uuid references `auth.users`).
- Soft state: kolom `status` text dengan check constraint, bukan boolean.
- Uang: `amount_*` BIGINT untuk IDR. Tidak ada floating-point.
- Currency: `char(3)` default `'IDR'` dengan check `currency = 'IDR'`.
- Idempotency: `idempotency_key` unik per business pada tabel transaksi.
- Reversal: kolom self-reference `reversal_of_*_id`.
- Audit: `audit_logs` mencatat aksi sensitif; tidak ada hapus diam-diam.

## Domain dan tabel

### Auth dan profil
- `profiles` — profil tambahan, `id` = `auth.users.id`.
- `businesses` — tenant usaha.
- `business_members` — keanggotaan user × business dengan role.
- `business_invitations` — undangan (draft; detail akan diperluas saat fase tim).

### Master data per usaha
- `customers`
- `categories` (income/expense)
- `payment_methods`
- `accounts` (cash, bank, ewallet)
- `order_statuses`

### Pesanan
- `orders`
- `order_items`
- `order_status_history`

### Keuangan
- `payments` (untuk pesanan)
- `transactions` (pemasukan/pengeluaran non-pesanan)
- `transfers`

### Audit
- `audit_logs`

### Sync (fase 8, placeholder)
- `device_registrations`, `sync_operations`, `sync_conflicts`.
- Detail akan ditulis di `OFFLINE_SYNC.md` sebelum fase offline.

## Detail tabel (ringkas)

### profiles
- `id uuid PK references auth.users(id)`.
- `full_name text`, `phone text`, `avatar_url text`.
- `created_at`, `updated_at`.

### businesses
- `id uuid PK`.
- `name text not null`, `legal_name text`, `logo_url text`.
- `contact_email text`, `contact_phone text`, `address text`.
- `timezone text not null default 'Asia/Jakarta'`.
- `currency char(3) not null default 'IDR' check (currency = 'IDR')`.
- `created_at`, `updated_at`.

### business_members
- `id uuid PK`.
- `business_id uuid FK businesses`, `user_id uuid FK auth.users`.
- `role business_role` (enum: `owner`, `admin`, `cashier`, `order_staff`, `viewer`).
- `status member_status` (enum: `invited`, `active`, `suspended`, `removed`).
- `invited_by uuid`, `invited_at`, `joined_at`.
- Unik: `(business_id, user_id)`.

### customers
- `id`, `business_id`.
- `name text not null`, `phone text`, `email text`, `address text`, `notes text`.
- `status text` check in (`active`, `archived`).
- `created_by`, `created_at`, `updated_at`.

### categories
- `id`, `business_id`.
- `type text` check in (`income`, `expense`).
- `name text not null`, `status text` (`active`, `archived`).
- Unik: `(business_id, type, name)`.

### payment_methods
- `id`, `business_id`, `name text not null`, `status text`.
- Unik: `(business_id, name)`.

### accounts
- `id`, `business_id`, `name text not null`.
- `type text` check in (`cash`, `bank`, `ewallet`).
- `currency char(3) default 'IDR'`, `initial_balance bigint not null default 0`.
- `status text` (`active`, `archived`).
- Unik: `(business_id, name)`.

### order_statuses
- `id`, `business_id`, `name text not null`, `code text not null`.
- `sort_order integer not null default 0`, `is_final boolean not null default false`.
- Unik: `(business_id, code)`.
- Default seed saat business dibuat: `draft`, `process`, `done`, `cancelled` (draft; lihat Q1).

### orders
- `id`, `business_id`.
- `order_number text not null`, `customer_id uuid FK customers`.
- `order_date date not null default current_date`, `due_date date`.
- `subtotal_amount bigint not null default 0`.
- `discount_amount bigint not null default 0`.
- `additional_fee_amount bigint not null default 0`.
- `shipping_amount bigint not null default 0`.
- `total_amount bigint not null default 0`.
- `paid_amount bigint not null default 0` (cache; sumber kebenaran adalah `payments`).
- `currency char(3) not null default 'IDR'`.
- `notes text`.
- `order_status_id uuid FK order_statuses`.
- `payment_status text not null default 'unpaid'` check in (`unpaid`, `partial`, `paid`, `overpaid`, `refunded`).
- `status text not null default 'active'` check in (`active`, `cancelled`).
- `cancelled_at`, `cancelled_by`, `cancel_reason`.
- `created_by`, `created_at`, `updated_at`.
- Unik: `(business_id, order_number)`.

### order_items
- `id`, `business_id`, `order_id uuid FK orders`.
- `position integer not null default 0`.
- `description text not null`.
- `quantity numeric(14,3) not null default 1`.
- `unit_price bigint not null default 0`.
- `discount_amount bigint not null default 0`.
- `line_total bigint not null default 0`.
- `created_at`.

### order_status_history
- `id`, `business_id`, `order_id uuid FK orders`.
- `from_status_id uuid FK order_statuses`, `to_status_id uuid FK order_statuses`.
- `changed_by uuid`, `changed_at timestamptz not null default now()`, `notes text`.

### payments
- `id`, `business_id`, `order_id uuid FK orders`.
- `amount bigint not null check (amount > 0)`.
- `currency char(3) not null default 'IDR'`.
- `payment_date date not null default current_date`.
- `payment_method_id uuid FK payment_methods`.
- `account_id uuid FK accounts`.
- `reference text`, `notes text`.
- `status text not null default 'pending'` check in (`pending`, `confirmed`, `cancelled`, `reversed`).
- `idempotency_key text`.
- `confirmed_at`, `confirmed_by`.
- `cancelled_at`, `cancelled_by`, `cancel_reason`.
- `reversal_of_payment_id uuid FK payments`.
- `created_by`, `created_at`, `updated_at`.
- Unik: `(business_id, idempotency_key)`.

### transactions (non-pesanan)
- `id`, `business_id`.
- `type text not null` check in (`income`, `expense`).
- `category_id uuid FK categories`, `account_id uuid FK accounts`.
- `amount bigint not null check (amount > 0)`.
- `currency char(3) not null default 'IDR'`.
- `transaction_date date not null default current_date`.
- `description text not null`, `reference text`, `attachment_url text`.
- `status text not null default 'confirmed'` check in (`confirmed`, `cancelled`, `reversed`).
- `idempotency_key text`.
- `reversal_of_transaction_id uuid FK transactions`.
- `cancelled_at`, `cancelled_by`, `cancel_reason`.
- `created_by`, `created_at`, `updated_at`.
- Unik: `(business_id, idempotency_key)`.

### transfers
- `id`, `business_id`.
- `from_account_id uuid FK accounts`, `to_account_id uuid FK accounts`.
- `amount bigint not null check (amount > 0)`.
- `currency char(3) not null default 'IDR'`.
- `transfer_date date not null default current_date`.
- `description text`.
- `status text not null default 'confirmed'` check in (`confirmed`, `cancelled`, `reversed`).
- `idempotency_key text`.
- `cancelled_at`, `cancelled_by`, `cancel_reason`.
- `created_by`, `created_at`, `updated_at`.
- Check: `from_account_id <> to_account_id`.
- Unik: `(business_id, idempotency_key)`.

### audit_logs
- `id`, `business_id`.
- `actor_id uuid`, `action text not null`, `entity_type text not null`, `entity_id uuid`.
- `payload jsonb`, `created_at timestamptz not null default now()`.

## RPC (server-side, SECURITY DEFINER)

### `create_order(p_business_id, p_customer_id, p_order_date, p_due_date, p_notes, p_discount_amount, p_additional_fee_amount, p_shipping_amount, p_items jsonb) returns uuid`

- Validasi membership (role owner/admin/cashier/order_staff).
- Generate `order_number` format **Q5-A** `YYYYMMDD-NNN` per bisnis per hari. Diserialkan via `pg_advisory_xact_lock(hashtext('order_seq:'||business_id), hashtext(YYYYMMDD))`, dilindungi unique `(business_id, order_number)`.
- Insert order + order_items atomik. Subtotal = Σ(quantity × unit_price - discount). Total = subtotal - diskon + fee + ongkir.
- `order_status_id` di-set ke `code='draft'` (fallback: status pertama by `sort_order`).
- `created_by` diisi server-side via `auth.uid()`.

### `change_order_status(p_order_id, p_to_status_id, p_notes) returns void`

- Validasi membership (role owner/admin/cashier/order_staff).
- **Menolak** status tujuan dengan `code='cancelled'` (raise `USE_CANCEL_ORDER`). Cancel wajib lewat `cancel_order`.
- Update `orders.order_status_id` + insert `order_status_history` (from, to, changed_by, notes) atomik.

### `cancel_order(p_order_id, p_reason) returns void`

- Validasi membership.
- Menolak order yang sudah `status='cancelled'` (raise `ALREADY_CANCELLED`).
- Set `orders.status='cancelled'`, `cancelled_at`, `cancelled_by`, `cancel_reason`, `order_status_id=cancelled` (jika ada). Insert history dengan `notes = p_reason || 'Order cancelled'` atomik.

### `record_payment(p_business_id, p_order_id, p_amount, p_payment_method_id, p_account_id, p_payment_date, p_reference, p_notes, p_idempotency_key) returns uuid`

- Validasi membership (role owner/admin/cashier). Viewer ditolak.
- Validasi order ada di `p_business_id`, bukan `cancelled`.
- Validasi `p_payment_method_id` dan `p_account_id` (jika non-null) milik bisnis.
- Validasi `p_amount > 0`.
- Idempotency: jika `p_idempotency_key` sudah dipakai di business ini, return ID yang sudah ada (tidak membuat baris baru).
- Insert payment `status='confirmed'`, `confirmed_at=now()`, `confirmed_by=auth.uid()`.
- Recompute `orders.paid_amount` via helper `order_paid_amount(order_id)` dan `orders.payment_status` via helper `order_payment_status(order_id)`.
- Insert `audit_logs` (`payment.recorded`).
- **Overpay diizinkan** → status `overpaid`. Deteksi kelebihan bayar di reporting (Fase 6).

### `void_payment(p_payment_id, p_reason) returns uuid`

- Validasi membership (owner/admin/cashier).
- Menolak void jika payment bukan `status='confirmed'`, atau payment itu sendiri reversal (`reversal_of_payment_id is not null`), atau sudah pernah di-void (ada reversal lain yang menunjuk ke payment ini).
- `p_reason` wajib non-empty.
- Insert payment **baru** dengan `amount` sama, `reversal_of_payment_id = p_payment_id`, `status='confirmed'`, `notes='Reversal: <reason>'`. Payment asli tetap `confirmed` (tidak dihapus, tidak diubah — sesuai D-04).
- Recompute `orders.paid_amount`/`payment_status` order terkait.
- Insert `audit_logs` (`payment.voided`).

### Helper: `order_paid_amount(p_order_id uuid) returns bigint`

`Σ amount` untuk `status='confirmed'` dan `reversal_of_payment_id is null`, dikurangi `Σ amount` untuk `status='confirmed'` dan `reversal_of_payment_id is not null`.

### Helper: `order_payment_status(p_order_id uuid) returns text`

Bandingkan `order_paid_amount` vs `orders.total_amount`:
- `0` → `unpaid`
- `0 < paid < total` → `partial`
- `paid = total` → `paid`
- `paid > total` → `overpaid`

### Seed default payment data (Q8-A)

Trigger `after insert on businesses` menyisipkan:
- `payment_methods`: `Cash`, `Transfer Bank`, `E-Wallet`.
- `accounts`: `Kas Tunai` (cash), `Rekening Bank` (bank), `E-Wallet` (ewallet).

Idempoten via unique `(business_id, name)`.

### `record_transaction(p_business_id, p_type, p_amount, p_description, p_category_id, p_account_id, p_transaction_date, p_reference, p_attachment_url, p_idempotency_key) returns uuid`

- Validasi membership (owner/admin/cashier). Viewer ditolak.
- Validasi `p_type` in (`income`, `expense`), `p_amount > 0`, `p_description` non-empty.
- Validasi `p_category_id` (jika ada) milik bisnis & tipenya sesuai `p_type`.
- Validasi `p_account_id` (jika ada) milik bisnis.
- Idempotency via `(business_id, idempotency_key)`.
- Insert `status='confirmed'` + `audit_logs` (`transaction.recorded`).

### `void_transaction(p_transaction_id, p_reason) returns uuid`

- Menolak void untuk transaction yang bukan `status='confirmed'`, atau sudah reversal, atau sudah pernah di-void.
- `p_reason` wajib non-empty.
- Insert **baris baru** dengan `reversal_of_transaction_id` = transaksi asli, tipe sama, amount sama, category/account sama. Baris asli tetap `confirmed`.
- Insert `audit_logs` (`transaction.voided`).

### `record_transfer(p_business_id, p_from_account_id, p_to_account_id, p_amount, p_transfer_date, p_description, p_idempotency_key) returns uuid`

- Validasi membership.
- Validasi akun asal & tujuan milik bisnis, `from != to`, `p_amount > 0`.
- Idempotency via `(business_id, idempotency_key)`.
- Insert `status='confirmed'` + `audit_logs` (`transfer.recorded`).

### `void_transfer(p_transfer_id, p_reason) returns void`

- Menolak void jika transfer sudah `status='cancelled'`.
- Set `status='cancelled'`, `cancelled_at`, `cancelled_by`, `cancel_reason`.
- Insert `audit_logs` (`transfer.voided`).
- Catatan: transfer menggunakan flag `status`, bukan reversal row.

### `account_balance(p_account_id, p_as_of date default null) returns bigint`

**Formula:**

- `p_as_of` memfilter `transaction_date <= as_of` dsb; untuk `p_as_of` tanggal, transfer yang **dibatalkan SETELAH** tanggal itu tetap dihitung (historis).
- Menolak jika viewer bukan member.

### `account_balances(p_business_id) returns table(account_id, account_name, balance)`

Bulk wrapper untuk dashboard — satu panggilan untuk semua akun aktif, hindari N+1.

### `cash_flow_summary(p_business_id, p_from, p_to) returns jsonb`

Mengembalikan `{income, expense, payments_net, net}`. Payments dihitung terpisah dari income (F5-01-A: tidak ada auto-jurnal ganda). `net = income - expense + payments_net`.

## RLS (Row Level Security)

- Semua tabel tenant mengaktifkan RLS.
- Helper: `public.is_business_member(p_business_id uuid, p_roles public.business_role[] default null)`.
- Policy utama:
  - Select: member aktif dari business tersebut.
  - Insert/Update: member dengan role yang diizinkan (owner, admin, cashier, order_staff sesuai tabel).
  - Audit log: hanya owner/admin yang bisa baca; insert via server-side.
- Service-role key tidak boleh ada di klien. Klien memakai anon key + sesi user.
- Policy ditulis di migration `20261101000000_initial_schema.sql` (draft).

## Aturan keuangan (draft)

Dihitung di server/SQL, bukan di klien.

- `line_total = round(quantity * unit_price) - discount_amount`
- `subtotal_amount = sum(order_items.line_total)` untuk order terkait.
- `total_amount = subtotal_amount - discount_amount + additional_fee_amount + shipping_amount`
- `paid_amount = sum(payments.amount) where status = 'confirmed' and order_id = :order_id`
- `payment_status`:
  - `unpaid` jika `paid = 0` dan `total > 0`
  - `partial` jika `0 < paid < total`
  - `paid` jika `paid = total`
  - `overpaid` jika `paid > total`
  - `refunded` jika ada refund yang tercatat
- Arus kas bersih: `sum(income confirmed) + sum(payments confirmed) - sum(expense confirmed) - sum(refunds confirmed)`. Transfer internal tidak dihitung.
- Laba operasional: **BELUM FINAL**. Perlakuan uang muka, refund, ongkir, biaya harus disetujui sebelum dipakai.

## Index (draft)

- `idx_business_members_user` pada `(user_id)` where status = 'active'
- `idx_business_members_business` pada `(business_id)`
- `idx_customers_business` pada `(business_id)`
- `idx_orders_business_date` pada `(business_id, order_date desc)`
- `idx_order_items_order` pada `(order_id)`
- `idx_order_items_business` pada `(business_id)`
- `idx_order_status_history_order` pada `(order_id)`
- `idx_payments_business` pada `(business_id)`
- `idx_payments_order` pada `(order_id)`
- `idx_payments_status` pada `(business_id, status)`
- `idx_transactions_business_date` pada `(business_id, transaction_date desc)`
- `idx_transactions_account` pada `(account_id)`
- `idx_transfers_business_date` pada `(business_id, transfer_date desc)`
- `idx_audit_logs_business` pada `(business_id, created_at desc)`
- `idx_audit_logs_entity` pada `(entity_type, entity_id)`

## Pertanyaan terbuka (belum diputuskan)

Tidak memblokir draft skema, tetapi harus diputuskan sebelum modul terkait:

- **Q1** — **APPROVED (2026-11-01).** `order_statuses` di-seed otomatis saat bisnis dibuat: `draft`, `process`, `done` (final), `cancelled` (final). Diimplementasikan di migration `20261101020100_seed_order_statuses_on_business_create.sql` via trigger `after insert on businesses`.
- **Q2** — Apakah `profiles` bisa dibaca oleh sesama member business? Default draft: ya, hanya `full_name` dan `avatar_url`.
- **Q3** — Apakah satu `payments` boleh melunasi beberapa order sekaligus? Default draft: tidak; satu payment untuk satu order. Perlu keputusan sebelum modul pembayaran.
- **Q4** — Refund dicatat sebagai payment baru dengan `reversal_of_payment_id` dan `amount` positif, atau payment negatif? Default draft: payment baru, `amount` positif, dikurangkan saat agregasi.
- **Q5** — Format `order_number`? Default draft: `YYYYMMDD-####`, sequence per business per hari.
- **Q6** — Apakah ongkir dari ekspedisi dicatat di `orders.shipping_amount` atau sebagai `transactions` expense? Default draft: `shipping_amount` untuk ongkir yang dibebankan ke pelanggan; biaya ekspedisi aktual sebagai `transactions.expense`.
- **Q7** — Retensi `audit_logs`? Default draft: simpan sampai kebijakan retensi ditetapkan.

## Batas dokumen

- Dokumen ini **DRAFT**. Tidak final.
- SQL migration disimpan di `supabase/migrations/20261101000000_initial_schema.sql` dan belum dijalankan.
- Test isolasi RLS akan dibuat saat Supabase siap.
- Tidak ada klaim tes lulus di dokumen ini.
- Rumus laba belum final.

## RPC Fase 6 — Pengaturan Bisnis & Laporan

### `update_business_profile(p_business_id, p_name, p_legal_name, p_contact_email, p_contact_phone, p_address, p_timezone) returns void`

- Validasi membership (owner/admin). Cashier, order_staff, viewer ditolak.
- Validasi `p_name` non-empty dan `p_timezone` non-empty.
- **Tidak** mengubah `currency` (D-07 locked IDR).
- Update baris `businesses`, trigger `updated_at` otomatis.
- Insert `audit_logs` (`business.profile_updated`).

### `report_summary(p_business_id, p_from, p_to) returns jsonb`

Semua role boleh baca (viewer, order_staff, cashier, admin, owner). Ini query baca, bukan aksi.

Return JSON:
```json
{
  "from": "YYYY-MM-DD",
  "to": "YYYY-MM-DD",
  "orders_count": 0,
  "orders_total": 0,
  "payments_received": 0,
  "receivables_remaining": 0,
  "income": 0,
  "expense": 0,
  "payments_net": 0,
  "cash_flow_net": 0,
  "balance_by_account": [
    {"account_id": "...", "account_name": "...", "balance": 0}
  ]
}

```


**Formula:**
- `orders_count` / `orders_total`: order non-cancelled dalam rentang `order_date BETWEEN p_from AND p_to`.
- `payments_received`: Σ payments(confirmed) - Σ payments(confirmed reversal) di `payment_date BETWEEN p_from AND p_to`.
- `receivables_remaining`: snapshot Σ (total_amount - paid_amount) untuk order aktif (unpaid/partial). **Tidak** rentang tanggal.
- `income` / `expense` / `payments_net` / `cash_flow_net`: dari `cash_flow_summary(business_id, from, to)`.
- `balance_by_account`: snapshot dari `account_balances(business_id)`.
- Laba operasional **belum dihitung** (D-02 belum final).

**Ekspor (client-side, Fase 6):** CSV + XLSX; PDF ditunda (D-05 revised).

## RPC Fase 7 — Tim & Undangan

### `list_business_members(p_business_id) returns table(user_id, email, full_name, avatar_url, role, status, joined_at, is_self)`

- Validasi membership (semua role). Return error `NOT_A_MEMBER` jika bukan member aktif.
- Termasuk member non-active (invited/suspended), diurutkan berdasarkan hierarki role lalu `created_at`.
- `is_self` = `bm.user_id = auth.uid()`.

### `create_invitation(p_business_id, p_email, p_role) returns table(invitation_id, token, expires_at)`

- Validasi: caller adalah owner/admin; email non-empty; tidak boleh invite self; target email belum jadi member.
- Owner boleh invite `admin`/`cashier`/`order_staff`/`viewer`. Admin hanya `cashier`/`order_staff`/`viewer`.
- Idempotent: jika sudah ada pending invitation untuk email sama dan belum expired, return yang lama.
- Token 64-char hex (`gen_random_uuid()` x2). Expiry 7 hari.

### `revoke_invitation(p_invitation_id) returns void`

- Validasi owner/admin.
- Hanya boleh revoke yang `status=pending` (`INVITATION_NOT_PENDING` jika tidak).

### `accept_invitation(p_token) returns uuid` (business_id)

- Wajib login (JWT email).
- Validasi email match dengan invitation (`EMAIL_MISMATCH`), status pending, belum expired.
- Idempotent: kalau invitation `accepted` oleh user yang sama → return `business_id` tanpa error.
- Insert `business_members` (status active) atau abaikan jika sudah member.
- Set invitation `status=accepted`, `accepted_at`, `accepted_by`.

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

- **Q1** — Apakah `order_statuses` di-seed otomatis saat business dibuat? Default draft: ya, minimal `draft`, `process`, `done`, `cancelled`.
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

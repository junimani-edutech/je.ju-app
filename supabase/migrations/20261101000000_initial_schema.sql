-- JeJu initial schema (DRAFT v0.1)
-- Status: draft, belum dijalankan.
-- Asumsi: dijalankan di Supabase (schema auth.users sudah ada).
-- Tidak ada klaim tes lulus.

create extension if not exists pgcrypto;

-- =========================================================
-- Enum types (idempotent-ish)
-- =========================================================
do $$ begin
  create type public.business_role as enum ('owner','admin','cashier','order_staff','viewer');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.member_status as enum ('invited','active','suspended','removed');
exception when duplicate_object then null; end $$;

-- =========================================================
-- Profiles (extends auth.users)
-- =========================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================================================
-- Businesses
-- =========================================================
create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  logo_url text,
  contact_email text,
  contact_phone text,
  address text,
  timezone text not null default 'Asia/Jakarta',
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================================================
-- Business members
-- =========================================================
create table if not exists public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.business_role not null,
  status public.member_status not null default 'active',
  invited_by uuid references auth.users(id),
  invited_at timestamptz,
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, user_id)
);

create index if not exists idx_business_members_user
  on public.business_members(user_id) where status = 'active';
create index if not exists idx_business_members_business
  on public.business_members(business_id);

-- =========================================================
-- Helper function (security definer agar aman dari RLS rekursif)
-- =========================================================
create or replace function public.is_business_member(
  p_business_id uuid,
  p_roles public.business_role[] default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.business_members
    where business_id = p_business_id
      and user_id = auth.uid()
      and status = 'active'
      and (p_roles is null or role = any (p_roles))
  );
$$;

-- =========================================================
-- Master data per business
-- =========================================================
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  address text,
  notes text,
  status text not null default 'active' check (status in ('active','archived')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_customers_business on public.customers(business_id);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  name text not null,
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  unique (business_id, type, name)
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  type text not null check (type in ('cash','bank','ewallet')),
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  initial_balance bigint not null default 0,
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  unique (business_id, name)
);

create table if not exists public.order_statuses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  code text not null,
  sort_order integer not null default 0,
  is_final boolean not null default false,
  created_at timestamptz not null default now(),
  unique (business_id, code)
);

-- =========================================================
-- Orders
-- =========================================================
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_number text not null,
  customer_id uuid references public.customers(id),
  order_date date not null default current_date,
  due_date date,
  subtotal_amount bigint not null default 0,
  discount_amount bigint not null default 0,
  additional_fee_amount bigint not null default 0,
  shipping_amount bigint not null default 0,
  total_amount bigint not null default 0,
  paid_amount bigint not null default 0,
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  notes text,
  order_status_id uuid references public.order_statuses(id),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid','partial','paid','overpaid','refunded')),
  status text not null default 'active' check (status in ('active','cancelled')),
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  cancel_reason text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, order_number)
);
create index if not exists idx_orders_business_date
  on public.orders(business_id, order_date desc);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  position integer not null default 0,
  description text not null,
  quantity numeric(14,3) not null default 1,
  unit_price bigint not null default 0,
  discount_amount bigint not null default 0,
  line_total bigint not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_order_items_order on public.order_items(order_id);
create index if not exists idx_order_items_business on public.order_items(business_id);

create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status_id uuid references public.order_statuses(id),
  to_status_id uuid references public.order_statuses(id),
  changed_by uuid references auth.users(id),
  changed_at timestamptz not null default now(),
  notes text
);
create index if not exists idx_order_status_history_order
  on public.order_status_history(order_id);

-- =========================================================
-- Payments
-- =========================================================
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  order_id uuid not null references public.orders(id),
  amount bigint not null check (amount > 0),
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  payment_date date not null default current_date,
  payment_method_id uuid references public.payment_methods(id),
  account_id uuid references public.accounts(id),
  reference text,
  notes text,
  status text not null default 'pending'
    check (status in ('pending','confirmed','cancelled','reversed')),
  idempotency_key text,
  confirmed_at timestamptz,
  confirmed_by uuid references auth.users(id),
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  cancel_reason text,
  reversal_of_payment_id uuid references public.payments(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, idempotency_key)
);
create index if not exists idx_payments_business on public.payments(business_id);
create index if not exists idx_payments_order on public.payments(order_id);
create index if not exists idx_payments_status on public.payments(business_id, status);

-- =========================================================
-- Transactions (income/expense non-order)
-- =========================================================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  category_id uuid references public.categories(id),
  account_id uuid references public.accounts(id),
  amount bigint not null check (amount > 0),
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  transaction_date date not null default current_date,
  description text not null,
  reference text,
  attachment_url text,
  status text not null default 'confirmed'
    check (status in ('confirmed','cancelled','reversed')),
  idempotency_key text,
  reversal_of_transaction_id uuid references public.transactions(id),
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  cancel_reason text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, idempotency_key)
);
create index if not exists idx_transactions_business_date
  on public.transactions(business_id, transaction_date desc);
create index if not exists idx_transactions_account
  on public.transactions(account_id);

-- =========================================================
-- Transfers
-- =========================================================
create table if not exists public.transfers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  from_account_id uuid not null references public.accounts(id),
  to_account_id uuid not null references public.accounts(id),
  amount bigint not null check (amount > 0),
  currency char(3) not null default 'IDR' check (currency = 'IDR'),
  transfer_date date not null default current_date,
  description text,
  status text not null default 'confirmed'
    check (status in ('confirmed','cancelled','reversed')),
  idempotency_key text,
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id),
  cancel_reason text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_account_id <> to_account_id),
  unique (business_id, idempotency_key)
);
create index if not exists idx_transfers_business_date
  on public.transfers(business_id, transfer_date desc);

-- =========================================================
-- Audit logs
-- =========================================================
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  actor_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_audit_logs_business
  on public.audit_logs(business_id, created_at desc);
create index if not exists idx_audit_logs_entity
  on public.audit_logs(entity_type, entity_id);

-- =========================================================
-- Enable RLS
-- =========================================================
alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.customers enable row level security;
alter table public.categories enable row level security;
alter table public.payment_methods enable row level security;
alter table public.accounts enable row level security;
alter table public.order_statuses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payments enable row level security;
alter table public.transactions enable row level security;
alter table public.transfers enable row level security;
alter table public.audit_logs enable row level security;

-- =========================================================
-- Policies (draft)
-- =========================================================
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id);

drop policy if exists businesses_select_member on public.businesses;
create policy businesses_select_member on public.businesses
  for select using (public.is_business_member(id));

drop policy if exists businesses_update_owner on public.businesses;
create policy businesses_update_owner on public.businesses
  for update using (public.is_business_member(id, array['owner']::public.business_role[]));

drop policy if exists members_select on public.business_members;
create policy members_select on public.business_members
  for select using (public.is_business_member(business_id));

drop policy if exists members_insert_admin on public.business_members;
create policy members_insert_admin on public.business_members
  for insert with check (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists members_update_admin on public.business_members;
create policy members_update_admin on public.business_members
  for update using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists members_delete_admin on public.business_members;
create policy members_delete_admin on public.business_members
  for delete using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists customers_select on public.customers;
create policy customers_select on public.customers
  for select using (public.is_business_member(business_id));

drop policy if exists customers_insert on public.customers;
create policy customers_insert on public.customers
  for insert with check (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists customers_update on public.customers;
create policy customers_update on public.customers
  for update using (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists categories_select on public.categories;
create policy categories_select on public.categories
  for select using (public.is_business_member(business_id));

drop policy if exists categories_manage on public.categories;
create policy categories_manage on public.categories
  for all using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists payment_methods_select on public.payment_methods;
create policy payment_methods_select on public.payment_methods
  for select using (public.is_business_member(business_id));

drop policy if exists payment_methods_manage on public.payment_methods;
create policy payment_methods_manage on public.payment_methods
  for all using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists accounts_select on public.accounts;
create policy accounts_select on public.accounts
  for select using (public.is_business_member(business_id));

drop policy if exists accounts_manage on public.accounts;
create policy accounts_manage on public.accounts
  for all using (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]));

drop policy if exists order_statuses_select on public.order_statuses;
create policy order_statuses_select on public.order_statuses
  for select using (public.is_business_member(business_id));

drop policy if exists order_statuses_manage on public.order_statuses;
create policy order_statuses_manage on public.order_statuses
  for all using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

drop policy if exists orders_select on public.orders;
create policy orders_select on public.orders
  for select using (public.is_business_member(business_id));

drop policy if exists orders_insert on public.orders;
create policy orders_insert on public.orders
  for insert with check (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists orders_update on public.orders;
create policy orders_update on public.orders
  for update using (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists order_items_select on public.order_items;
create policy order_items_select on public.order_items
  for select using (public.is_business_member(business_id));

drop policy if exists order_items_manage on public.order_items;
create policy order_items_manage on public.order_items
  for all using (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists order_status_history_select on public.order_status_history;
create policy order_status_history_select on public.order_status_history
  for select using (public.is_business_member(business_id));

drop policy if exists order_status_history_insert on public.order_status_history;
create policy order_status_history_insert on public.order_status_history
  for insert with check (public.is_business_member(business_id, array['owner','admin','cashier','order_staff']::public.business_role[]));

drop policy if exists payments_select on public.payments;
create policy payments_select on public.payments
  for select using (public.is_business_member(business_id));

drop policy if exists payments_insert on public.payments;
create policy payments_insert on public.payments
  for insert with check (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]));

drop policy if exists payments_update on public.payments;
create policy payments_update on public.payments
  for update using (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]));

drop policy if exists transactions_select on public.transactions;
create policy transactions_select on public.transactions
  for select using (public.is_business_member(business_id));

drop policy if exists transactions_manage on public.transactions;
create policy transactions_manage on public.transactions
  for all using (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]));

drop policy if exists transfers_select on public.transfers;
create policy transfers_select on public.transfers
  for select using (public.is_business_member(business_id));

drop policy if exists transfers_manage on public.transfers;
create policy transfers_manage on public.transfers
  for all using (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]))
  with check (public.is_business_member(business_id, array['owner','admin','cashier']::public.business_role[]));

drop policy if exists audit_logs_select on public.audit_logs;
create policy audit_logs_select on public.audit_logs
  for select using (public.is_business_member(business_id, array['owner','admin']::public.business_role[]));

-- Audit logs: insert hanya via server-side / triggers.
-- Tidak ada policy insert untuk audit_logs.

-- =========================================================
-- End of draft migration
-- =========================================================

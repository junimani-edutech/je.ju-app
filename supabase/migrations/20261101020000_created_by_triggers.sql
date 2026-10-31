-- Migration: set_created_by triggers untuk tabel transaksi.
-- Fase 4 / Langkah 9A.
-- Tujuan: created_by diisi server-side via auth.uid() untuk mencegah manipulasi klien.

create or replace function public.set_created_by()
returns trigger
language plpgsql
as $$
begin
  new.created_by = auth.uid();
  return new;
end;
$$;

drop trigger if exists trg_customers_created_by on public.customers;
create trigger trg_customers_created_by
before insert on public.customers
for each row execute function public.set_created_by();

drop trigger if exists trg_orders_created_by on public.orders;
create trigger trg_orders_created_by
before insert on public.orders
for each row execute function public.set_created_by();

drop trigger if exists trg_payments_created_by on public.payments;
create trigger trg_payments_created_by
before insert on public.payments
for each row execute function public.set_created_by();

drop trigger if exists trg_transactions_created_by on public.transactions;
create trigger trg_transactions_created_by
before insert on public.transactions
for each row execute function public.set_created_by();

drop trigger if exists trg_transfers_created_by on public.transfers;
create trigger trg_transfers_created_by
before insert on public.transfers
for each row execute function public.set_created_by();

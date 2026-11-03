-- Migration: Prevent changing business_id on all tenant tables.
-- Security fix: Once a record is created, its business_id must never change.

create or replace function public.prevent_business_id_update()
returns trigger
language plpgsql
as $$
begin
  if new.business_id <> old.business_id then
    raise exception 'BUSINESS_ID_IMMUTABLE' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Terapkan ke tabel-tabel utama
do $$
declare
  t text;
begin
  foreach t in array array[
    'customers', 'orders', 'order_items', 'payments', 
    'transactions', 'transfers', 'accounts', 'categories'
  ] loop
    execute format('drop trigger if exists trg_%s_business_id_immutable on public.%I;', t, t);
    execute format('create trigger trg_%s_business_id_immutable before update on public.%I for each row execute function public.prevent_business_id_update();', t, t);
  end loop;
end $$;

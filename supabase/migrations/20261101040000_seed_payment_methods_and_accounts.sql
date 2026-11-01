-- Migration: seed default payment_methods + accounts saat business dibuat.
-- Q8-A APPROVED 2026-11-01.

create or replace function public.seed_default_payment_data()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.payment_methods (business_id, name) values
    (new.id, 'Cash'),
    (new.id, 'Transfer Bank'),
    (new.id, 'E-Wallet')
  on conflict (business_id, name) do nothing;

  insert into public.accounts (business_id, name, type) values
    (new.id, 'Kas Tunai', 'cash'),
    (new.id, 'Rekening Bank', 'bank'),
    (new.id, 'E-Wallet', 'ewallet')
  on conflict (business_id, name) do nothing;

  return new;
end;
$$;

revoke all on function public.seed_default_payment_data() from public;
revoke all on function public.seed_default_payment_data() from anon;
revoke all on function public.seed_default_payment_data() from authenticated;

drop trigger if exists trg_businesses_seed_payment_data on public.businesses;
create trigger trg_businesses_seed_payment_data
after insert on public.businesses
for each row execute function public.seed_default_payment_data();

-- Backfill untuk bisnis yang sudah ada.
insert into public.payment_methods (business_id, name)
select b.id, v.name
from public.businesses b
cross join (values ('Cash'),('Transfer Bank'),('E-Wallet')) as v(name)
on conflict (business_id, name) do nothing;

insert into public.accounts (business_id, name, type)
select b.id, v.name, v.type
from public.businesses b
cross join (values
  ('Kas Tunai', 'cash'),
  ('Rekening Bank', 'bank'),
  ('E-Wallet', 'ewallet')
) as v(name, type)
on conflict (business_id, name) do nothing;

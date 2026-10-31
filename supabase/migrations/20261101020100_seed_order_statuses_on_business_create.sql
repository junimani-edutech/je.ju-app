-- Migration: seed default order_statuses saat business dibuat.
-- Q1 APPROVED 2026-11-01.
-- Trigger after insert on businesses -> seed draft/process/done/cancelled.
-- Idempoten via unique (business_id, code).
-- Backfill untuk bisnis yang sudah ada (dev/test).

create or replace function public.seed_default_order_statuses()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.order_statuses
    (business_id, name, code, sort_order, is_final)
  values
    (new.id, 'Draft',      'draft',     0, false),
    (new.id, 'Diproses',   'process',   1, false),
    (new.id, 'Selesai',    'done',      2, true),
    (new.id, 'Dibatalkan', 'cancelled', 3, true)
  on conflict (business_id, code) do nothing;
  return new;
end;
$$;

revoke all on function public.seed_default_order_statuses() from public;
revoke all on function public.seed_default_order_statuses() from anon;
revoke all on function public.seed_default_order_statuses() from authenticated;

drop trigger if exists trg_businesses_seed_order_statuses on public.businesses;
create trigger trg_businesses_seed_order_statuses
after insert on public.businesses
for each row execute function public.seed_default_order_statuses();

-- Backfill untuk bisnis yang sudah ada.
insert into public.order_statuses (business_id, name, code, sort_order, is_final)
select b.id, v.name, v.code, v.sort_order, v.is_final
from public.businesses b
cross join (values
  ('Draft',      'draft',     0, false),
  ('Diproses',   'process',   1, false),
  ('Selesai',    'done',      2, true),
  ('Dibatalkan', 'cancelled', 3, true)
) as v(name, code, sort_order, is_final)
on conflict (business_id, code) do nothing;

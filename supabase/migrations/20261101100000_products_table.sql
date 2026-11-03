-- Migration: products master data.
-- Fase 11 / Langkah 11A.

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  price bigint not null check (price >= 0),
  description text,
  status text not null default 'active' check (status in ('active','archived')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_products_business on public.products(business_id);
create index if not exists idx_products_business_status on public.products(business_id, status);

-- Auto-fill created_by
drop trigger if exists trg_products_created_by on public.products;
create trigger trg_products_created_by
before insert on public.products
for each row execute function public.set_created_by();

-- Auto-update updated_at
drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at
before update on public.products
for each row execute function public.set_updated_at();

-- RLS
alter table public.products enable row level security;

drop policy if exists products_select on public.products;
create policy products_select on public.products
  for select using (public.is_business_member(business_id));

drop policy if exists products_insert on public.products;
create policy products_insert on public.products
  for insert with check (
    public.is_business_member(business_id,
      array['owner','admin','cashier']::public.business_role[])
  );

drop policy if exists products_update on public.products;
create policy products_update on public.products
  for update using (
    public.is_business_member(business_id,
      array['owner','admin','cashier']::public.business_role[])
  );

-- Foreign key opsional ke order_items (untuk analitik)
alter table public.order_items
  add column if not exists product_id uuid references public.products(id);

create index if not exists idx_order_items_product on public.order_items(product_id);

-- RPC upsert_product untuk offline sync
create or replace function public.upsert_product(
  p_id uuid,
  p_business_id uuid,
  p_name text,
  p_price bigint,
  p_description text default null,
  p_status text default 'active'
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existing_biz uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = '28000';
  end if;

  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'NAME_REQUIRED' using errcode = '22023';
  end if;

  if p_price is null or p_price < 0 then
    raise exception 'PRICE_INVALID' using errcode = '22023';
  end if;

  if p_status not in ('active', 'archived') then
    raise exception 'STATUS_INVALID' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.business_members
    where business_id = p_business_id
      and user_id = v_uid and status = 'active'
      and role in ('owner','admin','cashier')
  ) then
    raise exception 'NOT_A_MEMBER' using errcode = '28000';
  end if;

  select business_id into v_existing_biz from public.products where id = p_id;
  if v_existing_biz is not null and v_existing_biz <> p_business_id then
    raise exception 'PRODUCT_BUSINESS_MISMATCH' using errcode = '22023';
  end if;

  insert into public.products (
    id, business_id, name, price, description, status, created_by
  ) values (
    p_id, p_business_id, btrim(p_name), p_price,
    nullif(btrim(coalesce(p_description, '')), ''),
    p_status, v_uid
  )
  on conflict (id) do update set
    name = excluded.name,
    price = excluded.price,
    description = excluded.description,
    status = excluded.status,
    updated_at = now();

  return p_id;
end;
$$;

revoke all on function public.upsert_product(uuid, uuid, text, bigint, text, text) from public, anon;
grant execute on function public.upsert_product(uuid, uuid, text, bigint, text, text) to authenticated;

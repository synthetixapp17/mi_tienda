-- SINTHETIX PRO - Productos SQLite <-> Supabase
-- Ejecutar en Supabase SQL Editor.
-- Este script NO elimina datos existentes.

create extension if not exists pgcrypto;

create table if not exists public.store_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists store_categories_name_uq
  on public.store_categories (lower(name));

create table if not exists public.store_products (
  id uuid primary key default gen_random_uuid(),
  local_id text not null,
  name text not null,
  description text,
  sku text,
  barcode text,
  price numeric not null default 0,
  stock numeric not null default 0,
  category_id uuid references public.store_categories(id) on delete set null,
  brand text,
  color text,
  size text,
  image_url text,
  active boolean not null default true,
  featured boolean not null default false,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create unique index if not exists store_products_local_id_uq
  on public.store_products(local_id);

create index if not exists store_products_barcode_idx
  on public.store_products(barcode);

create index if not exists store_products_updated_at_idx
  on public.store_products(updated_at desc);

alter table public.store_categories enable row level security;
alter table public.store_products enable row level security;

-- El POS inicia sesión anónimamente; Supabase entrega el rol authenticated.
drop policy if exists "sinthetix categories authenticated all" on public.store_categories;
create policy "sinthetix categories authenticated all"
on public.store_categories
for all to authenticated
using (true)
with check (true);

drop policy if exists "sinthetix products authenticated all" on public.store_products;
create policy "sinthetix products authenticated all"
on public.store_products
for all to authenticated
using (true)
with check (true);

-- Verificación rápida después de ejecutar:
select count(*) as categorias from public.store_categories;
select count(*) as productos from public.store_products;

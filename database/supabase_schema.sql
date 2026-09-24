-- Ejecutar en Supabase SQL Editor.
-- Las credenciales viven en Supabase Auth; no se almacenan contrasenas aqui.

create table if not exists public.usuarios (
    id uuid primary key references auth.users(id) on delete cascade,
    cedula varchar(10) not null unique,
    nombre varchar(100) not null,
    apellido varchar(100) not null,
    edad integer not null check (edad between 12 and 100),
    peso numeric(5,2) not null check (peso > 0),
    patologia_o_alergias text,
    activo boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.usuarios enable row level security;

drop policy if exists "usuarios_select_own" on public.usuarios;
create policy "usuarios_select_own"
on public.usuarios for select
to authenticated
using (auth.uid() = id);

drop policy if exists "usuarios_insert_own" on public.usuarios;
create policy "usuarios_insert_own"
on public.usuarios for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "usuarios_update_own" on public.usuarios;
create policy "usuarios_update_own"
on public.usuarios for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create index if not exists idx_usuarios_cedula on public.usuarios(cedula);

grant usage on schema public to authenticated;
grant select, insert, update on public.usuarios to authenticated;
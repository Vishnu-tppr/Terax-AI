create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone_number text,
  profile_image_url text,
  preferences jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone_number text not null,
  email text,
  relationship text not null default 'emergency'
    check (relationship in ('emergency', 'family', 'friend')),
  priority smallint not null default 1
    check (priority between 1 and 5),
  notification_methods jsonb not null default '["sms"]'::jsonb,
  is_primary boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.emergency_incidents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trigger_type text not null
    check (trigger_type in ('button', 'voice', 'gesture', 'facial_distress', 'safe_zone', 'manual')),
  status text not null default 'active'
    check (status in ('active', 'resolved', 'failed')),
  location text,
  latitude double precision,
  longitude double precision,
  user_name text,
  emergency_contacts jsonb,
  email_contacts jsonb,
  recording_url text,
  ai_analysis text,
  description text,
  triggered_at timestamptz,
  contact_ids jsonb,
  contacts_notified integer,
  resolved_at timestamptz,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.location_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  accuracy double precision,
  altitude double precision,
  heading double precision,
  speed double precision,
  address text,
  source text not null default 'mobile_app',
  captured_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists contacts_set_updated_at on public.emergency_contacts;
create trigger contacts_set_updated_at
before update on public.emergency_contacts
for each row execute function public.set_updated_at();

drop trigger if exists incidents_set_updated_at on public.emergency_incidents;
create trigger incidents_set_updated_at
before update on public.emergency_incidents
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.emergency_incidents enable row level security;
alter table public.location_events enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "contacts_select_own" on public.emergency_contacts;
create policy "contacts_select_own"
on public.emergency_contacts for select
using (auth.uid() = user_id);

drop policy if exists "contacts_modify_own" on public.emergency_contacts;
create policy "contacts_modify_own"
on public.emergency_contacts for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "incidents_select_own" on public.emergency_incidents;
create policy "incidents_select_own"
on public.emergency_incidents for select
using (auth.uid() = user_id);

drop policy if exists "incidents_modify_own" on public.emergency_incidents;
create policy "incidents_modify_own"
on public.emergency_incidents for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "locations_select_own" on public.location_events;
create policy "locations_select_own"
on public.location_events for select
using (auth.uid() = user_id);

drop policy if exists "locations_insert_own" on public.location_events;
create policy "locations_insert_own"
on public.location_events for insert
with check (auth.uid() = user_id);

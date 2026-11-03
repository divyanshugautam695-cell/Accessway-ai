-- AccessWay AI starter schema for Supabase
-- Run this whole file once in Supabase Dashboard > SQL Editor.
-- Client apps use only the publishable key. Never put a service_role/secret key in Flutter.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Other',
  address text not null default '',
  latitude double precision,
  longitude double precision,
  source text not null default 'community',
  verification_status text not null default 'unknown'
    check (verification_status in ('unknown', 'community_reported', 'reviewed', 'institution_confirmed', 'stale')),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  check ((latitude is null and longitude is null) or (latitude is not null and longitude is not null))
);

create table if not exists public.accessibility_features (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  feature_key text not null,
  status text not null default 'unknown'
    check (status in ('unknown', 'available', 'limited', 'unavailable', 'needs_rechecking')),
  evidence_note text not null default '',
  evidence_method text not null default 'community_observation',
  observed_at timestamptz,
  contributor_id uuid references auth.users(id) on delete set null,
  review_status text not null default 'community_reported'
    check (review_status in ('community_reported', 'reviewed', 'institution_confirmed', 'rejected', 'stale')),
  created_at timestamptz not null default now()
);

create table if not exists public.barrier_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  place_id uuid references public.places(id) on delete set null,
  place_name text not null,
  category text not null,
  description text not null check (char_length(description) between 8 and 2000),
  status text not null default 'community_reported'
    check (status in ('community_reported', 'under_review', 'resolved', 'rejected', 'stale')),
  created_at timestamptz not null default now()
);

create index if not exists places_published_idx on public.places (is_published);
create index if not exists accessibility_features_place_idx on public.accessibility_features (place_id);
create index if not exists barrier_reports_reporter_created_idx on public.barrier_reports (reporter_id, created_at desc);

-- Create a profile automatically when a new Auth user signs up.
create or replace function public.handle_new_accessway_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_accessway_auth_user_created on auth.users;
create trigger on_accessway_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_accessway_user();

alter table public.profiles enable row level security;
alter table public.places enable row level security;
alter table public.accessibility_features enable row level security;
alter table public.barrier_reports enable row level security;

-- Profiles: each signed-in user can read and edit only their own profile.
drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles
for select to authenticated using (id = (select auth.uid()));

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile" on public.profiles
for insert to authenticated with check (id = (select auth.uid()));

-- Published places and their feature records are readable; only trusted staff
-- should publish places or perform institutional verification.
drop policy if exists "Read published places" on public.places;
create policy "Read published places" on public.places
for select to anon, authenticated using (is_published = true);

drop policy if exists "Read features for published places" on public.accessibility_features;
create policy "Read features for published places" on public.accessibility_features
for select to anon, authenticated
using (exists (
  select 1 from public.places p
  where p.id = place_id and p.is_published = true
));

-- Authenticated contributors can submit observations for a published place.
-- Submissions remain community-reported until a reviewer changes their status.
drop policy if exists "Contributors submit feature observations" on public.accessibility_features;
create policy "Contributors submit feature observations" on public.accessibility_features
for insert to authenticated
with check (
  contributor_id = (select auth.uid())
  and review_status = 'community_reported'
  and exists (
    select 1 from public.places p
    where p.id = place_id and p.is_published = true
  )
);

-- Barrier reports are private to the reporting account in this starter schema.
-- A future moderated dashboard can expose approved summaries without exposing
-- contributor account details.
drop policy if exists "Users read own barrier reports" on public.barrier_reports;
create policy "Users read own barrier reports" on public.barrier_reports
for select to authenticated using (reporter_id = (select auth.uid()));

drop policy if exists "Users submit own barrier reports" on public.barrier_reports;
create policy "Users submit own barrier reports" on public.barrier_reports
for insert to authenticated with check (reporter_id = (select auth.uid()));

grant select on public.places, public.accessibility_features to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert on public.barrier_reports to authenticated;
grant insert on public.accessibility_features to authenticated;

-- =====================================================================
--  THE PRANA SPACE — Supabase setup
--  Paste this whole file into Supabase → SQL Editor → New query → Run
--  Safe to run once on a fresh project.
-- =====================================================================

-- ---------- 1. Admins (who can read patient data) --------------------
create table if not exists public.admins (
  email text primary key
);

-- Helper: is the logged-in user an admin?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;

-- ---------- 2. Patients (intake form + healer fields) ----------------
create table if not exists public.patients (
  id               uuid primary key default gen_random_uuid(),
  created_at       timestamptz not null default now(),
  source           text not null default 'web_form',      -- web_form | manual

  -- About you
  full_name        text not null,
  whatsapp         text not null,
  email            text,
  dob              date,
  gender           text,
  occupation       text,
  address          text,

  -- Concern
  primary_concerns text[] default '{}',
  concern_other    text,
  heal_goal        text,
  symptoms         jsonb not null default '[]'::jsonb,     -- [{name, intensity, remarks}]
  impact_score     int check (impact_score between 1 and 10),

  -- Health
  medical_history  text,

  -- Photo (path inside the private "patient-photos" bucket)
  photo_path       text,

  -- Other
  heard_from       text,
  heard_other      text,
  consent          boolean not null default false,
  consent_at       timestamptz default now(),

  -- Healer-only fields
  status           text not null default 'Active',        -- Active | Inactive
  category         text not null default 'Normal',
  case_fees        numeric(10,2),
  admin_notes      text
);

-- ---------- 3. Energy scans ------------------------------------------
create table if not exists public.scans (
  id               uuid primary key default gen_random_uuid(),
  created_at       timestamptz not null default now(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  scan_date        date not null default current_date,
  avg_aura         numeric(8,2),
  aura_unit        text default 'Inches',
  avg_activation   numeric(8,2),
  activation_unit  text default 'Inches',
  major_chakras    jsonb not null default '{}'::jsonb,     -- {Crown:{energy,energy_obs,activation,activation_obs}, ...}
  minor_chakras    jsonb not null default '[]'::jsonb,     -- [{name, energy, energy_obs, activation, activation_obs}]
  organs           jsonb not null default '[]'::jsonb,     -- [{name, energy, obs}]
  emotions         jsonb not null default '[]'::jsonb,     -- [{name, obs}]
  notes            text
);

-- ---------- 4. Healing sessions --------------------------------------
create table if not exists public.healings (
  id               uuid primary key default gen_random_uuid(),
  created_at       timestamptz not null default now(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  healing_date     date not null,
  healing_time     time,
  status           text not null default 'Pending',       -- Pending | Complete | Cancelled
  notes            text,
  series_id        uuid                                    -- groups repeated sessions
);

-- ---------- 5. Payments ----------------------------------------------
create table if not exists public.payments (
  id               uuid primary key default gen_random_uuid(),
  created_at       timestamptz not null default now(),
  patient_id       uuid not null references public.patients(id) on delete cascade,
  paid_on          date not null default current_date,
  amount           numeric(10,2) not null,
  mode             text,                                   -- UPI | Cash | Bank transfer | Card
  note             text
);

create index if not exists scans_patient_idx    on public.scans(patient_id, scan_date);
create index if not exists healings_patient_idx on public.healings(patient_id, healing_date);
create index if not exists healings_date_idx    on public.healings(healing_date);
create index if not exists payments_patient_idx on public.payments(patient_id);

-- ---------- 6. Row Level Security ------------------------------------
alter table public.admins   enable row level security;
alter table public.patients enable row level security;
alter table public.scans    enable row level security;
alter table public.healings enable row level security;
alter table public.payments enable row level security;

-- Public website visitors may ONLY submit the intake form (no reading).
revoke all on public.patients from anon;
grant insert (
  id, full_name, whatsapp, email, dob, gender, occupation, address,
  primary_concerns, concern_other, heal_goal, symptoms, impact_score,
  medical_history, photo_path, heard_from, heard_other, consent
) on public.patients to anon;

drop policy if exists "public can submit intake" on public.patients;
create policy "public can submit intake"
  on public.patients for insert to anon
  with check (consent = true and source = 'web_form');

-- Admin (Mamta) can do everything.
drop policy if exists "admin all patients" on public.patients;
create policy "admin all patients" on public.patients
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin all scans" on public.scans;
create policy "admin all scans" on public.scans
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin all healings" on public.healings;
create policy "admin all healings" on public.healings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin all payments" on public.payments;
create policy "admin all payments" on public.payments
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin read admins" on public.admins;
create policy "admin read admins" on public.admins
  for select to authenticated using (public.is_admin());

-- ---------- 7. Private photo storage ---------------------------------
insert into storage.buckets (id, name, public)
values ('patient-photos', 'patient-photos', false)
on conflict (id) do nothing;

-- Visitors can upload a photo, but can never view or list photos.
drop policy if exists "public upload photo" on storage.objects;
create policy "public upload photo" on storage.objects
  for insert to anon
  with check (bucket_id = 'patient-photos');

drop policy if exists "admin manage photos" on storage.objects;
create policy "admin manage photos" on storage.objects
  for all to authenticated
  using (bucket_id = 'patient-photos' and public.is_admin())
  with check (bucket_id = 'patient-photos' and public.is_admin());

-- =====================================================================
--  LAST STEP — add Mamta's login email (replace the example below)
-- =====================================================================
-- insert into public.admins (email) values ('mamta@example.com');

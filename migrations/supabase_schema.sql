-- Supabase Production-Ready Schema for Doctor Consultation App & Platform Admin
-- This schema covers users, doctors, appointments, payments, reviews, notifications, and settings

-- User profiles (patients, doctors, admins)
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  username text,
  first_name text not null check (char_length(first_name) > 1),
  last_name text not null check (char_length(last_name) > 1),
  email text unique not null check (position('@' in email) > 1),
  phone text check (phone ~ '^\+?[0-9\- ]{7,20}$'),
  profile_image text,
  bio text,
  role text check (role in ('patient', 'doctor', 'admin')) not null,
  is_doctor boolean default false,
  is_patient boolean default true,
  is_doctor_approved boolean default false,
  approval_status text check (approval_status in ('pending','approved','rejected')) default 'pending',
  specialty text,
  experience text,
  consultation_fee numeric check (consultation_fee >= 0),
  mobile_money_provider text,
  mobile_money_number text,
  license_document_path text,
  approval_note text,
  is_online boolean default false,
  payout_recipient_code text,
  deactivated boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

alter table profiles add column if not exists username text;
alter table profiles add column if not exists profile_image text;
alter table profiles add column if not exists bio text;
alter table profiles add column if not exists specialty text;
alter table profiles add column if not exists experience text;
alter table profiles add column if not exists consultation_fee numeric check (consultation_fee >= 0);
alter table profiles add column if not exists mobile_money_provider text;
alter table profiles add column if not exists mobile_money_number text;
alter table profiles add column if not exists license_document_path text;
alter table profiles add column if not exists approval_note text;
alter table profiles add column if not exists is_online boolean default false;
alter table profiles add column if not exists payout_recipient_code text;
alter table profiles add column if not exists deactivated boolean default false;
alter table profiles add column if not exists updated_at timestamptz default now();
alter table profiles add column if not exists deleted_at timestamptz;
create unique index if not exists idx_profiles_username on profiles(username) where username is not null;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-images',
  'profile-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists profile_images_public_read on storage.objects;
create policy profile_images_public_read on storage.objects
  for select using (bucket_id = 'profile-images');

drop policy if exists profile_images_authenticated_upload on storage.objects;
create policy profile_images_authenticated_upload on storage.objects
  for insert to authenticated with check (bucket_id = 'profile-images');

drop policy if exists profile_images_authenticated_update on storage.objects;
create policy profile_images_authenticated_update on storage.objects
  for update to authenticated using (bucket_id = 'profile-images') with check (bucket_id = 'profile-images');

-- Doctor-specific data
create table if not exists doctors (
  id uuid primary key references profiles(id) on delete cascade on update cascade,
  rating numeric default 0 check (rating >= 0 and rating <= 5),
  review_count integer default 0 check (review_count >= 0)
);

alter table doctors add column if not exists rating numeric default 0 check (rating >= 0 and rating <= 5);
alter table doctors add column if not exists review_count integer default 0 check (review_count >= 0);

-- Appointments between patients and doctors
create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade on update cascade,
  doctor_id uuid not null references profiles(id) on delete cascade on update cascade,
  patient_name text not null,
  doctor_name text not null,
  speciality text,
  appointment_date timestamptz not null,
  time_slot text,
  consultation_fee numeric check (consultation_fee >= 0),
  status text check (status in ('pending', 'confirmed', 'completed', 'cancelled')) default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

alter table appointments add column if not exists patient_name text;
alter table appointments add column if not exists patient_avatar text;
alter table appointments add column if not exists doctor_name text;
alter table appointments add column if not exists doctor_image text;
alter table appointments add column if not exists speciality text;
alter table appointments add column if not exists time_slot text;
alter table appointments add column if not exists consultation_fee numeric check (consultation_fee >= 0);
alter table appointments add column if not exists notes text;
alter table appointments add column if not exists rating numeric check (rating >= 0 and rating <= 5);
alter table appointments add column if not exists review text;
alter table appointments add column if not exists updated_at timestamptz default now();
alter table appointments add column if not exists deleted_at timestamptz;

-- Payments for appointments
create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade on update cascade,
  doctor_id uuid not null references profiles(id) on delete cascade on update cascade,
  appointment_id uuid references appointments(id) on delete set null on update cascade,
  amount numeric not null check (amount >= 0),
  status text check (status in ('pending', 'completed', 'failed')) default 'pending',
  payment_method text,
  payout_status text check (payout_status in ('not_ready', 'pending', 'processed', 'failed')) default 'not_ready',
  created_at timestamptz default now(),
  deleted_at timestamptz
);

alter table payments add column if not exists appointment_id uuid references appointments(id) on delete set null on update cascade;
alter table payments add column if not exists payment_method text;
alter table payments add column if not exists payout_status text check (payout_status in ('not_ready', 'pending', 'processed', 'failed')) default 'not_ready';
alter table payments add column if not exists deleted_at timestamptz;

-- Reviews for doctors
create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references profiles(id) on delete cascade on update cascade,
  user_id uuid not null references profiles(id) on delete cascade on update cascade,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  review_text text,
  approved boolean default false,
  status text check (status in ('pending', 'approved', 'rejected')) default 'pending',
  created_at timestamptz default now(),
  deleted_at timestamptz
);

alter table reviews add column if not exists comment text;
alter table reviews add column if not exists review_text text;
alter table reviews add column if not exists approved boolean default false;
alter table reviews add column if not exists status text check (status in ('pending', 'approved', 'rejected')) default 'pending';
alter table reviews add column if not exists deleted_at timestamptz;

-- System notifications
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  title text,
  message text not null,
  target_role text check (target_role in ('all', 'patient', 'doctor', 'admin')) default 'all',
  user_id uuid references profiles(id) on delete cascade on update cascade,
  created_at timestamptz default now()
);

alter table notifications add column if not exists title text;
alter table notifications add column if not exists target_role text check (target_role in ('all', 'patient', 'doctor', 'admin')) default 'all';
alter table notifications add column if not exists user_id uuid references profiles(id) on delete cascade on update cascade;

-- Platform settings
create table if not exists settings (
  id integer primary key default 1,
  default_fee numeric check (default_fee >= 0),
  platform_commission numeric default 15 check (platform_commission >= 0 and platform_commission <= 100),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table settings add column if not exists default_fee numeric check (default_fee >= 0);
alter table settings add column if not exists platform_commission numeric default 15 check (platform_commission >= 0 and platform_commission <= 100);
alter table settings add column if not exists updated_at timestamptz default now();

create table if not exists specialties (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  active boolean default true,
  created_at timestamptz default now()
);

-- Audit log for admin actions
create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references profiles(id) on update cascade,
  action text not null,
  target_table text,
  target_id uuid,
  details jsonb,
  created_at timestamptz default now()
);


-- Indexes for performance
create index if not exists idx_profiles_email on profiles(email);
create index if not exists idx_appointments_doctor_id on appointments(doctor_id);
create index if not exists idx_appointments_user_id on appointments(user_id);
create index if not exists idx_appointments_status on appointments(status);
create index if not exists idx_payments_user_id on payments(user_id);
create index if not exists idx_payments_doctor_id on payments(doctor_id);
create index if not exists idx_payments_status on payments(status);
create index if not exists idx_reviews_doctor_id on reviews(doctor_id);
create index if not exists idx_reviews_user_id on reviews(user_id);
create index if not exists idx_reviews_rating on reviews(rating);
create index if not exists idx_notifications_target_role on notifications(target_role);

-- Admin access helpers and RLS policies used by the platform-admin dashboard.
create or replace function public.is_platform_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('admin', 'superadmin')
      and coalesce(deactivated, false) = false
  );
$$;

alter table profiles enable row level security;
alter table doctors enable row level security;
alter table appointments enable row level security;
alter table payments enable row level security;
alter table reviews enable row level security;
alter table notifications enable row level security;
alter table settings enable row level security;
alter table specialties enable row level security;
alter table audit_log enable row level security;

drop policy if exists admin_all_profiles on profiles;
create policy admin_all_profiles on profiles
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_doctors on doctors;
create policy admin_all_doctors on doctors
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_appointments on appointments;
create policy admin_all_appointments on appointments
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_payments on payments;
create policy admin_all_payments on payments
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_reviews on reviews;
create policy admin_all_reviews on reviews
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_notifications on notifications;
create policy admin_all_notifications on notifications
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_settings on settings;
create policy admin_all_settings on settings
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_specialties on specialties;
create policy admin_all_specialties on specialties
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists admin_all_audit_log on audit_log;
create policy admin_all_audit_log on audit_log
  for all using (public.is_platform_admin()) with check (public.is_platform_admin());


-- Migration version tracking
create table if not exists migration_versions (
  id serial primary key,
  name text not null,
  applied_at timestamptz default now()
);

-- Audit triggers (example for appointments)
create or replace function log_appointment_update() returns trigger as $$
begin
  insert into audit_log(admin_id, action, target_table, target_id, details)
  values (null, 'update', 'appointments', NEW.id, row_to_json(NEW));
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists appointment_update_audit on appointments;
create trigger appointment_update_audit
  after update on appointments
  for each row execute procedure log_appointment_update();

-- Seed platform superadmin login.
-- Admin portal username: superadmin
-- Admin portal password: 123456
create extension if not exists pgcrypto;

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin
) values (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-4111-8111-111111111111',
  'authenticated',
  'authenticated',
  'superadmin@docconsult.app',
  crypt('123456', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"username":"superadmin","role":"admin"}'::jsonb,
  false
) on conflict (id) do update set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = excluded.email_confirmed_at,
  updated_at = now(),
  raw_app_meta_data = excluded.raw_app_meta_data,
  raw_user_meta_data = excluded.raw_user_meta_data;

insert into auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
) values (
  '22222222-2222-4222-8222-222222222222',
  '11111111-1111-4111-8111-111111111111',
  '{"sub":"11111111-1111-4111-8111-111111111111","email":"superadmin@docconsult.app","username":"superadmin"}'::jsonb,
  'email',
  'superadmin@docconsult.app',
  now(),
  now(),
  now()
) on conflict do nothing;

insert into profiles (
  id,
  username,
  first_name,
  last_name,
  email,
  phone,
  role,
  is_doctor,
  is_patient,
  is_doctor_approved,
  approval_status,
  created_at,
  updated_at
) values (
  '11111111-1111-4111-8111-111111111111',
  'superadmin',
  'Super',
  'Admin',
  'superadmin@docconsult.app',
  '+233000000000',
  'admin',
  false,
  false,
  false,
  'approved',
  now(),
  now()
) on conflict (email) do update set
  username = excluded.username,
  first_name = excluded.first_name,
  last_name = excluded.last_name,
  role = excluded.role,
  is_doctor = false,
  is_patient = false,
  approval_status = 'approved',
  updated_at = now();

insert into settings (id, default_fee, platform_commission)
values (1, 150, 15)
on conflict (id) do update set
  default_fee = excluded.default_fee,
  platform_commission = excluded.platform_commission,
  updated_at = now();

insert into specialties (name) values
  ('Cardiologist'),
  ('Dermatologist'),
  ('Paediatrician'),
  ('Dentist'),
  ('General Practice'),
  ('Eye Specialist')
on conflict (name) do nothing;

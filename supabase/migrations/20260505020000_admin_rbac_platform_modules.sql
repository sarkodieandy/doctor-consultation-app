-- Production admin RBAC and platform operations modules
-- Non-breaking migration: adds missing tables and policies used by admin dashboard + Flutter integration.

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- 1) Admin roles and permissions
-- -----------------------------------------------------------------------------
create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  is_system boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.admin_permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  module text not null,
  action text not null,
  description text,
  created_at timestamptz default now()
);

create table if not exists public.admin_role_permissions (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references public.admin_roles(id) on delete cascade,
  permission_id uuid not null references public.admin_permissions(id) on delete cascade,
  created_at timestamptz default now(),
  unique(role_id, permission_id)
);

create table if not exists public.admin_users (
  id uuid primary key references public.profiles(id) on delete cascade,
  role_id uuid not null references public.admin_roles(id) on delete restrict,
  is_active boolean default true,
  last_login_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create index if not exists idx_admin_users_role on public.admin_users(role_id);
create index if not exists idx_admin_users_active on public.admin_users(is_active);
create index if not exists idx_admin_role_permissions_role on public.admin_role_permissions(role_id);

insert into public.admin_roles (code, name, description, is_system)
values
  ('super_admin', 'Super Admin', 'Full access to all modules', true),
  ('finance_admin', 'Finance Admin', 'Payments, payouts, refunds, reports access', true),
  ('support_admin', 'Support Admin', 'Support tickets, complaints, users support actions', true),
  ('doctor_verification_admin', 'Doctor Verification Admin', 'Doctor approvals and credential checks', true),
  ('content_manager', 'Content Manager', 'CMS, banners, health tips, announcements', true)
on conflict (code) do nothing;

insert into public.admin_permissions (code, module, action, description)
values
  ('dashboard.view', 'dashboard', 'view', 'View overview metrics'),
  ('patients.manage', 'patients', 'manage', 'Manage patient records'),
  ('doctors.manage', 'doctors', 'manage', 'Manage doctor profiles'),
  ('doctors.verify', 'doctor_verification', 'verify', 'Approve/reject doctor documents'),
  ('appointments.manage', 'appointments', 'manage', 'Manage appointments'),
  ('consultations.view', 'consultations', 'view', 'View consultation records'),
  ('payments.manage', 'payments', 'manage', 'Manage payments and references'),
  ('payouts.manage', 'payouts', 'manage', 'Manage doctor payouts'),
  ('reviews.moderate', 'reviews', 'moderate', 'Moderate reviews and ratings'),
  ('complaints.manage', 'complaints', 'manage', 'Handle complaints and disputes'),
  ('refunds.manage', 'refunds', 'manage', 'Handle refunds'),
  ('notifications.manage', 'notifications', 'manage', 'Send and manage notifications'),
  ('content.manage', 'cms', 'manage', 'Manage CMS content and banners'),
  ('support.manage', 'support', 'manage', 'Manage support tickets'),
  ('reports.view', 'reports', 'view', 'Access analytics and report exports'),
  ('audit.view', 'audit', 'view', 'View audit logs'),
  ('settings.manage', 'settings', 'manage', 'Manage platform settings')
on conflict (code) do nothing;

-- Super Admin gets all permissions
insert into public.admin_role_permissions (role_id, permission_id)
select r.id, p.id
from public.admin_roles r
cross join public.admin_permissions p
where r.code = 'super_admin'
on conflict (role_id, permission_id) do nothing;

-- Finance Admin
insert into public.admin_role_permissions (role_id, permission_id)
select r.id, p.id
from public.admin_roles r
join public.admin_permissions p on p.code in (
  'dashboard.view', 'payments.manage', 'payouts.manage', 'refunds.manage', 'reports.view', 'audit.view'
)
where r.code = 'finance_admin'
on conflict (role_id, permission_id) do nothing;

-- Support Admin
insert into public.admin_role_permissions (role_id, permission_id)
select r.id, p.id
from public.admin_roles r
join public.admin_permissions p on p.code in (
  'dashboard.view', 'patients.manage', 'appointments.manage', 'complaints.manage', 'support.manage', 'notifications.manage', 'audit.view'
)
where r.code = 'support_admin'
on conflict (role_id, permission_id) do nothing;

-- Doctor Verification Admin
insert into public.admin_role_permissions (role_id, permission_id)
select r.id, p.id
from public.admin_roles r
join public.admin_permissions p on p.code in (
  'dashboard.view', 'doctors.manage', 'doctors.verify', 'appointments.manage', 'reviews.moderate', 'audit.view'
)
where r.code = 'doctor_verification_admin'
on conflict (role_id, permission_id) do nothing;

-- Content Manager
insert into public.admin_role_permissions (role_id, permission_id)
select r.id, p.id
from public.admin_roles r
join public.admin_permissions p on p.code in (
  'dashboard.view', 'notifications.manage', 'content.manage', 'reports.view'
)
where r.code = 'content_manager'
on conflict (role_id, permission_id) do nothing;

-- -----------------------------------------------------------------------------
-- 2) Domain tables requested by production scope
-- -----------------------------------------------------------------------------
create table if not exists public.patients (
  id uuid primary key references public.profiles(id) on delete cascade,
  patient_code text unique,
  gender text check (gender in ('male', 'female', 'other', 'unknown')) default 'unknown',
  date_of_birth date,
  location text,
  support_status text check (support_status in ('normal', 'needs_help', 'escalated', 'restricted')) default 'normal',
  last_login_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.doctor_verifications (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  status text not null check (status in ('pending', 'approved', 'rejected', 'more_documents_required', 'suspended', 'reverify_required')) default 'pending',
  reviewer_id uuid references public.profiles(id) on delete set null,
  decision_reason text,
  admin_note text,
  requested_documents text[],
  reviewed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.doctor_documents (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  verification_id uuid references public.doctor_verifications(id) on delete set null,
  document_type text not null check (document_type in (
    'medical_license', 'national_id', 'passport', 'professional_certificate',
    'profile_photo', 'hospital_proof', 'specialty_proof', 'bank_or_momo_details', 'other'
  )),
  storage_path text not null,
  file_name text,
  mime_type text,
  status text not null check (status in ('uploaded', 'approved', 'rejected', 'needs_resubmission')) default 'uploaded',
  rejection_reason text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.doctor_specialties (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  specialty_id uuid not null references public.specialties(id) on delete cascade,
  is_primary boolean default false,
  created_at timestamptz default now(),
  unique(doctor_id, specialty_id)
);

create table if not exists public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  weekday int check (weekday between 0 and 6),
  date_override date,
  start_time time not null,
  end_time time not null,
  consultation_duration_minutes int not null default 30 check (consultation_duration_minutes > 0),
  break_start time,
  break_end time,
  timezone text default 'Africa/Accra',
  is_available boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  check (start_time < end_time),
  check ((weekday is not null) or (date_override is not null))
);

create table if not exists public.consultations (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  consultation_type text not null check (consultation_type in ('video', 'audio', 'chat', 'physical')),
  status text not null check (status in ('scheduled', 'in_progress', 'completed', 'cancelled', 'missed')) default 'scheduled',
  payment_status text check (payment_status in ('pending', 'completed', 'failed', 'refunded')) default 'pending',
  start_time timestamptz,
  end_time timestamptz,
  duration_seconds int,
  prescription_issued boolean default false,
  patient_feedback jsonb,
  complaint_status text check (complaint_status in ('none', 'open', 'under_review', 'resolved')) default 'none',
  admin_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.medical_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.profiles(id) on delete cascade,
  uploaded_by uuid not null references public.profiles(id) on delete cascade,
  appointment_id uuid references public.appointments(id) on delete set null,
  document_type text not null check (document_type in (
    'lab_result', 'scan_report', 'previous_prescription', 'medical_history',
    'insurance_document', 'other_health_document'
  )),
  storage_bucket text default 'medical-documents',
  storage_path text not null,
  file_name text,
  mime_type text,
  file_size bigint,
  status text check (status in ('active', 'removed', 'restricted')) default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.profiles(id) on delete cascade,
  payment_id uuid references public.payments(id) on delete set null,
  amount numeric(10,2) not null check (amount > 0),
  currency text default 'GHS',
  payout_method text,
  destination_account text,
  recipient_code text,
  transfer_code text,
  status text not null check (status in ('pending', 'processing', 'paid', 'failed', 'on_hold')) default 'pending',
  failure_reason text,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  complaint_code text unique,
  patient_id uuid references public.profiles(id) on delete set null,
  doctor_id uuid references public.profiles(id) on delete set null,
  appointment_id uuid references public.appointments(id) on delete set null,
  consultation_id uuid references public.consultations(id) on delete set null,
  payment_id uuid references public.payments(id) on delete set null,
  complaint_type text not null check (complaint_type in (
    'doctor_no_show', 'patient_no_show', 'wrong_charge', 'poor_service', 'refund_request',
    'prescription_issue', 'app_problem', 'payment_problem', 'other'
  )),
  subject text,
  message text not null,
  status text not null check (status in ('open', 'under_review', 'waiting_for_doctor', 'waiting_for_patient', 'resolved', 'closed')) default 'open',
  priority text check (priority in ('low', 'medium', 'high', 'critical')) default 'medium',
  assigned_admin_id uuid references public.profiles(id) on delete set null,
  admin_note text,
  resolved_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete cascade,
  complaint_id uuid references public.complaints(id) on delete set null,
  patient_id uuid references public.profiles(id) on delete set null,
  doctor_id uuid references public.profiles(id) on delete set null,
  amount numeric(10,2) not null check (amount > 0),
  reason text,
  status text not null check (status in ('requested', 'approved', 'rejected', 'processing', 'refunded', 'failed')) default 'requested',
  decision_reason text,
  gateway_reference text,
  decided_by uuid references public.profiles(id) on delete set null,
  decided_at timestamptz,
  refunded_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_code text unique,
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_type text not null check (user_type in ('patient', 'doctor', 'admin')),
  subject text not null,
  message text not null,
  priority text check (priority in ('low', 'medium', 'high', 'critical')) default 'medium',
  status text not null check (status in ('open', 'in_progress', 'waiting_for_user', 'resolved', 'closed')) default 'open',
  assigned_admin_id uuid references public.profiles(id) on delete set null,
  internal_note text,
  resolved_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.support_ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  author_role text not null check (author_role in ('patient', 'doctor', 'admin')),
  message text not null,
  is_internal boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.cms_pages (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  content text,
  content_json jsonb,
  status text check (status in ('draft', 'published', 'archived')) default 'draft',
  published_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.app_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  cta_text text,
  cta_link text,
  audience text check (audience in ('all', 'patient', 'doctor', 'admin')) default 'all',
  is_active boolean default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.health_tips (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text,
  audience text check (audience in ('all', 'patient', 'doctor')) default 'all',
  status text check (status in ('draft', 'published', 'archived')) default 'draft',
  published_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists public.system_settings (
  key text primary key,
  value jsonb not null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- -----------------------------------------------------------------------------
-- 3) Extend existing tables for production tracking
-- -----------------------------------------------------------------------------
alter table public.specialties
  add column if not exists description text,
  add column if not exists icon_url text,
  add column if not exists default_consultation_fee numeric check (default_consultation_fee >= 0),
  add column if not exists updated_at timestamptz default now(),
  add column if not exists deleted_at timestamptz;

alter table public.doctors
  add column if not exists featured boolean default false,
  add column if not exists listed_publicly boolean default true,
  add column if not exists commission_percentage numeric default 15 check (commission_percentage >= 0 and commission_percentage <= 100),
  add column if not exists total_earnings numeric(12,2) default 0,
  add column if not exists pending_payout numeric(12,2) default 0,
  add column if not exists updated_at timestamptz default now();

alter table public.profiles
  add column if not exists medical_license_number text,
  add column if not exists hospital_affiliation text,
  add column if not exists featured boolean default false,
  add column if not exists listed_publicly boolean default true,
  add column if not exists last_login_at timestamptz;

alter table public.appointments
  add column if not exists appointment_code text,
  add column if not exists consultation_type text check (consultation_type in ('video', 'audio', 'chat', 'physical')) default 'video',
  add column if not exists consultation_status text,
  add column if not exists payment_status text,
  add column if not exists platform_commission numeric(10,2),
  add column if not exists doctor_earning numeric(10,2),
  add column if not exists booking_notes text,
  add column if not exists cancellation_reason text,
  add column if not exists admin_notes text,
  add column if not exists refund_status text,
  add column if not exists reassigned_doctor_id uuid references public.profiles(id) on delete set null;

alter table public.audit_log
  add column if not exists admin_role text,
  add column if not exists old_value jsonb,
  add column if not exists new_value jsonb,
  add column if not exists ip_address text,
  add column if not exists device_info text;

create or replace view public.audit_logs as
select * from public.audit_log;

-- -----------------------------------------------------------------------------
-- 4) Indexes for filters/search
-- -----------------------------------------------------------------------------
create index if not exists idx_patients_support_status on public.patients(support_status);
create index if not exists idx_doctor_verifications_doctor on public.doctor_verifications(doctor_id, status);
create index if not exists idx_doctor_documents_doctor on public.doctor_documents(doctor_id, document_type, status);
create index if not exists idx_doctor_availability_doctor on public.doctor_availability(doctor_id, weekday, date_override);
create index if not exists idx_consultations_appointment on public.consultations(appointment_id, status);
create index if not exists idx_consultations_doctor on public.consultations(doctor_id, start_time);
create index if not exists idx_medical_documents_patient on public.medical_documents(patient_id, document_type, status);
create index if not exists idx_payouts_doctor_status on public.payouts(doctor_id, status, created_at desc);
create index if not exists idx_complaints_status_priority on public.complaints(status, priority, created_at desc);
create index if not exists idx_refunds_status on public.refunds(status, created_at desc);
create index if not exists idx_support_tickets_status on public.support_tickets(status, priority, created_at desc);
create index if not exists idx_support_tickets_user on public.support_tickets(user_id, created_at desc);
create index if not exists idx_cms_pages_slug on public.cms_pages(slug);
create index if not exists idx_app_banners_active on public.app_banners(is_active, starts_at, ends_at);
create index if not exists idx_health_tips_status on public.health_tips(status, created_at desc);

-- -----------------------------------------------------------------------------
-- 5) Storage buckets for medical docs and CMS assets
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'medical-documents',
  'medical-documents',
  false,
  15728640,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'cms-assets',
  'cms-assets',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- -----------------------------------------------------------------------------
-- 6) RBAC helper functions and RLS policies
-- -----------------------------------------------------------------------------
create or replace function public.current_admin_role_code()
returns text
language sql
security definer
set search_path = public
as $$
  select ar.code
  from public.admin_users au
  join public.admin_roles ar on ar.id = au.role_id
  where au.id = auth.uid()
    and au.is_active = true
    and au.deleted_at is null
  limit 1;
$$;

create or replace function public.has_admin_permission(permission_code text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users au
    join public.admin_roles ar on ar.id = au.role_id
    join public.admin_role_permissions arp on arp.role_id = ar.id
    join public.admin_permissions ap on ap.id = arp.permission_id
    where au.id = auth.uid()
      and au.is_active = true
      and au.deleted_at is null
      and ap.code = permission_code
  )
  or public.current_admin_role_code() = 'super_admin';
$$;

alter table public.admin_roles enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_users enable row level security;
alter table public.patients enable row level security;
alter table public.doctor_verifications enable row level security;
alter table public.doctor_documents enable row level security;
alter table public.doctor_specialties enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.consultations enable row level security;
alter table public.medical_documents enable row level security;
alter table public.payouts enable row level security;
alter table public.complaints enable row level security;
alter table public.refunds enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_ticket_messages enable row level security;
alter table public.cms_pages enable row level security;
alter table public.app_banners enable row level security;
alter table public.health_tips enable row level security;
alter table public.system_settings enable row level security;

-- Admin full control on operational/admin tables
do $$
declare
  table_name text;
begin
  for table_name in
    select unnest(array[
      'admin_roles', 'admin_permissions', 'admin_role_permissions', 'admin_users',
      'patients', 'doctor_verifications', 'doctor_documents', 'doctor_specialties', 'doctor_availability',
      'consultations', 'medical_documents', 'payouts', 'complaints', 'refunds',
      'support_tickets', 'support_ticket_messages', 'cms_pages', 'app_banners', 'health_tips', 'system_settings'
    ])
  loop
    execute format('drop policy if exists admin_all_%I on public.%I', table_name, table_name);
    execute format('create policy admin_all_%I on public.%I for all using (public.is_platform_admin()) with check (public.is_platform_admin())', table_name, table_name);
  end loop;
end $$;

-- Recipient access policies (patient/doctor self scope)
drop policy if exists patient_own_patient_row on public.patients;
create policy patient_own_patient_row on public.patients
  for select using (auth.uid() = id or public.is_platform_admin());

drop policy if exists doctor_own_verification on public.doctor_verifications;
create policy doctor_own_verification on public.doctor_verifications
  for select using (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_own_documents on public.doctor_documents;
create policy doctor_own_documents on public.doctor_documents
  for select using (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_upload_documents on public.doctor_documents;
create policy doctor_upload_documents on public.doctor_documents
  for insert with check (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_own_availability_read on public.doctor_availability;
create policy doctor_own_availability_read on public.doctor_availability
  for select using (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_own_availability_write on public.doctor_availability;
create policy doctor_own_availability_write on public.doctor_availability
  for all using (auth.uid() = doctor_id or public.is_platform_admin())
  with check (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists consultation_participants_read on public.consultations;
create policy consultation_participants_read on public.consultations
  for select using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists consultation_doctor_update on public.consultations;
create policy consultation_doctor_update on public.consultations
  for update using (auth.uid() = doctor_id or public.is_platform_admin())
  with check (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists medical_docs_owner_read on public.medical_documents;
create policy medical_docs_owner_read on public.medical_documents
  for select using (auth.uid() = patient_id or auth.uid() = uploaded_by or public.is_platform_admin());

drop policy if exists medical_docs_owner_insert on public.medical_documents;
create policy medical_docs_owner_insert on public.medical_documents
  for insert with check (auth.uid() = uploaded_by or public.is_platform_admin());

drop policy if exists doctor_own_payouts on public.payouts;
create policy doctor_own_payouts on public.payouts
  for select using (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists complaint_participants_read on public.complaints;
create policy complaint_participants_read on public.complaints
  for select using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists complaint_patient_insert on public.complaints;
create policy complaint_patient_insert on public.complaints
  for insert with check (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists refund_participants_read on public.refunds;
create policy refund_participants_read on public.refunds
  for select using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists support_ticket_owner_read on public.support_tickets;
create policy support_ticket_owner_read on public.support_tickets
  for select using (auth.uid() = user_id or public.is_platform_admin());

drop policy if exists support_ticket_owner_insert on public.support_tickets;
create policy support_ticket_owner_insert on public.support_tickets
  for insert with check (auth.uid() = user_id or public.is_platform_admin());

drop policy if exists support_ticket_messages_read on public.support_ticket_messages;
create policy support_ticket_messages_read on public.support_ticket_messages
  for select using (
    exists (
      select 1
      from public.support_tickets st
      where st.id = support_ticket_messages.ticket_id
        and (st.user_id = auth.uid() or st.assigned_admin_id = auth.uid() or public.is_platform_admin())
    )
  );

drop policy if exists support_ticket_messages_insert on public.support_ticket_messages;
create policy support_ticket_messages_insert on public.support_ticket_messages
  for insert with check (
    auth.uid() = author_id and exists (
      select 1
      from public.support_tickets st
      where st.id = support_ticket_messages.ticket_id
        and (st.user_id = auth.uid() or st.assigned_admin_id = auth.uid() or public.is_platform_admin())
    )
  );

-- Public read for active CMS content used in app
drop policy if exists cms_pages_public_read on public.cms_pages;
create policy cms_pages_public_read on public.cms_pages
  for select using (status = 'published' and deleted_at is null);

drop policy if exists app_banners_public_read on public.app_banners;
create policy app_banners_public_read on public.app_banners
  for select using (
    is_active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
    and deleted_at is null
  );

drop policy if exists health_tips_public_read on public.health_tips;
create policy health_tips_public_read on public.health_tips
  for select using (status = 'published' and deleted_at is null);

-- -----------------------------------------------------------------------------
-- 7) Realtime publication additions
-- -----------------------------------------------------------------------------
do $$
begin
  begin
    alter publication supabase_realtime add table consultations;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table support_tickets;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table complaints;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table refunds;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table payouts;
  exception when others then null;
  end;
end $$;

-- -----------------------------------------------------------------------------
-- 8) Seed baseline system settings
-- -----------------------------------------------------------------------------
insert into public.system_settings (key, value)
values
  ('platform_commission', jsonb_build_object('percent', 15)),
  ('default_consultation_fee', jsonb_build_object('amount', 150, 'currency', 'GHS')),
  ('minimum_doctor_withdrawal_amount', jsonb_build_object('amount', 50, 'currency', 'GHS')),
  ('appointment_cancellation_policy', jsonb_build_object('hours_before', 24, 'refund_percent', 100)),
  ('refund_policy', jsonb_build_object('enabled', true, 'auto_refund_hours', 48)),
  ('consultation_defaults', jsonb_build_object('duration_minutes', 30, 'allow_video', true, 'allow_audio', true, 'allow_chat', true)),
  ('payment_gateway', jsonb_build_object('provider', 'paystack', 'enabled', true)),
  ('push_provider', jsonb_build_object('provider', 'fcm', 'enabled', false)),
  ('sms_provider', jsonb_build_object('provider', 'placeholder', 'enabled', false)),
  ('email_provider', jsonb_build_object('provider', 'placeholder', 'enabled', false)),
  ('maintenance_mode', jsonb_build_object('enabled', false)),
  ('app_version_control', jsonb_build_object('min_supported_version', '1.0.0', 'latest_version', '1.0.0'))
on conflict (key) do nothing;

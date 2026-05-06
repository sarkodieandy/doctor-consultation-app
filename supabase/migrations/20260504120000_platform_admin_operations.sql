-- Platform admin operational hardening.
-- Ensures admin actions update the same fields the Flutter app reads.

alter table public.profiles
  add column if not exists is_active boolean default true;

alter table public.profiles
  add column if not exists is_doctor_approved boolean default false;

alter table public.profiles
  add column if not exists approval_note text;

alter table public.profiles
  add column if not exists deactivated boolean default false;

alter table public.profiles
  add column if not exists updated_at timestamptz default now();

update public.profiles
set
  is_doctor_approved = approval_status = 'approved',
  is_active = coalesce(is_active, approval_status = 'approved')
where role = 'doctor';

create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.profiles(id) on update cascade,
  action text not null,
  target_table text,
  target_id uuid,
  details jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_audit_log_created_at on public.audit_log(created_at desc);
create index if not exists idx_audit_log_target on public.audit_log(target_table, target_id);
create index if not exists idx_profiles_admin_doctors
  on public.profiles(role, approval_status, is_active, deactivated);

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

alter table public.audit_log enable row level security;

drop policy if exists admin_all_audit_log on public.audit_log;
create policy admin_all_audit_log on public.audit_log
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_profiles on public.profiles;
create policy admin_all_profiles on public.profiles
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_doctors on public.doctors;
create policy admin_all_doctors on public.doctors
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_appointments on public.appointments;
create policy admin_all_appointments on public.appointments
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_payments on public.payments;
create policy admin_all_payments on public.payments
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_reviews on public.reviews;
create policy admin_all_reviews on public.reviews
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_notifications on public.notifications;
create policy admin_all_notifications on public.notifications
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_settings on public.settings;
create policy admin_all_settings on public.settings
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists admin_all_specialties on public.specialties;
create policy admin_all_specialties on public.specialties
  for all
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

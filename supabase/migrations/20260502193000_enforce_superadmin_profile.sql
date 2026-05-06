-- Ensure the seeded superadmin auth user is recognized as an admin profile.
-- This enables real credential login from platform-admin without preview mode.

-- Clear username from any stale profile that isn't the real auth user,
-- to avoid unique constraint violations on idx_profiles_username.
update public.profiles
set username = null
where username = 'superadmin'
  and id not in (
    select id from auth.users where lower(email) = 'superadmin@docconsult.app'
  );

insert into public.profiles (
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
  updated_at
)
select
  u.id,
  'superadmin',
  'Super',
  'Admin',
  lower(u.email),
  '+233000000000',
  'admin',
  false,
  false,
  false,
  'approved',
  now()
from auth.users u
where lower(u.email) = 'superadmin@docconsult.app'
on conflict (id) do update set
  username = 'superadmin',
  first_name = excluded.first_name,
  last_name = excluded.last_name,
  email = excluded.email,
  role = 'admin',
  is_doctor = false,
  is_patient = false,
  approval_status = 'approved',
  deactivated = false,
  updated_at = now();

update public.profiles
set
  role = 'admin',
  is_doctor = false,
  is_patient = false,
  approval_status = 'approved',
  deactivated = false,
  updated_at = now()
where lower(email) = 'superadmin@docconsult.app';

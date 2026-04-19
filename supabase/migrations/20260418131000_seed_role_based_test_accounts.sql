-- ================================================================
-- MIGRATION 023: Seed Role-Based Test Accounts
-- ================================================================
-- Creates the core test accounts used across the Flutter app and
-- local platform admin after running migration 022.
--
-- Accounts:
--   - patient@test.com / Test1234!
--   - doctor@test.com / Test1234!
--   - admin@test.com / Test1234!
-- ================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

DO $$
DECLARE
  patient_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0001';
  doctor_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0002';
  admin_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003';
BEGIN
  DELETE FROM public.commission_tiers;
  DELETE FROM public.commission_settings;

  DELETE FROM public.doctor_earnings
  WHERE doctor_id IN (doctor_uid);

  DELETE FROM public.doctor_verifications
  WHERE doctor_id IN (doctor_uid);

  DELETE FROM public.doctors
  WHERE profile_id IN (patient_uid, doctor_uid, admin_uid);

  DELETE FROM public.profiles
  WHERE id IN (patient_uid, doctor_uid, admin_uid)
     OR email IN ('patient@test.com', 'doctor@test.com', 'admin@test.com');

  DELETE FROM auth.identities
  WHERE user_id IN (patient_uid, doctor_uid, admin_uid)
     OR provider_id IN ('patient@test.com', 'doctor@test.com', 'admin@test.com');

  DELETE FROM auth.users
  WHERE id IN (patient_uid, doctor_uid, admin_uid)
     OR email IN ('patient@test.com', 'doctor@test.com', 'admin@test.com');

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    patient_uid,
    'authenticated',
    'authenticated',
    'patient@test.com',
    extensions.crypt('Test1234!', extensions.gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    '{"first_name":"Test","last_name":"Patient"}',
    FALSE
  ), (
    '00000000-0000-0000-0000-000000000000',
    doctor_uid,
    'authenticated',
    'authenticated',
    'doctor@test.com',
    extensions.crypt('Test1234!', extensions.gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    '{"first_name":"Dr. Dev","last_name":"Tester"}',
    FALSE
  ), (
    '00000000-0000-0000-0000-000000000000',
    admin_uid,
    'authenticated',
    'authenticated',
    'admin@test.com',
    extensions.crypt('Test1234!', extensions.gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    '{"first_name":"Platform","last_name":"Admin"}',
    FALSE
  );

  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    provider,
    identity_data,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    patient_uid,
    'patient@test.com',
    'email',
    jsonb_build_object(
      'sub', patient_uid::text,
      'email', 'patient@test.com',
      'email_verified', true
    ),
    NOW(),
    NOW(),
    NOW()
  ), (
    gen_random_uuid(),
    doctor_uid,
    'doctor@test.com',
    'email',
    jsonb_build_object(
      'sub', doctor_uid::text,
      'email', 'doctor@test.com',
      'email_verified', true
    ),
    NOW(),
    NOW(),
    NOW()
  ), (
    gen_random_uuid(),
    admin_uid,
    'admin@test.com',
    'email',
    jsonb_build_object(
      'sub', admin_uid::text,
      'email', 'admin@test.com',
      'email_verified', true
    ),
    NOW(),
    NOW(),
    NOW()
  );

  INSERT INTO public.profiles (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    is_online,
    created_at,
    updated_at
  ) VALUES (
    patient_uid,
    'patient@test.com',
    'Test',
    'Patient',
    '+233501234567',
    'patient',
    TRUE,
    NOW(),
    NOW()
  );

  INSERT INTO public.profiles (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    specialty,
    experience,
    consultation_fee,
    bio,
    approval_status,
    approval_note,
    approved_at,
    verification_method,
    is_online,
    created_at,
    updated_at
  ) VALUES (
    doctor_uid,
    'doctor@test.com',
    'Dr. Dev',
    'Tester',
    '+233509876543',
    'doctor',
    'General Practice',
    '5 years',
    35.00,
    'Test doctor account for development',
    'approved',
    'Automatically approved for local testing',
    NOW(),
    'seed',
    TRUE,
    NOW(),
    NOW()
  );

  INSERT INTO public.profiles (
    id,
    email,
    first_name,
    last_name,
    phone,
    role,
    is_online,
    created_at,
    updated_at
  ) VALUES (
    admin_uid,
    'admin@test.com',
    'Platform',
    'Admin',
    '+233500000000',
    'admin',
    TRUE,
    NOW(),
    NOW()
  );

  INSERT INTO public.doctor_verifications (
    doctor_id,
    license_verified,
    ghana_card_verified,
    overall_status,
    confidence_score,
    verification_notes,
    verification_method,
    verified_at,
    created_at,
    updated_at
  ) VALUES (
    doctor_uid,
    TRUE,
    TRUE,
    'approved',
    1.0,
    'Seeded approved doctor profile for local testing',
    'seed',
    NOW(),
    NOW(),
    NOW()
  );

  INSERT INTO public.doctor_earnings (
    doctor_id,
    month_year,
    created_at,
    updated_at
  ) VALUES (
    doctor_uid,
    TO_CHAR(NOW(), 'YYYY-MM'),
    NOW(),
    NOW()
  );

  INSERT INTO public.admin_settings (
    key,
    value,
    created_at,
    updated_at
  ) VALUES (
    'commission_settings',
    jsonb_build_object(
      'default_rate', 15,
      'currency', 'GHS',
      'minimum_fee', 0,
      'tiers_enabled', true
    ),
    NOW(),
    NOW()
  ) ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = NOW();

  INSERT INTO public.commission_settings (
    commission_type,
    commission_rate,
    applies_to_all,
    is_active,
    description,
    created_by_admin,
    effective_date,
    created_at,
    updated_at
  ) VALUES (
    'percentage',
    15.00,
    TRUE,
    TRUE,
    'Default platform commission',
    admin_uid,
    NOW(),
    NOW(),
    NOW()
  );

  INSERT INTO public.commission_tiers (
    name,
    min_consultations,
    rate,
    bonus,
    is_active,
    created_at,
    updated_at
  ) VALUES
    ('Starter', 0, 15.00, 0.00, TRUE, NOW(), NOW()),
    ('Growth', 25, 12.50, 50.00, TRUE, NOW(), NOW()),
    ('Top Performer', 50, 10.00, 150.00, TRUE, NOW(), NOW());
END $$;

COMMIT;

SELECT id, email
FROM auth.users
WHERE email IN ('patient@test.com', 'doctor@test.com', 'admin@test.com')
ORDER BY email;
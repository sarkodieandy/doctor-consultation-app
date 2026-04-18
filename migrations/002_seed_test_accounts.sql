-- ================================================================
-- DEV TEST ACCOUNTS – Doctor + Patient
-- ================================================================
-- Run this in Supabase Dashboard → SQL Editor AFTER 001_create_profiles_table.sql
-- ================================================================

-- Fixed UUIDs so we can reference them in profiles
DO $$
DECLARE
  patient_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0001';
  doctor_uid  UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0002';
BEGIN

  -- =====================
  -- 1. CREATE AUTH USERS
  -- =====================

  -- Test Patient
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at, confirmation_token,
    raw_app_meta_data, raw_user_meta_data
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    patient_uid,
    'authenticated', 'authenticated',
    'patient@test.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), NOW(), NOW(), '',
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "Test", "last_name": "Patient"}'
  ) ON CONFLICT (id) DO NOTHING;

  -- Also insert identity for the patient
  INSERT INTO auth.identities (
    id, user_id, provider_id, provider,
    identity_data, last_sign_in_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    patient_uid,
    'patient@test.com',
    'email',
    jsonb_build_object('sub', patient_uid::text, 'email', 'patient@test.com'),
    NOW(), NOW(), NOW()
  ) ON CONFLICT DO NOTHING;

  -- Test Doctor
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at, confirmation_token,
    raw_app_meta_data, raw_user_meta_data
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    doctor_uid,
    'authenticated', 'authenticated',
    'doctor@test.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), NOW(), NOW(), '',
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "Dr. Dev", "last_name": "Tester"}'
  ) ON CONFLICT (id) DO NOTHING;

  -- Also insert identity for the doctor
  INSERT INTO auth.identities (
    id, user_id, provider_id, provider,
    identity_data, last_sign_in_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    doctor_uid,
    'doctor@test.com',
    'email',
    jsonb_build_object('sub', doctor_uid::text, 'email', 'doctor@test.com'),
    NOW(), NOW(), NOW()
  ) ON CONFLICT DO NOTHING;

  -- =====================
  -- 2. CREATE PROFILES
  -- =====================

  -- Patient profile
  INSERT INTO public.profiles (
    id, email, first_name, last_name, phone,
    role, is_online, created_at, updated_at
  ) VALUES (
    patient_uid,
    'patient@test.com',
    'Test', 'Patient', '+233501234567',
    'patient', true, NOW(), NOW()
  ) ON CONFLICT (id) DO NOTHING;

  -- Doctor profile (approved)
  INSERT INTO public.profiles (
    id, email, first_name, last_name, phone,
    role, specialty, experience, consultation_fee,
    approval_status, is_online, created_at, updated_at
  ) VALUES (
    doctor_uid,
    'doctor@test.com',
    'Dr. Dev', 'Tester', '+233509876543',
    'doctor', 'General Practice', '5 years', 35.0,
    'approved', true, NOW(), NOW()
  ) ON CONFLICT (id) DO NOTHING;

  -- Also add doctor to public doctors listing
  INSERT INTO public.doctors (
    id, profile_id, name, specialty, description,
    image_url, rating, review_count, consultation_fee,
    experience, hospital, available, available_times
  ) VALUES (
    gen_random_uuid(),
    doctor_uid,
    'Dr. Dev Tester',
    'General Practice',
    'Test doctor account for development',
    'assets/images/doctor1.png',
    4.5, 0, 35.0,
    '5 years', 'Dev Hospital', true,
    ARRAY['09:00 AM','10:00 AM','11:00 AM','02:00 PM','03:00 PM']
  ) ON CONFLICT DO NOTHING;

END $$;

-- ================================================================
-- LOGIN CREDENTIALS:
--
--   PATIENT:
--     Email:    patient@test.com
--     Password: Test1234!
--
--   DOCTOR:
--     Email:    doctor@test.com
--     Password: Test1234!
--
-- ================================================================

-- ================================================================
-- ADMIN ACCOUNT for Platform Admin Dashboard
-- ================================================================
-- Run in Supabase Dashboard → SQL Editor AFTER 001 and 002
-- Login: admin@test.com / Test1234!
-- ================================================================

DO $$
DECLARE
  admin_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003';
BEGIN

  -- Create auth user
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at, confirmation_token,
    raw_app_meta_data, raw_user_meta_data
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    admin_uid,
    'authenticated', 'authenticated',
    'admin@test.com',
    crypt('Test1234!', gen_salt('bf')),
    NOW(), NOW(), NOW(), '',
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "Platform", "last_name": "Admin"}'
  ) ON CONFLICT (id) DO NOTHING;

  -- Create identity
  INSERT INTO auth.identities (
    id, user_id, provider_id, provider,
    identity_data, last_sign_in_at,
    created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    admin_uid,
    'admin@test.com',
    'email',
    jsonb_build_object('sub', admin_uid::text, 'email', 'admin@test.com'),
    NOW(), NOW(), NOW()
  ) ON CONFLICT DO NOTHING;

  -- Create admin profile
  INSERT INTO public.profiles (
    id, email, first_name, last_name, phone,
    role, is_online, created_at, updated_at
  ) VALUES (
    admin_uid,
    'admin@test.com',
    'Platform', 'Admin', '+233500000000',
    'admin', true, NOW(), NOW()
  ) ON CONFLICT (id) DO NOTHING;

END $$;

-- ================================================================
-- ADMIN RLS POLICIES
-- Allow admin role to SELECT all tables
-- ================================================================

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'profiles', 'doctors', 'appointments', 'payments',
      'reviews', 'messages', 'health_records', 'prescriptions',
      'medicines', 'consultations', 'doctor_schedules',
      'chat_sessions', 'notifications', 'doctor_earnings'
    ])
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS admin_select_%I ON public.%I',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY admin_select_%I ON public.%I FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
      )',
      tbl, tbl
    );
    -- Admin can also UPDATE (for approve/reject)
    EXECUTE format(
      'DROP POLICY IF EXISTS admin_update_%I ON public.%I',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY admin_update_%I ON public.%I FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
      )',
      tbl, tbl
    );
    -- Admin can DELETE
    EXECUTE format(
      'DROP POLICY IF EXISTS admin_delete_%I ON public.%I',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY admin_delete_%I ON public.%I FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
      )',
      tbl, tbl
    );
    -- Admin can INSERT (for approving doctors -> inserting into doctors table)
    EXECUTE format(
      'DROP POLICY IF EXISTS admin_insert_%I ON public.%I',
      tbl, tbl
    );
    EXECUTE format(
      'CREATE POLICY admin_insert_%I ON public.%I FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ''admin'')
      )',
      tbl, tbl
    );
  END LOOP;
END $$;

-- ================================================================
-- LOGIN: admin@test.com / Test1234!
-- ================================================================

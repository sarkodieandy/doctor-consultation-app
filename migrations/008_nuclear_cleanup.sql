-- ================================================================
-- NUCLEAR FIX: Clean up everything that might be breaking GoTrue
-- Run in Supabase Dashboard → SQL Editor
-- ================================================================

-- 1. Drop the is_admin() function (might interfere with GoTrue)
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;

-- 2. Drop ALL custom policies on ALL tables (start clean)
DO $$
DECLARE
  tbl TEXT;
  pol RECORD;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'profiles', 'doctors', 'appointments', 'payments',
      'reviews', 'messages', 'health_records', 'prescriptions',
      'medicines', 'consultations', 'doctor_schedules',
      'chat_sessions', 'notifications', 'doctor_earnings'
    ])
  LOOP
    FOR pol IN
      SELECT policyname FROM pg_policies
      WHERE tablename = tbl AND schemaname = 'public'
    LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, tbl);
    END LOOP;
  END LOOP;
END $$;

-- 3. Disable RLS on all tables temporarily (so nothing blocks)
ALTER TABLE IF EXISTS public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.doctors DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.appointments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.reviews DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.health_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.prescriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.medicines DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.consultations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.doctor_schedules DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chat_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.doctor_earnings DISABLE ROW LEVEL SECURITY;

-- 4. Clean up manually-inserted auth data (these can corrupt GoTrue)
DELETE FROM public.profiles WHERE id IN (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0001',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0002',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003'
);
DELETE FROM auth.identities WHERE user_id IN (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0001',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0002',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003'
);
DELETE FROM auth.users WHERE id IN (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0001',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0002',
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003'
);

-- 5. Grants
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 6. Reload PostgREST
NOTIFY pgrst, 'reload schema';

-- ================================================================
-- FIX: "Database error querying schema"
-- Root cause: admin RLS policy on profiles table is RECURSIVE
-- (it queries profiles to check if you can read profiles)
-- Fix: Use a SECURITY DEFINER function to bypass the recursion
-- Run in Supabase Dashboard → SQL Editor
-- ================================================================

-- 1. Create a helper function that checks admin role WITHOUT triggering RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 2. Drop the recursive admin policies on profiles and recreate them
DROP POLICY IF EXISTS admin_select_profiles ON public.profiles;
DROP POLICY IF EXISTS admin_update_profiles ON public.profiles;
DROP POLICY IF EXISTS admin_delete_profiles ON public.profiles;
DROP POLICY IF EXISTS admin_insert_profiles ON public.profiles;

CREATE POLICY admin_select_profiles ON public.profiles FOR SELECT
  USING (public.is_admin());
CREATE POLICY admin_update_profiles ON public.profiles FOR UPDATE
  USING (public.is_admin());
CREATE POLICY admin_delete_profiles ON public.profiles FOR DELETE
  USING (public.is_admin());
CREATE POLICY admin_insert_profiles ON public.profiles FOR INSERT
  WITH CHECK (public.is_admin());

-- 3. Also fix all other tables to use the function (cleaner + avoids same issue)
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'doctors', 'appointments', 'payments',
      'reviews', 'messages', 'health_records', 'prescriptions',
      'medicines', 'consultations', 'doctor_schedules',
      'chat_sessions', 'notifications', 'doctor_earnings'
    ])
  LOOP
    -- Drop old policies
    EXECUTE format('DROP POLICY IF EXISTS admin_select_%I ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS admin_update_%I ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS admin_delete_%I ON public.%I', tbl, tbl);
    EXECUTE format('DROP POLICY IF EXISTS admin_insert_%I ON public.%I', tbl, tbl);

    -- Recreate with is_admin() function
    EXECUTE format('CREATE POLICY admin_select_%I ON public.%I FOR SELECT USING (public.is_admin())', tbl, tbl);
    EXECUTE format('CREATE POLICY admin_update_%I ON public.%I FOR UPDATE USING (public.is_admin())', tbl, tbl);
    EXECUTE format('CREATE POLICY admin_delete_%I ON public.%I FOR DELETE USING (public.is_admin())', tbl, tbl);
    EXECUTE format('CREATE POLICY admin_insert_%I ON public.%I FOR INSERT WITH CHECK (public.is_admin())', tbl, tbl);
  END LOOP;
END $$;

-- 4. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- 5. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- RLS Policies only (after profiles exist)
-- Run in Supabase SQL Editor

-- Create is_admin function
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

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- Drop existing policies first
DROP POLICY IF EXISTS profiles_select ON public.profiles;
DROP POLICY IF EXISTS profiles_insert ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_delete_admin ON public.profiles;

-- PROFILES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY profiles_insert ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY profiles_update_admin ON public.profiles FOR UPDATE TO authenticated USING (public.is_admin());
CREATE POLICY profiles_delete_admin ON public.profiles FOR DELETE TO authenticated USING (public.is_admin());

-- DOCTORS
DROP POLICY IF EXISTS doctors_select ON public.doctors;
DROP POLICY IF EXISTS doctors_insert ON public.doctors;
DROP POLICY IF EXISTS doctors_update_own ON public.doctors;
DROP POLICY IF EXISTS doctors_update_admin ON public.doctors;
DROP POLICY IF EXISTS doctors_delete_admin ON public.doctors;

ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY doctors_select ON public.doctors FOR SELECT TO authenticated USING (true);
CREATE POLICY doctors_insert ON public.doctors FOR INSERT TO authenticated WITH CHECK (auth.uid() = profile_id);
CREATE POLICY doctors_update_own ON public.doctors FOR UPDATE TO authenticated USING (auth.uid() = profile_id);
CREATE POLICY doctors_update_admin ON public.doctors FOR UPDATE TO authenticated USING (public.is_admin());
CREATE POLICY doctors_delete_admin ON public.doctors FOR DELETE TO authenticated USING (public.is_admin());

-- Basic grants
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
NOTIFY pgrst, 'reload schema';

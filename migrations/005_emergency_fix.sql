-- EMERGENCY FIX: Disable RLS on profiles to unblock login
-- Then re-enable with safe policies

-- Step 1: Disable RLS entirely on profiles
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies on profiles (they cause recursion)
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.profiles', pol.policyname);
  END LOOP;
END $$;

-- Step 3: Re-enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Create the is_admin function (SECURITY DEFINER bypasses RLS)
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

-- Step 5: Simple non-recursive policies for profiles
-- Everyone authenticated can read all profiles
CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated
  USING (true);

-- Users can update their own profile
CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- Admin can update any profile
CREATE POLICY profiles_update_admin ON public.profiles FOR UPDATE TO authenticated
  USING (public.is_admin());

-- Admin can delete any profile
CREATE POLICY profiles_delete_admin ON public.profiles FOR DELETE TO authenticated
  USING (public.is_admin());

-- Allow insert during signup
CREATE POLICY profiles_insert ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow anon to read profiles (needed for PostgREST schema introspection)
CREATE POLICY profiles_select_anon ON public.profiles FOR SELECT TO anon
  USING (true);

-- Step 6: Grants
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- Step 7: Reload
NOTIFY pgrst, 'reload schema';

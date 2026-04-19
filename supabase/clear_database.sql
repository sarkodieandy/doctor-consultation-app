-- ================================================================
-- CLEAR SUPABASE DATABASE
-- ================================================================
-- Run this in Supabase SQL Editor when you want to wipe the app's
-- backend state before rebuilding from scratch.
--
-- What it clears:
--   - public schema tables, views, functions, triggers, policies, types
--   - auth identities and auth users
--
-- What it keeps:
--   - extensions schema
--   - Supabase system schemas
-- ================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Storage cleanup cannot be done through direct SQL deletes in Supabase.
-- Clear storage buckets from the Supabase dashboard or Storage API first
-- if you also want to remove uploaded files.

-- Remove all application auth users.
DELETE FROM auth.identities;
DELETE FROM auth.users;

DO $$
DECLARE
  row_record RECORD;
BEGIN
  FOR row_record IN
    SELECT format('DROP VIEW IF EXISTS public.%I CASCADE;', viewname) AS sql_stmt
    FROM pg_views
    WHERE schemaname = 'public'
  LOOP
    EXECUTE row_record.sql_stmt;
  END LOOP;

  FOR row_record IN
    SELECT format('DROP TABLE IF EXISTS public.%I CASCADE;', tablename) AS sql_stmt
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE row_record.sql_stmt;
  END LOOP;

  FOR row_record IN
    SELECT format(
      'DROP FUNCTION IF EXISTS public.%I(%s) CASCADE;',
      p.proname,
      pg_get_function_identity_arguments(p.oid)
    ) AS sql_stmt
    FROM pg_proc p
    INNER JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
  LOOP
    EXECUTE row_record.sql_stmt;
  END LOOP;

  FOR row_record IN
    SELECT format('DROP TYPE IF EXISTS public.%I CASCADE;', t.typname) AS sql_stmt
    FROM pg_type t
    INNER JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typtype IN ('e', 'c')
  LOOP
    EXECUTE row_record.sql_stmt;
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';

COMMIT;
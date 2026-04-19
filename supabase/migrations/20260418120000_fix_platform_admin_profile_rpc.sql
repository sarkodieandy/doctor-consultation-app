-- ================================================================
-- MIGRATION 021: Platform Admin Profile RPC Fallback
-- ================================================================
-- Purpose:
--   - Work around PostgREST schema cache failures on public.profiles
--   - Expose a stable RPC helper for the currently authenticated user
--   - Force schema cache reload after function creation
-- ================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_current_profile()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT to_jsonb(profile_row)
  FROM (
    SELECT
      p.id,
      p.email,
      p.first_name,
      p.last_name,
      p.phone,
      p.profile_image,
      p.bio,
      p.role,
      p.specialty,
      p.experience,
      p.consultation_fee,
      p.license_document_path,
      p.approval_status,
      p.approval_note,
      p.is_online,
      p.created_at,
      p.updated_at
    FROM public.profiles p
    WHERE p.id = auth.uid()
    LIMIT 1
  ) AS profile_row;
$$;

GRANT EXECUTE ON FUNCTION public.get_current_profile() TO authenticated;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctors TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
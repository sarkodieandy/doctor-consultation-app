-- DIAGNOSTIC: Check what's breaking GoTrue auth
-- Run in Supabase Dashboard → SQL Editor

-- 1. Check for triggers on auth.users (a broken trigger causes this error)
SELECT tgname, tgtype, proname, nspname
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE t.tgrelid = 'auth.users'::regclass
ORDER BY tgname;

-- 2. Check if auth functions exist and are valid
SELECT n.nspname, p.proname, p.prosrc
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname LIKE '%user%' OR p.proname LIKE '%profile%'
ORDER BY p.proname;

-- 3. Check auth.users count
SELECT count(*) as user_count FROM auth.users;

-- 4. Check for duplicate identities
SELECT user_id, provider, count(*)
FROM auth.identities
GROUP BY user_id, provider
HAVING count(*) > 1;

-- 5. Check identities for the admin user
SELECT id, user_id, provider, provider_id, identity_data
FROM auth.identities
WHERE user_id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003';

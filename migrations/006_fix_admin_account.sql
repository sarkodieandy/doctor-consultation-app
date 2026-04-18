-- ================================================================
-- FIX: Recreate admin account properly
-- Run in Supabase Dashboard → SQL Editor
-- Login: admin@test.com / Test1234!
-- ================================================================

-- Enable pgcrypto (needed for crypt/gen_salt)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

DO $$
DECLARE
  admin_uid UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeee0003';
BEGIN
  -- Clean up any partial creation
  DELETE FROM public.profiles WHERE id = admin_uid;
  DELETE FROM auth.identities WHERE user_id = admin_uid;
  DELETE FROM auth.users WHERE id = admin_uid;

  -- Create auth user with proper password hash
  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    created_at, updated_at, confirmation_token,
    recovery_token, email_change_token_new,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    admin_uid,
    'authenticated', 'authenticated',
    'admin@test.com',
    extensions.crypt('Test1234!', extensions.gen_salt('bf')),
    NOW(), NOW(), NOW(), '', '', '',
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "Platform", "last_name": "Admin"}',
    false
  );

  -- Create identity (required for email/password login)
  INSERT INTO auth.identities (
    id, user_id, provider_id, provider,
    identity_data, last_sign_in_at,
    created_at, updated_at
  ) VALUES (
    admin_uid,
    admin_uid,
    'admin@test.com',
    'email',
    jsonb_build_object(
      'sub', admin_uid::text,
      'email', 'admin@test.com',
      'email_verified', true
    ),
    NOW(), NOW(), NOW()
  );

  -- Create admin profile
  INSERT INTO public.profiles (
    id, email, first_name, last_name, phone,
    role, is_online, created_at, updated_at
  ) VALUES (
    admin_uid,
    'admin@test.com',
    'Platform', 'Admin', '+233500000000',
    'admin', true, NOW(), NOW()
  );

  RAISE NOTICE 'Admin account created successfully!';
END $$;

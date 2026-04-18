-- Create admin profile for the API-created user
-- Run in Supabase Dashboard → SQL Editor

INSERT INTO public.profiles (id, email, first_name, last_name, phone, role, is_online, created_at, updated_at)
VALUES (
  '11652651-326b-419b-99ef-2435bdf143b5',
  'admin@test.com',
  'Platform', 'Admin', '+233500000000',
  'admin', true, NOW(), NOW()
) ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- Also recreate patient and doctor accounts via profiles if they exist
-- First check what users exist
SELECT id, email FROM auth.users ORDER BY created_at;

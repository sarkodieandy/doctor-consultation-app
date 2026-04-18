-- Simple: Just create the profiles (no RLS/policies yet)
-- Run in Supabase SQL Editor

INSERT INTO public.profiles (id, email, first_name, last_name, phone, role, is_online, created_at, updated_at)
VALUES 
  ('84ca8104-8336-4fb7-ac6f-ae56286c5794', 'patient@test.com', 'Kwame', 'Mensah', '+233540000001', 'patient', false, NOW(), NOW()),
  ('b15b057b-f949-48bb-b9dd-1e08b543f141', 'doctor@test.com', 'Ama', 'Boateng', '+233540000002', 'doctor', false, NOW(), NOW()),
  ('11652651-326b-419b-99ef-2435bdf143b5', 'admin@test.com', 'Platform', 'Admin', '+233500000000', 'admin', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET 
  role = EXCLUDED.role,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name;

-- Create doctor record
INSERT INTO public.doctors (id, profile_id, name, specialty, experience, consultation_fee, rating, review_count, available, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'b15b057b-f949-48bb-b9dd-1e08b543f141',
  'Dr. Ama Boateng', 'General Practice', '5 years', 150.00,
  4.5, 12, true, NOW(), NOW()
)
ON CONFLICT DO NOTHING;

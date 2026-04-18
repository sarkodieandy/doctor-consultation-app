-- ================================================================
-- SEED: Create profiles + doctor record for test accounts
-- IDs from Supabase Admin API:
--   admin:   11652651-326b-419b-99ef-2435bdf143b5
--   patient: 84ca8104-8336-4fb7-ac6f-ae56286c5794
--   doctor:  b15b057b-f949-48bb-b9dd-1e08b543f141
-- Run in Supabase Dashboard → SQL Editor
-- ================================================================

-- Patient profile
INSERT INTO public.profiles (id, email, first_name, last_name, phone, role, is_online, created_at, updated_at)
VALUES (
  '84ca8104-8336-4fb7-ac6f-ae56286c5794',
  'patient@test.com',
  'Kwame', 'Mensah', '+233540000001',
  'patient', false, NOW(), NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'patient', first_name = 'Kwame', last_name = 'Mensah';

-- Doctor profile
INSERT INTO public.profiles (id, email, first_name, last_name, phone, role,
  specialty, experience, consultation_fee, approval_status,
  is_online, created_at, updated_at)
VALUES (
  'b15b057b-f949-48bb-b9dd-1e08b543f141',
  'doctor@test.com',
  'Ama', 'Boateng', '+233540000002',
  'doctor',
  'General Practice', '5 years', 150.00, 'approved',
  false, NOW(), NOW()
) ON CONFLICT (id) DO UPDATE SET
  role = 'doctor', first_name = 'Ama', last_name = 'Boateng',
  specialty = 'General Practice', experience = '5 years',
  consultation_fee = 150.00, approval_status = 'approved';

-- Admin profile (may already exist from 009)
INSERT INTO public.profiles (id, email, first_name, last_name, phone, role, is_online, created_at, updated_at)
VALUES (
  '11652651-326b-419b-99ef-2435bdf143b5',
  'admin@test.com',
  'Platform', 'Admin', '+233500000000',
  'admin', true, NOW(), NOW()
) ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- Doctor record in doctors table
INSERT INTO public.doctors (id, profile_id, name, specialty, experience, consultation_fee, rating, review_count, available, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'b15b057b-f949-48bb-b9dd-1e08b543f141',
  'Dr. Ama Boateng', 'General Practice', '5 years', 150.00,
  4.5, 12, true, NOW(), NOW()
) ON CONFLICT DO NOTHING;

-- ================================================================
-- RE-ENABLE RLS with SAFE non-recursive policies
-- ================================================================

-- Helper function (SECURITY DEFINER = bypasses RLS)
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

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- ==================
-- PROFILES
-- ==================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY profiles_insert ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY profiles_update_admin ON public.profiles FOR UPDATE TO authenticated USING (public.is_admin());
CREATE POLICY profiles_delete_admin ON public.profiles FOR DELETE TO authenticated USING (public.is_admin());

-- ==================
-- DOCTORS
-- ==================
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY doctors_select ON public.doctors FOR SELECT TO authenticated USING (true);
CREATE POLICY doctors_insert ON public.doctors FOR INSERT TO authenticated WITH CHECK (auth.uid() = profile_id);
CREATE POLICY doctors_update_own ON public.doctors FOR UPDATE TO authenticated USING (auth.uid() = profile_id);
CREATE POLICY doctors_update_admin ON public.doctors FOR UPDATE TO authenticated USING (public.is_admin());
CREATE POLICY doctors_delete_admin ON public.doctors FOR DELETE TO authenticated USING (public.is_admin());

-- ==================
-- APPOINTMENTS
-- ==================
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY appts_select ON public.appointments FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR auth.uid()::text = doctor_id::text OR public.is_admin());
CREATE POLICY appts_insert ON public.appointments FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY appts_update ON public.appointments FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR auth.uid()::text = doctor_id::text OR public.is_admin());
CREATE POLICY appts_delete ON public.appointments FOR DELETE TO authenticated
  USING (public.is_admin());

-- ==================
-- PAYMENTS
-- ==================
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY payments_select ON public.payments FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY payments_insert ON public.payments FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY payments_update ON public.payments FOR UPDATE TO authenticated
  USING (public.is_admin());

-- ==================
-- CONSULTATIONS
-- ==================
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;

CREATE POLICY consult_select ON public.consultations FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR auth.uid()::text = doctor_id::text OR public.is_admin());
CREATE POLICY consult_insert ON public.consultations FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY consult_update ON public.consultations FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR auth.uid()::text = doctor_id::text OR public.is_admin());

-- ==================
-- CHAT_SESSIONS
-- ==================
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY chat_select ON public.chat_sessions FOR SELECT TO authenticated
  USING (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text OR public.is_admin());
CREATE POLICY chat_insert ON public.chat_sessions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text);
CREATE POLICY chat_update ON public.chat_sessions FOR UPDATE TO authenticated
  USING (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text OR public.is_admin());

-- ==================
-- MESSAGES
-- ==================
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY msg_select ON public.messages FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.chat_sessions cs
      WHERE cs.id = chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id::text = auth.uid()::text)
    )
    OR public.is_admin()
  );
CREATE POLICY msg_insert ON public.messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id);
CREATE POLICY msg_update ON public.messages FOR UPDATE TO authenticated
  USING (auth.uid() = sender_id OR public.is_admin());

-- ==================
-- PRESCRIPTIONS
-- ==================
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY rx_select ON public.prescriptions FOR SELECT TO authenticated
  USING (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text OR public.is_admin());
CREATE POLICY rx_insert ON public.prescriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid()::text = doctor_id::text);
CREATE POLICY rx_update ON public.prescriptions FOR UPDATE TO authenticated
  USING (auth.uid()::text = doctor_id::text OR public.is_admin());

-- ==================
-- MEDICINES
-- ==================
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY med_select ON public.medicines FOR SELECT TO authenticated USING (true);
CREATE POLICY med_insert ON public.medicines FOR INSERT TO authenticated WITH CHECK (true);

-- ==================
-- REVIEWS
-- ==================
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY rev_select ON public.reviews FOR SELECT TO authenticated USING (true);
CREATE POLICY rev_insert ON public.reviews FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = patient_id);
CREATE POLICY rev_update ON public.reviews FOR UPDATE TO authenticated
  USING (auth.uid() = patient_id OR public.is_admin());
CREATE POLICY rev_delete ON public.reviews FOR DELETE TO authenticated
  USING (public.is_admin());

-- ==================
-- HEALTH_RECORDS
-- ==================
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY hr_select ON public.health_records FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY hr_insert ON public.health_records FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY hr_update ON public.health_records FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

-- ==================
-- NOTIFICATIONS
-- ==================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notif_select ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());
CREATE POLICY notif_insert ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);
CREATE POLICY notif_update ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

-- ==================
-- DOCTOR_SCHEDULES
-- ==================
ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY sched_select ON public.doctor_schedules FOR SELECT TO authenticated USING (true);
CREATE POLICY sched_insert ON public.doctor_schedules FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = doctor_id);
CREATE POLICY sched_update ON public.doctor_schedules FOR UPDATE TO authenticated
  USING (auth.uid() = doctor_id OR public.is_admin());

-- ==================
-- DOCTOR_EARNINGS
-- ==================
ALTER TABLE public.doctor_earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY earn_select ON public.doctor_earnings FOR SELECT TO authenticated
  USING (auth.uid() = doctor_id OR public.is_admin());
CREATE POLICY earn_insert ON public.doctor_earnings FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());
CREATE POLICY earn_update ON public.doctor_earnings FOR UPDATE TO authenticated
  USING (public.is_admin());

-- ==================
-- GRANTS + RELOAD
-- ==================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
NOTIFY pgrst, 'reload schema';

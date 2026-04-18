-- ================================================================
-- Doctor Consultation App – COMPLETE DATABASE
-- ================================================================
-- Run this ENTIRE file in Supabase Dashboard → SQL Editor → New Query
-- ================================================================

-- =====================
-- 1. PROFILES TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.profiles (
  id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                 TEXT NOT NULL,
  first_name            TEXT NOT NULL DEFAULT '',
  last_name             TEXT NOT NULL DEFAULT '',
  phone                 TEXT NOT NULL DEFAULT '',
  profile_image         TEXT DEFAULT '',
  bio                   TEXT DEFAULT '',
  role                  TEXT NOT NULL DEFAULT 'patient',
  specialty             TEXT,
  experience            TEXT,
  consultation_fee      DOUBLE PRECISION,
  license_document_path TEXT,
  approval_status       TEXT,
  approval_note         TEXT,
  is_online             BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);
  

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Anyone can read doctor profiles"
  ON public.profiles FOR SELECT
  USING (role = 'doctor' AND approval_status = 'approved');

CREATE POLICY "Service role full access"
  ON public.profiles FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 2. DOCTORS TABLE (public listing / search)
-- =====================
CREATE TABLE IF NOT EXISTS public.doctors (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id        UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  name              TEXT NOT NULL,
  specialty         TEXT NOT NULL,
  description       TEXT DEFAULT '',
  image_url         TEXT DEFAULT '',
  rating            DOUBLE PRECISION DEFAULT 4.5,
  review_count      INTEGER DEFAULT 0,
  consultation_fee  DOUBLE PRECISION DEFAULT 0,
  experience        TEXT DEFAULT '',
  hospital          TEXT DEFAULT '',
  available         BOOLEAN DEFAULT TRUE,
  available_times   TEXT[] DEFAULT '{}',
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read doctors"
  ON public.doctors FOR SELECT
  USING (true);

CREATE POLICY "Doctors can update own listing"
  ON public.doctors FOR UPDATE
  USING (profile_id = auth.uid());

CREATE POLICY "Doctors can insert own listing"
  ON public.doctors FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Service role full access doctors"
  ON public.doctors FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 3. APPOINTMENTS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.appointments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_id         UUID NOT NULL,
  doctor_name       TEXT NOT NULL DEFAULT '',
  doctor_image      TEXT DEFAULT '',
  speciality        TEXT DEFAULT '',
  appointment_date  TIMESTAMPTZ NOT NULL,
  time_slot         TEXT NOT NULL,
  consultation_fee  DOUBLE PRECISION DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'pending',
  notes             TEXT,
  rating            DOUBLE PRECISION,
  review            TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Doctors can read their appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid()::text = doctor_id::text);

CREATE POLICY "Service role full access appointments"
  ON public.appointments FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 4. PAYMENTS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id    UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor_id         UUID NOT NULL,
  user_id           UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount            DOUBLE PRECISION NOT NULL DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'pending',
  payment_method    TEXT NOT NULL DEFAULT 'paystack',
  transaction_id    TEXT UNIQUE,
  receipt_id        TEXT,
  failure_reason    TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  completed_at      TIMESTAMPTZ
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments"
  ON public.payments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own payments"
  ON public.payments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access payments"
  ON public.payments FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 5. CONSULTATIONS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.consultations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id      UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor_id           UUID NOT NULL,
  doctor_name         TEXT NOT NULL DEFAULT '',
  doctor_avatar       TEXT DEFAULT '',
  user_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  scheduled_time      TIMESTAMPTZ NOT NULL,
  duration_minutes    INTEGER NOT NULL DEFAULT 30,
  status              TEXT NOT NULL DEFAULT 'scheduled',
  consultation_type   TEXT NOT NULL DEFAULT 'video',
  room_id             TEXT,
  recording_url       TEXT,
  summary             TEXT,
  started_at          TIMESTAMPTZ,
  ended_at            TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own consultations"
  ON public.consultations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Doctors can read their consultations"
  ON public.consultations FOR SELECT
  USING (auth.uid()::text = doctor_id::text);

CREATE POLICY "Users can insert own consultations"
  ON public.consultations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own consultations"
  ON public.consultations FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid()::text = doctor_id::text);

CREATE POLICY "Service role full access consultations"
  ON public.consultations FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 6. CHAT_SESSIONS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id         UUID NOT NULL,
  doctor_name       TEXT NOT NULL DEFAULT '',
  doctor_avatar     TEXT DEFAULT '',
  patient_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message      TEXT,
  last_message_time TIMESTAMPTZ DEFAULT NOW(),
  unread_count      INTEGER DEFAULT 0,
  is_active         BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own chats"
  ON public.chat_sessions FOR SELECT
  USING (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text);

CREATE POLICY "Users can insert chats"
  ON public.chat_sessions FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Users can update own chats"
  ON public.chat_sessions FOR UPDATE
  USING (auth.uid() = patient_id OR auth.uid()::text = doctor_id::text);

CREATE POLICY "Service role full access chats"
  ON public.chat_sessions FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 7. MESSAGES TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id         UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_name     TEXT NOT NULL DEFAULT '',
  sender_avatar   TEXT DEFAULT '',
  message         TEXT NOT NULL,
  is_doctor       BOOLEAN DEFAULT FALSE,
  is_read         BOOLEAN DEFAULT FALSE,
  timestamp       TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chat members can read messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.chat_sessions cs
      WHERE cs.id = chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id::text = auth.uid()::text)
    )
  );

CREATE POLICY "Chat members can insert messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages"
  ON public.messages FOR UPDATE
  USING (auth.uid() = sender_id);

CREATE POLICY "Service role full access messages"
  ON public.messages FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 8. PRESCRIPTIONS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id       UUID NOT NULL,
  doctor_name     TEXT NOT NULL DEFAULT '',
  appointment_id  UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  patient_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  prescribed_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date     TIMESTAMPTZ,
  notes           TEXT DEFAULT '',
  status          TEXT NOT NULL DEFAULT 'active',
  attachment_url  TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can read own prescriptions"
  ON public.prescriptions FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Doctors can manage prescriptions"
  ON public.prescriptions FOR ALL
  USING (auth.uid()::text = doctor_id::text);

CREATE POLICY "Service role full access prescriptions"
  ON public.prescriptions FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 9. MEDICINES TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.medicines (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  dosage          TEXT NOT NULL DEFAULT '',
  frequency       TEXT NOT NULL DEFAULT '',
  duration        INTEGER NOT NULL DEFAULT 0,
  instructions    TEXT DEFAULT '',
  side_effects    TEXT[] DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read medicines via prescription"
  ON public.medicines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.prescriptions p
      WHERE p.id = prescription_id
      AND (p.patient_id = auth.uid() OR p.doctor_id::text = auth.uid()::text)
    )
  );

CREATE POLICY "Doctors can manage medicines"
  ON public.medicines FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.prescriptions p
      WHERE p.id = prescription_id
      AND p.doctor_id::text = auth.uid()::text
    )
  );

CREATE POLICY "Service role full access medicines"
  ON public.medicines FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 10. REVIEWS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.reviews (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id          UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor_id               UUID NOT NULL,
  doctor_name             TEXT NOT NULL DEFAULT '',
  doctor_avatar           TEXT DEFAULT '',
  patient_id              UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  patient_name            TEXT NOT NULL DEFAULT '',
  patient_avatar          TEXT DEFAULT '',
  rating                  DOUBLE PRECISION NOT NULL DEFAULT 5,
  title                   TEXT DEFAULT '',
  review_text             TEXT DEFAULT '',
  tags                    TEXT[] DEFAULT '{}',
  helpful_count           INTEGER DEFAULT 0,
  is_verified_appointment BOOLEAN DEFAULT FALSE,
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read reviews"
  ON public.reviews FOR SELECT
  USING (true);

CREATE POLICY "Patients can insert own reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own reviews"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can delete own reviews"
  ON public.reviews FOR DELETE
  USING (auth.uid() = patient_id);

CREATE POLICY "Service role full access reviews"
  ON public.reviews FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 11. HEALTH_RECORDS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.health_records (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          TEXT NOT NULL DEFAULT 'vital',
  title         TEXT NOT NULL,
  value         TEXT NOT NULL DEFAULT '',
  unit          TEXT DEFAULT '',
  normal_range  TEXT,
  status        TEXT DEFAULT 'normal',
  record_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  document_url  TEXT,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own health records"
  ON public.health_records FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health records"
  ON public.health_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health records"
  ON public.health_records FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health records"
  ON public.health_records FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Doctors can read patient health records"
  ON public.health_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.appointments a
      WHERE a.user_id = health_records.user_id
      AND a.doctor_id::text = auth.uid()::text
      AND a.status IN ('confirmed', 'completed')
    )
  );

CREATE POLICY "Service role full access health records"
  ON public.health_records FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 12. NOTIFICATIONS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'appointment',
  related_id  TEXT,
  is_read     BOOLEAN DEFAULT FALSE,
  read_at     TIMESTAMPTZ,
  metadata    JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access notifications"
  ON public.notifications FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 13. DOCTOR_SCHEDULES TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.doctor_schedules (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id               UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date                    DATE NOT NULL,
  available_times         TEXT[] DEFAULT '{}',
  max_appointments        INTEGER DEFAULT 10,
  break_time              TEXT,
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doctor_id, date)
);

ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read schedules"
  ON public.doctor_schedules FOR SELECT
  USING (true);

CREATE POLICY "Doctors can manage own schedules"
  ON public.doctor_schedules FOR ALL
  USING (auth.uid() = doctor_id);

CREATE POLICY "Service role full access schedules"
  ON public.doctor_schedules FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 14. DOCTOR_EARNINGS TABLE
-- =====================
CREATE TABLE IF NOT EXISTS public.doctor_earnings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id             UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  payment_id            UUID REFERENCES public.payments(id) ON DELETE SET NULL,
  amount                DOUBLE PRECISION NOT NULL DEFAULT 0,
  commission_percentage DOUBLE PRECISION DEFAULT 10,
  net_earnings          DOUBLE PRECISION NOT NULL DEFAULT 0,
  period                DATE NOT NULL,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.doctor_earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doctors can read own earnings"
  ON public.doctor_earnings FOR SELECT
  USING (auth.uid() = doctor_id);

CREATE POLICY "Service role full access earnings"
  ON public.doctor_earnings FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');


-- =====================
-- 15. INDEXES FOR PERFORMANCE
-- =====================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_approval ON public.profiles(approval_status);
CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON public.doctors(specialty);
CREATE INDEX IF NOT EXISTS idx_doctors_available ON public.doctors(available);
CREATE INDEX IF NOT EXISTS idx_appointments_user ON public.appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor ON public.appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments(status);
CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_appointment ON public.payments(appointment_id);
CREATE INDEX IF NOT EXISTS idx_consultations_user ON public.consultations(user_id);
CREATE INDEX IF NOT EXISTS idx_consultations_doctor ON public.consultations(doctor_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_patient ON public.chat_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_doctor ON public.chat_sessions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON public.messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON public.prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_reviews_doctor ON public.reviews(doctor_id);
CREATE INDEX IF NOT EXISTS idx_health_records_user ON public.health_records(user_id);
CREATE INDEX IF NOT EXISTS idx_health_records_type ON public.health_records(type);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_doctor_schedules_doctor ON public.doctor_schedules(doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_schedules_date ON public.doctor_schedules(date);
CREATE INDEX IF NOT EXISTS idx_doctor_earnings_doctor ON public.doctor_earnings(doctor_id);


-- =====================
-- 16. AUTO-UPDATE TIMESTAMPS TRIGGER
-- =====================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER doctors_updated_at BEFORE UPDATE ON public.doctors
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER appointments_updated_at BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER consultations_updated_at BEFORE UPDATE ON public.consultations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER chat_sessions_updated_at BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER prescriptions_updated_at BEFORE UPDATE ON public.prescriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER health_records_updated_at BEFORE UPDATE ON public.health_records
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER reviews_updated_at BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER doctor_schedules_updated_at BEFORE UPDATE ON public.doctor_schedules
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- =====================
-- 17. SEED DEFAULT DOCTORS (matching app mock data)
-- =====================
INSERT INTO public.doctors (id, name, specialty, description, image_url, rating, review_count, consultation_fee, experience, hospital, available, available_times)
VALUES
  (gen_random_uuid(), 'Dr. Stella Kane', 'Heart Surgeon', 'Experienced heart surgeon with 12 years of practice', 'assets/images/doctor1.png', 4.8, 150, 50.0, '12 years', 'Flower Hospitals', true, ARRAY['09:00 AM','10:00 AM','11:00 AM','02:00 PM','03:00 PM']),
  (gen_random_uuid(), 'Dr. Joseph Cart', 'Dental Surgeon', 'Expert in dental surgery and oral care', 'assets/images/doctor2.png', 4.6, 89, 40.0, '8 years', 'Flower Hospitals', true, ARRAY['08:00 AM','09:30 AM','01:00 PM','02:30 PM','04:00 PM']),
  (gen_random_uuid(), 'Dr. Stephanie', 'Eye Specialist', 'Specialized in eye care and vision correction', 'assets/images/doctor3.png', 4.7, 120, 45.0, '10 years', 'Flower Hospitals', true, ARRAY['10:00 AM','11:30 AM','01:00 PM','03:00 PM','04:30 PM'])
ON CONFLICT DO NOTHING;


-- =====================
-- DONE! All 14 tables created with RLS, indexes, triggers, and seed data.

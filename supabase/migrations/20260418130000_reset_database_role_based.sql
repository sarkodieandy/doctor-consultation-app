-- ================================================================
-- MIGRATION 022: Reset Database With Role-Based Access
-- ================================================================
-- Purpose:
--   - Drop the existing public app schema and rebuild it cleanly
--   - Use one consistent role-based model: patient, doctor, admin
--   - Recreate only the tables and columns the current app actually uses
--
-- WARNING:
--   - This migration deletes all existing application data in public schema
--   - Run this only when you intentionally want a full reset
-- ================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

DROP VIEW IF EXISTS public.doctor_commissions CASCADE;

DROP TABLE IF EXISTS public.paystack_transactions CASCADE;
DROP TABLE IF EXISTS public.payouts CASCADE;
DROP TABLE IF EXISTS public.doctor_earnings CASCADE;
DROP TABLE IF EXISTS public.commission_tiers CASCADE;
DROP TABLE IF EXISTS public.commission_settings CASCADE;
DROP TABLE IF EXISTS public.admin_settings CASCADE;
DROP TABLE IF EXISTS public.doctor_verifications CASCADE;
DROP TABLE IF EXISTS public.doctor_schedules CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.health_records CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.medicines CASCADE;
DROP TABLE IF EXISTS public.prescriptions CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.chat_sessions CASCADE;
DROP TABLE IF EXISTS public.consultations CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.appointments CASCADE;
DROP TABLE IF EXISTS public.doctors CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP FUNCTION IF EXISTS public.touch_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.has_role(public.app_role) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.sync_doctor_directory_from_profile() CASCADE;
DROP FUNCTION IF EXISTS public.sync_notification_read_flags() CASCADE;
DROP FUNCTION IF EXISTS public.get_current_profile() CASCADE;

DROP TYPE IF EXISTS public.notification_type CASCADE;
DROP TYPE IF EXISTS public.health_record_status CASCADE;
DROP TYPE IF EXISTS public.health_record_type CASCADE;
DROP TYPE IF EXISTS public.consultation_type CASCADE;
DROP TYPE IF EXISTS public.consultation_status CASCADE;
DROP TYPE IF EXISTS public.payment_method CASCADE;
DROP TYPE IF EXISTS public.payment_status CASCADE;
DROP TYPE IF EXISTS public.appointment_status CASCADE;
DROP TYPE IF EXISTS public.doctor_approval_status CASCADE;
DROP TYPE IF EXISTS public.app_role CASCADE;

CREATE TYPE public.app_role AS ENUM ('patient', 'doctor', 'admin');
CREATE TYPE public.doctor_approval_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.appointment_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
CREATE TYPE public.payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE public.payment_method AS ENUM ('paystack', 'mobile_money', 'credit_card');
CREATE TYPE public.consultation_status AS ENUM ('scheduled', 'ongoing', 'completed', 'cancelled');
CREATE TYPE public.consultation_type AS ENUM ('video', 'audio', 'text');
CREATE TYPE public.health_record_type AS ENUM ('vital', 'lab', 'document', 'allergy');
CREATE TYPE public.health_record_status AS ENUM ('normal', 'high', 'low');
CREATE TYPE public.notification_type AS ENUM (
  'appointment',
  'payment',
  'reminder',
  'review',
  'registration_approved',
  'registration_rejected',
  'doctor_verification_review'
);

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.has_role(required_role public.app_role)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = required_role
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT public.has_role('admin'::public.app_role);
$$;

CREATE OR REPLACE FUNCTION public.get_current_profile()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT to_jsonb(p)
  FROM public.profiles p
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.sync_notification_read_flags()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.is_read = COALESCE(NEW.is_read, NEW.read, FALSE);
  NEW.read = NEW.is_read;

  IF NEW.is_read = TRUE AND NEW.read_at IS NULL THEN
    NEW.read_at = NOW();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  profile_image TEXT NOT NULL DEFAULT '',
  bio TEXT NOT NULL DEFAULT '',
  role public.app_role NOT NULL DEFAULT 'patient',
  specialty TEXT,
  experience TEXT,
  consultation_fee NUMERIC(10, 2),
  license_document_path TEXT,
  approval_status public.doctor_approval_status,
  approval_note TEXT,
  approved_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  verification_method TEXT,
  is_online BOOLEAN NOT NULL DEFAULT FALSE,
  mobile_money_provider TEXT,
  mobile_money_number TEXT,
  paystack_recipient_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    (role = 'doctor' AND approval_status IS NOT NULL)
    OR (role <> 'doctor')
  )
);

CREATE TABLE public.doctors (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  specialty TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  rating NUMERIC(3, 2) NOT NULL DEFAULT 4.5,
  review_count INTEGER NOT NULL DEFAULT 0,
  consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  experience TEXT NOT NULL DEFAULT '',
  hospital TEXT NOT NULL DEFAULT '',
  available BOOLEAN NOT NULL DEFAULT TRUE,
  available_times TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (id = profile_id)
);

CREATE TABLE public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_name TEXT NOT NULL DEFAULT '',
  doctor_image TEXT NOT NULL DEFAULT '',
  speciality TEXT NOT NULL DEFAULT '',
  appointment_date TIMESTAMPTZ NOT NULL,
  time_slot TEXT NOT NULL,
  consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status public.appointment_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  rating NUMERIC(2, 1),
  review TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status public.payment_status NOT NULL DEFAULT 'pending',
  payment_method public.payment_method NOT NULL DEFAULT 'paystack',
  transaction_id TEXT UNIQUE,
  paystack_reference TEXT UNIQUE,
  receipt_id TEXT,
  failure_reason TEXT,
  commission_id UUID,
  commission_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  commission_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0,
  doctor_earnings NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE public.consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_name TEXT NOT NULL DEFAULT '',
  doctor_avatar TEXT NOT NULL DEFAULT '',
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  scheduled_time TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 30,
  status public.consultation_status NOT NULL DEFAULT 'scheduled',
  consultation_type public.consultation_type NOT NULL DEFAULT 'video',
  room_id TEXT,
  recording_url TEXT,
  summary TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_name TEXT NOT NULL DEFAULT '',
  doctor_avatar TEXT NOT NULL DEFAULT '',
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unread_count INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (doctor_id, patient_id)
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL DEFAULT '',
  sender_avatar TEXT NOT NULL DEFAULT '',
  message TEXT NOT NULL,
  is_doctor BOOLEAN NOT NULL DEFAULT FALSE,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  patient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  doctor_name TEXT NOT NULL DEFAULT '',
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  prescribed_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date TIMESTAMPTZ,
  notes TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active',
  attachment_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.medicines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL DEFAULT '',
  frequency TEXT NOT NULL DEFAULT '',
  duration INTEGER NOT NULL DEFAULT 0,
  instructions TEXT NOT NULL DEFAULT '',
  side_effects TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID UNIQUE REFERENCES public.appointments(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doctor_name TEXT NOT NULL DEFAULT '',
  doctor_avatar TEXT NOT NULL DEFAULT '',
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL DEFAULT '',
  patient_avatar TEXT NOT NULL DEFAULT '',
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title TEXT NOT NULL DEFAULT '',
  review_text TEXT NOT NULL DEFAULT '',
  tags TEXT[] NOT NULL DEFAULT '{}',
  helpful_count INTEGER NOT NULL DEFAULT 0,
  is_verified_appointment BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.health_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type public.health_record_type NOT NULL,
  title TEXT NOT NULL,
  value TEXT NOT NULL DEFAULT '',
  unit TEXT,
  normal_range TEXT,
  status public.health_record_status,
  record_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  document_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type public.notification_type NOT NULL,
  related_id TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  metadata JSONB,
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.doctor_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  schedule_date DATE NOT NULL,
  available_times TEXT[] NOT NULL DEFAULT '{}',
  max_appointments_per_day INTEGER NOT NULL DEFAULT 12,
  break_start TIME,
  break_end TIME,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (doctor_id, schedule_date)
);

CREATE TABLE public.doctor_verifications (
  doctor_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  license_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ghana_card_verified BOOLEAN NOT NULL DEFAULT FALSE,
  overall_status TEXT NOT NULL DEFAULT 'pending',
  confidence_score NUMERIC(5, 4) NOT NULL DEFAULT 0,
  verification_notes TEXT NOT NULL DEFAULT '',
  license_number TEXT,
  ghana_card_number TEXT,
  verification_method TEXT,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.admin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.commission_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  commission_type TEXT NOT NULL DEFAULT 'percentage',
  commission_rate NUMERIC(10, 2) NOT NULL DEFAULT 10.0,
  min_commission NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
  max_commission NUMERIC(10, 2),
  applies_to_all BOOLEAN NOT NULL DEFAULT TRUE,
  doctor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  specialty TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  description TEXT,
  created_by_admin UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  effective_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.commission_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  min_consultations INTEGER NOT NULL DEFAULT 0,
  rate NUMERIC(10, 2) NOT NULL,
  bonus NUMERIC(10, 2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.payments
  ADD CONSTRAINT payments_commission_id_fk
  FOREIGN KEY (commission_id) REFERENCES public.commission_settings(id) ON DELETE SET NULL;

CREATE TABLE public.doctor_earnings (
  doctor_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_consultations INTEGER NOT NULL DEFAULT 0,
  total_revenue NUMERIC(12, 2) NOT NULL DEFAULT 0,
  total_commissions_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
  total_earnings NUMERIC(12, 2) NOT NULL DEFAULT 0,
  month_consultations INTEGER NOT NULL DEFAULT 0,
  month_revenue NUMERIC(12, 2) NOT NULL DEFAULT 0,
  month_commissions_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
  month_earnings NUMERIC(12, 2) NOT NULL DEFAULT 0,
  month_year TEXT,
  average_consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  average_commission_rate NUMERIC(10, 2) NOT NULL DEFAULT 0,
  last_payment_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  commission_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  paystack_transfer_code TEXT,
  paystack_reference TEXT,
  mobile_money_provider TEXT,
  mobile_money_number TEXT,
  failure_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.paystack_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference TEXT NOT NULL UNIQUE,
  type TEXT,
  amount NUMERIC(10, 2),
  status TEXT,
  payment_id UUID REFERENCES public.payments(id) ON DELETE SET NULL,
  payout_id UUID REFERENCES public.payouts(id) ON DELETE SET NULL,
  metadata JSONB,
  response JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.sync_doctor_directory_from_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    DELETE FROM public.doctors WHERE profile_id = OLD.id;
    RETURN OLD;
  END IF;

  IF NEW.role = 'doctor' AND NEW.approval_status = 'approved' THEN
    INSERT INTO public.doctors (
      id,
      profile_id,
      name,
      specialty,
      description,
      image_url,
      consultation_fee,
      experience,
      hospital,
      available,
      available_times
    ) VALUES (
      NEW.id,
      NEW.id,
      TRIM(CONCAT(NEW.first_name, ' ', NEW.last_name)),
      COALESCE(NEW.specialty, 'General Practice'),
      COALESCE(NEW.bio, ''),
      COALESCE(NULLIF(NEW.profile_image, ''), 'assets/images/doctor1.png'),
      COALESCE(NEW.consultation_fee, 0),
      COALESCE(NEW.experience, ''),
      'DocConsult Hospital',
      COALESCE(NEW.is_online, FALSE),
      ARRAY['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM']
    )
    ON CONFLICT (profile_id) DO UPDATE SET
      name = EXCLUDED.name,
      specialty = EXCLUDED.specialty,
      description = EXCLUDED.description,
      image_url = EXCLUDED.image_url,
      consultation_fee = EXCLUDED.consultation_fee,
      experience = EXCLUDED.experience,
      available = EXCLUDED.available,
      updated_at = NOW();
  ELSE
    DELETE FROM public.doctors WHERE profile_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_touch_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER doctors_touch_updated_at
BEFORE UPDATE ON public.doctors
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER appointments_touch_updated_at
BEFORE UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER consultations_touch_updated_at
BEFORE UPDATE ON public.consultations
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER chat_sessions_touch_updated_at
BEFORE UPDATE ON public.chat_sessions
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER prescriptions_touch_updated_at
BEFORE UPDATE ON public.prescriptions
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER reviews_touch_updated_at
BEFORE UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER health_records_touch_updated_at
BEFORE UPDATE ON public.health_records
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER doctor_schedules_touch_updated_at
BEFORE UPDATE ON public.doctor_schedules
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER doctor_verifications_touch_updated_at
BEFORE UPDATE ON public.doctor_verifications
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER admin_settings_touch_updated_at
BEFORE UPDATE ON public.admin_settings
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER commission_settings_touch_updated_at
BEFORE UPDATE ON public.commission_settings
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER commission_tiers_touch_updated_at
BEFORE UPDATE ON public.commission_tiers
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER doctor_earnings_touch_updated_at
BEFORE UPDATE ON public.doctor_earnings
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER payouts_touch_updated_at
BEFORE UPDATE ON public.payouts
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER paystack_transactions_touch_updated_at
BEFORE UPDATE ON public.paystack_transactions
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE TRIGGER notifications_sync_read_flags
BEFORE INSERT OR UPDATE ON public.notifications
FOR EACH ROW EXECUTE FUNCTION public.sync_notification_read_flags();

CREATE TRIGGER profiles_sync_doctors_after_insert
AFTER INSERT ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_doctor_directory_from_profile();

CREATE TRIGGER profiles_sync_doctors_after_update
AFTER UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_doctor_directory_from_profile();

CREATE TRIGGER profiles_sync_doctors_after_delete
AFTER DELETE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_doctor_directory_from_profile();

CREATE INDEX profiles_role_approval_idx ON public.profiles (role, approval_status);
CREATE INDEX appointments_user_idx ON public.appointments (user_id, appointment_date DESC);
CREATE INDEX appointments_doctor_idx ON public.appointments (doctor_id, appointment_date DESC);
CREATE INDEX payments_user_idx ON public.payments (user_id, created_at DESC);
CREATE INDEX payments_doctor_idx ON public.payments (doctor_id, created_at DESC);
CREATE INDEX consultations_user_idx ON public.consultations (user_id, scheduled_time DESC);
CREATE INDEX consultations_doctor_idx ON public.consultations (doctor_id, scheduled_time DESC);
CREATE INDEX chat_sessions_patient_idx ON public.chat_sessions (patient_id, last_message_time DESC);
CREATE INDEX chat_sessions_doctor_idx ON public.chat_sessions (doctor_id, last_message_time DESC);
CREATE INDEX messages_chat_idx ON public.messages (chat_id, timestamp ASC);
CREATE INDEX notifications_user_idx ON public.notifications (user_id, created_at DESC);
CREATE INDEX doctor_verifications_status_idx ON public.doctor_verifications (overall_status, verified_at DESC);
CREATE INDEX commission_settings_active_idx ON public.commission_settings (is_active, effective_date DESC);
CREATE INDEX payouts_doctor_idx ON public.payouts (doctor_id, created_at DESC);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paystack_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_own_admin_or_public_doctors ON public.profiles
FOR SELECT TO authenticated
USING (
  auth.uid() = id
  OR public.is_admin()
  OR (role = 'doctor' AND approval_status = 'approved')
);

CREATE POLICY profiles_public_doctor_directory ON public.profiles
FOR SELECT TO anon
USING (role = 'doctor' AND approval_status = 'approved');

CREATE POLICY profiles_insert_self_or_admin ON public.profiles
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_update_self_or_admin ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_delete_admin ON public.profiles
FOR DELETE TO authenticated
USING (public.is_admin());

CREATE POLICY doctors_select_all ON public.doctors
FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY doctors_manage_self_or_admin ON public.doctors
FOR ALL TO authenticated
USING (auth.uid() = profile_id OR public.is_admin())
WITH CHECK (auth.uid() = profile_id OR public.is_admin());

CREATE POLICY appointments_select_participants ON public.appointments
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY appointments_insert_patient_or_admin ON public.appointments
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY appointments_update_participants ON public.appointments
FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY payments_select_participants ON public.payments
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY payments_insert_user_or_admin ON public.payments
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY payments_update_participants ON public.payments
FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY consultations_select_participants ON public.consultations
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY consultations_insert_user_doctor_or_admin ON public.consultations
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY consultations_update_participants ON public.consultations
FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY chat_sessions_select_participants ON public.chat_sessions
FOR SELECT TO authenticated
USING (auth.uid() = patient_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY chat_sessions_insert_participants ON public.chat_sessions
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = patient_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY chat_sessions_update_participants ON public.chat_sessions
FOR UPDATE TO authenticated
USING (auth.uid() = patient_id OR auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = patient_id OR auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY messages_select_chat_participants ON public.messages
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.chat_sessions cs
    WHERE cs.id = messages.chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id = auth.uid() OR public.is_admin())
  )
);

CREATE POLICY messages_insert_chat_participants ON public.messages
FOR INSERT TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.chat_sessions cs
    WHERE cs.id = messages.chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id = auth.uid() OR public.is_admin())
  )
);

CREATE POLICY messages_update_chat_participants ON public.messages
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.chat_sessions cs
    WHERE cs.id = messages.chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id = auth.uid() OR public.is_admin())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.chat_sessions cs
    WHERE cs.id = messages.chat_id
      AND (cs.patient_id = auth.uid() OR cs.doctor_id = auth.uid() OR public.is_admin())
  )
);

CREATE POLICY prescriptions_select_participants ON public.prescriptions
FOR SELECT TO authenticated
USING (auth.uid() = doctor_id OR auth.uid() = patient_id OR public.is_admin());

CREATE POLICY prescriptions_insert_doctor_or_admin ON public.prescriptions
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY prescriptions_update_doctor_or_admin ON public.prescriptions
FOR UPDATE TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY medicines_access_via_prescription ON public.medicines
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.prescriptions p
    WHERE p.id = medicines.prescription_id
      AND (p.doctor_id = auth.uid() OR p.patient_id = auth.uid() OR public.is_admin())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.prescriptions p
    WHERE p.id = medicines.prescription_id
      AND (p.doctor_id = auth.uid() OR p.patient_id = auth.uid() OR public.is_admin())
  )
);

CREATE POLICY reviews_select_all ON public.reviews
FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY reviews_insert_patient_or_admin ON public.reviews
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = patient_id OR public.is_admin());

CREATE POLICY reviews_update_patient_or_admin ON public.reviews
FOR UPDATE TO authenticated
USING (auth.uid() = patient_id OR public.is_admin())
WITH CHECK (auth.uid() = patient_id OR public.is_admin());

CREATE POLICY health_records_select_owner_or_admin ON public.health_records
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY health_records_insert_owner_or_admin ON public.health_records
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY health_records_update_owner_or_admin ON public.health_records
FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY notifications_select_owner_or_admin ON public.notifications
FOR SELECT TO authenticated
USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY notifications_insert_authenticated ON public.notifications
FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY notifications_update_owner_or_admin ON public.notifications
FOR UPDATE TO authenticated
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY doctor_schedules_select_all ON public.doctor_schedules
FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY doctor_schedules_manage_owner_or_admin ON public.doctor_schedules
FOR ALL TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY doctor_verifications_select_owner_or_admin ON public.doctor_verifications
FOR SELECT TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY doctor_verifications_insert_owner_or_admin ON public.doctor_verifications
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY doctor_verifications_update_owner_or_admin ON public.doctor_verifications
FOR UPDATE TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin())
WITH CHECK (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY admin_settings_admin_only ON public.admin_settings
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY commission_settings_select_active_or_admin ON public.commission_settings
FOR SELECT TO authenticated
USING (is_active = TRUE OR public.is_admin());

CREATE POLICY commission_settings_admin_manage ON public.commission_settings
FOR INSERT TO authenticated
WITH CHECK (public.is_admin());

CREATE POLICY commission_settings_admin_update ON public.commission_settings
FOR UPDATE TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY commission_settings_admin_delete ON public.commission_settings
FOR DELETE TO authenticated
USING (public.is_admin());

CREATE POLICY commission_tiers_select_admin ON public.commission_tiers
FOR SELECT TO authenticated
USING (public.is_admin());

CREATE POLICY commission_tiers_admin_manage ON public.commission_tiers
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY doctor_earnings_select_owner_or_admin ON public.doctor_earnings
FOR SELECT TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY doctor_earnings_admin_manage ON public.doctor_earnings
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY payouts_select_owner_or_admin ON public.payouts
FOR SELECT TO authenticated
USING (auth.uid() = doctor_id OR public.is_admin());

CREATE POLICY payouts_admin_manage ON public.payouts
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY paystack_transactions_admin_only ON public.paystack_transactions
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.doctors TO anon;
GRANT SELECT ON public.profiles TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_role(public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_profile() TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
-- Doctor Verifications Table
-- Stores OCR verification results and approval status

CREATE TABLE IF NOT EXISTS public.doctor_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Verification Results
  license_verified BOOLEAN DEFAULT FALSE,
  ghana_card_verified BOOLEAN DEFAULT FALSE,
  overall_status VARCHAR(50) DEFAULT 'pending', -- 'approved', 'rejected', 'manual_review', 'pending'
  confidence_score DECIMAL(5, 2) DEFAULT 0.0,
  
  -- Extracted Document Data
  license_number VARCHAR(100),
  license_expiry_date DATE,
  ghana_card_number VARCHAR(50),
  date_of_birth DATE,
  
  -- Metadata
  verification_notes TEXT,
  verification_method VARCHAR(50), -- 'automated_ocr', 'manual', 'third_party'
  verified_by_admin UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  -- Timestamps
  verified_at TIMESTAMP WITH TIME ZONE,
  manual_review_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Indexes
  CONSTRAINT valid_status CHECK (overall_status IN ('approved', 'rejected', 'manual_review', 'pending'))
);

-- Enable RLS
ALTER TABLE public.doctor_verifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Doctors can view their own verification status
CREATE POLICY "Doctors can view own verification" ON public.doctor_verifications
  FOR SELECT USING (auth.uid() = doctor_id);

-- Admins can view all verifications
CREATE POLICY "Admins can view all verifications" ON public.doctor_verifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update verifications (manual approval)
CREATE POLICY "Admins can update verifications" ON public.doctor_verifications
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Service role can insert verifications (automated verification)
CREATE POLICY "Service role can insert verifications" ON public.doctor_verifications
  FOR INSERT WITH CHECK (true);

-- Create indexes for faster queries
CREATE INDEX idx_doctor_verifications_status ON public.doctor_verifications(overall_status);
CREATE INDEX idx_doctor_verifications_doctor_id ON public.doctor_verifications(doctor_id);
CREATE INDEX idx_doctor_verifications_verified_at ON public.doctor_verifications(verified_at);
CREATE INDEX idx_doctor_verifications_confidence ON public.doctor_verifications(confidence_score DESC);

-- Add trigger to update verification status in profiles table
CREATE OR REPLACE FUNCTION update_doctor_approval_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.overall_status = 'approved' THEN
    UPDATE public.profiles
    SET approval_status = 'approved',
        approval_note = COALESCE(approval_note, 'Approved via automated document verification'),
        verified_at = NOW()
    WHERE id = NEW.doctor_id;
  ELSIF NEW.overall_status = 'rejected' THEN
    UPDATE public.profiles
    SET approval_status = 'rejected',
        approval_note = COALESCE(approval_note, 'Rejected: ' || COALESCE(NEW.verification_notes, 'Document verification failed')),
        verified_at = NOW()
    WHERE id = NEW.doctor_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_doctor_approval_status ON public.doctor_verifications;
CREATE TRIGGER trigger_update_doctor_approval_status
AFTER INSERT OR UPDATE ON public.doctor_verifications
FOR EACH ROW
EXECUTE FUNCTION update_doctor_approval_status();

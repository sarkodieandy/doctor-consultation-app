-- Service schema compatibility patch
-- Ensures Flutter service layer fields exist in all environments.

alter table if exists public.reviews
  add column if not exists helpful_count integer not null default 0;

alter table if exists public.medical_documents
  add column if not exists notes text;

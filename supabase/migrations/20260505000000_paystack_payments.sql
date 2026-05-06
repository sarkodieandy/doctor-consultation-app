-- Paystack Payment Integration Migration
-- Run this in Supabase SQL Editor

-- ── 1. Extend payments table with Paystack fields ──────────────────────────────
alter table payments
  add column if not exists gateway_reference  text unique,
  add column if not exists gateway_response   jsonb,
  add column if not exists platform_fee       numeric(10,2) default 0,
  add column if not exists doctor_amount      numeric(10,2) default 0,
  add column if not exists currency           text default 'GHS',
  add column if not exists completed_at       timestamptz,
  add column if not exists refunded_at        timestamptz,
  add column if not exists refund_reason      text,
  add column if not exists payout_batch_id    uuid;

-- Update status check to include 'refunded'
alter table payments drop constraint if exists payments_status_check;
alter table payments add constraint payments_status_check
  check (status in ('pending', 'completed', 'failed', 'refunded'));

-- ── 2. Payout batches (doctor disbursements) ────────────────────────────────────
create table if not exists payout_batches (
  id              uuid primary key default gen_random_uuid(),
  processed_by    uuid references profiles(id) on delete set null,
  doctor_id       uuid not null references profiles(id) on delete cascade,
  total_amount    numeric(10,2) not null check (total_amount > 0),
  payment_count   int not null default 0,
  transfer_code   text,          -- Paystack transfer code for tracking
  status          text not null default 'pending'
                    check (status in ('pending', 'processing', 'completed', 'failed')),
  failure_reason  text,
  created_at      timestamptz default now(),
  completed_at    timestamptz
);

-- Link payments to their payout batch
alter table payments
  add constraint fk_payments_payout_batch
  foreign key (payout_batch_id) references payout_batches(id) on delete set null;

-- ── 3. Indexes ──────────────────────────────────────────────────────────────────
create index if not exists idx_payments_gateway_reference on payments(gateway_reference);
create index if not exists idx_payments_payout_status     on payments(payout_status);
create index if not exists idx_payout_batches_doctor_id   on payout_batches(doctor_id);
create index if not exists idx_payout_batches_status      on payout_batches(status);

-- ── 4. RLS for payout_batches (admin-only write, doctors can read their own) ───
alter table payout_batches enable row level security;

drop policy if exists admin_all_payout_batches on payout_batches;
create policy admin_all_payout_batches on payout_batches
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists doctor_own_payout_batches on payout_batches;
create policy doctor_own_payout_batches on payout_batches
  for select
  using (auth.uid() = doctor_id);

-- ── 5. Patient can read their own payments ──────────────────────────────────────
drop policy if exists patient_own_payments on payments;
create policy patient_own_payments on payments
  for select
  using (auth.uid() = user_id);

-- ── 6. Patient can insert a pending payment (init step) ─────────────────────────
drop policy if exists patient_insert_payment on payments;
create policy patient_insert_payment on payments
  for insert
  with check (auth.uid() = user_id and status = 'pending');

-- ── 7. Realtime publication ──────────────────────────────────────────────────────
-- (skip if already added in a previous migration)
do $$
begin
  begin
    alter publication supabase_realtime add table payments;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table payout_batches;
  exception when others then null;
  end;
end $$;

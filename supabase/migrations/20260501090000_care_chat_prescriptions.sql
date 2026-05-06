-- Care chat and prescription workflow for patient/doctor consultations.

create table if not exists care_chats (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid references appointments(id) on delete set null on update cascade,
  patient_id uuid not null references profiles(id) on delete cascade on update cascade,
  doctor_id uuid not null references profiles(id) on delete cascade on update cascade,
  patient_name text,
  patient_avatar text,
  doctor_name text,
  doctor_avatar text,
  last_message text default '',
  last_message_time timestamptz default now(),
  patient_unread_count integer default 0 check (patient_unread_count >= 0),
  doctor_unread_count integer default 0 check (doctor_unread_count >= 0),
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(patient_id, doctor_id, appointment_id)
);

create table if not exists care_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references care_chats(id) on delete cascade on update cascade,
  sender_id uuid not null references profiles(id) on delete cascade on update cascade,
  sender_name text,
  sender_avatar text,
  message text not null check (char_length(trim(message)) > 0),
  is_doctor boolean default false,
  is_read boolean default false,
  created_at timestamptz default now()
);

create table if not exists prescriptions (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references profiles(id) on delete cascade on update cascade,
  patient_id uuid not null references profiles(id) on delete cascade on update cascade,
  appointment_id uuid references appointments(id) on delete set null on update cascade,
  doctor_name text,
  prescribed_date timestamptz default now(),
  expiry_date timestamptz,
  notes text,
  status text check (status in ('active', 'completed', 'expired')) default 'active',
  attachment_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz
);

create table if not exists prescription_medicines (
  id uuid primary key default gen_random_uuid(),
  prescription_id uuid not null references prescriptions(id) on delete cascade on update cascade,
  name text not null,
  dosage text not null,
  frequency text not null,
  duration integer default 1 check (duration > 0),
  instructions text,
  side_effects text[] default '{}',
  created_at timestamptz default now()
);

create index if not exists idx_care_chats_patient_id on care_chats(patient_id);
create index if not exists idx_care_chats_doctor_id on care_chats(doctor_id);
create index if not exists idx_care_messages_chat_id on care_messages(chat_id);
create index if not exists idx_prescriptions_patient_id on prescriptions(patient_id);
create index if not exists idx_prescriptions_doctor_id on prescriptions(doctor_id);
create index if not exists idx_prescriptions_appointment_id on prescriptions(appointment_id);
create index if not exists idx_prescription_medicines_prescription_id on prescription_medicines(prescription_id);

alter table care_chats enable row level security;
alter table care_messages enable row level security;
alter table prescriptions enable row level security;
alter table prescription_medicines enable row level security;

drop policy if exists chat_participants_read on care_chats;
create policy chat_participants_read on care_chats
  for select using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists chat_participants_insert on care_chats;
create policy chat_participants_insert on care_chats
  for insert with check (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists chat_participants_update on care_chats;
create policy chat_participants_update on care_chats
  for update using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin())
  with check (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists message_participants_read on care_messages;
create policy message_participants_read on care_messages
  for select using (
    exists (
      select 1 from care_chats
      where care_chats.id = care_messages.chat_id
        and (auth.uid() = care_chats.patient_id or auth.uid() = care_chats.doctor_id or public.is_platform_admin())
    )
  );

drop policy if exists message_participants_insert on care_messages;
create policy message_participants_insert on care_messages
  for insert with check (
    auth.uid() = sender_id and exists (
      select 1 from care_chats
      where care_chats.id = care_messages.chat_id
        and (auth.uid() = care_chats.patient_id or auth.uid() = care_chats.doctor_id or public.is_platform_admin())
    )
  );

drop policy if exists prescription_participants_read on prescriptions;
create policy prescription_participants_read on prescriptions
  for select using (auth.uid() = patient_id or auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_writes_prescriptions on prescriptions;
create policy doctor_writes_prescriptions on prescriptions
  for insert with check (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists doctor_updates_prescriptions on prescriptions;
create policy doctor_updates_prescriptions on prescriptions
  for update using (auth.uid() = doctor_id or public.is_platform_admin())
  with check (auth.uid() = doctor_id or public.is_platform_admin());

drop policy if exists prescription_medicines_participants_read on prescription_medicines;
create policy prescription_medicines_participants_read on prescription_medicines
  for select using (
    exists (
      select 1 from prescriptions
      where prescriptions.id = prescription_medicines.prescription_id
        and (auth.uid() = prescriptions.patient_id or auth.uid() = prescriptions.doctor_id or public.is_platform_admin())
    )
  );

drop policy if exists doctor_writes_prescription_medicines on prescription_medicines;
create policy doctor_writes_prescription_medicines on prescription_medicines
  for insert with check (
    exists (
      select 1 from prescriptions
      where prescriptions.id = prescription_medicines.prescription_id
        and (auth.uid() = prescriptions.doctor_id or public.is_platform_admin())
    )
  );

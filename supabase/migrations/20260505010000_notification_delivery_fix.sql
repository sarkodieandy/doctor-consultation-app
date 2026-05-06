-- Allow patients and doctors to receive direct and role-targeted notifications.

drop policy if exists recipient_read_notifications on notifications;
create policy recipient_read_notifications on notifications
  for select
  using (
    auth.uid() = user_id
    or target_role = 'all'
    or (
      target_role in ('patient', 'doctor', 'admin')
      and exists (
        select 1
        from profiles
        where id = auth.uid()
          and role = target_role
      )
    )
  );

drop policy if exists recipient_update_notifications on notifications;
create policy recipient_update_notifications on notifications
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

do $$
begin
  begin
    alter publication supabase_realtime add table notifications;
  exception when others then null;
  end;
end $$;
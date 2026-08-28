create or replace function public.cancel_my_today_meal()
returns table (
  meal_id uuid,
  meal_date date,
  status public.meal_status,
  rate numeric,
  cancelled_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  current_employee_id uuid;
  meal_record public.meal_records%rowtype;
  cancellation_time timestamptz;
  karachi_now timestamp;
  karachi_date date;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  current_employee_id := public.get_my_employee_id();

  if current_employee_id is null then
    raise exception 'Employee record not found.';
  end if;

  karachi_now := timezone('Asia/Karachi', now());
  karachi_date := karachi_now::date;
  if karachi_now::time >= time '10:00:00' then
    raise exception 'Today''s meal cancellation window has closed.';
  end if;

  select *
    into meal_record
    from public.meal_records as mr
     where mr.employee_id = current_employee_id
       and mr.meal_date = karachi_date
   for update;

  if not found then
    raise exception 'No meal is scheduled for today.';
  end if;

  if meal_record.status = 'CANCELLED'::public.meal_status then
    raise exception 'Today''s meal is already cancelled.';
  end if;

  if meal_record.status = 'SERVED'::public.meal_status then
    raise exception 'A served meal cannot be cancelled.';
  end if;

  if meal_record.status <> 'PLANNED'::public.meal_status then
    raise exception 'Today''s meal cannot be cancelled.';
  end if;

    cancellation_time := now();

    update public.meal_records as mr
     set status = 'CANCELLED'::public.meal_status,
      cancelled_at = cancellation_time,
         updated_by = auth.uid(),
         updated_at = now()
  where mr.id = meal_record.id;

  insert into public.ledger (
    employee_id,
    transaction_date,
    transaction_type,
    description,
    debit,
    credit,
    reference_id
  )
  select
    current_employee_id,
    karachi_date,
    'CANCELLATION'::public.transaction_type,
    'Meal cancellation - ' || karachi_date,
    0,
    meal_record.rate,
    meal_record.id
  where not exists (
    select 1
      from public.ledger as l
     where l.employee_id = current_employee_id
       and l.transaction_type = 'CANCELLATION'::public.transaction_type
       and l.reference_id = meal_record.id
  );

  return query
  select meal_record.id,
         meal_record.meal_date,
         'CANCELLED'::public.meal_status,
         meal_record.rate,
         cancellation_time;
end;
$$;

revoke execute on function public.cancel_my_today_meal() from public;
grant execute on function public.cancel_my_today_meal() to authenticated;

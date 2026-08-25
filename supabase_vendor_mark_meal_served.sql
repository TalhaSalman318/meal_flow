create or replace function public.vendor_mark_meal_served(p_meal_id uuid)
returns table (
  meal_id uuid,
  employee_id uuid,
  meal_date date,
  meal_type public.meal_type,
  status public.meal_status,
  rate numeric,
  served_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  meal_record public.meal_records%rowtype;
  serving_time timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  if coalesce(public.get_my_role()::text, '') <> 'VENDOR' then
    raise exception 'Only vendors can serve meals.';
  end if;

  select *
    into meal_record
    from public.meal_records
   where id = p_meal_id
   for update;

  if not found then
    raise exception 'Meal not found.';
  end if;

  if meal_record.meal_date <> current_date then
    raise exception 'Only today''s meals can be served.';
  end if;

  if meal_record.status = 'CANCELLED'::public.meal_status then
    raise exception 'Cancelled meals cannot be served.';
  end if;

  if meal_record.status = 'SERVED'::public.meal_status then
    raise exception 'Meal is already served.';
  end if;

  if meal_record.status <> 'PLANNED'::public.meal_status then
    raise exception 'This meal cannot be served.';
  end if;

  serving_time := now();

  update public.meal_records
     set status = 'SERVED'::public.meal_status,
         served_at = serving_time,
         updated_by = auth.uid(),
         updated_at = serving_time
   where id = meal_record.id;

  return query
  select meal_record.id,
         meal_record.employee_id,
         meal_record.meal_date,
         meal_record.meal_type,
         'SERVED'::public.meal_status,
         meal_record.rate,
         serving_time;
end;
$$;

revoke execute on function public.vendor_mark_meal_served(uuid) from public;
grant execute on function public.vendor_mark_meal_served(uuid) to authenticated;

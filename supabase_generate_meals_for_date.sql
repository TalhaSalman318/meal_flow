create or replace function public.generate_meals_for_date(p_meal_date date)
returns table (
  generated_meals integer,
  generated_charges integer
)
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  subscription_record record;
  meal_id uuid;
  meals_created integer := 0;
  charges_created integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  if coalesce(public.get_my_role()::text, '') <> 'VENDOR' then
    raise exception 'Only vendors can generate meals.';
  end if;

  if p_meal_date is null then
    raise exception 'Meal date is required.';
  end if;

  for subscription_record in
    select s.employee_id, s.daily_rate
      from public.subscriptions s
     where s.status = 'ACTIVE'::public.subscription_status
       and p_meal_date between s.start_date and s.end_date
       and not exists (
         select 1
           from public.subscription_pauses sp
          where sp.subscription_id = s.id
            and p_meal_date between sp.start_date and sp.end_date
       )
  loop
    insert into public.meal_records (
      employee_id,
      meal_date,
      meal_type,
      status,
      rate
    ) values (
      subscription_record.employee_id,
      p_meal_date,
      'NORMAL'::public.meal_type,
      'PLANNED'::public.meal_status,
      subscription_record.daily_rate
    )
    on conflict (employee_id, meal_date) do nothing
    returning id into meal_id;

    if meal_id is not null then
      meals_created := meals_created + 1;
      perform public.add_meal_charge(
        subscription_record.employee_id,
        p_meal_date,
        subscription_record.daily_rate,
        'Meal charge - ' || p_meal_date
      );
      charges_created := charges_created + 1;
      meal_id := null;
    end if;
  end loop;

  return query select meals_created, charges_created;
end;
$$;

revoke execute on function public.generate_meals_for_date(date) from public;
revoke execute on function public.generate_meals_for_date(date) from authenticated;
grant execute on function public.generate_meals_for_date(date) to authenticated;

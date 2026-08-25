create or replace function public.get_today_guest_meals_for_vendor()
returns table (
  id uuid,
  employee_id uuid,
  employee_code text,
  employee_name text,
  guest_type public.guest_type,
  guest_name text,
  vendor_id uuid,
  vendor_name text,
  meal_date date,
  meal_type public.meal_type,
  amount numeric,
  notes text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;
  if coalesce(public.get_my_role()::text, '') <> 'VENDOR' then
    raise exception 'Only vendors can view guest meals.';
  end if;

  return query
  select gm.id,
         gm.employee_id,
         e.employee_code::text,
         p.full_name::text,
         gm.guest_type,
         gm.guest_name,
         gm.vendor_id,
         v.vendor_name::text,
         gm.meal_date,
         gm.meal_type,
         gm.amount,
         gm.notes,
         gm.created_at
    from public.guest_meals gm
    join public.employees e on e.id = gm.employee_id
    join public.profiles p on p.id = e.profile_id
    left join public.vendors v on v.id = gm.vendor_id
   where gm.meal_date = current_date
   order by gm.created_at desc;
end;
$$;

revoke execute on function public.get_today_guest_meals_for_vendor() from public;
grant execute on function public.get_today_guest_meals_for_vendor() to authenticated;

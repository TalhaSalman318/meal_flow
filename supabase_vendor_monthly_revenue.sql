create or replace function public.get_vendor_revenue_for_period(
  p_start_date date,
  p_end_date date
)
returns numeric
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  current_vendor_id uuid;
  meal_total numeric := 0;
  guest_total numeric := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  if coalesce(public.get_my_role()::text, '') <> 'VENDOR' then
    raise exception 'Only vendors can view revenue.';
  end if;

  select v.id
    into current_vendor_id
    from public.vendors v
   where v.profile_id = auth.uid()
   limit 1;

  if current_vendor_id is null then
    raise exception 'Vendor record not found.';
  end if;

  select coalesce(sum(mr.rate), 0)
    into meal_total
    from public.meal_records mr
   where mr.meal_date between p_start_date and p_end_date;

  select coalesce(sum(gm.amount), 0)
    into guest_total
    from public.guest_meals gm
   where gm.vendor_id = current_vendor_id
     and gm.meal_date between p_start_date and p_end_date;

  return meal_total + guest_total;
end;
$$;

revoke execute on function public.get_vendor_revenue_for_period(date, date) from public;
grant execute on function public.get_vendor_revenue_for_period(date, date) to authenticated;

create or replace function public.get_vendor_daily_revenue_for_period(
  p_start_date date,
  p_end_date date
)
returns table (
  meal_date date,
  total numeric
)
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  current_vendor_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  if coalesce(public.get_my_role()::text, '') <> 'VENDOR' then
    raise exception 'Only vendors can view revenue.';
  end if;

  select v.id
    into current_vendor_id
    from public.vendors v
   where v.profile_id = auth.uid()
   limit 1;

  if current_vendor_id is null then
    raise exception 'Vendor record not found.';
  end if;

  return query
  with daily_meals as (
    select mr.meal_date,
           sum(mr.rate) as total
      from public.meal_records mr
     where mr.meal_date between p_start_date and p_end_date
     group by mr.meal_date
  ),
  daily_guests as (
    select gm.meal_date,
           sum(gm.amount) as total
      from public.guest_meals gm
     where gm.vendor_id = current_vendor_id
       and gm.meal_date between p_start_date and p_end_date
     group by gm.meal_date
  )
  select coalesce(dm.meal_date, dg.meal_date) as meal_date,
         coalesce(dm.total, 0) + coalesce(dg.total, 0) as total
    from daily_meals dm
    full outer join daily_guests dg
      on dm.meal_date = dg.meal_date
   order by coalesce(dm.meal_date, dg.meal_date);
end;
$$;

revoke execute on function public.get_vendor_daily_revenue_for_period(date, date) from public;
grant execute on function public.get_vendor_daily_revenue_for_period(date, date) to authenticated;

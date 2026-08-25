create or replace function public.create_guest_meal(
  p_guest_type public.guest_type,
  p_guest_name text,
  p_vendor_id uuid,
  p_meal_date date,
  p_meal_type public.meal_type,
  p_amount numeric,
  p_notes text
)
returns public.guest_meals
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  current_employee_id uuid;
  created_guest public.guest_meals;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.';
  end if;

  current_employee_id := public.get_my_employee_id();
  if current_employee_id is null then
    raise exception 'Employee record not found.';
  end if;

  if p_guest_name is null or btrim(p_guest_name) = '' then
    raise exception 'Guest name is required.';
  end if;
  if length(btrim(p_guest_name)) > 100 then
    raise exception 'Guest name is too long.';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Guest meal amount must be greater than zero.';
  end if;
  if p_meal_date is null then
    raise exception 'Meal date is required.';
  end if;
  if p_meal_date <> current_date then
    raise exception 'Guest meals can only be added for today.';
  end if;

  if p_guest_type = 'EMPLOYEE'::public.guest_type and p_vendor_id is not null then
    raise exception 'Vendor must be empty for an employee guest.';
  end if;

  if p_guest_type = 'VENDOR'::public.guest_type then
    if p_vendor_id is null then
      raise exception 'A vendor is required for a vendor guest.';
    end if;
    if not exists (
      select 1 from public.vendors
      where id = p_vendor_id and status = 'ACTIVE'
    ) then
      raise exception 'The selected vendor is not active.';
    end if;
  end if;

  insert into public.guest_meals (
    employee_id, guest_type, guest_name, vendor_id,
    meal_date, meal_type, amount, notes
  ) values (
    current_employee_id, p_guest_type, btrim(p_guest_name), p_vendor_id,
    p_meal_date, p_meal_type, p_amount, nullif(btrim(p_notes), '')
  ) returning * into created_guest;

  insert into public.ledger (
    employee_id, transaction_date, transaction_type,
    description, debit, credit, reference_id
  ) values (
    current_employee_id,
    created_guest.meal_date,
    'GUEST_MEAL'::public.transaction_type,
    'Guest meal - ' || created_guest.guest_name,
    created_guest.amount,
    0,
    created_guest.id
  );

  return created_guest;
end;
$$;

revoke execute on function public.create_guest_meal(public.guest_type, text, uuid, date, public.meal_type, numeric, text) from public;
grant execute on function public.create_guest_meal(public.guest_type, text, uuid, date, public.meal_type, numeric, text) to authenticated;

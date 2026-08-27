insert into storage.buckets (id, name, public)
values ('menu-images', 'menu-images', true)
on conflict (id) do update set public = excluded.public;

create policy "Authenticated users can view menu images"
on storage.objects for select
to authenticated
using (bucket_id = 'menu-images');

create policy "Vendors can upload menu images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'menu-images'
  and (select role from public.profiles where id = auth.uid()) = 'VENDOR'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Vendors can replace their menu images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'menu-images'
  and (select role from public.profiles where id = auth.uid()) = 'VENDOR'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'menu-images'
  and (select role from public.profiles where id = auth.uid()) = 'VENDOR'
  and (storage.foldername(name))[1] = auth.uid()::text
);
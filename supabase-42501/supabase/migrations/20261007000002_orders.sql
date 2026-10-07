-- Created AFTER auto_expose_new_tables = false: RLS policies present, but no GRANTs
create table public.orders (id bigint generated always as identity primary key, item text);
alter table public.orders enable row level security;
create policy "anyone can read" on public.orders for select to anon, authenticated using (true);
create policy "anyone can insert" on public.orders for insert to anon, authenticated with check (true);

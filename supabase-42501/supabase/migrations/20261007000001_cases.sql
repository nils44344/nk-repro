-- Case A: RLS on, no policies at all
create table public.notes_nopolicy (id bigint generated always as identity primary key, body text);
alter table public.notes_nopolicy enable row level security;

-- Case B: RLS on, SELECT policy only (reads work, writes denied)
create table public.notes_selectonly (id bigint generated always as identity primary key, body text);
alter table public.notes_selectonly enable row level security;
create policy "anyone can read" on public.notes_selectonly for select to anon, authenticated using (true);

-- Case C: RLS on, INSERT policy only (plain insert ok, insert().select() returning the row?)
create table public.notes_insertonly (id bigint generated always as identity primary key, body text);
alter table public.notes_insertonly enable row level security;
create policy "anyone can insert" on public.notes_insertonly for insert to anon, authenticated with check (true);

-- Case D: the profiles pattern: insert only your own row, authenticated only
create table public.profiles (id uuid primary key, username text);
alter table public.profiles enable row level security;
create policy "insert own profile" on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "read own profile" on public.profiles for select to authenticated using ((select auth.uid()) = id);

-- Case E: user_id defaulted by the client vs policy (todos with user_id column)
create table public.todos (id bigint generated always as identity primary key, user_id uuid, task text);
alter table public.todos enable row level security;
create policy "insert own todos" on public.todos for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "read own todos" on public.todos for select to authenticated using ((select auth.uid()) = user_id);

-- Case F: storage bucket with no policy on storage.objects
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

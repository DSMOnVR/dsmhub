-- DSMHub chat upgrade: categories/channels, owner/moderator roles, message deletion,
-- and private file attachments. Run once in the Supabase SQL Editor for this project.
begin;

create table if not exists public.dsmhub_chat_roles (
  user_id text primary key,
  role text not null check (role in ('owner', 'moderator')),
  created_at timestamptz not null default now()
);

create table if not exists public.dsmhub_chat_categories (
  id text primary key check (id ~ '^[a-z0-9][a-z0-9_-]{0,39}$'),
  name text not null check (char_length(name) between 1 and 40),
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.dsmhub_chat_channels (
  id text primary key check (id ~ '^[a-z0-9][a-z0-9_-]{0,39}$'),
  name text not null check (char_length(name) between 1 and 40),
  topic text not null default '' check (char_length(topic) <= 120),
  category_id text not null references public.dsmhub_chat_categories(id) on delete cascade,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.dsmhub_chat_messages
  add column if not exists attachments jsonb not null default '[]'::jsonb;
alter table public.dsmhub_chat_messages replica identity full;

insert into public.dsmhub_chat_categories (id, name, position)
values ('text', 'Text Channels', 0)
on conflict (id) do nothing;

insert into public.dsmhub_chat_channels (id, name, topic, category_id, position)
values
  ('general', 'general', 'The place for anything DSMHub.', 'text', 0),
  ('games', 'games', 'Talk about games and what you are playing.', 'text', 1),
  ('music', 'music', 'Share what you are listening to.', 'text', 2),
  ('help', 'help', 'Ask the community for help.', 'text', 3)
on conflict (id) do nothing;

-- Bootstrap the owner from the existing profile shown in DSMHub. This only runs
-- if no owner role exists yet, so later username changes do not remove ownership.
do $$
declare matching_profiles integer;
begin
  if not exists (select 1 from public.dsmhub_chat_roles where role = 'owner') then
    select count(*) into matching_profiles
    from public.dsmhub_profiles
    where lower(username) = 'undylaned';
    if matching_profiles <> 1 then
      raise exception 'Expected exactly one DSMHub profile named undylaned to bootstrap the owner; found %.', matching_profiles;
    end if;
    insert into public.dsmhub_chat_roles (user_id, role)
    select user_id, 'owner'
    from public.dsmhub_profiles
    where lower(username) = 'undylaned'
    on conflict (user_id) do update set role = 'owner';
  end if;
end $$;

create or replace function public.dsmhub_chat_is_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.dsmhub_chat_roles
    where user_id = (select auth.jwt() ->> 'sub') and role = 'owner'
  );
$$;

create or replace function public.dsmhub_chat_is_moderator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.dsmhub_chat_roles
    where user_id = (select auth.jwt() ->> 'sub') and role in ('owner', 'moderator')
  );
$$;

revoke all on function public.dsmhub_chat_is_owner() from public, anon;
revoke all on function public.dsmhub_chat_is_moderator() from public, anon;
grant execute on function public.dsmhub_chat_is_owner() to authenticated;
grant execute on function public.dsmhub_chat_is_moderator() to authenticated;

alter table public.dsmhub_chat_roles enable row level security;
alter table public.dsmhub_chat_categories enable row level security;
alter table public.dsmhub_chat_channels enable row level security;

grant select, insert, update, delete on public.dsmhub_chat_roles to authenticated;
grant select, insert, update, delete on public.dsmhub_chat_categories to authenticated;
grant select, insert, update, delete on public.dsmhub_chat_channels to authenticated;
grant select, insert, delete on public.dsmhub_chat_messages to authenticated;

drop policy if exists "Chat roles are visible to members" on public.dsmhub_chat_roles;
create policy "Chat roles are visible to members"
  on public.dsmhub_chat_roles for select to authenticated using (true);
drop policy if exists "Only owner can add moderators" on public.dsmhub_chat_roles;
create policy "Only owner can add moderators"
  on public.dsmhub_chat_roles for insert to authenticated
  with check ((select public.dsmhub_chat_is_owner()) and role = 'moderator');
drop policy if exists "Only owner can update moderators" on public.dsmhub_chat_roles;
create policy "Only owner can update moderators"
  on public.dsmhub_chat_roles for update to authenticated
  using ((select public.dsmhub_chat_is_owner()) and role = 'moderator')
  with check ((select public.dsmhub_chat_is_owner()) and role = 'moderator');
drop policy if exists "Only owner can remove moderators" on public.dsmhub_chat_roles;
create policy "Only owner can remove moderators"
  on public.dsmhub_chat_roles for delete to authenticated
  using ((select public.dsmhub_chat_is_owner()) and role = 'moderator');

drop policy if exists "Members can read chat categories" on public.dsmhub_chat_categories;
create policy "Members can read chat categories"
  on public.dsmhub_chat_categories for select to authenticated using (true);
drop policy if exists "Only owner can add chat categories" on public.dsmhub_chat_categories;
create policy "Only owner can add chat categories"
  on public.dsmhub_chat_categories for insert to authenticated
  with check ((select public.dsmhub_chat_is_owner()));
drop policy if exists "Only owner can update chat categories" on public.dsmhub_chat_categories;
create policy "Only owner can update chat categories"
  on public.dsmhub_chat_categories for update to authenticated
  using ((select public.dsmhub_chat_is_owner())) with check ((select public.dsmhub_chat_is_owner()));
drop policy if exists "Only owner can remove chat categories" on public.dsmhub_chat_categories;
create policy "Only owner can remove chat categories"
  on public.dsmhub_chat_categories for delete to authenticated
  using ((select public.dsmhub_chat_is_owner()));

drop policy if exists "Members can read chat channels" on public.dsmhub_chat_channels;
create policy "Members can read chat channels"
  on public.dsmhub_chat_channels for select to authenticated using (true);
drop policy if exists "Only owner can add chat channels" on public.dsmhub_chat_channels;
create policy "Only owner can add chat channels"
  on public.dsmhub_chat_channels for insert to authenticated
  with check ((select public.dsmhub_chat_is_owner()));
drop policy if exists "Only owner can update chat channels" on public.dsmhub_chat_channels;
create policy "Only owner can update chat channels"
  on public.dsmhub_chat_channels for update to authenticated
  using ((select public.dsmhub_chat_is_owner())) with check ((select public.dsmhub_chat_is_owner()));
drop policy if exists "Only owner can remove chat channels" on public.dsmhub_chat_channels;
create policy "Only owner can remove chat channels"
  on public.dsmhub_chat_channels for delete to authenticated
  using ((select public.dsmhub_chat_is_owner()));

drop policy if exists "Members can delete own messages or moderators can delete any" on public.dsmhub_chat_messages;
create policy "Members can delete own messages or moderators can delete any"
  on public.dsmhub_chat_messages for delete to authenticated
  using (user_id = (select auth.jwt() ->> 'sub') or (select public.dsmhub_chat_is_moderator()));

do $$
begin
  if not exists (select 1 from storage.buckets where id = 'dsmhub-chat-attachments') then
    insert into storage.buckets (id, name, public, file_size_limit)
    values ('dsmhub-chat-attachments', 'dsmhub-chat-attachments', false, 15728640);
  elsif exists (select 1 from storage.buckets where id = 'dsmhub-chat-attachments' and public) then
    raise exception 'The dsmhub-chat-attachments bucket already exists as public. Set it to private before running this upgrade.';
  end if;
end $$;

drop policy if exists "Chat members can read attachments" on storage.objects;
create policy "Chat members can read attachments"
  on storage.objects for select to authenticated
  using (bucket_id = 'dsmhub-chat-attachments');
drop policy if exists "Members can upload their own chat attachments" on storage.objects;
create policy "Members can upload their own chat attachments"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'dsmhub-chat-attachments'
    and (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
  );
drop policy if exists "Owners and moderators can delete chat attachments" on storage.objects;
create policy "Owners and moderators can delete chat attachments"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'dsmhub-chat-attachments'
    and (
      (storage.foldername(name))[1] = (select auth.jwt() ->> 'sub')
      or (select public.dsmhub_chat_is_moderator())
    )
  );

do $$
declare target_table text;
begin
  foreach target_table in array array['dsmhub_chat_messages','dsmhub_chat_categories','dsmhub_chat_channels','dsmhub_chat_roles'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = target_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', target_table);
    end if;
  end loop;
end $$;

commit;

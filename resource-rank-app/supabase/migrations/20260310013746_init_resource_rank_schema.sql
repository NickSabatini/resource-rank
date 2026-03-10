-- ResourceRank initial schema
-- Source of truth for schema changes should remain migrations in this directory.

create extension if not exists pgcrypto;

create type public.resource_status as enum ('active', 'pending', 'hidden', 'spam');
create type public.resource_type as enum ('article', 'book', 'video', 'course', 'podcast', 'other');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null,
  created_at timestamptz not null default now(),
  trust_level integer not null default 0 check (trust_level >= 0),
  is_banned boolean not null default false
);

create table public.topics (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null unique,
  description text,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now()
);

create table public.resources (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  title text not null,
  url text not null,
  canonical_url text not null,
  canonical_url_hash text not null,
  description text,
  resource_type public.resource_type not null default 'article',
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  score integer not null default 0,
  up_count integer not null default 0,
  down_count integer not null default 0,
  report_count integer not null default 0,
  status public.resource_status not null default 'active',
  constraint resources_topic_id_canonical_url_hash_key unique (topic_id, canonical_url_hash)
);

create table public.votes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  value smallint not null check (value in (-1, 1)),
  created_at timestamptz not null default now(),
  constraint votes_user_id_resource_id_key unique (user_id, resource_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now(),
  constraint reports_user_id_resource_id_key unique (user_id, resource_id)
);

create index topics_slug_idx on public.topics (slug);
create index resources_topic_id_score_idx on public.resources (topic_id, score desc);
create index resources_topic_id_created_at_idx on public.resources (topic_id, created_at desc);
create index resources_status_idx on public.resources (status);
create index votes_resource_id_idx on public.votes (resource_id);
create index reports_resource_id_idx on public.reports (resource_id);

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, ''), '@', 1), 'user')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();

create or replace function public.apply_vote_delta(
  p_resource_id uuid,
  p_old_value smallint,
  p_new_value smallint
)
returns void
language plpgsql
as $$
declare
  old_up_delta integer := 0;
  old_down_delta integer := 0;
  old_score_delta integer := 0;
  new_up_delta integer := 0;
  new_down_delta integer := 0;
  new_score_delta integer := 0;
begin
  if p_old_value = 1 then
    old_up_delta := -1;
    old_score_delta := -1;
  elsif p_old_value = -1 then
    old_down_delta := -1;
    old_score_delta := 1;
  end if;

  if p_new_value = 1 then
    new_up_delta := 1;
    new_score_delta := 1;
  elsif p_new_value = -1 then
    new_down_delta := 1;
    new_score_delta := -1;
  end if;

  update public.resources
  set
    up_count = up_count + old_up_delta + new_up_delta,
    down_count = down_count + old_down_delta + new_down_delta,
    score = score + old_score_delta + new_score_delta
  where id = p_resource_id;
end;
$$;

create or replace function public.handle_votes_counter()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    perform public.apply_vote_delta(new.resource_id, 0, new.value);
    return new;
  elsif tg_op = 'UPDATE' then
    perform public.apply_vote_delta(new.resource_id, old.value, new.value);
    return new;
  elsif tg_op = 'DELETE' then
    perform public.apply_vote_delta(old.resource_id, old.value, 0);
    return old;
  end if;

  return null;
end;
$$;

create trigger votes_counter_trigger
  after insert or update of value or delete on public.votes
  for each row execute procedure public.handle_votes_counter();

create or replace function public.handle_reports_counter()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    update public.resources
    set report_count = report_count + 1
    where id = new.resource_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.resources
    set report_count = greatest(report_count - 1, 0)
    where id = old.resource_id;
    return old;
  end if;

  return null;
end;
$$;

create trigger reports_counter_trigger
  after insert or delete on public.reports
  for each row execute procedure public.handle_reports_counter();

alter table public.users enable row level security;
alter table public.topics enable row level security;
alter table public.resources enable row level security;
alter table public.votes enable row level security;
alter table public.reports enable row level security;

create policy "Users are readable by everyone"
  on public.users
  for select
  using (true);

create policy "Users can insert own profile"
  on public.users
  for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.users
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Topics are readable by everyone"
  on public.topics
  for select
  using (true);

create policy "Authenticated users can create topics"
  on public.topics
  for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Resources are readable by everyone"
  on public.resources
  for select
  using (status = 'active' or auth.uid() = created_by);

create policy "Authenticated users can create resources"
  on public.resources
  for insert
  to authenticated
  with check (auth.uid() = created_by);

create policy "Users can read own votes"
  on public.votes
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own votes"
  on public.votes
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own votes"
  on public.votes
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own votes"
  on public.votes
  for delete
  using (auth.uid() = user_id);

create policy "Users can read own reports"
  on public.reports
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own reports"
  on public.reports
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can delete own reports"
  on public.reports
  for delete
  using (auth.uid() = user_id);

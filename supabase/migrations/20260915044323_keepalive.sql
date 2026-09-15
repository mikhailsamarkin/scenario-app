-- Keep-alive для free-tier Supabase (dev + prod).
--
-- Supabase приостанавливает free-проекты после 7 дней без user database
-- activity. Активностью считается запрос к БД через PostgREST (exposed-схема
-- public), а запросы к Storage/Auth/Management API — нет. Поэтому заводим
-- лёгкую таблицу, к которой GitHub Actions (supabase-keepalive.yml в
-- репозитории scenario-site) ежедневно обращается:
--   GET /rest/v1/keepalive?select=id&limit=1   (anon key)
--
-- Применяется к обоим проектам: bzraqbhydmklvpfqiidl (dev), sjxmmqnejolgtwcfjzsd (prod).

create table if not exists public.keepalive (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now()
);

alter table public.keepalive enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'keepalive'
      and policyname = 'keepalive_select'
  ) then
    create policy keepalive_select on public.keepalive
      for select to anon, authenticated
      using (true);
  end if;
end $$;

insert into public.keepalive default values;

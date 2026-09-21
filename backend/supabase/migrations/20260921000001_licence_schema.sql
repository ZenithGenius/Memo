-- Schéma de licence (ADR-004, ADR-008).
-- Les utilisateurs ne peuvent jamais écrire dans subscriptions ni devices :
-- l'activation est faite par un administrateur, l'enregistrement d'appareil
-- et l'émission de jeton par les fonctions serveur (rôle service_role).

create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.plans (
  code text primary key,
  name text not null,
  max_devices int not null check (max_devices between 1 and 10),
  period_days int not null check (period_days > 0),
  price_fcfa int not null check (price_fcfa >= 0),
  sort_order int not null default 0
);

create table public.accounts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  phone text,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_code text not null references public.plans (code),
  starts_at timestamptz not null default now(),
  valid_until timestamptz not null,
  status text not null default 'active' check (status in ('active', 'revoked')),
  activated_by uuid references auth.users (id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  check (valid_until > starts_at)
);
create index subscriptions_user_idx on public.subscriptions (user_id, valid_until desc);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- empreinte de la clé publique matérielle de l'appareil (claim `dev` du jeton)
  fingerprint text not null,
  label text,
  platform text not null check (platform in ('android', 'ios')),
  integrity_level text not null default 'unknown'
    check (integrity_level in ('unknown', 'strong', 'basic', 'failed')),
  installed_from_store boolean,
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  revoked_at timestamptz,
  unique (user_id, fingerprint)
);

-- Journal d'émission des jetons : audit et détection d'abus.
create table public.license_issuances (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id uuid not null references public.devices (id) on delete cascade,
  issued_at timestamptz not null default now(),
  valid_until timestamptz not null,
  token_expires_at timestamptz not null,
  key_id text not null,
  integrity_level text not null
);
create index license_issuances_user_idx on public.license_issuances (user_id, issued_at desc);

insert into public.plans (code, name, max_devices, period_days, price_fcfa, sort_order) values
  ('essentiel', 'Essentiel', 2, 30, 1000, 1),
  ('famille', 'Famille', 2, 30, 2000, 2),
  ('professionnel', 'Professionnel', 2, 30, 3000, 3),
  ('structure', 'Structure', 2, 30, 5000, 4);

-- Administrateur : fonction stable, exécutée avec les droits du propriétaire.
create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- Limite d'appareils actifs par compte, appliquée par la base (atomique),
-- quel que soit le code appelant. Sans abonnement actif : un seul appareil.
create function public.enforce_device_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  allowed int;
  current_count int;
begin
  select coalesce(max(p.max_devices), 1) into allowed
  from public.subscriptions s
  join public.plans p on p.code = s.plan_code
  where s.user_id = new.user_id
    and s.status = 'active'
    and s.valid_until > now();

  select count(*) into current_count
  from public.devices d
  where d.user_id = new.user_id
    and d.revoked_at is null
    and d.id is distinct from new.id;

  if new.revoked_at is null and current_count >= allowed then
    raise exception 'device_limit_reached' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger devices_limit
before insert or update of revoked_at on public.devices
for each row execute function public.enforce_device_limit();

-- Création automatique de la fiche compte à l'inscription.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.accounts (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Sécurité par ligne : tout est fermé par défaut.
alter table public.admins enable row level security;
alter table public.plans enable row level security;
alter table public.accounts enable row level security;
alter table public.subscriptions enable row level security;
alter table public.devices enable row level security;
alter table public.license_issuances enable row level security;

create policy plans_read on public.plans for select to authenticated, anon using (true);

create policy accounts_own_read on public.accounts
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy accounts_own_update on public.accounts
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy subscriptions_own_read on public.subscriptions
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy subscriptions_admin_write on public.subscriptions
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy devices_own_read on public.devices
  for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy devices_admin_update on public.devices
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy issuances_read on public.license_issuances
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

create policy admins_admin_read on public.admins
  for select to authenticated using (public.is_admin());

-- Droits de table : rien pour anon hors lecture des offres.
revoke all on all tables in schema public from anon, authenticated;
grant select on public.plans to anon, authenticated;
grant select, update (display_name, phone) on public.accounts to authenticated;
grant select, insert, update, delete on public.subscriptions to authenticated;
grant select, update on public.devices to authenticated;
grant select on public.license_issuances to authenticated;
grant select on public.admins to authenticated;

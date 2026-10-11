-- Back-office complet (issues #26, #27) : rôles d'administration, paiements,
-- journal d'audit et fonctions de lecture du tableau de bord.
-- Toute règle est appliquée ici, jamais seulement dans l'interface.

-- ─── Rôles ──────────────────────────────────────────────────────────────────
-- super_admin : lecture et écriture. support : lecture seule.
alter table public.admins
  add column role text not null default 'super_admin'
    check (role in ('super_admin', 'support'));

create function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins where user_id = auth.uid() and role = 'super_admin'
  );
$$;

-- Les écritures existantes passent de « tout administrateur » à super_admin.
drop policy subscriptions_admin_write on public.subscriptions;
create policy subscriptions_admin_write on public.subscriptions
  for all to authenticated using (public.is_super_admin()) with check (public.is_super_admin());

drop policy devices_admin_update on public.devices;
create policy devices_admin_update on public.devices
  for update to authenticated using (public.is_super_admin()) with check (public.is_super_admin());

create policy accounts_admin_update on public.accounts
  for update to authenticated using (public.is_super_admin()) with check (public.is_super_admin());

-- ─── Offres ─────────────────────────────────────────────────────────────────
-- Une offre déjà souscrite ne peut pas être supprimée (clé étrangère) : on la
-- retire de la vente.
alter table public.plans add column active boolean not null default true;

create policy plans_admin_insert on public.plans
  for insert to authenticated with check (public.is_super_admin());
create policy plans_admin_update on public.plans
  for update to authenticated using (public.is_super_admin()) with check (public.is_super_admin());
grant insert, update on public.plans to authenticated;

-- ─── Résiliation datée ──────────────────────────────────────────────────────
alter table public.subscriptions
  add column revoked_at timestamptz,
  add column revoked_by uuid references auth.users (id) on delete set null;

create function public.stamp_subscription_revocation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'revoked' and old.status is distinct from 'revoked' then
    new.revoked_at := now();
    new.revoked_by := auth.uid();
  elsif new.status = 'active' then
    new.revoked_at := null;
    new.revoked_by := null;
  end if;
  return new;
end;
$$;

create trigger subscriptions_revocation_stamp
before update of status on public.subscriptions
for each row execute function public.stamp_subscription_revocation();

-- ─── Paiements ──────────────────────────────────────────────────────────────
-- Registre en ajout seul : aucune modification ni suppression par l'API.
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subscription_id uuid references public.subscriptions (id) on delete set null,
  amount_fcfa int not null check (amount_fcfa >= 0),
  method text not null
    check (method in ('mtn_momo', 'orange_money', 'especes', 'virement', 'offert')),
  reference text check (char_length(reference) <= 120),
  paid_at timestamptz not null default now(),
  recorded_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index payments_paid_at_idx on public.payments (paid_at desc);
create index payments_user_idx on public.payments (user_id, paid_at desc);

alter table public.payments enable row level security;
create policy payments_admin_read on public.payments
  for select to authenticated using (public.is_admin());
-- Les privilèges par défaut de Supabase donnent tout à anon et authenticated
-- sur une nouvelle table : on ne garde que la lecture.
revoke all on public.payments from anon, authenticated;
grant select on public.payments to authenticated;

-- Activation ou prolongation : abonnement et paiement écrits ensemble, auteur
-- pris dans la session et non fourni par le client.
create function public.admin_activate_subscription(
  target_user uuid,
  plan text,
  until timestamptz,
  amount_fcfa int,
  method text,
  reference text default null,
  note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  sub_id uuid;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if until <= now() then
    raise exception 'invalid_until' using errcode = '22023';
  end if;

  insert into public.subscriptions (user_id, plan_code, valid_until, activated_by, note)
  values (target_user, plan, until, auth.uid(), nullif(trim(note), ''))
  returning id into sub_id;

  insert into public.payments (user_id, subscription_id, amount_fcfa, method, reference, recorded_by)
  values (target_user, sub_id, amount_fcfa, method, nullif(trim(reference), ''), auth.uid());

  return sub_id;
end;
$$;

-- ─── Journal d'audit ────────────────────────────────────────────────────────
-- Alimenté uniquement par des déclencheurs ; lisible par les administrateurs,
-- jamais modifiable par l'API.
create table public.audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  actor uuid,
  action text not null check (action in ('insert', 'update', 'delete')),
  entity text not null,
  entity_id text,
  before jsonb,
  after jsonb
);
create index audit_log_at_idx on public.audit_log (at desc);
create index audit_log_entity_idx on public.audit_log (entity, entity_id);

alter table public.audit_log enable row level security;
create policy audit_admin_read on public.audit_log
  for select to authenticated using (public.is_admin());
-- Les privilèges par défaut de Supabase donnent tout à anon et authenticated
-- sur une nouvelle table : on ne garde que la lecture.
revoke all on public.audit_log from anon, authenticated;
grant select on public.audit_log to authenticated;

create function public.audit_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  row_data jsonb := to_jsonb(case when tg_op = 'DELETE' then old else new end);
begin
  insert into public.audit_log (actor, action, entity, entity_id, before, after)
  values (
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    coalesce(row_data ->> 'id', row_data ->> 'code', row_data ->> 'user_id'),
    case when tg_op <> 'INSERT' then to_jsonb(old) end,
    case when tg_op <> 'DELETE' then to_jsonb(new) end
  );
  return null;
end;
$$;

create trigger audit_subscriptions after insert or update or delete on public.subscriptions
  for each row execute function public.audit_row();
create trigger audit_payments after insert or update or delete on public.payments
  for each row execute function public.audit_row();
create trigger audit_plans after insert or update or delete on public.plans
  for each row execute function public.audit_row();
create trigger audit_admins after insert or update or delete on public.admins
  for each row execute function public.audit_row();
-- Appareils : seule la révocation est tracée (last_seen change à chaque
-- synchronisation et noierait le journal).
create trigger audit_devices after update of revoked_at on public.devices
  for each row execute function public.audit_row();
create trigger audit_accounts after update on public.accounts
  for each row execute function public.audit_row();

-- ─── Administrateurs ────────────────────────────────────────────────────────
create function public.admin_list()
returns table (user_id uuid, email text, role text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select a.user_id, u.email::text, a.role, a.created_at
  from public.admins a join auth.users u on u.id = a.user_id
  order by a.created_at;
end;
$$;

-- Ajoute ou change le rôle d'un compte existant (inscrit au préalable).
create function public.admin_set_role(target_email text, new_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select id into target from auth.users where lower(email) = lower(trim(target_email));
  if target is null then
    raise exception 'unknown_account' using errcode = 'P0002';
  end if;
  if new_role <> 'super_admin'
     and exists (select 1 from public.admins where user_id = target and role = 'super_admin')
     and (select count(*) from public.admins where role = 'super_admin') = 1 then
    raise exception 'last_super_admin' using errcode = 'P0001';
  end if;
  insert into public.admins (user_id, role) values (target, new_role)
  on conflict (user_id) do update set role = excluded.role;
end;
$$;

create function public.admin_remove(target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if exists (select 1 from public.admins where user_id = target and role = 'super_admin')
     and (select count(*) from public.admins where role = 'super_admin') = 1 then
    raise exception 'last_super_admin' using errcode = 'P0001';
  end if;
  delete from public.admins where user_id = target;
end;
$$;

-- Rôle de la personne connectée (null si elle n'est pas administratrice).
create function public.admin_me()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.admins where user_id = auth.uid();
$$;

-- ─── Lecture : comptes ──────────────────────────────────────────────────────
-- Recherche, filtre par situation, pagination ; total renvoyé sur chaque ligne.
-- Remplace admin_search_account, supprimée avec l'ancien panneau.

create function public.admin_accounts(
  query text default '',
  status text default 'all',
  lim int default 25,
  off int default 0
)
returns table (
  user_id uuid,
  email text,
  display_name text,
  phone text,
  created_at timestamptz,
  plan_name text,
  valid_until timestamptz,
  situation text,
  active_devices bigint,
  total bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if status not in ('all', 'active', 'expiring', 'expired', 'free') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  return query
  with latest as (
    select distinct on (s.user_id) s.user_id, s.valid_until, s.status, p.name
    from public.subscriptions s join public.plans p on p.code = s.plan_code
    order by s.user_id, s.valid_until desc
  ),
  listed as (
    select
      u.id, u.email::text as email, a.display_name, a.phone, a.created_at,
      l.name, l.valid_until,
      case
        when l.user_id is null then 'free'
        when l.status = 'active' and l.valid_until > now() + interval '7 days' then 'active'
        when l.status = 'active' and l.valid_until > now() then 'expiring'
        else 'expired'
      end as situation,
      (select count(*) from public.devices d where d.user_id = u.id and d.revoked_at is null) as devices
    from auth.users u
    join public.accounts a on a.user_id = u.id
    left join latest l on l.user_id = u.id
    where coalesce(query, '') = ''
       or u.email ilike '%' || query || '%'
       or a.phone ilike '%' || query || '%'
       or a.display_name ilike '%' || query || '%'
  )
  select r.id, r.email, r.display_name, r.phone, r.created_at, r.name, r.valid_until,
         r.situation, r.devices, count(*) over ()
  from listed r
  where status = 'all' or r.situation = status
  order by r.created_at desc
  limit least(greatest(lim, 1), 100) offset greatest(off, 0);
end;
$$;

-- ─── Lecture : tableau de bord ──────────────────────────────────────────────
create function public.admin_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  month_start timestamptz := date_trunc('month', now());
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  with active_now as (
    select distinct s.user_id from public.subscriptions s
    where s.status = 'active' and s.valid_until > now()
  ),
  first_sub as (
    select s.user_id, min(s.starts_at) as first_at from public.subscriptions s group by s.user_id
  )
  select jsonb_build_object(
    'accounts_total', (select count(*) from public.accounts),
    'accounts_this_month', (select count(*) from public.accounts where created_at >= month_start),
    'active_subscribers', (select count(*) from active_now),
    'new_subscribers_this_month', (select count(*) from first_sub where first_at >= month_start),
    'cancellations_this_month',
      (select count(*) from public.subscriptions where revoked_at >= month_start),
    'ever_subscribed', (select count(*) from first_sub),
    'mrr_fcfa', (
      select coalesce(sum(p.price_fcfa), 0) from (
        select distinct on (s.user_id) s.plan_code from public.subscriptions s
        where s.status = 'active' and s.valid_until > now()
        order by s.user_id, s.valid_until desc
      ) cur join public.plans p on p.code = cur.plan_code
    ),
    'revenue_this_month_fcfa',
      (select coalesce(sum(amount_fcfa), 0) from public.payments where paid_at >= month_start),
    'revenue_by_month', (
      select jsonb_agg(jsonb_build_object('month', to_char(m, 'YYYY-MM'), 'amount_fcfa', coalesce(t.total, 0)) order by m)
      from generate_series(month_start - interval '11 months', month_start, interval '1 month') m
      left join (
        select date_trunc('month', paid_at) as mo, sum(amount_fcfa) as total
        from public.payments group by 1
      ) t on t.mo = m
    ),
    'retention', (
      -- Parmi les comptes abonnés pour la première fois il y a au moins n
      -- mois, combien ont encore un abonnement en cours.
      select jsonb_agg(r.item order by r.n) from (
        select n, jsonb_build_object(
          'months', n,
          'cohort', count(f.user_id) filter (where f.first_at <= now() - make_interval(months => n)),
          'retained', count(f.user_id) filter (
            where f.first_at <= now() - make_interval(months => n) and a.user_id is not null)
        ) as item
        from unnest(array[3, 6, 12]) n
        cross join first_sub f
        left join active_now a on a.user_id = f.user_id
        group by n
      ) r
    ),
    'expiring_7_days', (
      select count(*) from (
        select distinct on (s.user_id) s.user_id, s.status, s.valid_until
        from public.subscriptions s order by s.user_id, s.valid_until desc
      ) l
      where l.status = 'active' and l.valid_until > now() and l.valid_until <= now() + interval '7 days'
    ),
    'integrity_alerts', (
      select count(*) from public.devices
      where revoked_at is null and integrity_level in ('basic', 'failed')
    )
  ) into result;

  return result;
end;
$$;

-- ─── Droits d'exécution ─────────────────────────────────────────────────────
revoke all on function
  public.is_super_admin(),
  public.admin_activate_subscription(uuid, text, timestamptz, int, text, text, text),
  public.admin_list(),
  public.admin_set_role(text, text),
  public.admin_remove(uuid),
  public.admin_me(),
  public.admin_accounts(text, text, int, int),
  public.admin_dashboard()
from public, anon;

grant execute on function
  public.is_super_admin(),
  public.admin_activate_subscription(uuid, text, timestamptz, int, text, text, text),
  public.admin_list(),
  public.admin_set_role(text, text),
  public.admin_remove(uuid),
  public.admin_me(),
  public.admin_accounts(text, text, int, int),
  public.admin_dashboard()
to authenticated;

-- Fonctions de déclencheur : jamais appelables directement.
revoke all on function public.audit_row(), public.stamp_subscription_revocation() from public, anon, authenticated;

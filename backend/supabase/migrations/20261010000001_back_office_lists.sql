-- Listes du back-office (#27) : abonnements, paiements et appareils avec
-- l'e-mail du compte. auth.users n'est jamais exposé par l'API : ces
-- fonctions le joignent, et seulement pour un administrateur.

create function public.admin_subscriptions(
  query text default '',
  status text default 'all',
  lim int default 25,
  off int default 0
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  plan_code text,
  plan_name text,
  starts_at timestamptz,
  valid_until timestamptz,
  state text,
  note text,
  created_at timestamptz,
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
  if status not in ('all', 'active', 'expiring', 'expired', 'revoked') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;
  return query
  with listed as (
    select s.id, s.user_id, u.email::text as email, s.plan_code, p.name as plan_name,
           s.starts_at, s.valid_until, s.note, s.created_at,
           case
             when s.status = 'revoked' then 'revoked'
             when s.valid_until <= now() then 'expired'
             when s.valid_until <= now() + interval '7 days' then 'expiring'
             else 'active'
           end as state
    from public.subscriptions s
    join auth.users u on u.id = s.user_id
    join public.plans p on p.code = s.plan_code
    where coalesce(query, '') = '' or u.email ilike '%' || query || '%'
  )
  select l.id, l.user_id, l.email, l.plan_code, l.plan_name, l.starts_at, l.valid_until,
         l.state, l.note, l.created_at, count(*) over ()
  from listed l
  where status = 'all' or l.state = status
  order by l.valid_until desc
  limit least(greatest(lim, 1), 500) offset greatest(off, 0);
end;
$$;

create function public.admin_payments(
  query text default '',
  since timestamptz default null,
  until timestamptz default null,
  lim int default 25,
  off int default 0
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  amount_fcfa int,
  method text,
  reference text,
  paid_at timestamptz,
  plan_name text,
  recorded_by_email text,
  total bigint,
  total_amount_fcfa bigint
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
  return query
  select pa.id, pa.user_id, u.email::text, pa.amount_fcfa, pa.method, pa.reference, pa.paid_at,
         pl.name, r.email::text,
         count(*) over (), sum(pa.amount_fcfa) over ()
  from public.payments pa
  join auth.users u on u.id = pa.user_id
  left join public.subscriptions s on s.id = pa.subscription_id
  left join public.plans pl on pl.code = s.plan_code
  left join auth.users r on r.id = pa.recorded_by
  where (coalesce(query, '') = '' or u.email ilike '%' || query || '%' or pa.reference ilike '%' || query || '%')
    and (since is null or pa.paid_at >= since)
    and (until is null or pa.paid_at < until)
  order by pa.paid_at desc
  limit least(greatest(lim, 1), 500) offset greatest(off, 0);
end;
$$;

create function public.admin_devices(
  query text default '',
  scope text default 'all',
  lim int default 25,
  off int default 0
)
returns table (
  id uuid,
  user_id uuid,
  email text,
  platform text,
  label text,
  integrity_level text,
  installed_from_store boolean,
  first_seen timestamptz,
  last_seen timestamptz,
  revoked_at timestamptz,
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
  if scope not in ('all', 'active', 'revoked', 'alerts') then
    raise exception 'invalid_scope' using errcode = '22023';
  end if;
  return query
  select d.id, d.user_id, u.email::text, d.platform, d.label, d.integrity_level,
         d.installed_from_store, d.first_seen, d.last_seen, d.revoked_at, count(*) over ()
  from public.devices d
  join auth.users u on u.id = d.user_id
  where (coalesce(query, '') = '' or u.email ilike '%' || query || '%')
    and case scope
          when 'active' then d.revoked_at is null
          when 'revoked' then d.revoked_at is not null
          when 'alerts' then d.revoked_at is null
                             and (d.integrity_level in ('basic', 'failed') or d.installed_from_store is false)
          else true
        end
  order by d.last_seen desc
  limit least(greatest(lim, 1), 500) offset greatest(off, 0);
end;
$$;

revoke all on function
  public.admin_subscriptions(text, text, int, int),
  public.admin_payments(text, timestamptz, timestamptz, int, int),
  public.admin_devices(text, text, int, int)
from public, anon;

grant execute on function
  public.admin_subscriptions(text, text, int, int),
  public.admin_payments(text, timestamptz, timestamptz, int, int),
  public.admin_devices(text, text, int, int)
to authenticated;

-- Suppression du compte par son titulaire, depuis l'application (#36).
-- Exigée par les boutiques pour toute application qui permet de créer un
-- compte. Le compte et ses données (profil, abonnements, appareils, licences)
-- sont supprimés ; les paiements restent au registre comptable, détachés du
-- compte, et le journal ne garde ni nom ni téléphone.

alter table public.payments alter column user_id drop not null;
alter table public.payments drop constraint payments_user_id_fkey;
alter table public.payments
  add constraint payments_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete set null;

-- Liste et export des paiements : un paiement dont le compte a été supprimé
-- reste compté (adresse vide).
create or replace function public.admin_payments(
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
  left join auth.users u on u.id = pa.user_id
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

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'forbidden';
  end if;
  -- Un administrateur est retiré par un super-administrateur, jamais par
  -- l'application (il doit toujours en rester un).
  if exists (select 1 from public.admins where user_id = uid) then
    raise exception 'admin_account';
  end if;

  update public.audit_log
     set before = before - 'display_name' - 'phone',
         after = after - 'display_name' - 'phone'
   where entity = 'accounts' and entity_id = uid::text;

  insert into public.audit_log (actor, action, entity, entity_id)
  values (uid, 'delete', 'users', uid::text);

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

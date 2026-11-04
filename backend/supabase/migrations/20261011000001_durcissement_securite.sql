-- Durcissement de sécurité du back-office (revue du 2026-10-11).

-- ─── Double facteur obligatoire pour les droits d'administration ────────────
-- Un mot de passe d'administrateur volé ne suffit plus : les droits ne
-- s'appliquent qu'à une session vérifiée par un second facteur (TOTP), que
-- Supabase signale par le claim `aal` = 'aal2' du jeton d'accès.
create function public.session_aal2()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'aal', '') = 'aal2';
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.session_aal2()
     and exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.session_aal2()
     and exists (
       select 1 from public.admins where user_id = auth.uid() and role = 'super_admin'
     );
$$;

-- admin_me() reste lisible sans second facteur : l'interface en a besoin pour
-- savoir qu'elle doit demander le code. Elle ne renvoie que le rôle de la
-- personne connectée et n'ouvre aucun droit.

-- ─── Attribution d'un rôle ──────────────────────────────────────────────────
-- 1. Seulement à une adresse confirmée : sinon n'importe qui peut s'inscrire
--    avec l'adresse d'un futur administrateur et recevoir ses droits. En
--    production, la confirmation des e-mails doit être activée (sans elle,
--    Supabase confirme toute adresse dès l'inscription).
-- 2. Verrou sur la table : deux super-administrateurs qui se rétrogradent en
--    même temps ne peuvent plus laisser l'équipe sans super-administrateur.
create or replace function public.admin_set_role(target_email text, new_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid;
  confirmed boolean;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if new_role not in ('super_admin', 'support') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;
  select id, email_confirmed_at is not null into target, confirmed
  from auth.users where lower(email) = lower(trim(target_email));
  if target is null then
    raise exception 'unknown_account' using errcode = 'P0002';
  end if;
  if not confirmed then
    raise exception 'unconfirmed_email' using errcode = 'P0001';
  end if;

  lock table public.admins in share row exclusive mode;
  if new_role <> 'super_admin'
     and exists (select 1 from public.admins where user_id = target and role = 'super_admin')
     and (select count(*) from public.admins where role = 'super_admin') = 1 then
    raise exception 'last_super_admin' using errcode = 'P0001';
  end if;
  insert into public.admins (user_id, role) values (target, new_role)
  on conflict (user_id) do update set role = excluded.role;
end;
$$;

create or replace function public.admin_remove(target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  lock table public.admins in share row exclusive mode;
  if exists (select 1 from public.admins where user_id = target and role = 'super_admin')
     and (select count(*) from public.admins where role = 'super_admin') = 1 then
    raise exception 'last_super_admin' using errcode = 'P0001';
  end if;
  delete from public.admins where user_id = target;
end;
$$;

-- ─── Surface d'attaque ──────────────────────────────────────────────────────
-- Ancienne recherche de l'ancien panneau : annoncée comme retirée par
-- 20261008000001_back_office.sql mais jamais supprimée, toujours appelable.
drop function public.admin_search_account(text);

-- ─── Droits d'exécution ─────────────────────────────────────────────────────
-- `create or replace` conserve les droits existants ; la nouvelle fonction
-- reçoit ceux de Supabase par défaut, qu'on restreint comme les autres.
revoke all on function public.session_aal2() from public, anon;
grant execute on function public.session_aal2() to authenticated;

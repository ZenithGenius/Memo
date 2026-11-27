-- Tests du durcissement de sécurité (20261011000001) : double facteur,
-- adresse confirmée, dernier super-administrateur. Exécution :
--   docker exec -i "$SUPABASE_DB_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 < backend/tests/securite.sql
-- Tout est annulé à la fin (rollback).
begin;

create function pg_temp.as_user(uid uuid, aal text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal, 'amr', json_build_array(json_build_object('method', 'totp', 'timestamp', extract(epoch from now())::bigint)))::text, true);
  execute 'set local role authenticated';
end $$;

create function pg_temp.as_service() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;

create function pg_temp.expect_error(sql text, needle text) returns void language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    if sqlerrm like '%' || needle || '%' then return; end if;
    raise exception 'erreur inattendue: % (attendu: %)', sqlerrm, needle;
  end;
  raise exception 'aucune erreur alors que "%" était attendu', needle;
end $$;

create function pg_temp.assert_eq(actual anyelement, expected anyelement, label text) returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'ECHEC %: obtenu %, attendu %', label, actual, expected;
  end if;
  raise notice 'OK %', label;
end $$;

-- Un super-admin, un client, et une personne qui a pris l'adresse d'un futur
-- collègue sans jamais la confirmer.
insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'super@test.local', now()),
  ('00000000-0000-0000-0000-0000000000c1', 'client@test.local', now()),
  ('00000000-0000-0000-0000-0000000000e1', 'futur.collegue@test.local', null);
delete from public.admins;
insert into public.admins (user_id, role) values ('00000000-0000-0000-0000-0000000000a1', 'super_admin');

-- ─── Double facteur ────────────────────────────────────────────────────────
-- Mot de passe seul (aal1) : le rôle est lisible, aucun droit n'est ouvert.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select pg_temp.assert_eq(public.admin_me(), 'super_admin', 'rôle lisible sans second facteur');
select pg_temp.assert_eq(public.is_admin(), false, 'pas de droits d''administrateur en aal1');
select pg_temp.expect_error($q$select public.admin_dashboard()$q$, 'forbidden');
select pg_temp.expect_error($q$select * from public.admin_accounts()$q$, 'forbidden');
select pg_temp.expect_error(
  $q$select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c1', 'essentiel',
     now() + interval '30 days', 1000, 'mtn_momo')$q$, 'forbidden');
select pg_temp.expect_error(
  $q$insert into public.subscriptions (user_id, plan_code, valid_until)
     values ('00000000-0000-0000-0000-0000000000c1', 'essentiel', now() + interval '30 days')$q$,
  'row-level security');
select pg_temp.assert_eq((select count(*) from public.audit_log), 0::bigint, 'journal fermé en aal1');
select pg_temp.assert_eq(
  (select count(*) from public.accounts where user_id <> '00000000-0000-0000-0000-0000000000a1'), 0::bigint,
  'comptes des autres fermés en aal1');

-- Jeton sans claim aal (ancien ou forgé) : traité comme aal1.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select pg_temp.assert_eq(public.is_super_admin(), false, 'claim aal absent : pas de droits');

-- Avec le second facteur (aal2) : droits ouverts.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.assert_eq(public.is_super_admin(), true, 'droits ouverts en aal2');
select pg_temp.assert_eq((public.admin_dashboard() ? 'accounts_total'), true, 'tableau de bord lisible en aal2');

-- Session de plus de 24 heures (second facteur vérifié il y a 25 h) : droits fermés.
select set_config('request.jwt.claims', json_build_object(
  'sub', '00000000-0000-0000-0000-0000000000a1', 'role', 'authenticated', 'aal', 'aal2',
  'amr', json_build_array(json_build_object('method', 'totp',
    'timestamp', extract(epoch from now() - interval '25 hours')::bigint)))::text, true);
select pg_temp.assert_eq(public.is_super_admin(), false, 'session de plus de 24 h : pas de droits');
select pg_temp.assert_eq(public.is_admin(), false, 'session de plus de 24 h : pas administrateur');
-- aal2 sans horodatage du second facteur : droits fermés.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated","aal":"aal2"}', true);
select pg_temp.assert_eq(public.is_super_admin(), false, 'aal2 sans horodatage : pas de droits');
-- Vérifié il y a 23 h : encore valable.
select set_config('request.jwt.claims', json_build_object(
  'sub', '00000000-0000-0000-0000-0000000000a1', 'role', 'authenticated', 'aal', 'aal2',
  'amr', json_build_array(json_build_object('method', 'totp',
    'timestamp', extract(epoch from now() - interval '23 hours')::bigint)))::text, true);
select pg_temp.assert_eq(public.is_super_admin(), true, 'session de 23 h : droits ouverts');

-- Un client reste chez lui, avec ou sans second facteur.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1', 'aal2');
select pg_temp.assert_eq(public.is_admin(), false, 'un client en aal2 n''est pas administrateur');
select pg_temp.assert_eq(
  (select count(*) from public.accounts where user_id = '00000000-0000-0000-0000-0000000000c1'), 1::bigint,
  'un client lit toujours sa fiche');

-- ─── Attribution d'un rôle ─────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.expect_error(
  $q$select public.admin_set_role('futur.collegue@test.local', 'super_admin')$q$, 'unconfirmed_email');
select pg_temp.expect_error($q$select public.admin_set_role('client@test.local', 'root')$q$, 'invalid_role');
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select count(*) from public.admins where user_id = '00000000-0000-0000-0000-0000000000e1'), 0::bigint,
  'adresse non confirmée : aucun rôle attribué');

-- Le dernier super-administrateur ne peut toujours pas se retirer.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.expect_error($q$select public.admin_remove('00000000-0000-0000-0000-0000000000a1')$q$, 'last_super_admin');
select public.admin_set_role('client@test.local', 'support');
select pg_temp.assert_eq((select count(*) from public.admin_list()), 2::bigint, 'adresse confirmée : rôle attribué');

-- ─── Surface d'attaque ─────────────────────────────────────────────────────
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select count(*) from pg_proc where proname = 'admin_search_account'), 0::bigint,
  'ancienne recherche supprimée');
set local role anon;
select pg_temp.expect_error($q$select public.session_aal2()$q$, 'permission denied');
reset role;

rollback;

-- Tests du schéma de licence. Exécution :
--   docker exec -i "$SUPABASE_DB_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 < backend/tests/licence_rls.sql
-- (conteneur : supabase_db_<project_id de config.toml>)
-- Tout est annulé à la fin (rollback).
begin;

create function pg_temp.as_user(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

create function pg_temp.as_service() returns void language plpgsql as $$
begin
  execute 'reset role';
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

create function pg_temp.assert_eq(actual bigint, expected bigint, label text) returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'ECHEC %: obtenu %, attendu %', label, actual, expected;
  end if;
  raise notice 'OK %', label;
end $$;

-- Jeu de données : deux abonnés et un administrateur.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.local'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.local'),
  ('00000000-0000-0000-0000-0000000000ad', 'admin@test.local');
insert into public.admins values ('00000000-0000-0000-0000-0000000000ad');

select pg_temp.assert_eq(
  (select count(*) from public.accounts where user_id in (
    '00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000b',
    '00000000-0000-0000-0000-0000000000ad')), 3, 'fiche compte créée à l''inscription');

-- Un abonné ne peut pas s'activer lui-même.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect_error(
  $q$insert into public.subscriptions (user_id, plan_code, valid_until)
     values ('00000000-0000-0000-0000-00000000000a', 'essentiel', now() + interval '30 days')$q$,
  'row-level security');
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select count(*) from public.subscriptions where user_id = '00000000-0000-0000-0000-00000000000a'), 0,
  'auto-activation refusée');

-- L'administrateur active A.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000ad');
insert into public.subscriptions (user_id, plan_code, valid_until, activated_by)
values ('00000000-0000-0000-0000-00000000000a', 'essentiel', now() + interval '30 days',
        '00000000-0000-0000-0000-0000000000ad');
select pg_temp.assert_eq(
  (select count(*) from public.subscriptions where user_id = '00000000-0000-0000-0000-00000000000a'), 1,
  'administrateur peut activer');

-- A voit son abonnement, B ne voit rien.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.assert_eq((select count(*) from public.subscriptions), 1, 'A voit son abonnement (uniquement le sien)');
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.assert_eq((select count(*) from public.subscriptions), 0, 'B ne voit pas celui de A');
select pg_temp.assert_eq((select count(*) from public.accounts), 1, 'B ne voit que sa fiche');

-- Un abonné ne peut pas créer ni modifier un appareil (fonction serveur uniquement).
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect_error(
  $q$insert into public.devices (user_id, fingerprint, platform)
     values ('00000000-0000-0000-0000-00000000000a', 'fp-x', 'android')$q$,
  'permission denied');
select pg_temp.as_service();

-- Limite d'appareils : B sans abonnement = 1 appareil.
insert into public.devices (user_id, fingerprint, platform)
values ('00000000-0000-0000-0000-00000000000b', 'b1', 'android');
select pg_temp.expect_error(
  $q$insert into public.devices (user_id, fingerprint, platform)
     values ('00000000-0000-0000-0000-00000000000b', 'b2', 'android')$q$,
  'device_limit_reached');

-- A abonné (offre essentiel) = 2 appareils, pas 3.
insert into public.devices (user_id, fingerprint, platform) values
  ('00000000-0000-0000-0000-00000000000a', 'a1', 'android'),
  ('00000000-0000-0000-0000-00000000000a', 'a2', 'ios');
select pg_temp.expect_error(
  $q$insert into public.devices (user_id, fingerprint, platform)
     values ('00000000-0000-0000-0000-00000000000a', 'a3', 'android')$q$,
  'device_limit_reached');

-- Révoquer un appareil libère une place.
update public.devices set revoked_at = now()
where user_id = '00000000-0000-0000-0000-00000000000a' and fingerprint = 'a1';
insert into public.devices (user_id, fingerprint, platform)
values ('00000000-0000-0000-0000-00000000000a', 'a3', 'android');
select pg_temp.assert_eq(
  (select count(*) from public.devices
   where user_id = '00000000-0000-0000-0000-00000000000a' and revoked_at is null), 2,
  'révocation libère une place');

-- Un abonnement expiré ne donne plus droit à deux appareils.
update public.subscriptions set valid_until = now() - interval '1 day',
  starts_at = now() - interval '31 days';
update public.devices set revoked_at = now()
where user_id = '00000000-0000-0000-0000-00000000000a';
insert into public.devices (user_id, fingerprint, platform)
values ('00000000-0000-0000-0000-00000000000a', 'a4', 'android');
select pg_temp.expect_error(
  $q$insert into public.devices (user_id, fingerprint, platform)
     values ('00000000-0000-0000-0000-00000000000a', 'a5', 'android')$q$,
  'device_limit_reached');

-- Anonyme : lit les offres, rien d'autre.
reset role;
set local role anon;
select pg_temp.assert_eq((select count(*) from public.plans), 4, 'anonyme lit les offres');
select pg_temp.expect_error('select count(*) from public.accounts', 'permission denied');
select pg_temp.expect_error('select count(*) from public.subscriptions', 'permission denied');

reset role;
rollback;
\echo 'TOUS LES TESTS SQL PASSENT'

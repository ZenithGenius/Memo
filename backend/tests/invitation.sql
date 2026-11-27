-- Tests de l'invitation d'un administrateur (20261122000001).
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

insert into auth.users (id, email, email_confirmed_at, invited_at, created_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'super@test.local', now(), null, now()),
  ('00000000-0000-0000-0000-0000000000b1', 'support@test.local', now(), null, now()),
  ('00000000-0000-0000-0000-0000000000d1', 'invitee@test.local', null, now(), now()),
  ('00000000-0000-0000-0000-0000000000e1', 'inscrit@test.local', null, null, now()),
  ('00000000-0000-0000-0000-0000000000f1', 'accepte@test.local', now(), now(), now()),
  -- Inscrit d'avance (non confirmé) puis invité : pré-détournement.
  ('00000000-0000-0000-0000-000000000011', 'piege@test.local', null, now(), now() - interval '2 days');
-- Inscrit pendant l'invitation (même instant), avec son mot de passe.
insert into auth.users (id, email, email_confirmed_at, invited_at, created_at, encrypted_password) values
  ('00000000-0000-0000-0000-000000000012', 'course@test.local', null, now(), now(), '$2a$10$hachedemotdepasse');
delete from public.admins;
insert into public.admins (user_id, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'super_admin'),
  ('00000000-0000-0000-0000-0000000000b1', 'support');

-- Seul un super-administrateur avec second facteur invite.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1', 'aal2');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000d1', 'support')$q$, 'forbidden');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000d1', 'support')$q$, 'forbidden');
select pg_temp.as_service();
set local role anon;
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000d1', 'support')$q$, 'permission denied');
reset role;

-- Seulement un compte invité jamais confirmé : pas une inscription libre
-- non confirmée (adresse d'un autre), ni un compte déjà en service.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000e1', 'support')$q$, 'not_invited');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000f1', 'support')$q$, 'not_invited');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-000000000011', 'support')$q$, 'not_invited');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-000000000012', 'support')$q$, 'not_invited');
select pg_temp.expect_error($q$select public.admin_grant_invited('00000000-0000-0000-0000-0000000000d1', 'owner')$q$, 'invalid_role');

select public.admin_grant_invited('00000000-0000-0000-0000-0000000000d1', 'support');
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select role from public.admins where user_id = '00000000-0000-0000-0000-0000000000d1'), 'support', 'rôle attribué à l''invité');
select pg_temp.assert_eq(
  (select actor from public.audit_log where entity = 'admins' and action = 'insert'
     and after ->> 'user_id' = '00000000-0000-0000-0000-0000000000d1'),
  '00000000-0000-0000-0000-0000000000a1'::uuid, 'invitation tracée au nom du super-administrateur');

-- Recherche d'un compte : fonction serveur seulement.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.expect_error($q$select public.auth_account_exists('piege@test.local')$q$, 'permission denied');
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.auth_account_exists(' Piege@Test.local '), true, 'compte existant trouvé, casse et espaces ignorés');
select pg_temp.assert_eq(public.auth_account_exists('inconnu@test.local'), false, 'adresse sans compte');
reset role;

rollback;

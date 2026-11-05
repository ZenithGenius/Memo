-- Tests de la trace des réinitialisations de mot de passe (20261105000002).
-- Tout est annulé à la fin (rollback).
begin;

create function pg_temp.as_user(uid uuid, aal text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal)::text, true);
  execute 'set local role authenticated';
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

insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'super@test.local', now()),
  ('00000000-0000-0000-0000-0000000000b1', 'support@test.local', now()),
  ('00000000-0000-0000-0000-0000000000c1', 'clarisse@test.local', now());
delete from public.admins;
insert into public.admins (user_id, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'super_admin'),
  ('00000000-0000-0000-0000-0000000000b1', 'support');

-- Support en lecture seule, ou super-administrateur sans second facteur : refusé.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1', 'aal2');
select pg_temp.expect_error($q$select public.admin_log_password_reset('00000000-0000-0000-0000-0000000000c1')$q$, 'forbidden');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select pg_temp.expect_error($q$select public.admin_log_password_reset('00000000-0000-0000-0000-0000000000c1')$q$, 'forbidden');

-- Super-administrateur : adresse renvoyée pour l'envoi, demande tracée.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal2');
select pg_temp.assert_eq(
  public.admin_log_password_reset('00000000-0000-0000-0000-0000000000c1'),
  'clarisse@test.local', 'adresse du compte renvoyée');
select pg_temp.expect_error($q$select public.admin_log_password_reset('00000000-0000-0000-0000-0000000000ff')$q$, 'not_found');
reset role;
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where action = 'password_reset' and entity = 'users'
      and entity_id = '00000000-0000-0000-0000-0000000000c1'
      and actor = '00000000-0000-0000-0000-0000000000a1'),
  1::bigint, 'demande tracée avec son auteur');

select pg_temp.assert_eq(has_function_privilege('anon', 'public.admin_log_password_reset(uuid)', 'execute'), false, 'anon ne peut pas appeler la fonction');

rollback;

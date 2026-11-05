-- Tests de la suppression du compte par son titulaire (20261105000001).
-- Tout est annulé à la fin (rollback).
begin;

create function pg_temp.as_user(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated', 'aal', 'aal1')::text, true);
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

insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'admin@test.local', now()),
  ('00000000-0000-0000-0000-0000000000c1', 'clarisse@test.local', now()),
  ('00000000-0000-0000-0000-0000000000c2', 'autre@test.local', now());
delete from public.admins;
insert into public.admins (user_id, role) values ('00000000-0000-0000-0000-0000000000a1', 'super_admin');
-- Le compte est créé avec l'utilisateur ; chaque modification est journalisée.
update public.accounts set display_name = 'Clarisse', phone = '+237600000000'
 where user_id = '00000000-0000-0000-0000-0000000000c1';
update public.accounts set phone = '+237611111111' where user_id = '00000000-0000-0000-0000-0000000000c1';
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where entity = 'accounts'
      and entity_id = '00000000-0000-0000-0000-0000000000c1' and after ? 'phone'),
  2::bigint, 'téléphone présent dans le journal avant suppression');
insert into public.subscriptions (id, user_id, plan_code, valid_until) values
  ('00000000-0000-0000-0000-00000000005b', '00000000-0000-0000-0000-0000000000c1', 'essentiel', now() + interval '30 days');
insert into public.payments (user_id, subscription_id, amount_fcfa, method) values
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000005b', 1000, 'mtn_momo');

-- Sans session : refusé.
select pg_temp.as_user(null);
select pg_temp.expect_error($q$select public.delete_my_account()$q$, 'forbidden');

-- Un administrateur ne se supprime pas depuis l'application.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.expect_error($q$select public.delete_my_account()$q$, 'admin_account');

-- La titulaire supprime son compte.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select public.delete_my_account();
select pg_temp.as_service();

select pg_temp.assert_eq((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000c1'), 0::bigint, 'compte supprimé');
select pg_temp.assert_eq((select count(*) from public.accounts where user_id = '00000000-0000-0000-0000-0000000000c1'), 0::bigint, 'profil de compte supprimé');
select pg_temp.assert_eq((select count(*) from public.subscriptions where user_id = '00000000-0000-0000-0000-0000000000c1'), 0::bigint, 'abonnements supprimés');
select pg_temp.assert_eq((select count(*) from public.payments where amount_fcfa = 1000 and user_id is null), 1::bigint, 'paiement conservé, détaché du compte');
select pg_temp.assert_eq(
  (select count(*) from public.audit_log
    where entity = 'accounts' and entity_id = '00000000-0000-0000-0000-0000000000c1'
      and (before ? 'phone' or after ? 'phone' or before ? 'display_name' or after ? 'display_name')),
  0::bigint, 'journal sans nom ni téléphone');
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where entity = 'users' and action = 'delete'
      and entity_id = '00000000-0000-0000-0000-0000000000c1'),
  1::bigint, 'suppression tracée');
select pg_temp.assert_eq((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000c2'), 1::bigint, 'autres comptes intacts');

-- Le paiement reste dans la liste et les totaux du back-office.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select set_config('request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-0000000000a1', 'role', 'authenticated', 'aal', 'aal2')::text, true);
select pg_temp.assert_eq(
  (select count(*) from public.admin_payments() where amount_fcfa = 1000 and email is null),
  1::bigint, 'paiement d''un compte supprimé listé au back-office');
select pg_temp.as_service();

-- Anonyme : aucun droit d'exécution.
select pg_temp.assert_eq(has_function_privilege('anon', 'public.delete_my_account()', 'execute'), false, 'anon ne peut pas appeler la fonction');

rollback;

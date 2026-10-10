-- Tests du back-office : rôles, paiements, audit, tableau de bord. Exécution :
--   docker exec -i "$SUPABASE_DB_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 < backend/tests/back_office.sql
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

-- Jeu de données : un super-admin, un support, deux abonnés potentiels.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'super@test.local'),
  ('00000000-0000-0000-0000-0000000000a2', 'support@test.local'),
  ('00000000-0000-0000-0000-0000000000c1', 'client1@test.local'),
  ('00000000-0000-0000-0000-0000000000c2', 'client2@test.local');
-- Isole le test des administrateurs déjà présents en local.
delete from public.admins;
insert into public.admins (user_id, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'super_admin'),
  ('00000000-0000-0000-0000-0000000000a2', 'support');

-- ─── Rôles ─────────────────────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a2');
select pg_temp.assert_eq(public.admin_me(), 'support', 'rôle support lu');
select pg_temp.expect_error(
  $q$select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c1', 'essentiel',
     now() + interval '30 days', 1000, 'mtn_momo')$q$, 'forbidden');
select pg_temp.expect_error(
  $q$insert into public.subscriptions (user_id, plan_code, valid_until)
     values ('00000000-0000-0000-0000-0000000000c1', 'essentiel', now() + interval '30 days')$q$,
  'row-level security');
-- Une mise à jour refusée par la sécurité par ligne ne lève pas d'erreur :
-- elle ne touche aucune ligne.
update public.plans set price_fcfa = 1 where code = 'essentiel';
select pg_temp.as_service();
select pg_temp.assert_eq((select price_fcfa from public.plans where code = 'essentiel'), 1000, 'support ne modifie pas les offres');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a2');
select pg_temp.expect_error($q$select public.admin_set_role('client1@test.local', 'support')$q$, 'forbidden');
select pg_temp.assert_eq((select count(*) from public.audit_log) >= 0, true, 'support lit le journal');

-- Un compte non administrateur n'accède à rien.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select pg_temp.expect_error($q$select public.admin_dashboard()$q$, 'forbidden');
select pg_temp.expect_error($q$select * from public.admin_accounts()$q$, 'forbidden');
select pg_temp.assert_eq((select count(*) from public.audit_log), 0::bigint, 'un client ne voit pas le journal');
select pg_temp.assert_eq((select count(*) from public.payments), 0::bigint, 'un client ne voit pas les paiements');

-- ─── Activation atomique ──────────────────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c1', 'essentiel',
  now() + interval '30 days', 1000, 'mtn_momo', ' MP2610.0001 ', 'payé au guichet');
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select activated_by from public.subscriptions where user_id = '00000000-0000-0000-0000-0000000000c1'),
  '00000000-0000-0000-0000-0000000000a1'::uuid, 'auteur de l''activation pris dans la session');
select pg_temp.assert_eq(
  (select reference from public.payments where user_id = '00000000-0000-0000-0000-0000000000c1'),
  'MP2610.0001', 'paiement enregistré avec la même transaction, référence nettoyée');
select pg_temp.assert_eq(
  (select subscription_id is not null from public.payments where user_id = '00000000-0000-0000-0000-0000000000c1'),
  true, 'paiement rattaché à l''abonnement');

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.expect_error(
  $q$select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c2', 'essentiel',
     now() - interval '1 day', 1000, 'especes')$q$, 'invalid_until');
select pg_temp.expect_error(
  $q$select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c2', 'essentiel',
     now() + interval '30 days', 1000, 'bitcoin')$q$, 'payments_method_check');
-- Le registre des paiements est en ajout seul.
select pg_temp.expect_error($q$update public.payments set amount_fcfa = 0$q$, 'permission denied');
select pg_temp.expect_error($q$delete from public.payments$q$, 'permission denied');

-- ─── Résiliation datée et journal d'audit ─────────────────────────────────
update public.subscriptions set status = 'revoked' where user_id = '00000000-0000-0000-0000-0000000000c1';
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select revoked_by from public.subscriptions where user_id = '00000000-0000-0000-0000-0000000000c1'),
  '00000000-0000-0000-0000-0000000000a1'::uuid, 'résiliation datée et attribuée');
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where entity = 'subscriptions' and action = 'update'
     and actor = '00000000-0000-0000-0000-0000000000a1'), 1::bigint, 'résiliation tracée dans le journal');
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where entity = 'payments' and action = 'insert'), 1::bigint,
  'paiement tracé dans le journal');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.expect_error($q$delete from public.audit_log$q$, 'permission denied');
select pg_temp.expect_error($q$update public.audit_log set actor = null$q$, 'permission denied');

-- ─── Administrateurs ───────────────────────────────────────────────────────
select pg_temp.expect_error($q$select public.admin_remove('00000000-0000-0000-0000-0000000000a1')$q$, 'last_super_admin');
select pg_temp.expect_error($q$select public.admin_set_role('super@test.local', 'support')$q$, 'last_super_admin');
select pg_temp.expect_error($q$select public.admin_set_role('inconnu@test.local', 'support')$q$, 'unknown_account');
select public.admin_set_role('client2@test.local', 'support');
select pg_temp.assert_eq((select count(*) from public.admin_list()), 3::bigint, 'nouvel administrateur ajouté');
select public.admin_remove('00000000-0000-0000-0000-0000000000c2');
select pg_temp.assert_eq((select count(*) from public.admin_list()), 2::bigint, 'administrateur retiré');

-- ─── Lecture : comptes et tableau de bord ─────────────────────────────────
select public.admin_activate_subscription('00000000-0000-0000-0000-0000000000c2', 'famille',
  now() + interval '3 days', 2000, 'orange_money');
select pg_temp.assert_eq(
  (select situation from public.admin_accounts('client2@test.local')), 'expiring', 'abonnement qui expire sous 7 jours');
select pg_temp.assert_eq(
  (select situation from public.admin_accounts('client1@test.local')), 'expired', 'abonnement résilié');
select pg_temp.assert_eq(
  (select count(*) from public.admin_accounts('test.local', 'expiring')), 1::bigint, 'filtre par situation');
select pg_temp.expect_error($q$select * from public.admin_accounts('', 'nimporte')$q$, 'invalid_status');
select pg_temp.assert_eq(
  (public.admin_dashboard() ->> 'revenue_this_month_fcfa')::int >= 3000, true, 'revenus encaissés du mois');
select pg_temp.assert_eq(
  (public.admin_dashboard() ->> 'expiring_7_days')::int >= 1, true, 'expirations à relancer');
select pg_temp.assert_eq(
  jsonb_array_length(public.admin_dashboard() -> 'revenue_by_month'), 12, 'revenus sur 12 mois');
select pg_temp.assert_eq(
  jsonb_array_length(public.admin_dashboard() -> 'retention'), 3, 'rétention à 3, 6 et 12 mois');

-- Anonyme : aucune fonction d'administration.
select pg_temp.as_service();
set local role anon;
select pg_temp.expect_error($q$select public.admin_dashboard()$q$, 'permission denied');
reset role;

rollback;

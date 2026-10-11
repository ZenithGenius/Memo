-- Tests du contenu en base (20261011000002, 20261011000003) : droits,
-- validation, publication, images. Exécution :
--   docker exec -i "$SUPABASE_DB_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 < backend/tests/contenu.sql
-- Tout est annulé à la fin (rollback).
begin;

create function pg_temp.as_user(uid uuid, aal text default 'aal2') returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated', 'aal', aal)::text, true);
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

-- Pictogramme valide à compléter par chaque test.
create function pg_temp.new_pictogram(code text, sort_order int, level int) returns text language sql as $$
  select format(
    $f$insert into public.content_pictograms (code, category_code, level, audience, sort_order, labels)
       values (%L, split_part(%L, '-', 3), %s, 'all', %s,
               '{"fr": {"label": "Sauter", "spoken": "sauter"}, "en": {"label": "Jump", "spoken": "jump"}}')$f$,
    code, code, level, sort_order);
$$;

insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'super@test.local', now()),
  ('00000000-0000-0000-0000-0000000000a2', 'support@test.local', now()),
  ('00000000-0000-0000-0000-0000000000c1', 'client@test.local', now());
delete from public.admins;
insert into public.admins (user_id, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'super_admin'),
  ('00000000-0000-0000-0000-0000000000a2', 'support');

-- ─── Import initial ────────────────────────────────────────────────────────
select pg_temp.assert_eq((select count(*) from public.content_pictograms), 131::bigint, '131 pictogrammes importés');
select pg_temp.assert_eq((select max(version) from public.content_releases), 5, 'publication 5 = ancien pack.json');
select pg_temp.assert_eq(
  public.content_build_pack(5) = (select pack from public.content_releases where version = 5), true,
  'le paquet reconstruit depuis la base est identique à l''ancien pack.json');

-- ─── Droits ────────────────────────────────────────────────────────────────
-- Client (même avec un second facteur) : rien.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select pg_temp.assert_eq((select count(*) from public.content_pictograms), 0::bigint, 'un client ne lit pas le catalogue');
select pg_temp.assert_eq((select count(*) from public.content_releases), 0::bigint, 'un client ne lit pas les publications');
select pg_temp.expect_error($q$select * from public.content_images$q$, 'permission denied');
select pg_temp.expect_error($q$select public.content_latest_pack()$q$, 'permission denied');
select pg_temp.expect_error($q$select * from public.content_published_image('00')$q$, 'permission denied');
select pg_temp.expect_error($q$select * from public.admin_image('00')$q$, 'forbidden');

-- Support : lecture seule.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a2');
select pg_temp.assert_eq((select count(*) from public.content_pictograms), 131::bigint, 'le support lit le catalogue');
select pg_temp.expect_error(pg_temp.new_pictogram('CAA-CR-ACT-026', 26, 2), 'row-level security');
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'forbidden');
select pg_temp.expect_error($q$select public.admin_put_image('aaaa', 'image/png')$q$, 'forbidden');

-- Super-administrateur sans second facteur : refusé.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1', 'aal1');
select pg_temp.expect_error(pg_temp.new_pictogram('CAA-CR-ACT-026', 26, 2), 'row-level security');

-- Anonyme : rien.
select pg_temp.as_service();
set local role anon;
select pg_temp.expect_error($q$select * from public.content_pictograms$q$, 'permission denied');
reset role;

-- ─── Validation (ce que l'application exige) ───────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.expect_error(
  $q$insert into public.content_pictograms (code, category_code, level, audience, sort_order, labels)
     values ('CAA-CR-ACT-026', 'ACT', 2, 'robot', 26,
             '{"fr": {"label": "a", "spoken": "a"}, "en": {"label": "a", "spoken": "a"}}')$q$,
  'content_pictograms_audience_check');
select pg_temp.expect_error(
  $q$insert into public.content_pictograms (code, category_code, level, audience, sort_order, labels)
     values ('CAA-CR-ACT-026', 'ACT', 2, 'all', 26, '{"fr": {"label": "a", "spoken": "a"}}')$q$,
  'content_pictograms_labels_check');
select pg_temp.expect_error(
  $q$insert into public.content_pictograms (code, category_code, level, audience, sort_order, labels)
     values ('CAA-CR-ACT-026', 'ACT', 2, 'all', 26,
             '{"fr": {"label": "", "spoken": "a"}, "en": {"label": "a", "spoken": "a"}}')$q$,
  'content_pictograms_labels_check');
select pg_temp.expect_error(
  $q$insert into public.content_pictograms (code, category_code, level, audience, sort_order, labels)
     values ('CAA-CR-ALI-099', 'ACT', 2, 'all', 26,
             '{"fr": {"label": "a", "spoken": "a"}, "en": {"label": "a", "spoken": "a"}}')$q$,
  'content_pictograms_check');
select pg_temp.expect_error(pg_temp.new_pictogram('CAA-CR-ACT-026', 25, 2), 'content_pictograms_category_code_sort_order_key');
select pg_temp.expect_error(
  $q$insert into public.content_categories (code, sort_order, icon, color, labels)
     values ('JEU', 9, 'hand', '#FFFF00', '{"fr": "Jeux", "en": "Games"}')$q$,
  'content_categories_color_check');
select pg_temp.expect_error(
  $q$insert into public.content_categories (code, sort_order, icon, color, labels)
     values ('JEU', 9, 'rocket', '#2F7D4F', '{"fr": "Jeux", "en": "Games"}')$q$,
  'content_categories_icon_check');

-- ─── Publication ───────────────────────────────────────────────────────────
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'nothing_to_publish');

select pg_temp.as_service();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
do $$ begin execute pg_temp.new_pictogram('CAA-CR-ACT-026', 26, 2); end $$;
select pg_temp.assert_eq(public.admin_publish_content('Sauter'), 6, 'publication 6');
select pg_temp.assert_eq(
  (select pictogram_count from public.content_releases where version = 6), 132, 'nouveau pictogramme publié');
select pg_temp.assert_eq(
  (select published_by from public.content_releases where version = 6),
  '00000000-0000-0000-0000-0000000000a1'::uuid, 'auteur de la publication pris dans la session');
select pg_temp.assert_eq(
  (select count(*) from public.audit_log where entity = 'content_pictograms' and entity_id = 'CAA-CR-ACT-026'),
  1::bigint, 'ajout tracé dans le journal');

-- Position stable : un mot de niveau 0 placé après des mots de niveau 2.
do $$ begin execute pg_temp.new_pictogram('CAA-CR-ACT-027', 27, 0); end $$;
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'level_order: CAA-CR-ACT-027');
delete from public.content_pictograms where code = 'CAA-CR-ACT-027';
select pg_temp.assert_eq(
  (select count(*) from public.content_pictograms where code = 'CAA-CR-ACT-027'), 0::bigint,
  'un brouillon jamais publié se supprime');
-- Un pictogramme publié ne se supprime pas (favoris, tableaux) : il se retire.
delete from public.content_pictograms where code = 'CAA-CR-ACT-026';
select pg_temp.assert_eq(
  (select count(*) from public.content_pictograms where code = 'CAA-CR-ACT-026'), 1::bigint,
  'un pictogramme publié ne se supprime pas');
update public.content_pictograms set active = false where code = 'CAA-CR-ACT-026';
select pg_temp.assert_eq(public.admin_publish_content(), 7, 'retrait publié');
select pg_temp.assert_eq(
  jsonb_path_exists((select pack from public.content_releases where version = 7), '$.pictograms[*] ? (@.code == "CAA-CR-ACT-026")'),
  false, 'pictogramme retiré absent du paquet');

-- Les publications sont immuables.
select pg_temp.expect_error($q$update public.content_releases set notes = 'x'$q$, 'permission denied');
select pg_temp.expect_error($q$delete from public.content_releases$q$, 'permission denied');

-- ─── Images ────────────────────────────────────────────────────────────────
select pg_temp.expect_error($q$select public.admin_put_image('PHN2Zz48L3N2Zz4=', 'image/svg+xml')$q$, 'invalid_image');
-- Octets qui ne sont pas un PNG, annoncés comme PNG.
select pg_temp.expect_error($q$select public.admin_put_image('aGVsbG8gd29ybGQ=', 'image/png')$q$, 'invalid_image');
select pg_temp.expect_error($q$select public.admin_put_image('***', 'image/png')$q$, 'invalid_image');

create temporary table png (sha text);
grant select on png to public;
insert into png select public.admin_put_image(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'image/png');
select pg_temp.assert_eq((select char_length(sha) from png), 64, 'image PNG acceptée, empreinte SHA-256');
select pg_temp.assert_eq(
  public.admin_put_image('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'image/png'),
  (select sha from png), 'même image : même empreinte, stockée une fois');
select pg_temp.assert_eq((select mime from public.admin_image((select sha from png))), 'image/png', 'aperçu de l''image');

-- Envoyée mais pas publiée : la fonction serveur ne la sert pas.
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(
  (select count(*) from public.content_published_image((select sha from png))), 0::bigint,
  'image non publiée jamais servie');
reset role;

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
update public.content_pictograms set image_sha256 = (select sha from png) where code = 'CAA-CR-ACT-001';
select pg_temp.assert_eq(public.admin_publish_content('Nouvelle image'), 8, 'image publiée');
select pg_temp.assert_eq(
  (select pack #>> '{pictograms,0,imageObject,sha256}' from public.content_releases where version = 8),
  (select sha from png), 'empreinte de l''image dans le paquet');

select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(
  (select count(*) from public.content_published_image((select sha from png))), 1::bigint,
  'image publiée servie');
select pg_temp.assert_eq((public.content_latest_pack() ->> 'version')::int, 8, 'dernière publication servie');
reset role;

rollback;

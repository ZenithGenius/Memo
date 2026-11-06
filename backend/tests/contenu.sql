-- Tests du contenu en base (20261011000002, 20261011000003, 20261107000001,
-- 20261107000002) : droits,
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
select pg_temp.assert_eq((select count(*) from public.content_pictograms where tier = 'premium'), 131::bigint, '131 pictogrammes payants importés');
select pg_temp.assert_eq((select count(*) from public.content_pictograms where tier = 'free'), 20::bigint, '20 mots gratuits importés (#41)');
select pg_temp.assert_eq((select max(version) from public.content_releases), 5, 'publication 5 = ancien pack.json');
select pg_temp.assert_eq(
  jsonb_path_query_array(public.content_build_pack(5), '$.pictograms[*] ? (@.tier == "premium")')
    = (select pack -> 'pictograms' from public.content_releases where version = 5), true,
  'les mots payants reconstruits depuis la base sont identiques à l''ancien pack.json');

-- ─── Droits ────────────────────────────────────────────────────────────────
-- Client (même avec un second facteur) : rien.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select pg_temp.assert_eq((select count(*) from public.content_pictograms), 0::bigint, 'un client ne lit pas le catalogue');
select pg_temp.assert_eq((select count(*) from public.content_releases), 0::bigint, 'un client ne lit pas les publications');
select pg_temp.expect_error($q$select * from public.content_images$q$, 'permission denied');
select pg_temp.expect_error($q$select public.content_latest_pack()$q$, 'permission denied');
select pg_temp.expect_error($q$select public.content_published_image('00')$q$, 'permission denied');
select pg_temp.expect_error($q$select public.admin_register_image(repeat('a', 64), 'image/png')$q$, 'forbidden');
select pg_temp.assert_eq((select count(*) from storage.objects), 0::bigint, 'un client ne voit aucune image');

-- Support : lecture seule.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a2');
select pg_temp.assert_eq((select count(*) from public.content_pictograms), 151::bigint, 'le support lit le catalogue');
select pg_temp.expect_error(pg_temp.new_pictogram('CAA-CR-ACT-026', 26, 2), 'row-level security');
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'forbidden');
select pg_temp.expect_error($q$select public.admin_register_image(repeat('a', 64), 'image/png')$q$, 'forbidden');
select pg_temp.expect_error(
  $q$insert into storage.objects (bucket_id, name, metadata) values ('content-images', repeat('b', 64), '{}')$q$,
  'row-level security');

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
-- Les 20 mots gratuits ajoutés par la migration attendent leur publication :
-- d'ici là, le paquet gratuit est vide et l'application garde le sien.
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_free_pack(), null::jsonb, 'publication sans mot gratuit : pas de paquet gratuit');
reset role;
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.assert_eq(public.admin_publish_content('Mots gratuits'), 6, 'mots gratuits publiés');
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'nothing_to_publish');

select pg_temp.as_service();
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
do $$ begin execute pg_temp.new_pictogram('CAA-CR-ACT-026', 26, 2); end $$;
select pg_temp.assert_eq(public.admin_publish_content('Sauter'), 7, 'publication 7');
select pg_temp.assert_eq(
  (select pictogram_count from public.content_releases where version = 7), 152, 'nouveau pictogramme publié');
select pg_temp.assert_eq(
  (select published_by from public.content_releases where version = 7),
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
select pg_temp.assert_eq(public.admin_publish_content(), 8, 'retrait publié');
select pg_temp.assert_eq(
  jsonb_path_exists((select pack from public.content_releases where version = 8), '$.pictograms[*] ? (@.code == "CAA-CR-ACT-026")'),
  false, 'pictogramme retiré absent du paquet');

-- Les publications sont immuables.
select pg_temp.expect_error($q$update public.content_releases set notes = 'x'$q$, 'permission denied');
select pg_temp.expect_error($q$delete from public.content_releases$q$, 'permission denied');

-- ─── Images (Storage, ADR-012) ─────────────────────────────────────────────
-- Envoi dans Storage : nom = empreinte SHA-256, rien d'autre n'est accepté.
create temporary table png (sha text);
grant select on png to public;
insert into png values ('4a5d3c0f1e2b4a5d3c0f1e2b4a5d3c0f1e2b4a5d3c0f1e2b4a5d3c0f1e2b4a5d');
select pg_temp.expect_error(
  $q$insert into storage.objects (bucket_id, name, metadata) values ('content-images', 'image.svg', '{}')$q$,
  'row-level security');
insert into storage.objects (bucket_id, name, metadata)
select 'content-images', sha, '{"size": 68, "mimetype": "image/png"}' from png;
select pg_temp.as_service();
select pg_temp.assert_eq(
  (select count(*) from storage.buckets where id = 'content-images' and not public and file_size_limit = 524288),
  1::bigint, 'compartiment privé limité à 512 Kio');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');

-- Enregistrement : l'objet doit exister, avec le type annoncé.
select pg_temp.expect_error($q$select public.admin_register_image('pas-une-empreinte', 'image/png')$q$, 'invalid_image');
select pg_temp.expect_error($q$select public.admin_register_image(repeat('c', 64), 'image/png')$q$, 'image_not_uploaded');
select pg_temp.expect_error($q$select public.admin_register_image((select sha from png), 'image/webp')$q$, 'invalid_image');
select pg_temp.expect_error($q$select public.admin_register_image((select sha from png), 'image/svg+xml')$q$, 'invalid_image');
select pg_temp.assert_eq(public.admin_register_image((select sha from png), 'image/png'), (select sha from png), 'image enregistrée');
select pg_temp.assert_eq(public.admin_register_image((select sha from png), 'image/png'), (select sha from png), 'même image : enregistrée une fois');
select pg_temp.as_service();
select pg_temp.assert_eq((select size from public.content_images where sha256 = (select sha from png)), 68, 'taille relevée par Storage');
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');

-- Envoyée mais pas publiée : la fonction serveur ne la sert pas.
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_published_image((select sha from png)), null::text, 'image non publiée jamais servie');
reset role;

select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
update public.content_pictograms set image_sha256 = (select sha from png) where code = 'CAA-CR-ACT-001';
select pg_temp.assert_eq(public.admin_publish_content('Nouvelle image'), 9, 'image publiée');
select pg_temp.assert_eq(
  (select jsonb_path_query_first(pack, '$.pictograms[*] ? (@.code == "CAA-CR-ACT-001").imageObject.sha256') #>> '{}'
   from public.content_releases where version = 9),
  (select sha from png), 'empreinte de l''image dans le paquet');
select pg_temp.assert_eq(
  (select (jsonb_path_query_first(pack, '$.pictograms[*] ? (@.code == "CAA-CR-ACT-001").imageObject.size') #>> '{}')::int
   from public.content_releases where version = 9),
  68, 'taille de l''image dans le paquet');

select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_published_image((select sha from png)), 'image/png', 'image publiée servie');
select pg_temp.assert_eq((public.content_latest_pack() ->> 'version')::int, 9, 'dernière publication servie');
reset role;

-- ─── Paquet gratuit (#41) ──────────────────────────────────────────────────
-- Une image payante ne sort pas par le paquet gratuit.
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_free_image((select sha from png)), null::text, 'image d''un mot payant : pas servie sans abonnement');
select pg_temp.assert_eq((public.content_free_pack() ->> 'version')::int, 9, 'paquet gratuit = dernière publication');
select pg_temp.assert_eq(jsonb_array_length(public.content_free_pack() -> 'pictograms'), 20, 'paquet gratuit : les 20 mots gratuits');
select pg_temp.assert_eq(
  jsonb_path_exists(public.content_free_pack(), '$.pictograms[*] ? (@.tier != "free")'), false,
  'paquet gratuit : aucun mot payant');
select pg_temp.assert_eq(public.content_free_pack() #>> '{categories,0,code}', 'CBE', 'paquet gratuit : ses seules catégories');
select pg_temp.assert_eq(jsonb_array_length(public.content_free_pack() -> 'categories'), 1, 'paquet gratuit : une catégorie');
reset role;

-- Un mot payant passe en gratuit, avec son image.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
update public.content_pictograms set tier = 'free' where code = 'CAA-CR-ACT-001';
select pg_temp.assert_eq(public.admin_publish_content('Gratuit : ACT-001'), 10, 'changement de palier publié');
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(jsonb_array_length(public.content_free_pack() -> 'pictograms'), 21, 'le mot passé en gratuit est dans le paquet gratuit');
select pg_temp.assert_eq(jsonb_array_length(public.content_free_pack() -> 'categories'), 2, 'avec sa catégorie');
select pg_temp.assert_eq(public.content_free_image((select sha from png)), 'image/png', 'son image est servie sans abonnement');
reset role;

-- ─── Variantes fille ou garçon (#19) ───────────────────────────────────────
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
insert into storage.objects (bucket_id, name, metadata) values
  ('content-images', repeat('d', 64), '{"size": 70, "mimetype": "image/png"}'),
  ('content-images', repeat('e', 64), '{"size": 71, "mimetype": "image/webp"}');
select public.admin_register_image(repeat('d', 64), 'image/png');
select public.admin_register_image(repeat('e', 64), 'image/webp');
select pg_temp.expect_error(
  $q$update public.content_pictograms set image_feminine_sha256 = repeat('9', 64) where code = 'CAA-CR-ACT-001'$q$,
  'foreign key');
update public.content_pictograms
  set image_feminine_sha256 = repeat('d', 64), image_masculine_sha256 = repeat('e', 64)
  where code = 'CAA-CR-ACT-001';
update public.content_pictograms set image_feminine_sha256 = repeat('d', 64) where code = 'CAA-CR-ACT-002';
select pg_temp.assert_eq(public.admin_publish_content('Variantes'), 11, 'variantes publiées');
select pg_temp.assert_eq(
  (select jsonb_path_query_first(pack, '$.pictograms[*] ? (@.code == "CAA-CR-ACT-001").imageVariantObjects')
   from public.content_releases where version = 11),
  jsonb_build_object(
    'feminine', jsonb_build_object('sha256', repeat('d', 64), 'mime', 'image/png', 'size', 70),
    'masculine', jsonb_build_object('sha256', repeat('e', 64), 'mime', 'image/webp', 'size', 71)),
  'les deux variantes dans le paquet');
select pg_temp.assert_eq(
  (select jsonb_path_query_first(pack, '$.pictograms[*] ? (@.code == "CAA-CR-ACT-002").imageVariantObjects')
   from public.content_releases where version = 11),
  jsonb_build_object('feminine', jsonb_build_object('sha256', repeat('d', 64), 'mime', 'image/png', 'size', 70)),
  'une seule variante : seule elle figure');
select pg_temp.assert_eq(
  (select jsonb_path_exists(pack, '$.pictograms[*] ? (@.code == "CAA-CR-ACT-003").imageVariantObjects')
   from public.content_releases where version = 11),
  false, 'sans variante : rien dans le paquet');
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_free_image(repeat('e', 64)), 'image/webp', 'variante d''un mot gratuit servie sans abonnement');
select pg_temp.assert_eq(public.content_published_image(repeat('e', 64)), 'image/webp', 'variante servie aux abonnés');
reset role;
-- Variante d'un mot payant : pas par le paquet gratuit.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
update public.content_pictograms set image_feminine_sha256 = null where code = 'CAA-CR-ACT-002';
update public.content_pictograms set image_masculine_sha256 = repeat('d', 64) where code = 'CAA-CR-ACT-002';
update public.content_pictograms set image_feminine_sha256 = null, image_masculine_sha256 = null where code = 'CAA-CR-ACT-001';
select pg_temp.assert_eq(public.admin_publish_content(), 12, 'variante déplacée sur un mot payant');
select pg_temp.as_service();
set local role service_role;
select pg_temp.assert_eq(public.content_free_image(repeat('d', 64)), null::text, 'variante d''un mot payant : pas servie sans abonnement');
select pg_temp.assert_eq(public.content_published_image(repeat('d', 64)), 'image/png', 'mais servie aux abonnés');
select pg_temp.assert_eq(public.content_published_image(repeat('e', 64)), null::text, 'variante retirée : plus servie');
reset role;

-- Les fonctions du paquet gratuit ne s'appellent pas directement.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000c1');
select pg_temp.expect_error($q$select public.content_free_pack()$q$, 'permission denied');
select pg_temp.as_service();
set local role anon;
select pg_temp.expect_error($q$select public.content_free_image('00')$q$, 'permission denied');
reset role;

-- Palier inconnu refusé ; publication sans aucun mot gratuit refusée.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.expect_error($q$update public.content_pictograms set tier = 'gold' where code = 'CAA-CR-ACT-002'$q$, 'content_pictograms_tier_check');
update public.content_pictograms set tier = 'premium';
select pg_temp.expect_error($q$select public.admin_publish_content()$q$, 'no_free_content');

rollback;

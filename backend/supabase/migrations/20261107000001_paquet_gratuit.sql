-- Paquet gratuit réglable depuis le back-office (#41). Chaque pictogramme
-- porte son palier : « free » (sans compte) ou « premium » (abonnés). Le
-- palier est une valeur et non un booléen, pour accueillir d'autres paliers
-- (#18) sans changer le format du paquet.
--
-- L'application garde un paquet gratuit embarqué pour le premier lancement
-- hors ligne, puis le met à jour depuis la fonction free-pack, sans compte.

alter table public.content_pictograms
  add column tier text not null default 'premium' check (tier in ('free', 'premium'));
grant update (tier) on public.content_pictograms to authenticated;

-- Les 20 mots gratuits, jusqu'ici seulement dans l'application, rejoignent le
-- catalogue du serveur (même codes : favoris et tableaux restent valides).
create temporary table free_import (pack jsonb);
insert into free_import values ($pack$
{"categories": [{"code": "CBE", "sortOrder": 1, "icon": "bubble", "color": "#C1502E", "labels": {"fr": "Mes besoins", "en": "My needs"}}], "pictograms": [{"code": "CAA-CR-CBE-001", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 1, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Je veux", "spoken": "je veux"}, "en": {"label": "I want", "spoken": "I want"}}}, {"code": "CAA-CR-CBE-002", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 2, "tier": "free", "image": "assets/content/images/demo/je-ne-veux-pas.png", "labelInImage": true, "labels": {"fr": {"label": "Je ne veux pas", "spoken": "je ne veux pas"}, "en": {"label": "I don't want", "spoken": "I don't want"}}}, {"code": "CAA-CR-CBE-003", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 3, "tier": "free", "image": "assets/content/images/demo/encore.png", "labelInImage": true, "labels": {"fr": {"label": "Encore", "spoken": "encore"}, "en": {"label": "More", "spoken": "more"}}}, {"code": "CAA-CR-CBE-004", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 4, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Fini", "spoken": "fini"}, "en": {"label": "Finished", "spoken": "finished"}}}, {"code": "CAA-CR-CBE-005", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 5, "tier": "free", "image": "assets/content/images/demo/aide-moi.png", "labelInImage": true, "labels": {"fr": {"label": "Aide-moi", "spoken": "aide-moi"}, "en": {"label": "Help me", "spoken": "help me"}}}, {"code": "CAA-CR-CBE-006", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 6, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Attends", "spoken": "attends"}, "en": {"label": "Wait", "spoken": "wait"}}}, {"code": "CAA-CR-CBE-007", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 7, "tier": "free", "image": "assets/content/images/demo/oui.png", "labelInImage": true, "labels": {"fr": {"label": "Oui", "spoken": "oui"}, "en": {"label": "Yes", "spoken": "yes"}}}, {"code": "CAA-CR-CBE-008", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 8, "tier": "free", "image": "assets/content/images/demo/non.png", "labelInImage": true, "labels": {"fr": {"label": "Non", "spoken": "non"}, "en": {"label": "No", "spoken": "no"}}}, {"code": "CAA-CR-CBE-009", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 9, "tier": "free", "image": "assets/content/images/demo/s-il-te-plait.png", "labelInImage": true, "labels": {"fr": {"label": "S'il te plaît", "spoken": "s'il te plaît"}, "en": {"label": "Please", "spoken": "please"}}}, {"code": "CAA-CR-CBE-010", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 10, "tier": "free", "image": "assets/content/images/demo/merci.png", "labelInImage": true, "labels": {"fr": {"label": "Merci", "spoken": "merci"}, "en": {"label": "Thank you", "spoken": "thank you"}}}, {"code": "CAA-CR-CBE-011", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 11, "tier": "free", "image": "assets/content/images/demo/stop.png", "labelInImage": true, "labels": {"fr": {"label": "Stop", "spoken": "stop"}, "en": {"label": "Stop", "spoken": "stop"}}}, {"code": "CAA-CR-CBE-012", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 12, "tier": "free", "image": "assets/content/images/demo/donne-moi.png", "labelInImage": true, "labels": {"fr": {"label": "Donne-moi", "spoken": "donne-moi"}, "en": {"label": "Give me", "spoken": "give me"}}}, {"code": "CAA-CR-CBE-013", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 13, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Je veux aller", "spoken": "je veux aller"}, "en": {"label": "I want to go", "spoken": "I want to go"}}}, {"code": "CAA-CR-CBE-014", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 14, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Je veux rester", "spoken": "je veux rester"}, "en": {"label": "I want to stay", "spoken": "I want to stay"}}}, {"code": "CAA-CR-CBE-015", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 15, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Je veux changer", "spoken": "je veux changer"}, "en": {"label": "I want to change", "spoken": "I want to change"}}}, {"code": "CAA-CR-CBE-017", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 16, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "J'ai besoin", "spoken": "j'ai besoin"}, "en": {"label": "I need", "spoken": "I need"}}}, {"code": "CAA-CR-CBE-018", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 17, "tier": "free", "image": "assets/content/images/demo/je-ne-sais-pas.png", "labelInImage": true, "labels": {"fr": {"label": "Je ne sais pas", "spoken": "je ne sais pas"}, "en": {"label": "I don't know", "spoken": "I don't know"}}}, {"code": "CAA-CR-CBE-019", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 18, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Je n'ai pas compris", "spoken": "je n'ai pas compris"}, "en": {"label": "I didn't understand", "spoken": "I didn't understand"}}}, {"code": "CAA-CR-CBE-020", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 19, "tier": "free", "image": null, "labelInImage": false, "labels": {"fr": {"label": "Laisse-moi", "spoken": "laisse-moi"}, "en": {"label": "Leave me alone", "spoken": "leave me alone"}}}, {"code": "CAA-CR-CBE-021", "category": "CBE", "level": 0, "audience": "all", "sortOrder": 20, "tier": "free", "image": "assets/content/images/demo/viens.png", "labelInImage": true, "labels": {"fr": {"label": "Viens", "spoken": "viens"}, "en": {"label": "Come", "spoken": "come"}}}]}
$pack$);

insert into public.content_categories (code, sort_order, icon, color, labels)
select c ->> 'code', (c ->> 'sortOrder')::int, c ->> 'icon', c ->> 'color', c -> 'labels'
from free_import, jsonb_array_elements(pack -> 'categories') c
on conflict (code) do nothing;

insert into public.content_pictograms
  (code, category_code, level, audience, sort_order, labels, image_asset, label_in_image, tier)
select p ->> 'code', p ->> 'category', (p ->> 'level')::smallint, p ->> 'audience',
       (p ->> 'sortOrder')::int, p -> 'labels', p ->> 'image',
       (p ->> 'labelInImage')::boolean, 'free'
from free_import, jsonb_array_elements(pack -> 'pictograms') p
on conflict (code) do nothing;

drop table free_import;

create or replace function public.content_build_pack(pack_version int)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with live as (
    select p.*, c.sort_order as category_order
    from public.content_pictograms p
    join public.content_categories c on c.code = p.category_code
    where p.active
  )
  select jsonb_build_object(
    'version', pack_version,
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', c.code, 'sortOrder', c.sort_order, 'icon', c.icon,
        'color', c.color, 'labels', c.labels
      ) order by c.sort_order, c.code)
      from public.content_categories c
      where exists (select 1 from live l where l.category_code = c.code)
    ), '[]'::jsonb),
    'pictograms', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'code', l.code, 'category', l.category_code, 'level', l.level,
          'audience', l.audience, 'sortOrder', l.sort_order, 'tier', l.tier,
          'image', l.image_asset, 'labelInImage', l.label_in_image, 'labels', l.labels
        )
        || case when l.image_sha256 is null then '{}'::jsonb else jsonb_build_object(
             'imageObject', jsonb_build_object(
               'sha256', i.sha256, 'mime', i.mime, 'size', i.size))
           end
        order by l.category_order, l.category_code, l.sort_order)
      from live l
      left join public.content_images i on i.sha256 = l.image_sha256
    ), '[]'::jsonb),
    'phrases', '[]'::jsonb
  );
$$;

-- Publication : refusée sans aucun mot gratuit. L'application sans compte
-- n'aurait plus rien à proposer après sa mise à jour.
create or replace function public.admin_publish_content(notes text default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  latest record;
  next_version int;
  new_pack jsonb;
  bad text;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  lock table public.content_releases in exclusive mode;

  -- Position stable : dans une catégorie, un mot ne passe jamais devant un
  -- mot de niveau inférieur (monter de niveau ajoute à la fin).
  select p.code into bad
  from public.content_pictograms p
  where p.active and exists (
    select 1 from public.content_pictograms q
    where q.active and q.category_code = p.category_code
      and q.sort_order < p.sort_order and q.level > p.level
  )
  order by p.category_code, p.sort_order
  limit 1;
  if bad is not null then
    raise exception 'level_order: %', bad using errcode = '22023';
  end if;

  if not exists (select 1 from public.content_pictograms where active and tier = 'free') then
    raise exception 'no_free_content' using errcode = '22023';
  end if;

  select version, pack as current_pack into latest
  from public.content_releases order by version desc limit 1;
  next_version := coalesce(latest.version, 0) + 1;
  new_pack := public.content_build_pack(next_version);

  if jsonb_array_length(new_pack -> 'pictograms') = 0 then
    raise exception 'empty_content' using errcode = '22023';
  end if;
  if latest.version is not null and (new_pack - 'version') = (latest.current_pack - 'version') then
    raise exception 'nothing_to_publish' using errcode = 'P0001';
  end if;

  insert into public.content_releases (version, pack, pictogram_count, notes, published_by)
  values (next_version, new_pack, jsonb_array_length(new_pack -> 'pictograms'), nullif(trim(notes), ''), auth.uid());
  return next_version;
end;
$$;

-- ─── Lecture par la fonction free-pack (rôle service) ───────────────────────
-- Dernière publication réduite aux mots gratuits et à leurs catégories ;
-- `null` si elle n'en contient aucun (publication antérieure à ce palier) :
-- l'application garde alors ce qu'elle a.
create function public.content_free_pack()
returns jsonb
language sql
stable
set search_path = ''
as $$
  with pack as (select public.content_latest_pack() as p),
  free as (
    select x.value as pictogram, x.ordinality as n
    from pack, jsonb_array_elements(pack.p -> 'pictograms') with ordinality x
    where x.value ->> 'tier' = 'free'
  )
  select case when not exists (select 1 from free) then null else jsonb_build_object(
    'version', (select (p ->> 'version')::int from pack),
    'categories', (
      select jsonb_agg(c.value order by c.ordinality)
      from pack, jsonb_array_elements(pack.p -> 'categories') with ordinality c
      where exists (select 1 from free f where f.pictogram ->> 'category' = c.value ->> 'code')
    ),
    'pictograms', (select jsonb_agg(pictogram order by n) from free),
    'phrases', '[]'::jsonb
  ) end;
$$;

-- Type d'une image, seulement si un mot gratuit de la dernière publication
-- l'utilise.
create function public.content_free_image(target_sha256 text)
returns text
language sql
stable
set search_path = ''
as $$
  select i.mime
  from public.content_images i
  where i.sha256 = target_sha256
    and jsonb_path_exists(
      public.content_latest_pack(),
      '$.pictograms[*] ? (@.tier == "free" && @.imageObject.sha256 == $sha)',
      jsonb_build_object('sha', target_sha256));
$$;

revoke all on function public.content_free_pack(), public.content_free_image(text)
  from public, anon, authenticated;
grant execute on function public.content_free_pack(), public.content_free_image(text) to service_role;

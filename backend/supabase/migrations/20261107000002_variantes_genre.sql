-- Variantes fille ou garçon des pictogrammes qui représentent une personne
-- (#19). L'image commune reste obligatoire pour l'affichage : un profil sans
-- genre, ou un pictogramme sans variante, la garde. Les variantes sont des
-- images envoyées depuis le back-office comme les autres (ADR-012).

alter table public.content_pictograms
  add column image_feminine_sha256 text references public.content_images (sha256),
  add column image_masculine_sha256 text references public.content_images (sha256);
grant update (image_feminine_sha256, image_masculine_sha256) on public.content_pictograms to authenticated;

-- Paquet : `imageVariantObjects` porte les variantes présentes, au même
-- format que `imageObject`.
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
        || case when i.sha256 is null then '{}'::jsonb else jsonb_build_object(
             'imageObject', jsonb_build_object('sha256', i.sha256, 'mime', i.mime, 'size', i.size))
           end
        || case when f.sha256 is null and m.sha256 is null then '{}'::jsonb else jsonb_build_object(
             'imageVariantObjects', jsonb_strip_nulls(jsonb_build_object(
               'feminine', case when f.sha256 is not null then
                 jsonb_build_object('sha256', f.sha256, 'mime', f.mime, 'size', f.size) end,
               'masculine', case when m.sha256 is not null then
                 jsonb_build_object('sha256', m.sha256, 'mime', m.mime, 'size', m.size) end)))
           end
        order by l.category_order, l.category_code, l.sort_order)
      from live l
      left join public.content_images i on i.sha256 = l.image_sha256
      left join public.content_images f on f.sha256 = l.image_feminine_sha256
      left join public.content_images m on m.sha256 = l.image_masculine_sha256
    ), '[]'::jsonb),
    'phrases', '[]'::jsonb
  );
$$;

-- Une variante publiée sort aux mêmes conditions que l'image commune.
create or replace function public.content_published_image(target_sha256 text)
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
      '$.pictograms[*] ? (@.imageObject.sha256 == $sha
                          || @.imageVariantObjects.feminine.sha256 == $sha
                          || @.imageVariantObjects.masculine.sha256 == $sha)',
      jsonb_build_object('sha', target_sha256));
$$;

create or replace function public.content_free_image(target_sha256 text)
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
      '$.pictograms[*] ? (@.tier == "free"
                          && (@.imageObject.sha256 == $sha
                              || @.imageVariantObjects.feminine.sha256 == $sha
                              || @.imageVariantObjects.masculine.sha256 == $sha))',
      jsonb_build_object('sha', target_sha256));
$$;

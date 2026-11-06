-- Images du contenu en stockage objet (ADR-012, remplace la partie « images »
-- de l'ADR-011). Les octets quittent PostgreSQL pour Supabase Storage, adossé
-- en production à un stockage objet compatible S3 (SeaweedFS). La base ne
-- garde que les métadonnées ; le reste du système ne parle qu'à Storage.

-- ─── Compartiment ───────────────────────────────────────────────────────────
-- Privé : aucune URL publique. Les limites sont appliquées par Storage avant
-- toute écriture (512 Kio, PNG ou WebP ; pas de SVG, qui peut porter du script).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('content-images', 'content-images', false, 524288, array['image/png', 'image/webp'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Un objet porte le nom de son empreinte SHA-256 : envoyé par un
-- super-administrateur, lu par les administrateurs pour l'aperçu, jamais
-- modifié ni supprimé (aucune règle de mise à jour ou de suppression).
create policy content_images_upload on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'content-images'
    and name ~ '^[0-9a-f]{64}$'
    and public.is_super_admin()
  );
create policy content_images_preview on storage.objects
  for select to authenticated
  using (bucket_id = 'content-images' and public.is_admin());

-- ─── Métadonnées ────────────────────────────────────────────────────────────
-- Les octets ne peuvent pas être recopiés vers Storage depuis SQL : une image
-- encore utilisée par un pictogramme doit être renvoyée depuis le back-office
-- après la migration. Aucune ne l'est en production.
do $$
begin
  if exists (select 1 from public.content_pictograms where image_sha256 is not null) then
    raise exception 'images_a_renvoyer : retirer image_sha256 des pictogrammes, migrer, puis renvoyer les images';
  end if;
end;
$$;
delete from public.content_images;
alter table public.content_images drop column bytes cascade;
alter table public.content_images
  add column size int not null check (size between 1 and 524288);

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
          'audience', l.audience, 'sortOrder', l.sort_order, 'tier', 'premium',
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

-- Enregistre une image déjà envoyée dans Storage : vérifie qu'elle existe, son
-- type et sa taille réels (relevés par Storage), puis l'ajoute au catalogue.
create function public.admin_register_image(target_sha256 text, mime text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  stored_size int;
  stored_mime text;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if target_sha256 !~ '^[0-9a-f]{64}$' or mime not in ('image/png', 'image/webp') then
    raise exception 'invalid_image' using errcode = '22023';
  end if;
  select (o.metadata ->> 'size')::int, o.metadata ->> 'mimetype'
    into stored_size, stored_mime
  from storage.objects o
  where o.bucket_id = 'content-images' and o.name = target_sha256;
  if not found then
    raise exception 'image_not_uploaded' using errcode = '22023';
  end if;
  if stored_mime is distinct from mime then
    raise exception 'invalid_image' using errcode = '22023';
  end if;
  if stored_size is null or stored_size not between 1 and 524288 then
    raise exception 'image_too_large' using errcode = '22023';
  end if;
  insert into public.content_images (sha256, mime, size, created_by)
  values (target_sha256, mime, stored_size, auth.uid())
  on conflict (sha256) do nothing;
  return target_sha256;
end;
$$;

-- Type d'une image, seulement si la dernière publication la référence : un
-- brouillon envoyé mais pas encore publié ne sort pas. Les octets sont lus
-- dans Storage par la fonction serveur.
drop function public.content_published_image(text);
create function public.content_published_image(target_sha256 text)
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
      '$.pictograms[*] ? (@.imageObject.sha256 == $sha)',
      jsonb_build_object('sha', target_sha256));
$$;

drop function public.admin_put_image(text, text);
drop function public.admin_image(text);

revoke all on function
  public.admin_register_image(text, text),
  public.content_published_image(text),
  public.content_build_pack(int)
from public, anon, authenticated;
grant execute on function public.admin_register_image(text, text) to authenticated;
grant execute on function public.content_published_image(text) to service_role;

-- Contenu téléchargeable en base (issue #28, ADR-011) : catégories,
-- pictogrammes, images et publications versionnées. Le contenu gratuit reste
-- embarqué dans l'application (ADR-008) ; ici, le catalogue que la fonction
-- premium-pack sert aux abonnés.
--
-- Les contrôles reprennent ce que l'application exige à l'import (valeurs
-- d'énumération, libellés, position stable, contraste) : un contenu publié
-- qui les violerait ferait échouer l'application chez tous les abonnés.

-- ─── Validation ─────────────────────────────────────────────────────────────
create function public.content_category_labels_valid(l jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select jsonb_typeof(l) = 'object'
     and (select count(*) from jsonb_object_keys(l)) = 2
     and coalesce(char_length(trim(l ->> 'fr')) between 1 and 40, false)
     and coalesce(char_length(trim(l ->> 'en')) between 1 and 40, false)
     and jsonb_typeof(l -> 'fr') = 'string'
     and jsonb_typeof(l -> 'en') = 'string';
$$;

create function public.content_pictogram_labels_valid(l jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select jsonb_typeof(l) = 'object'
     and (select count(*) from jsonb_object_keys(l)) = 2
     and coalesce((
       select bool_and(
         jsonb_typeof(l -> lang) = 'object'
         and (select count(*) from jsonb_object_keys(l -> lang)) = 2
         and jsonb_typeof(l -> lang -> 'label') = 'string'
         and jsonb_typeof(l -> lang -> 'spoken') = 'string'
         and char_length(trim(l -> lang ->> 'label')) between 1 and 40
         and char_length(trim(l -> lang ->> 'spoken')) between 1 and 80
       )
       from unnest(array['fr', 'en']) lang
     ), false);
$$;

-- Contraste WCAG d'une couleur #RRGGBB sur fond blanc, même calcul que
-- l'application (Color.computeLuminance) : une catégorie doit atteindre 3:1.
create function public.content_contrast_on_white(hex text)
returns numeric
language sql
immutable
set search_path = ''
as $$
  with c as (
    select (('x' || substr(hex, 2 + 2 * i, 2))::bit(8)::int)::numeric / 255 as v, i
    from generate_series(0, 2) i
  ),
  lin as (
    select i, case when v <= 0.03928 then v / 12.92 else power((v + 0.055) / 1.055, 2.4) end as v
    from c
  )
  select 1.05 / (0.2126 * (select v from lin where i = 0)
               + 0.7152 * (select v from lin where i = 1)
               + 0.0722 * (select v from lin where i = 2) + 0.05);
$$;

-- ─── Tables ─────────────────────────────────────────────────────────────────
create table public.content_categories (
  code text primary key check (code ~ '^[A-Z]{3}$'),
  sort_order int not null check (sort_order between 1 and 999),
  -- Icônes connues de l'application (category_icons.dart).
  icon text not null check (icon in ('bubble', 'hand', 'plate', 'face', 'cross', 'person', 'house', 'drop')),
  color text not null check (color ~ '^#[0-9A-Fa-f]{6}$' and public.content_contrast_on_white(color) >= 3),
  labels jsonb not null check (public.content_category_labels_valid(labels)),
  updated_at timestamptz not null default now()
);

-- Image envoyée depuis le back-office, identifiée par son empreinte : une
-- même image n'est stockée qu'une fois, et un appareil ne la télécharge
-- qu'une fois. PNG ou WebP seulement (pas de SVG, qui peut porter du script).
create table public.content_images (
  sha256 text primary key check (sha256 ~ '^[0-9a-f]{64}$'),
  mime text not null check (mime in ('image/png', 'image/webp')),
  bytes bytea not null check (octet_length(bytes) between 1 and 524288),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users (id) on delete set null,
  check (sha256 = encode(sha256(bytes), 'hex'))
);

create table public.content_pictograms (
  -- Identifiant permanent de la charte graphique : jamais réattribué.
  code text primary key check (code ~ '^CAA-CR-[A-Z]{3}-[0-9]{3}$'),
  category_code text not null references public.content_categories (code),
  level smallint not null check (level between 0 and 2),
  audience text not null check (audience in ('child', 'teen', 'adult', 'all')),
  sort_order int not null check (sort_order between 1 and 9999),
  labels jsonb not null check (public.content_pictogram_labels_valid(labels)),
  -- Image livrée dans l'application (contenu de démonstration actuel).
  image_asset text check (image_asset ~ '^assets/content/images/[a-z0-9/_-]+\.png$'),
  -- Image envoyée depuis le back-office, téléchargée par l'application.
  image_sha256 text references public.content_images (sha256),
  label_in_image boolean not null default false,
  -- Retiré des prochaines publications (jamais supprimé une fois publié :
  -- favoris et tableaux des familles le désignent par son code).
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  -- Position stable : un ordre par catégorie, jamais partagé.
  unique (category_code, sort_order),
  check (split_part(code, '-', 3) = category_code)
);
create index content_pictograms_image_idx on public.content_pictograms (image_sha256);

-- Publication : instantané immuable du paquet servi aux abonnés.
create table public.content_releases (
  version int primary key check (version > 0),
  pack jsonb not null,
  pictogram_count int not null check (pictogram_count >= 0),
  notes text check (char_length(notes) <= 500),
  published_at timestamptz not null default now(),
  published_by uuid references auth.users (id) on delete set null
);

create function public.content_touch()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger content_categories_touch before update on public.content_categories
  for each row execute function public.content_touch();
create trigger content_pictograms_touch before update on public.content_pictograms
  for each row execute function public.content_touch();

-- Journal d'audit : chaque modification du catalogue (les images, en octets,
-- sont tracées par l'empreinte portée par le pictogramme).
create trigger audit_content_categories after insert or update or delete on public.content_categories
  for each row execute function public.audit_row();
create trigger audit_content_pictograms after insert or update or delete on public.content_pictograms
  for each row execute function public.audit_row();

-- ─── Paquet ─────────────────────────────────────────────────────────────────
-- Même format que le paquet embarqué et l'ancien premium-pack/pack.json.
create function public.content_build_pack(pack_version int)
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
               'sha256', i.sha256, 'mime', i.mime, 'size', octet_length(i.bytes)))
           end
        order by l.category_order, l.category_code, l.sort_order)
      from live l
      left join public.content_images i on i.sha256 = l.image_sha256
    ), '[]'::jsonb),
    'phrases', '[]'::jsonb
  );
$$;

-- ─── Administration ─────────────────────────────────────────────────────────
-- Envoi d'une image : vérifie le format réel (signature des octets, pas
-- seulement le type annoncé) et renvoie son empreinte.
create function public.admin_put_image(data_base64 text, mime text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  raw bytea;
  digest text;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if char_length(data_base64) > 700000 then
    raise exception 'image_too_large' using errcode = '22023';
  end if;
  begin
    raw := decode(data_base64, 'base64');
  exception when others then
    raise exception 'invalid_image' using errcode = '22023';
  end;
  if octet_length(raw) > 524288 then
    raise exception 'image_too_large' using errcode = '22023';
  end if;
  if not (
    (mime = 'image/png' and substring(raw from 1 for 8) = '\x89504e470d0a1a0a'::bytea)
    or (mime = 'image/webp' and substring(raw from 1 for 4) = '\x52494646'::bytea
        and substring(raw from 9 for 4) = '\x57454250'::bytea)
  ) then
    raise exception 'invalid_image' using errcode = '22023';
  end if;
  digest := encode(sha256(raw), 'hex');
  insert into public.content_images (sha256, mime, bytes, created_by)
  values (digest, mime, raw, auth.uid())
  on conflict (sha256) do nothing;
  return digest;
end;
$$;

-- Image en base64 pour l'aperçu du back-office.
create function public.admin_image(target_sha256 text)
returns table (mime text, data_base64 text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
  select i.mime, encode(i.bytes, 'base64') from public.content_images i where i.sha256 = target_sha256;
end;
$$;

-- Publication : construit le paquet depuis le catalogue, vérifie ce que
-- l'application exige, puis l'enregistre sous la version suivante.
create function public.admin_publish_content(notes text default null)
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

-- ─── Lecture par les fonctions serveur (rôle service) ───────────────────────
-- Dernière publication, servie par premium-pack.
create function public.content_latest_pack()
returns jsonb
language sql
stable
set search_path = ''
as $$
  select pack from public.content_releases order by version desc limit 1;
$$;

-- Image en base64, seulement si la dernière publication la référence : un
-- brouillon envoyé mais pas encore publié ne sort pas.
create function public.content_published_image(target_sha256 text)
returns table (mime text, data_base64 text)
language sql
stable
set search_path = ''
as $$
  select i.mime, encode(i.bytes, 'base64')
  from public.content_images i
  where i.sha256 = target_sha256
    and jsonb_path_exists(
      public.content_latest_pack(),
      '$.pictograms[*] ? (@.imageObject.sha256 == $sha)',
      jsonb_build_object('sha', target_sha256));
$$;

-- ─── Sécurité par ligne et droits ───────────────────────────────────────────
alter table public.content_categories enable row level security;
alter table public.content_pictograms enable row level security;
alter table public.content_images enable row level security;
alter table public.content_releases enable row level security;

create policy content_categories_admin_read on public.content_categories
  for select to authenticated using (public.is_admin());
create policy content_categories_admin_insert on public.content_categories
  for insert to authenticated with check (public.is_super_admin());
create policy content_categories_admin_update on public.content_categories
  for update to authenticated using (public.is_super_admin()) with check (public.is_super_admin());

create policy content_pictograms_admin_read on public.content_pictograms
  for select to authenticated using (public.is_admin());
create policy content_pictograms_admin_insert on public.content_pictograms
  for insert to authenticated with check (public.is_super_admin());
create policy content_pictograms_admin_update on public.content_pictograms
  for update to authenticated using (public.is_super_admin()) with check (public.is_super_admin());
-- Suppression d'un brouillon seulement : un pictogramme déjà publié est
-- retiré (active = false), jamais supprimé.
create policy content_pictograms_admin_delete_draft on public.content_pictograms
  for delete to authenticated using (
    public.is_super_admin()
    and not exists (
      select 1 from public.content_releases r
      where jsonb_path_exists(r.pack, '$.pictograms[*] ? (@.code == $c)', jsonb_build_object('c', code))
    )
  );

create policy content_releases_admin_read on public.content_releases
  for select to authenticated using (public.is_admin());

-- Les privilèges par défaut de Supabase donnent tout à anon et authenticated :
-- lecture et écriture des administrateurs par la sécurité par ligne, octets
-- des images et publications par les fonctions seulement.
revoke all on public.content_categories, public.content_pictograms,
  public.content_images, public.content_releases from anon, authenticated;
grant select, insert, update (sort_order, icon, color, labels) on public.content_categories to authenticated;
grant select, insert, delete,
  update (category_code, level, audience, sort_order, labels, image_asset, image_sha256, label_in_image, active)
  on public.content_pictograms to authenticated;
grant select on public.content_releases to authenticated;
-- content_images : aucun accès direct (admin_put_image, admin_image).

revoke all on function
  public.admin_put_image(text, text),
  public.admin_image(text),
  public.admin_publish_content(text),
  public.content_build_pack(int),
  public.content_latest_pack(),
  public.content_published_image(text)
from public, anon, authenticated;
grant execute on function
  public.admin_put_image(text, text),
  public.admin_image(text),
  public.admin_publish_content(text)
to authenticated;
grant execute on function
  public.content_latest_pack(),
  public.content_published_image(text)
to service_role;
-- Les fonctions de validation des contraintes restent appelables : pures et
-- sans accès aux données. Le déclencheur ne s'appelle jamais directement.
revoke all on function public.content_touch() from public, anon, authenticated;

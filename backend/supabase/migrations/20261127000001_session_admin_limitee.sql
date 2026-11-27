-- Session du back-office limitée à 24 heures.
--
-- Le jeton d'accès dure une heure, mais le back-office le renouvelait sans
-- fin : une session ouverte restait valable indéfiniment. Les réglages de
-- session de GoTrue sont globaux (ils déconnecteraient aussi les parents de
-- l'application mobile) ; la limite porte donc sur les droits d'administration
-- eux-mêmes : ils ne valent que si le second facteur a été vérifié il y a
-- moins de 24 heures (horodatage `totp` du claim `amr` du jeton). Passé ce
-- délai, une nouvelle connexion avec second facteur est nécessaire, même avec
-- un jeton volé et renouvelé.

create or replace function public.admin_session_valid()
returns boolean
language sql
stable
set search_path = ''
as $$
  select public.session_aal2()
     and coalesce((
       select max((e ->> 'timestamp')::bigint)
       from jsonb_array_elements(coalesce(auth.jwt() -> 'amr', '[]'::jsonb)) e
       where e ->> 'method' = 'totp'
     ), 0) > extract(epoch from now() - interval '24 hours');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.admin_session_valid()
     and exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.admin_session_valid()
     and exists (
       select 1 from public.admins where user_id = auth.uid() and role = 'super_admin'
     );
$$;

revoke all on function public.admin_session_valid() from public, anon;
grant execute on function public.admin_session_valid() to authenticated;

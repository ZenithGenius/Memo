-- Recherche de compte pour le panneau d'administration (ADR-008, issue #8).
-- `auth.users` n'est jamais exposé par l'API : cette fonction expose
-- seulement l'e-mail, et seulement à un administrateur.
create function public.admin_search_account(query text)
returns table (
  user_id uuid,
  email text,
  display_name text,
  phone text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'not_admin' using errcode = 'P0001';
  end if;
  return query
  select u.id, u.email, a.display_name, a.phone, a.created_at
  from auth.users u
  join public.accounts a on a.user_id = u.id
  where u.email ilike '%' || query || '%'
     or a.phone ilike '%' || query || '%'
     or a.display_name ilike '%' || query || '%'
  order by a.created_at desc
  limit 20;
end;
$$;

revoke all on function public.admin_search_account(text) from public, anon;
grant execute on function public.admin_search_account(text) to authenticated;

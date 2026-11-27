-- Invitation d'un administrateur depuis le back-office : un super-administrateur
-- saisit l'adresse, la personne reçoit un e-mail pour choisir son mot de passe.
-- Plus besoin qu'elle s'inscrive d'abord dans l'application.
--
-- admin_set_role refuse une adresse non confirmée (sinon n'importe qui
-- s'inscrirait avec l'adresse d'un autre puis attendrait qu'on lui donne un
-- rôle). Ici, c'est le super-administrateur qui crée le compte et l'invitation
-- part vers l'adresse saisie : le compte n'est utilisable qu'après le lien de
-- cet e-mail. Le rôle peut donc être attribué dès l'invitation, à un compte
-- invité qui n'a encore jamais été confirmé, et à lui seul.
--
-- Pré-détournement : quelqu'un pourrait s'inscrire d'avance avec l'adresse
-- (compte non confirmé, son mot de passe), puis attendre l'invitation. Deux
-- protections : la fonction serveur passe par admin_set_role (adresse
-- confirmée exigée) dès que l'adresse a déjà un compte, et le rôle n'est
-- donné ici qu'à un compte créé par l'invitation elle-même.

-- Lecture réservée à la fonction serveur admin-invite.
create function public.auth_account_exists(target_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from auth.users where lower(email) = lower(trim(target_email)));
$$;
revoke all on function public.auth_account_exists(text) from public, anon, authenticated;
grant execute on function public.auth_account_exists(text) to service_role;

create function public.admin_grant_invited(target uuid, new_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if new_role not in ('super_admin', 'support') then
    raise exception 'invalid_role' using errcode = '22023';
  end if;
  if not exists (
    select 1 from auth.users
    where id = target and invited_at is not null and email_confirmed_at is null
      -- Compte créé par l'invitation, pas une inscription : aucun mot de passe
      -- (une inscription en a toujours un), créé au moment de l'invitation.
      and coalesce(encrypted_password, '') = ''
      and invited_at - created_at between interval '0' and interval '1 minute'
  ) then
    raise exception 'not_invited' using errcode = 'P0001';
  end if;
  -- Journal d'audit : par le déclencheur de public.admins (auteur = session).
  insert into public.admins (user_id, role) values (target, new_role)
  on conflict (user_id) do update set role = excluded.role;
end;
$$;

revoke all on function public.admin_grant_invited(uuid, text) from public, anon;
grant execute on function public.admin_grant_invited(uuid, text) to authenticated;

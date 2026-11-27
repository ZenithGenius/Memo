-- Réinitialisation du mot de passe (#42). L'e-mail est envoyé par le service
-- d'authentification ; un super-administrateur peut le déclencher pour une
-- famille depuis sa fiche, sans jamais voir ni choisir le mot de passe.
-- Cette fonction contrôle le rôle et trace la demande au journal.

alter table public.audit_log drop constraint audit_log_action_check;
alter table public.audit_log
  add constraint audit_log_action_check
  check (action in ('insert', 'update', 'delete', 'password_reset'));

create function public.admin_log_password_reset(target uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_email text;
begin
  if not public.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select email into target_email from auth.users where id = target;
  if target_email is null then
    raise exception 'not_found';
  end if;
  insert into public.audit_log (actor, action, entity, entity_id)
  values (auth.uid(), 'password_reset', 'users', target::text);
  return target_email;
end;
$$;

revoke all on function public.admin_log_password_reset(uuid) from public, anon;
grant execute on function public.admin_log_password_reset(uuid) to authenticated;

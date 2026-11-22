#!/usr/bin/env bash
# Crée (ou promeut) un super-administrateur du back-office, depuis le dossier
# de l'environnement sur le serveur :
#   bash create-super-admin.sh adresse@exemple.com
# Le compte est créé confirmé, avec un mot de passe provisoire affiché une
# seule fois : à changer dès la première connexion. La double
# authentification est demandée par le back-office à la première connexion.
set -euo pipefail
cd "$(dirname "$0")"
EMAIL=${1:?adresse e-mail}
set -a; . ./.env; set +a

psql() { docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

id=$(psql -v email="$EMAIL" <<<"select id from auth.users where lower(email) = lower(:'email');")
if [ -z "$id" ]; then
  # Mot de passe conforme à la règle (10 caractères au moins, minuscule, majuscule, chiffre).
  PASSWORD="Memo-$(openssl rand -hex 6)-$(openssl rand -base64 9 | tr -dc 'A-Za-z0-9' | head -c 8)A7"
  body=$(jq -n --arg e "$EMAIL" --arg p "$PASSWORD" '{email: $e, password: $p, email_confirm: true}')
  id=$(curl -fsS "http://127.0.0.1:$API_PORT/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" -d "$body" | jq -r .id)
  echo "Compte créé : $EMAIL"
  echo "Mot de passe provisoire (affiché une seule fois) : $PASSWORD"
else
  echo "Compte existant : $EMAIL"
fi

psql -v id="$id" <<<"insert into public.admins (user_id, role) values (:'id', 'super_admin')
  on conflict (user_id) do update set role = 'super_admin';"
echo "Rôle super_admin attribué sur l'environnement $ENVIRONMENT."

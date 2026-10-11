#!/usr/bin/env bash
# Test de bout en bout de la fonction issue-license contre la pile locale.
# Prérequis : `supabase start` et `supabase functions serve` en cours (voir backend/README.md).
set -euo pipefail
cd "$(dirname "$0")/../.."
eval "$(supabase status --workdir backend -o env 2>/dev/null | grep -E '^(ANON_KEY|API_URL)=')"

# Conteneur de la base : dérivé du project_id de config.toml, surchargeable.
PROJECT_ID=$(sed -n 's/^project_id = "\(.*\)"/\1/p' backend/supabase/config.toml)
DB_CONTAINER="${SUPABASE_DB_CONTAINER:-supabase_db_${PROJECT_ID}}"
DB_USER="${SUPABASE_DB_USER:-postgres}"

psql_() { docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -q "$@"; }
call() {
  curl -s -w '\n%{http_code}' -X POST "$API_URL/functions/v1/issue-license" \
    -H "Authorization: Bearer $JWT" -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" -d "$1"
}
expect() { # attendu, obtenu, libellé
  if [ "$1" != "$2" ]; then echo "ECHEC $3: attendu $1, obtenu $2"; exit 1; fi
  echo "OK $3"
}

# Compte jetable : adresse et mot de passe aléatoires, jamais réutilisés.
EMAIL="e2e-$(openssl rand -hex 6)@test.invalid"
PASSWORD="$(openssl rand -base64 24)Aa1"
SIGNUP=$(curl -s -X POST "$API_URL/auth/v1/signup" -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c 'import json,sys; print(json.dumps({"email": sys.argv[1], "password": sys.argv[2]}))' "$EMAIL" "$PASSWORD")")
JWT=$(echo "$SIGNUP" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
UID_=$(echo "$SIGNUP" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")

code() { echo "$1" | tail -1; }

expect 401 "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API_URL/functions/v1/issue-license" -H "apikey: $ANON_KEY" -d '{}')" "sans JWT"
expect 402 "$(code "$(call '{"fingerprint":"abcdefghijklmnop1234","platform":"android"}')")" "sans abonnement"

psql_ -c "insert into public.subscriptions (user_id, plan_code, valid_until) values ('$UID_', 'essentiel', now() + interval '30 days');"

R1=$(call '{"fingerprint":"abcdefghijklmnop1234","platform":"android"}')
expect 200 "$(code "$R1")" "abonné : jeton émis"
expect 200 "$(code "$(call '{"fingerprint":"second-device-0000001","platform":"ios"}')")" "deuxième appareil"
expect 409 "$(code "$(call '{"fingerprint":"third-device-00000002","platform":"android"}')")" "troisième appareil refusé"
expect 400 "$(code "$(call '{"fingerprint":"x","platform":"android"}')")" "empreinte invalide"

# Appareil révoqué : plus de jeton.
psql_ -c "update public.devices set revoked_at = now() where user_id = '$UID_' and fingerprint = 'second-device-0000001';"
expect 403 "$(code "$(call '{"fingerprint":"second-device-0000001","platform":"ios"}')")" "appareil révoqué"

# Installation hors boutique : jeton limité à 7 jours.
psql_ -c "update public.devices set installed_from_store = false where user_id = '$UID_' and fingerprint = 'abcdefghijklmnop1234';"
R2=$(call '{"fingerprint":"abcdefghijklmnop1234","platform":"android"}')
DAYS=$(echo "$R2" | head -n -1 | python3 -c "
import sys,json,datetime as d
r=json.load(sys.stdin)
p=lambda s: d.datetime.fromisoformat(s.replace('Z','+00:00'))
print(round((p(r['valid_until'])-p(r['server_time'])).total_seconds()/86400))")
expect 7 "$DAYS" "jeton court hors boutique"

# Contenu payant : seulement pour un appareil enregistré d'un abonné.
pack() {
  curl -s -o /tmp/premium.json -w '%{http_code}' \
    "$API_URL/functions/v1/premium-pack?fingerprint=$1${2:+&have=$2}" \
    -H "Authorization: Bearer $JWT" -H "apikey: $ANON_KEY"
}
expect 200 "$(pack abcdefghijklmnop1234)" "paquet payant livré"
VERSION=$(python3 -c "import json; print(json.load(open('/tmp/premium.json'))['version'])")
COUNT=$(python3 -c "import json; print(len(json.load(open('/tmp/premium.json'))['pictograms']))")
expect 131 "$COUNT" "131 pictogrammes payants"
expect 204 "$(pack abcdefghijklmnop1234 "$VERSION")" "déjà à jour"
expect 403 "$(pack inconnu-0000000000000)" "appareil inconnu"
expect 403 "$(pack second-device-0000001)" "appareil révoqué"

# Image envoyée depuis le back-office (issue #28) : servie aux abonnés une fois
# publiée seulement. Le compte de test devient super-administrateur le temps du
# test ; octets aléatoires ajoutés au PNG pour une empreinte neuve à chaque
# exécution, puis catalogue remis dans son état.
image() {
  curl -s -o /tmp/premium.png -w '%{http_code}' \
    "$API_URL/functions/v1/premium-image?fingerprint=abcdefghijklmnop1234&sha256=$1" \
    -H "Authorization: Bearer $JWT" -H "apikey: $ANON_KEY"
}
PNG_B64=$( (echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | base64 -d; openssl rand 16) | base64 -w0)
AS_ADMIN="insert into public.admins (user_id, role) values ('$UID_', 'super_admin') on conflict (user_id) do nothing;
select set_config('request.jwt.claims', '{\"sub\": \"$UID_\", \"role\": \"authenticated\", \"aal\": \"aal2\"}', true);"
SHA=$(psql_ -tA -c "$AS_ADMIN select public.admin_put_image('$PNG_B64', 'image/png');" | tail -1)
expect 404 "$(image "$SHA")" "image envoyée mais pas publiée : jamais servie"
psql_ -tA -c "$AS_ADMIN update public.content_pictograms set image_sha256 = '$SHA' where code = 'CAA-CR-ACT-001';
  select public.admin_publish_content('e2e');" >/dev/null
expect 200 "$(image "$SHA")" "image publiée servie"
expect "$SHA" "$(sha256sum /tmp/premium.png | cut -d' ' -f1)" "octets identiques à l'envoi"
psql_ -tA -c "$AS_ADMIN update public.content_pictograms set image_sha256 = null where code = 'CAA-CR-ACT-001';
  select public.admin_publish_content('e2e : retour');
  delete from public.admins where user_id = '$UID_';" >/dev/null

# Abonnement révoqué : plus de jeton.
psql_ -c "update public.subscriptions set status = 'revoked' where user_id = '$UID_';"
expect 402 "$(code "$(call '{"fingerprint":"abcdefghijklmnop1234","platform":"android"}')")" "abonnement révoqué"
expect 402 "$(pack abcdefghijklmnop1234)" "paquet refusé sans abonnement"
expect 402 "$(image "$SHA")" "image refusée sans abonnement"

echo "TOUS LES TESTS E2E PASSENT"

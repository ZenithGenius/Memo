#!/usr/bin/env bash
# Test de bout en bout de la fonction issue-license contre la pile locale.
# Prérequis : `supabase start` et `supabase functions serve` en cours (voir backend/README.md).
set -euo pipefail
cd "$(dirname "$0")/../.."
eval "$(supabase status --workdir backend -o env 2>/dev/null | grep -E '^(ANON_KEY|API_URL)=')"

psql_() { docker exec -i supabase_db_memo psql -U postgres -q "$@"; }
call() {
  curl -s -w '\n%{http_code}' -X POST "$API_URL/functions/v1/issue-license" \
    -H "Authorization: Bearer $JWT" -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" -d "$1"
}
expect() { # attendu, obtenu, libellé
  if [ "$1" != "$2" ]; then echo "ECHEC $3: attendu $1, obtenu $2"; exit 1; fi
  echo "OK $3"
}

EMAIL="e2e$(date +%s)@test.local"
SIGNUP=$(curl -s -X POST "$API_URL/auth/v1/signup" -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL\",\"password\":\"Test-Pass-12345\"}")
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

# Abonnement révoqué : plus de jeton.
psql_ -c "update public.subscriptions set status = 'revoked' where user_id = '$UID_';"
expect 402 "$(code "$(call '{"fingerprint":"abcdefghijklmnop1234","platform":"android"}')")" "abonnement révoqué"

echo "TOUS LES TESTS E2E PASSENT"

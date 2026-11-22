#!/usr/bin/env bash
# Crée les secrets d'un environnement, une seule fois, sur le serveur :
#   bash init-env.sh production api.exemple.com admin.exemple.com 8100 8180 3100
# Écrit .env et s3.json (lecture réservée au propriétaire) sans jamais écraser
# un fichier existant. N'affiche que les valeurs publiques (clé anon, clé
# publique de licence), nécessaires pour construire l'application.
set -euo pipefail
cd "$(dirname "$0")"
ENVIRONMENT=${1:?environnement}
API_HOST=${2:?domaine de l\'API}
ADMIN_HOST=${3:?domaine du back-office}
API_PORT=${4:?port local de la passerelle}
ADMIN_PORT=${5:?port local du back-office}
STUDIO_PORT=${6:?port local de Studio}

if [ -e .env ] || [ -e s3.json ]; then
  echo ".env ou s3.json existe déjà : rien n'est modifié." >&2
  exit 1
fi
umask 077

b64url() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
jwt() {
  local header payload
  header=$(printf '%s' '{"alg":"HS256","typ":"JWT"}' | b64url)
  payload=$(printf '%s' "$1" | b64url)
  printf '%s.%s.%s' "$header" "$payload" \
    "$(printf '%s.%s' "$header" "$payload" | openssl dgst -binary -sha256 -hmac "$JWT_SECRET" | b64url)"
}

JWT_SECRET=$(openssl rand -hex 32)
iat=$(date +%s)
exp=$((iat + 5 * 365 * 24 * 3600))
ANON_KEY=$(jwt "{\"role\":\"anon\",\"iss\":\"supabase\",\"iat\":$iat,\"exp\":$exp}")
SERVICE_ROLE_KEY=$(jwt "{\"role\":\"service_role\",\"iss\":\"supabase\",\"iat\":$iat,\"exp\":$exp}")
S3_ACCESS_KEY=$(openssl rand -hex 16)
S3_SECRET_KEY=$(openssl rand -hex 32)

# Clé de signature des licences propre à l'environnement (ADR-004).
openssl genpkey -algorithm ed25519 -out license.pem 2>/dev/null
LICENSE_PRIVATE_KEY_PKCS8=$(openssl pkcs8 -topk8 -nocrypt -in license.pem -outform DER | base64 -w0)
LICENSE_PUBLIC_KEY=$(openssl pkey -in license.pem -pubout -outform DER | tail -c 32 | base64 -w0)
rm -f license.pem

cat > .env <<EOF
ENVIRONMENT=$ENVIRONMENT
COMPOSE_PROJECT_NAME=memo-$ENVIRONMENT
API_EXTERNAL_URL=https://$API_HOST
SITE_URL=https://$ADMIN_HOST
API_PORT=$API_PORT
ADMIN_PORT=$ADMIN_PORT
STUDIO_PORT=$STUDIO_PORT
ADMIN_TAG=latest

POSTGRES_PASSWORD=$(openssl rand -hex 24)
JWT_SECRET=$JWT_SECRET
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
PG_META_CRYPTO_KEY=$(openssl rand -hex 24)
DASHBOARD_USERNAME=memo
DASHBOARD_PASSWORD=$(openssl rand -hex 16)
S3_ACCESS_KEY=$S3_ACCESS_KEY
S3_SECRET_KEY=$S3_SECRET_KEY

LICENSE_KEY_ID=${ENVIRONMENT:0:1}1
LICENSE_PRIVATE_KEY_PKCS8=$LICENSE_PRIVATE_KEY_PKCS8
LICENSE_PUBLIC_KEY=$LICENSE_PUBLIC_KEY

# E-mails (Brevo) : à renseigner, puis « docker compose up -d auth ».
MAILER_AUTOCONFIRM=false
SMTP_ADMIN_EMAIL=
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_SENDER_NAME=Memo
EOF

cat > s3.json <<EOF
{
  "identities": [
    {
      "name": "storage",
      "credentials": [{ "accessKey": "$S3_ACCESS_KEY", "secretKey": "$S3_SECRET_KEY" }],
      "actions": ["Read:memo-storage", "Write:memo-storage", "List:memo-storage", "Tagging:memo-storage"]
    }
  ]
}
EOF
# SeaweedFS lit s3.json avec son propre utilisateur.
chmod 644 s3.json

echo "Environnement $ENVIRONMENT créé."
echo "Valeurs publiques, pour construire l'application :"
echo "  SUPABASE_URL=https://$API_HOST"
echo "  SUPABASE_ANON_KEY=$ANON_KEY"
echo "  LICENSE_PUBLIC_KEY (kid ${ENVIRONMENT:0:1}1)=$LICENSE_PUBLIC_KEY"

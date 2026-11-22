#!/usr/bin/env bash
# Crée les secrets de Kiwi TCMS, une seule fois, sur le serveur :
#   bash init-env.sh tests.exemple.com
set -euo pipefail
cd "$(dirname "$0")"
[ -e .env ] && { echo ".env existe déjà : rien n'est modifié." >&2; exit 1; }
umask 077
cat > .env <<CONF
KIWI_DOMAIN=${1:?domaine de Kiwi}
KIWI_SECRET_KEY=$(openssl rand -hex 32)
KIWI_DB_PASSWORD=$(openssl rand -hex 24)
KIWI_DB_ROOT_PASSWORD=$(openssl rand -hex 24)
# E-mails (mêmes accès Brevo que Memo), facultatif.
KIWI_EMAIL_FROM=
KIWI_SMTP_HOST=
KIWI_SMTP_PORT=587
KIWI_SMTP_USER=
KIWI_SMTP_PASS=
CONF
echo ".env de Kiwi créé."

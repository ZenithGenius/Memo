#!/usr/bin/env bash
# Déploie la pile d'un environnement, depuis son dossier sur le serveur
# (/srv/memo/production ou /srv/memo/staging). Lancé par GitHub Actions :
#   ADMIN_TAG=<sha> bash deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "ERREUR : .env absent, lancer d'abord init-env.sh." >&2; exit 15; }
# La version demandée par l'appelant l'emporte sur celle du .env.
TAG_ARG=${ADMIN_TAG:-}
set -a; . ./.env; set +a
export ADMIN_TAG=${TAG_ARG:-${ADMIN_TAG:-latest}}
dc() { docker compose "$@"; }

wait_healthy() {
  local s
  for s in "$@"; do
    echo "attente de $s"
    timeout 180 bash -c "until [ \"\$(docker inspect -f '{{.State.Health.Status}}' \"\$(docker compose ps -q $s)\" 2>/dev/null)\" = healthy ]; do sleep 3; done" || {
      echo "ERREUR : $s ne démarre pas." >&2; dc logs --tail 60 "$s" >&2; exit 1; }
  done
}

# Routeur des fonctions serveur à côté des fonctions de l'application.
rm -rf functions/main && cp -r functions-main functions/main

# ADMIN_TAG=local : image chargée à la main (docker load), rien à télécharger pour elle.
if [ "$ADMIN_TAG" = local ]; then
  dc pull --quiet $(dc config --services | grep -vx admin)
else
  dc pull --quiet
fi
dc up -d db seaweedfs
wait_healthy db seaweedfs
# Compartiment des images ; « already exists » au deuxième passage.
dc exec -T seaweedfs sh -c 'echo "s3.bucket.create -name memo-storage" | weed shell' >/dev/null 2>&1 || true

# Auth et Storage créent leurs schémas au démarrage ; les migrations de
# l'application s'appuient dessus.
dc up -d auth rest storage admin
wait_healthy auth storage
bash migrate.sh

dc up -d --remove-orphans
wait_healthy api-gw functions rest admin

echo "vérification par la passerelle"
curl -fsS -o /dev/null "http://127.0.0.1:$API_PORT/auth/v1/health" -H "apikey: $ANON_KEY"
curl -fsS -o /dev/null "http://127.0.0.1:$API_PORT/rest/v1/plans?select=code&limit=1" -H "apikey: $ANON_KEY"
curl -fsS -o /dev/null "http://127.0.0.1:$ADMIN_PORT/"
docker image prune -f >/dev/null
echo "Déploiement $ENVIRONMENT terminé (back-office $ADMIN_TAG)."

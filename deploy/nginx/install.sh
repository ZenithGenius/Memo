#!/usr/bin/env bash
# Installe les sites nginx de Memo et leur certificat Let's Encrypt.
# Idempotent ; à lancer en root depuis ce dossier, avec le domaine du serveur
# (les sites citent api.<domaine>, admin.<domaine>, staging-api.<domaine>,
# staging-admin.<domaine>) :
#   sudo DOMAIN=exemple.com bash install.sh
set -euo pipefail
cd "$(dirname "$0")"
D=${DOMAIN:?DOMAIN manquant (ex. : DOMAIN=exemple.com)}
[[ $D =~ ^[a-z0-9.-]+$ ]] || { echo "DOMAIN invalide : $D" >&2; exit 1; }
NAMES=(api.$D admin.$D staging-api.$D staging-admin.$D)
SITES=(default-deny memo-api memo-admin memo-staging-api memo-staging-admin)

install -m 644 snippets/*.conf /etc/nginx/snippets/
install -d -m 755 /var/www/certbot

# Premier passage : un site provisoire sur le port 80 répond au défi
# Let's Encrypt, le temps d'obtenir le certificat que les sites HTTPS citent.
if [ ! -f /etc/letsencrypt/live/memo/fullchain.pem ]; then
  cat > /etc/nginx/sites-enabled/memo-acme <<CONF
server {
    listen 80;
    server_name ${NAMES[*]};
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
}
CONF
  nginx -t && systemctl reload nginx
  args=(); for n in "${NAMES[@]}"; do args+=(-d "$n"); done
  certbot certonly --webroot -w /var/www/certbot --cert-name memo \
    --non-interactive --agree-tos --register-unsafely-without-email "${args[@]}"
  rm -f /etc/nginx/sites-enabled/memo-acme
fi

for s in "${SITES[@]}"; do
  sed "s/__DOMAIN__/$D/g" "sites-available/$s" > "/etc/nginx/sites-available/$s"
  chmod 644 "/etc/nginx/sites-available/$s"
  ln -sf "/etc/nginx/sites-available/$s" "/etc/nginx/sites-enabled/$s"
done
printf '#!/bin/sh\nsystemctl reload nginx\n' > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
nginx -t
systemctl reload nginx

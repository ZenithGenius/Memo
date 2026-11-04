#!/bin/sh
# Génère config.js depuis l'environnement au démarrage du conteneur (rien
# n'est écrit dans l'image). Même convention que le reste du dépôt : tout
# passe par l'environnement, jamais de valeur en dur dans le code.
set -eu

: "${SUPABASE_URL:?SUPABASE_URL requis}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY requis}"

cat > /usr/share/nginx/html/config.js <<EOF
export const SUPABASE_URL = "${SUPABASE_URL}";
export const SUPABASE_ANON_KEY = "${SUPABASE_ANON_KEY}";
EOF

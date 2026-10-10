#!/bin/sh
# Génère config.js depuis l'environnement à chaque démarrage : rien n'est
# écrit dans l'image.
set -eu
: "${SUPABASE_URL:?SUPABASE_URL requis}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY requis}"

js_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

cat > /usr/share/nginx/html/config.js <<CONF
window.MEMO_CONFIG = {
  supabaseUrl: "$(js_escape "$SUPABASE_URL")",
  supabaseAnonKey: "$(js_escape "$SUPABASE_ANON_KEY")",
};
CONF

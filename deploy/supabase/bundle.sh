#!/usr/bin/env bash
# Assemble le paquet à envoyer sur le serveur, à partir des seuls fichiers
# versionnés (git archive) : aucun .env local ne peut partir.
#   bash deploy/supabase/bundle.sh <sortie.tar.gz> [révision]
set -euo pipefail
OUT=$(realpath "${1:?archive de sortie}")
REV=${2:-HEAD}
ROOT=$(git rev-parse --show-toplevel)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

git -C "$ROOT" archive "$REV" deploy/supabase backend/supabase/migrations \
  backend/supabase/functions backend/supabase/templates | tar -x -C "$TMP"

B=$TMP/bundle
mv "$TMP/deploy/supabase" "$B"
rm -f "$B/bundle.sh"
mv "$TMP/backend/supabase/migrations" "$B/migrations"
mv "$TMP/backend/supabase/functions" "$B/functions"
mv "$TMP/backend/supabase/templates" "$B/templates"
# Fichiers d'exemple et tests : inutiles sur le serveur.
find "$B/functions" \( -name '*_test.ts' -o -name '.env*' \) -delete

tar -C "$B" -czf "$OUT" .
echo "$OUT"

#!/usr/bin/env bash
# Lint, format et tests unitaires des fonctions serveur, dans un conteneur Deno.
# Usage : run_deno.sh [fix]   ("fix" applique le formatage au lieu de le vérifier)
set -euo pipefail
cd "$(dirname "$0")/../.."
IMAGE="${DENO_IMAGE:-denoland/deno:alpine-2.1.4}"
MODE="${1:-check}"

run() { docker run --rm -v "$PWD/backend/supabase/functions:/app$2" -w /app "$IMAGE" "${@:3}"; }

if [ "$MODE" = fix ]; then
  run x "" deno fmt
  exit 0
fi
run x ":ro" deno fmt --check
run x ":ro" deno lint
run x ":ro" deno test --no-lock --quiet

#!/usr/bin/env bash
# Applique les migrations du dépôt qui ne l'ont pas encore été, une par
# transaction, et les note dans la même table que la CLI Supabase
# (supabase_migrations.schema_migrations). Une migration en échec arrête tout
# sans rien laisser à moitié appliqué.
set -euo pipefail
cd "$(dirname "$0")"

psql() { docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -qAt "$@"; }

psql -c "create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key, statements text[], name text);"

applied=$(psql -c "select version from supabase_migrations.schema_migrations")
for f in migrations/*.sql; do
  name=$(basename "$f" .sql)
  version=${name%%_*}
  if grep -qx "$version" <<<"$applied"; then continue; fi
  echo "migration $name"
  { echo "begin;"; cat "$f"; echo ";"
    echo "insert into supabase_migrations.schema_migrations (version, name) values ('$version', '${name#*_}');"
    echo "commit;"; } | psql
done
# PostgREST relit le schéma (nouvelles tables et fonctions).
psql -c "notify pgrst, 'reload schema';"

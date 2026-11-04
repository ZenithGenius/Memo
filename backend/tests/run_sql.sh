#!/usr/bin/env bash
# Migrations puis tests SQL sur un PostgreSQL nu, avec la doublure de Supabase
# (support/supabase_stub.sql). Connexion par les variables libpq habituelles :
# PGHOST, PGPORT, PGUSER, PGPASSWORD. La base MEMO_TEST_DB est recréée.
set -euo pipefail
cd "$(dirname "$0")/../.."
DB="${MEMO_TEST_DB:-memo_test}"
run() { psql -X -q -v ON_ERROR_STOP=1 "$@"; }

run -d postgres -c "drop database if exists $DB" -c "create database $DB"
PGOPTIONS="-c client_min_messages=warning" run -d "$DB" -f backend/tests/support/supabase_stub.sql
for m in backend/supabase/migrations/*.sql; do
  echo "migration $(basename "$m")"
  run -d "$DB" -f "$m"
done

failed=0
for t in backend/tests/*.sql; do
  if out=$(run -d "$DB" -f "$t" 2>&1); then
    echo "OK   $(basename "$t") ($(grep -c 'NOTICE:  OK ' <<<"$out") vérifications)"
  else
    echo "ECHEC $(basename "$t")"
    grep -E 'ERROR|ECHEC' <<<"$out" | head -5
    failed=1
  fi
done
exit "$failed"

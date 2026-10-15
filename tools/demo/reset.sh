#!/usr/bin/env bash
# Remet la démonstration à zéro : application comme neuve (première
# installation) et compte parent de démonstration supprimé, pour rejouer tout
# le parcours en direct. Les autres comptes et paiements sont conservés.
set -euo pipefail
DEMO_EMAIL="${MEMO_DEMO_EMAIL:-parent.demo@memo.test}"
API=http://127.0.0.1:54321
SR=$(supabase status --workdir "$(dirname "$0")/../../backend" -o json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['SERVICE_ROLE_KEY'])")

ID=$(curl -s "$API/auth/v1/admin/users?per_page=1000" -H "apikey: $SR" -H "Authorization: Bearer $SR" \
  | python3 -c "import json,sys; print(next((u['id'] for u in json.load(sys.stdin)['users'] if u['email']=='$DEMO_EMAIL'), ''))")
if [ -n "$ID" ]; then
  curl -s -o /dev/null -X DELETE "$API/auth/v1/admin/users/$ID" -H "apikey: $SR" -H "Authorization: Bearer $SR"
  echo "Compte $DEMO_EMAIL supprimé."
else
  echo "Aucun compte $DEMO_EMAIL à supprimer."
fi

adb shell pm clear com.creyativ.memo >/dev/null && echo "Application remise à zéro."
adb shell monkey -p com.creyativ.memo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

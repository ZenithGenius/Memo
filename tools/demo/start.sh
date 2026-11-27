#!/usr/bin/env bash
# Démarre toute la démonstration en local : Supabase (avec stockage), migrations,
# fonctions serveur, back-office (http://127.0.0.1:8787), émulateur Android et
# application connectée au serveur local.
# Prérequis : backend/supabase/functions/.env, apps/memo_app/env/dev.json et
# apps/admin/.env renseignés (voir les README).
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT=$PWD
AVD="${MEMO_DEMO_AVD:-TestLab_x64}"
LOG="${TMPDIR:-/tmp}/memo-demo"; mkdir -p "$LOG"

echo "1/6 Supabase"
supabase start --workdir backend -x realtime,imgproxy,mailpit,postgres-meta,studio,logflare,vector,supavisor >/dev/null
supabase migration up --workdir backend --local >/dev/null

echo "2/6 Fonctions serveur (journal : $LOG/functions.log)"
if ! pgrep -f "[s]upabase functions serve" >/dev/null; then
  nohup supabase functions serve --workdir backend --env-file backend/supabase/functions/.env >"$LOG/functions.log" 2>&1 &
fi

echo "3/6 Back-office (http://127.0.0.1:8787)"
(cd apps/admin && docker compose -p memo-demo up -d --build >/dev/null)

echo "4/6 Émulateur $AVD"
if ! adb devices | grep -q "emulator-"; then
  nohup "$HOME/Android/Sdk/emulator/emulator" -avd "$AVD" -no-snapshot-save -no-boot-anim >"$LOG/emulator.log" 2>&1 &
fi
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 3; done

echo "5/6 Application (variante prod, serveur local)"
APK=apps/memo_app/build/app/outputs/flutter-apk/app-prod-debug.apk
if [ ! -f "$APK" ]; then
  (cd apps/memo_app && flutter build apk --flavor prod --debug --dart-define-from-file=env/dev.json >/dev/null)
fi
adb install -r "$APK" >/dev/null

echo "6/6 Lancement"
adb shell monkey -p com.creyativ.memo -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
echo "Prêt. Back-office : http://127.0.0.1:8787, application ouverte sur l'émulateur."

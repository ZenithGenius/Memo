#!/usr/bin/env bash
# Échoue sur toute vulnérabilité HIGH/CRITICAL corrigeable, tout secret et toute
# mauvaise configuration HIGH/CRITICAL du dépôt (lockfile pub, Gradle, workflows CI).
set -euo pipefail
cd "$(dirname "$0")/../.."
exec trivy fs --no-progress --timeout 30m --exit-code 1 \
  --scanners vuln,secret,misconfig \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --skip-dirs docs --skip-dirs guides --skip-dirs .dart_tool --skip-dirs build \
  --skip-dirs design --skip-dirs .superpowers \
  .

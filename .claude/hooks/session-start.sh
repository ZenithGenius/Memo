#!/bin/bash
# Claude Code sur le web : installe le SDK Flutter épinglé en CI, les
# dépendances pub et le code généré (drift), pour analyze et test.
# Le SDK Android n'est pas installé : l'APK est construit par la CI.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"
VERSION=$(grep -m1 -oP 'flutter-version:\s*\K[\d.]+' .github/workflows/ci.yml)
FLUTTER_ROOT=/opt/flutter

if ! "$FLUTTER_ROOT/bin/flutter" --version 2>/dev/null | grep -q "Flutter $VERSION "; then
  rm -rf "$FLUTTER_ROOT"
  curl -sSfL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt
fi
git config --global --add safe.directory "$FLUTTER_ROOT" 2>/dev/null || true
export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter config --no-analytics --no-cli-animations >/dev/null 2>&1
echo "export PATH=\"$FLUTTER_ROOT/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

cd apps/memo_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs

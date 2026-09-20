# Memo

Application mobile de communication alternative et améliorée (CAA) par pictogrammes, utilisable sans connexion, sur Android et iOS.

## Organisation du dépôt

- `apps/memo_app` : application Flutter
- `adr/` : décisions d'architecture
- `specs/` : conception
- `plans/` : plans d'implémentation par jalon
- `tools/` : outils de génération (paquet de contenu)
- `.github/workflows/` : intégration continue

## Démarrage

Prérequis : Flutter 3.41.5 (Dart 3.11.3), SDK Android.

```bash
cd apps/memo_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Qualité

```bash
flutter analyze
flutter test
flutter test integration_test -d <appareil>
```

## Contrôles avant commit et avant push

Installation unique (nécessite `pre-commit`, `trivy` et Go) :

```bash
pre-commit install --install-hooks
```

À chaque commit :

- fichiers : conflits de fusion, clés privées, gros fichiers, YAML et JSON valides
- secrets : gitleaks
- Dart : `dart format`, `flutter analyze --fatal-infos`, `flutter test`
- message de commit : format conventionnel

À chaque push (et en CI) :

- trivy : vulnérabilités HIGH et CRITICAL des dépendances, secrets, mauvaises configurations
- `tools/security/check_eol.py` : paquets abandonnés, retirés ou visés par un avis de sécurité pub.dev, SDK Flutter en retard de deux versions mineures ou plus

Lancer tout à la main : `pre-commit run --all-files` puis `pre-commit run --all-files --hook-stage pre-push`.

Dependabot propose chaque semaine les mises à jour des paquets pub et des actions GitHub.

Regénérer le paquet de contenu embarqué : `python3 tools/generate_content_pack.py`.

## Conventions

- Commits conventionnels (`feat:`, `fix:`, `test:`, `chore:`, `docs:`).
- Aucune chaîne en dur dans l'interface : tout passe par `lib/l10n/app_fr.arb`.
- La couche domaine ne dépend ni de Flutter ni de drift.

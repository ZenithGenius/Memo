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

Regénérer le paquet de contenu embarqué : `python3 tools/generate_content_pack.py`.

## Conventions

- Commits conventionnels (`feat:`, `fix:`, `test:`, `chore:`, `docs:`).
- Aucune chaîne en dur dans l'interface : tout passe par `lib/l10n/app_fr.arb`.
- La couche domaine ne dépend ni de Flutter ni de drift.

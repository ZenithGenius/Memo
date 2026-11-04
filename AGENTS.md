# Memo : règles et carte du projet

Application de communication alternative et améliorée (CAA) par pictogrammes, pour le client CREYATIV (marché camerounais, prix en FCFA). Documentation, messages de commit et interface en français.

## Carte

- `apps/memo_app` : application Flutter (Riverpod, drift, flutter_tts), variantes `prod` et `dev`.
- `apps/admin` : back-office React + TypeScript (ADR-009), servi en conteneur sur http://127.0.0.1:8787 en local.
- `backend/supabase` : Supabase auto-hébergé (migrations, fonctions Deno `issue-license`, `premium-pack`, `premium-image`).
- `adr/` : décisions d'architecture. `specs/`, `plans/` : conception et plans par jalon.
- `tools/` : génération du paquet de contenu, contrôles de sécurité, démonstration locale (`tools/demo/` sur la branche `demo/presentation`).
- `docs/` : ignoré par Git (cahier des charges, cahier de recette), reste local.

## Environnements

- Local : `supabase start --workdir backend`, fonctions avec `supabase functions serve --workdir backend --env-file backend/supabase/functions/.env`, back-office avec `docker compose -p memo-demo up -d` dans `apps/admin`.
- Application : `--dart-define-from-file=env/dev.json`. Sur émulateur, le serveur est `http://10.0.2.2:54321` ; sur un vrai téléphone, l'adresse Wi-Fi du PC (APK à recompiler si elle change).
- Pas encore de production.

## Branches et PR

Chaîne de PR à fusionner dans l'ordre, par le propriétaire du dépôt uniquement : #16 → #29 → #30 → #32, et #4 → #31. `demo/presentation` intègre le tout pour les démonstrations et la recette.

## Règles de travail

- Ne jamais fusionner une PR soi-même.
- Aucun secret dans le dépôt : `backend/supabase/functions/.env`, `apps/memo_app/env/dev.json`, `apps/admin/.env`, `apps/admin/public/config.js` sont ignorés. Jamais de clé `service_role` côté navigateur ou application.
- Aucun détail d'implémentation dans l'interface ou les fichiers servis : message générique à l'écran, détail en console.
- Pas de tiret cadratin dans les documents, commits et PR.
- Tickets au format : En une phrase / Exigence / Constat / Travail attendu / Critère de validation, ajoutés au projet GitHub n°2.
- Retours de recette : un ticket par retour, vérifié dans le code, sans développer tant que ce n'est pas demandé.
- `docker compose` (v2) uniquement.

## Suivi

- État courant : `.agents/STATUS.md`.
- Historique des séances : `.agents/JOURNAL.md`.

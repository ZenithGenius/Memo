# Memo : conception de l'application mobile (M0 et M1)

Statut : validé le 2026-09-20. Référence produit : cahier des charges Memo v3.1.

## 1. Objectif

Livrer une application Flutter de communication alternative et améliorée (CAA), publiée sur Android et iOS à partir d'une base de code unique, utilisable sans connexion, et construite pour évoluer vers le contenu versionné, les comptes et la licence sans réécriture.

Ce document couvre les jalons M0 (fondations) et M1 (communication hors ligne). Les jalons M2 à M5 sont décrits au niveau architecture uniquement.

## 2. Décisions d'architecture

| Réf. | Décision | Justification |
|---|---|---|
| ADR-001 | Flutter et Dart, une base de code pour Android et iOS | Hors ligne robuste, publication simultanée |
| ADR-002 | Base SQLite locale (drift) comme source de vérité | Hors ligne natif, requêtes typées, migrations, flux réactifs |
| ADR-003 | Riverpod pour l'état et l'injection de dépendances | Sûr à la compilation, testable |
| ADR-004 | Jeton de licence signé (Ed25519), vérifié localement | Abonnement non falsifiable hors ligne |
| ADR-005 | Monorepo avec pub workspaces (sans outil externe) | Cohérence, simplicité |
| ADR-006 | Supabase pour le backend (à partir de M2) | Postgres, authentification, stockage, fonctions |
| ADR-007 | Identifiant d'application com.creyativ.memo | Décision du porteur de projet, définitif après publication |

## 3. Structure du dépôt

```
apps/memo_app/            application Flutter
packages/                 paquets Dart partagés (créés quand un second consommateur existe)
backend/                  migrations et fonctions Supabase (M2)
adr/                      décisions d'architecture
specs/                    spécifications
.github/workflows/        intégration continue
```

Règle : un paquet est extrait dans `packages/` seulement quand un deuxième consommateur en a besoin (back office, M4). Avant cela tout reste dans `apps/memo_app`.

## 4. Architecture de l'application

Organisation par fonctionnalité, chaque fonctionnalité en trois couches.

```
lib/
  core/            thème, routage, erreurs, utilitaires, i18n
  data/            base drift, source de contenu, dépôts concrets
  features/
    onboarding/    presentation / domain / data
    home/
    categories/
    message/       construction de la phrase, lecture vocale
    favorites/
    board/         « Mon tableau »
    profiles/      profils et niveaux
    settings/
```

Règles :
- la couche domaine ne dépend d'aucun paquet Flutter ni drift ;
- la présentation ne lit que des cas d'usage et des dépôts abstraits ;
- toute donnée affichée vient de la base locale, jamais directement d'un fichier ou d'un réseau ;
- aucune chaîne en dur dans l'interface (ARB).

## 5. Modèle de données local (drift)

| Table | Rôle |
|---|---|
| categories, category_translations | Catégories et libellés par langue |
| pictograms, pictogram_translations | Pictogrammes (code CAA-CR-…, image, version, niveau, public) et libellés par langue, avec le texte à prononcer |
| profiles | Profils (enfant, adolescent, adulte, accompagnant) et niveau |
| boards, board_cells | « Mon tableau » : disposition et cases |
| favorites | Favoris par profil (pictogramme ou phrase) |
| quick_phrases | Phrases rapides par profil |
| settings | Réglages clé et valeur |
| content_meta | Version du contenu installé |

Le mot est toujours une donnée séparée de l'image (exigence du cahier des charges).

## 6. Contenu embarqué (M1)

Un paquet de contenu versionné livré dans l'application : un manifeste JSON (catégories, pictogrammes, traductions, chemins d'images) et un dossier d'images. Au premier lancement il est importé dans la base. Ce même format sera celui des mises à jour téléchargées en M2, ce qui évite un second mécanisme.

Pour M1 le paquet contient la catégorie CBE complète (20 concepts prioritaires) et des catégories réduites servant de démonstration. Les images définitives ne sont pas disponibles : le paquet utilise des visuels provisoires générés, remplaçables sans changer le code. Les 40 échantillons de la charte servent de démonstration, marqués comme non validés (mot incrusté, styles mêlés).

## 7. Lecture vocale et composition de la phrase

- Interface `SpeechService` (implémentation `flutter_tts`, fausse implémentation pour les tests).
- Interface `PhraseComposer` : transforme une suite de pictogrammes en texte prononcé.
- M1 : concaténation des textes à prononcer, avec un champ par pictogramme pour la forme parlée. Les règles de grammaire (« Je veux de l'eau ») sont une amélioration ultérieure derrière la même interface.
- Au démarrage, l'application vérifie la présence d'une voix française et guide l'utilisateur sinon.

## 8. Exigences couvertes par M1

EF-01 à EF-04, EF-06, EF-09 à EF-12 (hors photos), EF-14, EF-15, EF-16 (français), EF-18. Reportés : EF-05 (phrases rapides, minimal), EF-07, EF-08, EF-13, EF-17 et suivants.

## 9. Qualité

- Analyse statique stricte, aucun avertissement toléré en CI.
- Tests unitaires du domaine et des dépôts (drift en mémoire), tests de widgets, tests golden des écrans clés, un test d'intégration du parcours « JE VEUX EAU ».
- Accessibilité : zones tactiles d'au moins 48 dp, contrastes, rendu à taille de texte agrandie testé.
- Intégration continue : analyse, tests, construction Android ; construction iOS sur runner macOS à partir de M5.
- Commits conventionnels, une branche par fonctionnalité, revue avant fusion.

## 10. Critères de sortie

**M0** : dépôt initialisé, CI verte, application vide au thème Sahel Warmth qui démarre sur l'émulateur, ADR-001 à ADR-007 rédigés.

**M1** : le parcours « Accueil, Besoins, JE VEUX, EAU, lecture » fonctionne en mode avion sur l'émulateur ; profils, niveaux, favoris et tableau persistent après redémarrage ; suite de tests verte.

## 11. Risques

- Voix française hors ligne absente sur certains téléphones.
- Pictogrammes définitifs non prêts : le contenu est remplaçable par données.
- Aucune vérification iOS locale avant la CI macOS.
- Paiement dans l'application face aux règles des boutiques : à trancher avant M3.

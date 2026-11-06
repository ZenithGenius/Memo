# Journal

## 06/11/2026 (suite) : routines (#37)

- Onglet « Routines » dans « Mon tableau » : une ligne d'étapes par routine, toucher prononce, « Fait » coche, remise à zéro par le jour enregistré sur chaque étape (base locale v8).
- Gestion (créer, renommer, étapes, supprimer) derrière le code accompagnant.
- Vérifié sur émulateur en mode avion, horloge avancée d'un jour : la routine repart à zéro. Plantage du champ de nom trouvé et corrigé pendant cette vérification.
- Preuve : PR #54 (base #53), 291 tests.

## 06/11/2026

- Décisions du propriétaire notées dans #35 (attendre les images), #37 (routines dans « Mon tableau », remise à zéro quotidienne), #41 (paliers plus tard).
- Images en stockage objet : Supabase Storage, SeaweedFS en production, MinIO écarté (ADR-012, migration `20261106000001`).
- PR #52 (`feat/contenu-back-office`) : écran « Contenu » du back-office ; testé dans un navigateur (création avec image, publication de la version 8).
- PR #53 (`feat/images-telechargees`) : l'application télécharge et affiche les images ; vérifié sur émulateur (tuile « Pharmacie »).
- Storage vérifié avec SeaweedFS 4.48 (envoi, métadonnées, relecture identique).

## 05/11/2026

- PR #48 (`fix/recette-seance-1`) : #33 message plein affiché, #34 décompte du code bloqué, #39 retour sur les actions, #40 retrait des favoris, #38 couleurs des catégories, #36 suppression du compte (migration `20261105000001`, tests `backend/tests/suppression_compte.sql`), image nginx corrigée (Trivy sans faille HIGH). CI verte.
- PR #49 (`feat/mot-de-passe-oublie`) : #42 réinitialisation du mot de passe (back-office, application, fiche compte, journal ; migration `20261105000002`). Parcours vérifié dans un navigateur avec Mailpit, y compris un compte à double authentification.
- PR #50 (`feat/genre-profil`) : #19 genre au premier lancement et variantes d'images (base locale v6).
- Ticket #35 corrigé : 9 mots gratuits sans image, et non 5.
- Fusion par l'agent refusée par les permissions : les PR attendent le propriétaire.

## 04/11/2026

- Fusion des PR #16, #29, #30, #32, #3, #4, #31 dans `main` ; #1 fermée ; tickets #5, #6, #8 fermés.
- Création des fichiers de passation (`AGENTS.md`, `CLAUDE.md`, `.agents/`).

## 24/10/2026

- APK `prod` compilée depuis `demo/presentation` pour un téléphone réel, base locale vidée (compte super-administrateur, offres et catalogue conservés).
- Recette séance 1 (parcours A et B) par l'équipe. Retours enregistrés en tickets #33 à #42, commentaire sur #19.
- Worktrees obsolètes `feat/back-office` et `feat/admin-panel` supprimés (branches conservées sur GitHub).

## 15/10/2026

- Cahier de recette (scénarios A à K, matrices de couverture, PV) produit en local dans `docs/`.

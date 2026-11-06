# État du projet

Mis à jour le 06/11/2026.

## Bloqué / urgent

- PR à fusionner par le propriétaire, dans l'ordre : #48 (corrections de recette), #49 (mot de passe oublié), #50 (genre du profil), #52 (écran Contenu, images en stockage objet), #53 (images affichées dans l'application), #54 (routines). Chaque PR part de la précédente.
- PR Dependabot : #44 à fermer (dossier `backend/admin` supprimé), #45 rendue inutile par #48 (même image nginx), #43, #46, #47 à examiner.
- Images à fournir par CREYATIV : 9 des 20 mots gratuits sans pictogramme (#35), 23 pictogrammes payants sur 131 avec image, aucune variante fille ou garçon (#19).
- Bloquants boutiques restants : politique de confidentialité publiée, version iOS (#13), SMTP de production pour les e-mails.

## En cours / à faire

- Recette : séance 1 faite le 24/10/2026. Séances 2 et 3 à faire après fusion des PR.
- Évolutions : #41 (paquet gratuit réglable, paliers décidés plus tard avec le client), variantes fille ou garçon côté serveur (#19).
- Production : déployer SeaweedFS (`backend/storage`) derrière Supabase Storage, sauvegarder son volume avec la base (ADR-012).
- Le sélecteur de pictogrammes (grille et routines) passe en partie sous la barre du message : à corriger.
- #38 : validation de la palette des catégories par CREYATIV.
- Corrections du cahier de recette en attente (sur demande seulement) : Brice créé en B08, B04 reporté en séance 2, chemin de suppression d'un profil, nombre réel de mots gratuits sans image.

## Référence

- Tableau : https://github.com/users/ZenithGenius/projects/2
- Cahier de recette (local) : `docs/Cahier de recette - Memo.pdf`, source `docs/recette/recette.md`.
- Tests SQL locaux : `PGHOST=localhost PGPORT=55432 PGUSER=postgres PGPASSWORD=postgres bash backend/tests/run_sql.sh` sur un conteneur `postgres:16-alpine`.
- E-mails en local : Supabase démarré sans exclure Mailpit (http://127.0.0.1:54324).

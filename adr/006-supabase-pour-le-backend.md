# ADR-006 : Supabase pour le backend

Statut : accepté (2026-09-20)

## Contexte

Il faut une base relationnelle, une authentification, un stockage de fichiers et des fonctions serveur, gérés par un développeur seul.

## Décision

Utiliser une plateforme de type Supabase à partir de M2, migrations versionnées dans backend/.

## Conséquences

Développement rapide, PostgreSQL standard, portabilité si besoin.

## Alternatives écartées

Backend sur mesure : plus de code et d'exploitation. Firebase : modèle NoSQL moins adapté.

## Mise à jour (2026-09-21)

Supabase est auto-hébergé dans des conteneurs Docker, en développement comme en production (fichier `compose.yaml`, commande `docker compose`). Aucun compte cloud n'est requis. Le déploiement de production (serveur, région, sauvegardes) reste à définir.

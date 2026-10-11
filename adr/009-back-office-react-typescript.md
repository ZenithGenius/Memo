# ADR-009 : Back-office en React et TypeScript

Statut : accepté (2026-10-10)

## Contexte

Le panneau d'administration a commencé en page statique sans compilation
(HTML et JavaScript). Le porteur de projet demande un back-office complet,
« pour tout gérer depuis un point central » : tableau de bord, comptes,
abonnements et paiements, offres, appareils, administrateurs, journal
d'activité, contenu. Une dizaine de modules avec formulaires, validation,
filtres, graphiques et rôles ne se maintient pas sans types ni composants.

## Décision

Reprendre la pile du back-office COLI, déjà connue de l'équipe :
React, TypeScript strict, Vite, TanStack Query, Zod, react-hook-form,
Tailwind, Recharts, Vitest. Application dans `apps/admin`, servie en
fichiers statiques par nginx non-root dans un conteneur.

Supabase reste le seul serveur : les droits sont appliqués par la sécurité
par ligne et des fonctions SQL réservées aux administrateurs (rôles
`super_admin` et `support`), jamais par l'interface seule.

## Conséquences

- Types générés depuis le schéma, tests unitaires des calculs, lint strict.
- Une chaîne Node (24 LTS) s'ajoute au dépôt Flutter : dépendances figées
  par `package-lock.json`, installées sans scripts, scannées par Trivy en CI.
- L'ancien panneau `backend/admin` est retiré.

## Alternatives écartées

- Page statique découpée en modules JavaScript : rapide à étendre, mais sans
  types ni tests, difficile à garder cohérente au-delà de quelques écrans.
- Flutter Web : un seul langage dans le dépôt, mais rendu et accessibilité
  moins adaptés à un outil de gestion riche en tableaux et formulaires.
- Supabase Studio : outil de développeur, pas de parcours métier ni de rôles.

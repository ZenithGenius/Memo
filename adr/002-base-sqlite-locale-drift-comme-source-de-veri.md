# ADR-002 : Base SQLite locale (drift) comme source de vérité

Statut : accepté (2026-09-20)

## Contexte

Toutes les données affichées doivent rester disponibles sans réseau et évoluer avec des migrations sûres.

## Décision

Stocker catalogue et données utilisateur dans SQLite via drift. L'interface lit uniquement la base.

## Conséquences

Requêtes typées, flux réactifs, migrations versionnées. La synchronisation (M2) écrit dans la base, jamais dans l'interface.

## Alternatives écartées

Fichiers JSON lus directement : pas de requêtes ni de migrations. Isar ou Hive : moins standard pour du relationnel.

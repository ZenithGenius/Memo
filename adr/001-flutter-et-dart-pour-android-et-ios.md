# ADR-001 : Flutter et Dart pour Android et iOS

Statut : accepté (2026-09-20)

## Contexte

Le produit doit fonctionner hors connexion et sortir sur Android et iOS dès la première version, avec une équipe réduite.

## Décision

Utiliser Flutter et Dart, une seule base de code pour Android et iOS (téléphones et tablettes).

## Conséquences

Un seul code à maintenir et à tester ; base locale et stockage sécurisé disponibles. Les builds iOS exigent macOS (intégration continue).

## Alternatives écartées

Développement natif Android puis iOS : plus coûteux et plus long. Architecture hybride web : moins adaptée au hors ligne et à la lecture vocale.

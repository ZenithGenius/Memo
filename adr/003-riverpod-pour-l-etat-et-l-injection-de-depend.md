# ADR-003 : Riverpod pour l'état et l'injection de dépendances

Statut : accepté (2026-09-20)

## Contexte

Il faut un état testable, réactif aux flux de la base et sans code de liaison lourd.

## Décision

Utiliser Riverpod. Les dépôts et services sont fournis par des providers, remplaçables dans les tests.

## Conséquences

Sûreté à la compilation, tests simples par surcharge de providers.

## Alternatives écartées

Bloc : plus cérémonieux pour ce périmètre. Provider : ancien, moins sûr.

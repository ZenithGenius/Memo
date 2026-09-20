# ADR-005 : Monorepo avec pub workspaces

Statut : accepté (2026-09-20)

## Contexte

Application, back office et backend évoluent ensemble et partageront du code.

## Décision

Un dépôt unique, workspace Dart natif. Un paquet n'est extrait dans packages/ que lorsqu'un second consommateur existe.

## Conséquences

Cohérence des versions sans outil supplémentaire.

## Alternatives écartées

Melos : outil en plus sans besoin actuel. Dépôts séparés : synchronisation coûteuse.

# ADR-013 : Paquet gratuit réglé depuis le back-office

Statut : accepté (2026-11-06). Complète l'ADR-008 (contenu gratuit embarqué) et l'ADR-011 (contenu en base).

## Contexte

Les 20 mots gratuits étaient figés dans l'application : en changer demandait une nouvelle version sur les boutiques (#41, recette du 24/10/2026). Le nombre de paliers payants (#18) n'est pas encore décidé avec le client.

## Décision

- Chaque pictogramme du catalogue porte un palier (`tier`) : `free` ou `premium`. C'est une valeur et non un booléen, pour accueillir d'autres paliers sans changer le format du paquet.
- Les 20 mots gratuits rejoignent le catalogue du serveur avec leurs codes d'origine : favoris, tableaux et routines des familles restent valides.
- Une publication contient tous les mots avec leur palier. Elle est refusée s'il ne reste aucun mot gratuit.
- La fonction `free-pack` est ouverte sans compte. Elle sert la dernière publication réduite aux mots gratuits et à leurs catégories, ainsi que les images de ces seuls mots. Elle répond 404 tant que la dernière publication ne contient aucun mot gratuit : l'application garde alors ce qu'elle a.
- L'application garde son paquet gratuit embarqué pour le premier lancement hors ligne. Elle met à jour le gratuit au démarrage et à chaque synchronisation du compte. Le paquet gratuit téléchargé fait foi : un mot qui en sort redevient réservé aux abonnés sur l'appareil.

## Conséquences

- Changer l'offre gratuite ne demande plus de nouvelle version de l'application.
- Le contenu gratuit et ses images sont publics, comme le paquet embarqué l'était déjà : rien de payant ne sort par `free-pack`.
- Le paquet embarqué de chaque nouvelle version de l'application doit être régénéré depuis une publication, pour qu'un premier lancement hors ligne propose l'offre gratuite en vigueur.

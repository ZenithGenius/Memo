# Revue de la maquette Claude Design (version 2)

Source : projet « Memo AAC app design », fichier `Memo.dc.html`, lu le 2026-09-21. Les images de comparaison sont dans `design/reviews/`.

La maquette complète les écrans déjà conçus. Elle ne remplace rien : ce document relève ce qui est déjà en place, les écarts, et propose un ordre pour les combler.

## Ce que la maquette confirme

- palette Sahel Warmth et police Manrope, identiques à l'application
- trois niveaux qui règlent la taille des tuiles : 2 colonnes pour les plus jeunes, 3, puis 4 (déjà implémenté, 2, 3 et 4 colonnes)
- étiquettes plus grandes pour le niveau le plus simple (16 points, désormais appliqué)
- écrans pensés pour un téléphone Android d'entrée de gamme (360 sur 760), sans défilement horizontal
- aucun appel réseau dans les parcours de communication
- chaque mot porte un libellé par langue : notre base stocke déjà les libellés par langue
- un noyau de mots très fréquents mis en avant : équivalent de notre catégorie « Mes besoins » (20 concepts)

## Écarts

| Sujet | Maquette | Application aujourd'hui | Proposition |
|---|---|---|---|
| Navigation | quatre onglets : Parler, Phrases, Mots, Réglages | accueil en grille avec raccourcis Favoris et Tableau, engrenage | adopter les onglets |
| Retour audio par mot | chaque touche prononce le mot (2b) | le mot n'est lu qu'avec la phrase | ajouter, réglable |
| Mode de lecture | « mot par mot » ou « phrase » | phrase seulement | ajouter avec le point précédent |
| Phrases toutes faites | onglet dédié avec thèmes | absent (EF-05 reporté) | ajouter comme onglet |
| Statistiques | onglet Mots : phrases de la semaine, mots les plus utilisés | absent | version locale simple, détail au back office (M4) |
| Prédiction | la suite la plus probable après le dernier mot (2c) | absent | nécessite un historique local d'usage |
| Profils | sélecteur « Qui parle ? » et profil en en-tête | un seul profil créé à l'installation | gérer plusieurs profils par appareil |
| Mode accompagnant | code à 4 chiffres, verrou visible dans l'en-tête | absent | ajouter, code conservé haché dans le stockage sécurisé |
| Langue | pastille FR/EN qui change tout, voix comprise | français seulement | ajouter les libellés anglais et le sélecteur |
| Réglages | niveau en contrôle segmenté, type d'image, voix et langue, économie d'énergie, prédiction | niveau seul, en boutons radio | enrichir |
| Économie d'énergie | écran atténué, sans vibration | vibration toujours active | option dans les réglages |
| Ajout d'un mot avec photo | réservé à l'accompagnant | absent (EF-13 reporté) | inchangé |
| Niveau | lié à l'âge : Enfant, Ado, Adulte | niveau de compétence séparé du type de profil | conserver la séparation |
| Cartes de situation | « Où es-tu maintenant ? » : maison, école, amis, émotions | catégories par thème | à envisager comme vue alternative |
| Barre de phrase | en haut (2a), au pouce en bas à droite (2b) | en bas, bouton large | garder en bas |

## Ce que l'application fait déjà en plus

- une couleur par catégorie, pour regrouper visuellement les symboles
- séparation du contenu gratuit et payant, préparée pour l'abonnement
- grille qui s'adapte aussi aux tablettes
- retour tactile et annonce pour les lecteurs d'écran à chaque ajout
- tests d'accessibilité (cibles tactiles, contraste, texte agrandi) et captures de référence des écrans

## État d'avancement

Fait :

- quatre onglets : Parler, Phrases, Mots, Réglages, chacun avec son historique
- retour audio par mot, réglable
- phrases toutes faites, prononcées d'un toucher
- statistiques de la semaine : phrases dites, nouveaux mots, classement
- réglages : niveau en contrôle segmenté, lecture de chaque mot, vibrations, langue
- étiquettes agrandies pour le niveau le plus simple
- anglais complet : interface, libellés, phrases, voix britannique, pastille FR/EN dans l'en-tête
- plusieurs profils par appareil, avec le profil actif dans l'en-tête et « Qui parle ? »
- mode accompagnant à code à 4 chiffres : niveau, tableau, phrases personnelles, changement et création de profil
- phrases personnelles : ajout et suppression par l'accompagnant
- code accompagnant oublié : contrôle adulte (addition écrite en lettres), nouveau code sans perte de données
- suppression d'un profil (hors profil actif), avec confirmation
- prédiction du mot suivant, apprise des phrases déjà dites par le profil, hors ligne

Reste à faire :

- choix du type d'image (photo, symbole, les deux), dès que les pictogrammes définitifs existent

## Priorités proposées

Tout ce que la maquette prévoit est fait, sauf le choix du type d'image, qui dépend des pictogrammes définitifs.

## Points à trancher

- le niveau reste-t-il une compétence (débutant, intermédiaire, avancé) ou devient-il un âge (enfant, ado, adulte) ? Un adulte après un AVC peut avoir besoin de grandes tuiles : la séparation actuelle le permet.
- la barre de phrase reste-t-elle en bas, plus proche du pouce ?
- les catégories thématiques ou les situations sont-elles l'entrée principale ?

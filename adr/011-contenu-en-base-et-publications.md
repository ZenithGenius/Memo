# ADR-011 : Contenu téléchargeable en base, publié par versions

Statut : accepté (2026-10-11). Précise l'ADR-008 (couche 1).

## Contexte

Le contenu payant était un fichier JSON du dépôt (`premium-pack/pack.json`),
embarqué dans la fonction `premium-pack`. Ajouter les pictogrammes livrés par
le client demandait un développeur et un déploiement (issue #28). Le dépôt est
public : un contenu payant réel n'y a pas sa place.

## Décision

- Le catalogue téléchargeable vit en base : catégories, pictogrammes (libellés
  FR/EN séparés de l'image, niveau, public, ordre), images.
- Les images sont des octets en base (PNG ou WebP, 512 Kio au plus), vérifiés
  par leur signature et identifiés par leur empreinte SHA-256. Pas de stockage
  de fichiers à part : une seule sauvegarde, la même sécurité par ligne, des
  tests sur un PostgreSQL nu.
- Publier construit le paquet depuis la base, au format du paquet embarqué, et
  l'enregistre comme une version immuable (`content_releases`). `premium-pack`
  sert la dernière ; `premium-image` sert une image seulement si cette
  publication la référence, aux mêmes conditions que le paquet.
- La publication refuse ce que l'application ne sait pas afficher : valeurs
  inconnues, libellés manquants, mot placé devant un mot de niveau inférieur
  (position stable), couleur de catégorie sous 3:1 sur fond blanc.
- Un pictogramme publié n'est jamais supprimé, seulement retiré : favoris et
  tableaux des familles le désignent par son code.
- L'import initial reprend `pack.json` comme publication 5 : les appareils qui
  l'ont déjà ne retéléchargent rien. Le fichier reste comme contenu de
  démonstration pour les tests et la variante dev.

## Conséquences

- Un pictogramme ajouté et publié depuis le back-office arrive chez les
  abonnés à la synchronisation suivante, sans déploiement.
- Deux évolutions de l'application, à part : télécharger les images envoyées
  (champ `imageObject` du paquet ; l'actuelle les ignore et affiche l'icône
  provisoire) et masquer un pictogramme payant absent de la dernière
  publication (l'import actuel ajoute et met à jour, sans rien retirer).
- Le contenu gratuit reste embarqué dans l'application (ADR-008).
- Le paquet et les images sont servis en clair aux abonnés authentifiés ; leur
  chiffrement reste l'issue #10.

## Alternatives écartées

- Supabase Storage pour les images : un service de plus, non démarré en local,
  des règles d'accès à maintenir à part, et des URL signées à faire expirer.
- Garder le fichier JSON et le régénérer : un déploiement par ajout, et le
  contenu payant dans un dépôt public.

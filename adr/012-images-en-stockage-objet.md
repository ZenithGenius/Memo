# ADR-012 : Images du contenu en stockage objet

Statut : accepté (2026-11-06). Remplace la partie « images » de l'ADR-011.

## Contexte

L'ADR-011 gardait les images des pictogrammes en octets dans PostgreSQL : une
seule sauvegarde et des tests sur un PostgreSQL nu. Avec l'écran de gestion du
contenu, CREYATIV va envoyer des centaines d'images, avec des variantes (fille
ou garçon, #19). Garder ces octets en base alourdit les sauvegardes, la
réplication et chaque lecture, et mélange deux natures de données.

## Décision

- Les images vivent dans Supabase Storage, compartiment privé
  `content-images` : 512 Kio au plus, PNG ou WebP seulement (pas de SVG, qui
  peut porter du script). Un objet porte le nom de son empreinte SHA-256 : une
  même image n'est stockée qu'une fois et un nom désigne toujours le même
  contenu.
- Le reste du système ne parle qu'à Storage, jamais au stockage objet
  lui-même. En production, Storage s'appuie sur un stockage compatible S3 :
  SeaweedFS (licence Apache 2.0, image épinglée par empreinte, aucun port
  publié, configuration dans `backend/storage/`). Le moteur S3 reste
  remplaçable sans toucher au code.
- La base ne garde que les métadonnées (`content_images` : empreinte, type,
  taille). Le back-office envoie l'image dans Storage, puis
  `admin_register_image` vérifie que l'objet existe, avec le type et la taille
  relevés par Storage, avant de l'ajouter au catalogue.
- Droits : seul un super-administrateur (double authentification) envoie une
  image ; les administrateurs la voient en aperçu par un lien signé de cinq
  minutes ; aucune règle ne permet de modifier ou de supprimer un objet. Les
  abonnés n'accèdent jamais à Storage directement.
- `premium-image` sert une image seulement si la dernière publication la
  référence, aux mêmes conditions que le paquet. Elle lit les octets dans
  Storage et vérifie leur empreinte et leur signature PNG ou WebP avant de les
  servir : un objet altéré dans le stockage ne part jamais.

## Conséquences

- La sauvegarde du serveur couvre deux éléments : la base et le volume du
  stockage objet.
- Le contrat de `premium-image` ne change pas pour l'application.
- Une image envoyée mais jamais enregistrée reste dans le stockage sans être
  servie ; un nettoyage périodique pourra la retirer.
- Les tests SQL sur PostgreSQL nu simulent les tables de Storage
  (`backend/tests/support/supabase_stub.sql`).

## Alternatives écartées

- Octets en base (ADR-011) : sauvegardes et lectures alourdies à mesure que le
  catalogue grandit.
- MinIO comme stockage objet : sa version communautaire n'évolue plus que pour
  la maintenance.
- Un service média dédié devant le stockage objet : plus de code et
  d'exploitation pour ce que Storage fait déjà (droits par rôle, liens signés,
  limites de taille et de type).

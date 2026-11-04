# ADR-010 : Double authentification obligatoire pour l'administration

Statut : accepté (2026-10-11)

## Contexte

Le back-office (ADR-009) active des abonnements, enregistre des paiements,
révoque des appareils et lit les e-mails et téléphones des familles. Un mot de
passe d'administrateur volé (hameçonnage, réutilisation) donnait jusqu'ici tous
ces droits. Le dépôt est public : le schéma et les fonctions d'administration
sont connus de tous, la seule barrière est l'authentification.

## Décision

Les droits d'administration ne s'appliquent qu'à une session vérifiée par un
second facteur : code temporaire d'une application d'authentification (TOTP),
fourni par Supabase Auth.

- La base l'impose : `is_admin()` et `is_super_admin()` exigent le claim
  `aal` = `aal2` du jeton d'accès. Toutes les règles de sécurité par ligne et
  fonctions d'administration en dépendent ; l'interface n'est pas une barrière.
- `admin_me()` reste lisible au mot de passe seul : il ne renvoie que le rôle
  de la personne connectée, pour que l'interface sache demander le code.
- Le back-office guide la configuration au premier passage (code QR), puis
  demande le code à chaque connexion.
- Un rôle ne s'attribue qu'à une adresse confirmée, et la confirmation des
  e-mails est activée en production : sans elle, n'importe qui pourrait
  s'inscrire avec l'adresse d'un futur collègue et recevoir son rôle.

## Conséquences

- Chaque administrateur a besoin d'une application d'authentification.
- Perte du téléphone : un administrateur du projet Supabase supprime le
  facteur (procédure dans `apps/admin/README.md`), la personne le reconfigure.
- L'application mobile n'est pas concernée : les familles ne passent jamais
  par ces fonctions.

## Alternatives écartées

- Second facteur par SMS : coût par envoi, interception possible (échange de
  carte SIM), dépendance à un fournisseur.
- Clés matérielles (WebAuthn) seules : plus sûres mais un équipement à acheter
  et à remplacer ; à ajouter plus tard en plus du TOTP.
- Contrôle dans l'interface seulement : contourné par un appel direct à l'API.

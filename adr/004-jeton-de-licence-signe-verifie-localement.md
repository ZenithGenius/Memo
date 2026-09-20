# ADR-004 : Jeton de licence signé vérifié localement

Statut : accepté (2026-09-20)

## Contexte

L'abonnement doit être vérifiable hors ligne sans pouvoir être falsifié en modifiant le stockage local.

## Décision

Le serveur signe {identifiant, expiration} en Ed25519 avec une clé privée qui ne quitte pas le serveur. L'application vérifie avec la clé publique embarquée et stocke le jeton dans Keystore ou Keychain.

## Conséquences

Falsification simple impossible ; exposition bornée à la période de grâce. La modification du binaire par un attaquant déterminé reste possible.

## Alternatives écartées

Indicateur booléen synchronisé : trivial à falsifier. Attestation matérielle à chaque usage : incompatible avec le hors ligne.

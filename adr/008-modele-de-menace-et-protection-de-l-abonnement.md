# ADR-008 : Modèle de menace et protection de l'abonnement hors ligne

Statut : accepté (2026-09-21). Complète et précise l'ADR-004.

## Contexte

L'application doit fonctionner sans connexion, mais l'abonnement est la seule source de revenu. Un contrôle exécuté uniquement sur le téléphone finit toujours par être contourné par un attaquant qui contrôle l'appareil : racine, instrumentation à l'exécution (Frida), binaire modifié. La détection de racine est un contrôle de résilience et non une protection de fond (OWASP MASVS-RESILIENCE).

L'ADR-004 protège contre la falsification du stockage, mais laisse ouvertes plusieurs voies :

- retour en arrière de l'horloge pour prolonger un abonnement expiré
- copie du jeton ou de la base vers un autre téléphone
- modification du binaire pour sauter la vérification et débloquer le contenu livré avec l'application
- partage d'un compte activé entre plusieurs personnes
- fichier d'installation redistribué hors des boutiques (pratique courante, y compris par partage local)

L'objectif réaliste n'est pas l'impossibilité absolue, mais un coût de contournement supérieur au prix de l'abonnement (1 000 FCFA par mois pour l'offre d'entrée), avec une exposition bornée et un contenu payant inaccessible sans serveur.

## Décision

Cinq couches, de la plus solide à la plus faible.

### 1. Le contenu payant n'est pas dans l'application

Seul le contenu gratuit (les 20 concepts prioritaires de l'offre Découverte) est livré dans le binaire. Le contenu payant est un paquet téléchargé après activation, chiffré, dont la clé de déchiffrement est délivrée par le serveur et enveloppée par une clé matérielle du téléphone non exportable (Android Keystore, Keychain). Modifier le binaire ne débloque donc rien : il n'y a rien à débloquer. C'est la seule protection qui ne dépend pas de l'honnêteté du client.

### 2. Jeton de licence lié à l'appareil

Le jeton signé (Ed25519, ADR-004) contient :

- l'identifiant de l'abonné et l'offre
- la fin de période payée (`valid_until`)
- la date d'émission par le serveur (`issued_at`)
- l'empreinte de la clé publique de l'appareil (`device`)
- l'identifiant de la clé de signature (`kid`), avec deux clés publiques embarquées pour permettre la rotation

L'application refuse un jeton dont l'empreinte ne correspond pas à sa propre clé matérielle. Un jeton copié sur un autre téléphone est inutilisable. Le serveur limite le nombre d'appareils par compte (deux par défaut).

### 3. Durée de validité portée par le jeton, pas par une période de grâce

Le jeton porte la fin de la période payée. Aucune reconnexion n'est nécessaire pendant cette période, ce qui répond au besoin hors ligne. Deux bornes limitent l'exposition :

- durée de vie maximale d'un jeton : 45 jours, même pour un abonnement prépayé de 12 mois, renouvelé à la prochaine synchronisation
- tolérance après `valid_until` : 3 jours, pour absorber un retard de renouvellement

Sans connexion pendant plus de 45 jours, l'application retombe sur le contenu gratuit jusqu'à la prochaine synchronisation. Une révocation (fraude, remboursement) prend effet au plus tard à ce terme.

### 4. Horloge non manipulable

Le temps utilisé pour comparer à `valid_until` n'est pas l'horloge murale seule. L'application conserve, dans un stockage protégé par une clé matérielle :

- le dernier instant de confiance (date serveur reçue dans le jeton ou la synchronisation)
- le plus grand instant d'horloge murale jamais observé
- l'horloge monotone (`elapsedRealtime`), qui ne peut pas être réglée par l'utilisateur, et l'identifiant de démarrage

Le temps effectif est le maximum de l'horloge murale, du plus grand instant observé, et de l'ancre de confiance avancée de l'horloge monotone quand le démarrage n'a pas changé. Si l'horloge murale recule de plus de 24 heures sous le plus grand instant observé, le contenu payant est suspendu jusqu'à la prochaine synchronisation.

### 5. Attestation et durcissement, comme signaux et non comme verrous

À l'activation et à chaque renouvellement, le serveur demande :

- un verdict Play Integrity (Android) ou App Attest (iOS), vérifié côté serveur uniquement
- une attestation de clé matérielle du Keystore pour la clé de l'appareil

Ces verdicts servent à moduler la confiance. Un verdict défavorable réduit la durée du jeton et lève une alerte dans le back office, mais ne bloque pas systématiquement : une part importante du parc local est constituée d'appareils bas de gamme, à ROM modifiée ou installés depuis un fichier redistribué, qui échoueraient à un contrôle strict. Le blocage dur est une décision produit à trancher (voir ci-dessous).

Durcissement côté application :

- compilation avec `--obfuscate` et `--split-debug-info`, R8 activé
- aucune clé privée ni secret dans le binaire (uniquement des clés publiques)
- l'état premium n'est jamais un booléen en base : il se déduit du jeton vérifié à chaque usage, par un point d'entrée unique
- vérification de la signature de l'application au démarrage

## Conséquences

Un attaquant qui root son téléphone et patch l'application peut sauter la vérification du jeton, mais n'obtient toujours que le contenu gratuit. Pour obtenir le contenu payant il doit extraire un paquet déjà déchiffré depuis un appareil légitimement activé, ce qui est un problème de copie de contenu, pas de contournement d'abonnement, et se traite par le droit d'auteur et la révocation du compte source.

Le retour en arrière de l'horloge est neutralisé tant que l'appareil n'a pas été racinisé. Le partage de jeton entre téléphones est neutralisé par la liaison à l'appareil. Le partage de compte est borné par la limite d'appareils.

Coûts :

- activation obligatoirement en ligne au moins une fois (déjà le cas : l'administrateur active le compte)
- gestion des clés de signature, de leur rotation, et d'un service d'émission de jetons (fonction serveur)
- livraison chiffrée du contenu payant, donc un format de paquet et une gestion de clés en plus du paquet gratuit
- le contenu payant n'est plus disponible tant que l'utilisateur n'a pas téléchargé son paquet

Ce changement modifie le jalon M1 : le paquet embarqué actuel de 151 pictogrammes devra être réduit aux 20 concepts gratuits avant M3, le reste passant en paquet téléchargeable dès M2.

## Alternatives écartées

- Vérification en ligne à chaque lancement : incompatible avec l'exigence hors ligne.
- Période de grâce longue sans borne de durée de vie du jeton : la révocation ne prendrait jamais effet.
- Blocage dur sur verdict d'intégrité : exclurait une partie du public cible.
- Obfuscation et détection de racine comme protection principale : contournables par instrumentation, donc insuffisantes seules.
- DRM tiers du commerce : coût et dépendance disproportionnés pour la taille du contenu.

## Décisions arrêtées

- installations hors boutique : acceptées, avec un jeton de courte durée et une alerte dans le back office
- durée maximale hors ligne : 45 jours
- appareils par compte : deux

## Références

- OWASP MASVS-RESILIENCE : https://mas.owasp.org/MASVS/11-MASVS-RESILIENCE/
- Play Integrity API, verdicts : https://developer.android.com/google/play/integrity/verdicts
- Android, attestation de clé matérielle : https://developer.android.com/privacy-and-security/security-key-attestation
- Falsification de l'horloge et licences : https://docs.talsec.app/appsec-articles/articles/appicrypt-against-time-spoofing-from-free-trial-abuse-to-license-fraud-and-audit-log-corruption

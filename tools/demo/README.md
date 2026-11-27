# Démonstration de bout en bout

Parcours complet en local : l'application sur un émulateur Android, le
serveur Supabase et le back-office, reliés comme en production.

## Avant la présentation

```bash
bash tools/demo/start.sh    # démarre tout (environ 2 minutes, 6 si l'APK doit être construit)
bash tools/demo/reset.sh    # application comme neuve, compte de démonstration supprimé
```

Avoir sous la main :

- le téléphone avec une application d'authentification (Google Authenticator,
  Microsoft Authenticator, Aegis) : la première connexion au back-office demande
  de scanner un code QR ;
- le mot de passe du compte administrateur.

## Scénario (10 à 15 minutes)

### 1. L'application, sans compte et hors connexion

1. Première installation : « Enfant », « Débutant », prénom (par exemple Amina).
2. Accueil : la catégorie gratuite « Mes besoins ».
3. Toucher « Je veux », puis « Encore » : chaque mot est prononcé, la phrase se
   compose en bas. « Lire le message » la prononce entière.
4. Montrer l'onglet Phrases (phrases toutes faites) et l'onglet Mots
   (statistiques de la semaine).

À dire : tout fonctionne sans réseau ; le contenu gratuit est embarqué.

### 2. Le compte de l'accompagnant

1. Réglages, Compte, « Se connecter ».
2. Code accompagnant : 1234 est refusé (« trop simple »), choisir par exemple 4719.
3. « Pas encore de compte ? » : `parent.demo@memo.test`, mot de passe d'au moins
   10 caractères avec majuscule, minuscule et chiffre (par exemple `DemoMemo2026`).
4. L'application affiche « Connecté, mais aucun abonnement actif ».

### 3. Le back-office : activation après paiement

1. Ouvrir http://127.0.0.1:8787, se connecter.
2. Double authentification : scanner le code QR avec le téléphone, saisir le
   code à six chiffres.
3. Tableau de bord : revenus, abonnés, fidélité, expirations, activité.
4. Comptes : rechercher `parent.demo`, ouvrir la fiche.
5. Activer un abonnement : offre Essentiel, moyen « MTN Mobile Money ».
   Sans référence, le formulaire refuse ; saisir par exemple `MP261015.1000.A001`.
6. Revenir au tableau de bord (Actualiser) : le paiement apparaît dans
   « Encaissé ce mois », l'action dans « Activité récente ».
7. Journal d'activité : l'activation et le paiement, avec leur auteur.

### 4. Retour dans l'application

1. Réglages, Compte, « Synchroniser ».
2. « Abonnement actif jusqu'au … » s'affiche.
3. Onglet Parler : les catégories payantes apparaissent (Actions, Alimentation,
   Mes émotions, Santé, Personnes, Lieux, Hygiène).

### Pour aller plus loin, si le temps le permet

- Back-office, Appareils : l'appareil de la démonstration, sa révocation.
- Back-office, Offres : modifier un prix, retirer une offre de la vente.
- Application : pastille FR/EN en haut à droite (interface et voix en anglais).

## En cas de problème

| Symptôme | Cause probable | Correction |
|---|---|---|
| L'application ne se synchronise pas | fonctions serveur arrêtées | relancer `bash tools/demo/start.sh` |
| Back-office : page blanche ou erreur de chargement | conteneur arrêté | `cd apps/admin && docker compose -p memo-demo up -d` |
| Code à six chiffres refusé | horloge du téléphone décalée | régler l'heure automatique sur le téléphone |
| Compte de démonstration déjà existant | démonstration déjà jouée | `bash tools/demo/reset.sh` |

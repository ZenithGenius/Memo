# Panneau d'administration (M4, issue #8)

Page statique (HTML + JS, aucun outil de compilation) qui parle directement à
Supabase. Tout le contrôle d'accès est fait par la sécurité par ligne
(`is_admin()`, migration `licence_schema.sql`) : la clé anon et ce code ne
sont pas des secrets, ils ne donnent aucun accès par eux-mêmes.

## Démarrage

```bash
cp backend/admin/config.example.js backend/admin/config.js   # puis renseigner
cd backend/admin && python3 -m http.server 8787
```

Ouvrir `http://localhost:8787`. En local, `SUPABASE_URL` et
`SUPABASE_ANON_KEY` viennent de `supabase status` (voir `backend/README.md`).

## Devenir administrateur

Aucune inscription ne donne ce rôle. Après s'être inscrit normalement dans
l'application ou via Supabase Studio :

```sql
insert into admins (user_id) select id from auth.users where email = '<compte>';
```

## Couvre (issue #8)

- connexion administrateur (Supabase Auth, vérifié contre `admins`)
- recherche de compte par e-mail, téléphone ou nom (`admin_search_account`,
  migration `20261007000001_admin_search_account.sql`)
- activer ou prolonger un abonnement, le résilier
- révoquer ou rétablir un appareil
- historique des jetons émis, alerte sur intégrité `basic`/`failed`
- tableau de bord : abonnés actifs, nouveaux abonnés du mois, résiliations,
  revenu mensuel estimé

## Indicateurs non couverts

Téléchargements, essais et taux de conversion demandent une analytique
d'installation et un état « essai », absents du schéma : voir issue #8 et
les tableaux de bord des boutiques en attendant.

## Limite connue

Le calcul du tableau de bord récupère tous les abonnements côté client. Correct
tant que la base d'abonnés reste modeste ; à déplacer vers une vue SQL
agrégée si ça devient lent.

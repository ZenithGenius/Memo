# Panneau d'administration (M4, issue #8)

Page statique (HTML + JS, aucun outil de compilation) qui parle directement à
Supabase. Tout le contrôle d'accès est fait par la sécurité par ligne
(`is_admin()`, migration `licence_schema.sql`) : la clé anon et ce code ne
sont pas des secrets, ils ne donnent aucun accès par eux-mêmes.

## Démarrage

```bash
cd backend/admin
cp .env.example .env   # puis renseigner
docker compose up --build
```

Ouvrir `http://localhost:8787`. En local, `SUPABASE_ANON_KEY` vient de
`supabase status` (voir `backend/README.md`) ; `SUPABASE_URL` reste
`http://host.docker.internal:54321` (le conteneur ne voit pas l'hôte sous
`127.0.0.1`). `config.js` est généré au démarrage du conteneur depuis ces
deux variables, jamais écrit dans l'image.

Sans Docker :

```bash
cp config.example.js config.js   # puis renseigner
python3 -m http.server 8787
```

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

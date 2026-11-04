# Back-office Memo

Application d'administration (ADR-009) : tableau de bord, comptes,
abonnements et paiements, offres, appareils, administrateurs, journal
d'activité. React, TypeScript, Vite ; Supabase comme seul serveur.

## Développement

```bash
nvm use                                   # Node 24 (.nvmrc)
npm ci --ignore-scripts
cp public/config.example.js public/config.js   # puis renseigner
supabase migration up --workdir ../../backend --local
npm run dev                               # http://localhost:5173
```

`public/config.js` est ignoré par Git. `supabaseAnonKey` est l'`ANON_KEY` de
`supabase status`, jamais `SECRET_KEY` ni `SERVICE_ROLE_KEY`.

Vérifications (les mêmes qu'en CI) :

```bash
npx tsc -b --noEmit && npx eslint . --max-warnings 0 && npx vitest run && npx vite build
```

Après une migration : `npm run gen:types`, puis compléter `src/lib/rpc-types.ts`
si une fonction SQL renvoie des colonnes pouvant être nulles (le générateur
les déclare toujours non nulles).

## Conteneur

```bash
cp .env.example .env    # puis renseigner
docker compose up --build
```

Ouvrir `http://localhost:8787`. `config.js` est généré au démarrage depuis
`SUPABASE_URL` et `SUPABASE_ANON_KEY`, jamais écrit dans l'image. Le port est
lié à `127.0.0.1` ; pour un accès distant, passer par un proxy TLS.

## Administrateurs et rôles

| Rôle | Droits |
|---|---|
| `super_admin` | lecture et écriture |
| `support` | lecture seule |

Les droits sont appliqués par la base (sécurité par ligne et fonctions SQL),
l'interface ne fait que masquer les actions impossibles. Premier
super-administrateur, sur un compte déjà inscrit :

```sql
insert into admins (user_id, role) select id, 'super_admin' from auth.users where email = '<compte>';
```

Les suivants s'ajoutent depuis l'écran Administrateurs.

## Organisation

```
src/
  app/          contextes (base, session et rôle, notifications), routes
  components/   ui/ (bibliothèque de composants), layout/ (coquille)
  features/     un dossier par module : api.ts (requêtes) + page
  lib/          types générés, formats, rôles, journal, export CSV
```

## Sécurité

- aucun HTML brut (règle ESLint), erreurs génériques à l'écran, détail en console ;
- CSP stricte servie par nginx, aucune ressource tierce (polices embarquées) ;
- dépendances figées, installées sans scripts, scannées par Trivy en CI ;
- image nginx non-root épinglée par empreinte, capacités retirées.

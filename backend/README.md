# Backend Memo

Supabase auto-hébergé : tous les services tournent dans des conteneurs Docker, aucun n'est installé sur la machine. La CLI `supabase` ne sert qu'à les piloter.

## Démarrage local

```bash
supabase start --workdir backend -x realtime,storage-api,imgproxy,mailpit,postgres-meta,studio,logflare,vector,supavisor
supabase functions serve --workdir backend --env-file backend/supabase/functions/.env
```

Services lancés : base Postgres, authentification, API REST, passerelle, exécution des fonctions.

## Configuration

Toute valeur sensible vient de l'environnement. `backend/supabase/functions/.env.example` liste les variables ; le vrai `.env` est ignoré par Git. Le code refuse de démarrer si une variable obligatoire manque.

## Clé de signature des licences

La clé privée Ed25519 est dans `backend/supabase/functions/.env` (ignoré par Git, jamais commité). Générer une paire :

```bash
openssl genpkey -algorithm ed25519 -out priv.pem
openssl pkcs8 -topk8 -nocrypt -in priv.pem -outform DER | base64 -w0        # LICENSE_PRIVATE_KEY_PKCS8
openssl pkey -in priv.pem -pubout -outform DER | tail -c 32 | base64 -w0    # clé publique à embarquer dans l'application
```

En production, la clé privée est un secret du serveur. Deux clés publiques sont embarquées dans l'application pour permettre la rotation (identifiant `kid`).

## Production : réglages à vérifier

Sur le projet hébergé (Authentication), indispensables à la sécurité :

- confirmation des e-mails activée : un rôle d'administration ne s'attribue
  qu'à une adresse confirmée, et sans confirmation Supabase confirme toute
  adresse dès l'inscription ;
- MFA TOTP activé (Multi-Factor) : les administrateurs ne peuvent rien faire
  sans second facteur (ADR-010).

La configuration locale (`supabase/config.toml`) garde la confirmation
désactivée pour les tests de bout en bout.

## Tests

```bash
bash backend/tests/run_sql.sh    # migrations + tests SQL sur un PostgreSQL nu (variables PGHOST, PGPORT, PGUSER, PGPASSWORD)
docker exec -i supabase_db_memo psql -U postgres -v ON_ERROR_STOP=1 < backend/tests/licence_rls.sql   # conteneur : supabase_db_<project_id>
docker run --rm -v "$PWD/backend/supabase/functions:/app:ro" -w /app denoland/deno:alpine-2.1.4 deno test --no-lock
bash backend/tests/e2e_issue_license.sh
```

`run_sql.sh` applique chaque migration sur une base neuve avec une doublure
minimale de Supabase (`tests/support/supabase_stub.sql`) puis exécute tous les
tests SQL ; c'est ce que fait la CI (`database.yml`). Ce n'est pas Supabase :
la confirmation d'e-mail et le second facteur se testent sur `supabase start`.

Pour le reste, le premier vérifie le schéma et la sécurité par ligne, le deuxième la logique de la fonction (dans un conteneur Deno, sans base), le troisième le parcours complet d'émission de jeton.

Vérifier un jeton avec le vérificateur de l'application :

```bash
cd apps/memo_app && dart run tool/verify_token.dart <jeton> <clé publique base64> <empreinte appareil>
```

## Contenu

- `supabase/migrations` : schéma versionné
- `supabase/functions/issue-license` : enregistrement de l'appareil et signature du jeton
- `tests` : tests SQL et bout en bout

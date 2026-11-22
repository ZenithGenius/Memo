# Serveur Memo : installation, déploiement, maintenance

`<serveur>` désigne l'adresse du serveur et `<domaine>` son domaine.

Ce dossier contient tout ce qui tourne sur le serveur de production. Aucun secret n'y figure : les secrets sont créés sur le serveur et y restent.

## Vue d'ensemble

| Élément | Valeur |
| --- | --- |
| Serveur | VPS Ubuntu 26.04 LTS, 4 cœurs, 8 Go de mémoire |
| Adresse | <serveur> |
| Utilisateurs | `ubuntu` (administration, sudo), `deploy` (déploiements GitHub Actions, groupe docker) |
| Pare-feu | ports 22, 80 et 443 seulement, chaque règle commentée (`service:projet:rôle`) |

| Environnement | API Supabase | Back-office | Dossier | Ports locaux (passerelle, back-office, Studio) |
| --- | --- | --- | --- | --- |
| Production | https://api.<domaine> | https://admin.<domaine> | /srv/memo/production | 8100, 8180, 3100 |
| Staging | https://staging-api.<domaine> | https://staging-admin.<domaine> | /srv/memo/staging | 8200, 8280, 3200 |

Les adresses réelles (serveur, domaine) ne figurent pas dans ce dépôt public : elles sont dans la documentation interne de l'équipe. Changer de domaine est décrit plus bas.

Chemin d'une requête : Internet, nginx du serveur (TLS), passerelle Envoy de l'environnement (127.0.0.1), services Supabase dans Docker. Aucun conteneur n'est joignable depuis Internet.

## Contenu du dossier

| Chemin | Rôle |
| --- | --- |
| `server/provision.sh` | Préparation et durcissement du serveur (relançable) |
| `server/sshd-hardening.conf` | Réglages SSH |
| `server/sysctl-hardening.conf` | Réglages du noyau |
| `server/docker-daemon.json` | Réglages de Docker |
| `server/zshrc`, `starship.toml`, `genius-banner`, `fastfetch.jsonc`, `bat-config` | Terminal de l'administrateur |
| `nginx/sites-available/` | Un fichier par site |
| `nginx/snippets/` | Parties communes (TLS, mandataire) |
| `nginx/install.sh` | Installation des sites et du certificat |
| `supabase/docker-compose.yml` | Pile d'un environnement |
| `supabase/init-env.sh` | Création des secrets d'un environnement (une seule fois) |
| `supabase/deploy.sh` | Déploiement d'un environnement |
| `supabase/migrate.sh` | Migrations de la base |
| `supabase/bundle.sh` | Paquet de déploiement (fichiers versionnés seulement) |
| `kiwi/` | Kiwi TCMS, gestion des tests (compose, réglages, secrets) |
| `supabase/envoy/`, `supabase/db/`, `supabase/functions-main/` | Fichiers repris de Supabase auto-hébergé |

## Accès

```bash
ssh ubuntu@<serveur>
```

Connexion par clé seulement. La clé de `deploy` est réservée à GitHub Actions.

Studio Supabase n'est pas exposé. Pour l'ouvrir sur la production :

```bash
ssh ubuntu@<serveur>
sudo -iu deploy sh -c 'cd /srv/memo/production && docker compose --profile studio up -d meta studio'
exit
ssh -L 3000:127.0.0.1:3100 ubuntu@<serveur>
```

Puis ouvrir http://localhost:3000 sur votre poste. Le refermer après usage :

```bash
sudo -iu deploy sh -c 'cd /srv/memo/production && docker compose --profile studio stop meta studio'
```

Pour le staging, remplacer `production` par `staging` et 3100 par 3200.

## Préparation du serveur

À faire une fois sur un serveur neuf, puis à relancer après toute modification d'un fichier de `server/` :

```bash
scp -r deploy/server ubuntu@<serveur>:/tmp/memo-provision
ssh ubuntu@<serveur>
sudo DEPLOY_PUBKEY='ssh-ed25519 AAAA… github-actions-memo-deploy' bash /tmp/memo-provision/provision.sh
```

Le script fait, dans l'ordre :

1. Mise à jour complète et installation des paquets (ufw, nginx, certbot, zsh, outils du terminal).
2. Mises à jour de sécurité automatiques (`unattended-upgrades`).
3. Mémoire d'échange de 4 Go (`/swapfile`).
4. Réglages du noyau (`/etc/sysctl.d/99-memo-hardening.conf`).
5. Utilisateur `deploy`, sans mot de passe, avec la clé de GitHub Actions ; dossiers `/srv/memo/production` et `/srv/memo/staging`.
6. SSH durci (`/etc/ssh/sshd_config.d/00-memo-hardening.conf`).
7. Pare-feu ufw : SSH, HTTP, HTTPS.
8. Docker depuis le dépôt officiel, avec rotation des journaux (`/etc/docker/daemon.json`).
9. CrowdSec et son pare-feu dynamique (nftables).
10. nginx : page par défaut retirée, version masquée.
11. Terminal de `ubuntu` : zsh, Oh My Zsh, Starship, bannière.

Après une mise à jour du noyau, la bannière l'indique : redémarrer avec `sudo reboot` (les conteneurs repartent seuls).

## SSH

Fichier `/etc/ssh/sshd_config.d/00-memo-hardening.conf` (copie de `server/sshd-hardening.conf`). Il est lu avant `50-cloud-init.conf` : sshd garde la première valeur lue.

- Connexion par clé seulement, mot de passe refusé.
- Connexion root interdite.
- Utilisateurs autorisés : `ubuntu` et `deploy`.
- Trois essais au plus par connexion.
- Pas de redirection X11 ni d'agent ; tunnel local permis (Studio).

Vérifier la configuration effective et l'appliquer :

```bash
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|allowusers'
sudo sshd -t && sudo systemctl reload ssh
```

Ajouter la clé d'un nouvel administrateur : une ligne de plus dans `/home/ubuntu/.ssh/authorized_keys`. Toujours garder une session ouverte pendant un changement de SSH et tester une nouvelle connexion avant de la fermer.

## Pare-feu et CrowdSec

```bash
sudo ufw status verbose
sudo ufw allow 2222/tcp comment 'service:projet:rôle'   # exemple : ouvrir un port, toujours avec un commentaire
sudo ufw delete allow 2222/tcp
```

Règles en place : `22/tcp` (ssh:serveur:administration et déploiement), `80/tcp` (nginx:memo:http), `443/tcp` (nginx:memo:https).

Docker publie ses ports en contournant ufw : c'est pourquoi chaque port de la pile n'écoute que sur 127.0.0.1. Ne jamais publier un port sans `127.0.0.1:` devant.

CrowdSec lit les journaux de SSH et de nginx et bloque les adresses qui attaquent. Collections installées : `crowdsecurity/linux`, `sshd`, `nginx`, `base-http-scenarios`, `http-cve`.

```bash
sudo cscli metrics                       # ce que CrowdSec lit et détecte
sudo cscli alerts list                   # attaques détectées
sudo cscli decisions list                # adresses bloquées
sudo cscli decisions delete --ip 1.2.3.4 # débloquer une adresse
sudo cscli decisions add --ip 1.2.3.4 --duration 24h   # bloquer à la main
sudo cscli hub update && sudo cscli hub upgrade        # mettre à jour les règles
sudo cscli bouncers list                 # le pare-feu dynamique doit y figurer
```

Pour éviter de bloquer votre propre adresse, l'ajouter à une liste blanche : `/etc/crowdsec/parsers/s02-enrich/mywhitelists.yaml` (voir la documentation de CrowdSec), puis `sudo systemctl reload crowdsec`.

## nginx

Chaque site est un fichier de `/etc/nginx/sites-available/`, activé par un lien dans `/etc/nginx/sites-enabled/` :

| Site | Rôle |
| --- | --- |
| `default-deny` | Ferme toute requête vers un nom inconnu ou l'adresse IP seule |
| `memo-api` | API de production, vers 127.0.0.1:8100 |
| `memo-admin` | Back-office de production, vers 127.0.0.1:8180 |
| `memo-staging-api` | API de staging, vers 127.0.0.1:8200 |
| `memo-staging-admin` | Back-office de staging, vers 127.0.0.1:8280 |

Parties communes dans `/etc/nginx/snippets/` :

- `memo-tls.conf` : certificat, protocoles TLS 1.2 et 1.3, HSTS ;
- `memo-api.conf` : seules les routes `/auth/v1/`, `/rest/v1/`, `/storage/v1/` et `/functions/v1/` sont transmises ; tout le reste répond 404 (Studio et outils internes compris) ;
- `memo-admin.conf` : back-office ; les modèles d'e-mail restent internes.

Les fichiers du dépôt citent `__DOMAIN__` : `install.sh` le remplace par le domaine reçu en paramètre. Installer ou mettre à jour les sites depuis le dépôt :

```bash
scp -r deploy/nginx ubuntu@<serveur>:/tmp/memo-nginx
ssh ubuntu@<serveur> 'sudo DOMAIN=<domaine> bash /tmp/memo-nginx/install.sh'
```

À la main, pour un site :

```bash
sudo nano /etc/nginx/sites-available/memo-api
sudo ln -s /etc/nginx/sites-available/memo-api /etc/nginx/sites-enabled/memo-api   # activer
sudo rm /etc/nginx/sites-enabled/memo-api                                          # désactiver
sudo nginx -t && sudo systemctl reload nginx
```

Journaux : `/var/log/nginx/access.log` et `/var/log/nginx/error.log`.

## Certificats

Un seul certificat Let's Encrypt, nommé `memo`, couvre les quatre noms. Obtenu par `nginx/install.sh` (méthode webroot, dossier `/var/www/certbot`). Renouvellement automatique par le minuteur de certbot ; nginx est rechargé après chaque renouvellement (`/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh`).

```bash
sudo certbot certificates             # date d'expiration
sudo certbot renew --dry-run          # tester le renouvellement
systemctl list-timers | grep certbot  # prochain passage
```

Le compte Let's Encrypt a été créé sans adresse e-mail (pas d'avis d'expiration). Pour en ajouter une : `sudo certbot update_account --email adresse@exemple.com`.

## Changer de domaine

Quand le vrai domaine existe :

1. Créer les enregistrements DNS A vers <serveur> (api, admin, staging-api, staging-admin).
2. Supprimer l'ancien certificat (`sudo certbot delete --cert-name memo`), puis relancer `install.sh` avec `DOMAIN=<nouveau domaine>`.
3. Dans `/srv/memo/<environnement>/.env`, changer `API_EXTERNAL_URL` et `SITE_URL`, puis redéployer.
4. Reconstruire l'application avec la nouvelle adresse de l'API.

## Pile Supabase

Chaque environnement est un projet Docker Compose (`memo-production`, `memo-staging`) avec ses propres conteneurs, volumes et réseau.

| Service | Rôle |
| --- | --- |
| `db` | PostgreSQL de Supabase (volume `db-data`) |
| `auth` | Comptes, connexion, e-mails, double authentification |
| `rest` | API REST (PostgREST) |
| `storage` | Fichiers (images du contenu), stockés dans SeaweedFS |
| `seaweedfs` | Stockage objet compatible S3 (volume `seaweedfs-data`) |
| `functions` | Fonctions serveur de Memo (licences, paquets, images) |
| `api-gw` | Passerelle Envoy, seule exposée (sur 127.0.0.1) |
| `admin` | Back-office (image `ghcr.io/zenithgenius/memo-admin`) |
| `meta`, `studio` | Studio, démarré à la demande seulement |

Services retirés par rapport à Supabase auto-hébergé, inutilisés par Memo : Realtime, analytique, imgproxy, pooler.

Les commandes `docker compose` lisent le `.env`, réservé à `deploy` : les lancer en `deploy`. Depuis `ubuntu` :

```bash
sudo -iu deploy
cd /srv/memo/production
docker compose ps                         # état des services
docker compose logs -f --tail 100 auth    # journaux d'un service
docker compose restart functions          # redémarrer un service
docker compose up -d                      # relancer ce qui est arrêté
docker compose exec db psql -U postgres   # console SQL
docker stats --no-stream                  # mémoire et processeur
```

Alias du terminal de `ubuntu`, sans passer par `deploy` : `dps` (conteneurs), `dlogs <conteneur>`, `decisions`, `alerts`.

## Secrets

Chaque environnement a son `/srv/memo/<environnement>/.env` (lecture réservée à `deploy`) et son `s3.json`, créés par `init-env.sh` à la première installation :

```bash
cd /srv/memo/production
bash init-env.sh production api.<domaine> admin.<domaine> 8100 8180 3100
```

Le script refuse d'écraser un `.env` existant. Il génère : mot de passe de la base, secret JWT, clés anon et service, clés S3, clé Ed25519 de signature des licences, identifiants de Studio. Il affiche seulement les valeurs publiques nécessaires à la construction de l'application (adresse, clé anon, clé publique de licence).

Ne jamais copier un `.env` hors du serveur ni le commiter. Sauvegarder les deux `.env` dans un coffre (gestionnaire de mots de passe) : sans eux, les données chiffrées et les licences émises ne sont plus vérifiables.

E-mails (Brevo) : renseigner `SMTP_ADMIN_EMAIL`, `SMTP_HOST` (`smtp-relay.brevo.com`), `SMTP_PORT` (587), `SMTP_USER` et `SMTP_PASS` dans le `.env`, puis :

```bash
docker compose up -d auth
```

## Déploiement

Automatique par GitHub Actions (`.github/workflows/deploy.yml`) :

1. `scan` : Trivy sur le dépôt (dépendances, secrets, configurations), construction de l'image du back-office, Trivy sur l'image. Toute faille bloque, quelle que soit sa gravité.
2. `publish` : publication de l'image scannée sur GHCR (`ghcr.io/zenithgenius/memo-admin:<commit>`).
3. `deploy` : paquet des fichiers versionnés envoyé en SSH (clé `deploy`, empreinte du serveur vérifiée), puis `deploy.sh` sur le serveur.

Un push sur `main` qui touche le back-office, Supabase ou ce dossier déploie le staging. La production se déploie à la main :

```bash
gh workflow run deploy.yml --ref main -f deploy_prod=true
gh run watch
```

`deploy.sh` démarre la base et le stockage, crée le compartiment des images, démarre l'authentification et le stockage, applique les migrations, démarre le reste, puis vérifie la passerelle et le back-office.

Configuration GitHub requise (Settings, Environments, `staging` et `production`) :

- secret `DEPLOY_SSH_KEY` : clé privée de `deploy` ;
- variable `DEPLOY_HOST` : <serveur> ;
- variable `DEPLOY_KNOWN_HOSTS` : sortie de `ssh-keyscan -t ed25519 <serveur>`, empreinte vérifiée sur le serveur (`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`).

Déploiement à la main, depuis le dépôt :

```bash
bash deploy/supabase/bundle.sh /tmp/memo.tar.gz
scp /tmp/memo.tar.gz deploy@<serveur>:/tmp/
ssh deploy@<serveur> 'cd /srv/memo/staging && tar -xzf /tmp/memo.tar.gz && ADMIN_TAG=staging bash deploy.sh'
```

Revenir à une version précédente du back-office : relancer `deploy.sh` avec `ADMIN_TAG=<commit précédent>`.

## Migrations

`migrate.sh` applique, une par transaction, les fichiers de `backend/supabase/migrations` pas encore appliqués, et les note dans `supabase_migrations.schema_migrations`. Une migration en échec arrête le déploiement sans rien laisser à moitié.

```bash
docker compose exec db psql -U postgres -c 'select version, name from supabase_migrations.schema_migrations order by version'
```

Une migration ne se modifie jamais après son application : on en ajoute une nouvelle.

## Gestion des tests (Kiwi TCMS)

Kiwi TCMS (édition communautaire) tient le cahier de recette : plans par parcours puis par scénario, un cas par point à valider, campagnes (Test Runs) avec verdict, commentaire et captures annotées.

| Élément | Valeur |
| --- | --- |
| Adresse | https://tests.<domaine> |
| Dossier | /srv/kiwi (`docker-compose.yml`, `memo_settings.py`, `.env` des secrets) |
| Port local | 8443 (HTTPS auto-signé de Kiwi, derrière nginx, site `memo-tests`) |
| Comptes | créés par l'administrateur ; inscription libre désactivée ; aucune page sans connexion |
| E-mails | Brevo, mêmes accès que Memo (`KIWI_SMTP_*` dans `.env`) |
| Compte administrateur | super-utilisateur Kiwi |

Installation (une fois) :

```bash
sudo install -d -m 750 -o deploy -g deploy /srv/kiwi
# copier deploy/kiwi/* dans /srv/kiwi, puis, en deploy :
cd /srv/kiwi && bash init-env.sh tests.<domaine>
docker compose up -d
docker compose exec web /Kiwi/manage.py migrate
docker compose exec web /Kiwi/manage.py set_domain tests.<domaine>
docker compose exec web /Kiwi/manage.py refresh_permissions
docker compose exec web /Kiwi/manage.py createsuperuser
```

Mise à jour : changer les empreintes des images dans `docker-compose.yml`, puis `docker compose up -d` et `docker compose exec web /Kiwi/manage.py upgrade`. Sauvegarde : volumes `kiwi_db_data` (MariaDB) et `kiwi_uploads` (pièces jointes).

Vérifications : `docker compose ps`, `docker compose exec web /Kiwi/manage.py sendtestemail <adresse>`, `curl -sI https://tests.<domaine>/` (302 vers la connexion).

Accès des agents : serveur MCP communautaire `kiwi-tcms-mcp-server` (danish54), relu et épinglé au commit 11620af ; deux modifications locales (vérification TLS réactivée, dotenv retiré). L'outil `tools/recette/capture.py` produit les captures annotées (cadres et pastilles rouges numérotées) depuis l'émulateur et peut les joindre à une exécution.

## Sauvegardes

À mettre en place : seule la sauvegarde quotidienne de l'hébergeur existe aujourd'hui. À sauvegarder ensemble, hors du serveur :

- la base de chaque environnement (`docker compose exec db pg_dump -U postgres -Fc postgres > memo.dump`) ;
- le volume `seaweedfs-data` (images) ;
- les fichiers `.env` et `s3.json`.

## Vérifications rapides

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://api.<domaine>/auth/v1/health   # 401 sans clé : passerelle active
curl -s https://admin.<domaine>/config.js                                        # adresse de l'API du back-office
sudo cscli decisions list
docker ps --format '{{.Names}} {{.Status}}'
```

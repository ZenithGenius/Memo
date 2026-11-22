#!/usr/bin/env bash
# Préparation et durcissement du serveur Memo (Ubuntu 26.04).
# Idempotent : se relance sans risque. À lancer en root depuis ce dossier :
#   sudo bash provision.sh
# Variables : DEPLOY_PUBKEY = clé publique SSH du déploiement GitHub Actions.
set -euo pipefail
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive

[ "$(id -u)" = 0 ] || { echo "À lancer avec sudo." >&2; exit 1; }
: "${DEPLOY_PUBKEY:?DEPLOY_PUBKEY manquante (clé publique du déploiement)}"

step() { printf '\n=== %s\n' "$*"; }

step "Mises à jour et paquets de base"
apt-get update -q
apt-get -y -q -o Dpkg::Options::=--force-confold full-upgrade
apt-get -y -q install ca-certificates curl gnupg git jq ufw nginx certbot \
  python3-certbot-nginx unattended-upgrades zsh starship eza fzf bat zoxide \
  figlet fastfetch

step "Mises à jour de sécurité automatiques"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades

step "Mémoire d'échange (4 Go)"
if ! swapon --show | grep -q /swapfile; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
echo 'vm.swappiness=10' > /etc/sysctl.d/90-memo-swap.conf

step "Noyau : réglages réseau et protections"
install -m 644 sysctl-hardening.conf /etc/sysctl.d/99-memo-hardening.conf
sysctl --system -q

step "Utilisateur de déploiement"
if ! id deploy >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash deploy
fi
passwd -l deploy >/dev/null
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
printf '%s\n' "$DEPLOY_PUBKEY" > /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
install -d -m 750 -o deploy -g deploy /srv/memo /srv/memo/production /srv/memo/staging

step "SSH : clés seules, pas de root"
install -m 644 sshd-hardening.conf /etc/ssh/sshd_config.d/00-memo-hardening.conf
sshd -t
systemctl reload ssh

step "Pare-feu (SSH, HTTP, HTTPS)"
ufw default deny incoming
ufw default allow outgoing
# Commentaires « service:projet:rôle » : chaque ouverture dit ce qu'elle sert.
# Les ports des conteneurs n'écoutent que sur 127.0.0.1 : aucune règle ici.
ufw allow 22/tcp comment 'ssh:serveur:administration (ubuntu) et deploiement (deploy)'
ufw allow 80/tcp comment 'nginx:memo:http (defis Lets Encrypt, redirection https)'
ufw allow 443/tcp comment 'nginx:memo:https (api et back-office, production et staging)'
ufw delete allow OpenSSH >/dev/null 2>&1 || true
ufw delete allow 'Nginx Full' >/dev/null 2>&1 || true
ufw --force enable

step "Docker (dépôt officiel)"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -q
apt-get -y -q install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
install -m 644 docker-daemon.json /etc/docker/daemon.json
systemctl enable docker
systemctl restart docker
usermod -aG docker deploy
usermod -aG docker ubuntu

step "CrowdSec et pare-feu dynamique"
curl -fsSL https://packagecloud.io/crowdsec/crowdsec/gpgkey | gpg --dearmor --yes -o /etc/apt/keyrings/crowdsec.gpg
# ponytail: dépôt « any » (CrowdSec ne publie pas encore de dépôt pour 26.04) ; binaires Go statiques
echo "deb [signed-by=/etc/apt/keyrings/crowdsec.gpg] https://packagecloud.io/crowdsec/crowdsec/any/ any main" \
  > /etc/apt/sources.list.d/crowdsec.list
apt-get update -q
apt-get -y -q install crowdsec
systemctl enable --now crowdsec
# Le bouncer enregistre sa clé auprès de l'API locale à l'installation : elle doit répondre.
timeout 60 bash -c 'until cscli lapi status >/dev/null 2>&1; do sleep 2; done'
apt-get -y -q install crowdsec-firewall-bouncer-nftables
cscli hub update
cscli collections install crowdsecurity/linux crowdsecurity/sshd crowdsecurity/nginx \
  crowdsecurity/base-http-scenarios crowdsecurity/http-cve
systemctl enable --now crowdsec crowdsec-firewall-bouncer
systemctl reload crowdsec

step "nginx : page par défaut retirée, version masquée"
rm -f /etc/nginx/sites-enabled/default
sed -i -E 's/^(\s*)#?\s*server_tokens\s+\S+;/\1server_tokens off;/' /etc/nginx/nginx.conf
nginx -t
systemctl reload nginx
# Les sites Memo et leur certificat : deploy/nginx/install.sh.

step "Terminal de l'administrateur : zsh, Oh My Zsh, Starship"
U=ubuntu
H=/home/$U
if [ ! -d "$H/.oh-my-zsh" ]; then
  sudo -u $U git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$H/.oh-my-zsh"
fi
for p in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  d="$H/.oh-my-zsh/custom/plugins/${p#*/}"
  [ -d "$d" ] || sudo -u $U git clone --depth 1 "https://github.com/$p.git" "$d"
done
install -m 644 -o $U -g $U zshrc "$H/.zshrc"
install -d -o $U -g $U "$H/.config"
install -m 644 -o $U -g $U starship.toml "$H/.config/starship.toml"
install -d -o $U -g $U "$H/.local/bin" "$H/.config/fastfetch"
install -m 755 -o $U -g $U genius-banner "$H/.local/bin/genius-banner"
install -m 644 -o $U -g $U fastfetch.jsonc "$H/.config/fastfetch/config.jsonc"
install -d -o $U -g $U "$H/.config/bat"
install -m 644 -o $U -g $U bat-config "$H/.config/bat/config"
# Message d'accueil standard d'Ubuntu remplacé par la bannière.
install -m 644 -o $U -g $U /dev/null "$H/.hushlogin"
chsh -s /usr/bin/zsh $U

step "Terminé"
docker --version
docker compose version
cscli version 2>/dev/null | head -1
ufw status | head -8

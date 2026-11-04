# Construction : dépendances installées sans scripts d'installation (aucun code
# tiers exécuté pendant npm ci), versions figées par package-lock.json.
FROM node:26-alpine@sha256:c6ad9e9c1d80f6eb607c26b4b0a132ff7a2344fad1c78ea3baa2a7d4c8de6d94 AS build
WORKDIR /app
COPY package.json package-lock.json .npmrc ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Service : nginx non-root, épinglé par empreinte, seuls les fichiers construits.
FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:15c994d10d6d78658721c3bcafff14cb281fba2a4bdf9d5ba92c416a472516e3
COPY --from=build /app/dist /usr/share/nginx/html
COPY docker/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/40-admin-config.sh /docker-entrypoint.d/40-admin-config.sh
USER 0
# Correctifs de sécurité Alpine publiés après l'image épinglée (ex. tiff,
# CVE-2026-4775) : appliqués ici sans attendre la prochaine image.
RUN apk upgrade --no-cache \
 && chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && rm -f /usr/share/nginx/html/config.example.js \
 && chown 101:101 /usr/share/nginx/html
USER 101
EXPOSE 8080

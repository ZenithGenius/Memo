# Construction : dépendances installées sans scripts d'installation (aucun code
# tiers exécuté pendant npm ci), versions figées par package-lock.json.
FROM node:25-alpine@sha256:bdf2cca6fe3dabd014ea60163eca3f0f7015fbd5c7ee1b0e9ccb4ced6eb02ef4 AS build
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

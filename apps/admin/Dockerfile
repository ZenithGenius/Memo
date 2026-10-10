# Construction : dépendances installées sans scripts d'installation (aucun code
# tiers exécuté pendant npm ci), versions figées par package-lock.json.
FROM node:24-alpine@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS build
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
RUN chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && rm -f /usr/share/nginx/html/config.example.js \
 && chown 101:101 /usr/share/nginx/html
USER 101
EXPOSE 8080

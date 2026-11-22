# Construction : dépendances installées sans scripts d'installation (aucun code
# tiers exécuté pendant npm ci), versions figées par package-lock.json.
FROM node:24-alpine@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS build
WORKDIR /app
COPY package.json package-lock.json .npmrc ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Service : nginx non-root, épinglé par empreinte, seuls les fichiers construits.
FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03
USER 0
# Correctifs de sécurité Alpine publiés après l'image épinglée (ex. tiff,
# CVE-2026-4775) : appliqués ici sans attendre la prochaine image.
# Même logique pour nginx : nginx.org tarde parfois à reconstruire son image ;
# le paquet nginx d'Alpine, déjà corrigé, remplace alors le sien. Les modules
# nginx.org (inutilisés) figent la version : ils sont retirés. La configuration
# non-root de l'image (nginx.conf) est conservée. Fait avant de copier le
# back-office : le changement de paquet vide /usr/share/nginx/html.
RUN cp /etc/nginx/nginx.conf /tmp/nginx.conf \
 && apk del --no-cache nginx-module-geoip nginx-module-image-filter nginx-module-njs nginx-module-xslt \
 && apk upgrade --no-cache \
 && apk add --no-cache 'nginx>=1.30.7' \
 && cp /tmp/nginx.conf /etc/nginx/nginx.conf && rm /tmp/nginx.conf \
 && install -d -o 101 -g 101 /var/cache/nginx
COPY --from=build /app/dist /usr/share/nginx/html
COPY docker/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/40-admin-config.sh /docker-entrypoint.d/40-admin-config.sh
RUN chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && rm -f /usr/share/nginx/html/config.example.js \
 && chown 101:101 /usr/share/nginx/html
USER 101
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1

# Image non-root, épinglée par empreinte (mise à jour par Dependabot) : un tag
# seul peut être republié avec un contenu différent.
FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03

COPY index.html app.js style.css theme.js /usr/share/nginx/html/
COPY vendor/supabase-js-2.117.3.umd.js /usr/share/nginx/html/vendor/
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.d/40-admin-config.sh /docker-entrypoint.d/40-admin-config.sh

# config.js est généré dans ce dossier à chaque démarrage (voir le script) :
# l'utilisateur non-root de l'image doit pouvoir y écrire.
USER 0
# Correctifs de sécurité Alpine publiés après l'image épinglée (ex. tiff,
# CVE-2026-4775) : appliqués ici sans attendre la prochaine image.
RUN apk upgrade --no-cache \
 && chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && chown 101:101 /usr/share/nginx/html
USER 101

EXPOSE 8080

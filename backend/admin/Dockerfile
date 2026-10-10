# Image non-root, épinglée par empreinte (mise à jour par Dependabot) : un tag
# seul peut être republié avec un contenu différent.
FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:15c994d10d6d78658721c3bcafff14cb281fba2a4bdf9d5ba92c416a472516e3

COPY index.html app.js style.css theme.js /usr/share/nginx/html/
COPY vendor/supabase-js-2.117.3.umd.js /usr/share/nginx/html/vendor/
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.d/40-admin-config.sh /docker-entrypoint.d/40-admin-config.sh

# config.js est généré dans ce dossier à chaque démarrage (voir le script) :
# l'utilisateur non-root de l'image doit pouvoir y écrire.
USER 0
RUN chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && chown 101:101 /usr/share/nginx/html
USER 101

EXPOSE 8080

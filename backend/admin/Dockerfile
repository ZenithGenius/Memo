FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY index.html app.js style.css /usr/share/nginx/html/
COPY docker-entrypoint.d/40-admin-config.sh /docker-entrypoint.d/40-admin-config.sh

# config.js est généré dans ce dossier à chaque démarrage (voir le script) :
# l'utilisateur non-root de l'image doit pouvoir y écrire.
USER root
RUN chmod +x /docker-entrypoint.d/40-admin-config.sh \
 && chown nginx:nginx /usr/share/nginx/html
USER nginx

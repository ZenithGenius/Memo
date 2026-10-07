// Copier vers config.js (ignoré par Git) et renseigner.
// La clé anon n'est pas un secret : l'accès réel est contrôlé par la
// sécurité par ligne (is_admin()), pas par cette clé.
export const SUPABASE_URL = "http://127.0.0.1:54321";
export const SUPABASE_ANON_KEY = "<clé anon affichée par `supabase status`>";

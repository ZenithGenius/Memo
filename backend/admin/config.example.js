// Copier vers config.js (ignoré par Git) et renseigner.
// La clé anon n'est pas un secret : l'accès réel est contrôlé par la
// sécurité par ligne (is_admin()), pas par cette clé.
// `supabase status` affiche plusieurs clés : prendre ANON_KEY (le long jeton
// qui commence par eyJ...), pas PUBLISHABLE_KEY ni SECRET_KEY/SERVICE_ROLE_KEY
// — ces deux dernières contournent la sécurité par ligne, à ne jamais mettre
// dans une page servie au navigateur.
export const SUPABASE_URL = "http://127.0.0.1:54321";
export const SUPABASE_ANON_KEY = "<ANON_KEY affichée par `supabase status`>";

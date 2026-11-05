/**
 * Lien de réinitialisation reçu par e-mail. Le fragment d'URL est lu au
 * chargement, avant que le client Supabase ne l'efface en ouvrant la session.
 */
export type AuthLink = "recovery" | "expired" | null;

export function readAuthLink(hash: string): AuthLink {
  const params = new URLSearchParams(hash.replace(/^#/, ""));
  if (params.get("type") === "recovery" && params.get("access_token")) return "recovery";
  if (params.get("error_code") || params.get("error")) return "expired";
  return null;
}

/** Règles du serveur : 10 caractères, minuscule, majuscule et chiffre. */
export function passwordProblem(password: string): string | null {
  if (password.length < 10) return "Au moins 10 caractères.";
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/\d/.test(password))
    return "Au moins une minuscule, une majuscule et un chiffre.";
  return null;
}

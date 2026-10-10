/**
 * Le détail technique d'une erreur part à la console, jamais à l'écran :
 * l'interface n'affiche que des messages génériques (pas de nom de table,
 * de fonction ou de règle de sécurité).
 */
export function report(context: string, error: unknown): void {
  console.error(`[${context}]`, error);
}

/** Message lisible pour les erreurs métier connues, générique sinon. */
export function userMessage(error: unknown, fallback: string): string {
  const raw = typeof error === "object" && error && "message" in error ? String(error.message) : "";
  if (raw.includes("last_super_admin")) return "Il doit rester au moins un super-administrateur.";
  if (raw.includes("unknown_account")) return "Aucun compte avec cet e-mail : la personne doit d'abord s'inscrire.";
  if (raw.includes("invalid_until")) return "La date de fin doit être dans le futur.";
  if (raw.includes("forbidden") || raw.includes("row-level security") || raw.includes("permission denied"))
    return "Votre rôle ne permet pas cette action.";
  return fallback;
}

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
  if (raw.includes("unconfirmed_email")) return "Adresse pas encore confirmée : la personne doit d'abord valider l'e-mail reçu à l'inscription.";
  if (raw.includes("invalid_until")) return "La date de fin doit être dans le futur.";
  if (raw.includes("image_too_large")) return "Image trop lourde : 512 Ko au maximum.";
  if (raw.includes("invalid_image")) return "Ce fichier n'est pas une image PNG ou WebP valide.";
  if (raw.includes("image_not_uploaded")) return "L'image n'a pas été reçue par le stockage. Réessayez.";
  if (raw.includes("nothing_to_publish")) return "Aucune modification à publier depuis la dernière publication.";
  if (raw.includes("empty_content")) return "Rien à publier : aucun pictogramme actif.";
  if (raw.includes("level_order")) return "Dans une catégorie, un mot ne peut pas passer devant un mot de niveau inférieur : corrigez l'ordre avant de publier.";
  if (raw.includes("already_published")) return "Ce pictogramme a déjà été publié : retirez-le au lieu de le supprimer.";
  if (raw.includes("duplicate key")) return "Ce code ou cette position existe déjà.";
  if (raw.includes("violates check constraint")) return "Certaines valeurs ne respectent pas les règles du catalogue.";
  if (raw.includes("forbidden") || raw.includes("row-level security") || raw.includes("permission denied"))
    return "Votre rôle ne permet pas cette action.";
  return fallback;
}

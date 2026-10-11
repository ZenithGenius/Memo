/**
 * Double authentification des administrateurs : la base n'ouvre les droits
 * qu'à une session `aal2` (migration 20261011000001). Ce calcul ne fait que
 * choisir l'écran à montrer.
 */
export type MfaStep = "done" | "verify" | "enroll";

export function mfaStep(currentLevel: string | null, nextLevel: string | null): MfaStep {
  if (currentLevel === "aal2") return "done";
  // Un facteur vérifié existe : il reste à saisir le code. Sinon, à configurer.
  return nextLevel === "aal2" ? "verify" : "enroll";
}

/** Code à six chiffres d'une application d'authentification. */
export const isTotpCode = (code: string): boolean => /^\d{6}$/.test(code);

// Durée de vie d'une session du back-office. La base applique les 24 heures
// (migration 20261127000001) ; l'interface déconnecte proprement avant qu'une
// action ne soit refusée, et après une heure sans activité.

export const MAX_SESSION_MS = 24 * 60 * 60 * 1000;
export const IDLE_MS = 60 * 60 * 1000;
export const IDLE_WARNING_MS = 60 * 1000;

/** Heure (ms) de la dernière vérification du second facteur, lue dans le jeton. */
export function mfaVerifiedAt(accessToken: string): number | null {
  try {
    const payload = accessToken.split(".")[1] ?? "";
    const json = JSON.parse(atob(payload.replace(/-/g, "+").replace(/_/g, "/"))) as { amr?: { method?: string; timestamp?: number }[] };
    const stamps = (json.amr ?? []).filter((e) => e.method === "totp" && typeof e.timestamp === "number").map((e) => (e.timestamp ?? 0) * 1000);
    return stamps.length ? Math.max(...stamps) : null;
  } catch {
    return null;
  }
}

/** Vrai quand la session a dépassé 24 heures (ou n'indique pas son second facteur). */
export function sessionExpired(accessToken: string, now: number): boolean {
  const at = mfaVerifiedAt(accessToken);
  return at === null || now - at >= MAX_SESSION_MS;
}

export const IDLE_SIGNED_OUT = "Session fermée après une heure sans activité. Reconnectez-vous.";
export const MAX_SIGNED_OUT = "Session de 24 heures écoulée. Reconnectez-vous.";

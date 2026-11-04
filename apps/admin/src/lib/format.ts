const fcfaFormatter = new Intl.NumberFormat("fr-FR");

export const fcfa = (amount: number): string => `${fcfaFormatter.format(amount)} FCFA`;

export const dateFr = (iso: string | null | undefined): string =>
  iso ? new Date(iso).toLocaleDateString("fr-FR", { day: "2-digit", month: "short", year: "numeric" }) : "—";

export const dateTimeFr = (iso: string | null | undefined): string =>
  iso
    ? new Date(iso).toLocaleString("fr-FR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" })
    : "—";

export const monthLabel = (yyyyMm: string): string => {
  const [y, m] = yyyyMm.split("-").map(Number);
  return new Date(Date.UTC(y ?? 1970, (m ?? 1) - 1, 1)).toLocaleDateString("fr-FR", {
    month: "short",
    year: "2-digit",
    timeZone: "UTC",
  });
};

export const percent = (part: number, whole: number): string =>
  whole === 0 ? "—" : `${Math.round((part / whole) * 100)} %`;

/**
 * Nouvelle date de fin pour une activation ou une prolongation : on part de
 * la fin de l'abonnement en cours s'il n'est pas encore expiré, pour qu'un
 * abonné qui paie en avance ne perde pas les jours restants.
 */
export function extendUntil(periodDays: number, currentUntil: Date | null, now: Date = new Date()): Date {
  const start = currentUntil && currentUntil > now ? currentUntil : now;
  const result = new Date(start);
  result.setDate(result.getDate() + periodDays);
  return result;
}

/** Valeur d'un <input type="date"> (AAAA-MM-JJ) en heure locale. */
export const toDateInput = (d: Date): string =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;

/** Fin de journée locale pour une date saisie : valable toute la journée choisie. */
export const endOfDay = (dateInput: string): Date => new Date(`${dateInput}T23:59:59`);

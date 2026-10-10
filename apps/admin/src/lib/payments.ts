export const PAYMENT_METHODS = {
  mtn_momo: "MTN Mobile Money",
  orange_money: "Orange Money",
  especes: "Espèces",
  virement: "Virement",
  offert: "Offert",
} as const;

export type PaymentMethod = keyof typeof PAYMENT_METHODS;

export const paymentMethods = Object.keys(PAYMENT_METHODS) as PaymentMethod[];

export const INTEGRITY = {
  strong: { tone: "success", label: "Forte" },
  unknown: { tone: "neutral", label: "Non évaluée" },
  basic: { tone: "warning", label: "Basique" },
  failed: { tone: "danger", label: "Échec" },
} as const;

/** Libellés sûrs pour une valeur venue de la base (inconnue : affichée telle quelle). */
export const methodLabel = (m: string): string =>
  (PAYMENT_METHODS as Record<string, string | undefined>)[m] ?? m;

export const integrityOf = (level: string) =>
  (INTEGRITY as Record<string, (typeof INTEGRITY)[keyof typeof INTEGRITY] | undefined>)[level] ?? INTEGRITY.unknown;

export type Situation = "active" | "expiring" | "expired" | "free";

export const SITUATION = {
  active: { tone: "success", label: "Abonné" },
  expiring: { tone: "warning", label: "Expire bientôt" },
  expired: { tone: "danger", label: "Expiré" },
  free: { tone: "neutral", label: "Gratuit" },
} as const;

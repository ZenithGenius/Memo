// Modèle des abonnements et paiements : valeurs admises, libellés, colonnes
// d'export. Aucune dépendance à l'affichage ; testé dans model.test.ts.
import type { FilterOption } from "@/components/ui/filters";
import { choice, text } from "@/hooks/use-list-filters";
import { dateFr, dateTimeFr } from "@/lib/format";
import { PAYMENT_PERIOD_OPTIONS, type PaymentPeriod } from "@/lib/payment-period";
import { methodLabel } from "@/lib/payments";
import type { PaymentRow, SubscriptionRow } from "@/lib/rpc-types";

export const PAGE_SIZE = 25;
export const EXPORT_LIMIT = 500;
export const DELETED_ACCOUNT = "Compte supprimé";

export type SubscriptionState = "all" | "active" | "expiring" | "expired" | "revoked";
type Tone = "success" | "warning" | "neutral" | "danger";

export const SUBSCRIPTION_STATES: readonly FilterOption<SubscriptionState>[] = [
  { value: "all", label: "Tous les états" },
  { value: "active", label: "En cours" },
  { value: "expiring", label: "Expirent bientôt" },
  { value: "expired", label: "Expirés" },
  { value: "revoked", label: "Résiliés" },
];

const STATE_META: Record<string, { tone: Tone; label: string }> = {
  active: { tone: "success", label: "En cours" },
  expiring: { tone: "warning", label: "Expire bientôt" },
  expired: { tone: "neutral", label: "Expiré" },
  revoked: { tone: "danger", label: "Résilié" },
};

/** Libellé et couleur de l'état d'un abonnement ; un état inconnu reste lisible. */
export function subscriptionState(state: string): { tone: Tone; label: string } {
  return STATE_META[state] ?? { tone: "neutral", label: state };
}

export const SUBSCRIPTION_FILTERS = {
  q: text(),
  etat: choice<SubscriptionState>("all", SUBSCRIPTION_STATES.map((o) => o.value)),
};

export const PAYMENT_FILTERS = {
  q: text(),
  periode: choice<PaymentPeriod>("this_month", PAYMENT_PERIOD_OPTIONS.map((o) => o.value)),
};

export const SUBSCRIPTION_CSV = {
  headers: ["Compte", "Offre", "Début", "Fin", "État"],
  toCells: (r: SubscriptionRow) => [r.email, r.plan_name, dateFr(r.starts_at), dateFr(r.valid_until), subscriptionState(r.state).label],
};

export const PAYMENT_CSV = {
  headers: ["Date", "Compte", "Montant (FCFA)", "Moyen", "Référence", "Offre", "Saisi par"],
  toCells: (r: PaymentRow) => [
    dateTimeFr(r.paid_at),
    r.email ?? DELETED_ACCOUNT,
    r.amount_fcfa,
    methodLabel(r.method),
    r.reference ?? "",
    r.plan_name ?? "",
    r.recorded_by_email ?? "Système",
  ],
};

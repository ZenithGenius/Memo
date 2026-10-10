export type PaymentPeriod = "this_month" | "last_month" | "last_12_months" | "all";

export const PAYMENT_PERIOD_OPTIONS: { value: PaymentPeriod; label: string }[] = [
  { value: "this_month", label: "Ce mois" },
  { value: "last_month", label: "Mois dernier" },
  { value: "last_12_months", label: "12 derniers mois" },
  { value: "all", label: "Tout" },
];

export interface PaymentPeriodRange {
  since: string | undefined;
  until: string | undefined;
}

/** Bornes pour admin_payments : since inclus, until exclus (fuseau local). */
export function paymentPeriodRange(period: PaymentPeriod, now: Date = new Date()): PaymentPeriodRange {
  const monthStart = (year: number, month: number) => new Date(year, month, 1, 0, 0, 0, 0);

  switch (period) {
    case "all":
      return { since: undefined, until: undefined };
    case "this_month":
      return {
        since: monthStart(now.getFullYear(), now.getMonth()).toISOString(),
        until: monthStart(now.getFullYear(), now.getMonth() + 1).toISOString(),
      };
    case "last_month":
      return {
        since: monthStart(now.getFullYear(), now.getMonth() - 1).toISOString(),
        until: monthStart(now.getFullYear(), now.getMonth()).toISOString(),
      };
    case "last_12_months":
      return {
        since: monthStart(now.getFullYear(), now.getMonth() - 12).toISOString(),
        until: undefined,
      };
  }
}

import type { Database } from "./database.types";

/**
 * Le générateur de types Supabase déclare non nulles toutes les colonnes
 * renvoyées par une fonction SQL. Celles-ci peuvent l'être : on rétablit
 * leur vrai type, sans quoi un « ?? » nécessaire passerait pour inutile.
 */
type Fn = Database["public"]["Functions"];
type Nullable<T, K extends keyof T> = Omit<T, K> & { [P in K]: T[P] | null };

export type AccountRow = Nullable<Fn["admin_accounts"]["Returns"][number], "display_name" | "phone" | "plan_name" | "valid_until">;
export type SubscriptionRow = Nullable<Fn["admin_subscriptions"]["Returns"][number], "note">;
export type PaymentRow = Nullable<Fn["admin_payments"]["Returns"][number], "reference" | "plan_name" | "recorded_by_email">;
export type DeviceRow = Nullable<Fn["admin_devices"]["Returns"][number], "label" | "installed_from_store" | "revoked_at">;
export type AdminRow = Fn["admin_list"]["Returns"][number];

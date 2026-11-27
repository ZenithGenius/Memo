// Modèle du journal d'activité : types d'événement filtrables.
import type { FilterOption } from "@/components/ui/filters";
import { choice } from "@/hooks/use-list-filters";

export const PAGE_SIZE = 25;

export type AuditEntity = "all" | "subscriptions" | "payments" | "plans" | "devices" | "admins" | "accounts" | "users";

export const AUDIT_ENTITIES: readonly FilterOption<AuditEntity>[] = [
  { value: "all", label: "Tous les événements" },
  { value: "subscriptions", label: "Abonnements" },
  { value: "payments", label: "Paiements" },
  { value: "plans", label: "Offres" },
  { value: "devices", label: "Appareils" },
  { value: "admins", label: "Administrateurs" },
  { value: "accounts", label: "Fiches compte" },
  { value: "users", label: "Comptes" },
];

export const AUDIT_FILTERS = {
  type: choice<AuditEntity>("all", AUDIT_ENTITIES.map((o) => o.value)),
};

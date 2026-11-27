// Modèle de la liste des appareils : périmètres filtrables.
import type { FilterOption } from "@/components/ui/filters";
import { choice, text } from "@/hooks/use-list-filters";
import type { DeviceScope } from "./api";

export const PAGE_SIZE = 25;

export const DEVICE_SCOPES: readonly FilterOption<DeviceScope>[] = [
  { value: "all", label: "Tous les appareils" },
  { value: "active", label: "Actifs" },
  { value: "alerts", label: "À vérifier" },
  { value: "revoked", label: "Révoqués" },
];

export const DEVICE_FILTERS = {
  q: text(),
  statut: choice<DeviceScope>("all", DEVICE_SCOPES.map((o) => o.value)),
};

/** Ce qu'il faut savoir d'un appareil pour le révoquer ou le rétablir. */
export interface DeviceRef { id: string; revoked_at: string | null }

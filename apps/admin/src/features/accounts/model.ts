// Modèle de la liste des comptes : critères de filtre et valeurs admises.
import type { FilterOption } from "@/components/ui/filters";
import { choice, text } from "@/hooks/use-list-filters";
import type { AccountFilter } from "./api";

export const PAGE_SIZE = 25;

export const ACCOUNT_SITUATIONS: readonly FilterOption<AccountFilter>[] = [
  { value: "all", label: "Toutes les situations" },
  { value: "active", label: "Abonnés" },
  { value: "expiring", label: "Expirent bientôt" },
  { value: "expired", label: "Expirés" },
  { value: "free", label: "Gratuits" },
];

export const ACCOUNT_FILTERS = {
  q: text(),
  situation: choice<AccountFilter>("all", ACCOUNT_SITUATIONS.map((o) => o.value)),
};

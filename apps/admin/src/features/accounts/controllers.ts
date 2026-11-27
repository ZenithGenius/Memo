// Contrôleur de la liste des comptes.
import { useState } from "react";
import { useDebounced } from "@/hooks/use-debounced";
import { useListFilters } from "@/hooks/use-list-filters";
import type { AccountRef } from "./AccountDrawer";
import { useAccounts } from "./api";
import { ACCOUNT_FILTERS, PAGE_SIZE } from "./model";

export function useAccountsList() {
  const filters = useListFilters(ACCOUNT_FILTERS);
  const search = useDebounced(filters.values.q.trim());
  const list = useAccounts(search, filters.values.situation, filters.page, PAGE_SIZE);
  const [account, setAccount] = useState<AccountRef | null>(null);
  return { filters, list, account, setAccount };
}

export type AccountsList = ReturnType<typeof useAccountsList>;

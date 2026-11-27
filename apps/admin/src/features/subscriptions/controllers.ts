// Contrôleurs des deux vues : état des filtres (dans l'adresse), requêtes,
// export et fiche de compte ouverte. Les vues ne reçoivent que ce qu'ils
// exposent.
import { useMemo, useState } from "react";
import { useDb } from "@/app/db-context";
import type { AccountRef } from "@/features/accounts/AccountDrawer";
import { useCsvExport } from "@/hooks/use-csv-export";
import { useDebounced } from "@/hooks/use-debounced";
import { useListFilters } from "@/hooks/use-list-filters";
import { paymentPeriodRange } from "@/lib/payment-period";
import { fetchPayments, fetchSubscriptions, usePayments, useSubscriptions } from "./api";
import { EXPORT_LIMIT, PAGE_SIZE, PAYMENT_CSV, PAYMENT_FILTERS, SUBSCRIPTION_CSV, SUBSCRIPTION_FILTERS } from "./model";

export function useSubscriptionsList() {
  const db = useDb();
  const filters = useListFilters(SUBSCRIPTION_FILTERS);
  const search = useDebounced(filters.values.q.trim());
  const q = useMemo(() => ({ query: search, state: filters.values.etat }), [search, filters.values.etat]);
  const list = useSubscriptions(q, { page: filters.page, pageSize: PAGE_SIZE });
  const exporter = useCsvExport({ filename: "memo-abonnements", ...SUBSCRIPTION_CSV, fetch: () => fetchSubscriptions(db, q, EXPORT_LIMIT, 0) });
  const [account, setAccount] = useState<AccountRef | null>(null);
  return { filters, searching: search !== "", list, exporter, account, setAccount };
}

export function usePaymentsList() {
  const db = useDb();
  const filters = useListFilters(PAYMENT_FILTERS);
  const search = useDebounced(filters.values.q.trim());
  const q = useMemo(() => ({ query: search, ...paymentPeriodRange(filters.values.periode) }), [search, filters.values.periode]);
  const list = usePayments(q, { page: filters.page, pageSize: PAGE_SIZE });
  const exporter = useCsvExport({ filename: "memo-paiements", ...PAYMENT_CSV, fetch: () => fetchPayments(db, q, EXPORT_LIMIT, 0) });
  const [account, setAccount] = useState<AccountRef | null>(null);
  return { filters, searching: search !== "", list, exporter, account, setAccount };
}

export type SubscriptionsList = ReturnType<typeof useSubscriptionsList>;
export type PaymentsList = ReturnType<typeof usePaymentsList>;

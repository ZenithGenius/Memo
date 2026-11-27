// Accès aux données des abonnements et paiements (fonctions RPC du serveur).
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { PaymentRow, SubscriptionRow } from "@/lib/rpc-types";
import type { Db } from "@/lib/supabase";
import type { SubscriptionState } from "./model";

export interface SubscriptionQuery { query: string; state: SubscriptionState }
export interface PaymentQuery { query: string; since: string | undefined; until: string | undefined }
interface Page { page: number; pageSize: number }

export async function fetchSubscriptions(db: Db, q: SubscriptionQuery, lim: number, off: number): Promise<SubscriptionRow[]> {
  const { data, error } = await db.rpc("admin_subscriptions", { query: q.query, status: q.state, lim, off });
  if (error) throw error;
  return data;
}

export async function fetchPayments(db: Db, q: PaymentQuery, lim: number, off: number): Promise<PaymentRow[]> {
  const { data, error } = await db.rpc("admin_payments", { query: q.query, since: q.since, until: q.until, lim, off });
  if (error) throw error;
  return data;
}

export function useSubscriptions(q: SubscriptionQuery, { page, pageSize }: Page) {
  const db = useDb();
  return useQuery({
    queryKey: ["subscriptions", q, page, pageSize],
    queryFn: async () => {
      const rows = await fetchSubscriptions(db, q, pageSize, page * pageSize);
      return { rows, total: rows[0]?.total ?? 0 };
    },
    placeholderData: keepPreviousData,
  });
}

export function usePayments(q: PaymentQuery, { page, pageSize }: Page) {
  const db = useDb();
  return useQuery({
    queryKey: ["payments", q, page, pageSize],
    queryFn: async () => {
      const rows = await fetchPayments(db, q, pageSize, page * pageSize);
      return { rows, total: rows[0]?.total ?? 0, totalAmountFcfa: rows[0]?.total_amount_fcfa ?? 0 };
    },
    placeholderData: keepPreviousData,
  });
}

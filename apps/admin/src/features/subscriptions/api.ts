import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { PaymentRow, SubscriptionRow } from "@/lib/rpc-types";

export type SubscriptionFilter = "all" | "active" | "expiring" | "expired" | "revoked";

export function useSubscriptions(query: string, status: SubscriptionFilter, page: number, pageSize: number) {
  const db = useDb();
  return useQuery({
    queryKey: ["subscriptions", query, status, page, pageSize],
    queryFn: async (): Promise<{ rows: SubscriptionRow[]; total: number }> => {
      const { data, error } = await db.rpc("admin_subscriptions", {
        query,
        status,
        lim: pageSize,
        off: page * pageSize,
      });
      if (error) throw error;
      return { rows: data, total: data[0]?.total ?? 0 };
    },
    placeholderData: keepPreviousData,
  });
}

export function usePayments(
  query: string,
  since: string | undefined,
  until: string | undefined,
  page: number,
  pageSize: number,
) {
  const db = useDb();
  return useQuery({
    queryKey: ["payments", query, since, until, page, pageSize],
    queryFn: async (): Promise<{ rows: PaymentRow[]; total: number; totalAmountFcfa: number }> => {
      const { data, error } = await db.rpc("admin_payments", {
        query,
        since,
        until,
        lim: pageSize,
        off: page * pageSize,
      });
      if (error) throw error;
      return {
        rows: data,
        total: data[0]?.total ?? 0,
        totalAmountFcfa: data[0]?.total_amount_fcfa ?? 0,
      };
    },
    placeholderData: keepPreviousData,
  });
}

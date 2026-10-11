import { useMutation, useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { TablesInsert, TablesUpdate } from "@/lib/database.types";
import { useInvalidateAll } from "@/features/accounts/api";

export type PlanRow = {
  code: string;
  name: string;
  price_fcfa: number;
  period_days: number;
  max_devices: number;
  active: boolean;
  sort_order: number;
};

export function usePlans() {
  const db = useDb();
  return useQuery({
    queryKey: ["plans"],
    queryFn: async (): Promise<PlanRow[]> => {
      const { data, error } = await db
        .from("plans")
        .select("code, name, price_fcfa, period_days, max_devices, active, sort_order")
        .order("sort_order");
      if (error) throw error;
      return data;
    },
  });
}

export function useUpsertPlan() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async (input: { mode: "create"; row: TablesInsert<"plans"> } | { mode: "update"; code: string; row: TablesUpdate<"plans"> }) => {
      if (input.mode === "create") {
        const { error } = await db.from("plans").insert({ ...input.row, active: input.row.active ?? true });
        if (error) throw error;
        return;
      }
      const { error } = await db.from("plans").update(input.row).eq("code", input.code);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useSetPlanActive() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ code, active }: { code: string; active: boolean }) => {
      const { error } = await db.from("plans").update({ active }).eq("code", code);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

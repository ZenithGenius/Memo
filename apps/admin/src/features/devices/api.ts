import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { DeviceRow } from "@/lib/rpc-types";

export type DeviceScope = "all" | "active" | "alerts" | "revoked";

export function useDevices(query: string, scope: DeviceScope, page: number, pageSize: number) {
  const db = useDb();
  return useQuery({
    queryKey: ["devices", query, scope, page, pageSize],
    queryFn: async (): Promise<{ rows: DeviceRow[]; total: number }> => {
      const { data, error } = await db.rpc("admin_devices", {
        query,
        scope,
        lim: pageSize,
        off: page * pageSize,
      });
      if (error) throw error;
      return { rows: data, total: data[0]?.total ?? 0 };
    },
    placeholderData: keepPreviousData,
  });
}

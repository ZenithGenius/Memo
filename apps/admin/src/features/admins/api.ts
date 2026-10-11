import { useMutation, useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { AdminRow } from "@/lib/rpc-types";
import { useInvalidateAll } from "@/features/accounts/api";
import type { AdminRole } from "@/lib/roles";

export function useAdmins() {
  const db = useDb();
  return useQuery({
    queryKey: ["admins"],
    queryFn: async (): Promise<AdminRow[]> => {
      const { data, error } = await db.rpc("admin_list");
      if (error) throw error;
      return data;
    },
  });
}

export function useSetAdminRole() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ targetEmail, newRole }: { targetEmail: string; newRole: AdminRole }) => {
      const { error } = await db.rpc("admin_set_role", { target_email: targetEmail, new_role: newRole });
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useRemoveAdmin() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ target }: { target: string }) => {
      const { error } = await db.rpc("admin_remove", { target });
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

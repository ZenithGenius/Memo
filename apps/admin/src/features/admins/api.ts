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

/** Code d'erreur métier renvoyé par la fonction (voir userMessage), sinon le message brut. */
async function inviteErrorCode(error: unknown): Promise<string> {
  const context: unknown = typeof error === "object" && error && "context" in error ? error.context : null;
  if (context instanceof Response) {
    const body: unknown = await context.json().catch(() => null);
    if (typeof body === "object" && body && "error" in body && typeof body.error === "string") return body.error;
  }
  return error instanceof Error ? error.message : "erreur inconnue";
}

/**
 * Ajout d'un administrateur : une nouvelle adresse reçoit une invitation par
 * e-mail (fonction serveur admin-invite), un compte existant reçoit le rôle.
 */
export function useInviteAdmin() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ email, role }: { email: string; role: AdminRole }): Promise<"invited" | "role_set"> => {
      const result = await db.functions.invoke<{ status: "invited" | "role_set" }>("admin-invite", {
        body: { email, role },
      });
      const error: unknown = result.error;
      if (error) throw new Error(await inviteErrorCode(error));
      if (!result.data) throw new Error("réponse vide");
      return result.data.status;
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

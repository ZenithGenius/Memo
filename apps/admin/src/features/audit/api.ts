import { useQuery } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";

export function useAdminEmails() {
  const db = useDb();
  return useQuery({
    queryKey: ["admins"],
    queryFn: async () => {
      const { data, error } = await db.rpc("admin_list");
      if (error) throw error;
      return data;
    },
    select: (rows) => new Map(rows.map((r) => [r.user_id, r.email])),
  });
}

export interface AuditFilters { entity: string; page: number; pageSize: number }

export function useAudit({ entity, page, pageSize }: AuditFilters) {
  const db = useDb();
  return useQuery({
    queryKey: ["audit", entity, page, pageSize],
    queryFn: async () => {
      let q = db.from("audit_log").select("id, at, actor, action, entity, entity_id, before, after", { count: "exact" })
        .order("at", { ascending: false })
        .range(page * pageSize, page * pageSize + pageSize - 1);
      if (entity !== "all") q = q.eq("entity", entity);
      const { data, error, count } = await q;
      if (error) throw error;
      return { rows: data, total: count ?? 0 };
    },
    placeholderData: (prev) => prev,
  });
}

/** Nom d'auteur affiché : e-mail de l'administrateur, « Système » sinon. */
export const actorName = (actor: string | null, emails: Map<string, string> | undefined): string =>
  actor === null ? "Système" : emails?.get(actor) ?? "Ancien administrateur";

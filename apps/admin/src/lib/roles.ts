export type AdminRole = "super_admin" | "support";

export const ROLE_LABEL: Record<AdminRole, string> = {
  super_admin: "Super-administrateur",
  support: "Support (lecture seule)",
};

export const isAdminRole = (value: unknown): value is AdminRole =>
  value === "super_admin" || value === "support";

/**
 * Seul un super-administrateur écrit. Ce contrôle ne sert qu'à masquer les
 * boutons inutiles : la base refuse de toute façon (sécurité par ligne).
 */
export const canWrite = (role: AdminRole | null): boolean => role === "super_admin";

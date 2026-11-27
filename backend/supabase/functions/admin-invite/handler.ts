import { json } from "../_shared/http.ts";

export type AdminRole = "super_admin" | "support";

/** Erreur d'une fonction SQL (code renvoyé tel quel au back-office). */
export class RoleError extends Error {}

export interface InviteDeps {
  /** Adresse du back-office : seule origine autorisée, et page d'arrivée du lien. */
  siteUrl: string;
  /** Le jeton de l'appelant est celui d'un super-administrateur (second facteur compris). */
  isSuperAdmin(authorization: string): Promise<boolean>;
  /** L'adresse a déjà un compte, confirmé ou non. */
  accountExists(email: string): Promise<boolean>;
  /** Crée le compte et envoie l'invitation ; "exists" si l'adresse a déjà un compte. */
  invite(email: string, redirectTo: string): Promise<{ id: string } | "exists">;
  /** Rôle d'un compte invité, au nom de l'appelant (journal d'audit). */
  grantInvited(authorization: string, userId: string, role: AdminRole): Promise<void>;
  /** Rôle d'un compte existant, avec les règles habituelles (adresse confirmée…). */
  setRole(authorization: string, email: string, role: AdminRole): Promise<void>;
}

const EMAIL = /^[^\s@]{1,64}@[^\s@]{1,255}\.[^\s@]{2,}$/;
const ROLES: readonly string[] = ["super_admin", "support"];
/** Refus métier des fonctions SQL, renvoyés au back-office pour un message clair. */
const KNOWN = new Set(["unconfirmed_email", "last_super_admin", "not_invited", "invalid_role"]);

/**
 * Invitation d'un administrateur (back-office). POST { email, role }.
 * Nouvelle adresse : compte créé, e-mail d'invitation, rôle attribué.
 * Compte existant : rôle attribué comme avant.
 */
export function createInviteHandler(deps: InviteDeps): (req: Request) => Promise<Response> {
  const cors = {
    "Access-Control-Allow-Origin": deps.siteUrl,
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
  const reply = (status: number, body: Record<string, unknown>) => json(status, body, cors);

  return async (req) => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (req.method !== "POST") return reply(405, { error: "method_not_allowed" });
    try {
      const authorization = req.headers.get("Authorization") ?? "";
      if (!authorization.startsWith("Bearer ") || !(await deps.isSuperAdmin(authorization))) {
        return reply(403, { error: "forbidden" });
      }
      const body = await req.json().catch(() => null) as { email?: unknown; role?: unknown } | null;
      const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : "";
      const role = typeof body?.role === "string" ? body.role : "";
      if (!EMAIL.test(email)) return reply(400, { error: "invalid_email" });
      if (!ROLES.includes(role)) return reply(400, { error: "invalid_role" });

      // Adresse qui a déjà un compte : jamais d'invitation, rôle par la voie
      // habituelle (adresse confirmée exigée). Un compte inscrit d'avance par
      // un tiers, non confirmé, ne peut donc pas recevoir de rôle.
      const invited = (await deps.accountExists(email))
        ? "exists"
        : await deps.invite(email, `${deps.siteUrl}/`);
      if (invited === "exists") {
        await deps.setRole(authorization, email, role as AdminRole);
        return reply(200, { status: "role_set" });
      }
      await deps.grantInvited(authorization, invited.id, role as AdminRole);
      return reply(200, { status: "invited" });
    } catch (e) {
      if (e instanceof RoleError && KNOWN.has(e.message)) return reply(409, { error: e.message });
      console.error("admin-invite", e);
      return reply(500, { error: "internal_error" });
    }
  };
}

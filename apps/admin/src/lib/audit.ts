import type { Json } from "./database.types";
import { dateFr, fcfa } from "./format";
import { methodLabel } from "./payments";
import { ROLE_LABEL, isAdminRole } from "./roles";

export interface AuditEntry {
  action: string;
  entity: string;
  before: Json | null;
  after: Json | null;
}

type Row = Record<string, Json | undefined>;
const asRow = (v: Json | null): Row => (v && typeof v === "object" && !Array.isArray(v) ? v : {});
const str = (v: Json | undefined): string => (typeof v === "string" ? v : "");
const num = (v: Json | undefined): number => (typeof v === "number" ? v : 0);

export const ENTITY_LABEL: Record<string, string> = {
  subscriptions: "Abonnement",
  payments: "Paiement",
  plans: "Offre",
  admins: "Administrateur",
  devices: "Appareil",
  accounts: "Fiche compte",
};

/** Phrase lisible pour une ligne du journal d'activité. */
export function describe(e: AuditEntry): string {
  const before = asRow(e.before);
  const after = asRow(e.after);
  switch (e.entity) {
    case "subscriptions":
      if (e.action === "insert") return `Abonnement activé : ${str(after.plan_code)} jusqu'au ${dateFr(str(after.valid_until))}`;
      if (after.status === "revoked" && before.status !== "revoked") return "Abonnement résilié";
      if (after.status === "active" && before.status === "revoked") return "Abonnement rétabli";
      return "Abonnement modifié";
    case "payments": {
      return `Paiement de ${fcfa(num(after.amount_fcfa))} (${methodLabel(str(after.method))})`;
    }
    case "plans":
      if (e.action === "insert") return `Offre créée : ${str(after.name)}`;
      if (before.active === true && after.active === false) return `Offre retirée de la vente : ${str(after.name)}`;
      if (before.active === false && after.active === true) return `Offre remise en vente : ${str(after.name)}`;
      return `Offre modifiée : ${str(after.name)}`;
    case "admins": {
      const role = isAdminRole(after.role) ? ROLE_LABEL[after.role] : "";
      if (e.action === "insert") return `Administrateur ajouté (${role})`;
      if (e.action === "delete") return "Administrateur retiré";
      return `Rôle changé : ${role}`;
    }
    case "devices":
      return after.revoked_at ? "Appareil révoqué" : "Appareil rétabli";
    case "accounts":
      return "Fiche compte modifiée";
    default:
      return `${ENTITY_LABEL[e.entity] ?? e.entity} : ${e.action}`;
  }
}

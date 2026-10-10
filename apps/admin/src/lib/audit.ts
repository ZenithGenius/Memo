import type { Json } from "./database.types";
import { dateFr, dateTimeFr, fcfa } from "./format";
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

const jsonEqual = (a: Json | undefined, b: Json | undefined): boolean =>
  JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

const displayValue = (v: Json | undefined): string => {
  if (v === undefined) return "";
  if (typeof v === "string") return v;
  return JSON.stringify(v);
};

export interface ChangedField { field: string; before: string; after: string }

/** Champs modifiés entre deux instantanés JSON (journal d'activité). */
export function changedFields(before: Json | null | undefined, after: Json | null | undefined): ChangedField[] {
  const bRow = asRow(before ?? null);
  const aRow = asRow(after ?? null);
  const keys = [...new Set([...Object.keys(bRow), ...Object.keys(aRow)])].sort();
  const wholeInsert = before == null;
  const wholeDelete = after == null;

  const out: ChangedField[] = [];
  for (const field of keys) {
    const bv = bRow[field];
    const av = aRow[field];
    if (jsonEqual(bv, av)) continue;
    out.push({
      field,
      before: wholeInsert ? "" : displayValue(bv),
      after: wholeDelete ? "" : displayValue(av),
    });
  }
  return out;
}

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

// ─── Détails lisibles ────────────────────────────────────────────────────────

/** Champs techniques jamais affichés (identifiants internes, empreinte). */
const HIDDEN = new Set(["id", "user_id", "subscription_id", "created_at", "fingerprint", "first_seen", "last_seen"]);

const LABELS: Record<string, string> = {
  plan_code: "Offre", valid_until: "Valide jusqu'au", starts_at: "Début", status: "Statut", note: "Note",
  activated_by: "Activé par", revoked_by: "Résilié par", revoked_at: "Révoqué le",
  amount_fcfa: "Montant", method: "Moyen de paiement", reference: "Référence", paid_at: "Payé le", recorded_by: "Saisi par",
  code: "Code", name: "Nom", price_fcfa: "Prix", period_days: "Durée (jours)", max_devices: "Appareils max",
  active: "En vente", sort_order: "Ordre d'affichage", role: "Rôle", display_name: "Nom affiché", phone: "Téléphone",
  platform: "Plateforme", label: "Nom de l'appareil", integrity_level: "Intégrité", installed_from_store: "Installé depuis la boutique",
};

const USER_FIELDS = new Set(["activated_by", "revoked_by", "recorded_by"]);
const DATE_FIELDS = new Set(["valid_until", "starts_at", "revoked_at", "paid_at"]);

export interface HumanChange { label: string; before?: string; after: string }

function humanValue(field: string, v: Json | undefined, resolveUser: (id: string) => string): string {
  if (v === undefined || v === null || v === "") return "vide";
  if (typeof v === "boolean") return v ? "Oui" : "Non";
  if (USER_FIELDS.has(field) && typeof v === "string") return resolveUser(v);
  if (DATE_FIELDS.has(field) && typeof v === "string") return dateTimeFr(v);
  if (field === "amount_fcfa" || field === "price_fcfa") return fcfa(num(v));
  if (field === "method") return methodLabel(str(v));
  if (field === "role") return isAdminRole(v) ? ROLE_LABEL[v] : str(v);
  if (field === "status") return v === "active" ? "Actif" : v === "revoked" ? "Résilié" : str(v);
  return typeof v === "string" ? v : JSON.stringify(v);
}

/**
 * Changements d'une ligne du journal en français : libellés métier, dates et
 * montants formatés, comptes désignés par leur e-mail, champs techniques
 * masqués. Une création n'a pas de valeur « avant ».
 */
export function humanChanges(e: AuditEntry, resolveUser: (id: string) => string): HumanChange[] {
  const isInsert = e.action === "insert";
  const before = asRow(e.before);
  const after = asRow(e.after);
  return changedFields(e.before, e.after)
    .filter((c) => !HIDDEN.has(c.field))
    .map((c) => {
      const label = LABELS[c.field] ?? c.field;
      const afterText = humanValue(c.field, e.action === "delete" ? undefined : after[c.field], resolveUser);
      return isInsert ? { label, after: afterText } : { label, before: humanValue(c.field, before[c.field], resolveUser), after: afterText };
    });
}

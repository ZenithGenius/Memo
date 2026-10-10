import { describe as suite, expect, it } from "vitest";
import { changedFields, describe } from "./audit";

suite("journal d'activité lisible", () => {
  it("activation d'abonnement", () => {
    expect(describe({ action: "insert", entity: "subscriptions", before: null, after: { plan_code: "essentiel", valid_until: "2026-11-22T10:00:00Z" } }))
      .toMatch(/^Abonnement activé : essentiel jusqu'au 22 nov\. 2026$/);
  });
  it("résiliation puis rétablissement", () => {
    expect(describe({ action: "update", entity: "subscriptions", before: { status: "active" }, after: { status: "revoked" } })).toBe("Abonnement résilié");
    expect(describe({ action: "update", entity: "subscriptions", before: { status: "revoked" }, after: { status: "active" } })).toBe("Abonnement rétabli");
  });
  it("paiement avec son moyen", () => {
    expect(describe({ action: "insert", entity: "payments", before: null, after: { amount_fcfa: 1000, method: "mtn_momo" } }))
      .toBe("Paiement de 1 000 FCFA (MTN Mobile Money)");
  });
  it("offre retirée de la vente", () => {
    expect(describe({ action: "update", entity: "plans", before: { active: true, name: "Famille" }, after: { active: false, name: "Famille" } }))
      .toBe("Offre retirée de la vente : Famille");
  });
  it("administrateur et appareil", () => {
    expect(describe({ action: "insert", entity: "admins", before: null, after: { role: "support" } })).toBe("Administrateur ajouté (Support (lecture seule))");
    expect(describe({ action: "update", entity: "devices", before: { revoked_at: null }, after: { revoked_at: "2026-10-10T10:00:00Z" } })).toBe("Appareil révoqué");
    expect(describe({ action: "update", entity: "devices", before: { revoked_at: "x" }, after: { revoked_at: null } })).toBe("Appareil rétabli");
  });
});

suite("changedFields", () => {
  it("mise à jour", () => {
    expect(changedFields({ name: "A", price_fcfa: 1000 }, { name: "B", price_fcfa: 1000 })).toEqual([
      { field: "name", before: "A", after: "B" },
    ]);
  });
  it("insertion", () => {
    expect(changedFields(null, { code: "essentiel", active: true })).toEqual([
      { field: "active", before: "", after: "true" },
      { field: "code", before: "", after: "essentiel" },
    ]);
  });
  it("suppression", () => {
    expect(changedFields({ code: "essentiel" }, null)).toEqual([
      { field: "code", before: "essentiel", after: "" },
    ]);
  });
  it("champs identiques ignorés", () => {
    expect(changedFields({ a: 1, b: "x" }, { a: 1, b: "y" })).toEqual([{ field: "b", before: "x", after: "y" }]);
  });
  it("valeurs non texte", () => {
    expect(changedFields({ flags: [1, 2] }, { flags: [1, 3] })).toEqual([
      { field: "flags", before: "[1,2]", after: "[1,3]" },
    ]);
  });
});

import { humanChanges } from "./audit";

suite("détails lisibles du journal", () => {
  const resolve = (id: string) => (id === "u-admin" ? "admin@memo.cm" : "Ancien administrateur");

  it("création : libellés français, valeurs formatées, champs techniques masqués", () => {
    const changes = humanChanges(
      { action: "insert", entity: "payments", before: null,
        after: { id: "p1", user_id: "u1", amount_fcfa: 1000, method: "orange_money", reference: "OM1", recorded_by: "u-admin" } },
      resolve,
    );
    expect(changes.map((c) => c.label)).toEqual(["Montant", "Moyen de paiement", "Saisi par", "Référence"]);
    expect(changes.find((c) => c.label === "Saisi par")).toEqual({ label: "Saisi par", after: "admin@memo.cm" });
    expect(changes.every((c) => c.before === undefined)).toBe(true);
    expect(changes.some((c) => /p1|u1/.test(c.after))).toBe(false);
  });

  it("modification : avant et après traduits", () => {
    const [status] = humanChanges(
      { action: "update", entity: "subscriptions", before: { status: "active" }, after: { status: "revoked" } },
      resolve,
    );
    expect(status).toEqual({ label: "Statut", before: "Actif", after: "Résilié" });
  });

  it("booléens et valeurs vides", () => {
    const changes = humanChanges(
      { action: "update", entity: "plans", before: { active: true, note: null }, after: { active: false, note: "promo" } },
      resolve,
    );
    expect(changes).toContainEqual({ label: "En vente", before: "Oui", after: "Non" });
    expect(changes).toContainEqual({ label: "Note", before: "vide", after: "promo" });
  });
});

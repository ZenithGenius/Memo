import { describe as suite, expect, it } from "vitest";
import { describe } from "./audit";

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

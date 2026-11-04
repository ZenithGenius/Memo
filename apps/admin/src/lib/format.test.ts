import { describe, expect, it } from "vitest";
import { endOfDay, extendUntil, percent, toDateInput } from "./format";
import { canWrite } from "./roles";
import { readConfig } from "./config";

describe("prolongation", () => {
  const now = new Date("2026-10-10T12:00:00");
  it("part de la fin de l'abonnement en cours s'il court encore", () => {
    expect(toDateInput(extendUntil(30, new Date("2026-10-23T12:00:00"), now))).toBe("2026-11-22");
  });
  it("part d'aujourd'hui si l'abonnement est expiré ou absent", () => {
    expect(toDateInput(extendUntil(30, new Date("2026-09-01T12:00:00"), now))).toBe("2026-11-09");
    expect(toDateInput(extendUntil(30, null, now))).toBe("2026-11-09");
  });
  it("une date saisie vaut jusqu'à la fin de la journée", () => {
    expect(endOfDay("2026-11-22").getHours()).toBe(23);
  });
});

describe("pourcentages", () => {
  it("arrondit et gère la division par zéro", () => {
    expect(percent(1, 3)).toBe("33 %");
    expect(percent(0, 0)).toBe("—");
  });
});

describe("rôles", () => {
  it("seul un super-administrateur écrit", () => {
    expect(canWrite("super_admin")).toBe(true);
    expect(canWrite("support")).toBe(false);
    expect(canWrite(null)).toBe(false);
  });
});

describe("configuration", () => {
  it("refuse une configuration incomplète ou invalide", () => {
    expect(readConfig(undefined)).toBeNull();
    expect(readConfig({ supabaseUrl: "pas une url", supabaseAnonKey: "x".repeat(30) })).toBeNull();
    expect(readConfig({ supabaseUrl: "http://127.0.0.1:54321", supabaseAnonKey: "x".repeat(30) })).not.toBeNull();
  });
});

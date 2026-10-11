import { describe, expect, it } from "vitest";
import { isTotpCode, mfaStep } from "./mfa";

describe("double authentification", () => {
  it("session déjà vérifiée par le second facteur : rien à demander", () => {
    expect(mfaStep("aal2", "aal2")).toBe("done");
  });
  it("facteur configuré mais session au mot de passe seul : code demandé", () => {
    expect(mfaStep("aal1", "aal2")).toBe("verify");
  });
  it("aucun facteur : configuration demandée", () => {
    expect(mfaStep("aal1", "aal1")).toBe("enroll");
    expect(mfaStep(null, null)).toBe("enroll");
  });
  it("code à six chiffres exactement", () => {
    expect(isTotpCode("123456")).toBe(true);
    expect(isTotpCode("12345")).toBe(false);
    expect(isTotpCode("12345a")).toBe(false);
    expect(isTotpCode(" 123456")).toBe(false);
  });
});

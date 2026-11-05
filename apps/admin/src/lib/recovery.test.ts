import { describe, expect, it } from "vitest";
import { passwordProblem, readAuthLink } from "./recovery";

describe("lien de réinitialisation", () => {
  it("lien valide", () => {
    expect(readAuthLink("#access_token=a&refresh_token=r&type=recovery")).toBe("recovery");
  });
  it("lien expiré ou déjà utilisé", () => {
    expect(readAuthLink("#error=access_denied&error_code=otp_expired&error_description=x")).toBe("expired");
  });
  it("aucun lien", () => {
    expect(readAuthLink("")).toBeNull();
    expect(readAuthLink("#type=recovery")).toBeNull();
  });
});

describe("règles du mot de passe", () => {
  it("refuse trop court ou trop simple", () => {
    expect(passwordProblem("Court1")).not.toBeNull();
    expect(passwordProblem("toutenminuscule1")).not.toBeNull();
    expect(passwordProblem("SansChiffreDuTout")).not.toBeNull();
  });
  it("accepte un mot de passe conforme", () => {
    expect(passwordProblem("Memo-Secret-2026")).toBeNull();
  });
});

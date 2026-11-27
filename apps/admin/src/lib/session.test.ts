import { describe, expect, it } from "vitest";
import { MAX_SESSION_MS, mfaVerifiedAt, sessionExpired } from "./session";

const b64 = (o: unknown) => btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const token = (claims: unknown) => `${b64({ alg: "HS256" })}.${b64(claims)}.sig`;
const NOW = Date.UTC(2026, 10, 27, 12, 0, 0);

describe("session du back-office", () => {
  it("lit l'heure du second facteur dans le jeton", () => {
    const t = token({ amr: [{ method: "password", timestamp: 100 }, { method: "totp", timestamp: 200 }] });
    expect(mfaVerifiedAt(t)).toBe(200_000);
  });

  it("valable 24 heures après le second facteur, pas au-delà", () => {
    const at = (ms: number) => token({ amr: [{ method: "totp", timestamp: Math.floor((NOW - ms) / 1000) }] });
    expect(sessionExpired(at(MAX_SESSION_MS - 60_000), NOW)).toBe(false);
    expect(sessionExpired(at(MAX_SESSION_MS + 60_000), NOW)).toBe(true);
  });

  it("jeton sans second facteur ou illisible : expiré", () => {
    expect(sessionExpired(token({ amr: [{ method: "password", timestamp: 1 }] }), NOW)).toBe(true);
    expect(sessionExpired("pas-un-jeton", NOW)).toBe(true);
  });
});

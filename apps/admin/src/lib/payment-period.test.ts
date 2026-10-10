import { describe, expect, it } from "vitest";
import { paymentPeriodRange } from "./payment-period";

describe("paymentPeriodRange", () => {
  const now = new Date("2026-10-15T14:30:00");

  it("couvre le mois en cours en local", () => {
    const { since, until } = paymentPeriodRange("this_month", now);
    expect(since).toBe(new Date(2026, 9, 1).toISOString());
    expect(until).toBe(new Date(2026, 10, 1).toISOString());
  });

  it("couvre le mois précédent", () => {
    const { since, until } = paymentPeriodRange("last_month", now);
    expect(since).toBe(new Date(2026, 8, 1).toISOString());
    expect(until).toBe(new Date(2026, 9, 1).toISOString());
  });

  it("remonte sur 12 mois sans borne haute", () => {
    const { since, until } = paymentPeriodRange("last_12_months", now);
    expect(since).toBe(new Date(2025, 9, 1).toISOString());
    expect(until).toBeUndefined();
  });

  it("ne filtre pas quand tout est demandé", () => {
    expect(paymentPeriodRange("all", now)).toEqual({ since: undefined, until: undefined });
  });
});

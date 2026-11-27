import { describe, expect, it } from "vitest";
import { activeCount, readFilters, writeFilters } from "./use-list-filters";

const specs = {
  q: { default: "" },
  status: { default: "all", values: ["all", "active", "expired"] as const },
};

describe("filtres d'une liste dans l'adresse", () => {
  it("valeurs par défaut quand l'adresse est vide ou porte une valeur non admise", () => {
    expect(readFilters(specs, new URLSearchParams(""))).toEqual({ q: "", status: "all" });
    expect(readFilters(specs, new URLSearchParams("status=hack"))).toEqual({ q: "", status: "all" });
    expect(readFilters(specs, new URLSearchParams("q=ami&status=active"))).toEqual({ q: "ami", status: "active" });
  });

  it("un changement retire les valeurs par défaut et revient à la première page", () => {
    const next = writeFilters(specs, new URLSearchParams("status=active&page=3&tab=x"), { status: "all", q: "léa" });
    expect(next.get("status")).toBeNull();
    expect(next.get("page")).toBeNull();
    expect(next.get("q")).toBe("léa");
    expect(next.get("tab")).toBe("x");
  });

  it("compte les critères actifs", () => {
    expect(activeCount(specs, { q: "", status: "all" })).toBe(0);
    expect(activeCount(specs, { q: "a", status: "expired" })).toBe(2);
  });
});

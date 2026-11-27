import { describe, expect, it } from "vitest";
import type { CategoryRow, PictogramRow } from "./api";
import { categoryCounts, contentFacets, filterPictograms, type ContentFilters } from "./model";

const pict = (code: string, cat: string, fr: string, o: Partial<PictogramRow> = {}) =>
  ({ code, category_code: cat, tier: "premium", image_sha256: null, image_asset: null, labels: { fr: { label: fr }, en: { label: fr } }, ...o }) as unknown as PictogramRow;
const cat = (code: string, fr: string) => ({ code, labels: { fr, en: fr } }) as unknown as CategoryRow;

const rows = [
  pict("A1", "CBE", "Encore", { tier: "free", image_sha256: "x" }),
  pict("A2", "CBE", "Fini", { tier: "free" }),
  pict("S1", "SAN", "Tête", { image_asset: "demo.png" }),
  pict("S2", "SAN", "Médicament"),
];
const none: ContentFilters = { q: "", categorie: "all", image: "all", offre: "all" };

describe("filtres du contenu", () => {
  it("combine catégorie, image, offre et recherche sans accents", () => {
    expect(filterPictograms(rows, { ...none, categorie: "SAN" }).map((p) => p.code)).toEqual(["S1", "S2"]);
    expect(filterPictograms(rows, { ...none, image: "missing" }).map((p) => p.code)).toEqual(["A2", "S2"]);
    expect(filterPictograms(rows, { ...none, offre: "free", image: "uploaded" }).map((p) => p.code)).toEqual(["A1"]);
    expect(filterPictograms(rows, { ...none, q: "medic" }).map((p) => p.code)).toEqual(["S2"]);
  });

  it("chaque effectif dit combien de lignes ce choix afficherait avec les autres critères", () => {
    const f = contentFacets(rows, [cat("CBE", "Mes besoins"), cat("SAN", "Santé")], { ...none, offre: "free" });
    expect(f.categorie.find((o) => o.value === "CBE")?.count).toBe(2);
    expect(f.categorie.find((o) => o.value === "SAN")?.count).toBe(0);
    expect(f.image.find((o) => o.value === "missing")?.count).toBe(1);
    // L'effectif d'une offre ignore le filtre d'offre lui-même.
    expect(f.offre.find((o) => o.value === "premium")?.count).toBe(2);
  });

  it("compte les mots et ceux sans image d'une catégorie", () => {
    expect(categoryCounts(rows, "SAN")).toEqual({ total: 2, missing: 1 });
  });
});

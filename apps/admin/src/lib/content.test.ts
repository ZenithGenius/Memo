import { describe, expect, it } from "vitest";
import { contrastOnWhite, hasImageSignature, imageFileProblem, imageState, levelOrderProblem, nextCode, nextSortOrder, sha256Hex } from "./content";

describe("catalogue", () => {
  it("code suivant dans la catégorie, jamais réattribué", () => {
    expect(nextCode("ACT", ["CAA-CR-ACT-001", "CAA-CR-ACT-025", "CAA-CR-ALI-040"])).toBe("CAA-CR-ACT-026");
    expect(nextCode("SAN", [])).toBe("CAA-CR-SAN-001");
  });
  it("nouveau mot en fin de catégorie", () => {
    expect(nextSortOrder([1, 2, 7])).toBe(8);
    expect(nextSortOrder([])).toBe(1);
  });
  it("contraste identique à la base", () => {
    expect(contrastOnWhite("#C1502E")).toBeGreaterThan(3);
    expect(contrastOnWhite("#FFD966")).toBeLessThan(3);
  });
  it("fichier image refusé ou accepté", () => {
    expect(imageFileProblem({ type: "image/svg+xml", size: 10 })).not.toBeNull();
    expect(imageFileProblem({ type: "image/png", size: 600 * 1024 })).not.toBeNull();
    expect(imageFileProblem({ type: "image/webp", size: 1000 })).toBeNull();
  });
  it("signature réelle de l'image", () => {
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    expect(hasImageSignature("image/png", png)).toBe(true);
    expect(hasImageSignature("image/webp", png)).toBe(false);
    expect(hasImageSignature("image/png", new TextEncoder().encode("<svg></svg>"))).toBe(false);
  });
  it("empreinte SHA-256", async () => {
    expect(await sha256Hex(new TextEncoder().encode("abc"))).toBe("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
  });
  it("position stable selon le niveau", () => {
    const cat = [
      { code: "A", level: 0, sort_order: 1, active: true },
      { code: "B", level: 1, sort_order: 2, active: true },
      { code: "C", level: 2, sort_order: 3, active: false },
    ];
    expect(levelOrderProblem({ code: "N", level: 0, sort_order: 4 }, cat)).toMatch(/Intermédiaire au minimum/);
    expect(levelOrderProblem({ code: "N", level: 1, sort_order: 4 }, cat)).toBeNull();
    expect(levelOrderProblem({ code: "A", level: 2, sort_order: 1 }, cat)).toMatch(/Intermédiaire au maximum/);
  });
  it("état de l'image", () => {
    expect(imageState({ image_sha256: "a", image_asset: "x" })).toBe("uploaded");
    expect(imageState({ image_sha256: null, image_asset: "x" })).toBe("demo");
    expect(imageState({ image_sha256: null, image_asset: null })).toBe("missing");
  });
});

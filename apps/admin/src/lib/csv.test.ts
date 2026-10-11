import { describe, expect, it } from "vitest";
import { toCsv } from "./csv";

describe("export CSV", () => {
  it("sépare par point-virgule et échappe guillemets et retours", () => {
    expect(toCsv(["a", "b"], [["x;y", 'dit "oui"'], [1, null]])).toBe('a;b\r\n"x;y";"dit ""oui"""\r\n1;');
  });
  it("neutralise les formules (injection CSV)", () => {
    expect(toCsv(["n"], [["=HYPERLINK(\"http://x\")"], ["+33"], ["-1"], ["@SUM(A1)"]]))
      .toBe("n\r\n\"'=HYPERLINK(\"\"http://x\"\")\"\r\n'+33\r\n'-1\r\n'@SUM(A1)");
  });
  it("préfixe aussi un nombre négatif (aucun montant négatif dans les exports)", () => {
    expect(toCsv(["n"], [[-5]])).toBe("n\r\n'-5");
  });
});

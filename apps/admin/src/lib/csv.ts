/**
 * Export CSV (séparateur « ; », lisible par Excel en français).
 * Une cellule commençant par = + - @ serait exécutée comme formule par un
 * tableur (injection CSV) : on la préfixe d'une apostrophe.
 */
export function toCsv(header: string[], rows: (string | number | null | undefined)[][]): string {
  const cell = (v: string | number | null | undefined): string => {
    let s = v === null || v === undefined ? "" : String(v);
    if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
    return /[";\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [header, ...rows].map((r) => r.map(cell).join(";")).join("\r\n");
}

export function downloadCsv(filename: string, csv: string): void {
  // BOM : accents corrects à l'ouverture dans Excel.
  const blob = new Blob(["﻿", csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

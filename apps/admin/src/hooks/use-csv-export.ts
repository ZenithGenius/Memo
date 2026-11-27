import { useState } from "react";
import { useToast } from "@/app/toast";
import { downloadCsv, toCsv } from "@/lib/csv";
import { report, userMessage } from "@/lib/errors";
import { toDateInput } from "@/lib/format";

/** Une exportation : où lire les lignes et comment les mettre en colonnes. */
export interface CsvExport<Row> {
  /** Préfixe du fichier : « memo-abonnements » donne memo-abonnements-2026-11-27.csv. */
  filename: string;
  headers: string[];
  fetch: () => Promise<Row[]>;
  toCells: (row: Row) => (string | number)[];
}

/** Contrôleur d'export CSV : état d'attente, téléchargement, message en cas d'échec. */
export function useCsvExport<Row>(spec: CsvExport<Row>) {
  const toast = useToast();
  const [exporting, setExporting] = useState(false);

  const run = async () => {
    setExporting(true);
    try {
      const rows = await spec.fetch();
      downloadCsv(`${spec.filename}-${toDateInput(new Date())}.csv`, toCsv(spec.headers, rows.map(spec.toCells)));
    } catch (e) {
      report(`export ${spec.filename}`, e);
      toast(userMessage(e, "L'export n'a pas pu être généré."), "error");
    } finally {
      setExporting(false);
    }
  };

  return { exporting, run };
}

import type { ReactNode } from "react";
import { cn } from "./cn";

export interface Column<T> {
  key: string;
  header: string;
  cell: (row: T) => ReactNode;
  /** Titre de la carte sur petit écran. */
  primary?: boolean;
  /** Masquée sur petit écran (ex. chevron). */
  desktopOnly?: boolean;
  align?: "left" | "right";
}

interface Props<T> {
  rows: T[];
  columns: Column<T>[];
  rowKey: (row: T) => string;
  onRowClick?: (row: T) => void;
  rowLabel?: (row: T) => string;
}

/** Tableau sur grand écran, cartes empilées et libellées sous 768 px. */
export function DataTable<T>({ rows, columns, rowKey, onRowClick, rowLabel }: Props<T>) {
  const clickable = onRowClick !== undefined;
  const open = (row: T) => onRowClick?.(row);
  return (
    <>
      <div className="hidden overflow-x-auto md:block">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr>
              {columns.map((c) => (
                <th
                  key={c.key}
                  scope="col"
                  className={cn(
                    "border-b border-line bg-muted-surface px-4 py-2.5 text-[0.7rem] font-semibold tracking-[0.12em] whitespace-nowrap text-fg-muted uppercase",
                    c.align === "right" ? "text-right" : "text-left",
                  )}
                >
                  {c.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr
                key={rowKey(row)}
                onClick={clickable ? () => { open(row); } : undefined}
                onKeyDown={clickable ? (e) => { if (e.key === "Enter") open(row); } : undefined}
                tabIndex={clickable ? 0 : undefined}
                aria-label={rowLabel?.(row)}
                className={cn("border-b border-line-subtle last:border-0 hover:bg-muted-surface", clickable && "cursor-pointer")}
              >
                {columns.map((c) => (
                  <td key={c.key} className={cn("px-4 py-3 align-middle", c.align === "right" && "text-right")}>
                    {c.cell(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <ul className="divide-y divide-line-subtle md:hidden">
        {rows.map((row) => {
          const content = (
            <div className="grid gap-2 px-4 py-3.5 text-sm">
              {columns.filter((c) => !c.desktopOnly).map((c) =>
                c.primary ? (
                  <div key={c.key}>{c.cell(row)}</div>
                ) : (
                  <div key={c.key} className="flex items-center justify-between gap-4">
                    <span className="shrink-0 text-[0.68rem] font-semibold tracking-widest text-fg-muted uppercase">{c.header}</span>
                    <span className="text-right">{c.cell(row)}</span>
                  </div>
                ),
              )}
            </div>
          );
          return (
            <li key={rowKey(row)}>
              {clickable ? (
                <button type="button" className="w-full text-left hover:bg-muted-surface" onClick={() => { open(row); }} aria-label={rowLabel?.(row)}>
                  {content}
                </button>
              ) : content}
            </li>
          );
        })}
      </ul>
    </>
  );
}

export function Pagination({ page, pageSize, total, onPage }: { page: number; pageSize: number; total: number; onPage: (p: number) => void }) {
  if (total <= pageSize) return null;
  const last = Math.max(0, Math.ceil(total / pageSize) - 1);
  return (
    <div className="flex items-center justify-between gap-3 border-t border-line-subtle px-4 py-3 text-sm text-fg-muted">
      <span>{page * pageSize + 1}–{Math.min(total, (page + 1) * pageSize)} sur {total}</span>
      <div className="flex gap-2">
        <button type="button" className="rounded-lg border border-line px-3 py-1.5 disabled:opacity-40" disabled={page === 0} onClick={() => { onPage(page - 1); }}>Précédent</button>
        <button type="button" className="rounded-lg border border-line px-3 py-1.5 disabled:opacity-40" disabled={page >= last} onClick={() => { onPage(page + 1); }}>Suivant</button>
      </div>
    </div>
  );
}

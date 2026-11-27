import { ChevronDown, RotateCcw, Search } from "lucide-react";
import { useId, type ReactNode } from "react";
import { cn } from "./cn";

// Composants de filtrage communs à toutes les listes :
//   <ListToolbar> recherche, critères et actions sur une ligne ;
//   <FilterSelect> un critère, avec son libellé et, si utile, ses effectifs ;
//   <ResultSummary> le nombre de résultats et « Réinitialiser » ;
//   <ViewTabs> le passage d'une vue à l'autre (jamais un filtre).

export interface FilterOption<V extends string> {
  value: V;
  label: string;
  count?: number;
}

const control =
  "h-10 rounded-lg border border-line bg-raised text-sm text-fg focus:border-accent focus:ring-4 focus:ring-ring focus:outline-none";

export function ListToolbar({ search, filters, actions }: { search?: ReactNode; filters?: ReactNode; actions?: ReactNode }) {
  return (
    <div className="mb-3 flex flex-wrap items-end gap-3">
      {search && <div className="w-full sm:w-80">{search}</div>}
      {filters}
      {actions && <div className="ml-auto flex flex-wrap items-end gap-2">{actions}</div>}
    </div>
  );
}

export function SearchInput({ value, onChange, placeholder, label }: { value: string; onChange: (v: string) => void; placeholder: string; label: string }) {
  const id = useId();
  return (
    <div className="grid gap-1">
      <label htmlFor={id} className="text-xs font-medium text-fg-muted">{label}</label>
      <div className="relative">
        <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-fg-muted" aria-hidden />
        <input
          id={id}
          type="search"
          value={value}
          onChange={(e) => { onChange(e.target.value); }}
          placeholder={placeholder}
          className={cn(control, "w-full pr-3 pl-9 placeholder:text-fg-muted")}
        />
      </div>
    </div>
  );
}

export function FilterSelect<V extends string>({ label, value, onChange, options, defaultValue }: {
  label: string;
  value: V;
  onChange: (v: V) => void;
  options: readonly FilterOption<V>[];
  /** Valeur « sans filtre » : un autre choix met le critère en évidence. */
  defaultValue?: V;
}) {
  const id = useId();
  const active = defaultValue !== undefined && value !== defaultValue;
  return (
    <div className="grid gap-1">
      <label htmlFor={id} className="text-xs font-medium text-fg-muted">{label}</label>
      <div className="relative">
        <select
          id={id}
          value={value}
          onChange={(e) => { onChange(e.target.value as V); }}
          className={cn(control, "min-w-40 appearance-none pr-9 pl-3", active && "border-accent-border bg-accent-muted font-medium text-accent-strong")}
        >
          {options.map((o) => (
            <option key={o.value} value={o.value}>
              {o.count === undefined ? o.label : `${o.label} (${o.count})`}
            </option>
          ))}
        </select>
        <ChevronDown className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-fg-muted" aria-hidden />
      </div>
    </div>
  );
}

export function ResultSummary({ shown, total, unit, active, onReset }: {
  shown: number;
  total?: number;
  /** Nom au singulier et au pluriel : ["pictogramme", "pictogrammes"]. */
  unit: readonly [string, string];
  active: number;
  onReset: () => void;
}) {
  const word = shown > 1 ? unit[1] : unit[0];
  return (
    <div className="mb-3 flex min-h-8 flex-wrap items-center gap-3 text-sm text-fg-muted" aria-live="polite">
      <span>
        <strong className="font-semibold text-fg">{shown}</strong> {word}
        {total !== undefined && total !== shown && <> sur {total}</>}
      </span>
      {active > 0 && (
        <button type="button" onClick={onReset} className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 font-medium text-accent-strong hover:bg-accent-muted">
          <RotateCcw className="size-3.5" aria-hidden />
          Réinitialiser {active > 1 ? `les ${active} filtres` : "le filtre"}
        </button>
      )}
    </div>
  );
}

export function ViewTabs<T extends string>({ value, onChange, options, label }: { value: T; onChange: (v: T) => void; options: readonly { value: T; label: string }[]; label: string }) {
  return (
    <div role="tablist" aria-label={label} className="mb-5 flex gap-6 border-b border-line">
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="tab"
          aria-selected={value === o.value}
          onClick={() => { onChange(o.value); }}
          className={cn(
            "-mb-px border-b-2 px-1 pb-2.5 text-sm font-medium transition-colors",
            value === o.value ? "border-accent text-fg" : "border-transparent text-fg-muted hover:text-fg",
          )}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

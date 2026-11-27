import { useCallback, useMemo } from "react";
import { useSearchParams } from "react-router";

/** Un critère de filtre : sa valeur par défaut et, pour un choix fermé, les valeurs admises. */
export interface FilterSpec<V extends string = string> {
  default: V;
  values?: readonly V[];
}

export type FilterSpecs = Record<string, FilterSpec>;

/** Critère libre (recherche) : vide par défaut. */
export const text = (): FilterSpec => ({ default: "" });

/** Critère à choix fermé : la valeur par défaut et les valeurs admises. */
export const choice = <V extends string>(defaultValue: V, values: readonly V[]): FilterSpec<V> => ({ default: defaultValue, values });

export type FilterValues<S extends FilterSpecs> = { [K in keyof S]: S[K]["default"] };

/** Lit les filtres d'une adresse ; une valeur absente ou non admise reprend sa valeur par défaut. */
export function readFilters<S extends FilterSpecs>(specs: S, params: URLSearchParams): FilterValues<S> {
  const out: Record<string, string> = {};
  for (const [key, spec] of Object.entries(specs)) {
    const raw = params.get(key);
    out[key] = raw !== null && (!spec.values || spec.values.includes(raw)) ? raw : spec.default;
  }
  return out as FilterValues<S>;
}

/** Applique un changement : les valeurs par défaut sortent de l'adresse, la page revient à la première. */
export function writeFilters<S extends FilterSpecs>(specs: S, params: URLSearchParams, patch: Partial<FilterValues<S>>): URLSearchParams {
  const next = new URLSearchParams(params);
  for (const [key, value] of Object.entries(patch) as [string, string | undefined][]) {
    const spec = specs[key];
    if (!spec || value === undefined) continue;
    if (value === spec.default || value === "") next.delete(key);
    else next.set(key, value);
  }
  next.delete("page");
  return next;
}

/** Nombre de critères qui s'écartent de leur valeur par défaut. */
export function activeCount<S extends FilterSpecs>(specs: S, values: FilterValues<S>): number {
  return Object.keys(specs).filter((k) => values[k] !== specs[k]?.default).length;
}

/**
 * Contrôleur des filtres d'une liste : l'état vit dans l'adresse de la page,
 * qui se recharge, se partage et suit les boutons précédent et suivant.
 */
export function useListFilters<S extends FilterSpecs>(specs: S) {
  const [params, setParams] = useSearchParams();
  const values = useMemo(() => readFilters(specs, params), [specs, params]);
  const page = Math.max(0, Number.parseInt(params.get("page") ?? "0", 10) || 0);

  const set = useCallback(
    (patch: Partial<FilterValues<S>>) => { setParams((prev) => writeFilters(specs, prev, patch), { replace: true }); },
    [specs, setParams],
  );
  const setPage = useCallback(
    (p: number) => {
      setParams((prev) => {
        const next = new URLSearchParams(prev);
        if (p > 0) next.set("page", String(p));
        else next.delete("page");
        return next;
      });
    },
    [setParams],
  );
  const reset = useCallback(() => {
    setParams((prev) => {
      const next = new URLSearchParams(prev);
      for (const key of Object.keys(specs)) next.delete(key);
      next.delete("page");
      return next;
    }, { replace: true });
  }, [specs, setParams]);

  return { values, set, page, setPage, reset, active: activeCount(specs, values) };
}

import type { ReactNode } from "react";
import { EmptyState, ErrorPanel, Skeleton } from "./feedback";

/** Ce qu'une liste doit savoir d'une requête, quelle que soit sa source. */
export interface ListQuery<D> {
  data: D | undefined;
  isPending: boolean;
  isError: boolean;
  refetch: () => unknown;
}

/**
 * Les quatre états d'une liste, toujours dans le même ordre et avec les mêmes
 * composants : chargement, erreur (Réessayer), aucun résultat, résultats.
 */
export function ListBody<D>({ query, isEmpty, empty, children }: {
  query: ListQuery<D>;
  isEmpty: (data: D) => boolean;
  empty: { icon: ReactNode; title: string; text?: string | undefined };
  children: (data: D) => ReactNode;
}) {
  if (query.isPending) return <Skeleton rows={8} />;
  if (query.isError || query.data === undefined) return <ErrorPanel onRetry={() => void query.refetch()} />;
  if (isEmpty(query.data)) return <EmptyState icon={empty.icon} title={empty.title} text={empty.text} />;
  return <>{children(query.data)}</>;
}

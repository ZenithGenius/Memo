// Modèle de l'écran Contenu : critères de filtre, filtrage et effectifs des
// pictogrammes. Fonctions pures, testées dans model.test.ts.
import type { FilterOption } from "@/components/ui/filters";
import { choice, text, type FilterValues } from "@/hooks/use-list-filters";
import { TIERS, imageState, type ImageState } from "@/lib/content";
import type { CategoryRow, PictogramRow, Tier } from "./api";

export type ImageFilter = "all" | ImageState;
export type TierFilter = "all" | Tier;

export const IMAGE_LABELS: Record<ImageState, string> = {
  uploaded: "Envoyées",
  demo: "Dans l'application seulement",
  missing: "Sans image",
};

export const CONTENT_FILTERS = {
  q: text(),
  // Codes de catégorie libres (on peut en créer) : pas de liste fermée.
  categorie: { default: "all" },
  image: choice<ImageFilter>("all", ["all", "uploaded", "demo", "missing"]),
  offre: choice<TierFilter>("all", ["all", "free", "premium"]),
};

export type ContentFilters = FilterValues<typeof CONTENT_FILTERS>;

/** Recherche sans accents ni majuscules. */
export const fold = (s: string) => s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

const matchesText = (p: PictogramRow, q: string) => !q || fold(`${p.labels.fr.label} ${p.labels.en.label} ${p.code}`).includes(q);

/** Pictogrammes qui répondent à tous les critères. */
export function filterPictograms(rows: PictogramRow[], f: ContentFilters): PictogramRow[] {
  const q = fold(f.q.trim());
  return rows.filter((p) =>
    (f.categorie === "all" || p.category_code === f.categorie)
    && (f.image === "all" || imageState(p) === f.image)
    && (f.offre === "all" || p.tier === f.offre)
    && matchesText(p, q));
}

function countBy<K extends string>(rows: PictogramRow[], key: (p: PictogramRow) => K): Map<K, number> {
  const m = new Map<K, number>();
  for (const p of rows) m.set(key(p), (m.get(key(p)) ?? 0) + 1);
  return m;
}

/**
 * Choix de chaque critère avec leurs effectifs. Chaque effectif tient compte
 * des autres critères (pas du sien) : il dit combien de lignes ce choix
 * afficherait.
 */
export function contentFacets(rows: PictogramRow[], categories: CategoryRow[], f: ContentFilters) {
  const without = (k: keyof ContentFilters) => filterPictograms(rows, { ...f, [k]: CONTENT_FILTERS[k].default });
  const byCat = countBy(without("categorie"), (p) => p.category_code);
  const byImage = countBy(without("image"), imageState);
  const byTier = countBy(without("offre"), (p) => p.tier);
  const total = (m: Map<string, number>) => [...m.values()].reduce((a, b) => a + b, 0);

  const categorie: FilterOption<string>[] = [
    { value: "all", label: "Toutes les catégories", count: total(byCat) },
    ...categories.map((c) => ({ value: c.code, label: c.labels.fr, count: byCat.get(c.code) ?? 0 })),
  ];
  const image: FilterOption<ImageFilter>[] = [
    { value: "all", label: "Toutes les images", count: total(byImage) },
    ...(["uploaded", "demo", "missing"] as const).map((v) => ({ value: v, label: IMAGE_LABELS[v], count: byImage.get(v) ?? 0 })),
  ];
  const offre: FilterOption<TierFilter>[] = [
    { value: "all", label: "Toutes les offres", count: total(byTier) },
    ...(["free", "premium"] as const).map((v) => ({ value: v, label: TIERS[v], count: byTier.get(v) ?? 0 })),
  ];
  return { categorie, image, offre };
}

/** Nombre de pictogrammes et de pictogrammes sans image, par catégorie. */
export function categoryCounts(rows: PictogramRow[], code: string) {
  const inCat = rows.filter((p) => p.category_code === code);
  return { total: inCat.length, missing: inCat.filter((p) => imageState(p) === "missing").length };
}

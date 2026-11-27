// Vues de l'écran Contenu : affichage seul, à partir des contrôleurs.
import { FolderPlus, Images, Pencil, Send } from "lucide-react";
import { Badge, Chip } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { DataTable } from "@/components/ui/data-table";
import { EmptyState } from "@/components/ui/feedback";
import { FilterSelect, ListToolbar, ResultSummary, SearchInput } from "@/components/ui/filters";
import { Field, Input } from "@/components/ui/form";
import { AUDIENCES, LEVELS, TIERS } from "@/lib/content";
import { dateTimeFr } from "@/lib/format";
import type { CategoryRow, PictogramRow, ReleaseRow } from "./api";
import type { ContentPageController, PictogramActions, PublishingController } from "./controllers";
import { categoryCounts } from "./model";
import { PictogramImage } from "./PictogramImage";

export function PublishCard({ releases, writable, p }: { releases: ReleaseRow[]; writable: boolean; p: PublishingController }) {
  const latest = releases[0];
  return (
    <Card className="mb-6">
      <div className="flex flex-wrap items-end gap-4 p-5">
        <div className="min-w-60 flex-1">
          <div className="flex items-center gap-2">
            <Send className="size-4.5 text-accent" aria-hidden />
            <h2 className="text-base">Publication</h2>
            <Chip>{latest ? `Version ${latest.version}` : "Jamais publié"}</Chip>
          </div>
          <p className="mt-1.5 text-sm text-fg-muted">
            {latest
              ? `Dernière publication le ${dateTimeFr(latest.published_at)} : ${latest.pictogram_count} pictogrammes.`
              : "Aucune version n'a encore été publiée."}
            {" "}Une modification n'arrive dans l'application qu'après publication.
          </p>
        </div>
        {writable && (
          <>
            <Field label="Note de version (facultative)" htmlFor="pub-notes" className="w-full sm:w-80">
              <Input id="pub-notes" maxLength={500} value={p.notes} placeholder="Ex. : 12 pictogrammes de santé" onChange={(e) => { p.setNotes(e.target.value); }} />
            </Field>
            <Button icon={<Send className="size-4" />} loading={p.publishing} onClick={() => void p.run()}>Publier</Button>
          </>
        )}
      </div>
    </Card>
  );
}

export function PictogramFilters({ c }: { c: ContentPageController }) {
  const { filters, facets } = c;
  return (
    <>
      <ListToolbar
        search={<SearchInput label="Rechercher" placeholder="Mot ou code" value={filters.values.q} onChange={(q) => { filters.set({ q }); }} />}
        filters={
          <>
            <FilterSelect label="Catégorie" value={filters.values.categorie} defaultValue="all" options={facets.categorie} onChange={(categorie) => { filters.set({ categorie }); }} />
            <FilterSelect label="Image" value={filters.values.image} defaultValue="all" options={facets.image} onChange={(image) => { filters.set({ image }); }} />
            <FilterSelect label="Offre" value={filters.values.offre} defaultValue="all" options={facets.offre} onChange={(offre) => { filters.set({ offre }); }} />
          </>
        }
      />
      <ResultSummary shown={c.rows.length} total={c.pictograms.length} unit={["pictogramme", "pictogrammes"]} active={filters.active} onReset={filters.reset} />
    </>
  );
}

export function PictogramsTable({ rows, categories, published, writable, actions, onEdit }: {
  rows: PictogramRow[];
  categories: CategoryRow[];
  published: Set<string>;
  writable: boolean;
  actions: PictogramActions;
  onEdit: (p: PictogramRow) => void;
}) {
  if (rows.length === 0) {
    return <EmptyState icon={<Images className="size-5" />} title="Aucun pictogramme" text="Aucun pictogramme ne correspond à ces filtres." />;
  }
  const categoryName = (code: string) => categories.find((c) => c.code === code)?.labels.fr ?? code;
  return (
    <DataTable
      rows={rows}
      rowKey={(p) => p.code}
      columns={[
        { key: "image", header: "Image", cell: (p) => <PictogramImage sha256={p.image_sha256} asset={p.image_asset} /> },
        { key: "word", header: "Mot", primary: true, cell: (p) => (
          <div className="min-w-0">
            <div className="font-semibold text-fg">{p.labels.fr.label}</div>
            <div className="text-xs text-fg-muted">{p.labels.en.label} · {p.code}</div>
          </div>
        ) },
        { key: "category", header: "Catégorie", desktopOnly: true, cell: (p) => categoryName(p.category_code) },
        { key: "level", header: "Niveau", desktopOnly: true, cell: (p) => LEVELS[p.level] },
        { key: "audience", header: "Public", desktopOnly: true, cell: (p) => AUDIENCES[p.audience] },
        { key: "tier", header: "Offre", cell: (p) => <Badge tone={p.tier === "free" ? "success" : "neutral"}>{TIERS[p.tier]}</Badge> },
        { key: "status", header: "Statut", cell: (p) => (
          !published.has(p.code) ? <Badge tone="info">Brouillon</Badge> : p.active ? <Badge tone="success">Publié</Badge> : <Badge tone="neutral">Retiré</Badge>
        ) },
        { key: "actions", header: "", align: "right", cell: (p) => writable && (
          <div className="flex flex-wrap justify-end gap-2">
            <Button size="sm" variant="secondary" icon={<Pencil className="size-3.5" />} onClick={() => { onEdit(p); }}>Modifier</Button>
            {published.has(p.code)
              ? <Button size="sm" variant={p.active ? "soft-danger" : "soft-accent"} onClick={() => void actions.toggleActive(p)}>{p.active ? "Retirer" : "Remettre"}</Button>
              : <Button size="sm" variant="soft-danger" onClick={() => void actions.deleteDraft(p)}>Supprimer</Button>}
          </div>
        ) },
      ]}
    />
  );
}

export function CategoriesCard({ categories, pictograms, writable, onEdit }: {
  categories: CategoryRow[];
  pictograms: PictogramRow[];
  writable: boolean;
  onEdit: (c: CategoryRow) => void;
}) {
  return (
    <Card className="mt-6">
      <CardHeader title="Catégories" icon={<FolderPlus className="size-4.5" />} />
      <DataTable
        rows={categories}
        rowKey={(c) => c.code}
        rowLabel={(c) => `Modifier ${c.labels.fr}`}
        onRowClick={writable ? onEdit : undefined}
        columns={[
          { key: "name", header: "Catégorie", primary: true, cell: (c) => (
            <div className="flex items-center gap-3">
              <span className="size-5 shrink-0 rounded-md border border-line" style={{ backgroundColor: c.color }} aria-hidden />
              <div className="min-w-0">
                <div className="font-semibold text-fg">{c.labels.fr}</div>
                <div className="text-xs text-fg-muted">{c.labels.en} · {c.code}</div>
              </div>
            </div>
          ) },
          { key: "order", header: "Place", align: "right", cell: (c) => c.sort_order },
          { key: "count", header: "Pictogrammes", align: "right", cell: (c) => categoryCounts(pictograms, c.code).total },
          { key: "missing", header: "Sans image", align: "right", cell: (c) => {
            const n = categoryCounts(pictograms, c.code).missing;
            return n ? <Badge tone="warning">{n}</Badge> : <span className="text-fg-muted">0</span>;
          } },
        ]}
      />
    </Card>
  );
}

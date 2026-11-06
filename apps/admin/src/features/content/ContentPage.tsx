import { FolderPlus, Images, Pencil, Plus, Send } from "lucide-react";
import { useMemo, useState } from "react";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { Badge, Chip } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { DataTable } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { SearchInput, Tabs } from "@/components/ui/filters";
import { Field, Input } from "@/components/ui/form";
import { useConfirm } from "@/components/ui/overlay";
import { PageHeader } from "@/components/ui/page";
import { AUDIENCES, LEVELS, imageState, nextSortOrder, type ImageState } from "@/lib/content";
import { report, userMessage } from "@/lib/errors";
import { dateTimeFr } from "@/lib/format";
import { canWrite } from "@/lib/roles";
import {
  type CategoryRow, type PictogramRow, useCategories, useDeleteDraft, usePictograms, usePublish, useReleases, useSetPictogramActive,
} from "./api";
import { CategoryDrawer, type CategoryDrawerState } from "./CategoryDrawer";
import { PictogramDrawer, type PictogramDrawerState } from "./PictogramDrawer";
import { PictogramImage } from "./PictogramImage";

type ImageFilter = "all" | ImageState;

const IMAGE_TABS: { value: ImageFilter; label: string }[] = [
  { value: "all", label: "Toutes" },
  { value: "missing", label: "Sans image" },
  { value: "demo", label: "Démonstration" },
  { value: "uploaded", label: "Envoyées" },
];

/** Normalise pour une recherche sans accents ni majuscules. */
const fold = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

export default function ContentPage() {
  const { role } = useSession();
  const writable = canWrite(role);
  const categories = useCategories();
  const pictograms = usePictograms();
  const releases = useReleases();
  const [category, setCategory] = useState("all");
  const [image, setImage] = useState<ImageFilter>("all");
  const [query, setQuery] = useState("");
  const [pictoDrawer, setPictoDrawer] = useState<PictogramDrawerState>(null);
  const [catDrawer, setCatDrawer] = useState<CategoryDrawerState>(null);

  const rows = useMemo(() => {
    const q = fold(query.trim());
    return (pictograms.data ?? []).filter((p) =>
      (category === "all" || p.category_code === category)
      && (image === "all" || imageState(p) === image)
      && (!q || fold(`${p.labels.fr.label} ${p.labels.en.label} ${p.code}`).includes(q)));
  }, [pictograms.data, category, image, query]);

  const loading = categories.isPending || pictograms.isPending || releases.isPending;
  const failed = categories.isError || pictograms.isError || releases.isError;

  return (
    <>
      <PageHeader
        title="Contenu"
        description="Catégories et pictogrammes servis aux abonnés : mots en français et en anglais, images, niveaux. Une modification n'arrive dans l'application qu'après publication."
        actions={writable ? (
          <Button icon={<Plus className="size-4" />} disabled={!categories.data?.length} onClick={() => { setPictoDrawer({ mode: "create" }); }}>
            Nouveau pictogramme
          </Button>
        ) : undefined}
      />
      {loading ? (
        <Card><Skeleton rows={8} /></Card>
      ) : failed ? (
        <Card><ErrorPanel onRetry={() => { void categories.refetch(); void pictograms.refetch(); void releases.refetch(); }} /></Card>
      ) : (
        <>
          <PublishCard writable={writable} releases={releases.data.releases} />
          <Card>
            <div className="grid gap-3 border-b border-line p-4">
              <div className="flex flex-wrap items-center gap-3">
                <SearchInput value={query} onChange={setQuery} placeholder="Mot ou code" label="Rechercher un pictogramme" />
                <Tabs label="Image" value={image} onChange={setImage} options={IMAGE_TABS} />
              </div>
              <Tabs
                label="Catégorie"
                value={category}
                onChange={setCategory}
                options={[{ value: "all", label: "Toutes" }, ...categories.data.map((c) => ({ value: c.code, label: c.labels.fr }))]}
              />
            </div>
            {rows.length === 0 ? (
              <EmptyState icon={<Images className="size-5" />} title="Aucun pictogramme" text="Aucun pictogramme ne correspond à ces filtres." />
            ) : (
              <PictogramsTable
                rows={rows}
                categories={categories.data}
                published={releases.data.published}
                writable={writable}
                onEdit={(p) => { setPictoDrawer({ mode: "edit", pictogram: p }); }}
              />
            )}
            <p className="border-t border-line px-4 py-3 text-xs text-fg-muted">
              {rows.length} pictogramme{rows.length > 1 ? "s" : ""} affiché{rows.length > 1 ? "s" : ""} sur {pictograms.data.length}.
            </p>
          </Card>
          <CategoriesCard
            categories={categories.data}
            pictograms={pictograms.data}
            writable={writable}
            onEdit={(c) => { setCatDrawer({ mode: "edit", category: c }); }}
            onCreate={() => { setCatDrawer({ mode: "create", nextOrder: nextSortOrder(categories.data.map((c) => c.sort_order)) }); }}
          />
          <PictogramDrawer
            state={pictoDrawer}
            categories={categories.data}
            pictograms={pictograms.data}
            onClose={() => { setPictoDrawer(null); }}
          />
          <CategoryDrawer state={catDrawer} onClose={() => { setCatDrawer(null); }} />
        </>
      )}
    </>
  );
}

function PublishCard({ writable, releases }: { writable: boolean; releases: { version: number; pictogram_count: number; notes: string | null; published_at: string }[] }) {
  const toast = useToast();
  const confirm = useConfirm();
  const publish = usePublish();
  const [notes, setNotes] = useState("");
  const latest = releases[0];

  const onPublish = async () => {
    const ok = await confirm({
      title: "Publier le contenu ?",
      text: "Les abonnés recevront cette version à leur prochaine synchronisation. Une publication ne peut pas être annulée, seulement remplacée par une nouvelle.",
      confirmLabel: "Publier",
    });
    if (!ok) return;
    try {
      const version = await publish.mutateAsync(notes);
      setNotes("");
      toast(`Version ${version} publiée.`);
    } catch (e) {
      report("publication", e);
      toast(userMessage(e, "La publication a échoué."), "error");
    }
  };

  return (
    <Card>
      <CardHeader
        title="Publication"
        icon={<Send className="size-4.5" />}
        aside={latest ? <Chip>Version {latest.version}</Chip> : <Chip>Jamais publié</Chip>}
      />
      <div className="grid gap-4 p-5">
        <p className="text-sm text-fg-muted">
          {latest
            ? `Dernière publication le ${dateTimeFr(latest.published_at)} : ${latest.pictogram_count} pictogrammes${latest.notes ? `, « ${latest.notes} »` : ""}.`
            : "Aucune version n'a encore été publiée."}
        </p>
        {writable && (
          <div className="flex flex-wrap items-end gap-3">
            <Field label="Note de version (facultative)" htmlFor="pub-notes" className="min-w-0 flex-1">
              <Input id="pub-notes" maxLength={500} value={notes} placeholder="Ex. : 12 pictogrammes de santé" onChange={(e) => { setNotes(e.target.value); }} />
            </Field>
            <Button icon={<Send className="size-4" />} loading={publish.isPending} onClick={() => void onPublish()}>Publier</Button>
          </div>
        )}
      </div>
    </Card>
  );
}

function PictogramsTable({ rows, categories, published, writable, onEdit }: {
  rows: PictogramRow[]; categories: CategoryRow[]; published: Set<string>; writable: boolean; onEdit: (p: PictogramRow) => void;
}) {
  const toast = useToast();
  const confirm = useConfirm();
  const setActive = useSetPictogramActive();
  const remove = useDeleteDraft();
  const categoryName = (code: string) => categories.find((c) => c.code === code)?.labels.fr ?? code;

  const toggle = async (p: PictogramRow) => {
    if (p.active && !(await confirm({
      title: `Retirer « ${p.labels.fr.label} » ?`,
      text: "Il disparaîtra chez les abonnés à la prochaine publication. Il reste dans le catalogue et peut être remis.",
      confirmLabel: "Retirer",
    }))) return;
    try {
      await setActive.mutateAsync({ code: p.code, active: !p.active });
      toast(p.active ? "Pictogramme retiré." : "Pictogramme remis.");
    } catch (e) {
      report("pictogramme", e);
      toast(userMessage(e, "Le pictogramme n'a pas pu être modifié."), "error");
    }
  };

  const del = async (p: PictogramRow) => {
    if (!(await confirm({
      title: `Supprimer le brouillon « ${p.labels.fr.label} » ?`,
      text: "Il n'a jamais été publié : il est supprimé définitivement, et son code ne sera plus utilisé.",
      confirmLabel: "Supprimer",
    }))) return;
    try {
      await remove.mutateAsync(p.code);
      toast("Brouillon supprimé.");
    } catch (e) {
      report("pictogramme", e);
      toast(userMessage(e, "Le brouillon n'a pas pu être supprimé."), "error");
    }
  };

  return (
    <DataTable
      rows={rows}
      rowKey={(p) => p.code}
      columns={[
        { key: "image", header: "Image", cell: (p) => <PictogramImage sha256={p.image_sha256} asset={p.image_asset} /> },
        {
          key: "word",
          header: "Mot",
          primary: true,
          cell: (p) => (
            <div className="min-w-0">
              <div className="font-semibold text-fg">{p.labels.fr.label}</div>
              <div className="text-xs text-fg-muted">{p.labels.en.label} · {p.code}</div>
            </div>
          ),
        },
        { key: "category", header: "Catégorie", desktopOnly: true, cell: (p) => categoryName(p.category_code) },
        { key: "level", header: "Niveau", desktopOnly: true, cell: (p) => LEVELS[p.level] },
        { key: "audience", header: "Public", desktopOnly: true, cell: (p) => AUDIENCES[p.audience] },
        {
          key: "status",
          header: "Statut",
          cell: (p) => !published.has(p.code)
            ? <Badge tone="info">Brouillon</Badge>
            : p.active ? <Badge tone="success">Publié</Badge> : <Badge tone="neutral">Retiré</Badge>,
        },
        {
          key: "actions",
          header: "",
          align: "right",
          cell: (p) => writable && (
            <div className="flex flex-wrap justify-end gap-2">
              <Button size="sm" variant="secondary" icon={<Pencil className="size-3.5" />} onClick={() => { onEdit(p); }}>Modifier</Button>
              {published.has(p.code)
                ? <Button size="sm" variant={p.active ? "soft-danger" : "soft-accent"} onClick={() => void toggle(p)}>{p.active ? "Retirer" : "Remettre"}</Button>
                : <Button size="sm" variant="soft-danger" onClick={() => void del(p)}>Supprimer</Button>}
            </div>
          ),
        },
      ]}
    />
  );
}

function CategoriesCard({ categories, pictograms, writable, onEdit, onCreate }: {
  categories: CategoryRow[]; pictograms: PictogramRow[]; writable: boolean; onEdit: (c: CategoryRow) => void; onCreate: () => void;
}) {
  return (
    <Card>
      <CardHeader
        title="Catégories"
        icon={<FolderPlus className="size-4.5" />}
        aside={writable ? <Button size="sm" variant="secondary" icon={<Plus className="size-3.5" />} onClick={onCreate}>Nouvelle catégorie</Button> : undefined}
      />
      <DataTable
        rows={categories}
        rowKey={(c) => c.code}
        rowLabel={(c) => `Modifier ${c.labels.fr}`}
        onRowClick={writable ? onEdit : undefined}
        columns={[
          {
            key: "name",
            header: "Catégorie",
            primary: true,
            cell: (c) => (
              <div className="flex items-center gap-3">
                <span className="size-5 shrink-0 rounded-md border border-line" style={{ backgroundColor: c.color }} aria-hidden />
                <div className="min-w-0">
                  <div className="font-semibold text-fg">{c.labels.fr}</div>
                  <div className="text-xs text-fg-muted">{c.labels.en} · {c.code}</div>
                </div>
              </div>
            ),
          },
          { key: "order", header: "Place", cell: (c) => c.sort_order },
          {
            key: "count",
            header: "Pictogrammes",
            cell: (c) => {
              const inCat = pictograms.filter((p) => p.category_code === c.code);
              const missing = inCat.filter((p) => imageState(p) === "missing").length;
              return `${inCat.length}${missing ? ` (${missing} sans image)` : ""}`;
            },
          },
        ]}
      />
    </Card>
  );
}

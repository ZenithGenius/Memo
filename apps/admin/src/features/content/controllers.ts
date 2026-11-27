// Contrôleurs de l'écran Contenu : données et filtres, publication, actions
// sur un pictogramme. Les vues n'appellent ni le serveur ni la confirmation.
import { useMemo, useState } from "react";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { useConfirm } from "@/components/ui/overlay";
import { useListFilters } from "@/hooks/use-list-filters";
import { nextSortOrder } from "@/lib/content";
import { report, userMessage } from "@/lib/errors";
import { canWrite } from "@/lib/roles";
import { useCategories, useDeleteDraft, usePictograms, usePublish, useReleases, useSetPictogramActive, type PictogramRow } from "./api";
import type { CategoryDrawerState } from "./CategoryDrawer";
import { CONTENT_FILTERS, contentFacets, filterPictograms } from "./model";
import type { PictogramDrawerState } from "./PictogramDrawer";

export function useContentPage() {
  const { role } = useSession();
  const categories = useCategories();
  const pictograms = usePictograms();
  const releases = useReleases();
  const filters = useListFilters(CONTENT_FILTERS);
  const [pictoDrawer, setPictoDrawer] = useState<PictogramDrawerState>(null);
  const [catDrawer, setCatDrawer] = useState<CategoryDrawerState>(null);

  const all = useMemo(() => pictograms.data ?? [], [pictograms.data]);
  const cats = useMemo(() => categories.data ?? [], [categories.data]);
  const rows = useMemo(() => filterPictograms(all, filters.values), [all, filters.values]);
  const facets = useMemo(() => contentFacets(all, cats, filters.values), [all, cats, filters.values]);

  return {
    loading: categories.isPending || pictograms.isPending || releases.isPending,
    failed: categories.isError || pictograms.isError || releases.isError,
    retry: () => { void categories.refetch(); void pictograms.refetch(); void releases.refetch(); },
    writable: canWrite(role),
    categories: cats,
    pictograms: all,
    releases: releases.data,
    filters,
    facets,
    rows,
    pictoDrawer,
    catDrawer,
    newPictogram: () => { setPictoDrawer({ mode: "create" }); },
    editPictogram: (p: PictogramRow) => { setPictoDrawer({ mode: "edit", pictogram: p }); },
    closePictogram: () => { setPictoDrawer(null); },
    newCategory: () => { setCatDrawer({ mode: "create", nextOrder: nextSortOrder(cats.map((c) => c.sort_order)) }); },
    editCategory: (c: (typeof cats)[number]) => { setCatDrawer({ mode: "edit", category: c }); },
    closeCategory: () => { setCatDrawer(null); },
  };
}

export function usePublishing() {
  const toast = useToast();
  const confirm = useConfirm();
  const publish = usePublish();
  const [notes, setNotes] = useState("");

  const run = async () => {
    const ok = await confirm({
      title: "Publier le contenu ?",
      text: "Les téléphones recevront cette version à leur prochaine synchronisation (mots gratuits pour tous, le reste pour les abonnés). Une publication ne peut pas être annulée, seulement remplacée par une nouvelle.",
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

  return { notes, setNotes, publishing: publish.isPending, run };
}

export function usePictogramActions() {
  const toast = useToast();
  const confirm = useConfirm();
  const setActive = useSetPictogramActive();
  const remove = useDeleteDraft();

  /** Retire un pictogramme publié (après confirmation) ou le remet. */
  const toggleActive = async (p: PictogramRow) => {
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

  /** Supprime un brouillon jamais publié. */
  const deleteDraft = async (p: PictogramRow) => {
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

  return { toggleActive, deleteDraft };
}

export type ContentPageController = ReturnType<typeof useContentPage>;
export type PublishingController = ReturnType<typeof usePublishing>;
export type PictogramActions = ReturnType<typeof usePictogramActions>;

import { FolderPlus, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { PageHeader } from "@/components/ui/page";
import { CategoryDrawer } from "./CategoryDrawer";
import { useContentPage, usePictogramActions, usePublishing } from "./controllers";
import { PictogramDrawer } from "./PictogramDrawer";
import { CategoriesCard, PictogramFilters, PictogramsTable, PublishCard } from "./views";

export default function ContentPage() {
  const c = useContentPage();
  const publishing = usePublishing();
  const actions = usePictogramActions();

  return (
    <>
      <PageHeader
        title="Contenu"
        description="Catégories et pictogrammes, gratuits ou réservés aux abonnés : mots en français et en anglais, images, niveaux."
        actions={c.writable ? (
          <>
            <Button variant="secondary" icon={<FolderPlus className="size-4" />} disabled={c.loading} onClick={c.newCategory}>Nouvelle catégorie</Button>
            <Button icon={<Plus className="size-4" />} disabled={c.loading || c.categories.length === 0} onClick={c.newPictogram}>Nouveau pictogramme</Button>
          </>
        ) : undefined}
      />
      {c.loading ? (
        <Card><Skeleton rows={8} /></Card>
      ) : c.failed || !c.releases ? (
        <Card><ErrorPanel onRetry={c.retry} /></Card>
      ) : (
        <>
          <PublishCard releases={c.releases.releases} writable={c.writable} p={publishing} />
          <PictogramFilters c={c} />
          <Card>
            <PictogramsTable rows={c.rows} categories={c.categories} published={c.releases.published} writable={c.writable} actions={actions} onEdit={c.editPictogram} />
          </Card>
          <CategoriesCard categories={c.categories} pictograms={c.pictograms} writable={c.writable} onEdit={c.editCategory} />
          <PictogramDrawer state={c.pictoDrawer} categories={c.categories} pictograms={c.pictograms} onClose={c.closePictogram} />
          <CategoryDrawer state={c.catDrawer} onClose={c.closeCategory} />
        </>
      )}
    </>
  );
}

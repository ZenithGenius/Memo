import { ImageOff, Smartphone } from "lucide-react";
import { cn } from "@/components/ui/cn";
import { useImage } from "./api";

/**
 * Vignette d'un pictogramme, avec un état toujours explicite :
 * image envoyée (lien signé du stockage), image livrée seulement dans
 * l'application (pas encore envoyée, donc invisible ici), ou aucune image.
 */
export function PictogramImage({ sha256, asset, size = "sm" }: { sha256: string | null; asset: string | null; size?: "sm" | "lg" }) {
  const image = useImage(sha256);
  const small = size === "sm";
  const box = cn(
    "grid shrink-0 place-items-center content-center gap-0.5 overflow-hidden rounded-lg border text-center leading-tight",
    small ? "size-14 px-1 text-[0.62rem]" : "size-32 px-2 text-xs",
  );
  const icon = small ? "size-4" : "size-6";

  if (sha256 && image.data) return <img src={image.data} alt="" className={cn(box, "border-line bg-raised object-contain p-0.5")} />;
  if (sha256 && image.isError) {
    return (
      <div className={cn(box, "border-danger-border bg-danger-muted text-danger")} title="L'image envoyée n'a pas pu être chargée">
        <ImageOff className={icon} aria-hidden />Introuvable
      </div>
    );
  }
  if (sha256) return <div className={cn(box, "animate-pulse border-line bg-subtle")} aria-label="Chargement de l'image" />;
  if (asset) {
    return (
      <div className={cn(box, "border-line bg-muted-surface text-fg-muted")} title="Image livrée dans l'application, pas encore envoyée au serveur : envoyez-la depuis Modifier pour la voir ici.">
        <Smartphone className={icon} aria-hidden />Dans l'app
      </div>
    );
  }
  return (
    <div className={cn(box, "border-dashed border-warning-border bg-warning-muted text-warning")} title="Aucune image : ce mot ne s'affiche pas au niveau débutant.">
      <ImageOff className={icon} aria-hidden />Sans image
    </div>
  );
}

import { ImageOff } from "lucide-react";
import { cn } from "@/components/ui/cn";
import { useImage } from "./api";

/**
 * Vignette d'un pictogramme : image envoyée (lien signé du stockage), image de
 * démonstration livrée dans l'application (non consultable ici), ou aucune.
 */
export function PictogramImage({ sha256, asset, size = "sm" }: { sha256: string | null; asset: string | null; size?: "sm" | "lg" }) {
  const image = useImage(sha256);
  const box = cn(
    "grid shrink-0 place-items-center overflow-hidden rounded-lg border border-line bg-raised text-center text-fg-muted",
    size === "sm" ? "size-12 text-[0.6rem]" : "size-28 text-xs",
  );
  if (sha256 && image.data) return <img src={image.data} alt="" className={cn(box, "object-contain")} />;
  if (sha256) return <div className={box} aria-label="Chargement de l'image" />;
  if (asset) return <div className={cn(box, "px-1 leading-tight")}>Démo dans l'app</div>;
  return (
    <div className={box} aria-label="Sans image">
      <ImageOff className={size === "sm" ? "size-4" : "size-6"} />
    </div>
  );
}

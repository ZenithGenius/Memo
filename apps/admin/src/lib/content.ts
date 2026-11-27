/** Règles du catalogue, les mêmes que celles de la base et de l'application. */

export const LEVELS = ["Débutant", "Intermédiaire", "Avancé"] as const;

export const TIERS = { free: "Gratuit", premium: "Abonnés" } as const;

export const AUDIENCES = { all: "Tous", child: "Enfant", teen: "Adolescent", adult: "Adulte" } as const;

/** Icônes connues de l'application pour une catégorie. */
export const CATEGORY_ICONS = {
  bubble: "Bulle", hand: "Main", plate: "Assiette", face: "Visage",
  cross: "Croix", person: "Personne", house: "Maison", drop: "Goutte",
} as const;

export const MAX_IMAGE_BYTES = 512 * 1024;

/** Code permanent suivant dans une catégorie : CAA-CR-ACT-026 après 025. */
export function nextCode(category: string, codes: string[]): string {
  const prefix = `CAA-CR-${category}-`;
  const max = codes
    .filter((c) => c.startsWith(prefix))
    .reduce((m, c) => Math.max(m, Number(c.slice(prefix.length)) || 0), 0);
  return `${prefix}${String(max + 1).padStart(3, "0")}`;
}

/** Nouveau mot ajouté à la fin de sa catégorie (position stable). */
export function nextSortOrder(orders: number[]): number {
  return orders.reduce((m, o) => Math.max(m, o), 0) + 1;
}

/** Contraste WCAG d'une couleur #RRGGBB sur blanc ; la base exige 3:1. */
export function contrastOnWhite(hex: string): number {
  const rgb = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const [r, g, b] = rgb.map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4)) as [number, number, number];
  return 1.05 / (0.2126 * r + 0.7152 * g + 0.0722 * b + 0.05);
}

/** Erreur lisible pour un fichier refusé, `null` s'il est accepté. */
export function imageFileProblem(file: { type: string; size: number }): string | null {
  if (file.type !== "image/png" && file.type !== "image/webp") return "Image PNG ou WebP uniquement.";
  if (file.size > MAX_IMAGE_BYTES) return "Image trop lourde : 512 Ko au maximum.";
  return null;
}

export type ImageState = "uploaded" | "demo" | "missing";

/** Image envoyée depuis le back-office, image de démonstration de l'application, ou aucune. */
export function imageState(p: { image_sha256: string | null; image_asset: string | null }): ImageState {
  if (p.image_sha256) return "uploaded";
  if (p.image_asset) return "demo";
  return "missing";
}

/** Signature réelle d'un PNG ou d'un WebP : le type annoncé ne suffit pas. */
export function hasImageSignature(mime: string, b: Uint8Array): boolean {
  const at = (offset: number, sig: number[]) => sig.every((v, i) => b[offset + i] === v);
  if (mime === "image/png") return at(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (mime === "image/webp") return at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50]);
  return false;
}

/** Empreinte SHA-256 en hexadécimal : le nom de l'image dans le stockage. */
export async function sha256Hex(bytes: Uint8Array<ArrayBuffer>): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  return Array.from(digest, (x) => x.toString(16).padStart(2, "0")).join("");
}

/**
 * Position stable : dans une catégorie, un mot ne passe jamais devant un mot
 * de niveau inférieur (monter de niveau ajoute des mots à la fin, sans
 * déplacer ceux que l'enfant connaît déjà). Même règle que la publication.
 */
export function levelOrderProblem(
  word: { code: string; level: number; sort_order: number },
  siblings: { code: string; level: number; sort_order: number; active: boolean }[],
): string | null {
  const others = siblings.filter((s) => s.active && s.code !== word.code);
  const higherBefore = others.filter((s) => s.sort_order < word.sort_order && s.level > word.level);
  if (higherBefore.length) {
    const min = Math.max(...higherBefore.map((s) => s.level));
    return `À cette place, des mots de niveau ${LEVELS[min]} le précèdent : niveau ${LEVELS[min]} au minimum, ou une place plus haute.`;
  }
  const lowerAfter = others.filter((s) => s.sort_order > word.sort_order && s.level < word.level);
  if (lowerAfter.length) {
    const max = Math.min(...lowerAfter.map((s) => s.level));
    return `Des mots de niveau ${LEVELS[max]} suivent cette place : niveau ${LEVELS[max]} au maximum, ou une place plus basse.`;
  }
  return null;
}

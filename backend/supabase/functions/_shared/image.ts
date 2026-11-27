import { json } from "./http.ts";

export const SHA256 = /^[0-9a-f]{64}$/;

/** Signature réelle d'un PNG ou d'un WebP (les octets, pas le type annoncé). */
function hasImageSignature(mime: string, b: Uint8Array): boolean {
  const at = (offset: number, sig: number[]) => sig.every((v, i) => b[offset + i] === v);
  if (mime === "image/png") return at(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (mime === "image/webp") {
    return at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50]);
  }
  return false;
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  return Array.from(digest, (x) => x.toString(16).padStart(2, "0")).join("");
}

/**
 * Réponse d'une image publiée. Le stockage objet ne garantit pas le contenu :
 * l'empreinte et le format sont vérifiés avant de servir (un objet altéré ne
 * part jamais). Le contenu ne change jamais pour une empreinte, d'où le cache
 * long ; [scope] dit qui peut le garder (« private » pour un abonné).
 */
export async function imageResponse(
  sha256: string,
  image: { mime: string; bytes: Uint8Array },
  scope: "private" | "public",
  logName: string,
): Promise<Response> {
  if (!hasImageSignature(image.mime, image.bytes) || (await sha256Hex(image.bytes)) !== sha256) {
    console.error(`${logName} : intégrité`, sha256);
    return json(500, { error: "internal_error" });
  }
  return new Response(image.bytes, {
    status: 200,
    headers: {
      "Content-Type": image.mime,
      "Content-Length": String(image.bytes.byteLength),
      "Cache-Control": `${scope}, max-age=31536000, immutable`,
      "X-Content-Type-Options": "nosniff",
    },
  });
}

import { json } from "../_shared/http.ts";
import type { ContentRepository } from "../_shared/ports.ts";
import { refuseUnlessSubscriber, type SubscriberDeps } from "../_shared/subscriber.ts";

export interface ImageHandlerDeps extends SubscriberDeps {
  publishedImage: ContentRepository["publishedImage"];
}

const SHA256 = /^[0-9a-f]{64}$/;

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
 * Image d'un pictogramme envoyée depuis le back-office (issue #28), aux mêmes
 * conditions que le paquet. GET ?fingerprint=…&sha256=<empreinte du paquet>.
 * Seule une image référencée par la dernière publication est servie ; son
 * contenu ne change jamais pour une empreinte donnée, d'où le cache long.
 */
export function createImageHandler(deps: ImageHandlerDeps): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method !== "GET") return json(405, { error: "method_not_allowed" });
    try {
      const url = new URL(req.url);
      const refused = await refuseUnlessSubscriber(deps, req, url);
      if (refused) return refused;

      const sha256 = url.searchParams.get("sha256") ?? "";
      if (!SHA256.test(sha256)) return json(400, { error: "invalid_sha256" });

      const image = await deps.publishedImage(sha256);
      if (!image) return json(404, { error: "not_found" });
      // Le stockage objet ne garantit pas le contenu : on vérifie l'empreinte
      // et le format avant de servir (un objet altéré ne part jamais).
      if (
        !hasImageSignature(image.mime, image.bytes) || (await sha256Hex(image.bytes)) !== sha256
      ) {
        console.error("premium-image : intégrité", sha256);
        return json(500, { error: "internal_error" });
      }
      return new Response(image.bytes, {
        status: 200,
        headers: {
          "Content-Type": image.mime,
          "Content-Length": String(image.bytes.byteLength),
          "Cache-Control": "private, max-age=31536000, immutable",
          "X-Content-Type-Options": "nosniff",
        },
      });
    } catch (e) {
      console.error("premium-image", e);
      return json(500, { error: "internal_error" });
    }
  };
}

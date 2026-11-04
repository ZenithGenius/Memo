import { json } from "../_shared/http.ts";
import type { ContentRepository } from "../_shared/ports.ts";
import { refuseUnlessSubscriber, type SubscriberDeps } from "../_shared/subscriber.ts";

export interface ImageHandlerDeps extends SubscriberDeps {
  publishedImage: ContentRepository["publishedImage"];
}

const SHA256 = /^[0-9a-f]{64}$/;

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

import { json } from "../_shared/http.ts";
import { imageResponse, SHA256 } from "../_shared/image.ts";
import type { ContentRepository } from "../_shared/ports.ts";

export type FreeHandlerDeps = Pick<ContentRepository, "freePack" | "freeImage">;

/**
 * Contenu gratuit (#41), sans compte : l'application met à jour son paquet
 * gratuit embarqué. GET ?have=<version> : le paquet des mots gratuits de la
 * dernière publication, 204 si l'appareil l'a déjà, 404 si elle n'en contient
 * aucun. GET ?sha256=<empreinte> : l'image d'un mot gratuit publié.
 */
export function createFreeHandler(deps: FreeHandlerDeps): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method !== "GET") return json(405, { error: "method_not_allowed" });
    try {
      const url = new URL(req.url);
      const sha256 = url.searchParams.get("sha256");
      if (sha256 !== null) {
        if (!SHA256.test(sha256)) return json(400, { error: "invalid_sha256" });
        const image = await deps.freeImage(sha256);
        if (!image) return json(404, { error: "not_found" });
        return await imageResponse(sha256, image, "public", "free-pack");
      }

      const pack = await deps.freePack();
      if (!pack) return json(404, { error: "no_content" });
      const have = Number(url.searchParams.get("have"));
      if (Number.isInteger(have) && have >= pack.version) {
        return new Response(null, { status: 204 });
      }
      return new Response(JSON.stringify(pack), {
        status: 200,
        headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
      });
    } catch (e) {
      console.error("free-pack", e);
      return json(500, { error: "internal_error" });
    }
  };
}

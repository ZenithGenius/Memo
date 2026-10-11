import { json } from "../_shared/http.ts";
import type { ContentRepository, PremiumPack } from "../_shared/ports.ts";
import { refuseUnlessSubscriber, type SubscriberDeps } from "../_shared/subscriber.ts";

export type { PremiumPack };

export interface PremiumHandlerDeps extends SubscriberDeps {
  /** Dernière publication du back-office (issue #28). */
  loadPack: ContentRepository["latestPack"];
}

/**
 * Livre le contenu payant publié depuis le back-office, aux seuls abonnés
 * (voir refuseUnlessSubscriber). GET ?fingerprint=…&have=<version> ; 204 si
 * l'appareil a déjà cette version. Les images envoyées depuis le back-office
 * sont servies à part par premium-image.
 */
export function createPremiumHandler(
  deps: PremiumHandlerDeps,
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method !== "GET") return json(405, { error: "method_not_allowed" });
    try {
      const url = new URL(req.url);
      const refused = await refuseUnlessSubscriber(deps, req, url);
      if (refused) return refused;

      const pack = await deps.loadPack();
      if (!pack) return json(404, { error: "no_content" });
      const have = Number(url.searchParams.get("have"));
      if (Number.isInteger(have) && have >= pack.version) {
        return new Response(null, { status: 204 });
      }
      return new Response(JSON.stringify(pack), {
        status: 200,
        headers: { "Content-Type": "application/json", "Cache-Control": "private, no-store" },
      });
    } catch (e) {
      console.error("premium-pack", e);
      return json(500, { error: "internal_error" });
    }
  };
}

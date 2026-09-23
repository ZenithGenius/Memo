import { json } from "../_shared/http.ts";
import type { LicenseRepository } from "../_shared/ports.ts";

/** Paquet de contenu payant, au format du paquet embarqué. */
export interface PremiumPack {
  version: number;
  [key: string]: unknown;
}

export interface PremiumHandlerDeps {
  /** Retourne l'identifiant de l'appelant d'après son JWT, ou `null`. */
  authenticate(req: Request): Promise<string | null>;
  repo: Pick<LicenseRepository, "findDevice" | "activeSubscription">;
  loadPack(): Promise<PremiumPack>;
  now(): Date;
}

const FINGERPRINT = /^[A-Za-z0-9+/=_-]{16,128}$/;

/**
 * Livre le contenu payant (ADR-008, couche 1) : seulement à un abonné actif,
 * depuis un appareil déjà enregistré par issue-license et non révoqué.
 * GET ?fingerprint=…&have=<version> ; 204 si l'appareil a déjà cette version.
 * ponytail: le contrôle d'accès est fait ici, le paquet n'est pas chiffré ; à
 * chiffrer le jour où il sera servi depuis un stockage public (CDN).
 */
export function createPremiumHandler(
  deps: PremiumHandlerDeps,
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method !== "GET") return json(405, { error: "method_not_allowed" });
    try {
      const userId = await deps.authenticate(req);
      if (!userId) return json(401, { error: "unauthorized" });

      const url = new URL(req.url);
      const fingerprint = url.searchParams.get("fingerprint") ?? "";
      if (!FINGERPRINT.test(fingerprint)) return json(400, { error: "invalid_fingerprint" });

      const device = await deps.repo.findDevice(userId, fingerprint);
      if (!device) return json(403, { error: "device_unknown" });
      if (device.revoked) return json(403, { error: "device_revoked" });

      if (!(await deps.repo.activeSubscription(userId, deps.now()))) {
        return json(402, { error: "no_active_subscription" });
      }

      const pack = await deps.loadPack();
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

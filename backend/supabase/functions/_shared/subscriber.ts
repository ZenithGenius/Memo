import { json } from "./http.ts";
import type { LicenseRepository } from "./ports.ts";

export interface SubscriberDeps {
  /** Retourne l'identifiant de l'appelant d'après son JWT, ou `null`. */
  authenticate(req: Request): Promise<string | null>;
  repo: Pick<LicenseRepository, "findDevice" | "activeSubscription">;
  now(): Date;
}

const FINGERPRINT = /^[A-Za-z0-9+/=_-]{16,128}$/;

/**
 * Contenu payant (ADR-008, couche 1) : un abonné actif, depuis un appareil
 * déjà enregistré par issue-license et non révoqué. Renvoie la réponse de
 * refus, ou `null` si l'accès est accordé. `?fingerprint=` dans l'URL.
 */
export async function refuseUnlessSubscriber(
  deps: SubscriberDeps,
  req: Request,
  url: URL,
): Promise<Response | null> {
  const userId = await deps.authenticate(req);
  if (!userId) return json(401, { error: "unauthorized" });

  const fingerprint = url.searchParams.get("fingerprint") ?? "";
  if (!FINGERPRINT.test(fingerprint)) return json(400, { error: "invalid_fingerprint" });

  const device = await deps.repo.findDevice(userId, fingerprint);
  if (!device) return json(403, { error: "device_unknown" });
  if (device.revoked) return json(403, { error: "device_revoked" });

  if (!(await deps.repo.activeSubscription(userId, deps.now()))) {
    return json(402, { error: "no_active_subscription" });
  }
  return null;
}

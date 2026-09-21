import { buildClaims, DAY_MS, encodeToken, tokenValidUntil } from "../_shared/license.ts";
import { DeviceLimitError, type LicenseRepository } from "../_shared/ports.ts";
import type { TokenSigner } from "../_shared/signer.ts";
import { json } from "../_shared/http.ts";
import { parseIssueRequest } from "../_shared/validation.ts";

export interface HandlerDeps {
  config: { keyId: string; shortTokenDays: number; maxTokenDays: number };
  /** Retourne l'identifiant de l'appelant d'après son JWT, ou `null`. */
  authenticate(req: Request): Promise<string | null>;
  repo: LicenseRepository;
  signer: TokenSigner;
  now(): Date;
}

/**
 * Enregistre l'appareil (limite appliquée par la base), vérifie l'abonnement,
 * signe le jeton. L'identité vient toujours du JWT, jamais du corps.
 */
export function createHandler(deps: HandlerDeps): (req: Request) => Promise<Response> {
  const { config, repo, signer } = deps;

  return async (req) => {
    if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

    try {
      const userId = await deps.authenticate(req);
      if (!userId) return json(401, { error: "unauthorized" });

      let body: unknown;
      try {
        body = await req.json();
      } catch {
        return json(400, { error: "invalid_json" });
      }
      const parsed = parseIssueRequest(body);
      if (!parsed.ok) return json(400, { error: parsed.error });
      const { fingerprint, platform, label } = parsed.value;

      const now = deps.now();

      const existing = await repo.findDevice(userId, fingerprint);
      if (existing?.revoked) return json(403, { error: "device_revoked" });

      let device = existing;
      if (!device) {
        try {
          device = {
            ...(await repo.registerDevice({ userId, fingerprint, platform, label })),
            revoked: false,
          };
        } catch (e) {
          if (e instanceof DeviceLimitError) return json(409, { error: "device_limit_reached" });
          throw e;
        }
      }

      const subscription = await repo.activeSubscription(userId, now);
      if (!subscription) return json(402, { error: "no_active_subscription" });

      const validUntil = tokenValidUntil(subscription, device, now, config.shortTokenDays);
      const token = await encodeToken(
        buildClaims({
          userId,
          planCode: subscription.planCode,
          fingerprint,
          keyId: signer.keyId,
          now,
          validUntil,
        }),
        signer,
      );

      await repo.recordIssuance({
        userId,
        deviceId: device.id,
        validUntil,
        tokenExpiresAt: new Date(now.getTime() + config.maxTokenDays * DAY_MS),
        keyId: signer.keyId,
        integrityLevel: device.integrityLevel,
      });
      await repo.touchDevice(device.id, now);

      return json(200, {
        token,
        server_time: now.toISOString(),
        valid_until: validUntil.toISOString(),
        plan: subscription.planCode,
      });
    } catch (e) {
      console.error("issue-license", e);
      return json(500, { error: "internal_error" });
    }
  };
}

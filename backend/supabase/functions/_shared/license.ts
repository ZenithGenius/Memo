// Règles métier pures de la licence (ADR-004, ADR-008). Aucune entrée-sortie.
import { toBase64Url } from "./encoding.ts";
import type { TokenSigner } from "./signer.ts";

export const DAY_MS = 86_400_000;

export interface Subscription {
  planCode: string;
  validUntil: Date;
}

export interface Device {
  id: string;
  integrityLevel: "unknown" | "strong" | "basic" | "failed";
  /** `null` tant que la provenance n'a pas été établie côté serveur. */
  installedFromStore: boolean | null;
}

export interface LicenseClaims {
  sub: string;
  plan: string;
  iat: number;
  exp: number;
  dev: string;
  kid: string;
}

/**
 * Confiance faible : vérification d'intégrité échouée ou installation hors
 * boutique. Ces informations sont établies côté serveur, jamais lues dans la
 * requête du client.
 */
export function isLowTrust(device: Device): boolean {
  return device.integrityLevel === "failed" || device.installedFromStore === false;
}

/** Fin de validité du jeton : la période payée, raccourcie si la confiance est faible. */
export function tokenValidUntil(
  subscription: Subscription,
  device: Device,
  now: Date,
  shortTokenDays: number,
): Date {
  if (!isLowTrust(device)) return subscription.validUntil;
  const cap = new Date(now.getTime() + shortTokenDays * DAY_MS);
  return cap < subscription.validUntil ? cap : subscription.validUntil;
}

export function buildClaims(input: {
  userId: string;
  planCode: string;
  fingerprint: string;
  keyId: string;
  now: Date;
  validUntil: Date;
}): LicenseClaims {
  return {
    sub: input.userId,
    plan: input.planCode,
    iat: Math.floor(input.now.getTime() / 1000),
    exp: Math.floor(input.validUntil.getTime() / 1000),
    dev: input.fingerprint,
    kid: input.keyId,
  };
}

/** Format `base64url(charge).base64url(signature)`, signature sur la charge encodée. */
export async function encodeToken(
  claims: LicenseClaims,
  signer: TokenSigner,
): Promise<string> {
  const payload = toBase64Url(new TextEncoder().encode(JSON.stringify(claims)));
  const signature = await signer.sign(payload);
  return `${payload}.${toBase64Url(signature)}`;
}

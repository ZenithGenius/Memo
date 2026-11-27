import type { Device, Subscription } from "./license.ts";
import type { Platform } from "./validation.ts";

export class DeviceLimitError extends Error {}

/** Paquet de contenu payant, au format du paquet embarqué. */
export interface PremiumPack {
  version: number;
  [key: string]: unknown;
}

/** Contenu publié depuis le back-office (issue #28). */
export interface ContentRepository {
  /** Dernière publication, `null` si rien n'a encore été publié. */
  latestPack(): Promise<PremiumPack | null>;
  /** Image référencée par la dernière publication, `null` sinon. Les octets
   * viennent du stockage objet (ADR-012). */
  publishedImage(sha256: string): Promise<{ mime: string; bytes: Uint8Array } | null>;
  /** Dernière publication réduite aux mots gratuits (#41), `null` si elle
   * n'en contient aucun. */
  freePack(): Promise<PremiumPack | null>;
  /** Image d'un mot gratuit de la dernière publication, `null` sinon. */
  freeImage(sha256: string): Promise<{ mime: string; bytes: Uint8Array } | null>;
}

/** Accès aux données de licence. Isole Supabase du reste de la logique. */
export interface LicenseRepository {
  findDevice(userId: string, fingerprint: string): Promise<(Device & { revoked: boolean }) | null>;
  registerDevice(input: {
    userId: string;
    fingerprint: string;
    platform: Platform;
    label: string | null;
  }): Promise<Device>;
  activeSubscription(userId: string, now: Date): Promise<Subscription | null>;
  recordIssuance(input: {
    userId: string;
    deviceId: string;
    validUntil: Date;
    tokenExpiresAt: Date;
    keyId: string;
    integrityLevel: string;
  }): Promise<void>;
  touchDevice(deviceId: string, now: Date): Promise<void>;
  /** Jetons émis pour ce compte depuis `since` (limite de fréquence). */
  countIssuancesSince(userId: string, since: Date): Promise<number>;
}

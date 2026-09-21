import type { Device, Subscription } from "./license.ts";
import type { Platform } from "./validation.ts";

export class DeviceLimitError extends Error {}

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
}

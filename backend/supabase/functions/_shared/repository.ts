import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { Device } from "./license.ts";
import { DeviceLimitError, type LicenseRepository } from "./ports.ts";
import type { Platform } from "./validation.ts";

const DEVICE_COLUMNS = "id, revoked_at, integrity_level, installed_from_store";

// deno-lint-ignore no-explicit-any
function toDevice(row: any): Device {
  return {
    id: row.id,
    integrityLevel: row.integrity_level,
    installedFromStore: row.installed_from_store,
  };
}

export class SupabaseLicenseRepository implements LicenseRepository {
  private readonly db: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.db = createClient(url, serviceRoleKey);
  }

  async findDevice(userId: string, fingerprint: string) {
    const { data, error } = await this.db
      .from("devices")
      .select(DEVICE_COLUMNS)
      .eq("user_id", userId)
      .eq("fingerprint", fingerprint)
      .maybeSingle();
    if (error) throw error;
    return data ? { ...toDevice(data), revoked: data.revoked_at !== null } : null;
  }

  async registerDevice(input: {
    userId: string;
    fingerprint: string;
    platform: Platform;
    label: string | null;
  }) {
    const { data, error } = await this.db
      .from("devices")
      .insert({
        user_id: input.userId,
        fingerprint: input.fingerprint,
        platform: input.platform,
        label: input.label,
      })
      .select(DEVICE_COLUMNS)
      .single();
    if (error) {
      if (error.message.includes("device_limit_reached")) throw new DeviceLimitError();
      throw error;
    }
    return toDevice(data);
  }

  async activeSubscription(userId: string, now: Date) {
    const { data, error } = await this.db
      .from("subscriptions")
      .select("plan_code, valid_until")
      .eq("user_id", userId)
      .eq("status", "active")
      .gt("valid_until", now.toISOString())
      .order("valid_until", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return data ? { planCode: data.plan_code, validUntil: new Date(data.valid_until) } : null;
  }

  async recordIssuance(input: {
    userId: string;
    deviceId: string;
    validUntil: Date;
    tokenExpiresAt: Date;
    keyId: string;
    integrityLevel: string;
  }) {
    const { error } = await this.db.from("license_issuances").insert({
      user_id: input.userId,
      device_id: input.deviceId,
      valid_until: input.validUntil.toISOString(),
      token_expires_at: input.tokenExpiresAt.toISOString(),
      key_id: input.keyId,
      integrity_level: input.integrityLevel,
    });
    if (error) throw error;
  }

  async touchDevice(deviceId: string, now: Date) {
    const { error } = await this.db
      .from("devices")
      .update({ last_seen: now.toISOString() })
      .eq("id", deviceId);
    if (error) throw error;
  }
}

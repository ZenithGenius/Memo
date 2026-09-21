// Émet un jeton de licence signé (ADR-004, ADR-008).
//
// POST { fingerprint, platform, label? } avec le JWT de l'utilisateur.
// Enregistre l'appareil (limite appliquée par la base), vérifie l'abonnement,
// signe { sub, plan, iat, exp, dev, kid } en Ed25519 et renvoie aussi la date
// du serveur, qui sert d'ancre à l'horloge de confiance de l'application.
import { createClient } from "npm:@supabase/supabase-js@2";

const SHORT_TOKEN_DAYS = 7;
const DAY_MS = 86_400_000;

function b64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

function b64url(bytes: Uint8Array): string {
  return b64(bytes).replaceAll("+", "-").replaceAll("/", "_");
}

function fromB64(s: string): Uint8Array {
  return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

let cachedKey: CryptoKey | null = null;
async function signingKey(): Promise<CryptoKey> {
  if (cachedKey) return cachedKey;
  const pkcs8 = Deno.env.get("LICENSE_PRIVATE_KEY_PKCS8");
  if (!pkcs8) throw new Error("LICENSE_PRIVATE_KEY_PKCS8 manquant");
  cachedKey = await crypto.subtle.importKey(
    "pkcs8",
    fromB64(pkcs8),
    { name: "Ed25519" },
    false,
    ["sign"],
  );
  return cachedKey;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const keyId = Deno.env.get("LICENSE_KEY_ID") ?? "k1";

  // Identité : le JWT de l'appelant, jamais un identifiant fourni dans le corps.
  const authHeader = req.headers.get("Authorization") ?? "";
  const asUser = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await asUser.auth.getUser();
  if (userError || !userData.user) return json(401, { error: "unauthorized" });
  const userId = userData.user.id;

  let body: { fingerprint?: string; platform?: string; label?: string };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }
  const { fingerprint, platform, label } = body;
  if (
    typeof fingerprint !== "string" ||
    !/^[A-Za-z0-9+/=_-]{16,128}$/.test(fingerprint)
  ) return json(400, { error: "invalid_fingerprint" });
  if (platform !== "android" && platform !== "ios") {
    return json(400, { error: "invalid_platform" });
  }

  const db = createClient(url, serviceKey);
  const now = new Date();

  // Appareil : la base refuse au-delà de la limite (déclencheur).
  const { data: existing } = await db
    .from("devices")
    .select("id, revoked_at, integrity_level, installed_from_store")
    .eq("user_id", userId)
    .eq("fingerprint", fingerprint)
    .maybeSingle();

  if (existing?.revoked_at) return json(403, { error: "device_revoked" });

  let device = existing;
  if (!device) {
    const { data, error } = await db
      .from("devices")
      .insert({
        user_id: userId,
        fingerprint,
        platform,
        label: typeof label === "string" ? label.slice(0, 80) : null,
      })
      .select("id, revoked_at, integrity_level, installed_from_store")
      .single();
    if (error) {
      if (error.message.includes("device_limit_reached")) {
        return json(409, { error: "device_limit_reached" });
      }
      return json(500, { error: "device_registration_failed" });
    }
    device = data;
  }

  // Abonnement actif : le plus tardif encore valide.
  const { data: sub } = await db
    .from("subscriptions")
    .select("plan_code, valid_until")
    .eq("user_id", userId)
    .eq("status", "active")
    .gt("valid_until", now.toISOString())
    .order("valid_until", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!sub) return json(402, { error: "no_active_subscription" });

  // Jeton court quand le niveau d'intégrité, établi côté serveur, est défavorable
  // (installation hors boutique ou vérification échouée). Le corps de la requête
  // n'est jamais cru pour cela.
  const untrusted = device.integrity_level === "failed" ||
    device.installed_from_store === false;
  let validUntil = new Date(sub.valid_until);
  if (untrusted) {
    const cap = new Date(now.getTime() + SHORT_TOKEN_DAYS * DAY_MS);
    if (cap < validUntil) validUntil = cap;
  }

  const payload = b64url(
    new TextEncoder().encode(JSON.stringify({
      sub: userId,
      plan: sub.plan_code,
      iat: Math.floor(now.getTime() / 1000),
      exp: Math.floor(validUntil.getTime() / 1000),
      dev: fingerprint,
      kid: keyId,
    })),
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "Ed25519",
      await signingKey(),
      new TextEncoder().encode(payload),
    ),
  );

  await db.from("license_issuances").insert({
    user_id: userId,
    device_id: device.id,
    valid_until: validUntil.toISOString(),
    token_expires_at: new Date(now.getTime() + 45 * DAY_MS).toISOString(),
    key_id: keyId,
    integrity_level: device.integrity_level,
  });
  await db.from("devices").update({ last_seen: now.toISOString() }).eq(
    "id",
    device.id,
  );

  return json(200, {
    token: `${payload}.${b64url(signature)}`,
    server_time: now.toISOString(),
    valid_until: validUntil.toISOString(),
    plan: sub.plan_code,
  });
});

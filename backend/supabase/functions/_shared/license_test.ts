import assert from "node:assert/strict";
import { ConfigError, loadConfig } from "./config.ts";
import { buildClaims, DAY_MS, encodeToken, isLowTrust, tokenValidUntil } from "./license.ts";
import { Ed25519Signer } from "./signer.ts";
import { parseIssueRequest } from "./validation.ts";
import { fromBase64, toBase64 } from "./encoding.ts";

const now = new Date("2026-09-15T00:00:00Z");
const sub = { planCode: "essentiel", validUntil: new Date("2026-10-15T00:00:00Z") };
const trusted = { id: "d1", integrityLevel: "unknown" as const, installedFromStore: null };

const fullEnv = {
  SUPABASE_URL: "http://api.test",
  SUPABASE_ANON_KEY: "anon",
  SUPABASE_SERVICE_ROLE_KEY: "service",
  LICENSE_KEY_ID: "k1",
  LICENSE_PRIVATE_KEY_PKCS8: "cGs=",
};
const env = (o: Record<string, string>) => ({ get: (k: string) => o[k] });

Deno.test("config : variables manquantes listées, sans valeur par défaut secrète", () => {
  assert.throws(
    () => loadConfig(env({ SUPABASE_URL: "x" })),
    (e: Error) => e instanceof ConfigError && e.message.includes("LICENSE_PRIVATE_KEY_PKCS8"),
  );
});

Deno.test("config : valeurs par défaut de politique et surcharge", () => {
  const c = loadConfig(env(fullEnv));
  assert.equal(c.shortTokenDays, 7);
  assert.equal(c.maxTokenDays, 45);
  const o = loadConfig(env({ ...fullEnv, LICENSE_SHORT_TOKEN_DAYS: "3" }));
  assert.equal(o.shortTokenDays, 3);
});

Deno.test("config : durée invalide refusée", () => {
  for (const bad of ["0", "-1", "abc", "1.5"]) {
    assert.throws(() => loadConfig(env({ ...fullEnv, LICENSE_MAX_TOKEN_DAYS: bad })), ConfigError);
  }
});

Deno.test("jeton complet : fin de période payée quand la confiance est normale", () => {
  assert.deepEqual(tokenValidUntil(sub, trusted, now, 7), sub.validUntil);
});

Deno.test("confiance faible : jeton limité à la durée courte", () => {
  const offStore = { ...trusted, installedFromStore: false };
  assert.equal(isLowTrust(offStore), true);
  assert.equal(tokenValidUntil(sub, offStore, now, 7).getTime(), now.getTime() + 7 * DAY_MS);
  const failed = { ...trusted, integrityLevel: "failed" as const };
  assert.equal(isLowTrust(failed), true);
});

Deno.test("confiance faible : jamais au-delà de la période payée", () => {
  const short = { planCode: "essentiel", validUntil: new Date(now.getTime() + 2 * DAY_MS) };
  const offStore = { ...trusted, installedFromStore: false };
  assert.deepEqual(tokenValidUntil(short, offStore, now, 7), short.validUntil);
});

Deno.test("validation de la requête", () => {
  assert.equal(parseIssueRequest({ fingerprint: "x", platform: "android" }).ok, false);
  assert.equal(parseIssueRequest({ fingerprint: "a".repeat(20), platform: "web" }).ok, false);
  assert.equal(parseIssueRequest(null).ok, false);
  const ok = parseIssueRequest({
    fingerprint: "a".repeat(20),
    platform: "ios",
    label: "L".repeat(200),
  });
  assert.equal(ok.ok, true);
  if (ok.ok) assert.equal(ok.value.label?.length, 80);
});

Deno.test("jeton signé : la signature se vérifie avec la clé publique", async () => {
  const pair = await crypto.subtle.generateKey("Ed25519", true, [
    "sign",
    "verify",
  ]) as CryptoKeyPair;
  const pkcs8 = toBase64(new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey)));
  const signer = await Ed25519Signer.fromPkcs8("k1", pkcs8);
  const claims = buildClaims({
    userId: "u1",
    planCode: "essentiel",
    fingerprint: "a".repeat(20),
    keyId: signer.keyId,
    now,
    validUntil: sub.validUntil,
  });
  const token = await encodeToken(claims, signer);
  const [payload, sig] = token.split(".");
  const sigBytes = fromBase64(sig.replaceAll("-", "+").replaceAll("_", "/"));
  const valid = await crypto.subtle.verify(
    "Ed25519",
    pair.publicKey,
    sigBytes,
    new TextEncoder().encode(payload),
  );
  assert.equal(valid, true);
  const decoded = JSON.parse(atob(payload.replaceAll("-", "+").replaceAll("_", "/")));
  assert.deepEqual(decoded, claims);
});

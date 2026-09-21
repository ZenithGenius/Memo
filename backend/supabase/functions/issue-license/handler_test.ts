import assert from "node:assert/strict";
import { createHandler, type HandlerDeps } from "./handler.ts";
import { DeviceLimitError, type LicenseRepository } from "../_shared/ports.ts";
import type { Device, Subscription } from "../_shared/license.ts";
import type { TokenSigner } from "../_shared/signer.ts";

const NOW = new Date("2026-09-15T00:00:00Z");
const FP = "abcdefghijklmnop1234";

class FakeRepo implements LicenseRepository {
  devices = new Map<string, Device & { revoked: boolean }>();
  subscription: Subscription | null = {
    planCode: "essentiel",
    validUntil: new Date("2026-10-15T00:00:00Z"),
  };
  limitReached = false;
  issuances: { deviceId: string; validUntil: Date }[] = [];
  touched: string[] = [];

  findDevice(_u: string, fp: string) {
    return Promise.resolve(this.devices.get(fp) ?? null);
  }
  registerDevice(i: { fingerprint: string }) {
    if (this.limitReached) return Promise.reject(new DeviceLimitError());
    const d: Device = {
      id: `dev-${i.fingerprint}`,
      integrityLevel: "unknown",
      installedFromStore: null,
    };
    this.devices.set(i.fingerprint, { ...d, revoked: false });
    return Promise.resolve(d);
  }
  activeSubscription() {
    return Promise.resolve(this.subscription);
  }
  recordIssuance(i: { deviceId: string; validUntil: Date }) {
    this.issuances.push(i);
    return Promise.resolve();
  }
  touchDevice(id: string) {
    this.touched.push(id);
    return Promise.resolve();
  }
}

const signer: TokenSigner = {
  keyId: "k1",
  sign: () => Promise.resolve(new Uint8Array([1, 2, 3])),
};

function setup(overrides: Partial<HandlerDeps> = {}) {
  const repo = new FakeRepo();
  const handler = createHandler({
    config: { keyId: "k1", shortTokenDays: 7, maxTokenDays: 45 },
    authenticate: () => Promise.resolve("user-1"),
    repo,
    signer,
    now: () => NOW,
    ...overrides,
  });
  return { repo, handler };
}

const post = (body: unknown) =>
  new Request("http://x/issue-license", { method: "POST", body: JSON.stringify(body) });

Deno.test("méthode autre que POST : 405", async () => {
  const { handler } = setup();
  assert.equal((await handler(new Request("http://x", { method: "GET" }))).status, 405);
});

Deno.test("non authentifié : 401, sans toucher aux données", async () => {
  const { handler, repo } = setup({ authenticate: () => Promise.resolve(null) });
  assert.equal((await handler(post({ fingerprint: FP, platform: "android" }))).status, 401);
  assert.equal(repo.devices.size, 0);
});

Deno.test("corps invalide : 400", async () => {
  const { handler } = setup();
  assert.equal(
    (await handler(new Request("http://x", { method: "POST", body: "pas du json" }))).status,
    400,
  );
  const r = await handler(post({ fingerprint: "x", platform: "android" }));
  assert.equal(r.status, 400);
  assert.equal((await r.json()).error, "invalid_fingerprint");
});

Deno.test("sans abonnement : 402", async () => {
  const { handler, repo } = setup();
  repo.subscription = null;
  assert.equal((await handler(post({ fingerprint: FP, platform: "android" }))).status, 402);
});

Deno.test("abonné : 200, jeton, date serveur, journal et dernière activité", async () => {
  const { handler, repo } = setup();
  const r = await handler(post({ fingerprint: FP, platform: "android" }));
  assert.equal(r.status, 200);
  const body = await r.json();
  assert.equal(body.plan, "essentiel");
  assert.equal(body.server_time, NOW.toISOString());
  assert.equal(body.valid_until, "2026-10-15T00:00:00.000Z");
  assert.equal(body.token.split(".").length, 2);
  assert.equal(repo.issuances.length, 1);
  assert.deepEqual(repo.touched, [`dev-${FP}`]);
});

Deno.test("limite d'appareils atteinte : 409", async () => {
  const { handler, repo } = setup();
  repo.limitReached = true;
  assert.equal((await handler(post({ fingerprint: FP, platform: "android" }))).status, 409);
  assert.equal(repo.issuances.length, 0);
});

Deno.test("appareil révoqué : 403", async () => {
  const { handler, repo } = setup();
  repo.devices.set(FP, {
    id: "d",
    integrityLevel: "unknown",
    installedFromStore: null,
    revoked: true,
  });
  assert.equal((await handler(post({ fingerprint: FP, platform: "android" }))).status, 403);
});

Deno.test("hors boutique : jeton court", async () => {
  const { handler, repo } = setup();
  repo.devices.set(FP, {
    id: "d",
    integrityLevel: "unknown",
    installedFromStore: false,
    revoked: false,
  });
  const body = await (await handler(post({ fingerprint: FP, platform: "android" }))).json();
  assert.equal(body.valid_until, "2026-09-22T00:00:00.000Z");
});

Deno.test("le corps ne peut pas imposer l'identité ni la confiance", async () => {
  const { handler, repo } = setup();
  const r = await handler(post({
    fingerprint: FP,
    platform: "android",
    user_id: "autre",
    installed_from_store: true,
    integrity_level: "strong",
  }));
  assert.equal(r.status, 200);
  assert.equal(repo.devices.get(FP)?.integrityLevel, "unknown");
});

Deno.test("erreur inattendue : 500 sans fuite de détail", async () => {
  const { handler, repo } = setup();
  repo.activeSubscription = () => Promise.reject(new Error("secret interne"));
  const r = await handler(post({ fingerprint: FP, platform: "android" }));
  assert.equal(r.status, 500);
  assert.equal(JSON.stringify(await r.json()).includes("secret"), false);
});

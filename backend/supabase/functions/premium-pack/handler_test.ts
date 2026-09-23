import assert from "node:assert/strict";
import { createPremiumHandler, type PremiumHandlerDeps } from "./handler.ts";

const FP = "abcdefghijklmnop1234";

function setup(over: {
  user?: string | null;
  device?: { revoked: boolean } | null;
  subscribed?: boolean;
  fail?: boolean;
} = {}) {
  const deps: PremiumHandlerDeps = {
    authenticate: () => Promise.resolve(over.user === undefined ? "u1" : over.user),
    repo: {
      findDevice: () =>
        Promise.resolve(
          over.device === null ? null : {
            id: "d1",
            integrityLevel: "unknown",
            installedFromStore: null,
            revoked: over.device?.revoked ?? false,
          },
        ),
      activeSubscription: () =>
        over.fail ? Promise.reject(new Error("secret interne")) : Promise.resolve(
          over.subscribed === false
            ? null
            : { planCode: "essentiel", validUntil: new Date("2027-01-01") },
        ),
    },
    loadPack: () => Promise.resolve({ version: 3, pictograms: [] }),
    now: () => new Date("2026-09-23"),
  };
  return createPremiumHandler(deps);
}

const get = (query = `fingerprint=${FP}`) =>
  new Request(`http://x/premium-pack?${query}`, { method: "GET" });

Deno.test("abonné, appareil connu : 200 avec le paquet, jamais mis en cache", async () => {
  const r = await setup()(get());
  assert.equal(r.status, 200);
  assert.equal((await r.json()).version, 3);
  assert.equal(r.headers.get("Cache-Control"), "private, no-store");
});

Deno.test("version déjà présente : 204 sans contenu", async () => {
  assert.equal((await setup()(get(`fingerprint=${FP}&have=3`))).status, 204);
  assert.equal((await setup()(get(`fingerprint=${FP}&have=2`))).status, 200);
});

Deno.test("refus : méthode, identité, empreinte, appareil, abonnement", async () => {
  assert.equal((await setup()(new Request("http://x", { method: "POST" }))).status, 405);
  assert.equal((await setup({ user: null })(get())).status, 401);
  assert.equal((await setup()(get("fingerprint=x"))).status, 400);
  assert.equal((await setup({ device: null })(get())).status, 403);
  assert.equal((await setup({ device: { revoked: true } })(get())).status, 403);
  assert.equal((await setup({ subscribed: false })(get())).status, 402);
});

Deno.test("erreur inattendue : 500 sans fuite de détail", async () => {
  const r = await setup({ fail: true })(get());
  assert.equal(r.status, 500);
  assert.equal(JSON.stringify(await r.json()).includes("secret"), false);
});

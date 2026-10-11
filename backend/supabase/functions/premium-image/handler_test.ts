import assert from "node:assert/strict";
import { createImageHandler, type ImageHandlerDeps } from "./handler.ts";

const FP = "abcdefghijklmnop1234";
const SHA = "a".repeat(64);
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function setup(over: {
  user?: string | null;
  device?: { revoked: boolean } | null;
  subscribed?: boolean;
  published?: boolean;
  fail?: boolean;
} = {}) {
  const asked: string[] = [];
  const deps: ImageHandlerDeps = {
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
        Promise.resolve(
          over.subscribed === false
            ? null
            : { planCode: "essentiel", validUntil: new Date("2027-01-01") },
        ),
    },
    publishedImage: (sha) => {
      asked.push(sha);
      if (over.fail) return Promise.reject(new Error("secret interne"));
      return Promise.resolve(over.published === false ? null : { mime: "image/png", bytes: PNG });
    },
    now: () => new Date("2026-10-11"),
  };
  return { handler: createImageHandler(deps), asked };
}

const get = (query = `fingerprint=${FP}&sha256=${SHA}`) =>
  new Request(`http://x/premium-image?${query}`, { method: "GET" });

Deno.test("abonné, image publiée : octets, type, cache long et privé", async () => {
  const { handler } = setup();
  const r = await handler(get());
  assert.equal(r.status, 200);
  assert.deepEqual(new Uint8Array(await r.arrayBuffer()), PNG);
  assert.equal(r.headers.get("Content-Type"), "image/png");
  assert.equal(r.headers.get("Content-Length"), "8");
  assert.equal(r.headers.get("Cache-Control"), "private, max-age=31536000, immutable");
  assert.equal(r.headers.get("X-Content-Type-Options"), "nosniff");
});

Deno.test("image absente de la dernière publication : 404", async () => {
  assert.equal((await setup({ published: false }).handler(get())).status, 404);
});

Deno.test("empreinte invalide : 400, sans interroger la base", async () => {
  for (const sha of ["", "A".repeat(64), "a".repeat(63), "../../etc/passwd"]) {
    const { handler, asked } = setup();
    const r = await handler(get(`fingerprint=${FP}&sha256=${encodeURIComponent(sha)}`));
    assert.equal(r.status, 400, sha);
    assert.equal(asked.length, 0);
  }
});

Deno.test("mêmes refus que le paquet : méthode, identité, appareil, abonnement", async () => {
  assert.equal((await setup().handler(new Request("http://x", { method: "POST" }))).status, 405);
  assert.equal((await setup({ user: null }).handler(get())).status, 401);
  assert.equal((await setup().handler(get(`fingerprint=x&sha256=${SHA}`))).status, 400);
  assert.equal((await setup({ device: null }).handler(get())).status, 403);
  assert.equal((await setup({ device: { revoked: true } }).handler(get())).status, 403);
  const { handler, asked } = setup({ subscribed: false });
  assert.equal((await handler(get())).status, 402);
  assert.equal(asked.length, 0, "aucune image lue sans abonnement");
});

Deno.test("erreur inattendue : 500 sans fuite de détail", async () => {
  const r = await setup({ fail: true }).handler(get());
  assert.equal(r.status, 500);
  assert.equal(JSON.stringify(await r.json()).includes("secret"), false);
});

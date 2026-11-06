import assert from "node:assert/strict";
import { createFreeHandler } from "./handler.ts";

const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const SHA = Array.from(
  new Uint8Array(await crypto.subtle.digest("SHA-256", PNG)),
  (x) => x.toString(16).padStart(2, "0"),
).join("");

function handler(over: { pack?: boolean; image?: Uint8Array | null; fail?: boolean } = {}) {
  return createFreeHandler({
    freePack: () =>
      over.fail
        ? Promise.reject(new Error("secret interne"))
        : Promise.resolve(over.pack === false ? null : { version: 9, pictograms: [] }),
    freeImage: (sha) =>
      Promise.resolve(
        over.image === null || sha !== SHA ? null : { mime: "image/png", bytes: over.image ?? PNG },
      ),
  });
}

const get = (query: string) => new Request(`http://x/free-pack${query}`);

Deno.test("sert le paquet gratuit sans compte", async () => {
  const res = await handler()(get(""));
  assert.equal(res.status, 200);
  assert.equal((await res.json()).version, 9);
});

Deno.test("204 quand l'appareil a déjà la version", async () => {
  assert.equal((await handler()(get("?have=9"))).status, 204);
  assert.equal((await handler()(get("?have=8"))).status, 200);
});

Deno.test("404 quand la publication n'a aucun mot gratuit", async () => {
  assert.equal((await handler({ pack: false })(get(""))).status, 404);
});

Deno.test("sert l'image d'un mot gratuit, vérifiée", async () => {
  const res = await handler()(get(`?sha256=${SHA}`));
  assert.equal(res.status, 200);
  assert.equal(res.headers.get("Content-Type"), "image/png");
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), PNG);
});

Deno.test("refuse une image hors paquet gratuit, une empreinte invalide, un objet altéré", async () => {
  assert.equal((await handler({ image: null })(get(`?sha256=${SHA}`))).status, 404);
  assert.equal((await handler()(get("?sha256=../etc"))).status, 400);
  const altered = new Uint8Array([...PNG, 0]);
  assert.equal((await handler({ image: altered })(get(`?sha256=${SHA}`))).status, 500);
});

Deno.test("erreur interne sans détail, méthode refusée", async () => {
  const res = await handler({ fail: true })(get(""));
  assert.equal(res.status, 500);
  assert.doesNotMatch(await res.text(), /secret/);
  assert.equal(
    (await handler()(new Request("http://x/free-pack", { method: "POST" }))).status,
    405,
  );
});

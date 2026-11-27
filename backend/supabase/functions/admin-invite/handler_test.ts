import assert from "node:assert/strict";
import { createInviteHandler, type InviteDeps, RoleError } from "./handler.ts";

const SITE = "https://admin.example.org";

function setup(over: {
  superAdmin?: boolean;
  exists?: boolean;
  existsOnInvite?: boolean;
  roleError?: string;
  fail?: boolean;
} = {}) {
  const calls: string[] = [];
  const deps: InviteDeps = {
    siteUrl: SITE,
    isSuperAdmin: (a) => {
      calls.push(`check ${a}`);
      return Promise.resolve(over.superAdmin ?? true);
    },
    accountExists: (email) => {
      calls.push(`exists? ${email}`);
      return Promise.resolve(over.exists ?? false);
    },
    invite: (email, redirectTo) => {
      calls.push(`invite ${email} ${redirectTo}`);
      if (over.fail) return Promise.reject(new Error("secret interne"));
      return Promise.resolve(over.existsOnInvite ? "exists" : { id: "u-new" });
    },
    grantInvited: (_a, id, role) => {
      calls.push(`grant ${id} ${role}`);
      return Promise.resolve();
    },
    setRole: (_a, email, role) => {
      calls.push(`setRole ${email} ${role}`);
      return over.roleError ? Promise.reject(new RoleError(over.roleError)) : Promise.resolve();
    },
  };
  return { handler: createInviteHandler(deps), calls };
}

const post = (body: unknown, auth = "Bearer jwt") =>
  new Request("http://x/admin-invite", {
    method: "POST",
    headers: { Authorization: auth, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

Deno.test("nouvelle adresse : invitation envoyée vers le back-office, rôle attribué", async () => {
  const { handler, calls } = setup();
  const res = await handler(post({ email: " Nouvelle@Exemple.org ", role: "support" }));
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: "invited" });
  assert.deepEqual(calls, [
    "check Bearer jwt",
    "exists? nouvelle@exemple.org",
    `invite nouvelle@exemple.org ${SITE}/`,
    "grant u-new support",
  ]);
  assert.equal(res.headers.get("Access-Control-Allow-Origin"), SITE);
});

Deno.test("compte existant : aucune invitation, rôle avec les règles habituelles", async () => {
  const { handler, calls } = setup({ exists: true });
  const res = await handler(post({ email: "a@b.org", role: "super_admin" }));
  assert.deepEqual(await res.json(), { status: "role_set" });
  assert.equal(calls.at(-1), "setRole a@b.org super_admin");
  assert.ok(!calls.some((c) => c.startsWith("invite")), "pas d'invitation vers un compte existant");
});

Deno.test("compte apparu entre la vérification et l'invitation : voie habituelle", async () => {
  const { handler, calls } = setup({ existsOnInvite: true });
  const res = await handler(post({ email: "a@b.org", role: "support" }));
  assert.deepEqual(await res.json(), { status: "role_set" });
  assert.equal(calls.at(-1), "setRole a@b.org support");
});

Deno.test("refus métier renvoyé tel quel (adresse non confirmée)", async () => {
  const { handler } = setup({ exists: true, roleError: "unconfirmed_email" });
  const res = await handler(post({ email: "a@b.org", role: "support" }));
  assert.equal(res.status, 409);
  assert.deepEqual(await res.json(), { error: "unconfirmed_email" });
});

Deno.test("refusé hors super-administrateur, sans jeton, ou mal formé", async () => {
  assert.equal(
    (await setup({ superAdmin: false }).handler(post({ email: "a@b.org", role: "support" })))
      .status,
    403,
  );
  const { handler, calls } = setup();
  assert.equal((await handler(post({ email: "a@b.org", role: "support" }, ""))).status, 403);
  assert.equal(calls.length, 0, "aucun appel sans jeton");
  assert.equal((await handler(post({ email: "pas-une-adresse", role: "support" }))).status, 400);
  assert.equal((await handler(post({ email: "a@b.org", role: "owner" }))).status, 400);
  assert.equal((await handler(new Request("http://x", { method: "GET" }))).status, 405);
});

Deno.test("préflight CORS limité au back-office ; erreur interne sans détail", async () => {
  const pre = await setup().handler(new Request("http://x", { method: "OPTIONS" }));
  assert.equal(pre.status, 204);
  assert.equal(pre.headers.get("Access-Control-Allow-Origin"), SITE);
  const res = await setup({ fail: true }).handler(post({ email: "a@b.org", role: "support" }));
  assert.equal(res.status, 500);
  assert.doesNotMatch(await res.text(), /secret/);
});

import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { AuthProvider, useAuth } from "@/app/auth";
import { DbProvider } from "@/app/db-context";
import type { Db } from "@/lib/supabase";
import { MfaPage } from "./MfaPage";

type Factor = { id: string; factor_type: string; status: string };

/** Client Supabase factice : rôle, niveau d'authentification et facteurs choisis par le test. */
/** Jeton dont le second facteur a été vérifié il y a `ageMs`. */
function tokenVerified(ageMs: number) {
  const b64 = (o: unknown) => btoa(JSON.stringify(o)).replace(/=+$/, "");
  return `${b64({ alg: "HS256" })}.${b64({ amr: [{ method: "totp", timestamp: Math.floor((Date.now() - ageMs) / 1000) }] })}.sig`;
}

function fakeDb(opts: { role: string | null; current: string; next: string; factors?: Factor[]; mfaAgeMs?: number }) {
  const session = { user: { email: "admin@test.local" }, access_token: tokenVerified(opts.mfaAgeMs ?? 60_000) };
  let current = opts.current;
  const factors = opts.factors ?? [];
  const mfa = {
    getAuthenticatorAssuranceLevel: vi.fn(() => Promise.resolve({ data: { currentLevel: current, nextLevel: opts.next }, error: null })),
    listFactors: vi.fn(() =>
      Promise.resolve({ data: { all: factors, totp: factors.filter((f) => f.status === "verified") }, error: null }),
    ),
    unenroll: vi.fn(() => Promise.resolve({ data: {}, error: null })),
    enroll: vi.fn(() =>
      Promise.resolve({ data: { id: "new-factor", totp: { qr_code: "data:image/svg+xml;utf-8,<svg/>", secret: "SECRET123" } }, error: null }),
    ),
    challengeAndVerify: vi.fn(({ code }: { code: string }) => {
      if (code !== "123456") return Promise.resolve({ data: null, error: new Error("invalid code") });
      current = "aal2";
      return Promise.resolve({ data: {}, error: null });
    }),
  };
  const signOut = vi.fn(() => Promise.resolve({ error: null }));
  const db = {
    rpc: vi.fn(() => Promise.resolve({ data: opts.role, error: null })),
    auth: {
      getSession: vi.fn(() => Promise.resolve({ data: { session } })),
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
      signOut,
      mfa,
    },
  };
  return { db: db as unknown as Db, mfa, signOut };
}

function Status() {
  const { state } = useAuth();
  return (
    <>
      <p data-testid="status">{state.status}</p>
      {state.status === "mfa" && <MfaPage step={state.step} />}
    </>
  );
}

const renderApp = (db: Db) =>
  render(
    <DbProvider db={db}>
      <AuthProvider>
        <Status />
      </AuthProvider>
    </DbProvider>,
  );

describe("double authentification des administrateurs", () => {
  it("un administrateur au mot de passe seul doit saisir son code", async () => {
    const { db } = fakeDb({ role: "super_admin", current: "aal1", next: "aal2", factors: [{ id: "f1", factor_type: "totp", status: "verified" }] });
    renderApp(db);
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("mfa"); });
    expect(screen.getByText(/Saisissez le code affiché/)).toBeInTheDocument();
  });

  it("une session déjà vérifiée ouvre directement l'administration", async () => {
    const { db } = fakeDb({ role: "support", current: "aal2", next: "aal2" });
    renderApp(db);
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("signed-in"); });
  });

  it("une session de plus de 24 heures renvoie à la connexion", async () => {
    const { db, signOut } = fakeDb({ role: "super_admin", current: "aal2", next: "aal2", mfaAgeMs: 25 * 60 * 60 * 1000 });
    renderApp(db);
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("signed-out"); });
    expect(signOut).toHaveBeenCalled();
  });

  it("un compte sans rôle est déconnecté, même avec un second facteur", async () => {
    const { db } = fakeDb({ role: null, current: "aal2", next: "aal2" });
    renderApp(db);
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("signed-out"); });
  });

  it("un code faux est refusé, le bon ouvre l'administration", async () => {
    const user = userEvent.setup();
    const { db, mfa } = fakeDb({ role: "super_admin", current: "aal1", next: "aal2", factors: [{ id: "f1", factor_type: "totp", status: "verified" }] });
    renderApp(db);
    const input = await screen.findByLabelText("Code à six chiffres");
    await waitFor(() => { expect(screen.getByRole("button", { name: "Valider" })).toBeEnabled(); });

    await user.type(input, "000000");
    await user.click(screen.getByRole("button", { name: "Valider" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Code incorrect");
    expect(screen.getByTestId("status")).toHaveTextContent("mfa");

    await user.type(input, "123456");
    await user.click(screen.getByRole("button", { name: "Valider" }));
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("signed-in"); });
    expect(mfa.challengeAndVerify).toHaveBeenLastCalledWith({ factorId: "f1", code: "123456" });
  });

  it("première connexion : configuration, après retrait d'un facteur abandonné", async () => {
    const user = userEvent.setup();
    const { db, mfa } = fakeDb({ role: "super_admin", current: "aal1", next: "aal1", factors: [{ id: "stale", factor_type: "totp", status: "unverified" }] });
    renderApp(db);
    await user.click(await screen.findByRole("button", { name: "Configurer" }));

    expect(await screen.findByAltText("Code QR de configuration")).toBeInTheDocument();
    expect(screen.getByText("SECRET123")).toBeInTheDocument();
    expect(mfa.unenroll).toHaveBeenCalledWith({ factorId: "stale" });
    expect(mfa.enroll).toHaveBeenCalledWith(expect.objectContaining({ factorType: "totp" }));

    await user.type(screen.getByLabelText("Code à six chiffres"), "123456");
    await user.click(screen.getByRole("button", { name: "Valider" }));
    await waitFor(() => { expect(screen.getByTestId("status")).toHaveTextContent("signed-in"); });
    expect(mfa.challengeAndVerify).toHaveBeenCalledWith({ factorId: "new-factor", code: "123456" });
  });
});

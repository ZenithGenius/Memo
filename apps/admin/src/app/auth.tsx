import type { Session } from "@supabase/supabase-js";
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import { report } from "@/lib/errors";
import { mfaStep } from "@/lib/mfa";
import type { AuthLink } from "@/lib/recovery";
import { isAdminRole, type AdminRole } from "@/lib/roles";
import type { Db } from "@/lib/supabase";
import { useDb } from "./db-context";

type AuthState =
  | { status: "loading" }
  | { status: "signed-out"; reason?: string; notice?: string }
  // Ouvert depuis le lien reçu par e-mail : choix d'un nouveau mot de passe,
  // pour un administrateur comme pour une famille (aucun rôle exigé).
  | { status: "recovery" }
  // Mot de passe accepté, second facteur encore à saisir ou à configurer : la
  // base refuse toute action d'administration tant que la session n'est pas aal2.
  | { status: "mfa"; step: "verify" | "enroll"; role: AdminRole }
  | { status: "signed-in"; session: Session; role: AdminRole };

interface AuthApi {
  state: AuthState;
  signIn: (email: string, password: string) => Promise<string | null>;
  signOut: () => Promise<void>;
  /** À appeler après la vérification d'un code : relit la session (aal2). */
  completeMfa: () => Promise<void>;
  /** Envoie le lien par e-mail. Même réponse que l'adresse existe ou non. */
  requestReset: (email: string) => Promise<string | null>;
  /** Mot de passe changé : toutes les sessions du compte sont fermées. */
  finishRecovery: () => Promise<void>;
}

const EXPIRED_LINK = "Ce lien a expiré ou a déjà servi. Demandez-en un nouveau.";

const NO_ACCESS = "Ce compte n'a pas accès à l'administration.";

const AuthContext = createContext<AuthApi | null>(null);

/** État d'une session : rôle d'administrateur, puis niveau d'authentification. */
async function stateFor(db: Db, session: Session | null): Promise<AuthState> {
  if (!session) return { status: "signed-out" };
  const { data: role, error } = await db.rpc("admin_me");
  if (error) report("rôle", error);
  if (!isAdminRole(role)) {
    await db.auth.signOut();
    return { status: "signed-out", reason: NO_ACCESS };
  }
  const { data: aal, error: aalError } = await db.auth.mfa.getAuthenticatorAssuranceLevel();
  if (aalError) report("niveau d'authentification", aalError);
  const step = mfaStep(aal?.currentLevel ?? null, aal?.nextLevel ?? null);
  return step === "done" ? { status: "signed-in", session, role } : { status: "mfa", step, role };
}

export function AuthProvider({ children, link = null }: { children: ReactNode; link?: AuthLink }) {
  const db = useDb();
  const [state, setState] = useState<AuthState>({ status: "loading" });

  const refresh = useCallback(async () => {
    const { data } = await db.auth.getSession();
    setState(await stateFor(db, data.session));
  }, [db]);

  useEffect(() => {
    let cancelled = false;
    void db.auth.getSession().then(async ({ data }) => {
      const next: AuthState =
        link === "recovery" && data.session
          ? { status: "recovery" }
          : link === "expired"
            ? { status: "signed-out", reason: EXPIRED_LINK }
            : await stateFor(db, data.session);
      if (!cancelled) setState(next);
    });
    const { data: sub } = db.auth.onAuthStateChange((event, session) => {
      if (event === "PASSWORD_RECOVERY") setState({ status: "recovery" });
      if (event === "SIGNED_OUT") setState((s) => (s.status === "signed-out" ? s : { status: "signed-out" }));
      if (event === "TOKEN_REFRESHED" && session)
        setState((s) => (s.status === "signed-in" ? { ...s, session } : s));
    });
    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, [db, link]);

  const api: AuthApi = {
    state,
    signIn: async (email, password) => {
      const { data, error } = await db.auth.signInWithPassword({ email: email.trim(), password });
      if (error) {
        report("connexion", error);
        return error.message === "Invalid login credentials"
          ? "E-mail ou mot de passe incorrect."
          : "Connexion impossible pour le moment. Réessayez.";
      }
      const next = await stateFor(db, data.session);
      setState(next);
      return next.status === "signed-out" ? (next.reason ?? NO_ACCESS) : null;
    },
    signOut: async () => {
      await db.auth.signOut();
      setState({ status: "signed-out" });
    },
    completeMfa: refresh,
    requestReset: async (email) => {
      const { error } = await db.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/`,
      });
      if (!error) return null;
      report("demande de réinitialisation", error);
      return error.status === 429
        ? "Trop de demandes. Réessayez dans une heure."
        : "Envoi impossible pour le moment. Réessayez.";
    },
    finishRecovery: async () => {
      const { error } = await db.auth.signOut({ scope: "global" });
      if (error) report("fermeture des sessions", error);
      setState({
        status: "signed-out",
        notice: "Mot de passe modifié. Connectez-vous avec le nouveau mot de passe.",
      });
    },
  };

  return <AuthContext value={api}>{children}</AuthContext>;
}

export function useAuth(): AuthApi {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("AuthProvider manquant");
  return ctx;
}

/** Session courante : à n'utiliser que sous la garde d'authentification. */
export function useSession() {
  const { state } = useAuth();
  if (state.status !== "signed-in") throw new Error("Session requise");
  return state;
}

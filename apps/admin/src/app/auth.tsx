import type { Session } from "@supabase/supabase-js";
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { report } from "@/lib/errors";
import { isAdminRole, type AdminRole } from "@/lib/roles";
import { useDb } from "./db-context";

type AuthState =
  | { status: "loading" }
  | { status: "signed-out"; reason?: string }
  | { status: "signed-in"; session: Session; role: AdminRole };

interface AuthApi {
  state: AuthState;
  signIn: (email: string, password: string) => Promise<string | null>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthApi | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const db = useDb();
  const [state, setState] = useState<AuthState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;

    async function resolve(session: Session | null) {
      if (!session) {
        if (!cancelled) setState({ status: "signed-out" });
        return;
      }
      const { data, error } = await db.rpc("admin_me");
      if (cancelled) return;
      if (error) report("rôle", error);
      if (!isAdminRole(data)) {
        await db.auth.signOut();
        setState({ status: "signed-out", reason: "Ce compte n'a pas accès à l'administration." });
        return;
      }
      setState({ status: "signed-in", session, role: data });
    }

    void db.auth.getSession().then(({ data }) => resolve(data.session));
    const { data: sub } = db.auth.onAuthStateChange((event, session) => {
      if (event === "SIGNED_OUT") setState({ status: "signed-out" });
      if (event === "TOKEN_REFRESHED" && session)
        setState((s) => (s.status === "signed-in" ? { ...s, session } : s));
    });
    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, [db]);

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
      const { data: role, error: roleError } = await db.rpc("admin_me");
      if (roleError) report("rôle", roleError);
      if (!isAdminRole(role)) {
        await db.auth.signOut();
        return "Ce compte n'a pas accès à l'administration.";
      }
      setState({ status: "signed-in", session: data.session, role });
      return null;
    },
    signOut: async () => {
      await db.auth.signOut();
      setState({ status: "signed-out" });
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

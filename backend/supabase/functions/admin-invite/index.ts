// Point d'entrée : configuration, dépendances, gestionnaire.
import { createClient } from "npm:@supabase/supabase-js@2.117.3";
import { requireEnv } from "../_shared/config.ts";
import { createInviteHandler, RoleError } from "./handler.ts";

const env = requireEnv(
  Deno.env,
  ["SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY", "SITE_URL"] as const,
);
const service = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
// Client au nom de l'appelant : les fonctions SQL vérifient son rôle et
// inscrivent son identité dans le journal d'audit.
const asCaller = (authorization: string) =>
  createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

async function rpc(authorization: string, fn: string, args: Record<string, unknown>) {
  const { error } = await asCaller(authorization).rpc(fn, args);
  if (error) throw new RoleError(error.message);
}

Deno.serve(
  createInviteHandler({
    siteUrl: env.SITE_URL.replace(/\/+$/, ""),
    async isSuperAdmin(authorization) {
      const { data, error } = await asCaller(authorization).rpc("is_super_admin");
      return !error && data === true;
    },
    async accountExists(email) {
      const { data, error } = await service.rpc("auth_account_exists", { target_email: email });
      if (error) throw error;
      return data === true;
    },
    async invite(email, redirectTo) {
      const { data, error } = await service.auth.admin.inviteUserByEmail(email, { redirectTo });
      if (error?.code === "email_exists") return "exists";
      if (error || !data.user) throw error ?? new Error("invitation sans compte");
      return { id: data.user.id };
    },
    grantInvited: (authorization, userId, role) =>
      rpc(authorization, "admin_grant_invited", { target: userId, new_role: role }),
    setRole: (authorization, email, role) =>
      rpc(authorization, "admin_set_role", { target_email: email, new_role: role }),
  }),
);

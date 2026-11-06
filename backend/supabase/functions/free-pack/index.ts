// Point d'entrée : configuration, dépendances, gestionnaire.
import { requireEnv } from "../_shared/config.ts";
import { SupabaseLicenseRepository } from "../_shared/repository.ts";
import { createFreeHandler } from "./handler.ts";

const env = requireEnv(Deno.env, ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"] as const);
const repo = new SupabaseLicenseRepository(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(
  createFreeHandler({
    freePack: () => repo.freePack(),
    freeImage: (sha256) => repo.freeImage(sha256),
  }),
);

// Point d'entrée : configuration, dépendances, gestionnaire.
import { createClient } from "npm:@supabase/supabase-js@2.117.3";
import { requireEnv } from "../_shared/config.ts";
import { SupabaseLicenseRepository } from "../_shared/repository.ts";
import { createImageHandler } from "./handler.ts";

const env = requireEnv(
  Deno.env,
  [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
  ] as const,
);
const repo = new SupabaseLicenseRepository(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(
  createImageHandler({
    repo,
    now: () => new Date(),
    publishedImage: (sha256) => repo.publishedImage(sha256),
    async authenticate(req) {
      const client = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      });
      const { data, error } = await client.auth.getUser();
      return error || !data.user ? null : data.user.id;
    },
  }),
);

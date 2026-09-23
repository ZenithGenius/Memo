// Point d'entrée : configuration, dépendances, gestionnaire.
import { createClient } from "npm:@supabase/supabase-js@2";
import { requireEnv } from "../_shared/config.ts";
import { SupabaseLicenseRepository } from "../_shared/repository.ts";
import { createPremiumHandler, type PremiumPack } from "./handler.ts";
import packJson from "./pack.json" with { type: "json" };

const env = requireEnv(
  Deno.env,
  [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
  ] as const,
);
const repo = new SupabaseLicenseRepository(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);

// Généré par tools/generate_content_pack.py. Importé comme module pour être
// embarqué dans la fonction (un fichier lu à l'exécution ne l'est pas).
const pack = packJson as PremiumPack;

Deno.serve(
  createPremiumHandler({
    repo,
    now: () => new Date(),
    loadPack: () => Promise.resolve(pack),
    async authenticate(req) {
      const client = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      });
      const { data, error } = await client.auth.getUser();
      return error || !data.user ? null : data.user.id;
    },
  }),
);

// Point d'entrée : lit la configuration, câble les dépendances, sert le gestionnaire.
import { createClient } from "npm:@supabase/supabase-js@2";
import { loadConfig } from "../_shared/config.ts";
import { SupabaseLicenseRepository } from "../_shared/repository.ts";
import { Ed25519Signer } from "../_shared/signer.ts";
import { createHandler } from "./handler.ts";

const config = loadConfig(Deno.env);
const signer = await Ed25519Signer.fromPkcs8(config.keyId, config.privateKeyPkcs8);
const repo = new SupabaseLicenseRepository(config.supabaseUrl, config.serviceRoleKey);

Deno.serve(
  createHandler({
    config,
    signer,
    repo,
    now: () => new Date(),
    async authenticate(req) {
      const client = createClient(config.supabaseUrl, config.anonKey, {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      });
      const { data, error } = await client.auth.getUser();
      return error || !data.user ? null : data.user.id;
    },
  }),
);

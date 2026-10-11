import { createClient } from "@supabase/supabase-js";
import type { AppConfig } from "./config";
import type { Database } from "./database.types";

export type Db = ReturnType<typeof createDb>;

export function createDb(config: AppConfig) {
  return createClient<Database>(config.supabaseUrl, config.supabaseAnonKey, {
    auth: { persistSession: true, autoRefreshToken: true },
  });
}

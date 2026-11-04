import { z } from "zod";

declare global {
  interface Window {
    MEMO_CONFIG?: unknown;
  }
}

const schema = z.object({
  supabaseUrl: z.url(),
  supabaseAnonKey: z.string().min(20),
});

export type AppConfig = z.infer<typeof schema>;

/** Configuration lue au démarrage (public/config.js, généré par le conteneur). */
export function readConfig(source: unknown = window.MEMO_CONFIG): AppConfig | null {
  const parsed = schema.safeParse(source);
  return parsed.success ? parsed.data : null;
}

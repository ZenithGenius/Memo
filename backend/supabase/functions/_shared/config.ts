// Configuration lue depuis l'environnement, validée une seule fois au démarrage.
// Aucun secret ni identifiant n'est écrit dans le code.

export interface EnvReader {
  get(key: string): string | undefined;
}

export interface LicenseConfig {
  supabaseUrl: string;
  anonKey: string;
  serviceRoleKey: string;
  /** Identifiant de la clé de signature (claim `kid`). */
  keyId: string;
  /** Clé privée Ed25519, PKCS8 en base64. Secret du serveur. */
  privateKeyPkcs8: string;
  /** Durée d'un jeton pour un appareil de confiance faible (ADR-008). */
  shortTokenDays: number;
  /** Durée de vie maximale d'un jeton, qui doit égaler celle du client (ADR-008). */
  maxTokenDays: number;
}

const REQUIRED = [
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
  "LICENSE_KEY_ID",
  "LICENSE_PRIVATE_KEY_PKCS8",
] as const;

// Valeurs de politique (ADR-008), surchargeables. Ce ne sont pas des secrets.
const DEFAULT_SHORT_TOKEN_DAYS = 7;
const DEFAULT_MAX_TOKEN_DAYS = 45;

export class ConfigError extends Error {}

function positiveInt(env: EnvReader, key: string, fallback: number): number {
  const raw = env.get(key);
  if (raw === undefined || raw === "") return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value <= 0) {
    throw new ConfigError(`${key} doit être un entier strictement positif`);
  }
  return value;
}

export function loadConfig(env: EnvReader): LicenseConfig {
  const missing = REQUIRED.filter((key) => !env.get(key));
  if (missing.length > 0) {
    throw new ConfigError(`Variables d'environnement manquantes : ${missing.join(", ")}`);
  }
  return {
    supabaseUrl: env.get("SUPABASE_URL")!,
    anonKey: env.get("SUPABASE_ANON_KEY")!,
    serviceRoleKey: env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    keyId: env.get("LICENSE_KEY_ID")!,
    privateKeyPkcs8: env.get("LICENSE_PRIVATE_KEY_PKCS8")!,
    shortTokenDays: positiveInt(env, "LICENSE_SHORT_TOKEN_DAYS", DEFAULT_SHORT_TOKEN_DAYS),
    maxTokenDays: positiveInt(env, "LICENSE_MAX_TOKEN_DAYS", DEFAULT_MAX_TOKEN_DAYS),
  };
}

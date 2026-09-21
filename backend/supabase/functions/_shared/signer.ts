import { fromBase64 } from "./encoding.ts";

/** Signe une chaîne ASCII. Isole l'algorithme et la gestion de la clé privée. */
export interface TokenSigner {
  readonly keyId: string;
  sign(message: string): Promise<Uint8Array>;
}

export class Ed25519Signer implements TokenSigner {
  private constructor(readonly keyId: string, private readonly key: CryptoKey) {}

  static async fromPkcs8(keyId: string, pkcs8Base64: string): Promise<Ed25519Signer> {
    const key = await crypto.subtle.importKey(
      "pkcs8",
      fromBase64(pkcs8Base64),
      { name: "Ed25519" },
      false,
      ["sign"],
    );
    return new Ed25519Signer(keyId, key);
  }

  async sign(message: string): Promise<Uint8Array> {
    const signature = await crypto.subtle.sign(
      "Ed25519",
      this.key,
      new TextEncoder().encode(message),
    );
    return new Uint8Array(signature);
  }
}

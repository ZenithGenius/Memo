export type Platform = "android" | "ios";

export interface IssueRequest {
  fingerprint: string;
  platform: Platform;
  label: string | null;
}

export type ParseResult =
  | { ok: true; value: IssueRequest }
  | { ok: false; error: "invalid_fingerprint" | "invalid_platform" };

const FINGERPRINT = /^[A-Za-z0-9+/=_-]{16,128}$/;
const MAX_LABEL = 80;

export function parseIssueRequest(body: unknown): ParseResult {
  const b = (body ?? {}) as Record<string, unknown>;
  if (typeof b.fingerprint !== "string" || !FINGERPRINT.test(b.fingerprint)) {
    return { ok: false, error: "invalid_fingerprint" };
  }
  if (b.platform !== "android" && b.platform !== "ios") {
    return { ok: false, error: "invalid_platform" };
  }
  const label = typeof b.label === "string" ? b.label.slice(0, MAX_LABEL) : null;
  return { ok: true, value: { fingerprint: b.fingerprint, platform: b.platform, label } };
}

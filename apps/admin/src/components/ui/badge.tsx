import type { ReactNode } from "react";
import { cn } from "./cn";

export type Tone = "success" | "warning" | "danger" | "neutral" | "info";

const tones: Record<Tone, string> = {
  success: "border-success-border bg-success-muted text-success",
  warning: "border-warning-border bg-warning-muted text-warning",
  danger: "border-danger-border bg-danger-muted text-danger",
  neutral: "border-line bg-subtle text-fg-muted",
  info: "border-accent-border bg-accent-muted text-accent-strong",
};

export function Badge({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) {
  return (
    <span className={cn("inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-semibold whitespace-nowrap", tones[tone])}>
      <span className="size-1.5 rounded-full bg-current" aria-hidden />
      {children}
    </span>
  );
}

export function Chip({ children }: { children: ReactNode }) {
  return <span className="inline-flex rounded-md bg-subtle px-2 py-0.5 text-xs font-medium text-fg-secondary">{children}</span>;
}

import { CircleAlert } from "lucide-react";
import type { ReactNode } from "react";
import { Button } from "./button";

export function Skeleton({ rows = 4 }: { rows?: number }) {
  return (
    <div className="grid gap-3 p-4" aria-busy="true" aria-label="Chargement">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="h-3.5 animate-pulse rounded-full bg-subtle" style={{ width: `${92 - i * 9}%` }} />
      ))}
    </div>
  );
}

export function EmptyState({ icon, title, text, action }: { icon: ReactNode; title: string; text?: string; action?: ReactNode }) {
  return (
    <div className="px-6 py-12 text-center">
      <div className="mx-auto grid size-13 place-items-center rounded-2xl bg-accent-muted text-accent-strong">{icon}</div>
      <p className="mt-3.5 font-semibold text-fg">{title}</p>
      {text && <p className="mt-1 text-sm text-fg-muted">{text}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

export function ErrorPanel({ onRetry }: { onRetry?: () => void }) {
  return (
    <EmptyState
      icon={<CircleAlert className="size-5" />}
      title="Ces données n'ont pas pu être chargées"
      text="Réessayez dans un instant."
      action={onRetry && <Button variant="secondary" onClick={onRetry}>Réessayer</Button>}
    />
  );
}

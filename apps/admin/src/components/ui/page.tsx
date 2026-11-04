import type { ReactNode } from "react";
import { Card } from "./card";
import { cn } from "./cn";

export function PageHeader({ title, description, actions }: { title: string; description?: string; actions?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl sm:text-[1.6rem]">{title}</h1>
        {description && <p className="mt-1.5 max-w-3xl text-sm leading-relaxed text-fg-muted">{description}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-2">{actions}</div>}
    </div>
  );
}

type Color = "blue" | "green" | "amber" | "red";
const iconColors: Record<Color, string> = {
  blue: "bg-accent-muted text-accent-strong",
  green: "bg-success-muted text-success",
  amber: "bg-warning-muted text-warning",
  red: "bg-danger-muted text-danger",
};

export function StatCard({ label, value, hint, icon, color = "blue" }: { label: string; value: ReactNode; hint?: ReactNode; icon: ReactNode; color?: Color }) {
  return (
    <Card className="grid gap-3.5 p-4.5">
      <div className="flex items-center justify-between gap-2">
        <span className="text-[0.8rem] font-medium text-fg-muted">{label}</span>
        <span className={cn("grid size-9 shrink-0 place-items-center rounded-xl", iconColors[color])}>{icon}</span>
      </div>
      <div className="font-heading text-[1.65rem] leading-none font-semibold tracking-tight text-fg">{value}</div>
      {hint && <div className="text-xs text-fg-muted">{hint}</div>}
    </Card>
  );
}

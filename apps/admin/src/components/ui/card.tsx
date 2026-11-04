import type { ReactNode } from "react";
import { cn } from "./cn";

export function Card({ className, children }: { className?: string; children: ReactNode }) {
  return <section className={cn("rounded-2xl border border-line bg-raised shadow-sm", className)}>{children}</section>;
}

export function CardHeader({ title, icon, aside }: { title: ReactNode; icon?: ReactNode; aside?: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-line-subtle px-5 py-3.5">
      <h2 className="flex items-center gap-2 font-sans text-[0.95rem] font-semibold text-fg">
        {icon ?? <span className="size-1.5 rounded-full bg-accent" aria-hidden />}
        {title}
      </h2>
      {aside && <div className="text-sm text-fg-muted">{aside}</div>}
    </div>
  );
}

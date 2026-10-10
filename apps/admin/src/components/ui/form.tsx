import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from "react";
import { cn } from "./cn";

const control =
  "h-10 w-full rounded-lg border border-line bg-raised px-3 text-sm text-fg placeholder:text-fg-muted transition focus:border-accent focus:outline-none focus:ring-4 focus:ring-ring disabled:opacity-60";

export function Field({ label, htmlFor, error, hint, children, className }: {
  label: string; htmlFor: string; error?: string | undefined; hint?: string; children: ReactNode; className?: string;
}) {
  return (
    <div className={cn("grid gap-1.5", className)}>
      <label htmlFor={htmlFor} className="text-xs font-semibold text-fg-secondary">{label}</label>
      {children}
      {error ? <p className="text-xs text-danger" role="alert">{error}</p> : hint && <p className="text-xs text-fg-muted">{hint}</p>}
    </div>
  );
}

export function Input({ className, ...rest }: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={cn(control, className)} {...rest} />;
}

export function Select({ className, children, ...rest }: SelectHTMLAttributes<HTMLSelectElement>) {
  return <select className={cn(control, className)} {...rest}>{children}</select>;
}

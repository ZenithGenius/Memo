import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cn } from "./cn";

type Variant = "primary" | "secondary" | "danger" | "ghost" | "soft-danger" | "soft-accent";
type Size = "sm" | "md";

const variants: Record<Variant, string> = {
  primary: "bg-blue-500 text-white shadow-sm hover:bg-blue-600",
  secondary: "border-line bg-raised text-fg hover:border-accent-border hover:bg-accent-muted",
  danger: "bg-red-500 text-white hover:bg-red-600",
  ghost: "bg-transparent text-fg-muted hover:bg-subtle hover:text-fg",
  "soft-danger": "border-danger-border bg-danger-muted text-danger hover:bg-red-500 hover:text-white",
  "soft-accent": "border-accent-border bg-accent-muted text-accent-strong hover:bg-blue-500 hover:text-white",
};

const sizes: Record<Size, string> = {
  sm: "h-auto rounded-lg px-2.5 py-1.5 text-xs",
  md: "h-10 rounded-xl px-4 text-sm",
};

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  icon?: ReactNode;
}

export function Button({ variant = "primary", size = "md", loading, icon, className, children, disabled, type = "button", ...rest }: Props) {
  return (
    <button
      type={type}
      disabled={disabled || loading}
      aria-busy={loading}
      className={cn(
        "inline-flex items-center justify-center gap-2 border border-transparent font-semibold whitespace-nowrap transition-colors disabled:cursor-not-allowed disabled:opacity-55",
        variants[variant],
        sizes[size],
        className,
      )}
      {...rest}
    >
      {loading ? <span className="size-4 animate-spin rounded-full border-2 border-current border-r-transparent" /> : icon}
      {children}
    </button>
  );
}

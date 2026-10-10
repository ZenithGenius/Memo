import { CircleAlert, CircleCheck } from "lucide-react";
import { createContext, useCallback, useContext, useState, type ReactNode } from "react";

type Tone = "success" | "error";
interface Toast { id: number; tone: Tone; message: string }

const ToastContext = createContext<((message: string, tone?: Tone) => void) | null>(null);

let nextId = 1;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const push = useCallback((message: string, tone: Tone = "success") => {
    const id = nextId++;
    setToasts((t) => [...t, { id, tone, message }]);
    setTimeout(() => { setToasts((t) => t.filter((x) => x.id !== id)); }, tone === "error" ? 6000 : 3200);
  }, []);

  return (
    <ToastContext value={push}>
      {children}
      <div className="fixed right-5 bottom-5 z-60 grid gap-2" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div
            key={t.id}
            className="animate-slide-in flex max-w-sm min-w-64 items-center gap-2.5 rounded-xl border border-line bg-raised px-3.5 py-3 text-sm text-fg shadow-lg"
          >
            {t.tone === "error" ? (
              <CircleAlert className="size-4.5 shrink-0 text-danger" />
            ) : (
              <CircleCheck className="size-4.5 shrink-0 text-success" />
            )}
            {t.message}
          </div>
        ))}
      </div>
    </ToastContext>
  );
}

export function useToast() {
  const push = useContext(ToastContext);
  if (!push) throw new Error("ToastProvider manquant");
  return push;
}

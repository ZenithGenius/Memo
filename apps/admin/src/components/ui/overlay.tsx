import { TriangleAlert, X } from "lucide-react";
import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { Button } from "./button";

interface ConfirmOptions { title: string; text: string; confirmLabel?: string }
type ConfirmFn = (o: ConfirmOptions) => Promise<boolean>;

const ConfirmContext = createContext<ConfirmFn | null>(null);

/** Confirmation avant une action irréversible ou sensible (dialogue natif). */
export function ConfirmProvider({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  const resolver = useRef<((ok: boolean) => void) | null>(null);
  const [options, setOptions] = useState<ConfirmOptions | null>(null);

  const confirm = useCallback<ConfirmFn>((o) => {
    setOptions(o);
    ref.current?.showModal();
    return new Promise((resolve) => { resolver.current = resolve; });
  }, []);

  const close = (ok: boolean) => {
    ref.current?.close();
    resolver.current?.(ok);
    resolver.current = null;
  };

  return (
    <ConfirmContext value={confirm}>
      {children}
      <dialog
        ref={ref}
        onCancel={() => { close(false); }}
        className="m-auto w-[min(420px,92vw)] rounded-2xl border border-line bg-raised p-0 text-fg-secondary shadow-xl backdrop:bg-overlay"
      >
        <div className="flex gap-3.5 p-5">
          <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-danger-muted text-danger"><TriangleAlert className="size-5" /></div>
          <div>
            <h3 className="text-base">{options?.title}</h3>
            <p className="mt-1.5 text-sm leading-relaxed text-fg-muted">{options?.text}</p>
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-line-subtle bg-muted-surface px-5 py-3.5">
          <Button variant="secondary" onClick={() => { close(false); }}>Annuler</Button>
          <Button variant="danger" onClick={() => { close(true); }}>{options?.confirmLabel ?? "Confirmer"}</Button>
        </div>
      </dialog>
    </ConfirmContext>
  );
}

export function useConfirm(): ConfirmFn {
  const fn = useContext(ConfirmContext);
  if (!fn) throw new Error("ConfirmProvider manquant");
  return fn;
}

/** Panneau latéral (fiche détaillée), fermé par Échap ou clic hors panneau. */
export function Drawer({ open, onClose, title, subtitle, avatar, children }: {
  open: boolean; onClose: () => void; title: string; subtitle?: string; avatar?: ReactNode; children: ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape" && !document.querySelector("dialog[open]")) onClose(); };
    document.addEventListener("keydown", onKey);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.removeEventListener("keydown", onKey); document.body.style.overflow = overflow; };
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50">
      <div className="animate-fade-in absolute inset-0 bg-overlay" onClick={onClose} aria-hidden />
      <aside role="dialog" aria-modal="true" aria-label={title} className="animate-slide-in absolute inset-y-0 right-0 flex w-[min(680px,100vw)] flex-col border-l border-line bg-page shadow-2xl">
        <header className="flex items-start justify-between gap-4 border-b border-line bg-raised px-6 py-5 max-sm:px-4">
          <div className="flex min-w-0 items-center gap-3.5">
            {avatar}
            <div className="min-w-0">
              <h2 className="truncate text-lg">{title}</h2>
              {subtitle && <p className="mt-0.5 text-sm text-fg-muted">{subtitle}</p>}
            </div>
          </div>
          <Button variant="ghost" onClick={onClose} aria-label="Fermer" icon={<X className="size-4.5" />} />
        </header>
        <div className="grid flex-1 content-start gap-4 overflow-y-auto px-6 pt-5 pb-8 max-sm:px-4">{children}</div>
      </aside>
    </div>
  );
}

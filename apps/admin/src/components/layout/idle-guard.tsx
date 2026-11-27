import { Clock } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useAuth } from "@/app/auth";
import { Button } from "@/components/ui/button";
import { IDLE_MS, IDLE_SIGNED_OUT, IDLE_WARNING_MS } from "@/lib/session";

const ACTIVITY = ["pointerdown", "keydown", "wheel", "touchstart"] as const;

/**
 * Déconnecte après une heure sans activité, avec un avertissement une minute
 * avant. Le temps écoulé est recalculé à chaque contrôle (et au retour sur
 * l'onglet), pour rester juste après une mise en veille de l'ordinateur.
 */
export function IdleGuard() {
  const { signOut } = useAuth();
  const last = useRef(0);
  const [warning, setWarning] = useState(false);

  useEffect(() => {
    last.current = Date.now();
    const touch = () => { last.current = Date.now(); setWarning(false); };
    const check = () => {
      const idle = Date.now() - last.current;
      if (idle >= IDLE_MS) void signOut(IDLE_SIGNED_OUT);
      else setWarning(idle >= IDLE_MS - IDLE_WARNING_MS);
    };
    for (const e of ACTIVITY) window.addEventListener(e, touch, { passive: true });
    document.addEventListener("visibilitychange", check);
    const timer = window.setInterval(check, 10_000);
    return () => {
      for (const e of ACTIVITY) window.removeEventListener(e, touch);
      document.removeEventListener("visibilitychange", check);
      window.clearInterval(timer);
    };
  }, [signOut]);

  if (!warning) return null;
  return (
    <div role="alertdialog" aria-labelledby="idle-title" className="fixed inset-x-4 bottom-4 z-50 mx-auto flex max-w-md items-center gap-3 rounded-xl border border-line bg-raised p-4 shadow-lg">
      <Clock className="size-5 shrink-0 text-warning" aria-hidden="true" />
      <p id="idle-title" className="flex-1 text-sm">Sans activité, vous serez déconnecté dans une minute.</p>
      <Button onClick={() => { last.current = Date.now(); setWarning(false); }}>Rester connecté</Button>
    </div>
  );
}

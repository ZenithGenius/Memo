import { ChevronRight, LogOut, Menu, Moon, Sun } from "lucide-react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { NavLink, useLocation } from "react-router";
import { useAuth, useSession } from "@/app/auth";
import { ROLE_LABEL } from "@/lib/roles";
import { cn } from "@/components/ui/cn";
import { NAV, titleFor } from "./nav";

function Brand() {
  return (
    <div className="flex items-center gap-2.5 px-1.5 py-1">
      <div className="grid size-8.5 place-items-center rounded-[0.6rem] bg-brand font-heading text-base font-bold text-white shadow-sm">M</div>
      <div className="leading-tight">
        <div className="font-heading text-[1.05rem] font-semibold text-fg">Memo</div>
        <div className="text-[0.68rem] tracking-[0.08em] text-fg-muted uppercase">Administration</div>
      </div>
    </div>
  );
}

function useTheme() {
  const [dark, setDark] = useState(() => document.documentElement.classList.contains("dark"));
  const toggle = () => {
    const next = !dark;
    document.documentElement.classList.toggle("dark", next);
    try { localStorage.setItem("memo-admin-theme", next ? "dark" : "light"); } catch { /* stockage indisponible */ }
    setDark(next);
  };
  return { dark, toggle };
}

export function Shell({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  const { signOut } = useAuth();
  const { session, role } = useSession();
  const { dark, toggle } = useTheme();
  const [navOpen, setNavOpen] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const email = session.user.email ?? "";

  useEffect(() => {
    const close = (e: MouseEvent) => { if (!menuRef.current?.contains(e.target as Node)) setMenuOpen(false); };
    document.addEventListener("click", close);
    return () => { document.removeEventListener("click", close); };
  }, []);

  const tbBtn = "inline-flex h-8.5 min-w-8.5 items-center justify-center gap-2 rounded-lg border border-white/25 bg-white/12 px-2 text-sm font-medium text-white transition-colors hover:border-white/40 hover:bg-white/20";

  return (
    <div className="flex min-h-screen">
      {navOpen && <div className="fixed inset-0 z-35 bg-overlay lg:hidden" onClick={() => { setNavOpen(false); }} aria-hidden />}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 flex w-64 flex-col gap-5 overflow-y-auto border-r border-line bg-muted-surface px-3 pt-3.5 pb-4 transition-transform duration-200",
          navOpen ? "translate-x-0 shadow-2xl" : "-translate-x-full lg:translate-x-0",
        )}
        aria-label="Navigation principale"
      >
        <Brand />
        {NAV.map((section) => (
          <nav key={section.title} aria-label={section.title}>
            <div className="mb-1.5 px-2 text-[0.7rem] font-semibold tracking-[0.08em] text-fg-muted uppercase">{section.title}</div>
            <div className="grid gap-1">
              {section.items.map(({ to, label, icon: Icon }) => (
                <NavLink
                  key={to}
                  to={to}
                  end={to === "/"}
                  onClick={() => { setNavOpen(false); }}
                  className={({ isActive }) =>
                    cn(
                      "flex min-h-10 items-center gap-2.5 rounded-lg border px-2.5 py-2 text-[0.92rem] font-medium transition-colors",
                      isActive
                        ? "border-accent-border bg-accent-muted text-accent-strong"
                        : "border-transparent text-fg-secondary hover:bg-subtle hover:text-accent-strong",
                    )
                  }
                >
                  <Icon className="size-4.5 shrink-0" />
                  {label}
                </NavLink>
              ))}
            </div>
          </nav>
        ))}
      </aside>

      <div className="flex min-w-0 flex-1 flex-col lg:ml-64">
        <header className="sticky top-0 z-30 flex min-h-14 items-center justify-between gap-4 border-b border-topbar-border bg-topbar px-6 text-white max-sm:px-4">
          <div className="flex min-w-0 items-center gap-3">
            <button type="button" className={cn(tbBtn, "lg:hidden")} onClick={() => { setNavOpen(true); }} aria-label="Ouvrir la navigation">
              <Menu className="size-4.5" />
            </button>
            <nav aria-label="Fil d'Ariane" className="flex items-center gap-1.5 text-sm whitespace-nowrap">
              <span className="text-white/70 max-sm:hidden">Memo</span>
              <ChevronRight className="size-3.5 text-white/60 max-sm:hidden" />
              <span className="truncate font-semibold">{titleFor(pathname)}</span>
            </nav>
          </div>
          <div className="flex items-center gap-2">
            <button type="button" className={tbBtn} onClick={toggle} aria-label={dark ? "Thème clair" : "Thème sombre"} title={dark ? "Thème clair" : "Thème sombre"}>
              {dark ? <Sun className="size-4.5" /> : <Moon className="size-4.5" />}
            </button>
            <div className="relative" ref={menuRef}>
              <button type="button" className={tbBtn} onClick={() => { setMenuOpen((o) => !o); }} aria-haspopup="menu" aria-expanded={menuOpen}>
                <span className="grid size-6 place-items-center rounded-full bg-white text-xs font-bold text-topbar">{(email[0] ?? "?").toUpperCase()}</span>
                <span className="max-sm:hidden">{email.split("@")[0]}</span>
              </button>
              {menuOpen && (
                <div role="menu" className="absolute top-[calc(100%+0.5rem)] right-0 w-64 rounded-xl border border-line bg-raised p-1.5 text-fg-secondary shadow-xl">
                  <div className="mb-1 border-b border-line-subtle px-2.5 pt-2 pb-2.5">
                    <div className="truncate text-sm font-semibold text-fg">{email}</div>
                    <div className="text-xs text-fg-muted">{ROLE_LABEL[role]}</div>
                  </div>
                  <button type="button" role="menuitem" onClick={() => void signOut()} className="flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-left text-sm text-danger hover:bg-danger-muted">
                    <LogOut className="size-4" /> Se déconnecter
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>
        <main className="page-glow flex-1 p-8 max-sm:px-4 max-sm:py-5">{children}</main>
      </div>
    </div>
  );
}

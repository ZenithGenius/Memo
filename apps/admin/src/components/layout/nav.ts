import { LayoutDashboard, Users } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface NavItem { to: string; label: string; icon: LucideIcon }
export interface NavSection { title: string; items: NavItem[] }

export const NAV: NavSection[] = [
  { title: "Pilotage", items: [{ to: "/", label: "Tableau de bord", icon: LayoutDashboard }] },
  {
    title: "Gestion",
    items: [
      { to: "/comptes", label: "Comptes", icon: Users },
    ],
  },
];

export const titleFor = (path: string): string =>
  NAV.flatMap((s) => s.items).find((i) => i.to === path)?.label ?? "Memo";

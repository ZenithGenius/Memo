import { Coins, FileClock, LayoutDashboard, ShieldCheck, Smartphone, Tags, Users } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export interface NavItem { to: string; label: string; icon: LucideIcon }
export interface NavSection { title: string; items: NavItem[] }

export const NAV: NavSection[] = [
  { title: "Pilotage", items: [{ to: "/", label: "Tableau de bord", icon: LayoutDashboard }] },
  {
    title: "Gestion",
    items: [
      { to: "/comptes", label: "Comptes", icon: Users },
      { to: "/abonnements", label: "Abonnements", icon: Coins },
      { to: "/offres", label: "Offres", icon: Tags },
      { to: "/appareils", label: "Appareils", icon: Smartphone },
    ],
  },
  {
    title: "Administration",
    items: [
      { to: "/administrateurs", label: "Administrateurs", icon: ShieldCheck },
      { to: "/journal", label: "Journal d'activité", icon: FileClock },
    ],
  },
];

export const titleFor = (path: string): string =>
  NAV.flatMap((s) => s.items).find((i) => i.to === path)?.label ?? "Memo";

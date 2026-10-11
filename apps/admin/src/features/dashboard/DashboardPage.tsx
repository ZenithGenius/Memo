import { useQuery } from "@tanstack/react-query";
import { BellRing, Coins, FileClock, RefreshCw, ShieldAlert, TrendingUp, UserMinus, UserPlus, Users, Wallet } from "lucide-react";
import { useState } from "react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useDb } from "@/app/db-context";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { PageHeader, StatCard } from "@/components/ui/page";
import { AccountDrawer, type AccountRef } from "@/features/accounts/AccountDrawer";
import { actorName, useAdminEmails } from "@/features/audit/api";
import { describe } from "@/lib/audit";
import type { AccountRow } from "@/lib/rpc-types";
import { dateFr, dateTimeFr, fcfa, monthLabel, percent } from "@/lib/format";
import { useDashboard, type Dashboard } from "./api";

export default function DashboardPage() {
  const dashboard = useDashboard();
  const [open, setOpen] = useState<AccountRef | null>(null);

  return (
    <>
      <PageHeader
        title="Tableau de bord"
        description="L'essentiel de l'activité : revenus encaissés, abonnés, fidélité, et ce qui demande une action."
        actions={
          <Button variant="secondary" icon={<RefreshCw className="size-4" />} loading={dashboard.isFetching} onClick={() => void dashboard.refetch()}>
            Actualiser
          </Button>
        }
      />
      {dashboard.isPending ? (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{Array.from({ length: 8 }, (_, i) => <Card key={i}><Skeleton rows={3} /></Card>)}</div>
      ) : dashboard.isError ? (
        <Card><ErrorPanel onRetry={() => void dashboard.refetch()} /></Card>
      ) : (
        <>
          <Kpis d={dashboard.data} />
          <div className="mt-4 grid gap-4 xl:grid-cols-3">
            <RevenueChart d={dashboard.data} />
            <Retention d={dashboard.data} />
          </div>
          <div className="mt-4 grid gap-4 xl:grid-cols-2">
            <Expiring onOpen={setOpen} />
            <RecentActivity />
          </div>
        </>
      )}
      <AccountDrawer account={open} onClose={() => { setOpen(null); }} />
    </>
  );
}

function Kpis({ d }: { d: Dashboard }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <StatCard label="Encaissé ce mois" value={fcfa(d.revenue_this_month_fcfa)} icon={<Coins className="size-4.5" />} color="green" hint="Paiements enregistrés" />
      <StatCard label="Abonnés actifs" value={d.active_subscribers} icon={<Users className="size-4.5" />} hint={`Revenu récurrent estimé : ${fcfa(d.mrr_fcfa)}`} />
      <StatCard label="Nouveaux abonnés" value={d.new_subscribers_this_month} icon={<UserPlus className="size-4.5" />} color="green" hint="Premier abonnement ce mois" />
      <StatCard label="Résiliations" value={d.cancellations_this_month} icon={<UserMinus className="size-4.5" />} color="amber" hint="Ce mois" />
      <StatCard label="Comptes créés" value={d.accounts_this_month} icon={<UserPlus className="size-4.5" />} hint={`${d.accounts_total} au total`} />
      <StatCard label="Taux de conversion" value={percent(d.ever_subscribed, d.accounts_total)} icon={<TrendingUp className="size-4.5" />} hint="Comptes déjà abonnés au moins une fois" />
      <StatCard label="Expirent sous 7 jours" value={d.expiring_7_days} icon={<BellRing className="size-4.5" />} color={d.expiring_7_days > 0 ? "amber" : "green"} hint="À relancer" />
      <StatCard label="Appareils à vérifier" value={d.integrity_alerts} icon={<ShieldAlert className="size-4.5" />} color={d.integrity_alerts > 0 ? "red" : "green"} hint="Intégrité douteuse" />
    </div>
  );
}

function RevenueChart({ d }: { d: Dashboard }) {
  const data = d.revenue_by_month.map((m) => ({ label: monthLabel(m.month), amount: m.amount_fcfa }));
  const year = d.revenue_by_month.reduce((s, m) => s + m.amount_fcfa, 0);
  return (
    <Card className="xl:col-span-2">
      <CardHeader title="Revenus encaissés par mois" icon={<Wallet className="size-4.5" />} aside={`12 mois : ${fcfa(year)}`} />
      <div className="h-72 p-4" role="img" aria-label={`Revenus des 12 derniers mois, total ${fcfa(year)}`}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            <CartesianGrid vertical={false} stroke="var(--border-subtle)" />
            <XAxis dataKey="label" tickLine={false} axisLine={false} tick={{ fill: "var(--fg-muted)", fontSize: 12 }} />
            <YAxis tickLine={false} axisLine={false} width={64} tick={{ fill: "var(--fg-muted)", fontSize: 12 }}
              tickFormatter={(v: number) => new Intl.NumberFormat("fr-FR", { notation: "compact" }).format(v)} />
            <Tooltip
              cursor={{ fill: "var(--accent-muted)" }}
              formatter={(v) => [fcfa(Number(v)), "Encaissé"]}
              contentStyle={{ background: "var(--surface-raised)", border: "1px solid var(--border)", borderRadius: 10, color: "var(--fg)" }}
            />
            <Bar dataKey="amount" fill="var(--accent)" radius={[6, 6, 0, 0]} maxBarSize={36} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}

function Retention({ d }: { d: Dashboard }) {
  const rows = d.retention ?? [];
  return (
    <Card>
      <CardHeader title="Fidélité des abonnés" icon={<TrendingUp className="size-4.5" />} />
      <div className="grid gap-5 p-5">
        <p className="text-sm text-fg-muted">Part des abonnés qui paient encore, parmi ceux abonnés depuis au moins…</p>
        {rows.map((r) => {
          const ratio = r.cohort === 0 ? 0 : r.retained / r.cohort;
          return (
            <div key={r.months}>
              <div className="mb-1.5 flex items-baseline justify-between text-sm">
                <span className="font-medium text-fg">{r.months} mois</span>
                <span className="text-fg-muted">
                  <span className="font-heading text-base font-semibold text-fg">{percent(r.retained, r.cohort)}</span> · {r.retained}/{r.cohort}
                </span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-subtle" aria-hidden>
                <div className="h-full rounded-full bg-accent" style={{ width: `${Math.round(ratio * 100)}%` }} />
              </div>
            </div>
          );
        })}
        {rows.every((r) => r.cohort === 0) && <p className="text-xs text-fg-muted">Pas encore assez d'historique : les premiers chiffres apparaîtront 3 mois après les premiers abonnements.</p>}
      </div>
    </Card>
  );
}

function Expiring({ onOpen }: { onOpen: (a: AccountRef) => void }) {
  const db = useDb();
  const expiring = useQuery({
    queryKey: ["accounts", "dashboard-expiring"],
    queryFn: async (): Promise<AccountRow[]> => {
      const { data, error } = await db.rpc("admin_accounts", { status: "expiring", lim: 8 });
      if (error) throw error;
      return data;
    },
  });
  return (
    <Card>
      <CardHeader title="À relancer : expirent sous 7 jours" icon={<BellRing className="size-4.5" />} />
      {expiring.isPending ? <Skeleton rows={4} /> : expiring.isError ? <ErrorPanel onRetry={() => void expiring.refetch()} /> : expiring.data.length === 0 ? (
        <EmptyState icon={<BellRing className="size-5" />} title="Rien à relancer" text="Aucun abonnement n'expire dans les 7 jours." />
      ) : (
        <ul className="divide-y divide-line-subtle">
          {expiring.data.map((a) => (
            <li key={a.user_id}>
              <button type="button" onClick={() => { onOpen({ userId: a.user_id, email: a.email }); }} className="flex w-full items-center justify-between gap-3 px-5 py-3 text-left hover:bg-muted-surface">
                <div className="min-w-0">
                  <div className="truncate font-semibold text-fg">{a.email}</div>
                  <div className="text-xs text-fg-muted">{a.phone ?? "Pas de téléphone"}</div>
                </div>
                <div className="flex shrink-0 items-center gap-2">
                  <Badge tone="warning">{a.plan_name ?? "Abonnement"}</Badge>
                  <span className="text-xs text-fg-muted">{dateFr(a.valid_until)}</span>
                </div>
              </button>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

function RecentActivity() {
  const db = useDb();
  const emails = useAdminEmails();
  const recent = useQuery({
    queryKey: ["audit", "dashboard-recent"],
    queryFn: async () => {
      const { data, error } = await db.from("audit_log").select("id, at, actor, action, entity, before, after").order("at", { ascending: false }).limit(8);
      if (error) throw error;
      return data;
    },
  });
  return (
    <Card>
      <CardHeader title="Activité récente" icon={<FileClock className="size-4.5" />} />
      {recent.isPending ? <Skeleton rows={4} /> : recent.isError ? <ErrorPanel onRetry={() => void recent.refetch()} /> : recent.data.length === 0 ? (
        <EmptyState icon={<FileClock className="size-5" />} title="Aucune activité" text="Les actions des administrateurs apparaîtront ici." />
      ) : (
        <ul className="divide-y divide-line-subtle">
          {recent.data.map((e) => (
            <li key={e.id} className="flex items-start justify-between gap-3 px-5 py-3 text-sm">
              <div className="min-w-0">
                <div className="text-fg">{describe(e)}</div>
                <div className="truncate text-xs text-fg-muted">{actorName(e.actor, emails.data)}</div>
              </div>
              <span className="shrink-0 text-xs text-fg-muted">{dateTimeFr(e.at)}</span>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

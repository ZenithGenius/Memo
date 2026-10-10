import { ChevronRight, Coins, Download, Receipt, Wallet } from "lucide-react";
import { useMemo, useState } from "react";
import { useDb } from "@/app/db-context";
import { useToast } from "@/app/toast";
import { Badge, Chip } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { Field, Select } from "@/components/ui/form";
import { SearchInput, Tabs } from "@/components/ui/filters";
import { PageHeader } from "@/components/ui/page";
import { AccountDrawer, type AccountRef } from "@/features/accounts/AccountDrawer";
import { useDebounced } from "@/hooks/use-debounced";
import { downloadCsv, toCsv } from "@/lib/csv";
import { report, userMessage } from "@/lib/errors";
import { dateFr, dateTimeFr, fcfa, toDateInput } from "@/lib/format";
import { PAYMENT_PERIOD_OPTIONS, paymentPeriodRange, type PaymentPeriod } from "@/lib/payment-period";
import { methodLabel } from "@/lib/payments";
import type { PaymentRow } from "@/lib/rpc-types";
import { usePayments, useSubscriptions, type SubscriptionFilter } from "./api";

const PAGE_SIZE = 25;
const EXPORT_LIMIT = 500;

type MainTab = "subscriptions" | "payments";

const MAIN_TABS: { value: MainTab; label: string }[] = [
  { value: "subscriptions", label: "Abonnements" },
  { value: "payments", label: "Paiements" },
];

const SUBSCRIPTION_FILTERS: { value: SubscriptionFilter; label: string }[] = [
  { value: "all", label: "Tous" },
  { value: "active", label: "En cours" },
  { value: "expiring", label: "Expirent bientôt" },
  { value: "expired", label: "Expirés" },
  { value: "revoked", label: "Résiliés" },
];

const SUBSCRIPTION_STATE = {
  active: { tone: "success" as const, label: "En cours" },
  expiring: { tone: "warning" as const, label: "Expire bientôt" },
  expired: { tone: "neutral" as const, label: "Expiré" },
  revoked: { tone: "danger" as const, label: "Résilié" },
};

const exportFilename = (prefix: string) => `${prefix}-${toDateInput(new Date())}.csv`;

export default function SubscriptionsPage() {
  const [mainTab, setMainTab] = useState<MainTab>("subscriptions");

  return (
    <>
      <PageHeader
        title="Abonnements et paiements"
        description="Parcourir les abonnements actifs ou passés et l'historique des paiements encaissés."
      />
      <div className="mb-4">
        <Tabs label="Vue" value={mainTab} onChange={setMainTab} options={MAIN_TABS} />
      </div>
      {mainTab === "subscriptions" ? <SubscriptionsTab /> : <PaymentsTab />}
    </>
  );
}

function SubscriptionsTab() {
  const db = useDb();
  const toast = useToast();
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<SubscriptionFilter>("all");
  const [page, setPage] = useState(0);
  const [open, setOpen] = useState<AccountRef | null>(null);
  const [exporting, setExporting] = useState(false);
  const query = useDebounced(search.trim());
  const subs = useSubscriptions(query, filter, page, PAGE_SIZE);

  const exportCsv = async () => {
    setExporting(true);
    try {
      const { data, error } = await db.rpc("admin_subscriptions", {
        query,
        status: filter,
        lim: EXPORT_LIMIT,
        off: 0,
      });
      if (error) throw error;
      const rows = data;
      const csv = toCsv(
        ["Compte", "Offre", "Début", "Fin", "État"],
        rows.map((r) => [
          r.email,
          r.plan_name,
          dateFr(r.starts_at),
          dateFr(r.valid_until),
          subscriptionStateLabel(r.state),
        ]),
      );
      downloadCsv(exportFilename("memo-abonnements"), csv);
    } catch (e) {
      report("export abonnements", e);
      toast(userMessage(e, "L'export n'a pas pu être généré."), "error");
    } finally {
      setExporting(false);
    }
  };

  return (
    <>
      <div className="mb-4 flex flex-col gap-3 xl:flex-row xl:items-end xl:justify-between">
        <div className="flex flex-col gap-3 xl:flex-row xl:items-center">
          <SearchInput
            label="Rechercher un abonnement"
            placeholder="E-mail du compte…"
            value={search}
            onChange={(v) => { setSearch(v); setPage(0); }}
          />
          <Tabs
            label="État"
            value={filter}
            onChange={(v) => { setFilter(v); setPage(0); }}
            options={SUBSCRIPTION_FILTERS}
          />
        </div>
        <Button variant="secondary" icon={<Download className="size-4" />} loading={exporting} onClick={() => void exportCsv()}>
          Exporter (CSV)
        </Button>
      </div>
      <Card>
        {subs.isPending ? (
          <Skeleton rows={8} />
        ) : subs.isError ? (
          <ErrorPanel onRetry={() => void subs.refetch()} />
        ) : subs.data.rows.length === 0 ? (
          <EmptyState
            icon={<Wallet className="size-5" />}
            title={query ? "Aucun abonnement trouvé" : "Aucun abonnement"}
            text={query ? "Essayez un autre e-mail." : undefined}
          />
        ) : (
          <>
            <DataTable
              rows={subs.data.rows}
              rowKey={(r) => r.id}
              rowLabel={(r) => `Ouvrir la fiche de ${r.email}`}
              onRowClick={(r) => { setOpen({ userId: r.user_id, email: r.email }); }}
              columns={[
                {
                  key: "account",
                  header: "Compte",
                  primary: true,
                  cell: (r) => <span className="font-semibold break-all text-fg">{r.email}</span>,
                },
                { key: "plan", header: "Offre", cell: (r) => r.plan_name },
                { key: "start", header: "Début", cell: (r) => dateFr(r.starts_at) },
                { key: "end", header: "Fin", cell: (r) => dateFr(r.valid_until) },
                {
                  key: "state",
                  header: "État",
                  cell: (r) => {
                    const s = subscriptionStateMeta(r.state);
                    return <Badge tone={s.tone}>{s.label}</Badge>;
                  },
                },
                {
                  key: "go",
                  header: "",
                  desktopOnly: true,
                  align: "right",
                  cell: () => <ChevronRight className="ml-auto size-4 text-fg-muted" />,
                },
              ]}
            />
            <Pagination page={page} pageSize={PAGE_SIZE} total={subs.data.total} onPage={setPage} />
          </>
        )}
      </Card>
      <AccountDrawer account={open} onClose={() => { setOpen(null); }} />
    </>
  );
}

function PaymentsTab() {
  const db = useDb();
  const toast = useToast();
  const [search, setSearch] = useState("");
  const [period, setPeriod] = useState<PaymentPeriod>("this_month");
  const [page, setPage] = useState(0);
  const [open, setOpen] = useState<AccountRef | null>(null);
  const [exporting, setExporting] = useState(false);
  const query = useDebounced(search.trim());
  const range = useMemo(() => paymentPeriodRange(period), [period]);
  const payments = usePayments(query, range.since, range.until, page, PAGE_SIZE);

  const exportCsv = async () => {
    setExporting(true);
    try {
      const { data, error } = await db.rpc("admin_payments", {
        query,
        since: range.since,
        until: range.until,
        lim: EXPORT_LIMIT,
        off: 0,
      });
      if (error) throw error;
      const rows: PaymentRow[] = data;
      const csv = toCsv(
        ["Date", "Compte", "Montant (FCFA)", "Moyen", "Référence", "Offre", "Saisi par"],
        rows.map((r: PaymentRow) => [
          dateTimeFr(r.paid_at),
          r.email,
          r.amount_fcfa,
          methodLabel(r.method),
          r.reference ?? "",
          r.plan_name ?? "",
          r.recorded_by_email ?? "Système",
        ]),
      );
      downloadCsv(exportFilename("memo-paiements"), csv);
    } catch (e) {
      report("export paiements", e);
      toast(userMessage(e, "L'export n'a pas pu être généré."), "error");
    } finally {
      setExporting(false);
    }
  };

  const totalAside =
    payments.data && payments.data.rows.length > 0
      ? `Total encaissé : ${fcfa(payments.data.totalAmountFcfa)}`
      : undefined;

  return (
    <>
      <div className="mb-4 flex flex-col gap-3 xl:flex-row xl:items-end xl:justify-between">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
          <SearchInput
            label="Rechercher un paiement"
            placeholder="E-mail ou référence…"
            value={search}
            onChange={(v) => { setSearch(v); setPage(0); }}
          />
          <Field label="Période" htmlFor="payments-period" className="w-full sm:w-48">
            <Select
              id="payments-period"
              value={period}
              onChange={(e) => { setPeriod(e.target.value as PaymentPeriod); setPage(0); }}
            >
              {PAYMENT_PERIOD_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </Select>
          </Field>
        </div>
        <Button variant="secondary" icon={<Download className="size-4" />} loading={exporting} onClick={() => void exportCsv()}>
          Exporter (CSV)
        </Button>
      </div>
      <Card>
        <CardHeader title="Paiements enregistrés" icon={<Receipt className="size-4.5" />} aside={totalAside} />
        {payments.isPending ? (
          <Skeleton rows={8} />
        ) : payments.isError ? (
          <ErrorPanel onRetry={() => void payments.refetch()} />
        ) : payments.data.rows.length === 0 ? (
          <EmptyState
            icon={<Coins className="size-5" />}
            title={query ? "Aucun paiement trouvé" : "Aucun paiement"}
            text={query ? "Essayez un autre e-mail ou une autre référence." : "Aucun paiement sur la période choisie."}
          />
        ) : (
          <>
            <DataTable
              rows={payments.data.rows}
              rowKey={(r) => r.id}
              rowLabel={(r) => `Ouvrir la fiche de ${r.email}`}
              onRowClick={(r) => { setOpen({ userId: r.user_id, email: r.email }); }}
              columns={[
                {
                  key: "date",
                  header: "Date",
                  primary: true,
                  cell: (r) => <span className="font-semibold text-fg">{dateTimeFr(r.paid_at)}</span>,
                },
                { key: "account", header: "Compte", cell: (r) => <span className="break-all">{r.email}</span> },
                { key: "amount", header: "Montant", cell: (r) => fcfa(r.amount_fcfa) },
                { key: "method", header: "Moyen", cell: (r) => <Chip>{methodLabel(r.method)}</Chip> },
                {
                  key: "ref",
                  header: "Référence",
                  cell: (r) => (
                    r.reference
                      ? <span className="font-mono text-xs">{r.reference}</span>
                      : <span className="text-fg-muted">—</span>
                  ),
                },
                {
                  key: "plan",
                  header: "Offre",
                  cell: (r) => r.plan_name ?? <span className="text-fg-muted">—</span>,
                },
                {
                  key: "recorded",
                  header: "Saisi par",
                  cell: (r) => r.recorded_by_email ?? "Système",
                },
              ]}
            />
            <Pagination page={page} pageSize={PAGE_SIZE} total={payments.data.total} onPage={setPage} />
          </>
        )}
      </Card>
      <AccountDrawer account={open} onClose={() => { setOpen(null); }} />
    </>
  );
}

function subscriptionStateMeta(state: string) {
  return (SUBSCRIPTION_STATE as Record<string, (typeof SUBSCRIPTION_STATE)[keyof typeof SUBSCRIPTION_STATE] | undefined>)[state]
    ?? { tone: "neutral" as const, label: state };
}

function subscriptionStateLabel(state: string): string {
  return subscriptionStateMeta(state).label;
}

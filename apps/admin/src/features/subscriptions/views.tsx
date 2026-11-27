// Vues des abonnements et paiements : affichage seul, à partir des contrôleurs.
import { ChevronRight, Coins, Download, Wallet } from "lucide-react";
import { Badge, Chip } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { FilterSelect, ListToolbar, ResultSummary, SearchInput } from "@/components/ui/filters";
import { ListBody } from "@/components/ui/list-body";
import { AccountDrawer } from "@/features/accounts/AccountDrawer";
import { dateFr, dateTimeFr, fcfa } from "@/lib/format";
import { PAYMENT_PERIOD_OPTIONS } from "@/lib/payment-period";
import { methodLabel } from "@/lib/payments";
import type { PaymentsList, SubscriptionsList } from "./controllers";
import { DELETED_ACCOUNT, PAGE_SIZE, SUBSCRIPTION_STATES, subscriptionState } from "./model";

function ExportButton({ exporter }: { exporter: { exporting: boolean; run: () => Promise<void> } }) {
  return (
    <Button variant="secondary" icon={<Download className="size-4" />} loading={exporter.exporting} onClick={() => void exporter.run()}>
      Exporter (CSV)
    </Button>
  );
}

const muted = (text = "—") => <span className="text-fg-muted">{text}</span>;

export function SubscriptionsView({ c }: { c: SubscriptionsList }) {
  const { filters, list } = c;
  return (
    <>
      <ListToolbar
        search={<SearchInput label="Rechercher" placeholder="E-mail du compte" value={filters.values.q} onChange={(q) => { filters.set({ q }); }} />}
        filters={<FilterSelect label="État" value={filters.values.etat} defaultValue="all" options={SUBSCRIPTION_STATES} onChange={(etat) => { filters.set({ etat }); }} />}
        actions={<ExportButton exporter={c.exporter} />}
      />
      <ResultSummary shown={list.data?.total ?? 0} unit={["abonnement", "abonnements"]} active={filters.active} onReset={filters.reset} />
      <Card>
        <ListBody
          query={list}
          isEmpty={(d) => d.rows.length === 0}
          empty={{ icon: <Wallet className="size-5" />, title: "Aucun abonnement", text: filters.active ? "Aucun abonnement ne correspond à ces filtres." : undefined }}
        >
          {(d) => (
            <>
              <DataTable
                rows={d.rows}
                rowKey={(r) => r.id}
                rowLabel={(r) => `Ouvrir la fiche de ${r.email}`}
                onRowClick={(r) => { c.setAccount({ userId: r.user_id, email: r.email }); }}
                columns={[
                  { key: "account", header: "Compte", primary: true, cell: (r) => <span className="font-semibold break-all text-fg">{r.email}</span> },
                  { key: "plan", header: "Offre", cell: (r) => r.plan_name },
                  { key: "start", header: "Début", cell: (r) => dateFr(r.starts_at) },
                  { key: "end", header: "Fin", cell: (r) => dateFr(r.valid_until) },
                  { key: "state", header: "État", cell: (r) => { const s = subscriptionState(r.state); return <Badge tone={s.tone}>{s.label}</Badge>; } },
                  { key: "go", header: "", desktopOnly: true, align: "right", cell: () => <ChevronRight className="ml-auto size-4 text-fg-muted" /> },
                ]}
              />
              <Pagination page={filters.page} pageSize={PAGE_SIZE} total={d.total} onPage={filters.setPage} />
            </>
          )}
        </ListBody>
      </Card>
      <AccountDrawer account={c.account} onClose={() => { c.setAccount(null); }} />
    </>
  );
}

export function PaymentsView({ c }: { c: PaymentsList }) {
  const { filters, list } = c;
  return (
    <>
      <ListToolbar
        search={<SearchInput label="Rechercher" placeholder="E-mail ou référence" value={filters.values.q} onChange={(q) => { filters.set({ q }); }} />}
        filters={<FilterSelect label="Période" value={filters.values.periode} defaultValue="this_month" options={PAYMENT_PERIOD_OPTIONS} onChange={(periode) => { filters.set({ periode }); }} />}
        actions={<ExportButton exporter={c.exporter} />}
      />
      <div className="flex flex-wrap items-baseline justify-between gap-3">
        <ResultSummary shown={list.data?.total ?? 0} unit={["paiement", "paiements"]} active={filters.active} onReset={filters.reset} />
        {list.data && list.data.rows.length > 0 && (
          <p className="mb-3 text-sm text-fg-muted">Total encaissé : <strong className="font-semibold text-fg">{fcfa(list.data.totalAmountFcfa)}</strong></p>
        )}
      </div>
      <Card>
        <ListBody
          query={list}
          isEmpty={(d) => d.rows.length === 0}
          empty={{ icon: <Coins className="size-5" />, title: "Aucun paiement", text: "Aucun paiement ne correspond à ces filtres." }}
        >
          {(d) => (
            <>
              <DataTable
                rows={d.rows}
                rowKey={(r) => r.id}
                rowLabel={(r) => (r.email ? `Ouvrir la fiche de ${r.email}` : DELETED_ACCOUNT)}
                onRowClick={(r) => { if (r.user_id && r.email) c.setAccount({ userId: r.user_id, email: r.email }); }}
                columns={[
                  { key: "date", header: "Date", primary: true, cell: (r) => <span className="font-semibold text-fg">{dateTimeFr(r.paid_at)}</span> },
                  { key: "account", header: "Compte", cell: (r) => <span className="break-all">{r.email ?? DELETED_ACCOUNT}</span> },
                  { key: "amount", header: "Montant", align: "right", cell: (r) => fcfa(r.amount_fcfa) },
                  { key: "method", header: "Moyen", cell: (r) => <Chip>{methodLabel(r.method)}</Chip> },
                  { key: "ref", header: "Référence", cell: (r) => (r.reference ? <span className="font-mono text-xs">{r.reference}</span> : muted()) },
                  { key: "plan", header: "Offre", cell: (r) => r.plan_name ?? muted() },
                  { key: "recorded", header: "Saisi par", cell: (r) => r.recorded_by_email ?? "Système" },
                ]}
              />
              <Pagination page={filters.page} pageSize={PAGE_SIZE} total={d.total} onPage={filters.setPage} />
            </>
          )}
        </ListBody>
      </Card>
      <AccountDrawer account={c.account} onClose={() => { c.setAccount(null); }} />
    </>
  );
}

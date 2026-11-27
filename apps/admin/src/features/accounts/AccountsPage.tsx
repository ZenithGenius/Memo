import { ChevronRight, Users } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { FilterSelect, ListToolbar, ResultSummary, SearchInput } from "@/components/ui/filters";
import { ListBody } from "@/components/ui/list-body";
import { PageHeader } from "@/components/ui/page";
import { dateFr } from "@/lib/format";
import { SITUATION, type Situation } from "@/lib/payments";
import { AccountDrawer } from "./AccountDrawer";
import { useAccountsList, type AccountsList } from "./controllers";
import { ACCOUNT_SITUATIONS, PAGE_SIZE } from "./model";

export default function AccountsPage() {
  return <AccountsView c={useAccountsList()} />;
}

export function AccountsView({ c }: { c: AccountsList }) {
  const { filters, list } = c;
  return (
    <>
      <PageHeader title="Comptes" description="Rechercher un compte, voir sa situation, gérer ses abonnements, paiements et appareils." />
      <ListToolbar
        search={<SearchInput label="Rechercher" placeholder="E-mail, téléphone ou nom" value={filters.values.q} onChange={(q) => { filters.set({ q }); }} />}
        filters={<FilterSelect label="Situation" value={filters.values.situation} defaultValue="all" options={ACCOUNT_SITUATIONS} onChange={(situation) => { filters.set({ situation }); }} />}
      />
      <ResultSummary shown={list.data?.total ?? 0} unit={["compte", "comptes"]} active={filters.active} onReset={filters.reset} />
      <Card>
        <ListBody
          query={list}
          isEmpty={(d) => d.rows.length === 0}
          empty={{ icon: <Users className="size-5" />, title: "Aucun compte", text: filters.active ? "Aucun compte ne correspond à ces filtres." : undefined }}
        >
          {(d) => (
            <>
              <DataTable
                rows={d.rows}
                rowKey={(a) => a.user_id}
                rowLabel={(a) => `Ouvrir la fiche de ${a.email}`}
                onRowClick={(a) => { c.setAccount({ userId: a.user_id, email: a.email }); }}
                columns={[
                  { key: "account", header: "Compte", primary: true, cell: (a) => (
                    <div className="min-w-0">
                      <div className="font-semibold break-all text-fg">{a.email}</div>
                      <div className="text-xs text-fg-muted">{a.display_name ?? "Sans nom"}</div>
                    </div>
                  ) },
                  { key: "phone", header: "Téléphone", cell: (a) => a.phone ?? <span className="text-fg-muted">—</span> },
                  { key: "situation", header: "Situation", cell: (a) => {
                    const s = SITUATION[a.situation as Situation];
                    return (
                      <div className="flex flex-wrap items-center justify-end gap-x-2 md:justify-start">
                        <Badge tone={s.tone}>{a.plan_name && a.situation !== "free" ? a.plan_name : s.label}</Badge>
                        {a.valid_until && <span className="text-xs text-fg-muted">{a.situation === "expired" ? "fini le" : "jusqu'au"} {dateFr(a.valid_until)}</span>}
                      </div>
                    );
                  } },
                  { key: "devices", header: "Appareils", align: "right", cell: (a) => a.active_devices },
                  { key: "created", header: "Inscrit le", cell: (a) => dateFr(a.created_at) },
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

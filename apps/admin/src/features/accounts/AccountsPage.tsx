import { ChevronRight, Users } from "lucide-react";
import { useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { SearchInput, Tabs } from "@/components/ui/filters";
import { PageHeader } from "@/components/ui/page";
import { useDebounced } from "@/hooks/use-debounced";
import { dateFr } from "@/lib/format";
import { SITUATION, type Situation } from "@/lib/payments";
import { AccountDrawer, type AccountRef } from "./AccountDrawer";
import { useAccounts, type AccountFilter } from "./api";

const PAGE_SIZE = 25;
const FILTERS: { value: AccountFilter; label: string }[] = [
  { value: "all", label: "Tous" },
  { value: "active", label: "Abonnés" },
  { value: "expiring", label: "Expirent bientôt" },
  { value: "expired", label: "Expirés" },
  { value: "free", label: "Gratuits" },
];

export default function AccountsPage() {
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<AccountFilter>("all");
  const [page, setPage] = useState(0);
  const [open, setOpen] = useState<AccountRef | null>(null);
  const query = useDebounced(search.trim());
  const accounts = useAccounts(query, filter, page, PAGE_SIZE);

  return (
    <>
      <PageHeader title="Comptes" description="Rechercher un compte, voir sa situation, gérer ses abonnements, paiements et appareils." />
      <div className="mb-4 flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <SearchInput label="Rechercher un compte" placeholder="E-mail, téléphone ou nom…" value={search} onChange={(v) => { setSearch(v); setPage(0); }} />
        <Tabs label="Situation" value={filter} onChange={(v) => { setFilter(v); setPage(0); }} options={FILTERS} />
      </div>
      <Card>
        {accounts.isPending ? (
          <Skeleton rows={8} />
        ) : accounts.isError ? (
          <ErrorPanel onRetry={() => void accounts.refetch()} />
        ) : accounts.data.rows.length === 0 ? (
          <EmptyState icon={<Users className="size-5" />} title={query ? "Aucun compte trouvé" : "Aucun compte"} text={query ? "Essayez un autre e-mail, numéro ou nom." : undefined} />
        ) : (
          <>
            <DataTable
              rows={accounts.data.rows}
              rowKey={(a) => a.user_id}
              rowLabel={(a) => `Ouvrir la fiche de ${a.email}`}
              onRowClick={(a) => { setOpen({ userId: a.user_id, email: a.email }); }}
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
                { key: "devices", header: "Appareils", cell: (a) => a.active_devices },
                { key: "created", header: "Inscrit le", cell: (a) => dateFr(a.created_at) },
                { key: "go", header: "", desktopOnly: true, align: "right", cell: () => <ChevronRight className="ml-auto size-4 text-fg-muted" /> },
              ]}
            />
            <Pagination page={page} pageSize={PAGE_SIZE} total={accounts.data.total} onPage={setPage} />
          </>
        )}
      </Card>
      <AccountDrawer account={open} onClose={() => { setOpen(null); }} />
    </>
  );
}

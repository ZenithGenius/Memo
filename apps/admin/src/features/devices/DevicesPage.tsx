import { Smartphone } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { FilterSelect, ListToolbar, ResultSummary, SearchInput } from "@/components/ui/filters";
import { ListBody } from "@/components/ui/list-body";
import { PageHeader } from "@/components/ui/page";
import { AccountDrawer, IntegrityBadge } from "@/features/accounts/AccountDrawer";
import { dateFr } from "@/lib/format";
import { useDevicesList, type DevicesList } from "./controllers";
import { DEVICE_SCOPES, PAGE_SIZE } from "./model";

export default function DevicesPage() {
  return <DevicesView c={useDevicesList()} />;
}

export function DevicesView({ c }: { c: DevicesList }) {
  const { filters, list } = c;
  return (
    <>
      <PageHeader title="Appareils" description="Appareils enregistrés par les comptes : intégrité, dernière activité et révocation." />
      <ListToolbar
        search={<SearchInput label="Rechercher" placeholder="E-mail du compte" value={filters.values.q} onChange={(q) => { filters.set({ q }); }} />}
        filters={<FilterSelect label="Statut" value={filters.values.statut} defaultValue="all" options={DEVICE_SCOPES} onChange={(statut) => { filters.set({ statut }); }} />}
      />
      <ResultSummary shown={list.data?.total ?? 0} unit={["appareil", "appareils"]} active={filters.active} onReset={filters.reset} />
      <Card>
        <ListBody
          query={list}
          isEmpty={(d) => d.rows.length === 0}
          empty={{
            icon: <Smartphone className="size-5" />,
            title: "Aucun appareil",
            text: filters.active ? "Aucun appareil ne correspond à ces filtres." : "Un appareil apparaît ici dès qu'un compte se connecte depuis l'application.",
          }}
        >
          {(d) => (
            <>
              <DataTable
                rows={d.rows}
                rowKey={(r) => r.id}
                columns={[
                  { key: "device", header: "Appareil", primary: true, cell: (r) => (
                    <div>
                      <div className="font-semibold text-fg">{r.label ?? r.platform}</div>
                      {r.installed_from_store === false && <div className="text-xs text-fg-muted">Installé hors boutique</div>}
                    </div>
                  ) },
                  { key: "account", header: "Compte", cell: (r) => (
                    <button type="button" className="break-all text-left font-medium text-accent-strong hover:underline" onClick={() => { c.setAccount({ userId: r.user_id, email: r.email }); }}>
                      {r.email}
                    </button>
                  ) },
                  { key: "integrity", header: "Intégrité", cell: (r) => <IntegrityBadge level={r.integrity_level} /> },
                  { key: "seen", header: "Vu le", cell: (r) => dateFr(r.last_seen) },
                  { key: "status", header: "Statut", cell: (r) => (r.revoked_at ? <Badge tone="danger">Révoqué</Badge> : <Badge tone="success">Actif</Badge>) },
                  { key: "action", header: "", align: "right", cell: (r) => c.writable && (
                    <Button size="sm" variant={r.revoked_at ? "soft-accent" : "soft-danger"} onClick={(e) => { e.stopPropagation(); void c.toggleRevoked(r); }}>
                      {r.revoked_at ? "Rétablir" : "Révoquer"}
                    </Button>
                  ) },
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

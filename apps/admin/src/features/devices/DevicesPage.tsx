import { Smartphone } from "lucide-react";
import { useState } from "react";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { SearchInput, Tabs } from "@/components/ui/filters";
import { PageHeader } from "@/components/ui/page";
import { useConfirm } from "@/components/ui/overlay";
import { AccountDrawer, IntegrityBadge, type AccountRef } from "@/features/accounts/AccountDrawer";
import { useSetDeviceRevoked } from "@/features/accounts/api";
import { useDebounced } from "@/hooks/use-debounced";
import { report, userMessage } from "@/lib/errors";
import { dateFr } from "@/lib/format";
import { canWrite } from "@/lib/roles";
import { useDevices, type DeviceScope } from "./api";

const PAGE_SIZE = 25;

const SCOPES: { value: DeviceScope; label: string }[] = [
  { value: "all", label: "Tous" },
  { value: "active", label: "Actifs" },
  { value: "alerts", label: "À vérifier" },
  { value: "revoked", label: "Révoqués" },
];

export default function DevicesPage() {
  const { role } = useSession();
  const writable = canWrite(role);
  const toast = useToast();
  const confirm = useConfirm();
  const setRevoked = useSetDeviceRevoked();
  const [search, setSearch] = useState("");
  const [scope, setScope] = useState<DeviceScope>("all");
  const [page, setPage] = useState(0);
  const [open, setOpen] = useState<AccountRef | null>(null);
  const query = useDebounced(search.trim());
  const devices = useDevices(query, scope, page, PAGE_SIZE);

  const toggleRevoked = async (d: { id: string; revoked_at: string | null; label: string | null; platform: string }) => {
    const revoke = !d.revoked_at;
    if (revoke && !(await confirm({
      title: "Révoquer cet appareil ?",
      text: "Il ne pourra plus recevoir de jeton ni télécharger le contenu payant. Vous pourrez le rétablir.",
      confirmLabel: "Révoquer",
    }))) return;
    try {
      await setRevoked.mutateAsync({ id: d.id, revoked: revoke });
      toast(revoke ? "Appareil révoqué." : "Appareil rétabli.");
    } catch (e) {
      report("appareil", e);
      toast(userMessage(e, "L'action sur l'appareil a échoué."), "error");
    }
  };

  return (
    <>
      <PageHeader
        title="Appareils"
        description="Appareils enregistrés par les comptes : intégrité, dernière activité et révocation."
      />
      <div className="mb-4 flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <SearchInput
          label="Rechercher un appareil"
          placeholder="E-mail du compte…"
          value={search}
          onChange={(v) => { setSearch(v); setPage(0); }}
        />
        <Tabs label="Périmètre" value={scope} onChange={(v) => { setScope(v); setPage(0); }} options={SCOPES} />
      </div>
      <Card>
        {devices.isPending ? (
          <Skeleton rows={8} />
        ) : devices.isError ? (
          <ErrorPanel onRetry={() => void devices.refetch()} />
        ) : devices.data.rows.length === 0 ? (
          <EmptyState
            icon={<Smartphone className="size-5" />}
            title={query ? "Aucun appareil trouvé" : "Aucun appareil"}
            text={query ? "Essayez un autre e-mail." : undefined}
          />
        ) : (
          <>
            <DataTable
              rows={devices.data.rows}
              rowKey={(d) => d.id}
              columns={[
                {
                  key: "device",
                  header: "Appareil",
                  primary: true,
                  cell: (d) => (
                    <div>
                      <div className="font-semibold text-fg">{d.label ?? d.platform}</div>
                      {d.installed_from_store === false && (
                        <div className="text-xs text-fg-muted">Installé hors boutique</div>
                      )}
                    </div>
                  ),
                },
                {
                  key: "account",
                  header: "Compte",
                  cell: (d) => (
                    <button
                      type="button"
                      className="break-all text-left font-medium text-accent-strong hover:underline"
                      onClick={() => { setOpen({ userId: d.user_id, email: d.email }); }}
                    >
                      {d.email}
                    </button>
                  ),
                },
                { key: "integrity", header: "Intégrité", cell: (d) => <IntegrityBadge level={d.integrity_level} /> },
                { key: "seen", header: "Vu le", cell: (d) => dateFr(d.last_seen) },
                {
                  key: "status",
                  header: "Statut",
                  cell: (d) => (
                    d.revoked_at
                      ? <Badge tone="danger">Révoqué</Badge>
                      : <Badge tone="success">Actif</Badge>
                  ),
                },
                {
                  key: "action",
                  header: "",
                  align: "right",
                  cell: (d) => writable && (
                    <Button
                      size="sm"
                      variant={d.revoked_at ? "soft-accent" : "soft-danger"}
                      onClick={(e) => {
                        e.stopPropagation();
                        void toggleRevoked(d);
                      }}
                    >
                      {d.revoked_at ? "Rétablir" : "Révoquer"}
                    </Button>
                  ),
                },
              ]}
            />
            <Pagination page={page} pageSize={PAGE_SIZE} total={devices.data.total} onPage={setPage} />
          </>
        )}
      </Card>
      <AccountDrawer account={open} onClose={() => { setOpen(null); }} />
    </>
  );
}

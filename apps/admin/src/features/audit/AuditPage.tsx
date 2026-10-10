import { FileClock } from "lucide-react";
import { useState } from "react";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { Tabs } from "@/components/ui/filters";
import { PageHeader } from "@/components/ui/page";
import { describe, humanChanges } from "@/lib/audit";
import { dateTimeFr } from "@/lib/format";
import { actorName, useAdminEmails, useAudit } from "./api";

const PAGE_SIZE = 25;

type EntityFilter = "all" | "subscriptions" | "payments" | "plans" | "devices" | "admins" | "accounts";

const ENTITY_TABS: { value: EntityFilter; label: string }[] = [
  { value: "all", label: "Tout" },
  { value: "subscriptions", label: "Abonnements" },
  { value: "payments", label: "Paiements" },
  { value: "plans", label: "Offres" },
  { value: "devices", label: "Appareils" },
  { value: "admins", label: "Administrateurs" },
  { value: "accounts", label: "Fiches compte" },
];

export default function AuditPage() {
  const [entity, setEntity] = useState<EntityFilter>("all");
  const [page, setPage] = useState(0);
  const emails = useAdminEmails();
  const audit = useAudit({ entity, page, pageSize: PAGE_SIZE });

  return (
    <>
      <PageHeader title="Journal d'activité" description="Historique des actions des administrateurs sur abonnements, paiements, offres et comptes." />
      <div className="mb-4 flex justify-end">
        <Tabs label="Type d'événement" value={entity} onChange={(v) => { setEntity(v); setPage(0); }} options={ENTITY_TABS} />
      </div>
      <Card>
        {audit.isPending ? (
          <Skeleton rows={8} />
        ) : audit.isError ? (
          <ErrorPanel onRetry={() => void audit.refetch()} />
        ) : audit.data.rows.length === 0 ? (
          <EmptyState icon={<FileClock className="size-5" />} title="Aucune entrée" text="Les actions apparaîtront ici au fil du temps." />
        ) : (
          <>
            <DataTable
              rows={audit.data.rows}
              rowKey={(e) => String(e.id)}
              columns={[
                {
                  key: "at",
                  header: "Quand",
                  primary: true,
                  cell: (e) => <span className="font-medium text-fg">{dateTimeFr(e.at)}</span>,
                },
                { key: "action", header: "Action", cell: (e) => describe(e) },
                { key: "actor", header: "Par", cell: (e) => actorName(e.actor, emails.data) },
                {
                  key: "details",
                  header: "Détails",
                  cell: (e) => {
                    const changes = humanChanges(e, (id) => actorName(id, emails.data));
                    return (
                      <details className="text-sm">
                        <summary className="cursor-pointer text-accent-strong hover:underline">Détails</summary>
                        {changes.length === 0 ? (
                          <p className="mt-2 text-xs text-fg-muted">Aucun détail à afficher.</p>
                        ) : (
                          <dl className="mt-2 grid gap-1 text-xs">
                            {changes.map((c) => (
                              <div key={c.label} className="flex flex-wrap gap-x-1.5">
                                <dt className="font-semibold text-fg">{c.label} :</dt>
                                <dd className="break-words text-fg-secondary">
                                  {c.before !== undefined && <><span className="text-fg-muted line-through">{c.before}</span>{" → "}</>}
                                  {c.after}
                                </dd>
                              </div>
                            ))}
                          </dl>
                        )}
                      </details>
                    );
                  },
                },
              ]}
            />
            <Pagination page={page} pageSize={PAGE_SIZE} total={audit.data.total} onPage={setPage} />
          </>
        )}
      </Card>
    </>
  );
}

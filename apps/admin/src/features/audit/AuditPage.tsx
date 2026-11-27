import { FileClock } from "lucide-react";
import { Card } from "@/components/ui/card";
import { DataTable, Pagination } from "@/components/ui/data-table";
import { FilterSelect, ListToolbar, ResultSummary } from "@/components/ui/filters";
import { ListBody } from "@/components/ui/list-body";
import { PageHeader } from "@/components/ui/page";
import { useListFilters } from "@/hooks/use-list-filters";
import { describe, humanChanges, type AuditEntry } from "@/lib/audit";
import { dateTimeFr } from "@/lib/format";
import { actorName, useAdminEmails, useAudit } from "./api";
import { AUDIT_ENTITIES, AUDIT_FILTERS, PAGE_SIZE } from "./model";

/** Contrôleur : type d'événement (dans l'adresse), page, noms des auteurs. */
function useAuditList() {
  const filters = useListFilters(AUDIT_FILTERS);
  const audit = useAudit({ entity: filters.values.type, page: filters.page, pageSize: PAGE_SIZE });
  const emails = useAdminEmails();
  const author = (id: string | null) => actorName(id, emails.data);
  return { filters, audit, author };
}

export default function AuditPage() {
  const { filters, audit, author } = useAuditList();
  return (
    <>
      <PageHeader title="Journal d'activité" description="Historique des actions des administrateurs sur abonnements, paiements, offres et comptes." />
      <ListToolbar
        filters={<FilterSelect label="Type d'événement" value={filters.values.type} defaultValue="all" options={AUDIT_ENTITIES} onChange={(type) => { filters.set({ type }); }} />}
      />
      <ResultSummary shown={audit.data?.total ?? 0} unit={["événement", "événements"]} active={filters.active} onReset={filters.reset} />
      <Card>
        <ListBody
          query={audit}
          isEmpty={(d) => d.rows.length === 0}
          empty={{ icon: <FileClock className="size-5" />, title: "Aucune entrée", text: "Les actions apparaîtront ici au fil du temps." }}
        >
          {(d) => (
            <>
              <DataTable
                rows={d.rows}
                rowKey={(e) => String(e.id)}
                columns={[
                  { key: "at", header: "Quand", primary: true, cell: (e) => <span className="font-medium text-fg">{dateTimeFr(e.at)}</span> },
                  { key: "action", header: "Action", cell: (e) => describe(e) },
                  { key: "actor", header: "Par", cell: (e) => author(e.actor) },
                  { key: "details", header: "Détails", cell: (e) => <AuditDetails entry={e} author={author} /> },
                ]}
              />
              <Pagination page={filters.page} pageSize={PAGE_SIZE} total={d.total} onPage={filters.setPage} />
            </>
          )}
        </ListBody>
      </Card>
    </>
  );
}

function AuditDetails({ entry, author }: { entry: AuditEntry; author: (id: string | null) => string }) {
  const changes = humanChanges(entry, author);
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
}

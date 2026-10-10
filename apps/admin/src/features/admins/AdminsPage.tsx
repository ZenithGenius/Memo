import { zodResolver } from "@hookform/resolvers/zod";
import { ShieldCheck } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { DataTable } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { Field, Input, Select } from "@/components/ui/form";
import { useConfirm } from "@/components/ui/overlay";
import { PageHeader } from "@/components/ui/page";
import { report, userMessage } from "@/lib/errors";
import { dateFr } from "@/lib/format";
import { ROLE_LABEL, canWrite, type AdminRole } from "@/lib/roles";
import type { AdminRow } from "@/lib/rpc-types";
import { useAdmins, useRemoveAdmin, useSetAdminRole } from "./api";

const adminRoles = ["super_admin", "support"] as const;

const addAdminSchema = z.object({
  email: z.email("E-mail invalide."),
  role: z.enum(adminRoles),
});

export default function AdminsPage() {
  const { role, session } = useSession();
  const writable = canWrite(role);
  const selfId = session.user.id;
  const admins = useAdmins();

  return (
    <>
      <PageHeader
        title="Administrateurs"
        description="Comptes autorisés à accéder au back-office et leur niveau d'accès."
      />
      {writable && <AddAdminCard />}
      <Card className={writable ? "mt-4" : undefined}>
        {admins.isPending ? (
          <Skeleton rows={6} />
        ) : admins.isError ? (
          <ErrorPanel onRetry={() => void admins.refetch()} />
        ) : admins.data.length === 0 ? (
          <EmptyState icon={<ShieldCheck className="size-5" />} title="Aucun administrateur" />
        ) : (
          <AdminsTable rows={admins.data} writable={writable} selfId={selfId} />
        )}
      </Card>
    </>
  );
}

function AddAdminCard() {
  const toast = useToast();
  const setRole = useSetAdminRole();
  const form = useForm({
    resolver: zodResolver(addAdminSchema),
    defaultValues: { email: "", role: "support" as AdminRole },
  });

  const onSubmit = form.handleSubmit(async (v) => {
    try {
      await setRole.mutateAsync({ targetEmail: v.email.trim(), newRole: v.role });
      toast("Administrateur ajouté.");
      form.reset({ email: "", role: "support" });
    } catch (e) {
      report("administrateur", e);
      toast(userMessage(e, "L'administrateur n'a pas pu être ajouté."), "error");
    }
  });

  return (
    <Card>
      <CardHeader title="Ajouter un administrateur" icon={<ShieldCheck className="size-4.5" />} />
      <form className="grid gap-3.5 p-5 sm:grid-cols-[1fr_auto_auto] sm:items-end" onSubmit={(e) => void onSubmit(e)}>
        <Field label="E-mail" htmlFor="admin-email" error={form.formState.errors.email?.message}>
          <Input id="admin-email" type="email" autoComplete="off" {...form.register("email")} />
        </Field>
        <Field label="Rôle" htmlFor="admin-role" error={form.formState.errors.role?.message}>
          <Select id="admin-role" {...form.register("role")}>
            {adminRoles.map((r) => (
              <option key={r} value={r}>{ROLE_LABEL[r]}</option>
            ))}
          </Select>
        </Field>
        <Button type="submit" loading={setRole.isPending}>Ajouter</Button>
      </form>
      <p className="border-t border-line-subtle px-5 py-3 text-xs text-fg-muted">
        La personne doit d'abord avoir créé un compte dans l'application.
      </p>
    </Card>
  );
}

function AdminsTable({ rows, writable, selfId }: { rows: AdminRow[]; writable: boolean; selfId: string }) {
  const toast = useToast();
  const confirm = useConfirm();
  const setRole = useSetAdminRole();
  const removeAdmin = useRemoveAdmin();

  const changeRole = async (row: AdminRow, newRole: AdminRole) => {
    if (newRole === row.role) return;
    const label = ROLE_LABEL[newRole];
    if (!(await confirm({
      title: "Changer le rôle ?",
      text: `Attribuer le rôle « ${label} » à ${row.email}.`,
      confirmLabel: "Confirmer",
    }))) return;
    try {
      await setRole.mutateAsync({ targetEmail: row.email, newRole });
      toast("Rôle mis à jour.");
    } catch (e) {
      report("rôle administrateur", e);
      toast(userMessage(e, "Le rôle n'a pas pu être modifié."), "error");
    }
  };

  const remove = async (row: AdminRow) => {
    if (!(await confirm({
      title: "Retirer cet administrateur ?",
      text: `${row.email} n'aura plus accès au back-office.`,
      confirmLabel: "Retirer",
    }))) return;
    try {
      await removeAdmin.mutateAsync({ target: row.user_id });
      toast("Administrateur retiré.");
    } catch (e) {
      report("retrait administrateur", e);
      toast(userMessage(e, "Le retrait a échoué."), "error");
    }
  };

  return (
    <DataTable
      rows={rows}
      rowKey={(a) => a.user_id}
      columns={[
        {
          key: "admin",
          header: "Administrateur",
          primary: true,
          cell: (a) => (
            <span className="font-semibold break-all text-fg">
              {a.email}
              {a.user_id === selfId && <span className="font-normal text-fg-muted"> (vous)</span>}
            </span>
          ),
        },
        {
          key: "role",
          header: "Rôle",
          cell: (a) => (
            <Badge tone={a.role === "super_admin" ? "info" : "neutral"}>
              {ROLE_LABEL[a.role as AdminRole]}
            </Badge>
          ),
        },
        { key: "since", header: "Depuis", cell: (a) => dateFr(a.created_at) },
        {
          key: "actions",
          header: "",
          align: "right",
          cell: (a) => writable && a.user_id !== selfId && (
            <div className="flex flex-wrap items-center justify-end gap-2">
              <Select
                className="h-8 min-w-[11rem] py-0 text-xs"
                value={a.role}
                onChange={(e) => void changeRole(a, e.target.value as AdminRole)}
                aria-label={`Rôle de ${a.email}`}
              >
                {adminRoles.map((r) => (
                  <option key={r} value={r}>{ROLE_LABEL[r]}</option>
                ))}
              </Select>
              <Button size="sm" variant="soft-danger" loading={removeAdmin.isPending} onClick={() => void remove(a)}>
                Retirer
              </Button>
            </div>
          ),
        },
      ]}
    />
  );
}

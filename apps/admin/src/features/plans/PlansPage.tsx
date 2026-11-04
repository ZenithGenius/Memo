import { zodResolver } from "@hookform/resolvers/zod";
import { Pencil, Tags } from "lucide-react";
import { useEffect, useState } from "react";
import { useForm, type FieldErrors, type UseFormRegister } from "react-hook-form";
import { z } from "zod";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DataTable } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { Field, Input } from "@/components/ui/form";
import { Drawer, useConfirm } from "@/components/ui/overlay";
import { PageHeader } from "@/components/ui/page";
import { report, userMessage } from "@/lib/errors";
import { fcfa } from "@/lib/format";
import { canWrite } from "@/lib/roles";
import { type PlanRow, usePlans, useSetPlanActive, useUpsertPlan } from "./api";

const codeSchema = z.string().regex(/^[a-z][a-z0-9_]{1,30}$/, "Code invalide : lettre minuscule puis minuscules, chiffres ou underscore (2 à 31 caractères).");

const planFieldsSchema = z.object({
  name: z.string().trim().min(1, "Nom requis.").max(60, "60 caractères maximum."),
  price_fcfa: z.coerce.number<number>().int("Montant entier.").min(0, "Montant positif ou nul."),
  period_days: z.coerce.number<number>().int("Durée entière.").min(1, "Au moins 1 jour.").max(3660, "3660 jours maximum."),
  max_devices: z.coerce.number<number>().int("Nombre entier.").min(1, "Au moins 1 appareil.").max(10, "10 appareils maximum."),
  sort_order: z.coerce.number<number>().int("Ordre entier."),
});

const createPlanSchema = planFieldsSchema.extend({ code: codeSchema });
const editPlanSchema = planFieldsSchema;

type CreatePlanForm = z.infer<typeof createPlanSchema>;
type EditPlanForm = z.infer<typeof editPlanSchema>;

type DrawerState = { mode: "create" } | { mode: "edit"; plan: PlanRow } | null;

export default function PlansPage() {
  const { role } = useSession();
  const writable = canWrite(role);
  const plans = usePlans();
  const [drawer, setDrawer] = useState<DrawerState>(null);

  return (
    <>
      <PageHeader
        title="Offres"
        description="Catalogue des offres d'abonnement : prix, durée, nombre d'appareils et mise en vente."
        actions={writable ? (
          <Button icon={<Tags className="size-4" />} onClick={() => { setDrawer({ mode: "create" }); }}>
            Nouvelle offre
          </Button>
        ) : undefined}
      />
      <Card>
        {plans.isPending ? (
          <Skeleton rows={6} />
        ) : plans.isError ? (
          <ErrorPanel onRetry={() => void plans.refetch()} />
        ) : plans.data.length === 0 ? (
          <EmptyState icon={<Tags className="size-5" />} title="Aucune offre" text="Créez une première offre pour activer des abonnements." />
        ) : (
          <PlansTable rows={plans.data} writable={writable} onEdit={(plan) => { setDrawer({ mode: "edit", plan }); }} />
        )}
      </Card>
      <PlanDrawer state={drawer} onClose={() => { setDrawer(null); }} />
    </>
  );
}

function PlansTable({ rows, writable, onEdit }: { rows: PlanRow[]; writable: boolean; onEdit: (p: PlanRow) => void }) {
  const toast = useToast();
  const confirm = useConfirm();
  const setActive = useSetPlanActive();

  const toggleActive = async (plan: PlanRow) => {
    if (plan.active) {
      const ok = await confirm({
        title: "Retirer cette offre de la vente ?",
        text: `« ${plan.name} » ne pourra plus être choisie pour de nouveaux abonnements.`,
        confirmLabel: "Retirer de la vente",
      });
      if (!ok) return;
    }
    try {
      await setActive.mutateAsync({ code: plan.code, active: !plan.active });
      toast(plan.active ? "Offre retirée de la vente." : "Offre remise en vente.");
    } catch (e) {
      report("offre", e);
      toast(userMessage(e, "L'offre n'a pas pu être mise à jour."), "error");
    }
  };

  return (
    <DataTable
      rows={rows}
      rowKey={(p) => p.code}
      columns={[
        {
          key: "name",
          header: "Offre",
          primary: true,
          cell: (p) => (
            <div className="min-w-0">
              <div className="font-semibold text-fg">{p.name}</div>
              <div className="text-xs text-fg-muted">{p.code}</div>
            </div>
          ),
        },
        { key: "price", header: "Prix", cell: (p) => fcfa(p.price_fcfa) },
        { key: "period", header: "Durée", cell: (p) => `${p.period_days} jours` },
        { key: "devices", header: "Appareils max", cell: (p) => p.max_devices },
        {
          key: "status",
          header: "Statut",
          cell: (p) => (p.active ? <Badge tone="success">En vente</Badge> : <Badge tone="neutral">Retirée</Badge>),
        },
        {
          key: "actions",
          header: "",
          align: "right",
          cell: (p) => {
            if (!writable) return null;
            return (
              <div className="flex flex-wrap justify-end gap-2">
                <Button size="sm" variant="secondary" icon={<Pencil className="size-3.5" />} onClick={() => { onEdit(p); }}>
                  Modifier
                </Button>
                <Button
                  size="sm"
                  variant={p.active ? "soft-danger" : "soft-accent"}
                  loading={setActive.isPending}
                  onClick={() => void toggleActive(p)}
                >
                  {p.active ? "Retirer de la vente" : "Remettre en vente"}
                </Button>
              </div>
            );
          },
        },
      ]}
    />
  );
}

function PlanDrawer({ state, onClose }: { state: DrawerState; onClose: () => void }) {
  const toast = useToast();
  const upsert = useUpsertPlan();
  const isCreate = state?.mode === "create";
  const plan = state?.mode === "edit" ? state.plan : null;

  const createForm = useForm<CreatePlanForm>({
    resolver: zodResolver(createPlanSchema),
    defaultValues: { code: "", name: "", price_fcfa: 0, period_days: 30, max_devices: 1, sort_order: 0 },
  });
  const editForm = useForm<EditPlanForm>({
    resolver: zodResolver(editPlanSchema),
    defaultValues: { name: "", price_fcfa: 0, period_days: 30, max_devices: 1, sort_order: 0 },
  });

  useEffect(() => {
    if (plan) {
      editForm.reset({
        name: plan.name,
        price_fcfa: plan.price_fcfa,
        period_days: plan.period_days,
        max_devices: plan.max_devices,
        sort_order: plan.sort_order,
      });
    } else if (isCreate) {
      createForm.reset({ code: "", name: "", price_fcfa: 0, period_days: 30, max_devices: 1, sort_order: 0 });
    }
  }, [plan, isCreate, createForm, editForm]);

  const onCreate = createForm.handleSubmit(async (v) => {
    try {
      await upsert.mutateAsync({
        mode: "create",
        row: {
          code: v.code,
          name: v.name.trim(),
          price_fcfa: v.price_fcfa,
          period_days: v.period_days,
          max_devices: v.max_devices,
          sort_order: v.sort_order,
        },
      });
      toast("Offre créée.");
      onClose();
    } catch (e) {
      report("offre", e);
      toast(userMessage(e, "L'offre n'a pas pu être créée."), "error");
    }
  });

  const onEdit = editForm.handleSubmit(async (v) => {
    if (!plan) return;
    try {
      await upsert.mutateAsync({
        mode: "update",
        code: plan.code,
        row: {
          name: v.name.trim(),
          price_fcfa: v.price_fcfa,
          period_days: v.period_days,
          max_devices: v.max_devices,
          sort_order: v.sort_order,
        },
      });
      toast("Offre modifiée.");
      onClose();
    } catch (e) {
      report("offre", e);
      toast(userMessage(e, "L'offre n'a pas pu être modifiée."), "error");
    }
  });

  return (
    <Drawer
      open={state !== null}
      onClose={onClose}
      title={isCreate ? "Nouvelle offre" : `Modifier ${plan?.name ?? ""}`}
      subtitle={plan ? plan.code : undefined}
    >
      <Card>
        {isCreate ? (
          <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onCreate(e)} noValidate>
            <Field label="Code" htmlFor="p-code" error={createForm.formState.errors.code?.message} className="sm:col-span-2" hint="Identifiant technique, non modifiable ensuite.">
              <Input id="p-code" autoComplete="off" {...createForm.register("code")} />
            </Field>
            <PlanFields register={createForm.register} err={createForm.formState.errors} />
            <div className="flex justify-end gap-2 sm:col-span-2">
              <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
              <Button type="submit" loading={upsert.isPending}>Créer</Button>
            </div>
          </form>
        ) : (
          <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onEdit(e)} noValidate>
            <PlanFields register={editForm.register} err={editForm.formState.errors} />
            <div className="flex justify-end gap-2 sm:col-span-2">
              <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
              <Button type="submit" loading={upsert.isPending}>Enregistrer</Button>
            </div>
          </form>
        )}
      </Card>
    </Drawer>
  );
}

function PlanFields({ register, err }: { register: UseFormRegister<EditPlanForm>; err: FieldErrors<EditPlanForm> }) {
  return (
    <>
      <Field label="Nom" htmlFor="p-name" error={err.name?.message} className="sm:col-span-2">
        <Input id="p-name" {...register("name")} />
      </Field>
      <Field label="Prix (FCFA)" htmlFor="p-price" error={err.price_fcfa?.message}>
        <Input id="p-price" type="number" min={0} step={1} inputMode="numeric" {...register("price_fcfa")} />
      </Field>
      <Field label="Durée (jours)" htmlFor="p-period" error={err.period_days?.message}>
        <Input id="p-period" type="number" min={1} max={3660} step={1} inputMode="numeric" {...register("period_days")} />
      </Field>
      <Field label="Appareils max" htmlFor="p-devices" error={err.max_devices?.message}>
        <Input id="p-devices" type="number" min={1} max={10} step={1} inputMode="numeric" {...register("max_devices")} />
      </Field>
      <Field label="Ordre d'affichage" htmlFor="p-sort" error={err.sort_order?.message}>
        <Input id="p-sort" type="number" step={1} inputMode="numeric" {...register("sort_order")} />
      </Field>
    </>
  );
}

import { zodResolver } from "@hookform/resolvers/zod";
import { BadgeCheck, KeyRound, Receipt, Smartphone, UserRound, Wallet } from "lucide-react";
import { useEffect, useMemo } from "react";
import { useForm, useWatch } from "react-hook-form";
import { z } from "zod";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { Badge, Chip } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { DataTable } from "@/components/ui/data-table";
import { EmptyState, ErrorPanel, Skeleton } from "@/components/ui/feedback";
import { Field, Input, Select } from "@/components/ui/form";
import { Drawer, useConfirm } from "@/components/ui/overlay";
import { report, userMessage } from "@/lib/errors";
import { dateFr, dateTimeFr, endOfDay, extendUntil, fcfa, toDateInput } from "@/lib/format";
import { PAYMENT_METHODS, integrityOf, methodLabel, paymentMethods, type PaymentMethod } from "@/lib/payments";
import { canWrite } from "@/lib/roles";
import { usePlans } from "@/features/plans/api";
import {
  useAccountDetail, useActivate, useSetDeviceRevoked, useSetSubscriptionStatus, useUpdateProfile,
} from "./api";

function activeDevicesSubtitle(n: number): string {
  if (n === 0) return "aucun appareil actif";
  if (n === 1) return "1 appareil actif";
  return `${n} appareils actifs`;
}

export interface AccountRef { userId: string; email: string }

const needsReference = (m: PaymentMethod) => m === "mtn_momo" || m === "orange_money" || m === "virement";

const activationSchema = z
  .object({
    plan: z.string().min(1, "Choisissez une offre."),
    until: z.string().min(1, "Date requise."),
    amount: z.coerce.number<number>().int("Montant entier.").min(0, "Montant positif."),
    method: z.enum(paymentMethods as [PaymentMethod, ...PaymentMethod[]]),
    reference: z.string().max(120),
    note: z.string().max(500),
  })
  .refine((v) => endOfDay(v.until) > new Date(), { path: ["until"], message: "La date doit être dans le futur." })
  .refine((v) => !needsReference(v.method) || v.reference.trim().length > 0, {
    path: ["reference"], message: "Référence de transaction requise pour ce moyen de paiement.",
  });

type ActivationForm = z.infer<typeof activationSchema>;

const profileSchema = z.object({
  displayName: z.string().max(80),
  phone: z.string().max(30).regex(/^[+\d\s().-]*$/, "Numéro invalide."),
});

export function AccountDrawer({ account, onClose }: { account: AccountRef | null; onClose: () => void }) {
  const { role } = useSession();
  const writable = canWrite(role);
  const detail = useAccountDetail(account?.userId ?? null);
  const data = detail.data;

  return (
    <Drawer
      open={account !== null}
      onClose={onClose}
      title={account?.email ?? ""}
      subtitle={data ? `Inscrit le ${dateFr(data.profile.created_at)} · ${activeDevicesSubtitle(data.devices.filter((d) => !d.revoked_at).length)}` : undefined}
      avatar={
        <div className="grid size-11 shrink-0 place-items-center rounded-xl bg-accent-muted font-heading text-lg font-semibold text-accent-strong">
          {(account?.email[0] ?? "?").toUpperCase()}
        </div>
      }
    >
      {detail.isPending ? (
        <Card><Skeleton rows={6} /></Card>
      ) : detail.isError || !data || !account ? (
        <Card><ErrorPanel onRetry={() => void detail.refetch()} /></Card>
      ) : (
        <>
          <ProfileCard userId={account.userId} profile={data.profile} writable={writable} />
          <SubscriptionsCard subscriptions={data.subscriptions} writable={writable} />
          {writable && (
            <ActivationCard
              userId={account.userId}
              current={data.subscriptions.find((s) => s.status === "active" && new Date(s.valid_until) > new Date()) ?? null}
            />
          )}
          <PaymentsCard payments={data.payments} />
          <DevicesCard devices={data.devices} writable={writable} />
          <IssuancesCard issuances={data.issuances} />
        </>
      )}
    </Drawer>
  );
}

function ProfileCard({ userId, profile, writable }: {
  userId: string; profile: { display_name: string | null; phone: string | null }; writable: boolean;
}) {
  const toast = useToast();
  const update = useUpdateProfile();
  const form = useForm({
    resolver: zodResolver(profileSchema),
    values: { displayName: profile.display_name ?? "", phone: profile.phone ?? "" },
  });

  const onSubmit = form.handleSubmit(async (v) => {
    try {
      await update.mutateAsync({ userId, ...v });
      toast("Fiche mise à jour.");
    } catch (e) {
      report("fiche compte", e);
      toast(userMessage(e, "La fiche n'a pas pu être mise à jour."), "error");
    }
  });

  return (
    <Card>
      <CardHeader title="Profil" icon={<UserRound className="size-4.5" />} />
      <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onSubmit(e)}>
        <Field label="Nom affiché" htmlFor="p-name" error={form.formState.errors.displayName?.message}>
          <Input id="p-name" disabled={!writable} placeholder="Non renseigné" {...form.register("displayName")} />
        </Field>
        <Field label="Téléphone" htmlFor="p-phone" error={form.formState.errors.phone?.message}>
          <Input id="p-phone" disabled={!writable} placeholder="Non renseigné" inputMode="tel" {...form.register("phone")} />
        </Field>
        {writable && form.formState.isDirty && (
          <div className="flex justify-end sm:col-span-2">
            <Button type="submit" variant="secondary" loading={update.isPending}>Enregistrer</Button>
          </div>
        )}
      </form>
    </Card>
  );
}

type Sub = NonNullable<ReturnType<typeof useAccountDetail>["data"]>["subscriptions"][number];

function subscriptionBadge(s: Sub) {
  if (s.status === "revoked") return <Badge tone="danger">Résilié</Badge>;
  if (new Date(s.valid_until) <= new Date()) return <Badge tone="neutral">Expiré</Badge>;
  return <Badge tone="success">Actif</Badge>;
}

function SubscriptionsCard({ subscriptions, writable }: { subscriptions: Sub[]; writable: boolean }) {
  const toast = useToast();
  const confirm = useConfirm();
  const setStatus = useSetSubscriptionStatus();

  const change = async (s: Sub, status: "active" | "revoked") => {
    if (status === "revoked") {
      const ok = await confirm({
        title: "Résilier cet abonnement ?",
        text: "Le contenu payant reste accessible jusqu'à l'expiration du dernier jeton émis (45 jours au plus), puis le compte retombe sur l'offre gratuite.",
        confirmLabel: "Résilier",
      });
      if (!ok) return;
    }
    try {
      await setStatus.mutateAsync({ id: s.id, status });
      toast(status === "revoked" ? "Abonnement résilié." : "Abonnement rétabli.");
    } catch (e) {
      report("abonnement", e);
      toast(userMessage(e, "L'abonnement n'a pas pu être modifié."), "error");
    }
  };

  return (
    <Card>
      <CardHeader title="Abonnements" icon={<Wallet className="size-4.5" />} />
      {subscriptions.length === 0 ? (
        <EmptyState icon={<Wallet className="size-5" />} title="Aucun abonnement" text="Ce compte utilise l'offre gratuite." />
      ) : (
        <DataTable
          rows={subscriptions}
          rowKey={(s) => s.id}
          columns={[
            { key: "plan", header: "Offre", primary: true, cell: (s) => (
              <div><div className="font-semibold text-fg">{s.plans.name}</div>{s.note && <div className="text-xs text-fg-muted">{s.note}</div>}</div>
            ) },
            { key: "until", header: "Valide jusqu'au", cell: (s) => dateFr(s.valid_until) },
            { key: "status", header: "Statut", cell: subscriptionBadge },
            { key: "action", header: "", align: "right", cell: (s) => {
              if (!writable) return null;
              const running = new Date(s.valid_until) > new Date();
              if (s.status === "active" && running)
                return <Button size="sm" variant="soft-danger" onClick={() => void change(s, "revoked")}>Résilier</Button>;
              if (s.status === "revoked" && running)
                return <Button size="sm" variant="soft-accent" onClick={() => void change(s, "active")}>Rétablir</Button>;
              return null;
            } },
          ]}
        />
      )}
    </Card>
  );
}

function ActivationCard({ userId, current }: { userId: string; current: Sub | null }) {
  const toast = useToast();
  const plans = usePlans();
  const activate = useActivate();
  const sellable = useMemo(() => (plans.data ?? []).filter((p) => p.active), [plans.data]);
  const form = useForm<ActivationForm>({
    resolver: zodResolver(activationSchema),
    defaultValues: { plan: "", until: "", amount: 0, method: "mtn_momo", reference: "", note: "" },
  });
  const plan = useWatch({ control: form.control, name: "plan" });

  // Offre par défaut : celle en cours, sinon la première en vente.
  useEffect(() => {
    if (!form.getValues("plan") && sellable[0]) form.setValue("plan", current?.plan_code ?? sellable[0].code);
  }, [sellable, current, form]);

  // Date et montant suivent l'offre choisie (prolongation depuis la fin en cours).
  useEffect(() => {
    const p = sellable.find((x) => x.code === plan);
    if (!p) return;
    form.setValue("until", toDateInput(extendUntil(p.period_days, current ? new Date(current.valid_until) : null)));
    form.setValue("amount", p.price_fcfa);
  }, [plan, sellable, current, form]);

  const onSubmit = form.handleSubmit(async (v) => {
    try {
      await activate.mutateAsync({ userId, plan: v.plan, until: endOfDay(v.until), amount: v.amount, method: v.method, reference: v.reference, note: v.note });
      toast(current ? "Abonnement prolongé, paiement enregistré." : "Abonnement activé, paiement enregistré.");
      form.reset({ ...form.getValues(), reference: "", note: "" });
    } catch (e) {
      report("activation", e);
      toast(userMessage(e, "L'abonnement n'a pas pu être activé."), "error");
    }
  });

  const err = form.formState.errors;
  return (
    <Card>
      <CardHeader title={current ? "Prolonger l'abonnement" : "Activer un abonnement"} icon={<BadgeCheck className="size-4.5" />} />
      <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onSubmit(e)} noValidate>
        <Field label="Offre" htmlFor="a-plan" error={err.plan?.message}>
          <Select id="a-plan" {...form.register("plan")}>
            {sellable.map((p) => <option key={p.code} value={p.code}>{p.name} · {fcfa(p.price_fcfa)} / {p.period_days} j</option>)}
          </Select>
        </Field>
        <Field label="Valide jusqu'au" htmlFor="a-until" error={err.until?.message}
          hint={current ? `Prolongé depuis la fin actuelle (${dateFr(current.valid_until)}).` : undefined}>
          <Input id="a-until" type="date" {...form.register("until")} />
        </Field>
        <Field label="Montant encaissé (FCFA)" htmlFor="a-amount" error={err.amount?.message}>
          <Input id="a-amount" type="number" min={0} step={1} inputMode="numeric" {...form.register("amount")} />
        </Field>
        <Field label="Moyen de paiement" htmlFor="a-method" error={err.method?.message}>
          <Select id="a-method" {...form.register("method")}>
            {paymentMethods.map((m) => <option key={m} value={m}>{PAYMENT_METHODS[m]}</option>)}
          </Select>
        </Field>
        <Field label="Référence de transaction" htmlFor="a-ref" error={err.reference?.message} className="sm:col-span-2">
          <Input id="a-ref" placeholder="Ex. MP261007.1530.A12345" {...form.register("reference")} />
        </Field>
        <Field label="Note interne" htmlFor="a-note" error={err.note?.message} className="sm:col-span-2">
          <Input id="a-note" placeholder="Facultatif" {...form.register("note")} />
        </Field>
        <div className="flex justify-end sm:col-span-2">
          <Button type="submit" loading={activate.isPending} icon={<BadgeCheck className="size-4.5" />}>
            {current ? "Prolonger" : "Activer"}
          </Button>
        </div>
      </form>
    </Card>
  );
}

type Payment = NonNullable<ReturnType<typeof useAccountDetail>["data"]>["payments"][number];

function PaymentsCard({ payments }: { payments: Payment[] }) {
  const total = payments.reduce((s, p) => s + p.amount_fcfa, 0);
  return (
    <Card>
      <CardHeader title="Paiements" icon={<Receipt className="size-4.5" />} aside={payments.length > 0 ? `Total ${fcfa(total)}` : undefined} />
      {payments.length === 0 ? (
        <EmptyState icon={<Receipt className="size-5" />} title="Aucun paiement enregistré" />
      ) : (
        <DataTable
          rows={payments}
          rowKey={(p) => p.id}
          columns={[
            { key: "date", header: "Date", primary: true, cell: (p) => <span className="font-semibold text-fg">{dateTimeFr(p.paid_at)}</span> },
            { key: "amount", header: "Montant", cell: (p) => fcfa(p.amount_fcfa) },
            { key: "method", header: "Moyen", cell: (p) => <Chip>{methodLabel(p.method)}</Chip> },
            { key: "ref", header: "Référence", cell: (p) => <span className="font-mono text-xs">{p.reference ?? "—"}</span> },
          ]}
        />
      )}
    </Card>
  );
}

type Device = NonNullable<ReturnType<typeof useAccountDetail>["data"]>["devices"][number];

export function IntegrityBadge({ level }: { level: string }) {
  const i = integrityOf(level);
  return <Badge tone={i.tone}>{i.label}</Badge>;
}

function DevicesCard({ devices, writable }: { devices: Device[]; writable: boolean }) {
  const toast = useToast();
  const confirm = useConfirm();
  const setRevoked = useSetDeviceRevoked();

  const toggle = async (d: Device) => {
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
    <Card>
      <CardHeader title="Appareils" icon={<Smartphone className="size-4.5" />} />
      {devices.length === 0 ? (
        <EmptyState icon={<Smartphone className="size-5" />} title="Aucun appareil" text="L'appareil s'enregistre à la première synchronisation." />
      ) : (
        <DataTable
          rows={devices}
          rowKey={(d) => d.id}
          columns={[
            { key: "device", header: "Appareil", primary: true, cell: (d) => (
              <div>
                <div className="font-semibold text-fg">{d.label ?? d.platform}</div>
                <div className="text-xs text-fg-muted">
                  {d.revoked_at ? `Révoqué le ${dateFr(d.revoked_at)}` : d.installed_from_store === false ? "Installé hors boutique" : d.platform}
                </div>
              </div>
            ) },
            { key: "integrity", header: "Intégrité", cell: (d) => <IntegrityBadge level={d.integrity_level} /> },
            { key: "seen", header: "Vu le", cell: (d) => dateFr(d.last_seen) },
            { key: "action", header: "", align: "right", cell: (d) => writable && (
              <Button size="sm" variant={d.revoked_at ? "soft-accent" : "soft-danger"} onClick={() => void toggle(d)}>
                {d.revoked_at ? "Rétablir" : "Révoquer"}
              </Button>
            ) },
          ]}
        />
      )}
    </Card>
  );
}

type Issuance = NonNullable<ReturnType<typeof useAccountDetail>["data"]>["issuances"][number];

function IssuancesCard({ issuances }: { issuances: Issuance[] }) {
  return (
    <Card>
      <CardHeader title="Jetons émis" icon={<KeyRound className="size-4.5" />} aside="10 plus récents" />
      {issuances.length === 0 ? (
        <EmptyState icon={<KeyRound className="size-5" />} title="Aucun jeton" text="Aucune synchronisation pour ce compte." />
      ) : (
        <DataTable
          rows={issuances}
          rowKey={(i) => String(i.id)}
          columns={[
            { key: "issued", header: "Émis", primary: true, cell: (i) => <span className="font-semibold text-fg">{dateTimeFr(i.issued_at)}</span> },
            { key: "until", header: "Valide jusqu'au", cell: (i) => dateFr(i.valid_until) },
            { key: "integrity", header: "Intégrité", cell: (i) => <IntegrityBadge level={i.integrity_level} /> },
          ]}
        />
      )}
    </Card>
  );
}

import { zodResolver } from "@hookform/resolvers/zod";
import { useEffect } from "react";
import { useForm, useWatch } from "react-hook-form";
import { z } from "zod";
import { useToast } from "@/app/toast";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Field, Input, Select } from "@/components/ui/form";
import { Drawer } from "@/components/ui/overlay";
import { CATEGORY_ICONS, contrastOnWhite } from "@/lib/content";
import { report, userMessage } from "@/lib/errors";
import { type CategoryRow, useSaveCategory } from "./api";

const schema = z.object({
  code: z.string().regex(/^[A-Z]{3}$/, "Trois lettres majuscules (ex. : JEU)."),
  fr: z.string().trim().min(1, "Requis.").max(40, "40 caractères maximum."),
  en: z.string().trim().min(1, "Requis.").max(40, "40 caractères maximum."),
  icon: z.enum(Object.keys(CATEGORY_ICONS) as [keyof typeof CATEGORY_ICONS]),
  color: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, "Couleur au format #RRGGBB.")
    .refine((c) => contrastOnWhite(c) >= 3, "Trop claire : le mot ne serait pas lisible (contraste 3:1 au minimum)."),
  sortOrder: z.coerce.number<number>().int("Nombre entier.").min(1, "Au moins 1.").max(999, "999 au maximum."),
});
type Form = z.infer<typeof schema>;

export type CategoryDrawerState = { mode: "create"; nextOrder: number } | { mode: "edit"; category: CategoryRow } | null;

/** Catégorie : libellés, icône, couleur de classement et place à l'accueil. */
export function CategoryDrawer({ state, onClose }: { state: CategoryDrawerState; onClose: () => void }) {
  const toast = useToast();
  const save = useSaveCategory();
  const editing = state?.mode === "edit" ? state.category : null;
  const form = useForm<Form>({ resolver: zodResolver(schema) });
  const color = useWatch({ control: form.control, name: "color" });

  useEffect(() => {
    if (!state) return;
    form.reset(
      editing
        ? { code: editing.code, fr: editing.labels.fr, en: editing.labels.en, icon: editing.icon as Form["icon"], color: editing.color, sortOrder: editing.sort_order }
        : { code: "", fr: "", en: "", icon: "bubble", color: "#1F7A6C", sortOrder: state.mode === "create" ? state.nextOrder : 1 },
    );
  }, [state, editing, form]);

  const onSubmit = form.handleSubmit(async (v) => {
    try {
      await save.mutateAsync({
        create: editing === null,
        row: { code: v.code, sort_order: v.sortOrder, icon: v.icon, color: v.color.toUpperCase(), labels: { fr: v.fr.trim(), en: v.en.trim() } },
      });
      toast(editing ? "Catégorie modifiée." : "Catégorie créée.");
      onClose();
    } catch (e) {
      report("catégorie", e);
      toast(userMessage(e, "La catégorie n'a pas pu être enregistrée."), "error");
    }
  });

  const err = form.formState.errors;
  const validColor = /^#[0-9A-Fa-f]{6}$/.test(color);
  return (
    <Drawer open={state !== null} onClose={onClose} title={editing ? `Modifier « ${editing.labels.fr} »` : "Nouvelle catégorie"} subtitle={editing?.code}>
      <Card>
        <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onSubmit(e)} noValidate>
          <Field label="Code" htmlFor="ca-code" error={err.code?.message} hint="Fait partie du code des pictogrammes : définitif.">
            <Input id="ca-code" disabled={editing !== null} maxLength={3} autoComplete="off" {...form.register("code")} />
          </Field>
          <Field label="Place à l'accueil" htmlFor="ca-sort" error={err.sortOrder?.message}>
            <Input id="ca-sort" type="number" min={1} max={999} inputMode="numeric" {...form.register("sortOrder")} />
          </Field>
          <Field label="Nom (français)" htmlFor="ca-fr" error={err.fr?.message}>
            <Input id="ca-fr" {...form.register("fr")} />
          </Field>
          <Field label="Nom (anglais)" htmlFor="ca-en" error={err.en?.message}>
            <Input id="ca-en" {...form.register("en")} />
          </Field>
          <Field label="Icône" htmlFor="ca-icon">
            <Select id="ca-icon" {...form.register("icon")}>
              {Object.entries(CATEGORY_ICONS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </Select>
          </Field>
          <Field label="Couleur de classement" htmlFor="ca-color" error={err.color?.message}
            hint={validColor ? `Contraste sur blanc : ${contrastOnWhite(color).toFixed(1)}:1` : undefined}>
            <div className="flex gap-2">
              <input type="color" aria-label="Choisir la couleur" value={validColor ? color : "#000000"}
                onChange={(e) => { form.setValue("color", e.target.value.toUpperCase(), { shouldValidate: true }); }}
                className="h-10 w-12 shrink-0 cursor-pointer rounded-lg border border-line bg-raised" />
              <Input id="ca-color" maxLength={7} {...form.register("color")} />
            </div>
          </Field>
          <div className="flex justify-end gap-2 sm:col-span-2">
            <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
            <Button type="submit" loading={save.isPending}>{editing ? "Enregistrer" : "Créer"}</Button>
          </div>
        </form>
      </Card>
    </Drawer>
  );
}

import { zodResolver } from "@hookform/resolvers/zod";
import { ImageUp } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { useForm, useWatch } from "react-hook-form";
import { z } from "zod";
import { useToast } from "@/app/toast";
import { Button } from "@/components/ui/button";
import { Card, CardHeader } from "@/components/ui/card";
import { Field, Input, Select } from "@/components/ui/form";
import { Drawer } from "@/components/ui/overlay";
import { AUDIENCES, LEVELS, TIERS, imageFileProblem, levelOrderProblem, nextCode, nextSortOrder } from "@/lib/content";
import { report, userMessage } from "@/lib/errors";
import { type CategoryRow, type PictogramRow, useSavePictogram, useUploadImage } from "./api";
import { PictogramImage } from "./PictogramImage";

const label = z.string().trim().min(1, "Requis.").max(40, "40 caractères maximum.");
const spoken = z.string().trim().min(1, "Requis.").max(80, "80 caractères maximum.");

const schema = z.object({
  category: z.string().min(1, "Choisissez une catégorie."),
  frLabel: label,
  frSpoken: spoken,
  enLabel: label,
  enSpoken: spoken,
  level: z.coerce.number<number>().int().min(0).max(2),
  audience: z.enum(["all", "child", "teen", "adult"]),
  tier: z.enum(["free", "premium"]),
  sortOrder: z.coerce.number<number>().int("Nombre entier.").min(1, "Au moins 1.").max(9999, "9999 au maximum."),
  labelInImage: z.boolean(),
  imageSha: z.string().nullable(),
  imageFeminine: z.string().nullable(),
  imageMasculine: z.string().nullable(),
});
type ImageField = "imageSha" | "imageFeminine" | "imageMasculine";
type Form = z.infer<typeof schema>;

export type PictogramDrawerState = { mode: "create" } | { mode: "edit"; pictogram: PictogramRow } | null;

/**
 * Création ou modification d'un pictogramme. Le code est attribué une fois
 * pour toutes ; un nouveau mot se place en fin de catégorie (position stable).
 */
export function PictogramDrawer({ state, categories, pictograms, onClose }: {
  state: PictogramDrawerState;
  categories: CategoryRow[];
  pictograms: PictogramRow[];
  onClose: () => void;
}) {
  const toast = useToast();
  const save = useSavePictogram();
  const upload = useUploadImage();
  const editing = state?.mode === "edit" ? state.pictogram : null;
  const form = useForm<Form>({ resolver: zodResolver(schema) });
  const category = useWatch({ control: form.control, name: "category" });
  const imageSha = useWatch({ control: form.control, name: "imageSha" }) ?? null;
  const imageFeminine = useWatch({ control: form.control, name: "imageFeminine" }) ?? null;
  const imageMasculine = useWatch({ control: form.control, name: "imageMasculine" }) ?? null;
  const [uploading, setUploading] = useState<ImageField | null>(null);

  useEffect(() => {
    if (!state) return;
    const p = editing;
    form.reset({
      category: p?.category_code ?? categories[0]?.code ?? "",
      frLabel: p?.labels.fr.label ?? "",
      frSpoken: p?.labels.fr.spoken ?? "",
      enLabel: p?.labels.en.label ?? "",
      enSpoken: p?.labels.en.spoken ?? "",
      level: p?.level ?? 0,
      audience: p?.audience ?? "all",
      tier: p?.tier ?? "premium",
      sortOrder: p?.sort_order ?? 1,
      labelInImage: p?.label_in_image ?? false,
      imageSha: p?.image_sha256 ?? null,
      imageFeminine: p?.image_feminine_sha256 ?? null,
      imageMasculine: p?.image_masculine_sha256 ?? null,
    });
  }, [state, editing, categories, form]);

  // Nouveau mot : en fin de catégorie, au niveau du dernier mot (le seul
  // qui ne déplace aucun mot déjà connu).
  useEffect(() => {
    if (state?.mode !== "create" || !category) return;
    const inCategory = pictograms.filter((p) => p.category_code === category && p.active);
    form.setValue("sortOrder", nextSortOrder(pictograms.filter((p) => p.category_code === category).map((p) => p.sort_order)));
    form.setValue("level", inCategory.reduce((m, p) => Math.max(m, p.level), 0));
  }, [state, category, pictograms, form]);

  const code = editing?.code ?? (category ? nextCode(category, pictograms.map((p) => p.code)) : "");

  const onFile = async (field: ImageField, file: File) => {
    const problem = imageFileProblem(file);
    if (problem) {
      toast(problem, "error");
      return;
    }
    setUploading(field);
    try {
      form.setValue(field, await upload.mutateAsync(file), { shouldDirty: true });
      toast("Image envoyée. Enregistrez puis publiez pour la diffuser.");
    } catch (e) {
      report("image", e);
      toast(userMessage(e, "L'image n'a pas pu être envoyée."), "error");
    } finally {
      setUploading(null);
    }
  };

  const onSubmit = form.handleSubmit(async (v) => {
    const problem = levelOrderProblem(
      { code, level: v.level, sort_order: v.sortOrder },
      pictograms.filter((p) => p.category_code === v.category),
    );
    if (problem) {
      form.setError("level", { message: problem });
      return;
    }
    try {
      await save.mutateAsync({
        create: editing === null,
        row: {
          code,
          category_code: v.category,
          level: v.level,
          audience: v.audience,
          tier: v.tier,
          sort_order: v.sortOrder,
          labels: {
            fr: { label: v.frLabel.trim(), spoken: v.frSpoken.trim() },
            en: { label: v.enLabel.trim(), spoken: v.enSpoken.trim() },
          },
          image_asset: editing?.image_asset ?? null,
          image_sha256: v.imageSha,
          image_feminine_sha256: v.imageFeminine,
          image_masculine_sha256: v.imageMasculine,
          label_in_image: v.labelInImage,
          active: editing?.active ?? true,
        },
      });
      toast(editing ? "Pictogramme modifié." : "Pictogramme créé.");
      onClose();
    } catch (e) {
      report("pictogramme", e);
      toast(userMessage(e, "Le pictogramme n'a pas pu être enregistré."), "error");
    }
  });

  const err = form.formState.errors;
  return (
    <Drawer
      open={state !== null}
      onClose={onClose}
      title={editing ? `Modifier « ${editing.labels.fr.label} »` : "Nouveau pictogramme"}
      subtitle={code || undefined}
    >
      <Card>
        <CardHeader title="Images" icon={<ImageUp className="size-4.5" />} />
        <div className="grid gap-4 p-5">
          <p className="text-sm text-fg-muted">
            PNG ou WebP, 512 Ko au maximum, sans texte dans l'image. Pour un mot qui représente une personne, les variantes
            s'affichent selon le genre du profil ; sans variante, l'image commune est utilisée.
          </p>
          <div className="grid gap-4 sm:grid-cols-3">
            <ImageSlot label="Image commune" sha256={imageSha} asset={editing?.image_asset ?? null}
              busy={uploading === "imageSha"} onPick={(f) => void onFile("imageSha", f)} />
            <ImageSlot label="Fille ou femme" sha256={imageFeminine} asset={null}
              busy={uploading === "imageFeminine"} onPick={(f) => void onFile("imageFeminine", f)}
              onClear={() => { form.setValue("imageFeminine", null, { shouldDirty: true }); }} />
            <ImageSlot label="Garçon ou homme" sha256={imageMasculine} asset={null}
              busy={uploading === "imageMasculine"} onPick={(f) => void onFile("imageMasculine", f)}
              onClear={() => { form.setValue("imageMasculine", null, { shouldDirty: true }); }} />
          </div>
        </div>
      </Card>
      <Card>
        <form className="grid gap-3.5 p-5 sm:grid-cols-2" onSubmit={(e) => void onSubmit(e)} noValidate>
          <Field label="Catégorie" htmlFor="pi-cat" error={err.category?.message} className="sm:col-span-2"
            hint={editing ? "La catégorie fait partie du code : elle ne change plus." : undefined}>
            <Select id="pi-cat" disabled={editing !== null} {...form.register("category")}>
              {categories.map((c) => <option key={c.code} value={c.code}>{c.labels.fr}</option>)}
            </Select>
          </Field>
          <Field label="Mot (français)" htmlFor="pi-fr" error={err.frLabel?.message}>
            <Input id="pi-fr" {...form.register("frLabel")} />
          </Field>
          <Field label="Prononciation (français)" htmlFor="pi-frs" error={err.frSpoken?.message}>
            <Input id="pi-frs" placeholder="Ce que dit la voix" {...form.register("frSpoken")} />
          </Field>
          <Field label="Mot (anglais)" htmlFor="pi-en" error={err.enLabel?.message}>
            <Input id="pi-en" {...form.register("enLabel")} />
          </Field>
          <Field label="Prononciation (anglais)" htmlFor="pi-ens" error={err.enSpoken?.message}>
            <Input id="pi-ens" {...form.register("enSpoken")} />
          </Field>
          <Field label="Niveau" htmlFor="pi-level" error={err.level?.message}>
            <Select id="pi-level" {...form.register("level")}>
              {LEVELS.map((l, i) => <option key={l} value={i}>{l}</option>)}
            </Select>
          </Field>
          <Field label="Public" htmlFor="pi-aud">
            <Select id="pi-aud" {...form.register("audience")}>
              {Object.entries(AUDIENCES).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </Select>
          </Field>
          <Field label="Offre" htmlFor="pi-tier" hint="Gratuit : visible sans compte, après publication.">
            <Select id="pi-tier" {...form.register("tier")}>
              {Object.entries(TIERS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </Select>
          </Field>
          <Field label="Ordre dans la catégorie" htmlFor="pi-sort" error={err.sortOrder?.message}
            hint="Un mot ne passe jamais devant un mot de niveau inférieur.">
            <Input id="pi-sort" type="number" min={1} max={9999} inputMode="numeric" {...form.register("sortOrder")} />
          </Field>
          <label className="flex items-center gap-2 self-end pb-2 text-sm text-fg-secondary">
            <input type="checkbox" className="size-4 accent-[var(--color-accent)]" {...form.register("labelInImage")} />
            Le mot est écrit dans l'image
          </label>
          <div className="flex justify-end gap-2 sm:col-span-2">
            <Button variant="secondary" type="button" onClick={onClose}>Annuler</Button>
            <Button type="submit" loading={save.isPending}>{editing ? "Enregistrer" : "Créer"}</Button>
          </div>
        </form>
      </Card>
    </Drawer>
  );
}

/** Emplacement d'image : aperçu, envoi, et retrait pour une variante. */
function ImageSlot({ label, sha256, asset, busy, onPick, onClear }: {
  label: string;
  sha256: string | null;
  asset: string | null;
  busy: boolean;
  onPick: (file: File) => void;
  onClear?: () => void;
}) {
  const input = useRef<HTMLInputElement>(null);
  return (
    <div className="grid justify-items-start gap-2">
      <span className="text-sm font-semibold text-fg-secondary">{label}</span>
      <PictogramImage sha256={sha256} asset={asset} size="lg" />
      <input
        ref={input}
        type="file"
        accept="image/png,image/webp"
        className="sr-only"
        aria-label={label}
        onChange={(e) => {
          const file = e.target.files?.[0];
          e.target.value = "";
          if (file) onPick(file);
        }}
      />
      <div className="flex flex-wrap gap-2">
        <Button size="sm" variant="secondary" loading={busy} onClick={() => input.current?.click()}>
          {sha256 ? "Remplacer" : "Envoyer"}
        </Button>
        {onClear && sha256 && <Button size="sm" variant="soft-danger" onClick={onClear}>Retirer</Button>}
      </div>
    </div>
  );
}

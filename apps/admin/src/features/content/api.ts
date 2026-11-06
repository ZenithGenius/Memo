import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import { hasImageSignature, sha256Hex } from "@/lib/content";
import type { Json } from "@/lib/database.types";

const BUCKET = "content-images";

export type Lang = "fr" | "en";
export interface PictogramLabels { fr: { label: string; spoken: string }; en: { label: string; spoken: string } }
export type Audience = "child" | "teen" | "adult" | "all";
/** Palier d'offre (#41) : « free » se voit sans compte. */
export type Tier = "free" | "premium";

export interface CategoryRow {
  code: string;
  sort_order: number;
  icon: string;
  color: string;
  labels: Record<Lang, string>;
}

export interface PictogramRow {
  code: string;
  category_code: string;
  level: number;
  audience: Audience;
  sort_order: number;
  labels: PictogramLabels;
  image_asset: string | null;
  image_sha256: string | null;
  /** Variantes selon le genre du profil (#19). */
  image_feminine_sha256: string | null;
  image_masculine_sha256: string | null;
  label_in_image: boolean;
  tier: Tier;
  active: boolean;
}

export interface ReleaseRow { version: number; pictogram_count: number; notes: string | null; published_at: string }

const KEYS = ["content-categories", "content-pictograms", "content-releases", "audit"];

function useRefresh() {
  const qc = useQueryClient();
  return () => Promise.all(KEYS.map((k) => qc.invalidateQueries({ queryKey: [k] })));
}

export function useCategories() {
  const db = useDb();
  return useQuery({
    queryKey: ["content-categories"],
    queryFn: async (): Promise<CategoryRow[]> => {
      const { data, error } = await db.from("content_categories").select("code, sort_order, icon, color, labels").order("sort_order");
      if (error) throw error;
      return data as unknown as CategoryRow[];
    },
  });
}

export function usePictograms() {
  const db = useDb();
  return useQuery({
    queryKey: ["content-pictograms"],
    queryFn: async (): Promise<PictogramRow[]> => {
      const { data, error } = await db
        .from("content_pictograms")
        .select("code, category_code, level, audience, sort_order, labels, image_asset, image_sha256, image_feminine_sha256, image_masculine_sha256, label_in_image, tier, active")
        .order("category_code")
        .order("sort_order");
      if (error) throw error;
      return data as unknown as PictogramRow[];
    },
  });
}

/** Codes déjà publiés : ceux-là ne se suppriment jamais, ils se retirent. */
export function useReleases() {
  const db = useDb();
  return useQuery({
    queryKey: ["content-releases"],
    queryFn: async (): Promise<{ releases: ReleaseRow[]; published: Set<string> }> => {
      const { data, error } = await db
        .from("content_releases")
        .select("version, pictogram_count, notes, published_at, pack")
        .order("version", { ascending: false });
      if (error) throw error;
      const published = new Set<string>();
      for (const r of data) {
        const pictos = (r.pack as { pictograms?: { code: string }[] } | null)?.pictograms ?? [];
        for (const p of pictos) published.add(p.code);
      }
      const releases = data.map((r) => ({
        version: r.version,
        pictogram_count: r.pictogram_count,
        notes: r.notes,
        published_at: r.published_at,
      }));
      return { releases, published };
    },
  });
}

/** Aperçu d'une image du stockage : lien signé de courte durée. */
export function useImage(sha256: string | null) {
  const db = useDb();
  return useQuery({
    queryKey: ["content-image", sha256],
    enabled: sha256 !== null,
    staleTime: 4 * 60_000,
    queryFn: async (): Promise<string> => {
      const { data, error } = await db.storage.from(BUCKET).createSignedUrl(sha256 ?? "", 300);
      if (error) throw error;
      return data.signedUrl;
    },
  });
}

export function useSaveCategory() {
  const db = useDb();
  const refresh = useRefresh();
  return useMutation({
    mutationFn: async ({ row, create }: { row: CategoryRow; create: boolean }) => {
      const { code, ...fields } = row;
      const values = { ...fields, labels: fields.labels as unknown as Json };
      const { error } = create
        ? await db.from("content_categories").insert({ code, ...values })
        : await db.from("content_categories").update(values).eq("code", code);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useSavePictogram() {
  const db = useDb();
  const refresh = useRefresh();
  return useMutation({
    mutationFn: async ({ row, create }: { row: PictogramRow; create: boolean }) => {
      const { code, ...fields } = row;
      const values = { ...fields, labels: fields.labels as unknown as Json };
      const { error } = create
        ? await db.from("content_pictograms").insert({ code, ...values })
        : await db.from("content_pictograms").update(values).eq("code", code);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useSetPictogramActive() {
  const db = useDb();
  const refresh = useRefresh();
  return useMutation({
    mutationFn: async ({ code, active }: { code: string; active: boolean }) => {
      const { error } = await db.from("content_pictograms").update({ active }).eq("code", code);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

/** Brouillon jamais publié seulement (la base refuse le reste). */
export function useDeleteDraft() {
  const db = useDb();
  const refresh = useRefresh();
  return useMutation({
    mutationFn: async (code: string) => {
      const { data, error } = await db.from("content_pictograms").delete().eq("code", code).select("code");
      if (error) throw error;
      if (data.length === 0) throw new Error("already_published");
    },
    onSuccess: refresh,
  });
}

/**
 * Envoi d'une image : nommée par son empreinte dans le stockage objet (une
 * même image n'est stockée qu'une fois), puis enregistrée au catalogue, qui
 * vérifie l'objet et ses métadonnées relevées par le stockage.
 */
export function useUploadImage() {
  const db = useDb();
  return useMutation({
    mutationFn: async (file: File): Promise<string> => {
      const bytes = new Uint8Array(await file.arrayBuffer());
      if (!hasImageSignature(file.type, bytes)) throw new Error("invalid_image");
      const sha256 = await sha256Hex(bytes);
      const { error: uploadError } = await db.storage.from(BUCKET).upload(sha256, bytes, { contentType: file.type, upsert: false });
      // Déjà présente : même empreinte, donc même contenu.
      if (uploadError && !/exists|duplicate/i.test(uploadError.message)) throw uploadError;
      const { data, error } = await db.rpc("admin_register_image", { target_sha256: sha256, mime: file.type });
      if (error) throw error;
      return data;
    },
  });
}

export function usePublish() {
  const db = useDb();
  const refresh = useRefresh();
  return useMutation({
    mutationFn: async (notes: string): Promise<number> => {
      const { data, error } = await db.rpc("admin_publish_content", { notes: notes.trim() || undefined });
      if (error) throw error;
      return data;
    },
    onSuccess: refresh,
  });
}

import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useDb } from "@/app/db-context";
import type { PaymentMethod, Situation } from "@/lib/payments";
import type { AccountRow } from "@/lib/rpc-types";

export type AccountFilter = "all" | Situation;

export function useAccounts(query: string, status: AccountFilter, page: number, pageSize: number) {
  const db = useDb();
  return useQuery({
    queryKey: ["accounts", query, status, page, pageSize],
    queryFn: async () => {
      const { data, error } = await db.rpc("admin_accounts", { query, status, lim: pageSize, off: page * pageSize });
      if (error) throw error;
      const rows = data as AccountRow[];
      return { rows, total: rows[0]?.total ?? 0 };
    },
    placeholderData: keepPreviousData,
  });
}

export function usePlans() {
  const db = useDb();
  return useQuery({
    queryKey: ["plans"],
    queryFn: async () => {
      const { data, error } = await db.from("plans").select("code, name, price_fcfa, period_days, max_devices, active, sort_order").order("sort_order");
      if (error) throw error;
      return data;
    },
  });
}

export function useAccountDetail(userId: string | null) {
  const db = useDb();
  return useQuery({
    queryKey: ["account", userId],
    enabled: userId !== null,
    queryFn: async () => {
      const id = userId ?? "";
      const [profile, subs, devices, issuances, payments] = await Promise.all([
        db.from("accounts").select("display_name, phone, created_at").eq("user_id", id).single(),
        db.from("subscriptions").select("id, plan_code, valid_until, status, note, created_at, revoked_at, plans(name)").eq("user_id", id).order("valid_until", { ascending: false }),
        db.from("devices").select("id, platform, label, integrity_level, installed_from_store, last_seen, revoked_at").eq("user_id", id).order("last_seen", { ascending: false }),
        db.from("license_issuances").select("id, issued_at, valid_until, key_id, integrity_level").eq("user_id", id).order("issued_at", { ascending: false }).limit(10),
        db.from("payments").select("id, amount_fcfa, method, reference, paid_at").eq("user_id", id).order("paid_at", { ascending: false }),
      ]);
      for (const r of [profile, subs, devices, issuances, payments]) if (r.error) throw r.error;
      if (!profile.data) throw new Error("fiche compte introuvable");
      return {
        profile: profile.data,
        subscriptions: subs.data ?? [],
        devices: devices.data ?? [],
        issuances: issuances.data ?? [],
        payments: payments.data ?? [],
      };
    },
  });
}

/** Rafraîchit tout ce qui dépend d'un compte après une écriture. */
function useInvalidateAll() {
  const qc = useQueryClient();
  return () => Promise.all(
    ["account", "accounts", "dashboard", "subscriptions", "payments", "devices", "audit"].map((k) => qc.invalidateQueries({ queryKey: [k] })),
  );
}

export interface ActivationInput {
  userId: string; plan: string; until: Date; amount: number; method: PaymentMethod; reference: string; note: string;
}

export function useActivate() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async (i: ActivationInput) => {
      const { error } = await db.rpc("admin_activate_subscription", {
        target_user: i.userId, plan: i.plan, until: i.until.toISOString(),
        amount_fcfa: i.amount, method: i.method, reference: i.reference, note: i.note,
      });
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useSetSubscriptionStatus() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: "active" | "revoked" }) => {
      const { error } = await db.from("subscriptions").update({ status }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useSetDeviceRevoked() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ id, revoked }: { id: string; revoked: boolean }) => {
      const { error } = await db.from("devices").update({ revoked_at: revoked ? new Date().toISOString() : null }).eq("id", id);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

export function useUpdateProfile() {
  const db = useDb();
  const refresh = useInvalidateAll();
  return useMutation({
    mutationFn: async ({ userId, displayName, phone }: { userId: string; displayName: string; phone: string }) => {
      const { error } = await db.from("accounts")
        .update({ display_name: displayName.trim() || null, phone: phone.trim() || null })
        .eq("user_id", userId);
      if (error) throw error;
    },
    onSuccess: refresh,
  });
}

// Contrôleur de la liste des appareils : filtres, droits, révocation.
import { useState } from "react";
import { useSession } from "@/app/auth";
import { useToast } from "@/app/toast";
import { useConfirm } from "@/components/ui/overlay";
import type { AccountRef } from "@/features/accounts/AccountDrawer";
import { useSetDeviceRevoked } from "@/features/accounts/api";
import { useDebounced } from "@/hooks/use-debounced";
import { useListFilters } from "@/hooks/use-list-filters";
import { report, userMessage } from "@/lib/errors";
import { canWrite } from "@/lib/roles";
import { useDevices } from "./api";
import { DEVICE_FILTERS, PAGE_SIZE, type DeviceRef } from "./model";

export function useDevicesList() {
  const { role } = useSession();
  const toast = useToast();
  const confirm = useConfirm();
  const setRevoked = useSetDeviceRevoked();
  const filters = useListFilters(DEVICE_FILTERS);
  const search = useDebounced(filters.values.q.trim());
  const list = useDevices(search, filters.values.statut, filters.page, PAGE_SIZE);
  const [account, setAccount] = useState<AccountRef | null>(null);

  /** Révoque un appareil actif (après confirmation) ou rétablit un appareil révoqué. */
  const toggleRevoked = async (d: DeviceRef) => {
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

  return { filters, list, writable: canWrite(role), toggleRevoked, account, setAccount };
}

export type DevicesList = ReturnType<typeof useDevicesList>;

import { useSearchParams } from "react-router";
import { ViewTabs } from "@/components/ui/filters";
import { PageHeader } from "@/components/ui/page";
import { usePaymentsList, useSubscriptionsList } from "./controllers";
import { PaymentsView, SubscriptionsView } from "./views";

type View = "abonnements" | "paiements";
const VIEWS: readonly { value: View; label: string }[] = [
  { value: "abonnements", label: "Abonnements" },
  { value: "paiements", label: "Paiements" },
];

export default function SubscriptionsPage() {
  const [params, setParams] = useSearchParams();
  const view: View = params.get("vue") === "paiements" ? "paiements" : "abonnements";
  return (
    <>
      <PageHeader title="Abonnements et paiements" description="Les abonnements actifs ou passés, et l'historique des paiements encaissés." />
      {/* Changer de vue repart de filtres vides : chaque vue a les siens. */}
      <ViewTabs label="Vue" value={view} options={VIEWS} onChange={(v) => { setParams(v === "abonnements" ? {} : { vue: v }); }} />
      {view === "abonnements" ? <Subscriptions /> : <Payments />}
    </>
  );
}

function Subscriptions() {
  return <SubscriptionsView c={useSubscriptionsList()} />;
}

function Payments() {
  return <PaymentsView c={usePaymentsList()} />;
}

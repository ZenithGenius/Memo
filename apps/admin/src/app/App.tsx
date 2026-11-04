import { lazy, Suspense } from "react";
import { Navigate, Route, Routes } from "react-router";
import { Shell } from "@/components/layout/shell";
import { Skeleton } from "@/components/ui/feedback";
import { LoginPage } from "@/features/auth/LoginPage";
import { useAuth } from "./auth";

const DashboardPage = lazy(() => import("@/features/dashboard/DashboardPage"));
const AccountsPage = lazy(() => import("@/features/accounts/AccountsPage"));
const PlansPage = lazy(() => import("@/features/plans/PlansPage"));
const AuditPage = lazy(() => import("@/features/audit/AuditPage"));
const SubscriptionsPage = lazy(() => import("@/features/subscriptions/SubscriptionsPage"));
const DevicesPage = lazy(() => import("@/features/devices/DevicesPage"));
const AdminsPage = lazy(() => import("@/features/admins/AdminsPage"));

export function App() {
  const { state } = useAuth();
  if (state.status === "loading") return null;
  if (state.status === "signed-out") return <LoginPage reason={state.reason} />;

  return (
    <Shell>
      <Suspense fallback={<Skeleton rows={6} />}>
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/comptes" element={<AccountsPage />} />
          <Route path="/abonnements" element={<SubscriptionsPage />} />
          <Route path="/offres" element={<PlansPage />} />
          <Route path="/appareils" element={<DevicesPage />} />
          <Route path="/administrateurs" element={<AdminsPage />} />
          <Route path="/journal" element={<AuditPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    </Shell>
  );
}

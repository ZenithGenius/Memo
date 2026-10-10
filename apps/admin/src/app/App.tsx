import { lazy, Suspense } from "react";
import { Navigate, Route, Routes } from "react-router";
import { Shell } from "@/components/layout/shell";
import { Skeleton } from "@/components/ui/feedback";
import { LoginPage } from "@/features/auth/LoginPage";
import { useAuth } from "./auth";

const DashboardPage = lazy(() => import("@/features/dashboard/DashboardPage"));
const AccountsPage = lazy(() => import("@/features/accounts/AccountsPage"));

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
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    </Shell>
  );
}

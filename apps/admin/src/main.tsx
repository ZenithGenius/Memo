import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router";
import { App } from "@/app/App";
import { AuthProvider } from "@/app/auth";
import { DbProvider } from "@/app/db-context";
import { ToastProvider } from "@/app/toast";
import { ConfirmProvider } from "@/components/ui/overlay";
import { readConfig } from "@/lib/config";
import { createDb } from "@/lib/supabase";
import "./styles.css";

const root = createRoot(document.getElementById("root") as HTMLElement);
const config = readConfig();

if (!config) {
  root.render(
    <p className="p-8 text-fg">Configuration absente ou invalide : renseigner <code>config.js</code> (voir le README).</p>,
  );
} else {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: true } },
  });
  root.render(
    <StrictMode>
      <DbProvider db={createDb(config)}>
        <QueryClientProvider client={queryClient}>
          <ToastProvider>
            <ConfirmProvider>
              <AuthProvider>
                <BrowserRouter>
                  <App />
                </BrowserRouter>
              </AuthProvider>
            </ConfirmProvider>
          </ToastProvider>
        </QueryClientProvider>
      </DbProvider>
    </StrictMode>,
  );
}

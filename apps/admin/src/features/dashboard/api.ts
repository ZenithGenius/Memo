import { useQuery } from "@tanstack/react-query";
import { z } from "zod";
import { useDb } from "@/app/db-context";

const dashboardSchema = z.object({
  accounts_total: z.number(),
  accounts_this_month: z.number(),
  active_subscribers: z.number(),
  new_subscribers_this_month: z.number(),
  cancellations_this_month: z.number(),
  ever_subscribed: z.number(),
  mrr_fcfa: z.number(),
  revenue_this_month_fcfa: z.number(),
  revenue_by_month: z.array(z.object({ month: z.string(), amount_fcfa: z.number() })),
  retention: z.array(z.object({ months: z.number(), cohort: z.number(), retained: z.number() })).nullable(),
  expiring_7_days: z.number(),
  integrity_alerts: z.number(),
});

export type Dashboard = z.infer<typeof dashboardSchema>;

export function useDashboard() {
  const db = useDb();
  return useQuery({
    queryKey: ["dashboard"],
    queryFn: async () => {
      const { data, error } = await db.rpc("admin_dashboard");
      if (error) throw error;
      return dashboardSchema.parse(data);
    },
  });
}

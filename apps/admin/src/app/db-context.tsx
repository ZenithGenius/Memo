import { createContext, useContext, type ReactNode } from "react";
import type { Db } from "@/lib/supabase";

const DbContext = createContext<Db | null>(null);

export function DbProvider({ db, children }: { db: Db; children: ReactNode }) {
  return <DbContext value={db}>{children}</DbContext>;
}

export function useDb(): Db {
  const db = useContext(DbContext);
  if (!db) throw new Error("DbProvider manquant");
  return db;
}

import { CircleAlert, KeyRound } from "lucide-react";
import { useState } from "react";
import { useAuth } from "@/app/auth";
import { useDb } from "@/app/db-context";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/form";
import { report } from "@/lib/errors";
import { isTotpCode } from "@/lib/mfa";
import { passwordProblem } from "@/lib/recovery";

/**
 * Nouveau mot de passe, depuis le lien reçu par e-mail. Un compte protégé par
 * la double authentification doit d'abord saisir son code : le serveur refuse
 * le changement sans lui.
 */
export function RecoveryPage() {
  const db = useDb();
  const { finishRecovery } = useAuth();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [code, setCode] = useState("");
  const [needCode, setNeedCode] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    const problem = passwordProblem(password);
    if (problem) {
      setError(problem);
      return;
    }
    if (password !== confirm) {
      setError("Les deux mots de passe sont différents.");
      return;
    }
    if (needCode && !isTotpCode(code.trim())) {
      setError("Le code compte six chiffres.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (needCode) {
        const { data } = await db.auth.mfa.listFactors();
        const factor = data?.totp[0];
        if (!factor) throw new Error("aucun facteur");
        const { error: e } = await db.auth.mfa.challengeAndVerify({ factorId: factor.id, code: code.trim() });
        if (e) {
          report("code de réinitialisation", e);
          setCode("");
          setError("Code incorrect ou expiré.");
          return;
        }
      }
      const { error: e } = await db.auth.updateUser({ password });
      if (e?.code === "insufficient_aal") {
        setNeedCode(true);
        setError("Saisissez le code de votre application d'authentification.");
        return;
      }
      if (e?.code === "same_password") {
        setError("Choisissez un mot de passe différent de l'ancien.");
        return;
      }
      if (e) {
        report("nouveau mot de passe", e);
        setError(e.code === "weak_password" ? "Mot de passe trop simple." : "Le mot de passe n'a pas pu être changé. Réessayez.");
        return;
      }
      await finishRecovery();
    } catch (e) {
      report("nouveau mot de passe", e);
      setError("Le mot de passe n'a pas pu être changé. Réessayez.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="page-glow grid min-h-screen place-items-center p-6">
      <div className="w-full max-w-sm rounded-2xl border border-line bg-raised p-8 shadow-lg">
        <div className="mb-6 flex items-center gap-2.5">
          <div className="grid size-8.5 place-items-center rounded-[0.6rem] bg-brand text-white">
            <KeyRound className="size-4.5" />
          </div>
          <h1 className="text-xl">Nouveau mot de passe</h1>
        </div>
        <p className="mb-6 text-sm text-fg-muted">
          Au moins 10 caractères, avec une minuscule, une majuscule et un chiffre. Toutes les sessions ouvertes seront
          fermées.
        </p>
        <form className="grid gap-4" onSubmit={(e) => { e.preventDefault(); void submit(); }} noValidate>
          <Field label="Nouveau mot de passe" htmlFor="new-password">
            <Input id="new-password" type="password" autoComplete="new-password" value={password} onChange={(e) => { setPassword(e.target.value); }} />
          </Field>
          <Field label="Confirmer le mot de passe" htmlFor="confirm-password">
            <Input id="confirm-password" type="password" autoComplete="new-password" value={confirm} onChange={(e) => { setConfirm(e.target.value); }} />
          </Field>
          {needCode && (
            <Field label="Code à six chiffres" htmlFor="totp">
              <Input id="totp" inputMode="numeric" autoComplete="one-time-code" maxLength={6} value={code} onChange={(e) => { setCode(e.target.value); }} />
            </Field>
          )}
          {error && (
            <p className="flex items-start gap-2 rounded-lg border border-danger-border bg-danger-muted px-3 py-2.5 text-sm text-danger" role="alert">
              <CircleAlert className="mt-0.5 size-4 shrink-0" /> {error}
            </p>
          )}
          <Button type="submit" loading={busy} className="w-full">Enregistrer le mot de passe</Button>
        </form>
      </div>
    </main>
  );
}

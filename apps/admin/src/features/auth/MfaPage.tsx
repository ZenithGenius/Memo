import { CircleAlert, ShieldCheck } from "lucide-react";
import { useEffect, useState } from "react";
import { useAuth } from "@/app/auth";
import { useDb } from "@/app/db-context";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/form";
import { report } from "@/lib/errors";
import { isTotpCode } from "@/lib/mfa";

interface Enrollment {
  factorId: string;
  qrCode: string;
  secret: string;
}

const WRONG_CODE = "Code incorrect ou expiré. Saisissez le code affiché maintenant.";

/**
 * Second facteur obligatoire pour l'administration : code d'une application
 * d'authentification (TOTP). Configuration au premier passage, puis code à
 * chaque connexion. Perte du téléphone : voir le README (procédure de secours).
 */
export function MfaPage({ step }: { step: "verify" | "enroll" }) {
  const db = useDb();
  const { completeMfa, signOut } = useAuth();
  const [factorId, setFactorId] = useState<string | null>(null);
  const [enrollment, setEnrollment] = useState<Enrollment | null>(null);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Facteur déjà configuré : celui à vérifier.
  useEffect(() => {
    if (step !== "verify") return;
    void db.auth.mfa.listFactors().then(({ data, error: e }) => {
      if (e) report("facteurs", e);
      const factor = data?.totp[0];
      if (factor) setFactorId(factor.id);
      else setError("Aucun facteur trouvé. Déconnectez-vous puis reconnectez-vous.");
    });
  }, [db, step]);

  const startEnrollment = async () => {
    setBusy(true);
    setError(null);
    try {
      // Une configuration abandonnée laisse un facteur non vérifié qui bloquerait
      // la suivante : on le retire avant d'en créer un nouveau.
      const { data: factors } = await db.auth.mfa.listFactors();
      for (const f of factors?.all ?? []) {
        if (f.factor_type === "totp" && f.status === "unverified") await db.auth.mfa.unenroll({ factorId: f.id });
      }
      const { data, error: e } = await db.auth.mfa.enroll({
        factorType: "totp",
        friendlyName: "Memo administration",
        issuer: "Memo administration",
      });
      if (e) throw e;
      setEnrollment({ factorId: data.id, qrCode: data.totp.qr_code, secret: data.totp.secret });
      setFactorId(data.id);
    } catch (e) {
      report("configuration double authentification", e);
      setError("La configuration n'a pas pu démarrer. Réessayez.");
    } finally {
      setBusy(false);
    }
  };

  const verify = async () => {
    if (!factorId) return;
    const value = code.trim();
    if (!isTotpCode(value)) {
      setError("Le code compte six chiffres.");
      return;
    }
    setBusy(true);
    setError(null);
    const { error: e } = await db.auth.mfa.challengeAndVerify({ factorId, code: value });
    setBusy(false);
    if (e) {
      report("vérification double authentification", e);
      setError(WRONG_CODE);
      setCode("");
      return;
    }
    await completeMfa();
  };

  const showCodeForm = step === "verify" || enrollment !== null;

  return (
    <main className="page-glow grid min-h-screen place-items-center p-6">
      <div className="w-full max-w-sm rounded-2xl border border-line bg-raised p-8 shadow-lg">
        <div className="mb-6 flex items-center gap-2.5">
          <div className="grid size-8.5 place-items-center rounded-[0.6rem] bg-brand text-white">
            <ShieldCheck className="size-4.5" />
          </div>
          <h1 className="text-xl">Double authentification</h1>
        </div>

        {step === "enroll" && !enrollment && (
          <div className="grid gap-4">
            <p className="text-sm text-fg-muted">
              L'administration exige un code temporaire en plus du mot de passe. Installez une application
              d'authentification (Google Authenticator, Microsoft Authenticator, Aegis…) puis configurez-la.
            </p>
            <Button onClick={() => void startEnrollment()} loading={busy} className="w-full">Configurer</Button>
          </div>
        )}

        {enrollment && (
          <div className="mb-5 grid gap-3">
            <p className="text-sm text-fg-muted">Scannez ce code avec l'application, puis saisissez le code à six chiffres affiché.</p>
            <img src={enrollment.qrCode} alt="Code QR de configuration" className="mx-auto size-44 rounded-lg bg-white p-2" />
            <p className="text-xs text-fg-muted">
              Sans appareil photo, saisissez cette clé dans l'application :{" "}
              <code className="break-all text-fg select-all">{enrollment.secret}</code>
            </p>
          </div>
        )}

        {showCodeForm && (
          <form
            className="grid gap-4"
            onSubmit={(e) => {
              e.preventDefault();
              void verify();
            }}
            noValidate
          >
            {step === "verify" && <p className="text-sm text-fg-muted">Saisissez le code affiché par votre application d'authentification.</p>}
            <Field label="Code à six chiffres" htmlFor="totp">
              <Input
                id="totp"
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={6}
                value={code}
                onChange={(e) => {
                  setCode(e.target.value.replace(/\D/g, ""));
                }}
                autoFocus
              />
            </Field>
            <Button type="submit" loading={busy} disabled={!factorId} className="w-full">Valider</Button>
          </form>
        )}

        {error && (
          <p className="mt-4 flex items-start gap-2 rounded-lg border border-danger-border bg-danger-muted px-3 py-2.5 text-sm text-danger" role="alert">
            <CircleAlert className="mt-0.5 size-4 shrink-0" /> {error}
          </p>
        )}

        <Button variant="ghost" onClick={() => void signOut()} className="mt-4 w-full">Se déconnecter</Button>
      </div>
    </main>
  );
}

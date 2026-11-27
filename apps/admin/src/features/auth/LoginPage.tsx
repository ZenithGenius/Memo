import { zodResolver } from "@hookform/resolvers/zod";
import { CircleAlert, CircleCheck } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useAuth } from "@/app/auth";
import { Button } from "@/components/ui/button";
import { Field, Input } from "@/components/ui/form";

const schema = z.object({
  email: z.email("Adresse e-mail invalide."),
  password: z.string().min(1, "Mot de passe requis."),
});

const resetSchema = z.object({ email: z.email("Adresse e-mail invalide.") });

/** Même réponse que l'adresse existe ou non : la page ne révèle aucun compte. */
const RESET_SENT = "Si un compte existe pour cette adresse, un lien vient d'être envoyé. Il est valable une heure.";

export function LoginPage({ reason, notice }: { reason?: string | undefined; notice?: string | undefined }) {
  const { signIn, requestReset } = useAuth();
  const [forgot, setForgot] = useState(false);
  const [error, setError] = useState<string | null>(reason ?? null);
  const [info, setInfo] = useState<string | null>(notice ?? null);
  const { register, handleSubmit, formState } = useForm({ resolver: zodResolver(schema) });
  const reset = useForm({ resolver: zodResolver(resetSchema) });

  const onSubmit = handleSubmit(async ({ email, password }) => {
    setError(null);
    setInfo(null);
    setError(await signIn(email, password));
  });

  const onReset = reset.handleSubmit(async ({ email }) => {
    setError(null);
    const failure = await requestReset(email);
    if (failure) setError(failure);
    else setInfo(RESET_SENT);
  });

  const switchMode = (next: boolean) => {
    setForgot(next);
    setError(null);
    setInfo(null);
  };

  const messages = (
    <>
      {error && (
        <p className="flex items-start gap-2 rounded-lg border border-danger-border bg-danger-muted px-3 py-2.5 text-sm text-danger" role="alert">
          <CircleAlert className="mt-0.5 size-4 shrink-0" /> {error}
        </p>
      )}
      {info && (
        <p className="flex items-start gap-2 rounded-lg border border-success-border bg-success-muted px-3 py-2.5 text-sm text-success" role="status">
          <CircleCheck className="mt-0.5 size-4 shrink-0" /> {info}
        </p>
      )}
    </>
  );

  return (
    <main className="page-glow grid min-h-screen place-items-center p-6">
      <div className="w-full max-w-sm rounded-2xl border border-line bg-raised p-8 shadow-lg">
        <div className="mb-7 flex items-center gap-2.5">
          <div className="grid size-8.5 place-items-center rounded-[0.6rem] bg-brand font-heading font-bold text-white">M</div>
          <div className="leading-tight">
            <div className="font-heading font-semibold text-fg">Memo</div>
            <div className="text-[0.68rem] tracking-[0.08em] text-fg-muted uppercase">Administration</div>
          </div>
        </div>
        {forgot ? (
          <>
            <h1 className="text-xl">Mot de passe oublié</h1>
            <p className="mt-1 mb-6 text-sm text-fg-muted">Recevez par e-mail un lien pour choisir un nouveau mot de passe.</p>
            <form className="grid gap-4" onSubmit={(e) => void onReset(e)} noValidate>
              <Field label="E-mail" htmlFor="reset-email" error={reset.formState.errors.email?.message}>
                <Input id="reset-email" type="email" autoComplete="username" placeholder="vous@exemple.com" {...reset.register("email")} />
              </Field>
              {messages}
              <Button type="submit" loading={reset.formState.isSubmitting} className="w-full">Envoyer le lien</Button>
              <Button variant="ghost" className="w-full" onClick={() => { switchMode(false); }}>Retour à la connexion</Button>
            </form>
          </>
        ) : (
          <>
        <h1 className="text-xl">Connexion</h1>
        <p className="mt-1 mb-6 text-sm text-fg-muted">Réservé à l'équipe Memo.</p>
        <form className="grid gap-4" onSubmit={(e) => void onSubmit(e)} noValidate>
          <Field label="E-mail" htmlFor="email" error={formState.errors.email?.message}>
            <Input id="email" type="email" autoComplete="username" placeholder="vous@exemple.com" {...register("email")} />
          </Field>
          <Field label="Mot de passe" htmlFor="password" error={formState.errors.password?.message}>
            <Input id="password" type="password" autoComplete="current-password" placeholder="Votre mot de passe" {...register("password")} />
          </Field>
          {messages}
          <Button type="submit" loading={formState.isSubmitting} className="w-full">Se connecter</Button>
          <Button variant="ghost" className="w-full" onClick={() => { switchMode(true); }}>Mot de passe oublié ?</Button>
        </form>
          </>
        )}
      </div>
    </main>
  );
}

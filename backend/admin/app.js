import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

let SUPABASE_URL, SUPABASE_ANON_KEY;
try {
  ({ SUPABASE_URL, SUPABASE_ANON_KEY } = await import("./config.js"));
} catch {
  document.body.innerHTML =
    "<p style='padding:2rem;font-family:sans-serif'>" +
    "config.js manquant. Copier config.example.js vers config.js et le renseigner.</p>";
  throw new Error("config.js manquant");
}

const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const $ = (id) => document.getElementById(id);
const fcfa = (n) => new Intl.NumberFormat("fr-FR").format(n) + " FCFA";
const dateFr = (iso) => (iso ? new Date(iso).toLocaleDateString("fr-FR") : "—");
// Échappement : display_name, phone et email sont modifiables par le compte
// lui-même (accounts_own_update) et affichés ici dans l'écran admin.
const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const toast = (msg) => {
  const t = document.createElement("div");
  t.className = "toast";
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 3000);
};

let plans = [];

// --- Connexion ---------------------------------------------------------

async function checkSession() {
  const { data: { session } } = await sb.auth.getSession();
  if (!session) return showLogin();

  // L'accès réel est décidé par is_admin() côté base (RLS) ; cette lecture
  // sert seulement à afficher le bon écran tout de suite.
  const { data, error } = await sb.from("admins").select("user_id").eq("user_id", session.user.id).maybeSingle();
  if (error || !data) {
    await sb.auth.signOut();
    return showLogin("Ce compte n'est pas administrateur.");
  }
  $("whoami").textContent = session.user.email; // textContent : pas d'échappement nécessaire
  showApp();
}

function showLogin(error = "") {
  $("login-view").classList.remove("hidden");
  $("app-view").classList.add("hidden");
  $("login-error").textContent = error;
}

async function showApp() {
  $("login-view").classList.add("hidden");
  $("app-view").classList.remove("hidden");
  await loadPlans();
  await loadKpis();
}

$("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  $("login-error").textContent = "";
  const { error } = await sb.auth.signInWithPassword({
    email: $("login-email").value.trim(),
    password: $("login-password").value,
  });
  if (error) return ($("login-error").textContent = "Identifiants invalides.");
  checkSession();
});

$("logout-btn").addEventListener("click", async () => {
  await sb.auth.signOut();
  showLogin();
});

// --- Tableau de bord -----------------------------------------------------

async function loadKpis() {
  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);

  const { data: subs, error } = await sb
    .from("subscriptions")
    .select("user_id, status, valid_until, created_at, plans(price_fcfa)");
  if (error) return toast("Erreur de chargement des abonnements : " + error.message);

  const now = new Date();
  const active = subs.filter((s) => s.status === "active" && new Date(s.valid_until) > now);
  const activeUsers = new Set(active.map((s) => s.user_id));

  // Premier abonnement de chaque compte, pour distinguer un nouvel abonné
  // d'un simple renouvellement.
  const firstByUser = new Map();
  for (const s of subs) {
    const prev = firstByUser.get(s.user_id);
    if (!prev || new Date(s.created_at) < new Date(prev)) firstByUser.set(s.user_id, s.created_at);
  }
  const newThisMonth = [...firstByUser.values()].filter((d) => new Date(d) >= monthStart).length;

  const revoked = subs.filter((s) => s.status === "revoked").length;
  const mrr = active.reduce((sum, s) => sum + (s.plans?.price_fcfa ?? 0), 0);

  const { count: integrityAlerts } = await sb
    .from("devices")
    .select("id", { count: "exact", head: true })
    .is("revoked_at", null)
    .in("integrity_level", ["basic", "failed"]);

  const kpis = [
    ["Abonnés actifs", activeUsers.size],
    ["Nouveaux abonnés ce mois", newThisMonth],
    // ponytail: pas de colonne updated_at sur subscriptions, donc pas de
    // fenêtre temporelle fiable ici ; total affiché, pas "ce mois".
    ["Résiliations (total)", revoked],
    ["Revenu mensuel estimé", fcfa(mrr)],
    ["Alertes d'intégrité appareil", integrityAlerts ?? 0],
  ];
  $("kpis").innerHTML = kpis
    .map(([label, value]) => `<div class="card kpi"><div class="label">${label}</div><div class="value">${value}</div></div>`)
    .join("");
}

async function loadPlans() {
  const { data, error } = await sb.from("plans").select("code, name, period_days, price_fcfa").order("sort_order");
  if (error) return toast("Erreur de chargement des offres : " + error.message);
  plans = data;
  $("activate-plan").innerHTML = plans
    .map((p) => `<option value="${esc(p.code)}">${esc(p.name)} — ${fcfa(p.price_fcfa)} / ${p.period_days} j</option>`)
    .join("");
}

// --- Recherche de compte ---------------------------------------------------

$("search-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const query = $("search-input").value.trim();
  if (!query) return;
  const { data, error } = await sb.rpc("admin_search_account", { query });
  if (error) return toast("Erreur de recherche : " + error.message);
  $("search-results").innerHTML = data.length
    ? data
        .map(
          (a) => `<div class="result" data-id="${a.user_id}" data-email="${esc(a.email)}">
            <span>${esc(a.email)}${a.display_name ? " — " + esc(a.display_name) : ""}</span>
            <span style="color:var(--muted);font-size:.85rem">${dateFr(a.created_at)}</span>
          </div>`
        )
        .join("")
    : "<p style='color:var(--muted)'>Aucun résultat.</p>";
});

$("search-results").addEventListener("click", (e) => {
  const row = e.target.closest(".result");
  if (row) openAccount(row.dataset.id, row.dataset.email);
});

// --- Fiche compte ---------------------------------------------------------

let currentUserId = null;

async function openAccount(userId, email) {
  currentUserId = userId;
  $("account-email").textContent = email;
  $("account-dialog").showModal();
  await refreshAccount();
}

async function refreshAccount() {
  const [{ data: subs }, { data: devices }, { data: issuances }] = await Promise.all([
    sb.from("subscriptions").select("id, plan_code, valid_until, status, plans(name)").eq("user_id", currentUserId).order("valid_until", { ascending: false }),
    sb.from("devices").select("id, platform, integrity_level, last_seen, revoked_at").eq("user_id", currentUserId).order("last_seen", { ascending: false }),
    sb.from("license_issuances").select("issued_at, valid_until, key_id, integrity_level").eq("user_id", currentUserId).order("issued_at", { ascending: false }).limit(10),
  ]);

  $("subscriptions-table").querySelector("tbody").innerHTML = (subs ?? [])
    .map((s) => {
      const active = s.status === "active" && new Date(s.valid_until) > new Date();
      return `<tr>
        <td>${esc(s.plans?.name ?? s.plan_code)}</td>
        <td>${dateFr(s.valid_until)}</td>
        <td><span class="badge ${active ? "ok" : s.status === "revoked" ? "off" : "warn"}">${active ? "actif" : esc(s.status)}</span></td>
        <td>${active ? `<button class="secondary danger revoke-sub" data-id="${s.id}">Résilier</button>` : ""}</td>
      </tr>`;
    })
    .join("");

  $("devices-table").querySelector("tbody").innerHTML = (devices ?? [])
    .map(
      (d) => `<tr>
        <td>${esc(d.platform)}</td>
        <td><span class="badge ${d.integrity_level === "strong" ? "ok" : d.integrity_level === "unknown" ? "warn" : "off"}">${esc(d.integrity_level)}</span></td>
        <td>${dateFr(d.last_seen)}</td>
        <td>${d.revoked_at ? "révoqué" : "actif"}</td>
        <td><button class="secondary ${d.revoked_at ? "" : "danger"} toggle-device" data-id="${d.id}" data-revoke="${d.revoked_at ? "0" : "1"}">${d.revoked_at ? "Rétablir" : "Révoquer"}</button></td>
      </tr>`
    )
    .join("");

  $("issuances-table").querySelector("tbody").innerHTML = (issuances ?? [])
    .map(
      (i) => `<tr>
        <td>${dateFr(i.issued_at)}</td>
        <td>${dateFr(i.valid_until)}</td>
        <td>${esc(i.key_id)}</td>
        <td><span class="badge ${i.integrity_level === "strong" ? "ok" : "warn"}">${esc(i.integrity_level)}</span></td>
      </tr>`
    )
    .join("");

  const defaultPlan = plans[0];
  if (defaultPlan) {
    const d = new Date();
    d.setDate(d.getDate() + defaultPlan.period_days);
    $("activate-until").value = d.toISOString().slice(0, 10);
  }
}

$("account-close").addEventListener("click", () => $("account-dialog").close());

$("activate-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const { data: { session } } = await sb.auth.getSession();
  const { error } = await sb.from("subscriptions").insert({
    user_id: currentUserId,
    plan_code: $("activate-plan").value,
    valid_until: new Date($("activate-until").value).toISOString(),
    activated_by: session.user.id,
    note: $("activate-note").value || null,
  });
  if (error) return toast("Erreur : " + error.message);
  $("activate-note").value = "";
  toast("Abonnement activé.");
  await refreshAccount();
  await loadKpis();
});

$("subscriptions-table").addEventListener("click", async (e) => {
  const btn = e.target.closest(".revoke-sub");
  if (!btn) return;
  if (!confirm("Résilier cet abonnement ?")) return;
  const { error } = await sb.from("subscriptions").update({ status: "revoked" }).eq("id", btn.dataset.id);
  if (error) return toast("Erreur : " + error.message);
  await refreshAccount();
  await loadKpis();
});

$("devices-table").addEventListener("click", async (e) => {
  const btn = e.target.closest(".toggle-device");
  if (!btn) return;
  const revoke = btn.dataset.revoke === "1";
  if (revoke && !confirm("Révoquer cet appareil ?")) return;
  const { error } = await sb.from("devices").update({ revoked_at: revoke ? new Date().toISOString() : null }).eq("id", btn.dataset.id);
  if (error) return toast("Erreur : " + error.message);
  await refreshAccount();
});

checkSession();

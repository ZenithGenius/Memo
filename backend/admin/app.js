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

// --- Utilitaires ------------------------------------------------------------

const $ = (id) => document.getElementById(id);
const fcfa = (n) => new Intl.NumberFormat("fr-FR").format(n) + " FCFA";
const dateFr = (iso) => (iso ? new Date(iso).toLocaleDateString("fr-FR", { day: "2-digit", month: "short", year: "numeric" }) : "—");
const dateTimeFr = (iso) => (iso ? new Date(iso).toLocaleString("fr-FR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" }) : "—");
// Échappement : display_name, phone et email sont modifiables par le compte
// lui-même (accounts_own_update) et affichés ici dans l'écran admin.
const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const icon = (name, style = "") => `<svg class="icon" ${style ? `style="${style}"` : ""}><use href="#i-${name}"/></svg>`;
const initial = (s) => esc((s || "?").trim().charAt(0).toUpperCase());

function toast(message, kind = "success") {
  const t = document.createElement("div");
  t.className = `toast ${kind}`;
  t.innerHTML = `${icon(kind === "error" ? "alert" : "check")}<span></span>`;
  t.querySelector("span").textContent = message;
  $("toasts").appendChild(t);
  setTimeout(() => t.remove(), kind === "error" ? 6000 : 3200);
}

function confirmAction(title, text, okLabel = "Confirmer") {
  const dialog = $("confirm-dialog");
  $("confirm-title").textContent = title;
  $("confirm-text").textContent = text;
  $("confirm-ok").textContent = okLabel;
  dialog.showModal();
  return new Promise((resolve) => dialog.addEventListener("close", () => resolve(dialog.returnValue === "ok"), { once: true }));
}

async function withLoading(button, fn) {
  const html = button.innerHTML;
  button.disabled = true;
  button.innerHTML = `<span class="spinner"></span>${esc(button.textContent.trim())}`;
  try {
    return await fn();
  } finally {
    button.disabled = false;
    button.innerHTML = html;
  }
}

const skeleton = (rows = 4) =>
  `<div class="skeleton">${Array.from({ length: rows }, (_, i) => `<div class="skeleton-row" style="width:${92 - i * 9}%"></div>`).join("")}</div>`;

const empty = (iconName, title, text) =>
  `<div class="empty"><div class="empty-icon">${icon(iconName)}</div><div class="empty-title">${title}</div><div class="empty-text">${text}</div></div>`;

const INTEGRITY = {
  strong: ["success", "Forte"],
  unknown: ["neutral", "Non évaluée"],
  basic: ["warning", "Basique"],
  failed: ["danger", "Échec"],
};
const integrityBadge = (level) => {
  const [kind, label] = INTEGRITY[level] ?? ["neutral", level];
  return `<span class="badge ${kind}">${esc(label)}</span>`;
};

// --- Thème ------------------------------------------------------------------

function applyThemeIcon() {
  const dark = document.documentElement.classList.contains("dark");
  $("theme-btn").innerHTML = icon(dark ? "sun" : "moon");
}

$("theme-btn").addEventListener("click", () => {
  const dark = document.documentElement.classList.toggle("dark");
  try { localStorage.setItem("memo-admin-theme", dark ? "dark" : "light"); } catch {}
  applyThemeIcon();
});
applyThemeIcon();

// --- Connexion --------------------------------------------------------------

function showLoginError(message) {
  const box = $("login-error");
  box.classList.toggle("hidden", !message);
  box.querySelector("span").textContent = message || "";
}

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
  const email = session.user.email ?? "";
  $("user-initial").textContent = (email.charAt(0) || "?").toUpperCase();
  $("user-label").textContent = email.split("@")[0];
  $("user-mail").textContent = email;
  showApp();
}

function showLogin(error = "") {
  $("login-view").classList.remove("hidden");
  $("app-view").classList.add("hidden");
  showLoginError(error);
}

async function showApp() {
  $("login-view").classList.add("hidden");
  $("app-view").classList.remove("hidden");
  await loadPlans();
  route();
}

$("login-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  showLoginError("");
  await withLoading($("login-submit"), async () => {
    const { error } = await sb.auth.signInWithPassword({
      email: $("login-email").value.trim(),
      password: $("login-password").value,
    });
    // Le message exact (clé API invalide, e-mail non confirmé, etc.) aide à
    // diagnostiquer un config.js mal renseigné : erreur courante, la clé
    // "secret"/service_role n'est pas la clé "anon" attendue ici.
    if (error) return showLoginError(error.message === "Invalid login credentials" ? "E-mail ou mot de passe incorrect." : error.message);
    await checkSession();
  });
});

// --- Coquille : navigation, menu utilisateur --------------------------------

const ROUTES = { "tableau-de-bord": "Tableau de bord", comptes: "Comptes" };

function route() {
  const name = location.hash.replace("#/", "") in ROUTES ? location.hash.replace("#/", "") : "tableau-de-bord";
  for (const r of Object.keys(ROUTES)) $(`page-${r}`).classList.toggle("hidden", r !== name);
  document.querySelectorAll(".nav-item").forEach((a) => a.classList.toggle("active", a.dataset.route === name));
  $("crumb-current").textContent = ROUTES[name];
  $("app-view").classList.remove("nav-open");
  if (name === "tableau-de-bord") loadDashboard();
  else searchAccounts($("search-input").value.trim());
}
window.addEventListener("hashchange", route);

$("menu-btn").addEventListener("click", () => $("app-view").classList.add("nav-open"));
$("nav-overlay").addEventListener("click", () => $("app-view").classList.remove("nav-open"));

$("user-btn").addEventListener("click", (e) => {
  e.stopPropagation();
  $("user-menu").classList.toggle("hidden");
});
document.addEventListener("click", (e) => {
  if (!e.target.closest(".user-chip")) $("user-menu").classList.add("hidden");
});

$("logout-btn").addEventListener("click", async () => {
  await sb.auth.signOut();
  $("user-menu").classList.add("hidden");
  showLogin();
});

// --- Tableau de bord --------------------------------------------------------

let plans = [];

async function loadPlans() {
  const { data, error } = await sb.from("plans").select("code, name, period_days, price_fcfa").order("sort_order");
  if (error) return toast("Offres indisponibles : " + error.message, "error");
  plans = data;
  $("activate-plan").innerHTML = plans
    .map((p) => `<option value="${esc(p.code)}">${esc(p.name)} · ${fcfa(p.price_fcfa)} / ${p.period_days} j</option>`)
    .join("");
}

async function loadDashboard() {
  $("kpis").innerHTML = Array.from({ length: 5 }, () => `<div class="card kpi">${skeleton(3)}</div>`).join("");
  $("recent-issuances").innerHTML = skeleton(5);
  $("integrity-alerts").innerHTML = skeleton(4);

  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);

  const [subsRes, alertsRes, issuancesRes] = await Promise.all([
    sb.from("subscriptions").select("user_id, status, valid_until, created_at, plans(price_fcfa)"),
    sb.from("devices").select("id, platform, integrity_level, last_seen, installed_from_store").is("revoked_at", null).in("integrity_level", ["basic", "failed"]).order("last_seen", { ascending: false }),
    sb.from("license_issuances").select("issued_at, valid_until, key_id, integrity_level, devices(platform)").order("issued_at", { ascending: false }).limit(10),
  ]);
  if (subsRes.error) return toast("Abonnements indisponibles : " + subsRes.error.message, "error");

  const subs = subsRes.data;
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
  const alerts = alertsRes.data ?? [];

  const kpis = [
    ["Abonnés actifs", activeUsers.size, "users", "blue", "Abonnement en cours"],
    ["Nouveaux abonnés", newThisMonth, "user-plus", "green", "Premier abonnement ce mois"],
    // ponytail: pas de colonne updated_at sur subscriptions, donc pas de
    // fenêtre temporelle fiable ici ; total affiché, pas « ce mois ».
    ["Résiliations", revoked, "user-x", "amber", "Total, toutes périodes"],
    ["Revenu mensuel estimé", fcfa(mrr), "wallet", "green", "Somme des offres actives"],
    ["Alertes d'intégrité", alerts.length, "shield", alerts.length ? "red" : "green", "Appareils actifs en basic ou failed"],
  ];
  $("kpis").innerHTML = kpis
    .map(
      ([label, value, ic, color, hint]) => `<div class="card kpi">
        <div class="kpi-top"><span class="kpi-label">${label}</span><span class="kpi-icon ${color}">${icon(ic)}</span></div>
        <div class="kpi-value">${value}</div>
        <div class="kpi-hint">${hint}</div>
      </div>`
    )
    .join("");

  const issuances = issuancesRes.data ?? [];
  $("recent-issuances").innerHTML = issuances.length
    ? `<div class="table-wrap"><table>
        <thead><tr><th>Émis</th><th>Appareil</th><th>Valide jusqu'au</th><th>Clé</th><th>Intégrité</th></tr></thead>
        <tbody>${issuances
          .map(
            (i) => `<tr>
              <td>${dateTimeFr(i.issued_at)}</td>
              <td><span class="chip">${esc(i.devices?.platform ?? "—")}</span></td>
              <td>${dateFr(i.valid_until)}</td>
              <td class="mono">${esc(i.key_id)}</td>
              <td>${integrityBadge(i.integrity_level)}</td>
            </tr>`
          )
          .join("")}</tbody></table></div>`
    : empty("key", "Aucun jeton émis", "Les jetons apparaissent ici à la première synchronisation d'un abonné.");

  $("integrity-alerts").innerHTML = alerts.length
    ? `<div class="table-wrap"><table>
        <thead><tr><th>Appareil</th><th>Intégrité</th><th>Vu le</th></tr></thead>
        <tbody>${alerts
          .map(
            (d) => `<tr>
              <td><div class="cell-main">${esc(d.platform)}</div><div class="cell-sub">${d.installed_from_store === false ? "Hors boutique" : "Boutique"}</div></td>
              <td>${integrityBadge(d.integrity_level)}</td>
              <td>${dateFr(d.last_seen)}</td>
            </tr>`
          )
          .join("")}</tbody></table></div>`
    : empty("shield", "Aucune alerte", "Tous les appareils actifs ont une intégrité correcte ou non évaluée.");
}

$("refresh-btn").addEventListener("click", (e) => withLoading(e.currentTarget, loadDashboard));

// --- Comptes ----------------------------------------------------------------

let searchTimer;
$("search-input").addEventListener("input", () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => searchAccounts($("search-input").value.trim()), 250);
});
$("search-form").addEventListener("submit", (e) => {
  e.preventDefault();
  searchAccounts($("search-input").value.trim());
});

async function searchAccounts(query) {
  $("accounts").innerHTML = skeleton(6);
  // Requête vide : les 20 comptes les plus récents.
  const { data, error } = await sb.rpc("admin_search_account", { query });
  if (error) {
    $("accounts").innerHTML = empty("alert", "Recherche impossible", esc(error.message));
    return;
  }
  if (!data.length) {
    $("accounts").innerHTML = query
      ? empty("search", "Aucun compte trouvé", "Essayez un autre e-mail, numéro ou nom.")
      : empty("users", "Aucun compte", "Les comptes créés depuis l'application apparaîtront ici.");
    return;
  }

  const ids = data.map((a) => a.user_id);
  const { data: activeSubs } = await sb
    .from("subscriptions")
    .select("user_id, valid_until, plans(name)")
    .in("user_id", ids)
    .eq("status", "active")
    .gt("valid_until", new Date().toISOString())
    .order("valid_until", { ascending: false });
  const current = new Map();
  for (const s of activeSubs ?? []) if (!current.has(s.user_id)) current.set(s.user_id, s);

  $("accounts").innerHTML = `<div class="table-wrap"><table>
    <thead><tr><th>Compte</th><th>Téléphone</th><th>Abonnement</th><th>Inscrit le</th><th></th></tr></thead>
    <tbody>${data
      .map((a) => {
        const sub = current.get(a.user_id);
        return `<tr class="clickable" data-id="${esc(a.user_id)}" data-email="${esc(a.email)}" data-created="${esc(a.created_at)}">
          <td><div class="cell-main">${esc(a.email)}</div><div class="cell-sub">${a.display_name ? esc(a.display_name) : "Sans nom"}</div></td>
          <td class="${a.phone ? "" : "muted"}">${a.phone ? esc(a.phone) : "—"}</td>
          <td>${sub ? `<span class="badge success">${esc(sub.plans?.name)}</span> <span class="cell-sub">jusqu'au ${dateFr(sub.valid_until)}</span>` : `<span class="badge neutral">Gratuit</span>`}</td>
          <td>${dateFr(a.created_at)}</td>
          <td class="text-right muted">${icon("chevron")}</td>
        </tr>`;
      })
      .join("")}</tbody></table></div>`;
}

$("accounts").addEventListener("click", (e) => {
  const row = e.target.closest("tr[data-id]");
  if (row) openAccount(row.dataset.id, row.dataset.email, row.dataset.created);
});

// --- Fiche compte (tiroir) --------------------------------------------------

let currentUserId = null;

function openAccount(userId, email, createdAt) {
  currentUserId = userId;
  $("drawer-avatar").innerHTML = initial(email);
  $("drawer-email").textContent = email;
  $("drawer-meta").textContent = `Inscrit le ${dateFr(createdAt)}`;
  $("drawer-root").classList.remove("hidden");
  document.body.style.overflow = "hidden";
  refreshAccount();
}

// Prolonger part de la fin de l'abonnement en cours, pas d'aujourd'hui :
// un abonné qui paie en avance ne perd pas les jours restants.
let activeUntil = null;
function setDefaultUntil() {
  const plan = plans.find((p) => p.code === $("activate-plan").value) ?? plans[0];
  if (!plan) return;
  const start = activeUntil && activeUntil > new Date() ? new Date(activeUntil) : new Date();
  start.setDate(start.getDate() + plan.period_days);
  $("activate-until").value = start.toISOString().slice(0, 10);
}

function closeDrawer() {
  $("drawer-root").classList.add("hidden");
  document.body.style.overflow = "";
  currentUserId = null;
}
$("drawer-close").addEventListener("click", closeDrawer);
$("drawer-backdrop").addEventListener("click", closeDrawer);
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && !$("drawer-root").classList.contains("hidden") && !$("confirm-dialog").open) closeDrawer();
});

$("activate-plan").addEventListener("change", setDefaultUntil);

async function refreshAccount() {
  $("drawer-subs").innerHTML = skeleton(3);
  $("drawer-devices").innerHTML = skeleton(2);
  $("drawer-issuances").innerHTML = skeleton(3);

  const [{ data: subs }, { data: devices }, { data: issuances }] = await Promise.all([
    sb.from("subscriptions").select("id, plan_code, valid_until, status, note, plans(name)").eq("user_id", currentUserId).order("valid_until", { ascending: false }),
    sb.from("devices").select("id, platform, integrity_level, last_seen, revoked_at, installed_from_store").eq("user_id", currentUserId).order("last_seen", { ascending: false }),
    sb.from("license_issuances").select("issued_at, valid_until, key_id, integrity_level").eq("user_id", currentUserId).order("issued_at", { ascending: false }).limit(10),
  ]);

  const current = (subs ?? []).find((s) => s.status === "active" && new Date(s.valid_until) > new Date());
  activeUntil = current ? new Date(current.valid_until) : null;
  $("activate-title").textContent = current ? "Prolonger l'abonnement" : "Activer un abonnement";
  $("activate-submit").innerHTML = `${icon("badge")}${current ? "Prolonger" : "Activer l'abonnement"}`;
  if (current) $("activate-plan").value = current.plan_code;
  setDefaultUntil();

  const activeDevices = (devices ?? []).filter((d) => !d.revoked_at).length;
  $("drawer-meta").textContent = `${$("drawer-meta").textContent.split(" · ")[0]} · ${activeDevices} appareil${activeDevices > 1 ? "s" : ""} actif${activeDevices > 1 ? "s" : ""}`;

  $("drawer-subs").innerHTML = subs?.length
    ? `<div class="table-wrap"><table>
        <thead><tr><th>Offre</th><th>Valide jusqu'au</th><th>Statut</th><th></th></tr></thead>
        <tbody>${subs
          .map((s) => {
            const active = s.status === "active" && new Date(s.valid_until) > new Date();
            const badge = active
              ? `<span class="badge success">Actif</span>`
              : s.status === "revoked"
                ? `<span class="badge danger">Résilié</span>`
                : `<span class="badge neutral">Expiré</span>`;
            return `<tr>
              <td><div class="cell-main">${esc(s.plans?.name ?? s.plan_code)}</div>${s.note ? `<div class="cell-sub">${esc(s.note)}</div>` : ""}</td>
              <td>${dateFr(s.valid_until)}</td>
              <td>${badge}</td>
              <td class="text-right">${active ? `<button class="btn btn-sm btn-soft-danger revoke-sub" data-id="${esc(s.id)}">Résilier</button>` : ""}</td>
            </tr>`;
          })
          .join("")}</tbody></table></div>`
    : empty("wallet", "Aucun abonnement", "Ce compte utilise l'offre gratuite. Activez une offre ci-dessous.");

  $("drawer-devices").innerHTML = devices?.length
    ? `<div class="table-wrap"><table>
        <thead><tr><th>Appareil</th><th>Intégrité</th><th>Vu le</th><th></th></tr></thead>
        <tbody>${devices
          .map(
            (d) => `<tr>
              <td><div class="cell-main">${esc(d.platform)}</div><div class="cell-sub">${d.revoked_at ? "Révoqué le " + dateFr(d.revoked_at) : d.installed_from_store === false ? "Hors boutique" : "Actif"}</div></td>
              <td>${integrityBadge(d.integrity_level)}</td>
              <td>${dateFr(d.last_seen)}</td>
              <td class="text-right"><button class="btn btn-sm ${d.revoked_at ? "btn-soft-accent" : "btn-soft-danger"} toggle-device" data-id="${esc(d.id)}" data-revoke="${d.revoked_at ? "0" : "1"}">${d.revoked_at ? "Rétablir" : "Révoquer"}</button></td>
            </tr>`
          )
          .join("")}</tbody></table></div>`
    : empty("phone", "Aucun appareil", "L'appareil s'enregistre à la première synchronisation depuis l'application.");

  $("drawer-issuances").innerHTML = issuances?.length
    ? `<div class="table-wrap"><table>
        <thead><tr><th>Émis</th><th>Valide jusqu'au</th><th>Clé</th><th>Intégrité</th></tr></thead>
        <tbody>${issuances
          .map(
            (i) => `<tr>
              <td>${dateTimeFr(i.issued_at)}</td>
              <td>${dateFr(i.valid_until)}</td>
              <td class="mono">${esc(i.key_id)}</td>
              <td>${integrityBadge(i.integrity_level)}</td>
            </tr>`
          )
          .join("")}</tbody></table></div>`
    : empty("key", "Aucun jeton", "Aucune synchronisation pour ce compte pour l'instant.");
}

$("activate-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  await withLoading($("activate-submit"), async () => {
    const { data: { session } } = await sb.auth.getSession();
    const { error } = await sb.from("subscriptions").insert({
      user_id: currentUserId,
      plan_code: $("activate-plan").value,
      valid_until: new Date($("activate-until").value).toISOString(),
      activated_by: session.user.id,
      note: $("activate-note").value.trim() || null,
    });
    if (error) return toast("Activation impossible : " + error.message, "error");
    $("activate-note").value = "";
    toast("Abonnement activé.");
    await refreshAccount();
    searchAccounts($("search-input").value.trim());
  });
});

$("drawer-subs").addEventListener("click", async (e) => {
  const btn = e.target.closest(".revoke-sub");
  if (!btn) return;
  const ok = await confirmAction("Résilier cet abonnement ?", "Le contenu payant reste accessible jusqu'à l'expiration du jeton déjà émis (45 jours au plus), puis le compte retombe sur l'offre gratuite.", "Résilier");
  if (!ok) return;
  const { error } = await sb.from("subscriptions").update({ status: "revoked" }).eq("id", btn.dataset.id);
  if (error) return toast("Résiliation impossible : " + error.message, "error");
  toast("Abonnement résilié.");
  await refreshAccount();
  searchAccounts($("search-input").value.trim());
});

$("drawer-devices").addEventListener("click", async (e) => {
  const btn = e.target.closest(".toggle-device");
  if (!btn) return;
  const revoke = btn.dataset.revoke === "1";
  if (revoke && !(await confirmAction("Révoquer cet appareil ?", "Il ne pourra plus recevoir de jeton ni télécharger le contenu payant. Vous pourrez le rétablir plus tard.", "Révoquer"))) return;
  const { error } = await sb.from("devices").update({ revoked_at: revoke ? new Date().toISOString() : null }).eq("id", btn.dataset.id);
  if (error) return toast("Action impossible : " + error.message, "error");
  toast(revoke ? "Appareil révoqué." : "Appareil rétabli.");
  await refreshAccount();
});

checkSession();

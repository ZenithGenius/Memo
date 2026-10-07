// Thème appliqué avant le premier rendu (pas de flash clair → sombre).
// Fichier séparé plutôt qu'un script en ligne : la CSP n'autorise que 'self'.
try {
  if (localStorage.getItem("memo-admin-theme") === "dark") document.documentElement.classList.add("dark");
} catch {}

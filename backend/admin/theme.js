// Thème appliqué avant le premier rendu (pas de flash clair → sombre).
try {
  if (localStorage.getItem("memo-admin-theme") === "dark") document.documentElement.classList.add("dark");
} catch {}

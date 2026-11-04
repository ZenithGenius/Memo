# Dépendances embarquées

Servies depuis la même origine que le panneau : la politique CSP n'autorise
aucun script tiers (`script-src 'self'`), et aucune version n'est résolue au
moment de l'exécution.

| Fichier | Origine | Vérification |
|---|---|---|
| `supabase-js-2.117.3.umd.js` | `dist/umd/supabase.js` du paquet npm `@supabase/supabase-js@2.117.3` | paquet : intégrité npm `sha512-K+f8PimXDunPWQ63CKRXaF5pbVPJxmfw5ryAnh0s9S9PkwcuqBjiSpIaqpF7KLDljeYwXIL85ST8QxaO0+XuvA==` ; fichier : sha256 `d6a5c4414a5d4ce646d9c1de223aa7067d3ff664c15394ffeb7fcffc763354a3` |

Mettre à jour :

```bash
v=2.x.y
npm view @supabase/supabase-js@$v dist.integrity      # comparer avec npm pack ci-dessous
npm pack @supabase/supabase-js@$v --json | grep integrity
tar xzf supabase-supabase-js-$v.tgz package/dist/umd/supabase.js
mv package/dist/umd/supabase.js backend/admin/vendor/supabase-js-$v.umd.js
sha256sum backend/admin/vendor/supabase-js-$v.umd.js   # reporter ici
```

puis changer le nom du fichier dans `index.html` et supprimer l'ancien.

#!/usr/bin/env python3
"""SBOM CycloneDX des fonctions serveur Deno.

Les fonctions n'ont pas de fichier de verrouillage que Trivy sache lire : leurs
dépendances npm sont résolues par Deno. On lit donc le graphe que donne
`deno info --json` pour chaque point d'entrée, avec les dépendances
transitives et leurs versions exactes.

Usage : sbom_deno.py <deno> <sortie.cdx.json> <point d'entrée>...
"""
import json
import pathlib
import subprocess
import sys
import uuid
from datetime import datetime, timezone


def purl(name: str, version: str) -> str:
    # Paquet à portée (@supabase/auth-js) : le @ s'encode dans un purl.
    return f"pkg:npm/{name.replace('@', '%40', 1) if name.startswith('@') else name}@{version}"


def main() -> None:
    deno, output, *entries = sys.argv[1:]
    if not entries:
        sys.exit("au moins un point d'entrée attendu")

    packages: dict[str, dict] = {}
    for entry in entries:
        info = json.loads(subprocess.run(
            [deno, "info", "--no-lock", "--json", entry],
            check=True, capture_output=True, text=True,
        ).stdout)
        packages.update(info.get("npmPackages", {}))

    components = [
        {
            "type": "library",
            "bom-ref": key,
            "name": pkg["name"],
            "version": pkg["version"],
            "purl": purl(pkg["name"], pkg["version"]),
        }
        for key, pkg in sorted(packages.items())
    ]
    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "component": {"type": "application", "name": "memo-functions", "bom-ref": "memo-functions"},
        },
        "components": components,
        "dependencies": [
            {"ref": key, "dependsOn": sorted(pkg.get("dependencies", []))}
            for key, pkg in sorted(packages.items())
        ],
    }
    pathlib.Path(output).write_text(json.dumps(bom, indent=2) + "\n", encoding="utf-8")
    print(f"{len(components)} composants écrits dans {output}")


if __name__ == "__main__":
    main()

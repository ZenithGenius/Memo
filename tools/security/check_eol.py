#!/usr/bin/env python3
"""Contrôle de fin de vie et d'abandon des dépendances.

Échoue si :
  - un paquet pub est abandonné (discontinued), retiré (retracted) ou touché
    par un avis de sécurité pub.dev ;
  - le SDK Flutter local ou celui épinglé dans la CI a au moins MAX_MINOR_GAP
    versions mineures de retard sur la dernière stable (seule la dernière
    stable reçoit des correctifs).
Hors ligne, la vérification du SDK est ignorée avec un avertissement.
"""
import json
import pathlib
import re
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = ROOT / "apps" / "memo_app"
RELEASES = "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
MAX_MINOR_GAP = 2

problems: list[str] = []


def run(cmd: list[str], cwd: pathlib.Path) -> str:
    return subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True).stdout


def check_packages() -> None:
    data = json.loads(run(["flutter", "pub", "outdated", "--json"], APP))
    for p in data["packages"]:
        name, cur = p["package"], (p.get("current") or {}).get("version", "?")
        if p.get("isDiscontinued"):
            problems.append(f"paquet abandonné : {name} {cur}")
        if p.get("isCurrentRetracted"):
            problems.append(f"version retirée : {name} {cur}")
        if p.get("isCurrentAffectedByAdvisory"):
            problems.append(f"avis de sécurité pub.dev : {name} {cur}")


def minor(v: str) -> tuple[int, int]:
    major, mnr = v.split(".")[:2]
    return int(major), int(mnr)


def check_sdk() -> None:
    try:
        with urllib.request.urlopen(RELEASES, timeout=20) as r:
            rel = json.load(r)
    except OSError as e:
        print(f"AVERTISSEMENT : version du SDK non vérifiée (réseau indisponible : {e})")
        return
    stable = next(x for x in rel["releases"] if x["hash"] == rel["current_release"]["stable"])
    latest = stable["version"]

    local = json.loads(run(["flutter", "--version", "--machine"], APP))["frameworkVersion"]
    ci = re.search(r"flutter-version:\s*([\d.]+)", (ROOT / ".github/workflows/ci.yml").read_text())
    for label, ver in (("Flutter local", local), ("Flutter épinglé en CI", ci.group(1) if ci else None)):
        if not ver:
            continue
        (lm, ln), (vm, vn) = minor(latest), minor(ver)
        if lm != vm or ln - vn >= MAX_MINOR_GAP:
            problems.append(f"{label} {ver} périmé : dernière stable {latest}")


check_packages()
check_sdk()

if problems:
    print("Fin de vie ou abandon détecté :")
    for p in problems:
        print(f"  - {p}")
    sys.exit(1)
print("Aucun paquet abandonné, retiré ou vulnérable ; SDK à jour.")

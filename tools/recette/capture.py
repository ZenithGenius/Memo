#!/usr/bin/env python3
"""Capture d'écran annotée de Memo (émulateur ou téléphone via adb), pour la recette.

Les repères (cadre rouge et pastille numérotée) se placent par le texte ou
la description d'accessibilité des éléments, lus dans l'arbre de l'écran :
pas de coordonnées à saisir.

  python3 capture.py sortie.png --repere "Suivant" --repere "Enfant"
  python3 capture.py sortie.png --repere "Encore" --flou "joumessi"   # flouter un texte
  python3 capture.py sortie.png --repere "Fini" --kiwi-execution 42 --commentaire "KO : ..."

--repere TEXTE[#n] : n-ième élément portant ce texte (1 par défaut).
--kiwi-execution : joint l'image (et le commentaire) à l'exécution Kiwi ;
  KIWI_URL, KIWI_USERNAME et KIWI_PASSWORD dans l'environnement.
"""
import argparse, base64, http.cookiejar, json, os, re, subprocess, sys, urllib.request
from io import BytesIO

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RED = (200, 0, 0)
FONT = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 34)
NODE = re.compile(r"<node [^>]*>")


def adb(*args: str) -> bytes:
    return subprocess.run(["adb", "exec-out", *args], check=True, capture_output=True).stdout


def bounds(xml: str, label: str) -> tuple[int, int, int, int]:
    text, _, n = label.partition("#")
    esc = text.replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;").replace(">", "&gt;")
    hits = [m.group(0) for m in NODE.finditer(xml)
            if re.search(r'(text|content-desc)="' + re.escape(esc) + r'("|&#10;)', m.group(0))]
    if len(hits) < int(n or 1):
        sys.exit(f"élément introuvable à l'écran : {label}")
    x0, y0, x1, y1 = map(int, re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', hits[int(n or 1) - 1]).groups())
    return x0, y0, x1, y1


def badge(d: ImageDraw.ImageDraw, n: int, box, w: int, h: int, placed: list) -> None:
    # Pastille dans un coin libre du cadre, comme dans les guides existants.
    s = 46
    for bx, by in ((box[0] - s + 6, box[1] - s + 6), (box[2] - 6, box[1] - s + 6),
                   (box[2] - 6, box[3] - 6), (box[0] - s + 6, box[3] - 6)):
        bx, by = max(0, min(bx, w - s)), max(0, min(by, h - s))
        if all(abs(bx - px) >= s or abs(by - py) >= s for px, py in placed):
            break
    placed.append((bx, by))
    d.rectangle((bx, by, bx + s, by + s), fill=RED)
    tw = d.textlength(str(n), font=FONT)
    d.text((bx + (s - tw) / 2, by + 4), str(n), fill="white", font=FONT)


def annotate(png: bytes, xml: str, marks: list[str], blurs: list[str]) -> Image.Image:
    im = Image.open(BytesIO(png)).convert("RGB")
    for b in blurs:
        box = bounds(xml, b)
        im.paste(im.crop(box).filter(ImageFilter.GaussianBlur(14)), box[:2])
    d, placed = ImageDraw.Draw(im), []
    for i, m in enumerate(marks, 1):
        box = bounds(xml, m)
        d.rectangle(box, outline=RED, width=5)
        badge(d, i, box, *im.size, placed)
    return im


def to_kiwi(execution: int, name: str, data: bytes, comment: str | None) -> None:
    url = os.environ["KIWI_URL"].rstrip("/") + "/json-rpc/"
    op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def rpc(method: str, *params):
        req = urllib.request.Request(url, json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": list(params)}).encode(),
                                     {"Content-Type": "application/json", "Referer": url})
        r = json.load(op.open(req, timeout=60))
        if "error" in r:
            sys.exit(f"Kiwi {method} : {r['error']['message']}")
        return r["result"]

    rpc("Auth.login", os.environ["KIWI_USERNAME"], os.environ["KIWI_PASSWORD"])
    rpc("TestExecution.add_attachment", execution, name, base64.b64encode(data).decode())
    if comment:
        rpc("TestExecution.add_comment", execution, comment)


def main() -> None:
    a = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    a.add_argument("sortie")
    a.add_argument("--repere", action="append", default=[])
    a.add_argument("--flou", action="append", default=[])
    a.add_argument("--kiwi-execution", type=int)
    a.add_argument("--commentaire")
    o = a.parse_args()
    subprocess.run(["adb", "shell", "uiautomator", "dump", "/sdcard/memo-ui.xml"], check=True, capture_output=True)
    xml = adb("cat", "/sdcard/memo-ui.xml").decode()
    im = annotate(adb("screencap", "-p"), xml, o.repere, o.flou)
    im.save(o.sortie, optimize=True)
    if o.kiwi_execution:
        to_kiwi(o.kiwi_execution, os.path.basename(o.sortie), open(o.sortie, "rb").read(), o.commentaire)
    print(o.sortie)


if __name__ == "__main__":
    main()

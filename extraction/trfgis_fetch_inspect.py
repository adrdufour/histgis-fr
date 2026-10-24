#!/usr/bin/env python3
"""
extraction/trfgis_fetch_inspect.py — récupération et inspection des dépôts TRF-GIS
(Victor Gay, Harvard Dataverse, CC BY 4.0).

Sans dépendance : urllib + stdlib. Parseur DBF minimal (en-tête seul).

Usage :
    python3 extraction/trfgis_fetch_inspect.py list cantons
    python3 extraction/trfgis_fetch_inspect.py fetch communes --match COG_COMMUNES_1870
    python3 extraction/trfgis_fetch_inspect.py fetch communes --match COG_COMMUNES --years 1870,1900,1940
    python3 extraction/trfgis_fetch_inspect.py inspect ./trfgis > rapport_entetes.txt

Le rapport produit par `inspect` est ce qu'il faut relire avant d'écrire
le chargeur : ne jamais se fier aux noms de colonnes de la data paper,
la limite des 10 caractères du format DBF a forcé des abréviations.
"""

import argparse
import csv
import io
import json
import os
import re
import signal
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

BASE = "https://dataverse.harvard.edu"

# Le WAF de Harvard Dataverse renvoie 403 sur le User-Agent par défaut
# d'urllib. Un UA de navigateur suffit ; aucun token n'est requis pour
# les dépôts TRF-GIS, qui sont publics (CC BY 4.0).
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36",
    "Accept": "*/*",
}


def _open(url, timeout=60, essais=4):
    """urlopen avec en-têtes et reprise. Dataverse renvoie fréquemment des
    502/503/504 passagers sur les gros dépôts : on réessaie avec une attente
    croissante plutôt que d'abandonner."""
    req = urllib.request.Request(url, headers=dict(HEADERS))
    token = os.environ.get("DATAVERSE_TOKEN")
    if token:
        req.add_header("X-Dataverse-key", token)
    for essai in range(essais):
        try:
            return urllib.request.urlopen(req, timeout=timeout)
        except urllib.error.HTTPError as e:
            if e.code not in (429, 500, 502, 503, 504) or essai == essais - 1:
                raise
            attente = 5 * (2 ** essai)
        except (urllib.error.URLError, TimeoutError) as e:
            if essai == essais - 1:
                raise
            attente = 5 * (2 ** essai)
        print(f"  serveur indisponible, nouvelle tentative dans {attente} s "
              f"({essai + 1}/{essais - 1})", file=sys.stderr)
        time.sleep(attente)

DOIS = {
    "cantons":         "doi:10.7910/DVN/U85RSZ",
    "circonscriptions": "doi:10.7910/DVN/L2LGDW",
    "communes":        "doi:10.7910/DVN/LZTZWE",
    "repro":           "doi:10.7910/DVN/6FCK3W",
}


# --------------------------------------------------------------------- API

def dataset_files(doi):
    """Liste les fichiers de la dernière version d'un dataset."""
    url = f"{BASE}/api/datasets/:persistentId/?{urllib.parse.urlencode({'persistentId': doi})}"
    with _open(url) as r:
        payload = json.load(r)
    out = []
    for f in payload["data"]["latestVersion"]["files"]:
        df = f["dataFile"]
        out.append({
            "id": df["id"],
            "name": df.get("filename", ""),
            "size": df.get("filesize", 0),
            "type": df.get("contentType", ""),
            "dir": f.get("directoryLabel", ""),
        })
    return out


def download(file_id, dest):
    """Télécharge un datafile. format=original évite la conversion Dataverse."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    # Sans paramètre : Dataverse rend la version tabulée (TSV avec en-tête)
    # des fichiers ingérés. Avec format=original on récupère le .dta Stata
    # binaire, illisible sans pandas.read_stata. Le repli sert aux fichiers
    # non ingérés (.txt, .zip), pour lesquels les deux URL sont équivalentes.
    urls = [
        f"{BASE}/api/access/datafile/{file_id}",
        f"{BASE}/api/access/datafile/{file_id}?format=original",
    ]
    last = None
    for url in urls:
        try:
            with _open(url, timeout=600) as r, open(dest, "wb") as fh:
                while chunk := r.read(1 << 20):
                    fh.write(chunk)
            return os.path.getsize(dest)
        except urllib.error.HTTPError as e:
            last = e
            continue
    raise last


# --------------------------------------------------------------- DBF header

DBF_TYPES = {
    "C": "texte", "N": "numérique", "F": "flottant", "D": "date",
    "L": "booléen", "M": "mémo",
}


def dbf_header(raw):
    """Parse l'en-tête d'un .dbf. Retourne (n_records, [(nom, type, longueur, déc)])."""
    n_records = int.from_bytes(raw[4:8], "little")
    header_len = int.from_bytes(raw[8:10], "little")
    fields, pos = [], 32
    while pos < header_len - 1 and raw[pos] != 0x0D:
        d = raw[pos:pos + 32]
        name = d[:11].split(b"\x00")[0].decode("latin-1").strip()
        fields.append((name, chr(d[11]), d[16], d[17]))
        pos += 32
    return n_records, fields


def dbf_first_record(raw, fields, header_len):
    """Extrait la première ligne, pour voir des valeurs réelles."""
    off = header_len + 1  # +1 : drapeau de suppression
    vals = []
    for name, ftype, length, _ in fields:
        vals.append(raw[off:off + length].decode("latin-1").strip())
        off += length
    return vals


def report_dbf(label, raw, out):
    n, fields = dbf_header(raw)
    header_len = int.from_bytes(raw[8:10], "little")
    try:
        sample = dbf_first_record(raw, fields, header_len)
    except Exception:
        sample = [""] * len(fields)
    print(f"\n### {label}", file=out)
    print(f"    {n} enregistrements, {len(fields)} colonnes", file=out)
    for (name, ftype, length, dec), val in zip(fields, sample):
        t = DBF_TYPES.get(ftype, ftype)
        v = (val[:38] + "…") if len(val) > 38 else val
        print(f"    {name:<12} {t:<10} len={length:<4} ex: {v}", file=out)


def report_csv(label, raw, out, delim=None):
    txt = raw.decode("utf-8-sig", errors="replace")
    if delim is None:
        try:
            delim = csv.Sniffer().sniff(txt[:4096], delimiters=",;\t|").delimiter
        except Exception:
            delim = "\t" if "\t" in txt[:4096] else ","
    rdr = csv.reader(io.StringIO(txt), delimiter=delim)
    rows = [row for _, row in zip(range(3), rdr)]
    n = txt.count("\n")
    shown = {"\t": "TAB", ",": ",", ";": ";"}.get(delim, repr(delim))
    print(f"\n### {label}", file=out)
    print(f"    ~{n} lignes, séparateur {shown}, "
          f"{len(rows[0]) if rows else 0} colonnes", file=out)
    if rows:
        for i, col in enumerate(rows[0]):
            ex1 = rows[1][i] if len(rows) > 1 and i < len(rows[1]) else ""
            ex2 = rows[2][i] if len(rows) > 2 and i < len(rows[2]) else ""
            print(f"    {col:<20} ex: {ex1[:28]:<30} {ex2[:28]}", file=out)


def report_codebook(label, raw, out, max_lines=400):
    """Un codebook Stata fait quelques Ko : on le rend intégralement."""
    txt = raw.decode("utf-8-sig", errors="replace")
    lines = txt.splitlines()
    print(f"\n### {label}  [codebook, {len(lines)} lignes]", file=out)
    for line in lines[:max_lines]:
        print(f"    {line}", file=out)
    if len(lines) > max_lines:
        print(f"    … {len(lines) - max_lines} lignes tronquées", file=out)


def walk_and_report(root, out):
    """Inspecte récursivement .dbf, .csv et le contenu des .zip."""
    if not os.path.isdir(root):
        print(f"\nLe chemin {root!r} n'existe pas.", file=out)
        return

    READ = (".dbf", ".csv", ".zip", ".tab", ".txt")

    # Inventaire d'abord : un rapport vide doit dire pourquoi il est vide.
    inventory, handled = {}, 0
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            ext = os.path.splitext(fn)[1].lower() or "(sans extension)"
            inventory[ext] = inventory.get(ext, 0) + 1
            if ext in READ:
                handled += 1

    print("\n## Inventaire", file=out)
    if not inventory:
        print(f"    Aucun fichier sous {root!r} — le téléchargement n'a rien écrit,",
              file=out)
        print("    ou les fichiers sont ailleurs. Vérifier avec : find "
              f"{root} -type f", file=out)
        return
    for ext, n in sorted(inventory.items(), key=lambda kv: -kv[1]):
        mark = "  <- lu" if ext in READ else ""
        print(f"    {ext:<18} {n:>5}{mark}", file=out)
    if handled == 0:
        print("\n    Aucune extension exploitable.", file=out)
        print("    Relancer `list` pour voir les noms réels du dépôt.", file=out)
        return
    print(f"\n    {handled} fichiers à inspecter.", file=out)

    # Codebooks en premier : ce sont eux qui nomment les variables.
    todo = []
    for dirpath, _, filenames in os.walk(root):
        for fn in sorted(filenames):
            if os.path.splitext(fn)[1].lower() in READ:
                todo.append(os.path.join(dirpath, fn))
    todo.sort(key=lambda p: (0 if "codebook" in os.path.basename(p).lower() else 1, p))

    for path in todo:
        rel = os.path.relpath(path, root)
        low = os.path.basename(path).lower()
        try:
            if low.endswith(".zip"):
                with zipfile.ZipFile(path) as z:
                    for info in z.infolist():
                        il = info.filename.lower()
                        if il.endswith(".dbf"):
                            report_dbf(f"{rel} :: {info.filename}", z.read(info), out)
                        elif il.endswith((".csv", ".tab", ".txt")):
                            report_csv(f"{rel} :: {info.filename}", z.read(info), out)
            elif low.endswith(".dbf"):
                with open(path, "rb") as fh:
                    report_dbf(rel, fh.read(), out)
            elif "codebook" in low:
                with open(path, "rb") as fh:
                    report_codebook(rel, fh.read(), out)
            elif low.endswith(".tab"):
                with open(path, "rb") as fh:
                    report_csv(rel, fh.read(), out, delim="\t")
            else:  # .csv, .txt
                with open(path, "rb") as fh:
                    report_csv(rel, fh.read(), out)
        except Exception as e:
            print(f"\n### {rel}\n    ERREUR : {e}", file=out)


# -------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("list", help="lister les fichiers d'un dépôt")
    p.add_argument("dataset", choices=DOIS)

    p = sub.add_parser("fetch", help="télécharger des fichiers d'un dépôt")
    p.add_argument("dataset", choices=DOIS)
    p.add_argument("--match", default="", help="sous-chaîne ou regex du nom de fichier")
    p.add_argument("--years", default="", help="liste d'années séparées par des virgules")
    p.add_argument("--dest", default="./trfgis")
    p.add_argument("--dry-run", action="store_true")

    p = sub.add_parser("inspect", help="rapport d'en-têtes sur un répertoire local")
    p.add_argument("root")

    a = ap.parse_args()

    # `... | head` ferme le tuyau avant la fin : comportement Unix normal,
    # que Python signale par une exception. On rétablit la sémantique shell.
    try:
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except (AttributeError, ValueError):
        pass                      # Windows, ou hors thread principal

    try:
        run(a)
    except urllib.error.HTTPError as e:
        if e.code == 403:
            sys.exit("403 : requête refusée par Dataverse. Vérifier que le "
                     "User-Agent est bien envoyé (HEADERS en haut du fichier). "
                     "Si le 403 persiste avec curl, le dépôt est restreint : "
                     "poser DATAVERSE_TOKEN dans l'environnement.")
        sys.exit(f"HTTP {e.code} sur {e.url}")
    except urllib.error.URLError as e:
        sys.exit(f"Réseau injoignable : {e.reason}")


def run(a):
    if a.cmd == "list":
        files = dataset_files(DOIS[a.dataset])
        total = sum(f["size"] for f in files)
        for f in files:
            loc = f"{f['dir']}/" if f["dir"] else ""
            print(f"{f['id']:>9}  {f['size']/1e6:>8.1f} Mo  {loc}{f['name']}")
        print(f"\n{len(files)} fichiers, {total/1e9:.2f} Go au total", file=sys.stderr)

    elif a.cmd == "fetch":
        files = dataset_files(DOIS[a.dataset])
        if a.match:
            files = [f for f in files if re.search(a.match, f["name"], re.I)]
        if a.years:
            years = {y.strip() for y in a.years.split(",")}
            files = [f for f in files
                     if any(y in f["name"] for y in years)]
        if not files:
            sys.exit("Aucun fichier ne correspond au filtre.")
        total = sum(f["size"] for f in files)
        print(f"{len(files)} fichiers, {total/1e6:.1f} Mo", file=sys.stderr)
        for f in files:
            dest = os.path.join(a.dest, a.dataset, f["dir"], f["name"])
            if a.dry_run:
                print(f"[dry-run] {dest}")
                continue
            if os.path.exists(dest) and os.path.getsize(dest) == f["size"]:
                print(f"= {dest}", file=sys.stderr)
                continue
            n = download(f["id"], dest)
            print(f"+ {dest} ({n/1e6:.1f} Mo)", file=sys.stderr)

    elif a.cmd == "inspect":
        out = sys.stdout
        print("RAPPORT D'EN-TÊTES TRF-GIS", file=out)
        print("=" * 60, file=out)
        walk_and_report(a.root, out)


if __name__ == "__main__":
    main()

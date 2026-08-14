#!/usr/bin/env python3
"""
resoudre_par_nom.py — complète la colonne `cible` de geom_correspondance.csv
en cherchant `nom_cible` dans le .DBF de GEOFLA.

Les communes absorbantes sont nommées, pas codées : leur code se lit dans la
trame elle-même, ce qui évite toute erreur de transcription et confirme au
passage que la commune y figure bien.

Usage :
    python3 resoudre_par_nom.py geom_correspondance.csv --dbf .../COMMUNE.DBF
"""

import argparse
import csv
import sys
import unicodedata


def sans_accents(s):
    """GEOFLA écrit les noms en capitales non accentuées."""
    d = unicodedata.normalize("NFD", s)
    return "".join(c for c in d if unicodedata.category(c) != "Mn").upper()


def lire_dbf(path, colonnes):
    raw = open(path, "rb").read()
    n = int.from_bytes(raw[4:8], "little")
    hl = int.from_bytes(raw[8:10], "little")
    rl = int.from_bytes(raw[10:12], "little")
    champs, p = [], 32
    while p < hl - 1 and raw[p] != 0x0D:
        d = raw[p:p + 32]
        champs.append((d[:11].split(b"\x00")[0].decode("latin-1").strip(),
                       d[16]))
        p += 32
    positions, off = {}, 1
    for nom, lg in champs:
        if nom in colonnes:
            positions[nom] = (off, lg)
        off += lg
    manquantes = set(colonnes) - set(positions)
    if manquantes:
        sys.exit(f"Colonnes absentes : {manquantes}")
    for i in range(n):
        base = hl + i * rl
        yield {c: raw[base + o:base + o + lg].decode("latin-1").strip()
               for c, (o, lg) in positions.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv_in")
    ap.add_argument("--dbf", required=True)
    a = ap.parse_args()

    index = {}
    for r in lire_dbf(a.dbf, {"INSEE_COM", "NOM_COMM"}):
        index.setdefault(sans_accents(r["NOM_COMM"]), []).append(r["INSEE_COM"])

    lignes = list(csv.DictReader(open(a.csv_in, encoding="utf-8")))
    if not lignes:
        sys.exit(f"{a.csv_in} est vide.")
    if "nom_cible" not in lignes[0]:
        sys.exit(f"{a.csv_in} ne contient pas de colonne 'nom_cible' — "
                 f"colonnes trouvées : {', '.join(lignes[0])}.\n"
                 "Il s'agit sans doute d'une version antérieure du fichier.")
    for l in lignes:
        nom = l.get("nom_cible", "").strip()
        if not nom or l["cible"].strip():
            continue
        codes = index.get(sans_accents(nom), [])
        if len(codes) == 1:
            l["cible"] = codes[0]
            print(f"  {l['insee']} -> {codes[0]} ({nom})")
        elif codes:
            print(f"  {l['insee']} : {nom} correspond à {len(codes)} communes "
                  f"({', '.join(codes)}) — à trancher", file=sys.stderr)
        else:
            print(f"  {l['insee']} : {nom} absente de GEOFLA", file=sys.stderr)

    with open(a.csv_in, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)
    reste = sum(1 for l in lignes if not l["cible"].strip())
    print(f"\n{reste} ligne(s) sans cible.", file=sys.stderr)


if __name__ == "__main__":
    main()

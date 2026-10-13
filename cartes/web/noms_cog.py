#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
noms_cog.py — les noms de communes en casse et accents, pour l'export Commons.

    python3 cartes/web/noms_cog.py      # écrit cartes/web/donnees/noms_cog.json

Pourquoi : `communes.json` porte le nom de GEOFLA (`nom_comm`), en capitales
sans accents — « MIREBEAU-SUR-BEZE ». La page s'en accommode ; un lien de
Wikipédia, non : un titre y est sensible à la casse et aux accents au-delà de
la première lettre, et [[Mirebeau-Sur-Beze]] est un lien rouge.

Source : `sources/cog/2012/france2012.txt`, qui tient toutes les communes ayant
existé depuis 1943, disparues comprises. On rend, par code INSEE, le nom
typographié (NCCENR) précédé de son article (ARTMIN) : « L'Abergement-
Clémenciat ». La page ne l'emploie que si le nom en capitales concorde ; sinon
elle garde le sien. Le fichier de l'Insee est en Windows-1252, pas en Latin-1 : « Chambœuf » y
porte un œ que Latin-1 n'a pas. Bibliothèque standard seulement, comme `servir.py`.
"""
import csv
import json
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
SOURCE = ICI.parents[1] / "sources" / "cog" / "2012" / "france2012.txt"
CIBLE = ICI / "donnees" / "noms_cog.json"
# Une commune active d'abord, puis associée, puis périmée, puis fraction.
RANG = {"1": 0, "5": 1, "2": 2, "3": 3, "4": 4, "6": 5}


def main():
    if not SOURCE.exists():
        sys.exit(f"introuvable : {SOURCE} (voir sources/cog/fetch_cog.sh)")
    noms = {}
    with open(SOURCE, encoding="cp1252", newline="") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            code = r["DEP"] + r["COM"]
            if len(r["DEP"]) == 3:          # outre-mer : 971 + 05
                code = r["DEP"] + r["COM"][-2:]
            art = (r["ARTMIN"] or "").strip("()")
            nom = r["NCCENR"].strip()
            if art:
                nom = art + nom if art.endswith("'") else f"{art} {nom}"
            rang = RANG.get(r["ACTUAL"], 9)
            if code not in noms or rang < noms[code][0]:
                noms[code] = (rang, nom)
    CIBLE.write_text(json.dumps({k: v[1] for k, v in sorted(noms.items())},
                                ensure_ascii=False, separators=(",", ":")),
                     encoding="utf-8")
    print(f"{len(noms)} noms -> {CIBLE}")


if __name__ == "__main__":
    main()

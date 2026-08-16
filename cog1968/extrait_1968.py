#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extrait_1968.py — la composition cantonale de 1968, fascicule par fascicule

    python3 cog1968/extrait_1968.py --dep 02
    python3 cog1968/extrait_1968.py --dep 02 --pages 18-30 --langue eng
    python3 cog1968/extrait_1968.py --tous            # les 83 fascicules

Produit `cog1968/communes_1968.csv`.

Ce que ce script NE réécrit PAS
-------------------------------
La chaîne d'OCR existe déjà : `cog1954/extrait_1954.py` rend une page en PNG
gris à 300 dpi (`pdftoppm`) puis la passe à `tesseract -l fra --psm 6`, le tout
en multiprocessing. Elle a été éprouvée sur 958 pages. **Elle est importée
telle quelle** — `page_texte`, `nettoie_nom`, `nettoie_nombre`, `SOSIES`.

Ce qui change est la **grammaire de la ligne**, et elle seule.

    1954   [arr] [canton] Nom.  [population]
    1968   [pop 1962] [pop 1962 sans doubles] [arr] [canton] [INSEE] Nom.  [pop 1968]

Lancer le parseur de 1954 sur un fascicule de 1968 rend **2 lignes sur 600** :
la chaîne tourne, la grammaire ne colle pas. C'est mesuré, pas supposé.

Ce que 1968 apporte, et que 1954 n'avait pas
--------------------------------------------
**Le code INSEE de la commune est imprimé.** Vérifié sur neuf communes de
l'Aisne, neuf concordances sur neuf avec `noms_geofla`. En 1954 la jointure
passait par le nom et laissait 7 576 orphelins ; ici il n'y a pas de jointure
par nom du tout. Le nom devient une pièce de contrôle au lieu d'être la clé.

Trois garde-fous en découlent :

* **le code croît** dans la page — l'INSEE est attribué dans l'ordre
  alphabétique. Un chiffre mal lu se détecte sur ses voisins, sans dictionnaire ;
* **le nom confirme le code**, et non l'inverse. Deux lectures indépendantes du
  même fait, dont l'une n'est plus nécessaire à l'autre ;
* **l'en-tête de page** porte « AISNE (02) » — le département ET son code, sur
  chaque feuille de tableau. Aucun héritage d'en-tête à gérer, aucune suite
  croissante à surveiller : les quatre pièges du volume national de 1954
  disparaissent.

Reste le tableau II — population et nombre de communes par canton — qui donne
une recette de contrôle fournie par la source. Il n'est pas encore extrait.
"""

import argparse
import collections
import csv
import multiprocessing
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
# On importe la chaîne d'OCR de 1954 plutôt que de la recopier. Si elle est
# améliorée là-bas — prétraitement, dpi, langue — 1968 en profite sans rien
# changer ici.
from extrait_1954 import page_texte, nettoie_nom, SOSIES   # noqa: E402

FASCICULES = RACINE / "sources" / "rp1968"
INDEX = RACINE / "cog1968" / "fascicules_1968.csv"
SORTIE = RACINE / "cog1968" / "communes_1968.csv"

# ---------------------------------------------------------------------------
# La ligne de commune du tableau III.
#
#   219  219   4  35  562  Nouvron-Vingré.   221  221  124  97  …
#   ─┬─  ─┬─   ┬  ─┬  ─┬─  ──────┬────────   ─┬─
#    │    │    │   │   │         │            └── population 1968
#    │    │    │   │   │         └── nom, terminé par un point ou une virgule
#    │    │    │   │   └── code INSEE de la commune, 3 chiffres
#    │    │    │   └── canton, 2 chiffres
#    │    │    └── arrondissement, 1 chiffre
#    │    └── population 1962 sans doubles comptes
#    └── population 1962 totale
#
# Les deux premières colonnes sont acceptées mais non exigées : le bord gauche
# de la page est le plus abîmé par la reliure, et une ligne dont la population
# de 1962 est illisible reste parfaitement utilisable — c'est le canton qu'on
# vient chercher, pas la démographie.
LIGNE = re.compile(
    r"(?:(\d[\d.\s]{0,9}?)\s+(\d[\d.\s]{0,9}?)\s+)?"     # populations 1962
    r"([\dOSlI])\s+"                                      # arrondissement
    r"([\dOSlI$]{2})\s+"                                  # canton
    r"(\d{3})\s+"                                         # code INSEE
    r"([A-ZÉÈÀÇŒ][A-Za-zÉÈÊËÀÂÎÏÔÛÙÇŒéèêëàâîïôûùç'’\-\. ]{2,44}?)"
    r"\s*[.,]\s+"                                         # le point final
    r"(\d[\d.]*)")                                        # population 1968

# « $ » pour « 3 » : confusion mesurée sur la première page OCRisée, où sept
# divergences sur huit portaient sur un 3 initial lu 8, 2 ou 1. On ne corrige
# ici que la substitution non ambiguë ; les autres se règlent par la monotonie
# du code INSEE, pas par une table de sosies qui devinerait.
SOSIES_1968 = str.maketrans({"O": "0", "S": "5", "l": "1", "I": "1", "$": "3"})


def index():
    """{code département: chemin du fascicule} — écrit par index_fascicules.py."""
    if not INDEX.exists():
        raise SystemExit("Lancer d'abord : python3 cog1968/index_fascicules.py")
    d = {}
    for l in csv.DictReader(INDEX.open(encoding="utf-8")):
        if l["dep"]:
            d[l["dep"]] = FASCICULES / l["fichier"]
    return d


def traite(args):
    """Une page -> les lignes de commune qu'elle porte."""
    pdf, page, langue = args
    out = []
    for brut in page_texte(pdf, page, langue=langue).splitlines():
        m = LIGNE.search(brut.strip())
        if not m:
            continue
        arr, canton, insee = (m.group(3).translate(SOSIES_1968),
                              m.group(4).translate(SOSIES_1968),
                              m.group(5))
        out.append(dict(page=page, arr=arr, canton=canton, insee3=insee,
                        nom=nettoie_nom(m.group(6)),
                        pop1968=m.group(7).replace(".", "")))
    return page, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dep", help="code département, ex. 02")
    ap.add_argument("--tous", action="store_true", help="les 83 fascicules")
    ap.add_argument("--pages", help="ex. 18-30 ; par défaut, tout le fascicule")
    ap.add_argument("--langue", default="fra")
    ap.add_argument("--jobs", type=int,
                    default=max(1, (multiprocessing.cpu_count() or 2) - 1))
    a = ap.parse_args()

    idx = index()
    if a.tous:
        cibles = sorted(idx.items())
    elif a.dep:
        if a.dep not in idx:
            raise SystemExit(f"Département {a.dep} absent de l'index.")
        cibles = [(a.dep, idx[a.dep])]
    else:
        raise SystemExit("Préciser --dep NN ou --tous.")

    lignes = []
    for dep, pdf in cibles:
        import subprocess
        n = int(subprocess.run(["pdfinfo", str(pdf)], capture_output=True,
                               text=True).stdout.split("Pages:")[1].split()[0])
        if a.pages:
            d, _, f = a.pages.partition("-")
            pages = range(int(d), int(f or d) + 1)
        else:
            pages = range(1, n + 1)
        print(f"{dep} : {pdf.name[-18:]}, {n} pages, "
              f"{len(list(pages))} traitées, langue « {a.langue} »")
        with multiprocessing.Pool(a.jobs) as pool:
            for page, out in pool.imap_unordered(
                    traite, [(pdf, p, a.langue) for p in pages]):
                for o in out:
                    o["dep"] = dep
                    o["insee"] = dep + o["insee3"]
                lignes += out
        print(f"   {len([l for l in lignes if l['dep'] == dep])} communes lues")

    if not lignes:
        raise SystemExit("Aucune ligne reconnue.")
    lignes.sort(key=lambda x: (x["dep"], x["insee"]))
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "insee", "insee3", "arr",
                                          "canton", "nom", "pop1968", "page"])
        w.writeheader()
        w.writerows(lignes)

    # Contrôle de monotonie : le code INSEE suit l'ordre alphabétique. Une
    # rupture signale un chiffre mal lu, sans avoir besoin d'un dictionnaire.
    ruptures = collections.defaultdict(int)
    for dep in {l["dep"] for l in lignes}:
        ordonne = [l for l in lignes if l["dep"] == dep]
        prec = ""
        for l in sorted(ordonne, key=lambda x: x["page"]):
            if prec and l["insee3"] < prec:
                ruptures[dep] += 1
            prec = l["insee3"]
    print(f"\n{len(lignes)} communes, {len({l['dep'] for l in lignes})} départements")
    print(f"{len({(l['dep'], l['canton']) for l in lignes})} cantons distincts")
    if ruptures:
        print("\nruptures de l'ordre alphabétique (codes à revoir) :")
        for d, n in sorted(ruptures.items()):
            print(f"   {d} : {n}")
    print(f"\n{SORTIE}")


if __name__ == "__main__":
    main()

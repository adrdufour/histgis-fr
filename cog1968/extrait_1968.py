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
import os
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
# Le nom, élargi le 20 août 2026 — trois mécanismes MESURÉS, pas supposés
# (`lignes_rejetees.py`, Bouches-du-Rhône et Territoire de Belfort) :
#
#   1. **L'article est rejeté en fin de nom, entre parenthèses** : « Barben
#      (La). », « Baux-de-Provence (Les). ». La classe n'acceptait pas `(`.
#      6,3 % des communes de 1968, et cela explique la géographie du rappel —
#      Moselle 88,7 %, Vendée 62,5 %, corrélation -0,50.
#   2. **Les appels de note**, « Andelnans (1). », parfois en accolades quand
#      l'OCR se trompe : « Bue {1}. ». À Belfort, 24 des 28 rejets.
#   3. **Les confusions de l'OCR** : « lstres » pour Istres — un `I` initial lu
#      `l` minuscule, quand le nom devait commencer par une majuscule — et
#      « Châäteauneuf », où un `ä` s'insère dans une classe qui l'ignorait.
#
# Élargir le nom fait entrer les lignes de TOTAL, qui portent la même
# signature — « 1°° Canton. », « TOTAL » — et ne sont pas des communes. D'où
# `EXCLUS`, appliqué avant : on élargit d'un côté, on referme de l'autre.
LIGNE = re.compile(
    r"(?:(\d[\d.\s]{0,9}?)\s+(\d[\d.\s]{0,9}?)\s+)?"     # populations 1962
    r"([\dOSlI])\s+"                                      # arrondissement
    r"([\dOSlI$]{2})\s+"                                  # canton
    r"(\d{3})\s+"                                         # code INSEE
    r"([A-Za-zÉÈÊËÀÂÄÎÏÔÖÛÜÙÇŒ]"                          # initiale, casse libre
    r"[A-Za-z0-9ÉÈÊËÀÂÄÎÏÔÖÛÜÙÇŒéèêëàâäîïôöûüùçœ'’\-\.\s(){}]{2,54}?)"
    r"\s*[.,]\s+"                                         # le point final
    r"(\d[\d.]*)")                                        # population 1968

# Les lignes de sous-total d'une grande ville : Marseille est découpée en
# « 1er Canton », « 2e Canton »… sous le code 055, et le fascicule clôt chaque
# groupe par un « TOTAL ». Ce ne sont pas des communes. Elles étaient rejetées
# par accident tant que le nom devait être une suite de lettres ; elles le sont
# désormais par décision.
EXCLUS = re.compile(r"\b(?:canton|total|ensemble)\b", re.I)

# « $ » pour « 3 » : confusion mesurée sur la première page OCRisée, où sept
# divergences sur huit portaient sur un 3 initial lu 8, 2 ou 1. On ne corrige
# ici que la substitution non ambiguë ; les autres se règlent par la monotonie
# du code INSEE, pas par une table de sosies qui devinerait.
SOSIES_1968 = str.maketrans({"O": "0", "S": "5", "l": "1", "I": "1", "$": "3"})


def bornes_cantonales():
    """{dep: plus haut code de canton connu en 1940} — une borne, pas un filtre.

    Un département de 37 cantons ne peut pas en porter un numéroté 94. Les
    codes lus au-delà de la borne sont donc presque sûrement des chiffres mal
    reconnus — mesuré sur l'Aisne : huit codes impossibles (50, 53, 54, 55, 60,
    82, 85, 94), vus une ou deux fois chacun, qui gonflaient le compte de 36 à
    44 cantons.

    **On signale, on ne supprime pas.** Un canton créé entre 1940 et 1968
    porterait justement un numéro au-delà de la borne : filtrer sur 1940
    reviendrait à faire de l'étalon un paramètre, et à rendre impossible la
    découverte même qu'on cherche. La colonne `hors_borne` marque la ligne, le
    tableau II tranchera.
    """
    hautes = collections.defaultdict(int)
    f = RACINE / "build" / "membership_canton.csv"
    if not f.exists():
        return hautes
    for l in csv.DictReader(f.open(encoding="utf-8")):
        u = l.get("unit_id") or ""
        if len(u) == 4 and u[2:].isdigit():
            hautes[u[:2]] = max(hautes[u[:2]], int(u[2:]))
    return hautes


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
        # Les sous-totaux d'une grande ville portent la même signature qu'une
        # commune depuis que le nom est élargi. On les écarte AVANT la grammaire
        # plutôt que d'espérer qu'elle les refuse.
        if EXCLUS.search(brut):
            continue
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
    # Une passe complète, c'est 83 fascicules et ~2 500 pages : des heures.
    # Accumuler en mémoire et n'écrire qu'à la fin, comme le faisait la
    # première version, fait perdre la nuit entière sur un plantage au 60e
    # département. On écrit donc après CHAQUE fascicule, et on sait reprendre.
    ap.add_argument("--reprendre", action="store_true",
                    help="sauter les départements déjà présents dans le CSV")
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

    CHAMPS = ["dep", "insee", "insee3", "arr", "canton", "nom", "pop1968",
              "hors_borne", "page"]
    deja = set()
    if a.reprendre and SORTIE.exists():
        deja = {l["dep"] for l in csv.DictReader(SORTIE.open(encoding="utf-8"))}
        cibles = [(d, p) for d, p in cibles if d not in deja]
        print(f"reprise : {len(deja)} départements déjà faits, "
              f"{len(cibles)} restants\n")
    neuf = not SORTIE.exists() or (not a.reprendre)
    sortie = SORTIE.open("w" if neuf else "a", newline="", encoding="utf-8")
    ecrivain = csv.DictWriter(sortie, fieldnames=CHAMPS)
    if neuf:
        ecrivain.writeheader()
        sortie.flush()

    bornes = bornes_cantonales()
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
        # Écriture immédiate, fichier vidé sur le disque : ce qui est lu est
        # acquis, même si la machine s'arrête à la page suivante.
        du_dep = [l for l in lignes if l["dep"] == dep]
        for l in du_dep:
            b = bornes.get(dep, 99)
            l["hors_borne"] = ("oui" if l["canton"].isdigit()
                               and int(l["canton"]) > b else "")
        ecrivain.writerows(sorted(du_dep, key=lambda x: x["insee"]))
        sortie.flush()
        os.fsync(sortie.fileno())
        print(f"   {len(du_dep)} communes lues, écrites")

    if not lignes:
        raise SystemExit("Aucune ligne reconnue.")
    lignes.sort(key=lambda x: (x["dep"], x["insee"]))
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "insee", "insee3", "arr",
                                          "canton", "nom", "pop1968",
                                          "hors_borne", "page"])
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
    hb = [l for l in lignes if l["hors_borne"]]
    tous = {(l["dep"], l["canton"]) for l in lignes}
    sains = {(l["dep"], l["canton"]) for l in lignes if not l["hors_borne"]}
    print(f"\n{len(lignes)} communes, {len({l['dep'] for l in lignes})} départements")
    print(f"{len(tous)} cantons distincts, dont {len(tous) - len(sains)} "
          f"au-delà de la borne de 1940")
    if hb:
        print(f"   {len(hb)} lignes concernées — colonne hors_borne, "
              f"à trancher par le tableau II")
    if ruptures:
        print("\nruptures de l'ordre alphabétique (codes à revoir) :")
        for d, n in sorted(ruptures.items()):
            print(f"   {d} : {n}")
    print(f"\n{SORTIE}")


if __name__ == "__main__":
    main()

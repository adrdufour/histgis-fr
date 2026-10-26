#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
essai_troisieme_1954.py — la redondance paie-t-elle aussi pour 1954 ?

    python3 archives/essais/essai_troisieme_1954.py --dep 09 --dep 34 --dep 90

Ce que 1968 a montré, et ce qui reste à vérifier ici
-----------------------------------------------------
Le 22 août 2026, réunir TROIS lectures du même fascicule a fait passer le
recensement de 1968 de 77,6 % à 95,6 % de rappel — bien plus que n'importe quel
réglage de la chaîne, et la meilleure des trois candidates était la plus
mauvaise prise seule. **En redondance, la décorrélation prime la performance.**

Reste à savoir si cela vaut pour 1954, qui n'est pas le même problème.

LA DIFFÉRENCE QUI CHANGE TOUT : PAS DE CODE INSEE
--------------------------------------------------
Le tableau de 1968 imprime le code INSEE de chaque commune. Il donne donc DEUX
informations indépendantes — le code sert de clé, le nom de contrôle — et c'est
ce qui a permis le vote majoritaire, puis les 121 codes retrouvés par le nom.

**Le volume de 1954 ne porte que le nom.** Une seule information porte tout :
la clé de fusion est justement ce que l'OCR abîme. Deux lectures d'une même
commune peuvent produire « Châteauneuf » et « Chäteauneuf » sans qu'aucune
troisième colonne ne dise qu'il s'agit de la même.

L'appariement entre passes se fait donc par nom normalisé puis comparaison
floue, à l'intérieur d'un département. C'est moins sûr qu'un code, et le banc
doit le mesurer avant qu'on engage cinq heures de calcul.

CE QUI EST DÉJÀ SUR DISQUE
--------------------------
`cog1954/ocr_brut/pNNNN.txt` — les 958 pages, lues en psm 6 à 300 dpi. **La
première des trois lectures existe**, et le témoin ne coûte donc rien.

CE QUE LE BANC COMPTE
---------------------
    justes   noms distincts appariés à une commune du département
    bruit    lignes reconnues dont le nom ne correspond à rien

Le second compte autant que le premier ici : 1954 souffre des DEUX maux. Le
Paris de l'extraction actuelle rend 79 lignes pour 20 arrondissements (395 %),
quand l'Ariège n'en rend que 62 % de son effectif.

La trame 2011 n'est pas l'attendu de 1954 — des communes ont fusionné depuis —
donc `justes` sous-estime en valeur absolue. C'est sans importance : le banc
compare des variantes entre elles sur le MÊME dénominateur.
"""

import argparse
import collections
import csv
import re
import sys
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RACINE / "cog1954"))
from extrait_1954 import (LIGNE, RENVOI, TOTAUX, page_texte,   # noqa: E402
                          nettoie_nom)

sys.path.insert(0, str(RACINE / "circo"))
from extrait_paris import cle                                   # noqa: E402

PDF = RACINE / "sources" / "rp1954" / \
      "master_RP_1954_POP_DEP_-ARROND_CANT_COMMU.pdf"
BRUT = RACINE / "cog1954" / "ocr_brut"
EXTRAIT = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
N1954 = RACINE / "cog1954" / "noms_1954.csv"   # cf. sql/65_noms_1954.sql

# La lecture en service est DÉJÀ sur disque : `ocr_brut` a été produit en
# psm 6 / 300 dpi. Le témoin ne coûte donc aucun calcul.
CANDIDATES = [
    ("psm 4 / 300", 300, "4"),
    ("psm 4 / 600", 600, "4"),
]


def noms_de(texte):
    """Les noms de commune que la grammaire de 1954 tire d'une page."""
    out = set()
    for brut in texte.splitlines():
        s = brut.strip()
        if not s or RENVOI.search(s) or TOTAUX.search(s):
            continue
        m = LIGNE.search(s)
        if m:
            n = cle(nettoie_nom(m.group(3)))
            if len(n) >= 4:
                out.add(n)
    return out


def pages_du_dep(dep):
    n = collections.Counter()
    for r in csv.DictReader(EXTRAIT.open(encoding="utf-8")):
        if r["dep"] == dep and r.get("page", "").isdigit():
            n[int(r["page"])] += 1
    return sorted(n) if n else []


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", action="append", required=True)
    args = ap.parse_args()

    if not PDF.exists():
        sys.exit(f"{PDF.name} absent de sources/rp1954/.")

    # LE RÉFÉRENTIEL, EN DEUX MORCEAUX.
    #
    # La trame 2011 seule ne suffit pas : une commune vivante en 1954 puis
    # absorbée depuis n'y figure pas, et comptait donc comme du BRUIT alors
    # qu'elle est ce que le dépouillement cherche. Le témoin — la lecture en
    # service — affichait ainsi 82 bruits sur l'Ariège pour 123 justes, ce qui
    # n'est pas crédible d'une chaîne éprouvée.
    #
    # `sql/65_noms_1954.sql` produit les noms que la base est seule à
    # connaître : ceux des communes disparues, tirés d'`insee_mvt.libelle_av`.
    ref = collections.defaultdict(set)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        ref[r["insee"].strip()[:2]].add(cle(r["nom"]))
    n_2011 = sum(len(v) for v in ref.values())

    if N1954.exists():
        for r in csv.DictReader(N1954.open(encoding="utf-8")):
            if r["nom"].strip():
                ref[r["code"][:2]].add(cle(r["nom"]))
        print(f"référentiel : {n_2011} noms de 2011 "
              f"+ {sum(len(v) for v in ref.values()) - n_2011} noms de communes "
              f"disparues depuis 1954\n")
    else:
        print("ATTENTION — cog1954/noms_1954.csv absent : le référentiel se")
        print("limite à la trame 2011, et le `bruit` comptera à tort les")
        print("communes disparues entre 1954 et 2011.")
        print("Produire le fichier : psql -d histgis -f sql/65_noms_1954.sql\n")

    cumul = collections.defaultdict(collections.Counter)

    for dep in args.dep:
        pages = pages_du_dep(dep)
        if not pages:
            print(f"département {dep} : aucune page connue — sauté.")
            continue

        lectures = {}

        # LE TÉMOIN, lu depuis `ocr_brut` — aucun calcul.
        vus = set()
        manquantes = 0
        for p in pages:
            f = BRUT / f"p{p:04d}.txt"
            if f.exists():
                vus |= noms_de(f.read_text(encoding="utf-8", errors="replace"))
            else:
                manquantes += 1
        lectures["psm 6 / 300 (en service)"] = vus
        if manquantes:
            print(f"  ({manquantes} pages absentes de ocr_brut pour {dep})")

        for nom, dpi, psm in CANDIDATES:
            t0 = time.time()
            v = set()
            for p in pages:
                v |= noms_de(page_texte(PDF, p, dpi=dpi, psm=psm))
            lectures[nom] = v
            print(f"  {dep} — {nom} : {len(pages)} pages en {time.time()-t0:.0f}s")

        temoin = lectures["psm 6 / 300 (en service)"]
        j0 = len(temoin & ref[dep])
        b0 = len(temoin - ref[dep])

        print(f"\ndépartement {dep} — {len(pages)} pages — "
              f"{len(ref[dep])} communes à la trame 2011")
        print(f"{'lecture':<26}{'justes':>8}{'bruit':>7}{'union':>8}{'APPORT':>8}")
        print("-" * 57)
        print(f"{'psm 6 / 300 (témoin)':<26}{j0:>8}{b0:>7}{'':>8}{'':>8}")

        union = set(temoin)
        for nom, _, _ in CANDIDATES:
            v = lectures[nom]
            u = temoin | v
            ju, bu = len(u & ref[dep]), len(u - ref[dep])
            print(f"{nom:<26}{len(v & ref[dep]):>8}{len(v - ref[dep]):>7}"
                  f"{ju:>8}{ju - j0:>+8}")
            cumul[nom]["apport"] += ju - j0
            cumul[nom]["bruit"] += bu - b0
            union |= v

        jt, bt = len(union & ref[dep]), len(union - ref[dep])
        print(f"{'UNION DES TROIS':<26}{'':>8}{'':>7}{jt:>8}{jt - j0:>+8}"
              f"   bruit {bt - b0:+}")
        cumul["UNION"]["apport"] += jt - j0
        cumul["UNION"]["bruit"] += bt - b0

    if len(args.dep) > 1:
        print(f"\nCUMUL sur {len(args.dep)} départements")
        print(f"{'':<26}{'apport':>10}{'bruit +':>10}")
        print("-" * 46)
        for nom in [c[0] for c in CANDIDATES] + ["UNION"]:
            k = cumul[nom]
            print(f"{nom:<26}{k['apport']:>+10}{k['bruit']:>+10}")

    print("\nLire `APPORT` ET `bruit`. 1954 souffre des DEUX maux —")
    print("l'Ariège rend 62 % de son effectif, Paris en rend 395 %.")
    print("\nEt se rappeler que la clé de fusion sera le NOM, pas un code :")
    print("ce banc mesure ce que les lectures apportent, pas encore la")
    print("difficulté de les apparier entre elles.")


if __name__ == "__main__":
    main()

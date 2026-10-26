#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
essai_troisieme.py — une TROISIÈME lecture apporterait-elle quelque chose ?

    python3 archives/essais/essai_troisieme.py --dep 43 --dep 21 --dep 92

La question, et pourquoi elle ne se règle pas à l'intuition
------------------------------------------------------------
Le 22 août 2026, la fusion de deux lectures — `--psm 6` et `--psm 4`, même
image, même moteur — a valu **+2 756 communes**, faisant passer le rappel de
84,0 % à 91,4 %. Elles ne se recouvraient qu'à 89 %.

D'où la tentation : si deux valent tant, trois vaudraient plus. Mais rien ne le
garantit. **Une troisième lecture excellente qui lirait exactement les mêmes
communes n'apporterait rien.** Ce qui compte n'est pas sa performance propre,
c'est son APPORT MARGINAL à l'union des deux en service.

C'est mesurable en dix minutes, et une passe complète coûte une nuit — deux si
l'on refait aussi la fusion. Le rapport est de un à cent.

Ce que ce banc calcule
----------------------
Pour chaque candidate :

    seule          ce qu'elle lit toute seule
    union 3        ce que donnent les trois lectures réunies
    APPORT         union 3 moins union 2  ← le seul chiffre qui décide
    faux ajoutés   le bruit qu'elle introduit dans l'union

Et deux compteurs, parce que l'un a déjà menti :

    communes       codes INSEE distincts et réels
    rattach.       paires commune-canton — ce que le trou 1943-1999 réclame

Une ville multicantonale vaut un code et plusieurs cantons. Un banc qui ne
compte que les codes sous-estime tout ce qui touche aux villes : mesuré le
22 août, +4 contre +11 sur le même correctif.

L'échantillon
-------------
Trois départements de qualité DIFFÉRENTE, et non trois cas difficiles :
la journée du 22 août a produit quatre conclusions fausses parce que
l'échantillon avait été choisi là où le défaut se trouvait. Un bon lecteur,
un moyen, un mauvais — l'apport marginal doit être regardé dans les trois.

Les candidates
--------------
La résolution est un EFFET DE SCAN et non de chaîne : 400 dpi rend +30, +5 et
+25 selon le fascicule. C'est une mauvaise nouvelle pour choisir un réglage
unique, et une bonne pour la redondance — une lecture irrégulière se trompe
ailleurs que les autres, ce qui est exactement ce qu'on cherche ici.
"""

import argparse
import collections
import csv
import sys
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RACINE / "cog1954"))
sys.path.insert(0, str(RACINE / "cog1968"))
from extrait_1968 import LIGNE, LIGNE_SUITE, EXCLUS, index, SOSIES_1968  # noqa: E402
from extrait_1954 import page_texte                                       # noqa: E402

NOMS = RACINE / "build" / "noms_geofla.csv"

# Les deux lectures EN SERVICE. Leur union est le point de comparaison, et rien
# d'autre : c'est elle qui est en base aujourd'hui.
EN_SERVICE = [("psm6 300", 300, "6"), ("psm4 300", 300, "4")]

CANDIDATES = [
    ("400 dpi psm4", 400, "4"),
    ("400 dpi psm6", 400, "6"),
    ("600 dpi psm4", 600, "4"),
]


def paires(texte, dep):
    """{(code INSEE, canton)} — avec la grammaire complète, LIGNE_SUITE comprise."""
    out = set()
    for brut in texte.splitlines():
        if EXCLUS.search(brut):
            continue
        s = brut.strip()
        m = LIGNE.search(s) or LIGNE_SUITE.search(s)
        if m:
            out.add((dep + m.group(5), m.group(4).translate(SOSIES_1968)))
    return out


def pages_du_dep(dep):
    src = RACINE / "cog1968" / "communes_1968_fusion.csv"
    n = collections.Counter()
    for r in csv.DictReader(src.open(encoding="utf-8")):
        if r["dep"] == dep and r.get("page"):
            n[int(r["page"])] += 1
    return list(range(min(n), max(n) + 1)) if n else []


def chiffres(vus, reels):
    vrais = {(c, ct) for c, ct in vus if c in reels}
    return len({c for c, _ in vrais}), len(vrais), \
           len({c for c, _ in vus if c not in reels})


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", action="append", required=True)
    args = ap.parse_args()

    reels = collections.defaultdict(set)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        reels[r["insee"].strip()[:2]].add(r["insee"].strip())

    fasc = index()
    cumul = collections.defaultdict(lambda: collections.Counter())

    for dep in args.dep:
        if dep not in fasc:
            print(f"département {dep} absent de l'index — sauté.")
            continue
        pages = pages_du_dep(dep)
        if not pages:
            print(f"département {dep} : aucune page connue — sauté.")
            continue

        lectures = {}
        t0 = time.time()
        for nom, dpi, psm in EN_SERVICE + CANDIDATES:
            vus = set()
            for p in pages:
                vus |= paires(page_texte(fasc[dep], p, dpi=dpi, psm=psm), dep)
            lectures[nom] = vus

        union2 = lectures["psm6 300"] | lectures["psm4 300"]
        c2, r2, f2 = chiffres(union2, reels[dep])

        print(f"\ndépartement {dep} — {len(pages)} pages × 5 lectures en "
              f"{time.time()-t0:.0f}s — {len(reels[dep])} communes au référentiel")
        print(f"{'lecture':<16}{'communes':>10}{'rattach.':>10}{'faux':>7}")
        print("-" * 43)
        for nom, _, _ in EN_SERVICE:
            c, r, f = chiffres(lectures[nom], reels[dep])
            print(f"{nom:<16}{c:>10}{r:>10}{f:>7}")
        print(f"{'UNION des 2':<16}{c2:>10}{r2:>10}{f2:>7}   <- en base aujourd'hui")

        print(f"\n{'candidate':<16}{'seule':>8}{'union 3':>9}"
              f"{'APPORT':>8}{'faux +':>8}")
        print("-" * 49)
        for nom, _, _ in CANDIDATES:
            _, r_seule, _ = chiffres(lectures[nom], reels[dep])
            u3 = union2 | lectures[nom]
            c3, r3, f3 = chiffres(u3, reels[dep])
            print(f"{nom:<16}{r_seule:>8}{r3:>9}{r3-r2:>+8}{f3-f2:>+8}")
            cumul[nom]["apport"] += r3 - r2
            cumul[nom]["faux"] += f3 - f2
            cumul[nom]["communes"] += c3 - c2

    if len(args.dep) > 1:
        n = len(args.dep)
        print(f"\nCUMUL sur {n} départements — apport marginal à l'union des deux")
        print(f"{'candidate':<16}{'communes':>10}{'rattach.':>10}{'faux +':>8}")
        print("-" * 44)
        for nom, _, _ in CANDIDATES:
            k = cumul[nom]
            print(f"{nom:<16}{k['communes']:>+10}{k['apport']:>+10}{k['faux']:>+8}")
        print(f"\nExtrapolation grossière à 86 départements (×{86/n:.0f}) :")
        for nom, _, _ in CANDIDATES:
            print(f"   {nom:<16} ~{cumul[nom]['apport']*86//n:>6} rattachements, "
                  f"~{cumul[nom]['faux']*86//n:>4} faux")

    print("\nSEUL `APPORT` décide — pas la performance de la candidate.")
    print("Une lecture excellente qui lit les mêmes communes n'apporte rien.")
    print("\nOrdre de grandeur pour juger : la 2e lecture avait valu +2 756")
    print("communes. En dessous de quelques centaines, une nuit de calcul")
    print("et une refusion ne se justifient pas.")


if __name__ == "__main__":
    main()

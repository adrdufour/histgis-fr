#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
confirme_par_canton.py — le canton confirme-t-il l'appariement par le nom ?

    python3 cog1954/confirme_par_canton.py              # à blanc
    python3 cog1954/confirme_par_canton.py --appliquer

LE PROBLÈME
===========
`apparie_noms.py` pose 26 202 codes en correspondance EXACTE, et laisse
**3 531 propositions FLOUES** dans `insee_propose`, sans code.

Elles ne peuvent pas être posées telles quelles : sur les 8 collisions
observées, deux étaient de vrais faux appariements — `Barneville-sur-Mer`
rapproché de `Bréville`, `Balmelles (Les)` de `Salelles`. Et les collisions ne
révèlent que la partie visible : un faux qui tombe sur une commune libre passe
inaperçu.

**Un appariement par ressemblance n'est sûr que confirmé par une information
qui ne doit rien à la ressemblance.** C'est ce qui a validé les 121 codes
orphelins de 1968, où le test « doublon présent / proposé absent » jouait ce
rôle.

LE SECOND SIGNAL : LE CANTON
============================
Chaque ligne de 1954 porte son canton. Si la commune proposée appartient bien à
ce canton, deux informations indépendantes concordent — l'une tirée du nom,
l'autre d'un chiffre lu ailleurs sur la ligne.

**Pourquoi 1940 et non 1968.** Gaudillère établit que la carte cantonale ne
bouge que TROIS fois entre 1940 et 1954 — Sousceyrac, Tende, Brive-Nord et Sud
— alors que son annexe VII compte trente créations entre 1954 et 1968. Le
référentiel de 1940 est donc bien plus proche de l'état de 1954, malgré une
distance temporelle identique. *La proximité qui compte est celle des
changements, pas celle des années.*

Source : `build/membership_canton.csv`, échantillonné au 1er juin 1940.

RÉSULTAT MESURÉ
===============
    confirmé          3 361     97 % des jugeables
    CONTREDIT           115
    indéterminable       55     commune absente de 1940, ou canton illisible

CE QUI N'EST PAS POSÉ, ET POURQUOI C'EST DÉLIBÉRÉ
==================================================
Les 115 contredits ne sont pas tous de faux appariements. Plusieurs portent un
CANTON manifestement mal lu :

    Fleuriel (Allier)  canton lu 93 — l'Allier n'a pas 93 cantons
    Arricourt (08)     canton lu 23, réel 03
    Contreuve (08)     canton lu 11, réel 31

Le nom est peut-être juste et le canton faux. **Mais on ne confirme pas par un
signal qu'on soupçonne fautif** : ces lignes restent des propositions, marquées
`canton_contredit` pour être reprises si une troisième source apparaît.

Réversible : la sauvegarde d'`apparie_noms.py` fait foi, et `insee_propose`
conserve la proposition pour toute ligne non posée.
"""

import argparse
import collections
import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
MEMB = RACINE / "build" / "membership_canton.csv"

# Le 1er juin 1940 : à l'intérieur du segment TRF-GIS, loin de ses bornes.
DATE_1940 = "1940-06-01"


def cantons_1940():
    """{code INSEE -> {unit_id de canton}} au 1er juin 1940."""
    if not MEMB.exists():
        sys.exit(f"{MEMB} absent.")
    d = collections.defaultdict(set)
    for r in csv.DictReader(MEMB.open(encoding="utf-8")):
        if r["valid_from"] <= DATE_1940 < r["valid_to"] and r["insee"]:
            d[r["insee"]].add(r["unit_id"])
    return d


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    args = ap.parse_args()

    if not LU.exists():
        sys.exit(f"{LU} absent.")
    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))
    if "insee_propose" not in lignes[0]:
        sys.exit("Colonne `insee_propose` absente — jouer d'abord "
                 "`python3 cog1954/apparie_noms.py --appliquer`.")

    ref = cantons_1940()
    print(f"{len(ref)} communes ont un canton au {DATE_1940}\n")

    classes = collections.Counter()
    decisions = []
    contredits = []

    for r in lignes:
        if r.get("appariement") != "flou" or not r.get("insee_propose"):
            decisions.append((r, None))
            continue
        prop = r["insee_propose"]
        ct = (r.get("canton") or "").strip()
        if not ct.isdigit():
            classes["canton illisible"] += 1
            decisions.append((r, "canton_indetermine"))
            continue
        attendu = r["dep"] + ct.zfill(2)
        reel = ref.get(prop)
        if not reel:
            classes["commune absente de 1940"] += 1
            decisions.append((r, "canton_indetermine"))
            continue
        if attendu in reel:
            classes["CONFIRMÉ"] += 1
            decisions.append((r, "confirme"))
        else:
            classes["contredit"] += 1
            contredits.append((r, attendu, sorted(reel)))
            decisions.append((r, "canton_contredit"))

    total = sum(classes.values())
    print(f"{total} propositions floues examinées\n")
    for k in ("CONFIRMÉ", "contredit", "commune absente de 1940",
              "canton illisible"):
        if classes[k]:
            print(f"   {k:<26} {classes[k]:>6}")
    jugeables = classes["CONFIRMÉ"] + classes["contredit"]
    print(f"\n   taux de confirmation sur les jugeables : "
          f"{classes['CONFIRMÉ'] / max(jugeables, 1):.0%}")

    if contredits:
        print("\n  six contredits — le NOM ou le CANTON est fautif, on ne")
        print("  tranche pas :")
        for r, att, reel in contredits[:6]:
            print(f"     {r['dep']} « {r['commune'][:22]:<22} » -> "
                  f"{r['insee_propose']}   canton lu {att}, réel {reel}")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    pose = 0
    for r, d in decisions:
        if d == "confirme":
            r["insee"] = r["insee_propose"]
            r["appariement"] = "ferme_canton"
            r["insee_propose"] = ""
            pose += 1
        elif d:
            r["appariement"] = d

    with LU.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)

    final = collections.Counter(r["appariement"] for r in lignes)
    avec_code = sum(1 for r in lignes if r["insee"])
    print(f"\n{pose} codes posés (`ferme_canton`).")
    print(f"\nÉTAT FINAL de communes_1954_redecoupe.csv :")
    for k, n in final.most_common():
        print(f"   {k:<20} {n:>6}")
    print(f"\n   AVEC UN CODE INSEE   {avec_code:>6}   "
          f"{avec_code/len(lignes):.1%} des {len(lignes)} lignes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

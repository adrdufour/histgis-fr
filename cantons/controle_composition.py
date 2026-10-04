#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_composition.py — juger l'extraction des décrets par le COG de 1999

    python3 cantons/controle_composition.py

Produit `cantons/controle_composition.csv`.

Le principe
-----------
`composition_decrets.py` annonce 95 % de noms appariés. Ce chiffre ne dit rien
de l'exactitude : un nom parfaitement apparié rangé sous le mauvais canton
reste une erreur, et l'appariement ne peut pas la voir — il ne regarde que le
nom, jamais le canton.

Il faut donc une source qui ne vienne pas des décrets. Le **COG de 1999** en
est une : `comsimp1999.txt` donne, pour chaque commune, son canton (colonnes
`DEP`, `COM`, `CT`). Le rapprochement est possible partout où un canton créé
entre 1973 et 1984 a survécu jusqu'en 1999.

Ce que la comparaison peut dire, et ce qu'elle ne peut pas
----------------------------------------------------------
**Un accord est concluant.** Si le décret de 1982 et le COG de 1999 rangent
les mêmes communes sous le même canton, deux lectures indépendantes tombent
d'accord, dont une qui n'a jamais vu le texte du JO.

**Un désaccord est ambigu**, et c'est la limite honnête de ce contrôle. Il
peut venir de nous — nom mal apparié, canton mal lu, liste mal coupée — comme
il peut venir du monde : entre 1982 et 1999, une commune a pu changer de
canton par un décret que nous n'avons pas dépouillé. C'est même attendu :
c'est précisément ce que le registre cantonal recense.

Donc **le taux d'accord se lit comme un plancher, jamais comme une note.** Un
accord élevé prouve que l'extraction tient ; un désaccord isolé ne prouve pas
qu'elle a tort.

L'appariement des cantons
-------------------------
La difficulté est que les décrets nomment les cantons (« Bourg-Est ») quand le
COG les numérote (`CT = 05`). On n'apparie donc pas par le code, on apparie
**par la composition elle-même** : le canton du COG retenu est celui qui
partage le plus de communes avec la liste du décret, dans le même département.
C'est faible pris isolément, mais c'est indépendant du nom — et le nom est
justement ce que l'OCR abîme.
"""

import argparse
import collections
import csv
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
EXTRAIT = RACINE / "cantons" / "composition_decrets.csv"
COG = RACINE / "sources" / "cog" / "1999" / "comsimp1999.txt"
SORTIE = RACINE / "cantons" / "controle_composition.csv"

# En deçà de trois communes entières, l'appariement par recouvrement ne
# distingue plus rien : deux cantons voisins partagent facilement une commune.
# Seuil posé avant de mesurer.
MINI = 3


def cog_1999():
    """{dep: {commune_insee: canton}} et {(dep, canton): {communes}}."""
    par_commune, par_canton = {}, collections.defaultdict(set)
    with COG.open(encoding="latin-1") as f:
        for l in csv.DictReader(f, delimiter="\t"):
            dep, com, ct = l["DEP"], l["COM"], (l["CT"] or "").strip()
            if not ct:
                continue
            insee = dep + com
            par_commune[insee] = (dep, ct)
            par_canton[(dep, ct)].add(insee)
    return par_commune, par_canton


def main():
    # Le contrôle vaut pour toute extraction qui rend les mêmes colonnes.
    # `composition_jo.py` en est une seconde ; on ne duplique pas le juge.
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default=str(EXTRAIT))
    ap.add_argument("--sortie", default=str(SORTIE))
    args = ap.parse_args()
    globals()["EXTRAIT"] = Path(args.source)
    globals()["SORTIE"] = Path(args.sortie)
    if not EXTRAIT.exists():
        raise SystemExit("Lancer d'abord composition_decrets.py.")
    par_commune, par_canton = cog_1999()
    print(f"COG 1999 : {len(par_commune)} communes, "
          f"{len(par_canton)} cantons\n")

    # les listes du décret, regroupées par (décret, canton)
    listes = collections.defaultdict(list)
    for l in csv.DictReader(EXTRAIT.open(encoding="utf-8")):
        if l["insee"]:
            listes[(l["decret"], l["date"], l["dep"], l["canton"])].append(
                l["insee"])

    lignes = []
    for (dec, date, dep, canton), communes in sorted(listes.items()):
        communes = set(communes)
        if len(communes) < MINI:
            lignes.append(dict(decret=dec, date=date, dep=dep, canton=canton,
                               communes=len(communes), canton_1999="",
                               retrouvees=0, taux="", verdict="trop court"))
            continue
        # le canton de 1999 qui partage le plus de communes avec la liste
        votes = collections.Counter(par_commune[c][1] for c in communes
                                    if c in par_commune
                                    and par_commune[c][0] == dep)
        if not votes:
            lignes.append(dict(decret=dec, date=date, dep=dep, canton=canton,
                               communes=len(communes), canton_1999="",
                               retrouvees=0, taux="0 %",
                               verdict="aucune commune retrouvée en 1999"))
            continue
        ct, n = votes.most_common(1)[0]
        taux = n / len(communes)
        lignes.append(dict(
            decret=dec, date=date, dep=dep, canton=canton,
            communes=len(communes), canton_1999=f"{dep}-{ct}",
            retrouvees=n, taux=f"{100*taux:.0f} %",
            verdict=("accord" if taux >= 0.8 else
                     "accord partiel" if taux >= 0.5 else "désaccord")))

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0]))
        w.writeheader()
        w.writerows(sorted(lignes, key=lambda x: (x["verdict"], x["dep"])))

    v = collections.Counter(l["verdict"] for l in lignes)
    jugeables = [l for l in lignes if l["verdict"] in
                 ("accord", "accord partiel", "désaccord")]
    print(f"{len(lignes)} cantons extraits des décrets")
    for k, n in v.most_common():
        print(f"   {k:34s} {n:4d}")
    if jugeables:
        d = sum(l["retrouvees"] for l in jugeables)
        t = sum(l["communes"] for l in jugeables)
        print(f"\nSur les {len(jugeables)} cantons jugeables : "
              f"{d} communes sur {t} retrouvées dans le même canton en 1999 "
              f"— {100*d/t:.1f} %")
    print(f"\n{SORTIE}")
    print("\nUn désaccord n'accuse pas l'extraction : entre le décret et 1999,")
    print("une commune a pu changer de canton. Le taux est un plancher.")


if __name__ == "__main__":
    main()

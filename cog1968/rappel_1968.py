#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
rappel_1968.py — combien de communes l'extraction a-t-elle réellement lues ?

    python3 cog1968/rappel_1968.py
    python3 cog1968/rappel_1968.py --detail       # les 20 pires départements

Pourquoi ce fichier existe
--------------------------
Le rappel de l'extraction de 1968 était cité — « 77,6 % » — sans qu'aucun
script ne le calcule. La docstring de `lignes_rejetees.py` renvoyait même à une
option `--attendu` d'`extrait_1968.py` qui **n'a jamais existé**. Un chiffre
sans commande qui le produise n'est pas une mesure : c'est un souvenir.

L'étalon
--------
`cm_commune`, construite par `20_commune_moderne.sql` à partir des mouvements
communaux de l'INSEE (1943-2025). Elle donne, pour chaque code, ses intervalles
d'existence. La liste des communes vivantes au **1er janvier 1968** en découle
sans arbitrage.

C'est un étalon INDÉPENDANT de l'OCR : il vient d'un fichier administratif, pas
d'une lecture d'image. Il a ses propres limites — le fichier INSEE commence en
1943, et une commune disparue avant cette date n'y figure pas — mais aucune de
ces limites ne dépend de la qualité de notre extraction.

Ce que le rappel ne dit pas
---------------------------
Il compte les communes LUES, pas les communes BIEN lues. Une ligne dont le code
INSEE a été mal reconnu fait disparaître sa commune des « trouvés » et crée un
DOUBLON sur une autre — laquelle est parfaitement connue de l'étalon. Le rappel
est donc un plafond, et c'est le nombre de doublons, non celui des « inconnus »,
qui mesure l'autre moitié du problème. Voir `controle_nom_code.py`.
"""

import argparse
import csv
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1968" / "communes_1968.csv"

sys.path.insert(0, str(RACINE))
from outils.base import connexion                        # noqa: E402

DATE = "1968-01-01"


def attendu(cur):
    """{code INSEE} des communes vivantes au 1er janvier 1968."""
    cur.execute("SET search_path TO histgis, public")
    cur.execute("SELECT to_regclass('histgis.cm_commune') IS NOT NULL")
    if not cur.fetchone()[0]:
        sys.exit("cm_commune absente : jouer sql/20_commune_moderne.sql.")
    cur.execute(
        "SELECT DISTINCT code FROM cm_commune "
        " WHERE daterange(valid_from, valid_to, '[)') @> %s::date", (DATE,))
    return {r[0].strip() for r in cur.fetchall()}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--detail", action="store_true",
                    help="lister les départements les plus mal lus")
    ap.add_argument("--fichier", help="mesurer un autre CSV que communes_1968.csv "
                                      "(ex. communes_1968_fusion.csv)")
    ap.add_argument("--sur", choices=("tout", "sur", "hors"), default="tout",
                    help="restreindre aux lignes dont `accord` vaut "
                         "`canton_conteste` (sur) ou non (hors)")
    args = ap.parse_args()

    src = Path(args.fichier) if args.fichier else LU
    if not src.is_absolute():
        src = RACINE / "cog1968" / src.name
    if not src.exists():
        sys.exit(f"{src} absent : lancer `python3 cog1968/extrait_1968.py --tous`.")

    lignes = list(csv.DictReader(src.open(encoding="utf-8")))
    # Le rappel d'un sous-ensemble se lit contre le MÊME dénominateur : il dit
    # quelle part des communes de 1968 ce sous-ensemble couvre, pas sa qualité
    # interne. Comparer `sur` et `hors` sans le rappeler serait trompeur.
    if args.sur != "tout" and lignes and "accord" in lignes[0]:
        garde = (lambda r: r["accord"] == "canton_conteste") if args.sur == "sur" \
            else (lambda r: r["accord"] != "canton_conteste")
        lignes = [r for r in lignes if garde(r)]
        print(f"(restreint à `{args.sur}` : {len(lignes)} lignes)\n")
    lus = {r["insee"].strip() for r in lignes if r["insee"].strip()}
    deps_lus = {r["dep"] for r in lignes}

    with connexion() as cnx, cnx.cursor() as cur:
        att = attendu(cur)

    # On ne juge que les départements dont on a le fascicule. Compter les neuf
    # manquants comme « non lus » mélangerait deux choses très différentes :
    # une source absente et une lecture ratée.
    att_perimetre = {c for c in att if c[:2] in deps_lus}

    trouves = lus & att_perimetre
    manquants = att_perimetre - lus
    inconnus = lus - att            # lus mais absents de l'étalon

    print(f"périmètre : {len(deps_lus)} départements sur 95")
    print(f"attendu   : {len(att_perimetre)} communes au 1er janvier 1968")
    print(f"lu        : {len(lus)} codes distincts "
          f"({len(lignes)} lignes)")
    print()
    print(f"  RAPPEL   {len(trouves) / len(att_perimetre):6.1%}   "
          f"({len(trouves)} / {len(att_perimetre)})")
    print(f"  manquants  {len(manquants):>6}")
    print(f"  lus mais inconnus de l'étalon  {len(inconnus):>6}")
    print(f"  doublons (lignes - codes distincts)  {len(lignes) - len(lus):>6}")
    print()
    # CE QUE MESURE CHAQUE LIGNE — corrigé le 22 août 2026, après une
    # prédiction fausse de ma part.
    #
    # Un code mal lu ne produit PAS un « inconnu » : il désigne une autre
    # commune du département, parfaitement connue de l'étalon. Il produit un
    # DOUBLON, et fait disparaître la vraie commune des « trouvés ».
    #
    # La correction de 331 codes le 22 août 2026 l'a montré : le rappel est
    # monté de 330 communes, les doublons ont baissé de 330, et les
    # « inconnus » n'ont pas bougé d'une unité.
    print("  Un code mal lu produit un DOUBLON, pas un inconnu : il designe")
    print("  une autre commune du departement, connue de l'etalon. Suivre les")
    print("  doublons, donc, et non les inconnus, pour juger d'une correction.")
    print()
    print("  Les « inconnus » sont autre chose : des codes absents de la trame")
    print("  2011 — communes disparues depuis, ou lectures impossibles.")

    par_dep = defaultdict(lambda: [0, 0])
    for c in att_perimetre:
        par_dep[c[:2]][1] += 1
    for c in trouves:
        par_dep[c[:2]][0] += 1

    scores = sorted(((t / n, d, t, n) for d, (t, n) in par_dep.items() if n),
                    key=lambda x: x[0])
    print(f"\ndépartements sous 80 % : "
          f"{sum(1 for s, *_ in scores if s < 0.80)} sur {len(scores)}")
    if args.detail:
        print("\nles 20 plus mal lus :")
        for s, d, t, n in scores[:20]:
            print(f"   {d}  {s:6.1%}   {t:>4} / {n:>4}")
        print("\nles 5 mieux lus :")
        for s, d, t, n in scores[-5:]:
            print(f"   {d}  {s:6.1%}   {t:>4} / {n:>4}")

    # Les « inconnus » par département : une concentration désigne un fascicule
    # dont les codes sont mal lus, pas une source incomplète.
    if args.detail and inconnus:
        c = Counter(x[:2] for x in inconnus)
        print("\ncodes lus mais inconnus, par département (10 premiers) :")
        for d, n in c.most_common(10):
            print(f"   {d}  {n:>4}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

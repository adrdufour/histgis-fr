#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
paris_circo_1815.py — les cinq divisions électorales d'avant 1860,
                       posées sur la trame des 48 quartiers de Vasserot

    python3 circo/paris_circo_1815.py

Ce qu'il fait
-------------
Il rattache les cinq divisions que `paris_circo.py` écarte — **1815,
1820-1831, 1831-1848, 1852-1857, 1857-1863** — aux 48 quartiers d'ALPAGE /
Vasserot, via `paris_vocab_1815.csv`. Sortie : `circo/paris_circo_1815.csv`,
une ligne par (division, circonscription, quartier), que
`sql/54_paris_circo_1815.sql` charge en base.

`paris_circo.py` a raison de les écarter : elles emploient l'AUTRE système de
quartiers, et le mélanger avec celui des 80 mettrait des territoires les uns
sur les autres — l'homonymie entre les deux nomenclatures est réelle et le
script d'origine la nomme comme un piège. Ici la trame est la bonne.

La recette, et pourquoi elle vaut quelque chose
-----------------------------------------------
Une division électorale doit **partitionner** la ville : chaque quartier une
fois, tous les quartiers. C'est une contrainte qui ne vient pas de nous mais de
la nature de l'objet, et elle ne peut pas être satisfaite par hasard sur 48
éléments.

Mesuré : les cinq divisions citent 48 quartiers sur 48, sans un non résolu.
Un seul quartier est cité deux fois, en 1815.

Ce qui n'est pas posé
---------------------
Un quartier cité par deux circonscriptions ne peut pas devenir un atome unique :
un atome n'appartient qu'à une unité par niveau à une date donnée, et la
contrainte `EXCLUDE` de la base le refuse. On suit le précédent de
`27_circo_2012.sql` et de `52_paris_circo_1986.sql` : poser ce qui est entier,
**nommer** ce qui est coupé.

La date de levé
---------------
La trame de Vasserot s'étale de 1810 à 1836. Une limite de 1815 peut donc être
dessinée d'après un levé de 1836 — anachronisme d'un quart de siècle, inhérent
à la source et non à ce script. La colonne `date_leve` de
`paris_quartier_1815` le porte, et le tableau final le rappelle.
"""

import collections
import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
DECOUPAGE = RACINE / "circo" / "paris_decoupage.csv"
VOCAB = RACINE / "circo" / "paris_vocab_1815.csv"
SORTIE = RACINE / "circo" / "paris_circo_1815.csv"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extrait_paris import cle                           # noqa: E402

# Les cinq divisions antérieures à 1860, dans l'ordre, avec leurs bornes.
# Chaque division court jusqu'au début de la suivante ; les dates sont celles
# du libellé de la transcription, rien n'est arrondi.
#
# 1848-1852 MANQUE : aucune division n'est transcrite entre la fin de la
# monarchie de Juillet et 1852. Le trou est réel et reste ouvert.
DIVISIONS = [
    ("1815",      "1815-01-01", "1820-01-01"),
    ("1820-1831", "1820-01-01", "1831-01-01"),
    ("1831-1848", "1831-01-01", "1848-01-01"),
    ("1852-1857", "1852-01-01", "1857-01-01"),
    ("1857-1863", "1857-01-01", "1863-01-01"),
]


def main():
    for f in (DECOUPAGE, VOCAB):
        if not f.exists():
            sys.exit(f"Fichier absent : {f}")

    vocab = {r["cle"]: (int(r["quartier"]), r["nom_vasserot"])
             for r in csv.DictReader(VOCAB.open(encoding="utf-8"))}
    lignes = list(csv.DictReader(DECOUPAGE.open(encoding="utf-8")))

    sortie, coupes, inconnus = [], [], collections.Counter()

    print("division      circos  quartiers  absents  coupes  non resolus")
    for periode, du, au in DIVISIONS:
        lot = [r for r in lignes
               if r["periode"] == periode and r["quartier"].strip()]
        par_q = collections.defaultdict(set)
        for r in lot:
            k = cle(r["quartier"])
            if k not in vocab:
                inconnus[k] += 1
                continue
            par_q[vocab[k][0]].add(r["circo_label"])

        coupe = {q for q, cs in par_q.items() if len(cs) > 1}
        for q, cs in sorted(par_q.items()):
            if q in coupe:
                coupes.append((periode, q, vocab_nom(vocab, q), sorted(cs)))
                continue
            sortie.append((periode, du, au, next(iter(cs)), q,
                           vocab_nom(vocab, q)))

        n_circo = len({r["circo_label"] for r in lot})
        print(f"{periode:<13} {n_circo:>6} {len(par_q):>10} "
              f"{48 - len(par_q):>8} {len(coupe):>7} "
              f"{sum(1 for r in lot if cle(r['quartier']) not in vocab):>12}")

    with SORTIE.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["periode", "du", "au", "circo", "quartier", "nom"])
        w.writerows(sortie)

    print(f"\n{SORTIE.relative_to(RACINE)} : {len(sortie)} lignes")
    print(f"circonscriptions distinctes : "
          f"{len({(p, c) for p, _, _, c, _, _ in sortie})}")

    if coupes:
        print(f"\nquartiers COUPES, non poses ({len(coupes)}) :")
        for p, q, nom, cs in coupes:
            print(f"   {p:<12} quartier {q:>2} {nom:<24} entre "
                  + " et ".join(cs))
        print("   L'atlas nomme parfois les rues ; les decouper demande une")
        print("   trame infra-quartier que nous n'avons pas. Les laisser vides")
        print("   est exact ; leur attribuer une circonscription ne le serait pas.")

    if inconnus:
        print(f"\nNON RESOLUS ({len(inconnus)}) — a corriger dans le vocabulaire :")
        for k, n in inconnus.most_common():
            print(f"   {k:<28} {n} occ.")
        return 1

    print("\nSuite : psql -d histgis -1 -v appliquer=1 "
          "-f sql/54_paris_circo_1815.sql")
    return 0


def vocab_nom(vocab, q):
    for _, (num, nom) in vocab.items():
        if num == q:
            return nom
    return "?"


if __name__ == "__main__":
    sys.exit(main())

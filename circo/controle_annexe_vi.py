#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_annexe_vi.py — la transcription du § 6 retombe-t-elle sur ses totaux ?

    python3 circo/controle_annexe_vi.py

Pourquoi ce contrôle existe
---------------------------
`circo/annexe_vi_villes_divisees.csv` est transcrit de PHOTOGRAPHIES du tableau
des 98 villes divisées (pages 784-786). Une erreur de lecture y produirait un
faux défaut de la couche — et `annexe_vi.md` met déjà en garde contre cela.

Mais le tableau porte son propre garde-fou : **la ligne TOTAL**. Elle n'est pas
une donnée de plus, c'est une somme, et une somme se recalcule. Une
transcription qui ne retombe pas dessus est fautive quelque part.

LA RÈGLE DE COMPTAGE, DÉDUITE ET NON SUPPOSÉE
---------------------------------------------
Le texte dit qu'une date entre parenthèses signale une division survenue EN
COURS de découpage — `(1902)` en colonne 1889 vaut 1902-1919. Il ne dit pas si
ces villes entrent dans le total.

La mesure tranche. En comptant tout, la colonne 1889 donne 33 pour 22 annoncés.
En ne comptant que les `X` pleins, elle donne **22 exactement**, et 1927 donne
**41 exactement**. Deux colonnes indépendantes, deux concordances exactes :

    **le TOTAL ne compte que les villes divisées dès l'OUVERTURE du découpage.**

C'est la règle, et elle valide du même coup la transcription de ces deux
colonnes — celles qui portent le plus de villes.

CE QUE CE SCRIPT NE FAIT PAS
----------------------------
Il ne corrige rien. Quatre colonnes restent en écart, et l'une d'elles a une
explication séduisante : déplacer le `X` de Brest de 1875 vers 1867 résoudrait
D'UN COUP les deux écarts (1867 passerait à 14, 1875 à 19, les deux valeurs
attendues).

**On ne le fait pas.** Ce serait ajuster la transcription sur l'étalon qu'elle
sert à vérifier — la faute que `METHODE.md` interdit expressément, et qui rend
tout contrôle ultérieur circulaire. L'hypothèse est signalée, à trancher sur
l'original.
"""

import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SRC = RACINE / "circo" / "annexe_vi_villes_divisees.csv"

COLS = ["1815", "1820", "1831", "1852", "1857", "1862",
        "1867", "1875", "1889", "1927", "1958", "1986"]

# La ligne TOTAL du tableau, page 786. C'est l'étalon de ce contrôle.
TOTAL = dict(zip(COLS, [1, 4, 12, 9, 10, 12, 14, 19, 22, 41, 43, 81]))

# Les découpages que la couche 1870-1940 peut confronter.
TESTABLES = ("1875", "1889", "1927")


def main():
    if not SRC.exists():
        sys.exit(f"{SRC} absent.")
    r = list(csv.DictReader(SRC.open(encoding="utf-8")))

    print(f"{len(r)} villes transcrites — le tableau en annonce 98"
          f"  {'OK' if len(r) == 98 else '<-- ÉCART'}\n")
    print(f"{'colonne':>8}{'X pleins':>10}{'parenth.':>10}"
          f"{'TOTAL':>7}{'écart':>7}   statut")
    print("-" * 60)

    exacts = []
    for c in COLS:
        plein = sum(1 for x in r if x["d" + c] == "X")
        par = sum(1 for x in r if x["d" + c] and x["d" + c] != "X")
        e = plein - TOTAL[c]
        if e == 0:
            exacts.append(c)
        marque = "" if e == 0 else "  à relire sur l'original"
        vise = " *" if c in TESTABLES else "  "
        print(f"{c:>8}{plein:>10}{par:>10}{TOTAL[c]:>7}{e:>+7}{vise}{marque}")

    print(f"\n  * = découpage confrontable à la couche 1870-1940")
    print(f"\n{len(exacts)} colonnes sur {len(COLS)} retombent exactement : "
          f"{', '.join(exacts)}")

    utiles = [c for c in TESTABLES if c in exacts]
    print(f"dont {len(utiles)} des 3 colonnes utiles : {', '.join(utiles) or 'aucune'}")

    print("\nLes villes divisées dès l'ouverture, par découpage confrontable :")
    for c in TESTABLES:
        v = sorted(x["ville"] for x in r if x["d" + c] == "X")
        print(f"\n  {c} — {len(v)} villes"
              f"{'  (concorde)' if c in exacts else '  (ÉCART, cf. ci-dessus)'}")
        for i in range(0, len(v), 4):
            print("     " + ", ".join(v[i:i + 4]))

    print("\n" + "-" * 60)
    print("Hypothèse NON appliquée : le X de Brest en 1875 serait en 1867.")
    print("Elle résoudrait les deux écarts d'un seul coup — raison de plus")
    print("de ne pas la poser sans l'original. Ajuster une transcription sur")
    print("le total qu'elle doit vérifier rend tout contrôle circulaire.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

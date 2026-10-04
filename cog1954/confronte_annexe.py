#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
confronte_annexe.py — le tableau A de 1954 contre l'annexe VII de Gaudillère

    python3 cog1954/confronte_annexe.py

Deux sources qui n'ont rien en commun décrivent la même période :

* **l'annexe VII** de l'atlas Gaudillère, transcrite à la main dans
  `cantons/annexe_vii.csv` — un travail d'historien sur les décrets ;
* **le tableau A** du recensement de 1954, page 895, transcrit dans
  `cog1954/tableau_a_1954.csv` — un document administratif contemporain
  des faits.

L'une est postérieure et savante, l'autre contemporaine et officielle. Elles
n'ont ni auteur, ni méthode, ni époque communs. Leur accord vaut donc
davantage que la somme de leurs autorités : c'est un contrôle indépendant au
sens de `METHODE.md`.

Ce que le contrôle ne peut pas faire
------------------------------------
Il ne compare que les CRÉATIONS et les SUPPRESSIONS de cantons entre 1941 et
1954. Le tableau A ne recense pas les transferts de communes entre cantons —
il note seulement que « de nombreuses communes ont changé de canton », en
renvoyant aux tableaux de population. L'annexe VII ne les recense jamais non
plus. Sur ce point, les deux sources se taisent ensemble, et leur silence ne
prouve rien.
"""

import collections
import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
TABLEAU = RACINE / "cog1954" / "tableau_a_1954.csv"
ANNEXE = RACINE / "cantons" / "annexe_vii.csv"

DEBUT, FIN = "1941-01-01", "1954-12-31"
CANTONAL = {"creation", "suppression", "fusion"}


def cle(dep, texte):
    """Clé de rapprochement : département + premiers mots significatifs."""
    t = (texte or "").lower()
    for prefixe in ("cr. ", "suppr. ", "création ", "suppression "):
        if t.startswith(prefixe):
            t = t[len(prefixe):]
    t = t.split("(")[0]
    mots = [m for m in t.replace("-", " ").split() if len(m) > 2]
    return dep, " ".join(mots[:2])


def main():
    for f in (TABLEAU, ANNEXE):
        if not f.exists():
            sys.exit(f"{f} absent.")

    ta = [l for l in csv.DictReader(TABLEAU.open(encoding="utf-8"))
          if l["type"] in CANTONAL]
    av = [l for l in csv.DictReader(ANNEXE.open(encoding="utf-8"))
          if l["type"] in CANTONAL and DEBUT <= l["date_iso"] <= FIN]

    print(f"tableau A  : {len(ta)} décisions cantonales")
    print(f"annexe VII : {len(av)} décisions cantonales entre 1941 et 1954\n")

    ita = {cle(l["dep"], l["texte"]): l for l in ta}
    iav = {cle(l["dep"], l["texte"]): l for l in av}

    communs = sorted(set(ita) & set(iav))
    print(f"{'':2s} {'dép.':>5s}  {'objet':28s} {'tableau A':>12s} "
          f"{'annexe VII':>12s}")
    accord = 0
    for k in communs:
        a, b = ita[k]["date_iso"], iav[k]["date_iso"]
        ok = a == b
        accord += ok
        print(f"{'  ' if ok else '!!'} {k[0]:>5s}  {k[1][:28]:28s} "
              f"{a:>12s} {b:>12s}")

    seul_ta = sorted(set(ita) - set(iav))
    seul_av = sorted(set(iav) - set(ita))
    print(f"\nen commun : {len(communs)}   dont dates identiques : {accord}")
    if seul_ta:
        print(f"\nseulement dans le tableau A ({len(seul_ta)}) :")
        for k in seul_ta:
            print(f"   {k[0]}  {ita[k]['texte'][:70]}")
    if seul_av:
        print(f"\nseulement dans l'annexe VII ({len(seul_av)}) :")
        for k in seul_av:
            print(f"   {k[0]}  {iav[k]['texte'][:70]}  ({iav[k]['date_iso']})")

    # --- second niveau : par DÉPARTEMENT ET DATE ------------------------
    #
    # Les deux sources ne découpent pas les événements de la même façon.
    # L'annexe écrit « Cr. Brive-N. et Brive-S. (dédoublement Brive) » sur une
    # ligne ; le tableau A en écrit trois — deux créations et une suppression.
    # Même décret, même jour, granularité différente. Comparer les libellés
    # fait alors apparaître un désaccord là où il n'y en a pas.
    #
    # La DATE et le DÉPARTEMENT sont le niveau où les deux sources sont
    # comparables, parce qu'ils ne dépendent d'aucune convention d'écriture.
    jta = collections.defaultdict(list)
    jav = collections.defaultdict(list)
    for l in ta:
        jta[(l["dep"], l["date_iso"])].append(l["texte"])
    for l in av:
        jav[(l["dep"], l["date_iso"])].append(l["texte"])

    print("\n--- au niveau (département, date), qui ne dépend d'aucune "
          "convention d'écriture ---")
    for k in sorted(set(jta) | set(jav)):
        a, b = len(jta.get(k, [])), len(jav.get(k, []))
        etat = "les deux" if a and b else ("tableau A seul" if a else "annexe seule")
        print(f"   {k[0]:>3s}  {k[1]}   tableau A : {a}  annexe VII : {b}   {etat}")
    manque = (set(jta) ^ set(jav))
    print(f"\ndates présentes dans une seule source : {len(manque)}"
          + (f" — {sorted(manque)}" if manque else " — aucune"))

    if not seul_ta and not seul_av and accord == len(communs):
        print("\n**Accord complet.** Deux sources sans auteur, méthode ni "
              "époque communs donnent la même liste et les mêmes dates.")
    elif not seul_ta and not seul_av:
        print("\n**Même liste, dates divergentes sur "
              f"{len(communs)-accord} cas.** À trancher sur pièces : la "
              "divergence est une information, pas un défaut.")


if __name__ == "__main__":
    main()

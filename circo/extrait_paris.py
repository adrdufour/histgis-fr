#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extrait_paris.py — met au propre paris_decoupage.xlsx

    python3 circo/extrait_paris.py

Produit :
    circo/paris_decoupage.csv   une ligne par (division, circonscription, quartier)
    circo/paris_vocab.csv       les orthographes de quartiers rencontrées

Ce que le script répare, et pourquoi
------------------------------------
1. **La numérotation détruite par Excel.** De 1876 à 1940 les circonscriptions
   se numérotent par arrondissement : `2/11` est la 2e circonscription du 11e.
   Excel a lu ces cellules comme des dates. La conversion est réversible — le
   mois porte le numéro de circonscription, le jour l'arrondissement — mais
   elle doit être défaite ici, pas dans le tableur, sinon un simple
   enregistrement l'aggrave.

2. **Le doublon de 1928-1940.** Deux blocs de 37 circonscriptions, identiques
   ligne à ligne. Un seul est conservé.

3. **Les deux divisions empilées sous `1893-1898`.** Elles diffèrent de deux
   arrondissements : le 4e à deux circonscriptions puis à une, le 16e à une
   puis à deux. Le premier bloc est le bon pour 1893-1898 (confirmé) ; le
   second est une division postérieure dont la date reste à établir. Il sort
   sous l'étiquette `?-?` avec `statut = periode_inconnue` — déclarée
   inconnue plutôt que devinée.

4. Les scories : `1920-1831` pour 1820-1831, `grandes-carrières-clignancourt`
   séparé par un tiret au lieu d'une virgule, la ligne `1914-1919` qui est un
   renvoi et non une donnée.

Ce que le script ne fait PAS
---------------------------
Il ne normalise pas les noms de quartiers. Il y a 92 orthographes pour 80
quartiers, mais le nom canonique doit venir de la couche officielle des
quartiers administratifs de la Ville de Paris, par jointure — pas d'une table
écrite de mémoire. `paris_vocab.csv` est là pour préparer cette jointure et
isoler ce qui ne tombera pas tout seul.
"""

import csv
import datetime
import unicodedata
from pathlib import Path

import openpyxl

RACINE = Path(__file__).resolve().parent.parent
SRC = RACINE / "circo" / "paris_decoupage.xlsx"
OUT = RACINE / "circo" / "paris_decoupage.csv"
VOCAB = RACINE / "circo" / "paris_vocab.csv"

# Les divisions où le numéro désigne un ARRONDISSEMENT (une ou plusieurs
# circonscriptions par arrondissement). Avant 1876 et après 1945, la
# numérotation est globale sur la ville.
PAR_ARRONDISSEMENT = {
    "1876-1881", "1881-1885", "1889-1893", "1893-1898",
    "1902-1910", "1910-1914", "1928-1940", "?-?",
}

# Corrections d'étiquettes de période
CORRIGE_PERIODE = {"1920-1831": "1820-1831"}

# Séparateurs de quartiers mal saisis : deux quartiers collés en un seul jeton
RECOLLE = {
    "grandes-carrières-clignancourt": "grandes-carrières, clignancourt",
    "jardin-des-plantes val-de-grace": "jardin-des-plantes, val-de-grace",
}

# Coquilles de saisie. Chacune est justifiée par une preuve INTERNE : les deux
# formes coexistent dans le fichier et désignent le même quartier. Aucune
# n'est corrigée de mémoire — le nom canonique viendra de la jointure avec la
# couche officielle. Ici on ne fait que réunir ce qui est déjà réuni ailleurs.
# Noter que la coquille est souvent PLUS fréquente que la forme correcte :
# la fréquence ne décide de rien.
COQUILLES = {
    "artetmetiers": "artsetmetiers",
    "chaussedantin": "chausseedantin",
    "enfantrouges": "enfantsrouges",
    "faubourgmontmarte": "faubourgmontmartre",
    "lavilette": "lavillette",
    "maisonsblanche": "maisonblanche",
    "marche": "marches",
    "montmarte": "montmartre",
    "portesaintdenis": "portedesaintdenis",
    "rochechouar": "rochechouart",
    "saintaveye": "saintavoye",
    "saintmarguerite": "saintemarguerite",
}


def lire_numero(v, par_arrondissement):
    """Rend (arrondissement, circonscription) — l'un des deux peut être None.

    Excel a transformé `2/11` en datetime(mois=2, jour=11). La paire
    (mois, jour) porte donc (circonscription, arrondissement) sans perte.
    """
    if isinstance(v, datetime.datetime):
        return v.day, v.month          # jour = arrondissement, mois = circo
    if v is None:
        return None, None
    s = str(v).strip()
    if s in ("-", ""):
        return None, None
    if "/" in s:                       # au cas où une cellule aurait survécu
        a, b = s.split("/", 1)
        return int(b), int(a)
    n = int(float(s))
    return (n, None) if par_arrondissement else (None, n)


def quartiers(cellule):
    s = str(cellule or "").strip()
    for faux, vrai in RECOLLE.items():
        s = s.replace(faux, vrai)
    return [q.strip() for q in s.split(",") if q.strip()]


def cle(nom):
    """Clé de rapprochement : sans accent, sans tiret, sans espace."""
    n = unicodedata.normalize("NFD", nom.lower())
    n = "".join(c for c in n if unicodedata.category(c) != "Mn")
    n = "".join(c for c in n if c.isalnum())
    return COQUILLES.get(n, n)


def main():
    wb = openpyxl.load_workbook(SRC, data_only=True)
    ws = wb["Feuil1"]
    brut = [(i,) + r for i, r in enumerate(ws.iter_rows(min_row=2, values_only=True), 2)
            if any(r)]

    # --- 1. réécriture des étiquettes de période ---------------------------
    lignes = []
    for ligne, annee, compo, numero, ville, remarque in brut:
        periode = CORRIGE_PERIODE.get(str(annee), str(annee))

        # les deux divisions empilées sous 1893-1898 : le second bloc est
        # une division postérieure, non datée
        if periode == "1893-1898" and ligne >= 176:
            periode = "?-?"

        # le doublon strict de 1928-1940 : on jette le second bloc
        if periode == "1928-1940" and ligne >= 335:
            continue

        lignes.append((ligne, periode, compo, numero, remarque))

    # --- 2. une ligne par quartier ----------------------------------------
    sortie, vocab = [], {}
    for ligne, periode, compo, numero, remarque in lignes:
        # la ligne 1914-1919 est un renvoi, pas une donnée
        if numero in (None, "-") and not isinstance(numero, (int, float, datetime.datetime)):
            sortie.append(dict(periode=periode, arrondissement="", circo="",
                               circo_label="", quartier="", statut="renvoi",
                               remarque=str(compo or "")))
            continue

        arr, circo = lire_numero(numero, periode in PAR_ARRONDISSEMENT)
        if arr and circo:
            label = f"{circo}/{arr}"
        elif arr:
            label = str(arr)
        else:
            label = str(circo)

        statut = "periode_inconnue" if periode == "?-?" else "ok"

        for q in quartiers(compo):
            vocab.setdefault(cle(q), {})[q] = vocab.setdefault(cle(q), {}).get(q, 0) + 1
            sortie.append(dict(
                periode=periode,
                arrondissement=arr or "",
                circo=circo or "",
                circo_label=label,
                quartier=q,
                statut=statut,
                remarque=str(remarque or ""),
            ))

    OUT.parent.mkdir(exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["periode", "arrondissement", "circo",
                                          "circo_label", "quartier", "statut",
                                          "remarque"])
        w.writeheader()
        w.writerows(sortie)

    # --- 3. le vocabulaire, pour préparer la jointure ---------------------
    with VOCAB.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["cle", "orthographes", "n_variantes", "occurrences"])
        for k in sorted(vocab):
            formes = vocab[k]
            w.writerow([k, " | ".join(sorted(formes)), len(formes), sum(formes.values())])

    # --- 4. ce qu'on a produit --------------------------------------------
    divisions = {}
    for r in sortie:
        if r["statut"] == "renvoi":
            continue
        divisions.setdefault(r["periode"], set()).add(r["circo_label"])

    print(f"{OUT.name} : {len(sortie)} lignes")
    print(f"{VOCAB.name} : {len(vocab)} quartiers distincts après rapprochement")
    multi = sum(1 for v in vocab.values() if len(v) > 1)
    print(f"           dont {multi} avec plusieurs orthographes")
    print()
    print(f"{'division':14s} {'circos':>7s}")
    for p in sorted(divisions, key=lambda s: (s == "?-?", s)):
        print(f"{p:14s} {len(divisions[p]):7d}")


if __name__ == "__main__":
    main()

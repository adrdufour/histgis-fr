#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""banc_seine.py — éprouver la transcription des circonscriptions de la Seine
AVANT de la poser en base.

    python3 circo/banc_seine.py

Ce que le banc mesure
---------------------
Une division électorale doit PARTITIONNER le département : chacune des
80 communes de la Seine hors Paris dans une circonscription et une seule.
Le banc résout les jetons de `circo/seine_circo.csv` — les uns sont des
communes, les autres des cantons — et compte les absentes et les doubles.

D'où vient l'entrée, et pourquoi ce n'est pas circulaire
--------------------------------------------------------
Deux entrées, d'origines étrangères l'une à l'autre :

  * la TRANSCRIPTION (`seine_circo.csv`) vient de deux textes — la loi du
    5 octobre 1946 et l'ordonnance du 13 octobre 1958 ;
  * le RÉFÉRENTIEL (l'export web de `cartes/web/donnees/dep/75`) vient de la
    base, c'est-à-dire de TRF-GIS pour les 80 communes et du COG de 1954 pour
    les 22 cantons.

Aucune ligne de la transcription n'a servi à fabriquer le référentiel.

    ATTENTION — une fois `88_seine_circo_1945_1967.sql` joué et l'export
    refait, ce banc lira ses propres rattachements dans les fichiers `x_*`.
    Il ne lit QUE `communes.json` et la planche cantonale de 1954 pour cette
    raison ; ne jamais l'élargir aux planches `x_*` du 75.

Le correctif de 1954
--------------------
Quatre communes manquent à la planche cantonale de 1954 — l'extraction OCR les
a laissées tomber. `cog1954/correctif_seine_1954.csv` les rend, code lu sur le
fascicule. Le banc tourne DEUX FOIS, sans puis avec, pour que le prix du
correctif se mesure au lieu de se supposer.

    PÉRIMÉ DEPUIS LE 6 SEPTEMBRE 2026, AU SOIR. `87` est joué : la planche
    cantonale de l'export porte désormais les quatre communes, et la passe
    « sans le correctif » rend 80/80 comme l'autre. Elle ne mesure plus rien —
    son entrée est devenue la sortie de ce qu'elle éprouvait. Le chiffre de
    76/80 est celui du 6 septembre au matin, il est au journal, et seul un
    export antérieur au jeu de `87` pourrait le reproduire.
"""
import csv
import json
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
EXPORT = os.path.join(RACINE, "cartes", "web", "donnees", "dep", "75")


def norm(s):
    s = unicodedata.normalize("NFD", s.lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    s = re.sub(r"^(le|la|les|l) ", "", s)
    return s.strip()


# Les seules équivalences de graphie que les deux textes imposent. Chacune est
# un choix, donc elle est écrite ici et non enfouie dans une comparaison floue.
ALIAS = {
    "chatillon sous bagneux": "chatillon",          # ord. 1958, commune
    "montreuil sous bois": "montreuil",             # loi 1946, canton
    "charenton le pont": "charenton",               # loi 1946, canton en base
}
# `Asnières` ne figure PAS ici : la loi de 1946 nomme le canton « Asnières » et
# la base aussi, l'ordonnance de 1958 nomme la commune « Asnières-sur-Seine » et
# la base aussi. Un alias les aurait confondus, et il a d'abord été écrit —
# le banc l'a rendu en cassant la résolution du canton.


def charge_referentiel():
    """Les 80 communes de la Seine hors Paris, et les 22 cantons de 1954."""
    com = json.load(open(os.path.join(EXPORT, "communes.json"),
                        encoding="utf-8"))["communes"]
    atomes = {k: v for k, v in com.items()
              if not k.startswith(("PQ", "PV"))
              and not (v.get("i") or "").startswith("75")}

    planche = None
    idx = json.load(open(os.path.join(EXPORT, "index.json"), encoding="utf-8"))
    cle = idx["annees"].get("1954", {}).get("c")
    if cle:
        planche = json.load(open(os.path.join(EXPORT, "c_%s.json" % cle),
                                 encoding="utf-8"))
    if planche is None or planche.get("niveau") != "canton":
        sys.exit("planche cantonale de 1954 introuvable dans l'export")

    noms = {u["id"]: u["nom"] for u in planche["unites"]}
    canton = defaultdict(list)
    for atom, unit in planche["rattachement"].items():
        canton[norm(noms[unit])].append(atom)
    return atomes, canton


def applique_correctif(atomes, canton):
    """Rend les communes que l'OCR de 1954 a laissées tomber."""
    chemin = os.path.join(RACINE, "cog1954", "correctif_seine_1954.csv")
    if not os.path.exists(chemin):
        return 0
    par_insee = {(v.get("i") or ""): k for k, v in atomes.items()}
    n = 0
    for ligne in csv.DictReader(open(chemin, encoding="utf-8")):
        atom = par_insee.get(ligne["insee"])
        if atom is None:
            sys.exit("correctif : insee %s hors des 80" % ligne["insee"])
        cle = norm(ligne["canton_nom"])
        if cle not in canton:
            sys.exit("correctif : canton %r inconnu de 1954" % ligne["canton_nom"])
        if atom not in canton[cle]:
            canton[cle].append(atom)
            n += 1
    return n


def resout(atomes, canton, avec_correctif):
    par_nom = {}
    for k, v in atomes.items():
        par_nom[norm(v["n"])] = k

    lignes = list(csv.DictReader(
        open(os.path.join(ICI, "seine_circo.csv"), encoding="utf-8")))
    divisions = defaultdict(lambda: defaultdict(list))
    inconnus = []
    for l in lignes:
        cle = ALIAS.get(norm(l["jeton"]), norm(l["jeton"]))
        if l["type"] == "canton":
            if cle not in canton:
                inconnus.append((l["division"], l["circo"], "canton", l["jeton"]))
                continue
            cible = canton[cle]
        else:
            if cle not in par_nom:
                inconnus.append((l["division"], l["circo"], "commune", l["jeton"]))
                continue
            cible = [par_nom[cle]]
        divisions[l["division"]][int(l["circo"])].extend(cible)
    return divisions, inconnus


def rapport(atomes, divisions, inconnus, titre):
    print("\n=== %s ===" % titre)
    if inconnus:
        print("  jetons non résolus :")
        for x in inconnus:
            print("    ", x)
    for div in sorted(divisions):
        vu = Counter()
        for circo, atoms in divisions[div].items():
            for a in atoms:
                vu[a] += 1
        absentes = sorted(atomes[k]["n"] for k in atomes if k not in vu)
        doubles = sorted(atomes[k]["n"] for k, c in vu.items() if c > 1)
        etat = "OK" if not absentes and not doubles else "DEFAUT"
        print("  %-10s  %2d circos  %2d/%d communes  absentes %-2d  doubles %-2d  %s"
              % (div, len(divisions[div]), len(vu), len(atomes),
                 len(absentes), len(doubles), etat))
        if absentes:
            print("      absentes :", ", ".join(absentes))
        if doubles:
            print("      doubles  :", ", ".join(doubles))


def main():
    atomes, canton = charge_referentiel()
    print("référentiel : %d communes de la Seine hors Paris, %d cantons en 1954"
          % (len(atomes), len(canton)))

    div, inc = resout(atomes, canton, False)
    rapport(atomes, div, inc, "sans le correctif de 1954")

    n = applique_correctif(atomes, canton)
    print("\ncorrectif de 1954 : %d rattachement(s) cantonaux rendus" % n)
    div, inc = resout(atomes, canton, True)
    rapport(atomes, div, inc, "avec le correctif de 1954")

    # Contrôle croisé : les cantons cités par 1958 sont-ils un sous-ensemble de
    # ceux cités par 1946 ? Deux textes, douze ans d'écart, aucun contact.
    lignes = list(csv.DictReader(
        open(os.path.join(ICI, "seine_circo.csv"), encoding="utf-8")))
    c46 = {ALIAS.get(norm(l["jeton"]), norm(l["jeton"])) for l in lignes
           if l["division"] == "1945-1958" and l["type"] == "canton"}
    c58 = {ALIAS.get(norm(l["jeton"]), norm(l["jeton"])) for l in lignes
           if l["division"] == "1958-1968" and l["type"] == "canton"}
    print("\ncantons cités par 1946 : %d ; par 1958 : %d ; en base à 1954 : %d"
          % (len(c46), len(c58), len(canton)))
    print("  1946 == base 1954 ......", "OUI" if c46 == set(canton) else
          "NON — écarts %s" % (c46 ^ set(canton)))
    print("  1958 inclus dans 1946 ..", "OUI" if c58 <= c46 else
          "NON — %s" % (c58 - c46))


if __name__ == "__main__":
    main()

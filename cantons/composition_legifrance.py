#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
composition_legifrance.py — 1990-1999, sans PDF ni OCR

    python3 cantons/composition_legifrance.py

Lit `cantons/legifrance_1990_1999.txt` — l'extraction du texte intégral que
Légifrance conserve à partir de 1991 — et produit :

  `cantons/composition_legifrance.csv`  une ligne par (décret, canton, commune)
  `cantons/transferts_legifrance.csv`   les mouvements isolés de commune
  `cantons/composition_legifrance_non_appariees.csv`

Pourquoi un fichier d'entrée figé
---------------------------------
Les pages `/jorf/id/…` de Légifrance sont rendues côté client : un `fetch`
sans session ne rend qu'une coquille. L'extraction se fait donc dans le
navigateur, une fois la session établie, et son résultat est déposé ici. Le
fichier est la trace reproductible ; le script ne refait que l'appariement des
noms, qui est la partie qu'on veut pouvoir rejouer et discuter.

Ce que les 83 décrets de 1990-1999 contiennent réellement
---------------------------------------------------------
Ils ne sont pas tous de même nature, et c'est le résultat principal :

  19  donnent une composition cantonale (les créations-modifications)
   4  déplacent une commune entière d'un canton à un autre
  40  transfèrent des **parcelles entre deux communes** — l'opération traverse
      une limite cantonale, d'où le mot « canton » dans le titre, mais aucune
      commune ne change de canton. Pour la couche cantonale, c'est un
      non-événement : cela concerne la géométrie, pas l'appartenance.
  10  autres
  10  n'ont pas de texte du tout sur Légifrance — titre seul, PDF requis, et
      ce sont tous des décrets **non numérotés** de 1990 et 1992.

Les quatre décrets du deuxième groupe valent d'être signalés : ce sont
exactement les « transferts isolés de commune » dont `mouvements_cantonaux.csv`
dit que l'annexe VII **ne les recense jamais**. Ici ils sont datés au jour près,
avec canton d'origine et canton d'arrivée.
"""

import collections
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from composition_jo import (apparie, cle, noms_par_departement,  # noqa: E402
                            communes_disparues)

RACINE = Path(__file__).resolve().parent.parent
ENTREE = RACINE / "cantons" / "legifrance_1990_1999.txt"
DECRETS = RACINE / "cantons" / "decrets_cantonaux.csv"
SORTIE = RACINE / "cantons" / "composition_legifrance.csv"
TRANSF = RACINE / "cantons" / "transferts_legifrance.csv"
RESTE = RACINE / "cantons" / "composition_legifrance_non_appariees.csv"


def main():
    index = {r["legifrance_id"][-6:].lstrip("0"): r
             for r in csv.DictReader(DECRETS.open(encoding="utf-8"))}
    vivantes = noms_par_departement()
    disparues = communes_disparues()

    lignes, transferts, rejets = [], [], []
    for l in ENTREE.open(encoding="utf-8"):
        l = l.rstrip("\n")
        if not l or l.startswith("#"):
            continue
        p = l.split("|")
        d = index.get(p[1].lstrip("0"))
        if d is None:
            rejets.append(dict(id=p[1], motif="décret absent du registre", detail=l[:120]))
            continue
        dep = d["dep_code"]
        base = dict(decret=d["decret"].replace("n° ", "") or "[%s]" % p[1],
                    date=d["date_signature"], dep=dep,
                    legifrance_url=d["legifrance_url"])

        if p[0] == "T":
            insee, ref, q = apparie(p[2], dep, vivantes, disparues)
            transferts.append(dict(base, commune=p[2], insee=insee, nom_ref=ref,
                                   appariement=q, canton_source=p[3],
                                   canton_destination=p[4]))
            continue

        canton = p[2]
        noms = [x for x in (p[3].split(";") if len(p) > 3 and p[3] else []) if x]
        if not noms:
            lignes.append(dict(base, canton=canton, nom_texte="", insee="",
                               nom_ref="", dep_insee="",
                               appariement="fraction seule", attribution="titre"))
            continue
        for n in noms:
            insee, ref, q = apparie(n, dep, vivantes, disparues)
            lignes.append(dict(base, canton=canton, nom_texte=n, insee=insee,
                               nom_ref=ref,
                               dep_insee=(insee[:3] if insee[:2] in ("97", "98")
                                          else insee[:2]) if insee else "",
                               appariement=q, attribution="titre"))
            if q in ("aucun", "ambigu hors departement"):
                rejets.append(dict(id=p[1], motif="nom non apparié (%s)" % dep,
                                   detail="%s / %s" % (canton, n)))

    # même ordre de colonnes que composition_jo.csv, pour que le contrôle
    # indépendant puisse juger les deux fichiers sans être modifié
    # ORDRE STRICTEMENT IDENTIQUE à composition_jo.csv. `\copy` de psql apparie
    # les colonnes par POSITION et non par nom, même avec HEADER true : deux
    # fichiers aux mêmes colonnes dans un ordre différent se chargent en
    # silence dans les mauvaises cases. C'est le piège déjà noté par `58`.
    cols = ["jo", "decret", "date", "dep", "canton", "nom_texte", "insee",
            "nom_ref", "dep_insee", "appariement", "attribution", "legifrance_url"]
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in sorted(lignes, key=lambda r: (r["date"], r["dep"], r["canton"], r["nom_texte"])):
            r["jo"] = "legifrance"
            w.writerow(r)
    if transferts:
        tc = ["decret", "date", "dep", "commune", "insee", "nom_ref", "appariement",
              "canton_source", "canton_destination", "legifrance_url"]
        with TRANSF.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=tc, extrasaction="ignore")
            w.writeheader()
            w.writerows(sorted(transferts, key=lambda r: (r["date"], r["dep"])))
    if rejets:
        with RESTE.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rejets[0]))
            w.writeheader()
            w.writerows(rejets)

    q = collections.Counter(r["appariement"] for r in lignes)
    print("lignes (décret × canton × commune) :", len(lignes))
    print("décrets :", len({r["decret"] for r in lignes}))
    print("cantons :", len({(r["dep"], r["canton"]) for r in lignes}))
    print("\nqualité d'appariement :")
    for k, v in q.most_common():
        print("   %-24s %4d  %5.1f %%" % (k, v, 100 * v / len(lignes)))
    print("\ntransferts isolés de commune :", len(transferts))
    for t in sorted(transferts, key=lambda r: r["date"]):
        print("   %s  %s  %-26s %-22s → %s" % (
            t["date"], t["dep"], t["commune"], t["canton_source"],
            t["canton_destination"]))
    print("\nrejets :", len(rejets))
    print("\npar année :")
    for a, n in sorted(collections.Counter(r["date"][:4] for r in lignes).items()):
        print("   %s  %4d lignes  %3d cantons" % (
            a, n, len({(r["dep"], r["canton"]) for r in lignes if r["date"][:4] == a})))


if __name__ == "__main__":
    main()

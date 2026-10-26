#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
paris_circo.py — poser les circonscriptions de Paris sur la trame des quartiers

    python3 circo/paris_circo.py

Ce qu'il fait
-------------
Il rattache `circo/paris_decoupage.csv` — la composition par quartier de dix-
neuf divisions électorales, transcrite de l'atlas Gaudillère — à la trame
géométrique des 80 quartiers posée par `paris_quartiers.py`. Résultat : une
table `paris_circo`, une circonscription par période avec sa géométrie.

C'est la dernière pièce du chantier parisien. Paris avait été déclaré
irréductible faute de trame ; la trame existe depuis `paris_quartiers.py`, et
ses 80 noms se sont retrouvés un à un dans le vocabulaire de la transcription.

Pourquoi Paris compte plus que sa taille
----------------------------------------
Le découpage **1958-1986** est bloqué nationalement par le trou cantonal
1941-1998 : il se définit par cantons, et la nomenclature cantonale de ces
années manque. Mais à Paris il se définit par QUARTIERS. C'est donc le premier
morceau de 1958 posable, sans rien attendre.

Ce que le script vérifie
------------------------
1. Chaque nom de quartier cité se résout en un numéro de 1 à 80. Les périodes
   antérieures à 1860 emploient l'AUTRE système de quartiers, celui des douze
   arrondissements : leurs noms ne se résolvent pas, et c'est attendu — ce
   n'est pas un échec mais une frontière.
2. Chaque division postérieure à 1860 partitionne la ville : 80 quartiers,
   cités une fois. Un quartier cité deux fois est partagé entre deux
   circonscriptions — l'atlas nomme alors les rues, et c'est le chantier
   suivant.
3. La géométrie de chaque circonscription est l'union de ses quartiers ; leur
   union par période doit rendre Paris.

Une inférence, déclarée comme telle
-----------------------------------
La période 1914-1919 ne porte qu'une ligne, de statut `renvoi` : « même
découpage et mêmes appellations que de 1902 à 1910 ». Le script la matérialise
en recopiant 1902-1910, et marque ces lignes `source = 'renvoi'`. Elles ne
sont pas transcrites, elles sont déduites d'une note du livre.
"""

import collections
import csv
import os
import sys
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
DECOUPAGE = RACINE / "circo" / "paris_decoupage.csv"
SORTIE = RACINE / "circo" / "paris_circo_controle.csv"

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(RACINE))
from outils.noms import cle                            # noqa: E402
from paris_quartiers import appariement, connexion     # noqa: E402

# La trame des 80 ne vaut qu'à partir de 1860 : le bois de Boulogne n'entre
# dans Paris qu'en 1852, celui de Vincennes en 1860, et l'avant-1860 relève
# des douze arrondissements et de leurs quarante-huit quartiers.
#
# LE PIÈGE DES HOMONYMES. Ce filtre est une barrière, pas une commodité. Sur
# les cinq divisions antérieures à 1860, SEIZE noms se résolvent quand même —
# Arsenal, Notre-Dame, Arcis, Montmartre… — parce que les deux systèmes
# partagent des noms. Ils ne partagent pas les territoires : le quartier de
# l'Arsenal de 1815 n'est pas le quartier 15 de 1876. Sans la barrière de
# date, le script poserait seize rattachements faux, et ils seraient
# invisibles — géométrie valide, noms plausibles, recette de couverture
# muette puisqu'elle ne compte que ce qu'on lui donne.
#
# C'est la même leçon que « le roule » contre « roule » : un nom identique
# dans deux nomenclatures est un homonyme jusqu'à preuve du contraire.
PIVOT = 1860


def annee(periode):
    """Année de début d'une étiquette de période. None si elle n'en a pas."""
    tete = (periode or "").split("-")[0].strip()
    return int(tete) if tete.isdigit() else None


def main():
    lignes = list(csv.DictReader(DECOUPAGE.open(encoding="utf-8")))

    # --- 1. le renvoi de 1914-1919 -------------------------------------
    renvoi = [l for l in lignes if l["statut"] == "renvoi"]
    if renvoi:
        modele = [l for l in lignes if l["periode"] == "1902-1910"]
        for l in modele:
            c = dict(l, periode="1914-1919", statut="renvoi")
            lignes.append(c)
        lignes = [l for l in lignes
                  if not (l["statut"] == "renvoi" and not l["quartier"])]
        print(f"1914-1919 : {len(modele)} lignes déduites de 1902-1910 "
              f"(renvoi du livre, non transcrites)")

    with connexion() as cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        cur.execute("SELECT quartier, nom FROM paris_quartier ORDER BY 1")
        quartiers = cur.fetchall()
        if not quartiers:
            sys.exit("Table paris_quartier vide. Lancer d'abord :\n"
                     "    python3 circo/paris_quartiers.py")

        # --- 2. index clé de l'atlas -> numéro de quartier --------------
        # On réutilise l'appariement de `paris_quartiers.py`, mais à
        # l'envers : là il validait la trame contre le vocabulaire, ici il
        # sert à résoudre. Une seule fonction, donc aucune divergence
        # possible entre le contrôle et l'usage.
        vocab = {cle(l["quartier"]) for l in lignes if l["quartier"]}
        index = {}
        for q, nom in quartiers:
            k, _ = appariement(nom, vocab)
            if k:
                index[k] = q
            index.setdefault(cle(nom), q)

        # --- 3. résolution -----------------------------------------------
        inconnus = collections.Counter()
        for l in lignes:
            l["q"] = index.get(cle(l["quartier"])) if l["quartier"] else None
            if l["quartier"] and l["q"] is None:
                inconnus[cle(l["quartier"])] += 1

        # --- 4. partition, période par période ---------------------------
        print(f"\n{'période':12s} {'circos':>7s} {'quartiers':>10s} "
              f"{'absents':>8s} {'partagés':>9s} {'hors trame':>11s}")
        controle, posables = [], []
        for p in sorted({l["periode"] for l in lignes}, key=lambda x: (
                annee(x) is None, annee(x) or 0, x)):
            lot = [l for l in lignes if l["periode"] == p]
            circos = {l["circo_label"] for l in lot if l["circo_label"]}
            vus = collections.Counter(l["q"] for l in lot if l["q"])
            hors = sum(1 for l in lot if l["quartier"] and not l["q"])
            absents = 80 - len(vus)
            partages = sum(1 for v in vus.values() if v > 1)
            a = annee(p)
            ancien = a is not None and a < PIVOT
            print(f"{p:12s} {len(circos):7d} {len(vus):10d} "
                  f"{absents:8d} {partages:9d} {hors:11d}"
                  + ("   (avant 1860, autre système)" if ancien else ""))
            controle.append(dict(periode=p, circos=len(circos),
                                 quartiers=len(vus), absents=absents,
                                 partages=partages, hors_trame=hors,
                                 avant_1860=ancien))
            # Une division n'est posée que si elle est POSTÉRIEURE à 1860,
            # complète et sans nom hors trame. Les trois conditions, pas deux.
            if not ancien and absents == 0 and hors == 0:
                posables.append(p)
            elif ancien:
                pass          # cf. PIÈGE DES HOMONYMES en tête de fichier

        if inconnus:
            print(f"\nnoms non résolus ({len(inconnus)} clés distinctes) — "
                  f"attendus pour l'avant-1860 :")
            for k, n in inconnus.most_common(12):
                print(f"    {k:28s} {n} occ.")

        # --- 5. la couche ------------------------------------------------
        cur.execute("DROP TABLE IF EXISTS paris_circo")
        cur.execute("CREATE TABLE paris_circo ("
                    "  periode text, circo text, quartiers smallint,"
                    # La LISTE des quartiers, pas seulement leur nombre : sans
                    # elle, toute reprise — carte, contrôle, recoupement —
                    # devrait refaire la résolution des noms et pourrait la
                    # refaire autrement. La couche doit porter ce qui l'a
                    # constituée.
                    "  q_list smallint[],"
                    "  source text,"
                    "  geom geometry(MultiPolygon, 2154),"
                    "  PRIMARY KEY (periode, circo))")
        pose = 0
        for p in posables:
            lot = [l for l in lignes if l["periode"] == p and l["q"]]
            src = "renvoi" if all(l["statut"] == "renvoi" for l in lot) \
                  else "atlas"
            par = collections.defaultdict(set)
            for l in lot:
                par[l["circo_label"]].add(l["q"])
            for c, qs in par.items():
                cur.execute(
                    "INSERT INTO paris_circo (periode, circo, quartiers,"
                    " q_list, source, geom) SELECT %s, %s, %s, %s, %s,"
                    " ST_Multi(ST_UnaryUnion(ST_Collect(geom)))"
                    " FROM paris_quartier WHERE quartier = ANY(%s)",
                    (p, c, len(qs), sorted(qs), src, sorted(qs)))
                pose += 1

        cur.execute("SELECT periode, count(*), sum(quartiers),"
                    " round((ST_Area(ST_Union(geom))/1e6)::numeric, 2)"
                    " FROM paris_circo GROUP BY 1 ORDER BY 1")
        bilan = cur.fetchall()

    print(f"\nparis_circo : {pose} circonscriptions posées, "
          f"{len(posables)} divisions")
    print(f"\n{'période':12s} {'circos':>7s} {'quartiers':>10s} {'km²':>8s}")
    for p, n, sq, km in bilan:
        print(f"{p:12s} {n:7d} {sq:10d} {km:8.2f}")

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["periode", "circos", "quartiers",
                                          "absents", "partages", "hors_trame",
                                          "avant_1860"])
        w.writeheader()
        w.writerows(controle)
    print(f"\nContrôle : {SORTIE}")


if __name__ == "__main__":
    main()

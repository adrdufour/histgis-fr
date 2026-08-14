#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_contiguite.py — les transferts de 1954 tiennent-ils géographiquement ?

    python3 cog1954/test_contiguite.py

`transferts_1954.py` sort 311 communes qui n'ont pas le même canton en 1940 et
en 1954. Ce sont des CANDIDATS, et rien de plus : ni l'annexe VII ni les
effectifs ne les confirment.

Le seul arbitre qui ne dépende ni des noms ni des codes est la **géométrie**.

Le principe
-----------
Un canton est un territoire **d'un seul tenant**. Une commune qui le rejoint
doit donc toucher son nouveau canton. Si elle en est séparée par d'autres
communes, le transfert est impossible — c'est une faute de lecture, quelle que
soit la vraisemblance du nom et du code.

C'est le même arbitrage que partout ailleurs dans ce projet : quand les codes
et les noms se contredisent, on regarde les polygones. Ils ne portent aucune
convention d'écriture, aucune abréviation, aucune coquille d'OCR.

Ce que le test peut dire, et ce qu'il ne peut pas
-------------------------------------------------
* **Non contiguë -> le transfert est FAUX.** C'est une réfutation, et elle est
  ferme.
* **Contiguë -> le transfert est POSSIBLE.** Ce n'est pas une confirmation :
  deux cantons voisins partagent une longue frontière, et une commune mal lue
  a de bonnes chances d'y être quand même adjacente.

Le test réfute, il ne prouve pas. C'est déjà beaucoup : si les 311 candidats
étaient du bruit, une bonne part devrait tomber.

Le canton de destination est reconstitué à partir de sa composition de **1940**
et privé des communes candidates, pour ne pas lui prêter d'avance le territoire
qu'on cherche à lui attribuer — ce serait raisonner en rond.

Dépendances : shapely, pyshp (le shapefile GEOFLA ED111 du dépôt).
"""

import collections
import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
TRANSFERTS = RACINE / "cog1954" / "transferts_1954.csv"
SORTIE = RACINE / "cog1954" / "transferts_contiguite.csv"
GEOFLA = (RACINE / "sources" / "geofla" / "repro" / "source_data" / "GEOFLA"
          / "GEOFLA_1-1_SHP_LAMB93_FR-ED111" / "GEOFLA"
          / "1_DONNEES_LIVRAISON_2013-12-00225"
          / "GEOFLA_1-1_SHP_LAMB93_FR-ED111" / "COMMUNES" / "COMMUNE")

# Tolérance de contact, en mètres. GEOFLA est généralisé : deux communes
# voisines peuvent ne pas se toucher exactement au pixel près. 150 m est
# large devant l'imprécision et étroit devant la taille d'une commune.
TOLERANCE = 150


def main():
    try:
        import shapefile
        from shapely.geometry import shape
        from shapely.ops import unary_union
    except ImportError:
        sys.exit("pip install shapely pyshp")

    if not TRANSFERTS.exists():
        sys.exit(f"{TRANSFERTS} absent. Lancer d'abord transferts_1954.py")

    tr = [l for l in csv.DictReader(TRANSFERTS.open(encoding="utf-8"))
          if l["verdict"] == "transfert"]
    print(f"{len(tr)} transferts candidats")

    # --- géométrie des communes ----------------------------------------
    r = shapefile.Reader(str(GEOFLA), encoding="latin-1")
    idx = {x[0]: k for k, x in enumerate(r.fields[1:])}
    geom = {}
    for sh, rec in zip(r.shapes(), r.records()):
        g = shape(sh.__geo_interface__).buffer(0)
        if not g.is_empty:
            geom[rec[idx["INSEE_COM"]]] = g
    print(f"{len(geom)} communes GEOFLA chargées")

    # --- composition de 1940, par canton --------------------------------
    membres = collections.defaultdict(set)
    for l in csv.DictReader((RACINE / "build" / "membership_canton.csv")
                            .open(encoding="utf-8")):
        if l["valid_from"] <= "1940-06-01" < l["valid_to"] and l["insee"]:
            membres[l["unit_id"]].add(l["insee"])

    candidats = {l["insee"] for l in tr}
    cache = {}

    def noyau(unit):
        """Le canton de 1940, privé de toutes les communes candidates."""
        if unit not in cache:
            gs = [geom[i] for i in membres.get(unit, ())
                  if i in geom and i not in candidats]
            cache[unit] = unary_union(gs) if gs else None
        return cache[unit]

    sorties, n = [], collections.Counter()
    for l in tr:
        g = geom.get(l["insee"])
        cible = noyau(l["canton_1954"])
        depart = noyau(l["canton_1940"])
        if g is None or cible is None:
            verdict, d = "indécidable", ""
        else:
            d = g.distance(cible)
            verdict = "contigu" if d <= TOLERANCE else "SÉPARÉ"
        dd = g.distance(depart) if (g is not None and depart is not None) else None
        n[verdict] += 1
        sorties.append(dict(l, contiguite=verdict,
                            distance_m=round(d) if d != "" else "",
                            distance_depart_m=round(dd) if dd is not None else ""))

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(sorties[0]))
        w.writeheader()
        w.writerows(sorted(sorties, key=lambda x: (x["contiguite"] != "SÉPARÉ",
                                                   -int(x["compagnons"] or 0))))

    print(f"\n{'verdict':14s} {'n':>5s}")
    for v in ("contigu", "SÉPARÉ", "indécidable"):
        print(f"  {v:14s} {n[v]:5d}")

    sep = [s for s in sorties if s["contiguite"] == "SÉPARÉ"]
    if sep:
        print(f"\n{len(sep)} transferts RÉFUTÉS — la commune ne touche pas son "
              f"nouveau canton :")
        for s in sorted(sep, key=lambda x: -x["distance_m"])[:15]:
            print(f"   {s['dep']} {s['commune'][:24]:24s} "
                  f"{s['nom_1940'][:16]:16s} -> {s['nom_1954'][:16]:16s} "
                  f"{s['distance_m']:6d} m")

    print(f"\n{SORTIE}")
    print("\nRappel : « contigu » ne confirme rien. Deux cantons voisins "
          "partagent une longue frontière, et une commune mal lue a de bonnes "
          "chances d'y être adjacente. Le test réfute, il ne prouve pas.")


if __name__ == "__main__":
    main()

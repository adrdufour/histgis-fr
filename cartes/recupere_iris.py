#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
recupere_iris.py — la trame IRIS des 119 villes à découper

    python3 cartes/recupere_iris.py            # télécharge et écrit le GeoJSON
    python3 cartes/recupere_iris.py --charger  # + charge dans PostGIS

Produit `cartes/iris_villes.geojson` (Lambert 93) et, avec `--charger`, la
table `histgis.iris_ville`.

Pourquoi
--------
119 communes de la base relèvent de plusieurs cantons à la fois, pour **214
coupes internes à tracer** — dont 81 villes qui n'en demandent qu'une. Ces
lignes n'existent nulle part : c'est le dernier gros chantier manuel du projet.

CONTOURS-IRIS (coédition INSEE-IGN, **Licence Ouverte 2.0**) fournit une trame
d'accrochage. Récupération faite le 14 août 2026 : **4 219 IRIS, les 119 villes
servies**.

| | villes couvertes | coupes pourvues d'une trame |
|---|---|---|
| ADMIN EXPRESS v4 (cantons 2025) | 67 % | 26 % |
| CONTOURS-IRIS | **100 %** | **211 / 214 — 98,6 %** |

La densité est d'un ordre de grandeur au-dessus du besoin : Nantes a 97 IRIS
pour 6 coupes, Dinan 7 pour une seule, Marseille 393 pour 11.

Le 88 % annoncé avant récupération était une estimation tirée des seuils de
population. La récupération réelle fait mieux : le seuil des 5 000 habitants
est appliqué plus souplement que la règle ne le dit.

Ce que la trame ne prouve pas
-----------------------------
Que les limites cantonales de 1870 suivent des limites d'IRIS. Les IRIS sont
calés sur la voirie, les îlots et les limites communales — **sauf à Paris**, où
l'INSEE les cale explicitement sur les limites de quartier, ce qui a permis de
reconstruire les 80 quartiers par simple union (`circo/paris_quartiers.py`).

Ailleurs, c'est un support : des lignes propres, topologiquement valides,
calées sur des rues réelles, où l'on choisit au lieu de dessiner. Le taux de
reprise réel se mesurera ville par ville dans QGIS.

Trois villes restent sans appui
-------------------------------
Les IRIS n'existent qu'au-dessus de 5 000 à 10 000 habitants. Trois villes
n'ont qu'un IRIS — c'est-à-dire aucune ligne interne — pour une coupe chacune :
**Confolens (16106), Tartas (40313), Le Quesnoy (59481)**. Les deux premières
étaient prévues par le seuil de population ; **Le Quesnoy ne l'était pas** et
n'est apparu qu'à la récupération. Le critère qui décide n'est pas la
population mais le nombre d'IRIS effectivement publiés : il fallait le
mesurer, pas le déduire.

Deux villes sont en trame juste suffisante — Saint-Flour (15187) et
Avesnes-sur-Helpe (59036), 2 IRIS pour 1 coupe : une seule ligne interne
offerte, à prendre ou à laisser.

Condition nécessaire vérifiée sur tout le lot : `IRIS >= coupes + 1` tient
pour 116 villes sur 119, soit **211 coupes sur 214**. C'est une condition
nécessaire, pas une garantie que la ligne de 1870 soit parmi celles offertes.

Licence : Licence Ouverte 2.0, compatible avec la contrainte du projet.
Source : https://data.geopf.fr/wfs/ows — couche STATISTICALUNITS.IRIS
"""

import argparse
import collections
import csv
import json
import os
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "cartes" / "iris_villes.geojson"
RAPPORT = RACINE / "cartes" / "iris_villes.csv"

WFS = "https://data.geopf.fr/wfs/ows"
COUCHE = "STATISTICALUNITS.IRIS:contours_iris"

# Un en-tête de navigateur : plusieurs services publics renvoient une réponse
# vide aux requêtes sans user-agent. C'est déjà le cas de `fetch_inspect` dans
# ce dépôt.
ENTETES = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) "
                         "AppleWebKit/537.36 (KHTML, like Gecko) "
                         "Chrome/126.0 Safari/537.36"}

# Par paquets de 20 codes : au-delà, l'URL devient assez longue pour que
# certains intermédiaires la refusent, et une requête qui échoue à mi-parcours
# coûte plus cher que deux requêtes qui passent.
PAQUET = 20

# Marseille, Lyon et Paris ne sont PAS codées par leur code de commune dans
# CONTOURS-IRIS : l'INSEE y code par arrondissement municipal. Interroger
# « 13055 » rend zéro IRIS pour une ville qui en compte 393 — un zéro qui ne
# ressemble pas à une erreur, puisque zéro est une réponse plausible pour une
# petite commune. C'est le même piège que les arrondissements de GEOFLA, qui
# avait déjà fait ressortir Marseille comme « non divisée ».
ARRONDISSEMENTS = {
    "13055": [f"132{i:02d}" for i in range(1, 17)],   # Marseille, 16 arr.
    "69123": [f"693{i:02d}" for i in range(81, 90)],  # Lyon, 9 arr.
    "75056": [f"751{i:02d}" for i in range(1, 21)],   # Paris, 20 arr.
}


def villes():
    """Les communes portant des atomes-fraction, et leur nombre de coupes.

    Le critère est le fractionnement — `atom_id` de la forme `cassini#canton` —
    et non la cohabitation sur un même code GEOFLA. Grouper par `insee` sans ce
    filtre donne 369 communes au lieu de 119 : on ramasse alors les communes
    anciennes ABSORBÉES, qui partagent un rattachement sans avoir jamais été
    coupées entre cantons.
    """
    f = RACINE / "build" / "atom.csv"
    c = collections.Counter(
        l["insee"] for l in csv.DictReader(f.open(encoding="utf-8"))
        if "#" in l["atom_id"] and l["insee"])
    return {i: n - 1 for i, n in c.items() if n > 1}


def noms():
    f = RACINE / "build" / "noms_geofla.csv"
    if not f.exists():
        return {}
    return {l["insee"]: l["nom"]
            for l in csv.DictReader(f.open(encoding="utf-8"))}


def interroge(codes, essais=3):
    """Un paquet de codes INSEE -> les entités IRIS, en Lambert 93."""
    filtre = "code_insee IN (" + ",".join(f"'{c}'" for c in codes) + ")"
    url = WFS + "?" + urllib.parse.urlencode({
        "SERVICE": "WFS", "VERSION": "2.0.0", "REQUEST": "GetFeature",
        "TYPENAMES": COUCHE, "OUTPUTFORMAT": "application/json",
        "SRSNAME": "EPSG:2154", "COUNT": "5000", "CQL_FILTER": filtre})
    for k in range(essais):
        try:
            req = urllib.request.Request(url, headers=ENTETES)
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read().decode("utf-8"))["features"]
        except Exception as e:
            if k == essais - 1:
                print(f"    ÉCHEC après {essais} essais : {e}")
                return []
            time.sleep(3 * (k + 1))
    return []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--charger", action="store_true",
                    help="charger dans histgis.iris_ville")
    a = ap.parse_args()

    coupes = villes()
    nom = noms()

    # On interroge par arrondissement là où il le faut, mais on RECOMPTE par
    # commune : la ville reste l'unité du chantier, l'arrondissement n'est
    # qu'une clé d'interrogation.
    vers_ville = {}
    for v in coupes:
        for c in ARRONDISSEMENTS.get(v, [v]):
            vers_ville[c] = v
    codes = sorted(vers_ville)
    print(f"{len(coupes)} villes à découper, {sum(coupes.values())} coupes")
    if any(v in ARRONDISSEMENTS for v in coupes):
        print(f"  ({len(codes)} codes interrogés : Marseille, Lyon et Paris "
              f"sont codées par arrondissement)")
    print()

    feats = []
    for i in range(0, len(codes), PAQUET):
        lot = codes[i:i + PAQUET]
        f = interroge(lot)
        feats += f
        print(f"  paquet {i//PAQUET + 1:2d}/{(len(codes)-1)//PAQUET + 1} : "
              f"{len(lot):2d} villes -> {len(f):5d} IRIS")
        time.sleep(1)          # on ne martèle pas un service public

    if not feats:
        sys.exit("Aucune entité reçue. Vérifier l'accès à data.geopf.fr.")

    SORTIE.write_text(json.dumps(
        {"type": "FeatureCollection",
         "crs": {"type": "name",
                 "properties": {"name": "urn:ogc:def:crs:EPSG::2154"}},
         "features": feats}, ensure_ascii=False), encoding="utf-8")

    # --- bilan par ville, et ce que la trame permet ---------------------
    par = collections.Counter(
        vers_ville.get(f["properties"].get("code_insee"),
                       f["properties"].get("code_insee"))
        for f in feats)
    lignes = []
    for c in sorted(coupes):
        n = par.get(c, 0)
        lignes.append(dict(
            insee=c, commune=nom.get(c, ""), coupes=coupes[c], iris=n,
            verdict=("sans trame" if n < 2 else
                     "trame étroite" if n < coupes[c] + 2 else
                     "trame confortable")))
    with RAPPORT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0]))
        w.writeheader()
        w.writerows(sorted(lignes, key=lambda x: (x["iris"], -x["coupes"])))

    v = collections.Counter(l["verdict"] for l in lignes)
    print(f"\n{len(feats)} IRIS pour {len(par)} villes")
    for k in ("trame confortable", "trame étroite", "sans trame"):
        print(f"   {k:20s} {v[k]:4d} villes")
    sans = [l for l in lignes if l["verdict"] == "sans trame"]
    if sans:
        print("\n  sans trame — à tracer sans aucun appui :")
        for l in sans:
            print(f"     {l['insee']}  {l['commune'][:24]:24s} "
                  f"{l['coupes']} coupe(s), {l['iris']} IRIS")
    print(f"\n{SORTIE}\n{RAPPORT}")

    if a.charger:
        charger(feats)


def charger(feats):
    """Pose `histgis.iris_ville`. PostGIS reprojette si besoin."""
    try:
        import psycopg2
    except ImportError:
        sys.exit("psycopg2 absent : le GeoJSON est écrit, le chargement non.")
    dsn = [os.environ["HISTGIS_DSN"]] if os.environ.get("HISTGIS_DSN") else [
        "dbname=histgis host=/var/run/postgresql", "dbname=histgis",
        "dbname=histgis host=localhost"]
    cx = None
    for d in dsn:
        try:
            cx = psycopg2.connect(d)
            break
        except psycopg2.OperationalError:
            pass
    if cx is None:
        sys.exit("Connexion impossible. Définir HISTGIS_DSN.")
    with cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        cur.execute("DROP TABLE IF EXISTS iris_ville")
        cur.execute("CREATE TABLE iris_ville ("
                    "  code_iris  char(9) PRIMARY KEY,"
                    "  code_insee char(5) NOT NULL,"
                    "  nom_commune text, nom_iris text, type_iris text,"
                    "  geom geometry(MultiPolygon, 2154) NOT NULL)")
        n = 0
        for f in feats:
            p = f.get("properties", {})
            if not p.get("code_iris") or not f.get("geometry"):
                continue
            cur.execute(
                "INSERT INTO iris_ville VALUES (%s,%s,%s,%s,%s,"
                " ST_Multi(ST_MakeValid(ST_SetSRID("
                "   ST_GeomFromGeoJSON(%s), 2154))))"
                " ON CONFLICT DO NOTHING",
                (p["code_iris"], p.get("code_insee"), p.get("nom_commune"),
                 p.get("nom_iris"), p.get("type_iris"),
                 json.dumps(f["geometry"])))
            n += 1
        cur.execute("CREATE INDEX ON iris_ville USING gist (geom)")
        cur.execute("CREATE INDEX ON iris_ville (code_insee)")
    print(f"\nhistgis.iris_ville : {n} IRIS chargés")


if __name__ == "__main__":
    main()

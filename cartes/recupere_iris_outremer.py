#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
recupere_iris_outremer.py — la trame IRIS des 28 communes d'outre-mer à découper

    python3 cartes/recupere_iris_outremer.py            # écrit le GeoJSON
    python3 cartes/recupere_iris_outremer.py --charger   # + charge dans PostGIS

Produit `cartes/iris_outremer.geojson` (**EPSG:4326**) et, avec `--charger`,
la table `histgis.iris_om`.

Le pendant d'outre-mer de `recupere_iris.py`. Trois différences, toutes
délibérées.

1. Le CRS de sortie est 4326, pas 2154
--------------------------------------
Le Lambert-93 n'est défini que pour la métropole. Reprojeter l'outre-mer en
2154 gonfle les surfaces d'un facteur mesuré le 16 août 2026 :

    971 Guadeloupe   1,28×      973 Guyane       1,63×
    972 Martinique   1,31×      974 La Réunion   3,54×
                                976 Mayotte      2,61×

La Réunion y passerait de 2 502 à 8 856 km². Ce ne sont pas des arrondis, et
tous les contrôles du projet sont surfaciques. L'outre-mer vit donc en 4326,
et les surfaces se calculent en `geography` — exactes sur l'ellipsoïde,
indépendantes de toute projection. La base métropolitaine ne bouge pas.

2. La liste des communes ne vient pas de la base
------------------------------------------------
`recupere_iris.py` déduit ses 119 villes des atomes-fraction de `build/atom.csv`.
Les atomes d'outre-mer n'existent pas encore : la liste vient de
`cartes/iris_outremer.csv`, lui-même tiré du fichier du ministère de
l'Intérieur (`circo/circo_outremer_1986_2012.csv`) et de la couche CANTON de
GEOFLA, qui s'accordent exactement sur ces 28 communes.

3. Pas de piège d'arrondissement municipal
-------------------------------------------
Marseille, Lyon et Paris sont codées par arrondissement dans CONTOURS-IRIS, et
rendent zéro IRIS interrogées par leur code de commune — un zéro plausible,
donc muet. **Aucune commune d'outre-mer n'est dans ce cas** : vérifié le
16 août, les 28 rendent des IRIS sous leur propre code. Il n'y a donc pas de
table de correspondance ici, et le script vérifie que le compte tombe juste.

Ce qui est attendu
------------------
864 IRIS outre-mer au total, dont **472 sur les 28 communes**, pour 61 coupes.
La condition nécessaire `IRIS >= coupes + 1` tient pour 28 communes sur 28 —
mieux qu'en métropole, où trois villes restaient sans appui. Le détail commune
par commune est dans `cartes/iris_outremer.csv`, écrit par le repérage et
réécrit ici avec les comptes réellement reçus.

Ce que la trame ne prouve pas
-----------------------------
Que les limites cantonales d'outre-mer suivent des limites d'IRIS. Comme en
métropole, c'est un support de tracé : des lignes propres, topologiquement
valides, calées sur des rues réelles, où l'on choisit au lieu de dessiner. Le
taux de reprise se mesurera commune par commune dans QGIS.

Source : https://data.geopf.fr/wfs/ows — couche STATISTICALUNITS.IRIS,
coédition INSEE-IGN, Licence Ouverte 2.0.
"""

import argparse
import collections
import csv
import json
import os
import pathlib
import sys
import time
import urllib.parse
import urllib.request

RACINE = pathlib.Path(__file__).resolve().parents[1]
LISTE = RACINE / "cartes" / "iris_outremer.csv"
SORTIE = RACINE / "cartes" / "iris_outremer.geojson"
RAPPORT = LISTE          # réécrit avec les comptes reçus

WFS = "https://data.geopf.fr/wfs/ows"
COUCHE = "STATISTICALUNITS.IRIS:contours_iris"

# Un en-tête de navigateur : plusieurs services publics renvoient une réponse
# vide aux requêtes sans user-agent. Même raison que dans `recupere_iris.py`.
ENTETES = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) "
                         "AppleWebKit/537.36 (KHTML, like Gecko) "
                         "Chrome/126.0 Safari/537.36"}

PAQUET = 10   # 28 communes : trois paquets suffisent, et l'URL reste courte

# Emprises approximatives, en degrés (lon min, lon max, lat min, lat max).
# Elles servent à un seul contrôle, mais un contrôle qui compte : en WFS 2.0,
# `EPSG:4326` peut être servi en lat/lon plutôt qu'en lon/lat selon
# l'implémentation. Inverser les axes place la Guadeloupe (−61,5 ; 16,2) au
# large de la Somalie (16,2 ; −61,5) — une géométrie parfaitement valide,
# simplement ailleurs. C'est le bogue du préfixe Marseille en version mondiale,
# et il ne se voit pas dans un décompte d'entités.
EMPRISES = {
    "971": (-62.0, -60.8, 15.8, 16.6),
    "972": (-61.3, -60.7, 14.3, 15.0),
    "973": (-55.0, -51.5, 2.0, 6.0),
    "974": (55.2, 55.9, -21.4, -20.8),
    "976": (44.9, 45.4, -13.1, -12.6),
}


def verifie_axes(feats):
    """Les coordonnées reçues tombent-elles là où ces communes se trouvent ?"""
    def points(g):
        if not g:
            return
        c = g.get("coordinates")
        pile = [c]
        while pile:
            x = pile.pop()
            if (isinstance(x, (list, tuple)) and len(x) >= 2
                    and all(isinstance(v, (int, float)) for v in x[:2])):
                yield x[0], x[1]
            elif isinstance(x, (list, tuple)):
                pile.extend(x)

    hors = collections.Counter()
    for f in feats:
        dep = (f.get("properties") or {}).get("code_insee", "")[:3]
        if dep not in EMPRISES:
            continue
        lo1, lo2, la1, la2 = EMPRISES[dep]
        for lon, lat in points(f.get("geometry")):
            if not (lo1 <= lon <= lo2 and la1 <= lat <= la2):
                hors[dep] += 1
            break          # un sommet par entité suffit à trancher
    return hors

# Mesuré le 16 août 2026. Sert de garde-fou : si le service rend moins que ça,
# c'est un incident, pas une nouvelle vérité.
ATTENDU_TOTAL = 472


def communes():
    """{code INSEE: nombre de coupes}, depuis le repérage."""
    if not LISTE.exists():
        sys.exit(f"absent : {LISTE}\n"
                 "  (produit par le repérage, voir annexes/docs/note_outre_mer.md §5)")
    with LISTE.open(encoding="utf-8") as f:
        lignes = list(csv.DictReader(f))
    return ({l["insee"]: int(l["coupes"]) for l in lignes},
            {l["insee"]: l["commune"] for l in lignes})


def interroge(codes, essais=3):
    """Un paquet de codes INSEE -> les entités IRIS, en WGS84."""
    filtre = "code_insee IN (" + ",".join(f"'{c}'" for c in codes) + ")"
    url = WFS + "?" + urllib.parse.urlencode({
        "SERVICE": "WFS", "VERSION": "2.0.0", "REQUEST": "GetFeature",
        "TYPENAMES": COUCHE, "OUTPUTFORMAT": "application/json",
        "SRSNAME": "EPSG:4326", "COUNT": "5000", "CQL_FILTER": filtre})
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
                    help="charger dans histgis.iris_om")
    a = ap.parse_args()

    coupes, nom = communes()
    codes = sorted(coupes)
    print(f"{len(codes)} communes d'outre-mer à découper, "
          f"{sum(coupes.values())} coupes")
    print("  (aucune n'est codée par arrondissement municipal, "
          "contrairement à Marseille, Lyon et Paris)\n")

    feats = []
    for i in range(0, len(codes), PAQUET):
        lot = codes[i:i + PAQUET]
        f = interroge(lot)
        feats += f
        print(f"  paquet {i//PAQUET + 1}/{(len(codes)-1)//PAQUET + 1} : "
              f"{len(lot):2d} communes -> {len(f):4d} IRIS")
        time.sleep(1)          # on ne martèle pas un service public

    if not feats:
        sys.exit("Aucune entité reçue. Vérifier l'accès à data.geopf.fr.")

    hors = verifie_axes(feats)
    if hors:
        sys.exit(
            "\nCoordonnées hors emprise : " + ", ".join(
                f"{d} ({n} entités)" for d, n in sorted(hors.items())) +
            "\n  Très probablement des axes inversés — `EPSG:4326` servi en"
            "\n  lat/lon au lieu de lon/lat. Essayer SRSNAME=CRS:84, ou"
            "\n  permuter les coordonnées avant écriture. Rien n'a été écrit.")
    print("  ✓ coordonnées dans l'emprise de chaque territoire (axes lon/lat)")

    SORTIE.write_text(json.dumps(
        {"type": "FeatureCollection",
         "crs": {"type": "name",
                 "properties": {"name": "urn:ogc:def:crs:EPSG::4326"}},
         "features": feats}, ensure_ascii=False), encoding="utf-8")

    # --- bilan par commune, et ce que la trame permet -------------------
    par = collections.Counter(f["properties"].get("code_insee") for f in feats)
    lignes, souci = [], 0
    for c in codes:
        n = par.get(c, 0)
        if n == 0:
            souci += 1
        lignes.append(dict(
            insee=c, commune=nom[c], dep=c[:3], coupes=coupes[c], iris=n,
            verdict=("aucun IRIS" if n == 0 else
                     "sans trame" if n < 2 else
                     "trame étroite" if n < coupes[c] + 2 else
                     "trame confortable")))
    with RAPPORT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0]))
        w.writeheader()
        w.writerows(lignes)

    v = collections.Counter(l["verdict"] for l in lignes)
    pourvues = sum(l["coupes"] for l in lignes if l["iris"] >= l["coupes"] + 1)
    total = sum(coupes.values())
    print(f"\n{len(feats)} IRIS pour {len(par)} communes "
          f"(attendu {ATTENDU_TOTAL})")
    for k in ("trame confortable", "trame étroite", "sans trame", "aucun IRIS"):
        if v[k]:
            print(f"   {k:20s} {v[k]:3d} communes")
    print(f"\n   coupes pourvues d'une trame : {pourvues} / {total}")

    if len(feats) < ATTENDU_TOTAL:
        print(f"\n  !! {ATTENDU_TOTAL - len(feats)} IRIS de moins qu'au "
              "16 août 2026 — incident de service plutôt que nouveauté,\n"
              "     relancer avant de conclure quoi que ce soit.")
    for l in lignes:
        if l["verdict"] in ("aucun IRIS", "sans trame"):
            print(f"     {l['insee']}  {l['commune'][:24]:24s} "
                  f"{l['coupes']} coupe(s), {l['iris']} IRIS")

    print(f"\n{SORTIE}\n{RAPPORT}")

    if a.charger:
        charger(feats)


def charger(feats):
    """Pose `histgis.iris_om`, en 4326.

    Surfaces : `ST_Area(geom::geography)`, en m². Pas de `ST_Area(geom)` ici —
    en 4326 ce serait des degrés carrés, un nombre qui ressemble à une surface
    sans en être une.
    """
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
        cur.execute("DROP TABLE IF EXISTS iris_om")
        cur.execute("CREATE TABLE iris_om ("
                    "  code_iris  char(9) PRIMARY KEY,"
                    "  code_insee char(5) NOT NULL,"
                    "  nom_commune text, nom_iris text, type_iris text,"
                    "  geom geometry(MultiPolygon, 4326) NOT NULL)")
        n = 0
        for f in feats:
            p = f.get("properties", {})
            if not p.get("code_iris") or not f.get("geometry"):
                continue
            cur.execute(
                "INSERT INTO iris_om VALUES (%s,%s,%s,%s,%s,"
                " ST_Multi(ST_MakeValid(ST_SetSRID("
                "   ST_GeomFromGeoJSON(%s), 4326))))"
                " ON CONFLICT DO NOTHING",
                (p["code_iris"], p.get("code_insee"), p.get("nom_commune"),
                 p.get("nom_iris"), p.get("type_iris"),
                 json.dumps(f["geometry"])))
            n += 1
        cur.execute("CREATE INDEX ON iris_om USING gist (geom)")
        cur.execute("CREATE INDEX ON iris_om (code_insee)")
        cur.execute("SELECT count(*), round(sum(ST_Area(geom::geography))"
                    "/1e6) FROM iris_om")
        nb, km2 = cur.fetchone()
    print(f"\nhistgis.iris_om : {nb} IRIS chargés, {km2} km² couverts")
    print("  (surfaces en geography — ST_Area(geom) rendrait des degrés carrés)")


if __name__ == "__main__":
    main()

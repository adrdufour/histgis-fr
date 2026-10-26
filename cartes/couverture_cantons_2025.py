#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
couverture_cantons_2025.py — les lignes modernes couvrent-elles nos villes ?

    python3 cartes/couverture_cantons_2025.py

La question
-----------
Des centaines de villes doivent être découpées à la main dans QGIS : ce sont
les communes portées par plusieurs atomes, celles qui relèvent de plusieurs
cantons à la fois. Marseille n'était que la première.

Aucune couche IGN n'a jamais porté ces lignes intérieures. GEOFLA replie
chaque ville divisée en un polygone unique — vérifié sur l'édition 2014 :
Bordeaux tombe entièrement dans « 3399 », Toulouse dans « 3199 », Lille dans
« 5992 ». Les 348 cantons qui manquent au COG 2012 sont exactement ceux-là,
295 pseudo-cantons au code ≥ 90.

ADMIN EXPRESS version 4 (avril 2025) est la première à publier « le contour
réel » des cantons : la commune multi-cantonale y est scindée. Ce script
mesure ce que cela nous donne — combien de nos villes divisées sont, elles
aussi, coupées en 2025, et donc pour combien il existe déjà un tracé sur
lequel s'accrocher.

Ce que le script NE dit pas
---------------------------
Que les lignes de 2014 suivent celles du XIXe siècle. Elles ont été tracées à
neuf et rien ne l'impose. Le gain attendu n'est pas la coïncidence mais le
stock : des coupes déjà propres, calées sur des rues et des cours d'eau
réels, où l'on choisit au lieu de dessiner. Le taux de coïncidence se jugera
ville par ville dans QGIS, Marseille en premier — ses onze lignes de 1870,
1886 et 1901 sont décrites dans `docs/gaudillere/protocole_georeferencement.md`.

Dépendances
-----------
`psycopg2` seul, déjà utilisé par `archives/planches/cartes_cantons.py` et
`consolide_registre.py`. Pas de pyproj, pas de pyshp : la reprojection et
l'intersection sont faites par PostGIS, qui les fait mieux.

Entrée attendue
---------------
`sources/geofla/a-can2025.geojson`, cantons électoraux 2025, source IGN COG CARTO
PLUS via icem7, Licence Ouverte 2.0 — compatible avec la contrainte du
projet. Géométrie simplifiée : bonne pour compter, pas pour digitaliser.
Pour QGIS il faudra ADMIN EXPRESS COG v4 complet.
"""

import csv
import json
import os
import sys
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
CAN2025 = RACINE / "sources" / "geofla" / "a-can2025.geojson"
SORTIE = RACINE / "cartes" / "couverture_cantons_2025.csv"

DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]

# Une commune n'est tenue pour coupée que si sa deuxième part dépasse ce
# seuil. En dessous ce sont des échardes de superposition entre millésimes :
# au seuil de 2 %, 8 156 communes ressortaient « coupées » sur GEOFLA 2014,
# toutes à 96/3. Le décalage de trame se déguise en fait.
SEUIL = 0.15

SQL_MESURE = f"""
WITH ville AS (
    -- Une ville divisée est une commune portant des ATOMES-FRACTION, ceux
    -- dont l'atom_id s'écrit 'cassini#canton'. Grouper simplement par
    -- insee_geofla en comptant les atomes en donnait 369 : c'est faux, la
    -- majorité sont des communes anciennes absorbées, qui partagent le même
    -- rattachement GEOFLA 2011 sans avoir jamais été coupées entre cantons.
    -- Le critère est le fractionnement, pas la cohabitation.
    --
    -- Sont exclus les atomes synthétiques de `15_creation_arriere.sql`, qui
    -- portent aussi fraction = true mais un cassini préfixé 'N' : ce ne sont
    -- pas des villes, ce sont des communes recréées en arrière.
    -- Deux origines, deux chantiers. `24_canton_moderne.sql` pose lui aussi
    -- des atomes-fraction, marqués `atom_geom.source = 'fraction_cog'` : ce
    -- sont les communes partagées entre cantons APRÈS 1943, données par le
    -- COG. Les compter avec les autres gonflait le total de 119 à 312 et
    -- noyait le seul taux qui décide du travail QGIS — les lignes de 2025
    -- sont quasi contemporaines des seconde, et très loin des premières.
    SELECT a.insee_geofla           AS insee,
           count(*)                 AS atomes,
           CASE WHEN bool_or(g.source <> 'fraction_cog')
                THEN 'historique (1870-1940)'
                ELSE 'moderne (1943-2012)' END AS origine,
           ST_Union(g.geom)         AS geom
    FROM   atom a
    JOIN   atom_geom g USING (atom_id)
    WHERE  a.insee_geofla IS NOT NULL
      AND  a.fraction
      AND  a.atom_id LIKE '%#%'
    GROUP  BY 1
    HAVING count(*) > 1
), part AS (
    SELECT v.insee, v.atomes, v.origine, c.can,
           ST_Area(ST_Intersection(v.geom, c.geom)) / ST_Area(v.geom) AS f
    FROM   ville v
    JOIN   can2025 c ON c.geom && v.geom AND ST_Intersects(c.geom, v.geom)
), bilan AS (
    SELECT insee, atomes, origine,
           count(*) FILTER (WHERE f > {SEUIL}) AS parts_2025
    FROM   part GROUP BY 1, 2, 3
)
SELECT b.insee,
       coalesce(g.nom, '')        AS nom,
       b.origine,
       b.atomes,
       coalesce(b.parts_2025, 0)  AS parts_2025,
       CASE WHEN coalesce(b.parts_2025, 0) > 1
            THEN 'lignes disponibles' ELSE 'à tracer entièrement' END AS statut
FROM   bilan b
LEFT   JOIN noms_geofla g ON g.insee = b.insee
ORDER  BY 3, 6, 4 DESC, 1
"""

# `insee_mvt` ne nomme que les communes qui ont bougé : la moitié des villes
# sortaient sans nom. GEOFLA les nomme toutes.
SQL_NOMS = """
CREATE TABLE IF NOT EXISTS noms_geofla (
    insee char(5) PRIMARY KEY, nom text NOT NULL, dep char(3))
"""


def connexion():
    if os.environ.get("HISTGIS_DSN"):
        return psycopg2.connect(os.environ["HISTGIS_DSN"])
    for dsn in DSN_CANDIDATS:
        try:
            return psycopg2.connect(dsn)
        except psycopg2.OperationalError:
            pass
    raise SystemExit("Connexion impossible. Définir HISTGIS_DSN.")


def charge(cur):
    """Pose `can2025` en Lambert 93. PostGIS reprojette depuis le WGS84."""
    gj = json.loads(CAN2025.read_text(encoding="utf-8"))
    cur.execute("DROP TABLE IF EXISTS can2025")
    cur.execute("CREATE TABLE can2025 ("
                "  can         text PRIMARY KEY,"
                "  nom         text,"
                "  dep         text,"
                # Champ donné par l'IGN, et le plus utile du lot : il dit si le
                # canton est fait de communes entières ou s'il en coupe une.
                # 670 cantons sur 2 061 en coupent au moins une — la couche
                # porte donc bien les lignes intérieures que GEOFLA n'a
                # jamais eues.
                "  composition text,"
                "  geom        geometry(MultiPolygon, 2154) NOT NULL)")
    n = 0
    vus = set()
    for f in gj["features"]:
        p = f["properties"]
        code = p.get("codgeo")
        if not code or code in vus or not f.get("geometry"):
            continue
        vus.add(code)
        cur.execute(
            "INSERT INTO can2025 (can, nom, dep, composition, geom)"
            " VALUES (%s, %s, %s, %s,"
            " ST_Multi(ST_MakeValid(ST_Transform("
            "   ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326), 2154))))",
            (code, p.get("libgeo", ""), p.get("dept", ""),
             p.get("composition", ""), json.dumps(f["geometry"])))
        n += 1
    cur.execute("CREATE INDEX ON can2025 USING gist (geom)")
    cur.execute("ANALYZE can2025")
    return n


def main():
    if not CAN2025.exists():
        sys.exit(
            f"Fichier absent : {CAN2025}\n\n"
            "À télécharger (Licence Ouverte 2.0, ~11,8 Mo) :\n"
            "  https://static.data.gouv.fr/resources/"
            "communes-cantons-et-epci-2025-admin-express-cog-plus-ign/"
            "20250626-075229/a-can2025.geojson\n"
            "et à déposer sous ce nom.")

    with connexion() as cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        n = charge(cur)
        print(f"can2025 : {n} cantons chargés et reprojetés en Lambert 93")
        cur.execute(SQL_NOMS)
        cur.execute("SELECT count(*) FROM noms_geofla")
        if cur.fetchone()[0] == 0:
            with (RACINE / "build" / "noms_geofla.csv").open(encoding="utf-8") as f:
                next(f)
                cur.copy_expert("COPY noms_geofla (insee, nom, dep) "
                                "FROM STDIN WITH (FORMAT csv)", f)
            print("noms_geofla : table de confort chargée depuis GEOFLA ED111")
        cur.execute("SELECT composition, count(*) FROM can2025 "
                    "GROUP BY 1 ORDER BY 2 DESC")
        for comp, k in cur.fetchall():
            print(f"  {k:5d}  {comp}")
        cur.execute(SQL_MESURE)
        lignes = cur.fetchall()

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["insee", "nom", "origine", "atomes", "parts_2025",
                    "statut"])
        w.writerows(lignes)

    for orig in ("historique (1870-1940)", "moderne (1943-2012)"):
        lot = [l for l in lignes if l[2] == orig]
        if not lot:
            continue
        d = [l for l in lot if l[5] == "lignes disponibles"]
        print(f"\n{orig} : {len(lot)} villes divisées")
        print(f"  coupées aussi en 2025 : {len(d)} "
              f"({100*len(d)//len(lot)} %)")
        print(f"  à tracer entièrement  : {len(lot)-len(d)}")

    hist = [l for l in lignes if l[2].startswith("historique")
            and l[5] == "lignes disponibles"]
    if hist:
        print("\nles mieux servies, période historique "
              "(atomes 1870-1940 / parts 2025) :")
        for l in sorted(hist, key=lambda x: -x[3])[:12]:
            print(f"  {l[0]}  {l[1][:26]:26s} {l[3]:3d} atomes "
                  f"-> {l[4]:2d} parts en 2025")
    print(f"\nDétail : {SORTIE}")
    print("\nRappel : la COÏNCIDENCE des tracés n'est pas mesurée ici — "
          "seulement leur existence. Elle se juge ville par ville dans QGIS.")


if __name__ == "__main__":
    main()

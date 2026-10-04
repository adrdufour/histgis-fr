#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
paris_quartiers_1815.py — poser les 48 quartiers du Paris d'avant 1860

    python3 circo/paris_quartiers_1815.py

Ce que ça débloque
------------------
`paris_quartiers.py` pose les 80 quartiers **d'après 1860**. Cinq des dix-neuf
divisions électorales transcrites dans `paris_decoupage.csv` sont antérieures —
1815, 1820-1831, 1831-1848, 1852-1857, 1857-1863 — et emploient l'AUTRE système :
douze arrondissements, quatre quartiers chacun, hérités des sections
révolutionnaires. Leurs noms ne se résolvent pas dans la trame des 80, et
`paris_circo.py` les écarte à juste titre : « ce n'est pas un échec mais une
frontière ».

Cette frontière tombe ici.

La source
---------
Consortium **ALPAGE**, couche 42 « Quartiers du temps de Vasserot », déposée
dans `42-Vasserot_quartiers_v1L93/`. Limites reprises de l'*Atlas pittoresque
des quarante-huit quartiers de Paris* d'A.-M. Perrot, repositionnées sur les
plans d'îlots Vasserot (1810-1836) géoréférencés. Lambert-93.

**Licence** : base sous ODbL 1.0, contenus sous DbCL 1.0, et — c'est ce qui
compte ici — « toutes les cartes produites à partir de la base ALPAGE doivent
être placées sous CC-BY-SA 2.0 ». Une carte tirée de ces géométries est donc
publiable sur Commons et Wikipédia, et doit y porter cette licence. Crédit
obligatoire et nominatif : **© ALPAGE : Anne-Laure Bethe**. Détail dans
`42-Vasserot_quartiers_v1L93/LICENCE_ET_CREDIT.md`.

Ce que la couche n'est pas
--------------------------
**Ce n'est pas un instantané.** Le champ `DATE_COYEC` donne la date de levé
quartier par quartier : 1813-1816 pour Saint-Marcel, 1832-1835 pour les
Quinze-Vingts. Un quart de siècle sépare les extrêmes. La table conserve cette
colonne, et toute carte qui s'en sert doit le dire.

Les recettes
------------
1. 48 quartiers, 12 arrondissements, **quatre par arrondissement**.
2. Les numéros de quartier vont de 1 à 48, sans trou ni doublon.
3. **Le Paris d'avant 1860 doit être contenu dans celui d'aujourd'hui** :
   l'annexion de 1860 n'a fait qu'ajouter du territoire. C'est un contrôle
   géométrique indépendant de la source, et il tombe si le géoréférencement de
   l'atlas est faux.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
SHP = RACINE / "42-Vasserot_quartiers_v1L93" / "VASSEROT_QUARTIERS_Project.shp"
GEOJSON = RACINE / "circo" / "sorties" / "vasserot_quartiers.geojson"


# La connexion est IMPORTÉE, pas réécrite. La mienne se contentait de
# `dbname=histgis` et échouait sur la socket ; celle du projet essaie une liste
# de DSN candidats et honore `HISTGIS_DSN`. Réécrire ce que le dépôt fournit,
# c'est se donner une seconde version qui divergera — c'est la remarque que
# `paris_quartiers.py` porte déjà sur la clé de rapprochement, quinze lignes
# plus bas dans son propre fichier.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from paris_quartiers import connexion                   # noqa: E402


def convertit():
    """Shapefile -> GeoJSON en Lambert-93, via ogr2ogr."""
    if GEOJSON.exists():
        return
    if not SHP.exists():
        sys.exit(f"Shapefile absent : {SHP}")
    if not shutil.which("ogr2ogr"):
        sys.exit("ogr2ogr absent (paquet gdal-bin). Il est déjà requis par "
                 "40_outremer.sql ; l'installer, ou convertir à la main.")
    GEOJSON.parent.mkdir(parents=True, exist_ok=True)
    # -t_srs explicite : le .prj annonce du Lambert-93, on le confirme plutôt
    # que de le supposer. Le .cpg annonce de l'UTF-8, contrairement à la fiche
    # de la couche qui parle d'ISO-8859-1 — on suit le .cpg, qui accompagne
    # les données et non leur description.
    subprocess.run(
        ["ogr2ogr", "-f", "GeoJSON", "-t_srs", "EPSG:2154",
         "-lco", "RFC7946=NO", str(GEOJSON), str(SHP)],
        check=True, env={**os.environ, "SHAPE_ENCODING": "UTF-8"})
    print(f"converti : {GEOJSON.relative_to(RACINE)}")


def charge(cur, gj):
    cur.execute("DROP TABLE IF EXISTS paris_quartier_1815")
    cur.execute("CREATE TABLE paris_quartier_1815 ("
                "  quartier       smallint PRIMARY KEY,"
                "  nom            text NOT NULL,"
                "  arrondissement smallint NOT NULL,"
                "  id_alpage      text,"
                # La date de levé, conservée : la couche couvre un quart de
                # siècle et l'oublier ferait passer une série pour un
                # instantané.
                "  date_leve      text,"
                "  geom           geometry(MultiPolygon, 2154) NOT NULL)")
    n = 0
    for f in gj["features"]:
        p = f["properties"]
        g = f.get("geometry")
        if not g:
            continue
        cur.execute(
            "INSERT INTO paris_quartier_1815 VALUES (%s, %s, %s, %s, %s,"
            " ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(%s), 2154))))",
            (int(p["NUM_QUARTI"]), p["NOM"], int(p["NUM_ARROND"]),
             p.get("ID_ALPAGE"), p.get("DATE_COYEC"), json.dumps(g)))
        n += 1
    cur.execute("CREATE INDEX ON paris_quartier_1815 USING gist (geom)")
    return n


def main():
    convertit()
    gj = json.loads(GEOJSON.read_text(encoding="utf-8"))

    with connexion() as cnx, cnx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        n = charge(cur, gj)
        print(f"paris_quartier_1815 : {n} quartiers chargés")

        # --- 1. structure -------------------------------------------------
        cur.execute("SELECT count(*), count(DISTINCT arrondissement),"
                    " min(quartier), max(quartier),"
                    " round((sum(ST_Area(geom))/1e6)::numeric, 2)"
                    " FROM paris_quartier_1815")
        nq, na, mn, mx, km2 = cur.fetchone()
        print(f"  {nq} quartiers, {na} arrondissements, "
              f"numéros {mn} à {mx}, {km2} km²")

        cur.execute("SELECT arrondissement, count(*) FROM paris_quartier_1815"
                    " GROUP BY 1 HAVING count(*) <> 4 ORDER BY 1")
        ecarts = cur.fetchall()
        print("  quatre quartiers par arrondissement : "
              + ("oui" if not ecarts else f"NON — {ecarts}"))

        cur.execute("SELECT count(*) FROM generate_series(1, 48) s"
                    " WHERE NOT EXISTS (SELECT 1 FROM paris_quartier_1815 q"
                    "                    WHERE q.quartier = s)")
        (trous,) = cur.fetchone()
        print(f"  numéros manquants entre 1 et 48 : {trous}")

        # --- 2. le contrôle indépendant -----------------------------------
        # L'annexion de 1860 n'a fait qu'AJOUTER du territoire : le Paris de
        # Vasserot doit tenir dans celui d'aujourd'hui. Si ça déborde, c'est le
        # géoréférencement de l'atlas qui est en cause, et il ne faut rien
        # poser tant qu'on ne sait pas de combien.
        cur.execute("SELECT to_regclass('histgis.paris_quartier') IS NOT NULL")
        if cur.fetchone()[0]:
            cur.execute("""
                WITH v AS (SELECT ST_UnaryUnion(ST_Collect(geom)) g
                             FROM paris_quartier_1815),
                     m AS (SELECT ST_UnaryUnion(ST_Collect(geom)) g
                             FROM paris_quartier)
                SELECT round((ST_Area(v.g)/1e6)::numeric, 2),
                       round((ST_Area(m.g)/1e6)::numeric, 2),
                       round((ST_Area(ST_Difference(v.g, m.g))/1e6)::numeric, 3)
                  FROM v, m""")
            av, ap, hors = cur.fetchone()
            print(f"\n  Paris de Vasserot : {av} km²")
            print(f"  Paris de 1860     : {ap} km²")
            print(f"  hors du Paris moderne : {hors} km²")
            if hors > 0.5:
                print("  ** DÉBORDEMENT — le géoréférencement est à vérifier "
                      "avant de poser quoi que ce soit. **")
        else:
            print("\n  paris_quartier absente : contrôle d'emboîtement sauté.")
            print("  (python3 circo/paris_quartiers.py)")

        # --- 3. la couche est-elle un instantané ? ------------------------
        cur.execute("SELECT date_leve, count(*) FROM paris_quartier_1815"
                    " GROUP BY 1 ORDER BY 1")
        print("\n  dates de levé :")
        for d, c in cur.fetchall():
            print(f"     {d or '(vide)':<12} {c:>2} quartier(s)")

    print("\nSuite : sql/54_paris_circo_1815.sql")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
paris_quartiers.py — poser les 80 quartiers administratifs de Paris

    python3 circo/paris_quartiers.py

Pourquoi ce script existe
-------------------------
Paris avait été déclaré irréductible faute de trame. `circo/note_paris.md` a
levé la moitié du blocage : la transcription de `paris_decoupage.xlsx` donne la
composition **par quartier** de dix-neuf divisions électorales de 1815 à 1986,
et douze divisions postérieures à 1860 citent exactement 80 quartiers, sans un
oubli ni un inventé. Restait l'autre moitié : la géométrie de ces 80 quartiers.

Le jeu de la Ville de Paris est en ODbL, incompatible avec la contrainte du
projet — sources CC BY-SA ou Licence Ouverte, vérifiables par URL publique.

La solution passe par les IRIS
------------------------------
CONTOURS-IRIS (coédition INSEE-IGN) est en **Licence Ouverte 2.0**. Or, pour
les communes découpées en IRIS, les deux premiers caractères du numéro d'IRIS
désignent le grand quartier ; et **à Paris les limites d'IRIS sont calées sur
les limites d'arrondissement, les limites de quartier et les tronçons de rue**.

Les 80 quartiers se reconstruisent donc par simple union, sans arbitrage :

    code_iris = 751 + AA + QQ + NN
                      |    |    +-- rang de l'IRIS dans le quartier
                      |    +------- quartier, 01 à 80, continu sur la ville
                      +------------ arrondissement

Vérifié sur le 4e : quartiers 13 Saint-Merri, 14 Saint-Gervais, 15 Arsenal,
16 Notre-Dame — les quatre quartiers du 4e, dans l'ordre.

Ce que le script ne garantit pas
--------------------------------
Que les limites de quartier de l'IRIS d'aujourd'hui soient celles de 1876. Les
80 quartiers sont réputés stables depuis la loi de 1859, mais « réputés » n'est
pas « vérifié ». Ce qui est posé ici est la trame moderne ; toute divergence
ancienne devra être traitée comme telle, et le contrôle par les rues (§ 4 de
`note_paris.md`) en donnera l'occasion.

Entrée attendue
---------------
`circo/sorties/iris_paris.geojson` — extraction WFS de CONTOURS-IRIS sur Paris, en
Lambert 93. L'URL est rappelée par le script s'il manque.
"""

import collections
import csv
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
IRIS = RACINE / "circo" / "sorties" / "iris_paris.geojson"
VOCAB = RACINE / "circo" / "paris_vocab.csv"
SORTIE = RACINE / "circo" / "paris_quartiers.csv"

URL = ("https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0"
       "&REQUEST=GetFeature&TYPENAMES=STATISTICALUNITS.IRIS:contours_iris"
       "&OUTPUTFORMAT=application/json&SRSNAME=EPSG:2154&COUNT=2000"
       "&CQL_FILTER=code_insee%20LIKE%20%27751%25%27")

DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]


def connexion():
    if os.environ.get("HISTGIS_DSN"):
        return psycopg2.connect(os.environ["HISTGIS_DSN"])
    for dsn in DSN_CANDIDATS:
        try:
            return psycopg2.connect(dsn)
        except psycopg2.OperationalError:
            pass
    raise SystemExit("Connexion impossible. Définir HISTGIS_DSN.")


# La clé de rapprochement est IMPORTÉE, pas réécrite. Une seconde version
# aurait divergé : la mienne réduisait « saint » à « st » alors que le
# vocabulaire garde « saint », et cinq quartiers sur 80 — Saint-Merri,
# Saint-Gervais, Saint-Victor, Saint-Lambert, Saint-Fargeau — seraient
# ressortis « non appariés » pour une raison qui n'existe pas dans les
# données. `extrait_paris.cle` porte en outre la table des coquilles.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from extrait_paris import cle          # noqa: E402


# Les quatre écarts que l'article ne suffit pas à expliquer. Chacun est
# justifié par le fichier de découpage lui-même, pas par une ressemblance de
# chaînes — c'est la règle du projet : on formule l'hypothèse, puis on la teste.
#
#   « roule »  : 14 occurrences, TOUJOURS arrondissement 8, de 1863 à 1986.
#                C'est bien le quartier 30. À ne pas confondre avec
#                « le roule », 5 occurrences, sans arrondissement, et
#                seulement de 1815 à 1863 : celui-là est le quartier
#                d'AVANT 1860, un autre objet. Les deux systèmes de
#                vocabulaire se séparent d'eux-mêmes, comme l'avait relevé
#                `note_paris.md`.
#
#   « sante »  : 14 occurrences, toujours arrondissement 14, de 1863 à 1986.
#                Le 14e y compte Montparnasse, Plaisance, Petit-Montrouge et
#                Santé, quand l'INSEE écrit Parc-de-Montsouris. Ce n'est pas
#                un désaccord de trame mais un RENOMMAGE du quartier 54.
#
#   les deux derniers sont orthographiques : le 3e de 1876 écrit
#   « saint aveye » pour Sainte-Avoye, et l'atlas « d'Acquin » pour d'Aquin.
INSEE_VERS_ATLAS = {
    "faubourgduroule":  ("roule", "abréviation ; « le roule » est un autre "
                                  "quartier, d'avant 1860"),
    "parcdemontsouris": ("sante", "renommage du quartier 54"),
    "sainteavoye":      ("saintavoye", "orthographe"),
    "saintthomasdaquin": ("saintthomasdacquin", "orthographe"),
}

ARTICLES = ("les ", "la ", "le ", "l'")


def appariement(nom, vocab):
    """Rend (clé retenue, motif) ou (None, None).

    L'article défini se promène d'une source à l'autre — « Les Halles » contre
    « halles », « Roquette » contre « la roquette » — et dans les deux sens.
    On essaie donc de le retirer ET de l'ajouter, ce qui règle huit cas sur
    douze sans table ni arbitrage.
    """
    n = (nom or "").strip()
    k = cle(n)
    if k in vocab:
        return k, "direct"
    if k in INSEE_VERS_ATLAS:
        cible, motif = INSEE_VERS_ATLAS[k]
        if cible in vocab:
            return cible, motif
    bas = n.lower()
    for a in ARTICLES:
        if bas.startswith(a):
            k2 = cle(n[len(a):])
            if k2 in vocab:
                return k2, "article retiré"
    for a in ("la ", "le ", "les "):
        k2 = cle(a + n)
        if k2 in vocab:
            return k2, "article ajouté"
    return None, None


def racine_iris(nom):
    """« Saint-Merri 3 » -> « Saint-Merri ». Le rang n'appartient pas au nom."""
    return re.sub(r"\s+\d+$", "", (nom or "").strip())


def charge(cur):
    gj = json.loads(IRIS.read_text(encoding="utf-8"))
    cur.execute("DROP TABLE IF EXISTS paris_quartier")
    cur.execute("DROP TABLE IF EXISTS iris_paris")
    cur.execute("CREATE TABLE iris_paris ("
                "  code_iris char(9) PRIMARY KEY,"
                "  code_insee char(5) NOT NULL,"
                "  quartier   smallint NOT NULL,"
                "  nom_iris   text,"
                "  type_iris  text,"
                "  geom       geometry(MultiPolygon, 2154) NOT NULL)")
    n = 0
    for f in gj["features"]:
        p = f["properties"]
        code = p.get("code_iris")
        if not code or not f.get("geometry"):
            continue
        # 751 AA QQ NN : le quartier est en position 6-7 du code
        cur.execute(
            "INSERT INTO iris_paris VALUES (%s, %s, %s, %s, %s,"
            " ST_Multi(ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(%s),2154))))"
            " ON CONFLICT DO NOTHING",
            (code, p.get("code_insee"), int(code[5:7]), p.get("nom_iris"),
             p.get("type_iris"), json.dumps(f["geometry"])))
        n += 1
    cur.execute("CREATE INDEX ON iris_paris USING gist (geom)")
    return n


SQL_QUARTIER = """
CREATE TABLE paris_quartier AS
SELECT quartier,
       min(code_insee)                        AS arrondissement,
       ST_Multi(ST_UnaryUnion(ST_Collect(geom))) AS geom,
       count(*)                               AS iris
FROM   iris_paris
GROUP  BY quartier
"""


def main():
    if not IRIS.exists():
        sys.exit(f"Fichier absent : {IRIS}\n\n"
                 "Extraction WFS de CONTOURS-IRIS sur Paris "
                 "(IGN/INSEE, Licence Ouverte 2.0) :\n\n  " + URL +
                 "\n\nEnregistrer sous ce nom.")

    with connexion() as cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        n = charge(cur)
        cur.execute(SQL_QUARTIER)
        cur.execute("ALTER TABLE paris_quartier ADD PRIMARY KEY (quartier)")
        cur.execute("ALTER TABLE paris_quartier ADD COLUMN nom text")

        # Le nom du quartier vient de préférence des IRIS d'HABITAT : les
        # IRIS techniques — « Seine et Berges », « Bassin de l'Arsenal » —
        # portent un nom de lieu, pas un nom de quartier.
        #
        # DÉCLASSER, ne pas EXCLURE. Les filtrer laissait sans nom les
        # quartiers qui n'ont aucun IRIS d'habitat — les bois de Boulogne et
        # de Vincennes, qui sont des quartiers à part entière et n'ont
        # presque pas d'habitants. Une règle bâtie sur le cas courant doit
        # dégrader, pas échouer, sur le cas limite.
        cur.execute("""
            UPDATE paris_quartier q SET nom = s.nom FROM (
                SELECT quartier, nom, row_number() OVER
                       (PARTITION BY quartier
                        ORDER BY (h > 0) DESC, n DESC, nom) AS r
                FROM (
                    SELECT quartier,
                           regexp_replace(nom_iris, '\\s+\\d+$', '') AS nom,
                           count(*) FILTER (
                               WHERE coalesce(type_iris, 'H') = 'H') AS h,
                           count(*) AS n
                    FROM   iris_paris
                    GROUP  BY 1, 2
                ) t
            ) s WHERE s.quartier = q.quartier AND s.r = 1
        """)

        cur.execute("SELECT count(*), count(DISTINCT arrondissement) "
                    "FROM paris_quartier")
        nq, narr = cur.fetchone()
        cur.execute("SELECT arrondissement, count(*) FROM paris_quartier "
                    "GROUP BY 1 HAVING count(*) <> 4 ORDER BY 1")
        anomalies = cur.fetchall()

        # Contrôle de surface : l'union des 80 quartiers doit rendre Paris.
        cur.execute("""
            SELECT ST_Area(ST_Union(q.geom)) / 1e6,
                   (SELECT ST_Area(ST_Union(g.geom)) / 1e6
                    FROM geofla_commune g WHERE left(g.insee_com,3) = '751')
            FROM paris_quartier q
        """)
        aq, ap = cur.fetchone()

        cur.execute("SELECT quartier, arrondissement, nom, iris "
                    "FROM paris_quartier ORDER BY quartier")
        quartiers = cur.fetchall()

    print(f"iris_paris     : {n} IRIS chargés")
    print(f"paris_quartier : {nq} quartiers, {narr} arrondissements")
    print(f"  4 quartiers par arrondissement : "
          f"{'oui' if not anomalies else 'NON — ' + str(anomalies)}")
    print(f"  surface : quartiers {aq:.2f} km², Paris GEOFLA {ap:.2f} km², "
          f"écart {abs(aq-ap):.3f} km²")

    # Le contrôle qui compte : la géométrie parle-t-elle la même langue que la
    # transcription ? `paris_vocab.csv` porte le vocabulaire des deux systèmes
    # de quartiers, l'ancien et les 80 d'après 1860. Si les 80 noms tirés de
    # l'IRIS s'y retrouvent, les deux sources se confirment l'une l'autre.
    vocab = {l["cle"] for l in csv.DictReader(VOCAB.open(encoding="utf-8"))}
    app = {q: appariement(nom, vocab) for q, a, nom, i in quartiers}
    trouves = [x for x in quartiers if app[x[0]][0]]
    manquants = [x for x in quartiers if not app[x[0]][0]]
    print(f"\nnoms retrouvés dans paris_vocab.csv : {len(trouves)} / {nq}")
    motifs = collections.Counter(app[q][1] for q, *_ in trouves)
    for m, k in motifs.most_common():
        print(f"    {k:3d}  {m}")
    if manquants:
        print("  non appariés :")
        for q, a, nom, i in manquants:
            print(f"    {q:2d}  arr. {a}  {nom}  (clé « {cle(nom or '')} »)")

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["quartier", "arrondissement", "nom_insee", "cle_atlas",
                    "motif", "iris"])
        for q, a, nom, i in quartiers:
            k, m = app[q]
            w.writerow([q, a, nom, k or "", m or "NON APPARIÉ", i])
    print(f"\nDétail : {SORTIE}")


if __name__ == "__main__":
    main()

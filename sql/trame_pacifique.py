#!/usr/bin/env python3
"""Nettoie et allège les trames du Pacifique : `geom_carte` dans om_pf_src et om_nc_src.

Appelé par `charger_pacifique.sh`, après ogr2ogr. Écrit une seconde colonne
géométrique ; la colonne `geom`, celle de la source, n'est pas touchée.
`135_pacifique.sql` lit `geom_carte`.

    python3 sql/trame_pacifique.py [--dsn "dbname=histgis"] [--tolerance 20]

Demande shapely >= 2.1 (GEOS >= 3.12) : `coverage_simplify` n'existe pas avant.
L'environnement `histgis` l'a ; PostGIS 3.2 n'a pas `ST_CoverageSimplify`.

POURQUOI LA NOUVELLE-CALÉDONIE DOIT ÊTRE RECOUSUE
-------------------------------------------------
Le portail data.gouv.nc publie des limites « simplifiées » commune par commune :
deux voisines ne partagent plus exactement leur limite. Mesuré le
25 octobre 2026 : 26 communes sur 33 ont des bords non appariés, la réunion
porte 292 trous, et l'accrochage à 25 m de l'export en fait 1 554 (7,4 km²).
GEOFLA, dans les DOM, en donne zéro avant comme après. Une carte faite de ces
formes montrerait un liseré blanc le long de chaque limite communale et
des points blancs dans chaque circonscription.

D'où une recouture, qui ne déplace aucune limite : toutes les limites sont
nouées ensemble, le plan est découpé en faces, et chaque face va à une commune.

  * une face couverte par UNE commune lui revient ;
  * une face couverte par DEUX (chevauchement) ou par AUCUNE alors que deux
    communes la bordent (interstice) va à la commune avec laquelle elle partage
    la plus longue limite — parmi les candidates pour un chevauchement, parmi
    les voisines pour un interstice ;
  * une face vide bordée par UNE seule commune est un trou de la source, pas un
    interstice : elle reste un trou.

Le résultat est vérifié par `coverage_is_valid` : s'il ne l'est pas, rien
n'est écrit.

POURQUOI LES DEUX SONT ALLÉGÉES
-------------------------------
Les deux trames sont bien plus fines que GEOFLA : 987 142 sommets pour la
Polynésie, 425 297 pour la Nouvelle-Calédonie, contre 3 000 à 16 000 par DOM.
Exportées telles quelles, ce sont 40 et 25 Mo de fichiers. `coverage_simplify`
allège sans défaire le partage des limites — deux voisines restent
voisines au sommet près —, ce qu'un `ST_Simplify` commune par commune ne
garantirait pas. 20 m par défaut, sous le pas de 25 m de l'export.
"""
import argparse
import sys

import psycopg2
import shapely
from shapely import wkb

DSN_CANDIDATS = ["dbname=histgis host=/var/run/postgresql", "dbname=histgis",
                 "dbname=histgis host=localhost"]
M_PAR_DEG = 111320.0


def connecte(dsn):
    for d in ([dsn] if dsn else DSN_CANDIDATS):
        try:
            return psycopg2.connect(d)
        except psycopg2.OperationalError as e:
            err = e
    sys.exit(f"Connexion impossible : {err}")


def lit(cur, table, cle):
    cur.execute(f"SELECT {cle}::text, ST_AsBinary(geom) FROM histgis.{table} "
                f"ORDER BY 1")
    rows = cur.fetchall()
    return [r[0] for r in rows], [wkb.loads(bytes(r[1])) for r in rows]


def recoud(geoms):
    """Partition propre des mêmes communes. Rend (géométries, compte rendu)."""
    lignes = shapely.union_all([g.boundary for g in geoms])
    faces = list(shapely.get_parts(shapely.polygonize(shapely.get_parts(lignes))))
    arbre = shapely.STRtree(geoms)
    pts = [f.point_on_surface() for f in faces]

    proprio = [None] * len(faces)
    a_trancher = []
    for k, (f, p) in enumerate(zip(faces, pts)):
        dedans = list(arbre.query(p, predicate="within"))
        if len(dedans) == 1:
            proprio[k] = dedans[0]
        else:
            a_trancher.append((k, dedans))

    # Les faces sûres d'abord : c'est contre elles qu'on mesure les limites.
    sures = [shapely.union_all([faces[k] for k in range(len(faces))
                               if proprio[k] == i]) for i in range(len(geoms))]
    arbre_s = shapely.STRtree(sures)
    n_chev = n_inter = n_trou = 0
    for k, dedans in a_trancher:
        f = faces[k]
        cand = dedans or [int(i) for i in arbre_s.query(f, predicate="touches")]
        longueurs = {i: f.boundary.intersection(sures[i].boundary).length
                     for i in cand}
        bordees = [i for i, l in longueurs.items() if l > 0]
        if dedans:
            n_chev += 1
        elif len(bordees) >= 2:
            n_inter += 1
        else:
            n_trou += 1
            continue                     # trou de la source : on le garde
        proprio[k] = max(cand, key=lambda i: (longueurs[i], -i))

    sortie = []
    for i in range(len(geoms)):
        g = shapely.union_all([faces[k] for k in range(len(faces))
                               if proprio[k] == i])
        sortie.append(g)
    return sortie, {"faces": len(faces), "chevauchements": n_chev,
                    "interstices": n_inter, "trous gardés": n_trou}


def multi(g):
    g = shapely.make_valid(g)
    polys = [p for p in shapely.get_parts(g) if p.geom_type == "Polygon"]
    return shapely.MultiPolygon(polys)


def traite(cx, table, cle, recoudre, tol_m):
    cur = cx.cursor()
    codes, geoms = lit(cur, table, cle)
    n0 = sum(shapely.get_num_coordinates(geoms))
    a0 = sum(g.area for g in geoms)
    print(f"{table} : {len(geoms)} communes, {n0} sommets, "
          f"couverture valide : {shapely.coverage_is_valid(geoms)}")
    if recoudre:
        geoms, cr = recoud(geoms)
        print("  recousue : " + ", ".join(f"{v} {k}" for k, v in cr.items()))
        if not shapely.coverage_is_valid(geoms):
            sys.exit(f"  {table} : couverture toujours invalide après recouture "
                     f"— rien n'est écrit.")
    geoms = list(shapely.coverage_simplify(geoms, tol_m / M_PAR_DEG))
    geoms = [multi(g) for g in geoms]
    vides = [c for c, g in zip(codes, geoms) if g.is_empty]
    if vides:
        sys.exit(f"  {table} : commune(s) vidée(s) par l'allègement : {vides}")
    if not shapely.coverage_is_valid(geoms):
        sys.exit(f"  {table} : couverture invalide après allègement — rien "
                 f"n'est écrit.")
    n1 = sum(shapely.get_num_coordinates(geoms))
    a1 = sum(g.area for g in geoms)
    print(f"  allégée à {tol_m:g} m : {n1} sommets ({100 * n1 / n0:.0f} %), "
          f"surface {100 * (a1 / a0 - 1):+.2f} %")

    cur.execute(f"ALTER TABLE histgis.{table} DROP COLUMN IF EXISTS geom_carte")
    cur.execute(f"ALTER TABLE histgis.{table} "
                f"ADD COLUMN geom_carte geometry(MultiPolygon, 4326)")
    for c, g in zip(codes, geoms):
        cur.execute(f"UPDATE histgis.{table} SET geom_carte = "
                    f"ST_SetSRID(ST_GeomFromWKB(%s), 4326) WHERE {cle}::text = %s",
                    (psycopg2.Binary(wkb.dumps(g)), c))
    cur.execute(f"SELECT count(*) FROM histgis.{table} WHERE geom_carte IS NULL")
    if cur.fetchone()[0]:
        sys.exit(f"  {table} : des lignes sans geom_carte.")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dsn", default=None)
    ap.add_argument("--tolerance", type=float, default=20.0,
                    help="tolérance d'allègement, en mètres (défaut 20)")
    args = ap.parse_args()
    cx = connecte(args.dsn)
    with cx:
        traite(cx, "om_pf_src", "idcom", recoudre=False, tol_m=args.tolerance)
        traite(cx, "om_nc_src", "code_com", recoudre=True, tol_m=args.tolerance)
    print("geom_carte écrite.")


if __name__ == "__main__":
    main()

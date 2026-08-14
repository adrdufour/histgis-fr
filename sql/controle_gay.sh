#!/usr/bin/env bash
# ============================================================================
# histgis — contrôle indépendant contre les cantons dissous par Victor Gay.
#
# TRF-GIS livre, pour 1870 et 1940 seulement, les cantons DÉJÀ dissous
# (`trfgis/cantons/Shapefiles/CANTONS_YYYY.zip`). Ces polygones ne dépendent
# pas de notre chaîne : les comparer à `snapshot_geom()` teste tout d'un coup,
# attributions comprises.
#
#   ./controle_gay.sh                       # base histgis, dossier parent
#   PGDATABASE=magine ./controle_gay.sh     # autre base
#   ./controle_gay.sh /autre/chemin/projet_carte
#
# Prérequis : la base doit être chargée (load.sh puis 05 → 06 → 07),
# et `ogr2ogr` disponible (paquet gdal-bin).
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
export PGDATABASE="${PGDATABASE:-histgis}"

ANNEES=(1870 1940)
SHPDIR="$RACINE/trfgis/cantons/Shapefiles"
NOMDIR="$RACINE/trfgis/cantons/Nomenclatures"

command -v ogr2ogr >/dev/null || { echo "ogr2ogr introuvable (apt install gdal-bin)" >&2; exit 1; }

for a in "${ANNEES[@]}"; do
    [[ -f "$SHPDIR/CANTONS_$a.zip" ]] || { echo "manquant : $SHPDIR/CANTONS_$a.zip" >&2; exit 1; }
done
[[ -d "$NOMDIR" ]] || { echo "manquant : $NOMDIR" >&2; exit 1; }

echo "Base   : $PGDATABASE"
echo "Racine : $RACINE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# 1. Shapefiles Gay → PostGIS
#
# Les .prj de TRF-GIS annoncent bien du Lambert-93, mais on ne reprojette pas :
# les coordonnées SONT en 2154 (cl_x ≈ 1 062 200, cl_y ≈ 6 325 700), donc
# `-a_srs` et pas `-t_srs`. Même choix que pour GEOFLA dans le README.
# ---------------------------------------------------------------------------
for a in "${ANNEES[@]}"; do
    echo
    echo "--- CANTONS_$a ---"
    unzip -o -q "$SHPDIR/CANTONS_$a.zip" -d "$TMP/gay_$a"
    SHP="$(find "$TMP/gay_$a" -iname '*.shp' | head -1)"
    [[ -n "$SHP" ]] || { echo "aucun .shp dans CANTONS_$a.zip" >&2; exit 1; }

    echo "  source   : $(basename "$SHP")"
    echo "  SRS lu   : $(ogrinfo -so -al "$SHP" 2>/dev/null | grep -m1 -E 'PROJCRS|PROJCS' || echo 'aucun .prj')"

    SHAPE_ENCODING=ISO-8859-1 ogr2ogr -f PostgreSQL "PG:dbname=$PGDATABASE" "$SHP" \
        -nln "histgis.ctrl_gay_$a" -nlt MULTIPOLYGON \
        -lco GEOMETRY_NAME=geom \
        -a_srs EPSG:2154 -overwrite
    echo "  chargé   : histgis.ctrl_gay_$a"
done

# ---------------------------------------------------------------------------
# 2. Correspondance canton réel → pseudo-canton
#
# COG_CANTONS_YYYY_MAPPING.tab ne liste QUE les exceptions : les cantons
# urbains regroupés sous un pseudo-canton unique (Montluçon-Est et
# Montluçon-Ouest → pseudo-canton « Montluçon », code 0380). Pour tous les
# autres cantons, deppct = depct — c'est 08_controle_gay.sql qui pose cette
# identité par défaut, ici on ne charge que le fichier.
#
# Encodage : les noms propres sont abîmés dans la source (accents non
# décodables). Sans importance, la comparaison ne porte que sur les codes ;
# on lit en latin-1, qui n'échoue jamais, et on garde les noms tels quels.
# ---------------------------------------------------------------------------
echo
echo "--- correspondance depct → deppct ---"
python3 - "$NOMDIR" "$TMP/ctrl_mapping.csv" <<'PY'
import csv, pathlib, re, sys

src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
fichiers = sorted(src.glob("COG_CANTONS_*_MAPPING.tab"))
if not fichiers:
    sys.exit(f"aucun COG_CANTONS_*_MAPPING.tab dans {src}")

n = 0
with dst.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["annee", "dep", "depct", "ct_name", "deppct", "pct_name"])
    for f in fichiers:
        annee = int(re.search(r"(\d{4})", f.name).group(1))
        lignes = f.read_text(encoding="latin-1").splitlines()
        entete = [c.strip().strip('"') for c in lignes[0].split("\t")]
        idx = {c: i for i, c in enumerate(entete)}
        for col in ("dep", "depct", "deppct"):
            if col not in idx:
                sys.exit(f"{f.name} : colonne {col} absente")
        for ligne in lignes[1:]:
            if not ligne.strip():
                continue
            ch = [c.strip().strip('"') for c in ligne.split("\t")]
            if len(ch) < len(entete):
                continue
            w.writerow([annee, ch[idx["dep"]], ch[idx["depct"]],
                        ch[idx.get("ct_name", 0)], ch[idx["deppct"]],
                        ch[idx.get("pct_name", 0)]])
            n += 1
print(f"  {len(fichiers)} fichiers, {n} regroupements urbains")
PY

# ---------------------------------------------------------------------------
# 3. Comparaison
# ---------------------------------------------------------------------------
echo
{
    psql -v ON_ERROR_STOP=1 -q \
         -v mapping="$TMP/ctrl_mapping.csv" \
         -f "$ICI/08_controle_gay.sql"
    psql -v ON_ERROR_STOP=1 -q -f "$ICI/09_ecart_detail.sql"
    psql -v ON_ERROR_STOP=1 -q -f "$ICI/10_couverture.sql"
} | tee "$RACINE/rapport_controle_gay.txt"

# ---------------------------------------------------------------------------
# 4. Export cartographique des divergences
#
# Un tableau d'IoU ne dit pas OÙ ça diverge. Le GeoPackage contient la
# différence symétrique de chaque pseudo-canton apparié : à ouvrir dans QGIS
# par-dessus les deux couches pour voir de quelles communes il s'agit.
# ---------------------------------------------------------------------------
echo
echo "--- export QGIS ---"
GPKG="$RACINE/controle_gay.gpkg"
rm -f "$GPKG"

ogr2ogr -f GPKG "$GPKG" "PG:dbname=$PGDATABASE" -nln ecarts -nlt MULTIPOLYGON -sql "
    SELECT e.annee, e.deppct, e.dep, e.pct_name, e.iou, e.km2_nous, e.km2_eux,
           e.cantons,
           ST_Multi(ST_CollectionExtract(
               ST_MakeValid(ST_SymDifference(n.geom, x.geom)), 3)) AS geom
    FROM   histgis.ctrl_ecart e
    JOIN   histgis.ctrl_nous n USING (annee, deppct)
    JOIN   histgis.ctrl_eux  x USING (annee, deppct)
    WHERE  e.statut = 'apparie' AND e.iou < 0.9999
      AND  NOT ST_IsEmpty(ST_SymDifference(n.geom, x.geom))"

# Passer par -sql plutôt que par le nom de table : ogr2ogr ne sait pas
# reprendre une clé primaire à deux colonnes et s'en plaint sans rien casser.
ogr2ogr -f GPKG -update "$GPKG" "PG:dbname=$PGDATABASE" -nln nous -nlt MULTIPOLYGON \
    -sql "SELECT annee, deppct, n_cantons, cantons, n_sans_geom, geom FROM histgis.ctrl_nous"

ogr2ogr -f GPKG -update "$GPKG" "PG:dbname=$PGDATABASE" -nln eux -nlt MULTIPOLYGON \
    -sql "SELECT annee, deppct, dep, pct_name, n_polygones, n_pseudo, codes_gay, geom FROM histgis.ctrl_eux"

# Écarts au niveau département : c'est là que se voit le territoire couvert
# d'un seul côté, invisible canton par canton.
ogr2ogr -f GPKG -update "$GPKG" "PG:dbname=$PGDATABASE" -nln ecarts_dep -nlt MULTIPOLYGON \
    -sql "SELECT annee, dep, km2_nous, km2_gay, km2_nous_seul, km2_gay_seul, iou,
                 geom_ecart AS geom
          FROM   histgis.ctrl_dep
          WHERE  iou < 0.9999 AND geom_ecart IS NOT NULL
            AND  NOT ST_IsEmpty(geom_ecart)"

ogr2ogr -f GPKG -update "$GPKG" "PG:dbname=$PGDATABASE" -nln non_couvert -nlt MULTIPOLYGON \
    -sql "SELECT annee, insee_com, nom_comm, dep, km2, pct_gay, geom
          FROM   histgis.ctrl_non_couvert"

echo "  écrit : $GPKG (couches : ecarts, ecarts_dep, non_couvert, nous, eux)"
echo "  (les avertissements « multi-column primary key » sont sans effet)"

echo
echo "Terminé."
echo "  Rapport : $RACINE/rapport_controle_gay.txt"
echo "  Carte   : $GPKG"

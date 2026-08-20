#!/usr/bin/env bash
# ============================================================================
# histgis — reconstruction complète de la base, géométries comprises.
#
#   cd sql && ./rebuild.sh
#
# Enchaîne : load.sh (01→04) → GEOFLA → 05 → 06 → 07 → 11 → 15.
#
# 11 et 15 sont les deux correctifs de couverture, et ils doivent être rejoués
# ici : load.sh repart d'un DROP SCHEMA, donc leurs atomes et rattachements
# disparaissent avec le reste. Les oublier ne casse rien — la base est
# simplement amputée de 522 km², en silence.
# DESTRUCTIF : load.sh fait DROP SCHEMA histgis CASCADE.
#
# À lancer après toute modification de `geom_correspondance.csv` ou des CSV de
# `build/` — ces fichiers sont lus par 02_load.sql, donc rien ne sert de
# rejouer 05 seul.
#
# Le contrôle indépendant n'est PAS enchaîné ici : ./controle_gay.sh, à part.
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
export PGDATABASE="${PGDATABASE:-histgis}"

PSQL="psql -v ON_ERROR_STOP=1 -q"

command -v ogr2ogr >/dev/null || { echo "ogr2ogr introuvable (apt install gdal-bin)" >&2; exit 1; }

# --- localisation des deux fichiers externes -------------------------------
SHP="$(find "$RACINE/sources/geofla" -iname 'COMMUNE.SHP' -print -quit 2>/dev/null || true)"
[[ -n "$SHP" ]] || {
    echo "COMMUNE.SHP introuvable sous $RACINE/sources/geofla" >&2
    echo "  python3 trfgis_fetch_inspect.py fetch repro \\" >&2
    echo "      --match '^COMMUNE\\.(SHP|SHX|DBF|PRJ)\$' --dest ./sources/geofla" >&2
    exit 1
}

MVT="$(find "$RACINE" -maxdepth 2 -name 'v_mvt_commune_*.csv' -print -quit 2>/dev/null || true)"
[[ -n "$MVT" ]] || {
    echo "v_mvt_commune_*.csv introuvable sous $RACINE" >&2
    echo "  curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv" >&2
    exit 1
}

echo "Base   : $PGDATABASE"
echo "Racine : $RACINE"
echo "GEOFLA : ${SHP#$RACINE/}"
echo "INSEE  : ${MVT#$RACINE/}"
echo

# --- 1. attributions -------------------------------------------------------
echo "=== 1/6 attributions (01 → 04) ==="
"$ICI/load.sh" "$RACINE" > /dev/null
echo "    fait — rapport dans rapport_chargement.txt"

# --- 2. trame communale ----------------------------------------------------
echo "=== 2/6 trame GEOFLA 2011 ==="
SHAPE_ENCODING=ISO-8859-1 ogr2ogr -f PostgreSQL "PG:dbname=$PGDATABASE" "$SHP" \
    -nln histgis.geofla_commune -nlt MULTIPOLYGON \
    -lco GEOMETRY_NAME=geom -a_srs EPSG:2154 -overwrite
echo "    fait"

# --- 3 à 5. géométries et correctifs ---------------------------------------
echo "=== 3/6 géométries (05) ==="
$PSQL -f "$ICI/05_geom.sql"

echo "=== 4/6 communes disparues (06, 07) ==="
$PSQL -v mvt="$MVT" -f "$ICI/06_insee_mvt.sql"
$PSQL -f "$ICI/07_reliquat.sql"

echo "=== 5/6 scissions 1870-1940 (11) ==="
$PSQL -f "$ICI/11_scission.sql"

echo "=== 6/6 communes nées après la série (15) ==="
$PSQL -f "$ICI/15_creation_arriere.sql"

echo
echo "Terminé. Pour noter le résultat : ./controle_gay.sh"

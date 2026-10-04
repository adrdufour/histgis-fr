#!/usr/bin/env bash
# Charge les trames d'outre-mer dans PostGIS, en EPSG:4326.
#
# À lancer AVANT sql/40_outremer.sql, qui refuse de démarrer sans ces tables.
#
#   bash sql/charger_outremer.sh            # dbname=histgis par défaut
#   HISTGIS_DSN="dbname=histgis" bash sql/charger_outremer.sh
#
# Pourquoi un script et pas une ligne de commande
# -----------------------------------------------
# Les cinq lots GEOFLA sont chacun dans leur propre projection, et il faut les
# empiler dans une seule table : le premier en -overwrite, les suivants en
# -append. C'est une boucle, donc un fichier — la même consigne en commentaire
# n'était pas exécutable, et le garde-fou de 40_outremer.sql s'est déclenché
# pour cette raison.
#
# L'encodage des DBF
# ------------------
# Les shapefiles GEOFLA sont en ISO-8859-1 et ne portent pas de fichier .cpg.
# Sans `--config SHAPE_ENCODING`, ogr2ogr les lit comme de l'UTF-8 et refuse
# d'écrire dès la première commune accentuée — « Préfecture de région » pour
# Dzaoudzi. Le projet connaît déjà ce piège : `37_reparer_encodage.sql` répare
# les dégâts après coup. Ici on le prend en amont, ce qui vaut mieux.
#
# `-t_srs` et non `-a_srs`
# ------------------------
# Le premier reprojette, le second se contente de réétiqueter. Mettre -a_srs
# EPSG:4326 sur des coordonnées UTM poserait la Guadeloupe à des milliers de
# kilomètres de chez elle, avec des géométries parfaitement valides. C'est
# exactement le genre d'erreur silencieuse que le projet traque ; 40_outremer.sql
# vérifie d'ailleurs la position du centroïde guadeloupéen après coup.

set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$RACINE/sources/outremer"
PG="PG:${HISTGIS_DSN:-dbname=histgis}"

command -v ogr2ogr >/dev/null || {
  echo "ogr2ogr absent — installer gdal-bin." >&2; exit 1; }

charge() {   # $1 = couche (COMMUNE|CANTON), $2 = table cible
  local couche="$1" table="$2" n=0
  # tri stable : l'ordre des lots ne change rien au résultat, mais un ordre
  # reproductible rend les décomptes comparables d'une exécution à l'autre
  local fichiers
  mapfile -t fichiers < <(find "$SRC" -path "*2015-03-04*" \
      -ipath "*/$couche/*" -iname "$couche.SHP" | sort)

  [[ ${#fichiers[@]} -eq 5 ]] || {
    echo "!! ${#fichiers[@]} lots $couche trouvés, 5 attendus." >&2
    printf '   %s\n' "${fichiers[@]}" >&2
    echo "   Lancer d'abord sources/outremer/telecharger_outremer.sh" >&2
    exit 1; }

  for f in "${fichiers[@]}"; do
    if [[ $n -eq 0 ]]; then mode=(-overwrite); else mode=(-append); fi
    ogr2ogr -f PostgreSQL "$PG" "$f" \
      -nln "histgis.$table" -nlt MULTIPOLYGON \
      -lco GEOMETRY_NAME=geom -t_srs EPSG:4326 "${mode[@]}" \
      --config SHAPE_ENCODING ISO-8859-1 \
      --config PG_USE_COPY YES
    n=$((n+1))
    echo "  ✓ $(basename "$(dirname "$(dirname "$f")")")"
  done
  echo "$table : $n lots chargés"
}

echo "=== COMMUNE -> histgis.om_commune_src ==="
charge COMMUNE om_commune_src
echo
echo "=== CANTON -> histgis.om_canton_src ==="
charge CANTON om_canton_src

echo
echo "=== Vérification ==="
psql "${HISTGIS_DSN:-dbname=histgis}" -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;
SELECT 'om_commune_src' AS table, count(*) AS n,
       count(DISTINCT left(insee_com,3)) AS departements,
       (SELECT DISTINCT ST_SRID(geom) FROM om_commune_src) AS srid
FROM   om_commune_src
UNION ALL
SELECT 'om_canton_src', count(*), count(DISTINCT code_dept),
       (SELECT DISTINCT ST_SRID(geom) FROM om_canton_src)
FROM   om_canton_src;
SQL

echo
echo "Attendu : om_commune_src 129 lignes, 5 départements, SRID 4326."
echo "          om_canton_src 113 lignes (dont 28 agrégats codés 90-99),"
echo "          1 seul 'département' — CODE_DEPT vaut 97 pour les cinq."
echo
echo "Ensuite, avec la base explicite — psql sans -d se connecterait à une base"
echo "portant votre nom d'utilisateur, qui n'existe pas :"
echo
echo "    psql -d ${HISTGIS_DSN:-histgis} -v ON_ERROR_STOP=1 -f sql/40_outremer.sql"

#!/usr/bin/env bash
# Charge les trames communales du Pacifique dans PostGIS, en EPSG:4326.
#
# À lancer AVANT sql/135_pacifique.sql, qui refuse de démarrer sans ces tables.
#
#   bash sql/charger_pacifique.sh            # dbname=histgis par défaut
#   HISTGIS_DSN="dbname=histgis" bash sql/charger_pacifique.sh
#
# Deux sources, deux licences, et ni l'une ni l'autre n'est celle du .gdb
# --------------------------------------------------------------------------
# * Polynésie française — ISPF, « Limites géographiques administratives »
#   (data.gouv.fr), couche `Com` de `shapefiles.zip` : 48 communes, en RGPF
#   (EPSG:4687). **ODbL.** Tranché le 25 octobre 2026 : une carte rendue est une
#   « œuvre produite » au sens de l'ODbL (§ 4.5), librement licenciable à
#   condition de citer la base ; elle peut donc aller sur Commons en
#   CC BY-SA 4.0 avec la mention de l'ISPF. Ce qui serait soumis au partage à
#   l'identique, c'est la base dérivée elle-même — `om_atom_geom` pour la
#   Polynésie — si on la redistribuait. On ne la redistribue pas.
#
# * Nouvelle-Calédonie — gouvernement de la Nouvelle-Calédonie, « Communes de
#   la Nouvelle-Calédonie (limites communales terrestres simplifiées) »,
#   data.gouv.nc, **Licence Ouverte 2.0**, 33 communes, en WGS84. Téléchargé
#   le 25 octobre 2026 avec ses métadonnées dans
#   `sources/nouvelle_caledonie/communes_gnc/`.
#
#   Le `BDADMIN-NC.gdb` du DITTT, à côté, N'EST PAS chargé : ses CGU de
#   juillet 2017 « excluent toute exploitation commerciale des Données », ce
#   qui ferme Commons. Le jeu simplifié du portail est tiré de la même
#   BDADMIN-NC (ses métadonnées y renvoient), mais il est publié sous une autre
#   licence, et c'est celle-là qui s'applique à ce qu'on en tire.
#
# `-t_srs` et non `-a_srs`, pour la raison donnée dans charger_outremer.sh.
# Ici l'écart serait invisible (RGPF et WGS84 diffèrent de moins d'un mètre),
# mais la règle ne dépend pas de la taille de l'erreur qu'elle évite.

set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PF="$RACINE/sources/polynesie/shapefiles.zip"
NC="$RACINE/sources/nouvelle_caledonie/communes_gnc/communes-nc-limites-terrestres-simplifiees.geojson"
PG="PG:${HISTGIS_DSN:-dbname=histgis}"

command -v ogr2ogr >/dev/null || {
  echo "ogr2ogr absent — installer gdal-bin." >&2; exit 1; }

[[ -f "$PF" ]] || { echo "!! $PF absent." >&2; exit 1; }
[[ -f "$NC" ]] || {
  echo "!! $NC absent. Le récupérer :" >&2
  echo "   curl -o '$NC' 'https://data.gouv.nc/api/explore/v2.1/catalog/datasets/communes-nc-limites-terrestres-simplifiees/exports/geojson'" >&2
  exit 1; }

echo "=== Polynésie (ISPF, Com) -> histgis.om_pf_src ==="
ogr2ogr -f PostgreSQL "$PG" "/vsizip/$PF/Com.shp" \
  -nln histgis.om_pf_src -nlt MULTIPOLYGON -overwrite \
  -lco GEOMETRY_NAME=geom -t_srs EPSG:4326 \
  -select IDCom,IDSub,Commune,Sub \
  --config PG_USE_COPY YES

echo "=== Nouvelle-Calédonie (data.gouv.nc) -> histgis.om_nc_src ==="
ogr2ogr -f PostgreSQL "$PG" "$NC" \
  -nln histgis.om_nc_src -nlt MULTIPOLYGON -overwrite \
  -lco GEOMETRY_NAME=geom -t_srs EPSG:4326 \
  -select code_com,nom,nom_minus \
  --config PG_USE_COPY YES

echo
echo "=== Recouture et allègement -> geom_carte ==="
# psycopg2 et shapely >= 2.1 : l'environnement `histgis`, pas le python3 du
# système. `HISTGIS_PY` pour en désigner un autre.
PY="${HISTGIS_PY:-python3}"
"$PY" -c "import shapely, psycopg2; assert hasattr(shapely, 'coverage_simplify')" 2>/dev/null || {
  echo "!! $PY n'a pas psycopg2 et shapely >= 2.1 — conda activate histgis," >&2
  echo "   ou HISTGIS_PY=~/miniforge3/envs/histgis/bin/python" >&2
  exit 1; }
"$PY" -I "$RACINE/sql/trame_pacifique.py" ${HISTGIS_DSN:+--dsn "$HISTGIS_DSN"}

echo
echo "=== Vérification ==="
psql "${HISTGIS_DSN:-dbname=histgis}" -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;
SELECT 'om_pf_src' AS table, count(*) AS n,
       (SELECT DISTINCT ST_SRID(geom) FROM om_pf_src) AS srid,
       round(sum(ST_Area(geom::geography))/1e6) AS km2
FROM   om_pf_src
UNION ALL
SELECT 'om_nc_src', count(*), (SELECT DISTINCT ST_SRID(geom) FROM om_nc_src),
       round(sum(ST_Area(geom::geography))/1e6)
FROM   om_nc_src;
SQL

echo
echo "Attendu : om_pf_src 48 lignes, om_nc_src 33 lignes, SRID 4326."
echo
echo "    psql -d ${HISTGIS_DSN:-histgis} -f sql/135_pacifique.sql              # à blanc"
echo "    psql -d ${HISTGIS_DSN:-histgis} -1 -v appliquer=1 -f sql/135_pacifique.sql"

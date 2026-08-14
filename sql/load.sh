#!/usr/bin/env bash
# ============================================================================
# histgis — chargement complet dans PostGIS.
#
#   ./load.sh                       # base histgis en local, dossier parent
#   PGDATABASE=magine ./load.sh     # autre base
#   ./load.sh /autre/chemin/projet_carte
#
# Variables libpq habituelles (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE).
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
export PGDATABASE="${PGDATABASE:-histgis}"

for f in build/atom.csv build/unit_canton.csv build/unit_circo.csv \
         build/membership_canton.csv build/membership_circo.csv \
         build/unit_renames.csv build/circo_regime.csv \
         build/attribution_ambigue.csv build/communes_fractionnees.csv \
         build/pseudo_multi_communes.csv geom_correspondance.csv; do
    [[ -f "$RACINE/$f" ]] || { echo "manquant : $RACINE/$f" >&2; exit 1; }
done

echo "Base   : $PGDATABASE"
echo "Racine : $RACINE"

PSQL="psql -v ON_ERROR_STOP=1 -q"

$PSQL -f "$ICI/01_schema.sql"
$PSQL -v racine="$RACINE" -f "$ICI/02_load.sql"
$PSQL -f "$ICI/03_functions.sql"
$PSQL -f "$ICI/04_checks.sql" | tee "$RACINE/rapport_chargement.txt"

echo
echo "Terminé. Rapport de recette : $RACINE/rapport_chargement.txt"

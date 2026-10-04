#!/usr/bin/env bash
# ============================================================================
# histgis — load_cog.sh : charge les 14 millésimes du COG, puis mesure
#
#   cd sql && ./load_cog.sh
#
# Enchaîne 22 (tables d'accueil), les 28 \copy, puis 23 (diagnostic).
# Rien n'est écrit dans le modèle : ni `atom`, ni `unit`, ni `membership`.
#
# Deux pièges de format, traités ici plutôt que subis plus tard :
#
#   * Les fichiers sont en CRLF. Le dernier champ de chaque ligne emporterait
#     un \r ; on le retire après chaque copie.
#   * Les noms contiennent des apostrophes — « (L') Abergement-Clémenciat ».
#     En CSV, le guillemet par défaut casserait la lecture : on le règle sur un
#     caractère qui n'apparaît jamais dans le fichier (backspace).
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
COG="$RACINE/sources/cog"
export PGDATABASE="${PGDATABASE:-histgis}"
PSQL="psql -v ON_ERROR_STOP=1 -q"

[[ -d "$COG" ]] || { echo "dossier $COG introuvable — lancer cog/fetch_cog.sh avant" >&2; exit 1; }

echo "Base   : $PGDATABASE"
echo "COG    : $COG"
echo

echo "=== 1/3 tables d'accueil ==="
$PSQL -f "$ICI/22_cog_stage.sql"

echo "=== 2/3 chargement des millésimes ==="
# ENCODING : WIN1252, et non LATIN1.
#
# Les deux jeux sont identiques SAUF sur la plage 0x80-0x9F, que Latin-1 laisse
# aux caractères de contrôle et que Windows-1252 remplit — œ, Œ, les
# apostrophes typographiques, les tirets cadratins. Les fichiers du COG sont en
# Windows-1252.
#
# Lus en LATIN1, les noms contenant `œ` recevaient donc U+009C, un caractère de
# contrôle : « Vanduvre-lès-Nancy », « Nux-les-Mines ». Quinze
# valeurs atteintes, toutes sur ce seul caractère — un même canton se
# retrouvait sous deux graphies, ce qui dédouble tout comptage par nom et fait
# échouer tout appariement.
#
# Repéré par `36_recette_annexe_vi.sql` § 6, réparé rétroactivement par
# `37_reparer_encodage.sql`. Ce correctif-ci tarit la source : sans lui, tout
# rebuild réintroduit le défaut.
COPYOPT="WITH (FORMAT csv, DELIMITER E'\t', HEADER true, ENCODING 'WIN1252', QUOTE E'\b', ESCAPE E'\b')"

for annee in $(seq 1999 2012); do
    fr=$(ls "$COG/$annee"/*france*"$annee"*.txt 2>/dev/null | head -1 || true)
    ca=$(ls "$COG/$annee"/*canton*"$annee"*.txt 2>/dev/null | head -1 || true)
    [[ -n "$fr" && -n "$ca" ]] || { echo "  $annee : fichier manquant, millésime ignoré" >&2; continue; }

    # chaque psql ouvre une session neuve : le search_path de 22 n'y survit
    # pas, et \copy s'exécute côté client. On qualifie donc les tables.
    $PSQL <<SQL
SET search_path TO histgis, public;
\\copy histgis.cog_commune_src (actual,cheflieu,cdc,rang,reg,dep,com,ar,ct,modif,pole,tncc,artmaj,ncc,artmin,nccenr,articlct,nccct) FROM '$fr' $COPYOPT
UPDATE histgis.cog_commune_src SET annee = $annee, nccct = rtrim(nccct, E'\r') WHERE annee IS NULL;

\\copy histgis.cog_canton_src (region,dep,ar,canton,typct,cheflieu,tncc,artmaj,ncc,artmin,nccenr) FROM '$ca' $COPYOPT
UPDATE histgis.cog_canton_src SET annee = $annee, nccenr = rtrim(nccenr, E'\r') WHERE annee IS NULL;
SQL
    printf '  %s ok\n' "$annee"
done

$PSQL -c "CREATE INDEX cog_commune_idx ON histgis.cog_commune_src (annee, dep, com);
          CREATE INDEX cog_canton_idx  ON histgis.cog_canton_src  (annee, dep, canton);
          ANALYZE histgis.cog_commune_src; ANALYZE histgis.cog_canton_src;"

echo "=== 3/3 diagnostic ==="
$PSQL -f "$ICI/23_cog_diag.sql"

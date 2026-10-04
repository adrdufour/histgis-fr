#!/usr/bin/env bash
# ============================================================================
# rejouer_circo.sh — reposer toute la couche des circonscriptions, dans l'ordre
#
#   cd sql && ./rejouer_circo.sh
#
# Pourquoi ce script existe
# -------------------------
# `27` et `28` suppriment leurs UNITÉS avant de les recréer. Toute autre table
# qui référence ces unités bloque la suppression :
#
#   ERROR: update or delete on table "unit" violates foreign key constraint
#   DETAIL: Key (unit_id, niveau)=(59-13@1986, circo) is still referenced
#
# Quatre fichiers posent aujourd'hui des `membership` sur ces unités :
# `40_scission_circo`, `43_circo_fraction`, `47_circo_mere` et
# `49_circo_1986_partage`. Il faut donc retirer leur travail AVANT, et le
# rejouer APRÈS.
#
# Le 20 août 2026, l'ignorer a vidé la couche entière : `27` et `28` se sont
# arrêtés entre leur suppression et leur pose, et la base est restée avec 118
# rattachements de circonscription au lieu de 37 000. Rien n'était perdu — tout
# est tracé — mais rien n'était visible non plus.
#
# L'ordre, et ses raisons
# -----------------------
#   1. retirer les dépendants, par leur trace (réversible, jamais par période) ;
#   2. `28` AVANT `27` : le nettoyage de `28` couvre 1986 → 2012-06-10, celui de
#      `27` commence à 2012-06-10. Dans ce sens ils ne se marchent pas dessus ;
#   3. `40_outremer`, qui vit dans ses propres tables `om_*` mais partage les
#      mêmes bornes ;
#   4. `49` — l'atlas Gaudillère lève les indéterminations que `28` laisse ;
#   5. `47` — la mère, réponse directe ;
#   6. `40_scission_circo` EN DERNIER — les voisins, réponse par procuration.
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
PSQL="psql -v ON_ERROR_STOP=1 -q -d histgis"

etape() { printf '\n\033[1m── %s\033[0m\n' "$1"; }

cd "$RACINE"

etape "0 — retrait des rattachements dépendants (par leur trace)"
$PSQL <<'SQL'
SET search_path TO histgis, public;
DO $$
DECLARE t text; n bigint; total bigint := 0;
BEGIN
    FOREACH t IN ARRAY ARRAY['circo_partage_trace', 'circo_mere_trace',
                             'scission_circo_trace', 'circo_fraction_trace']
    LOOP
        IF to_regclass('histgis.' || t) IS NULL THEN CONTINUE; END IF;
        EXECUTE format(
            'DELETE FROM membership m USING %I t WHERE t.membership_id = m.membership_id',
            t);
        GET DIAGNOSTICS n = ROW_COUNT;
        EXECUTE format('TRUNCATE %I', t);
        RAISE NOTICE '  % : % rattachement(s) retire(s)', rpad(t, 22), n;
        total := total + n;
    END LOOP;
    RAISE NOTICE '  total : %', total;
END $$;
SQL

etape "28 — circonscriptions de 1986"
$PSQL -v circo="$RACINE/circo/circo_1986.csv" -f "$ICI/28_circo_1986.sql"

etape "27 — circonscriptions de 2009"
$PSQL -v circo="$RACINE/circo/circo_2012.csv" -f "$ICI/27_circo_2012.sql"

# L'outre-mer vit dans ses propres tables `om_*` et exige un chargement
# ogr2ogr préalable (`om_commune_src`). Son absence ne doit pas arrêter la
# métropole : les deux espaces ne partagent aucune table, seulement les bornes.
if $PSQL -tAc "SELECT to_regclass('histgis.om_commune_src') IS NOT NULL" \
        | grep -q '^t$'; then
    etape "40 — outre-mer"
    $PSQL -v circo_om="$RACINE/circo/circo_outremer_1986_2012.csv" \
          -f "$ICI/40_outremer.sql"
else
    echo "  om_commune_src absente — outre-mer sauté (chargement ogr2ogr requis)." >&2
    echo "  Sans conséquence ici : les tables om_* sont indépendantes." >&2
fi

if [ -f "$RACINE/circo/circo_1986_partage.csv" ]; then
    etape "49 — cantons partagés de 1986 (atlas Gaudillère)"
    $PSQL -v partage="$RACINE/circo/circo_1986_partage.csv" \
          -f "$ICI/49_circo_1986_partage.sql"
else
    echo "  circo_1986_partage.csv absent — 49 sauté." >&2
    echo "  Pour l'engendrer : python3 circo/resoudre_1986_partage.py" >&2
fi

if [ -f "$RACINE/circo/circo_1986_correctifs.csv" ]; then
    etape "51 — correctif du découpage de 1986 (Ain)"
    $PSQL -v appliquer=1 -v correctif="$RACINE/circo/circo_1986_correctifs.csv" \
          -f "$ICI/51_circo_1986_correctif.sql"
fi

etape "47 — circo de la mère, quand les voisins se taisent"
$PSQL -f "$ICI/47_circo_mere.sql"

etape "40 — trous de la couche circo, par les voisins de canton"
$PSQL -f "$ICI/40_scission_circo.sql"

cat <<'FIN'

──────────────────────────────────────────────────────────────────────
Couche circo reposée. Repères attendus :

    à 1990   ~37 200 rattachements   (découpage de 1986)
    à 2011   ~37 200                 (idem : il court jusqu'en juin 2012)
    à 2012-12 ~37 300                (découpage de 2009)

Si l'un de ces chiffres est de l'ordre de la centaine, la chaîne s'est
arrêtée entre une suppression et une pose : relancer ce script, rien
n'est perdu.

Puis :

    python3 cartes/export_web.py
FIN

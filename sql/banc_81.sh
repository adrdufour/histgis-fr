#!/usr/bin/env bash
# ============================================================================
# banc_81.sh — banc d'essai de sql/81 sur un PostgreSQL jetable
#
# Même dispositif que `banc_75.sh` : schéma réel sans postgis, les deux
# `EXCLUDE` remplacées par des déclencheurs équivalents, données synthétiques
# de `banc_75_donnees.sql`, vrais CSV du dépôt.
#
# CE QU'IL AJOUTE À `banc_75.sh` : il joue la chaîne ENTIÈRE jusqu'à `81`,
# c'est-à-dire `79` (report arrière) PUIS `81` (report avant) dans la même
# base. C'est le seul moyen de vérifier ce que ni l'un ni l'autre ne peut dire
# seul : **que les deux reports ne se recouvrent pas**. `79` descend au dernier
# acte, `81` monte au premier ; s'ils se croisaient, la contrainte
# `membership_non_chevauchant` le refuserait, et on veut le savoir ici plutôt
# que sur la base d'Adrien.
#
# La cible existe déjà : `banc_75_donnees.sql` § 5 pose un jalon de 1968 sur
# [1968-01-01, 1969-01-01), dont un sixième des communes est délibérément
# rattaché à un autre canton. `81` a donc de quoi lire, ET son § 5 a de quoi
# mesurer — `pct_jamais_nommes` ne doit pas y valoir 100 %.
# *Trois fois en deux jours un banc a mesuré un tir sans cible ; celui-ci en a
# une, et elle est imparfaite exprès.*
#
# Ce qu'il prouve : la syntaxe, les jointures, les garde-fous, les contraintes,
#                   la rejouabilité, la non-collision de `79` et `81`.
# Ce qu'il ne prouve pas : les effectifs, qui dépendent des vraies couches.
#
#   bash sql/banc_81.sh        (depuis la racine du dépôt)
# ============================================================================
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
BANC="${BANC:-/tmp/banc_histgis_81}"
PGBIN="${PGBIN:-}"

if [ -z "$PGBIN" ]; then
    PGBIN="$(python3 - <<'PY' 2>/dev/null || true
import os, pgserver
print(os.path.join(os.path.dirname(pgserver.__file__), 'pginstall', 'bin'))
PY
)"
fi
if [ -z "$PGBIN" ] || [ ! -x "$PGBIN/psql" ]; then
    echo "Aucun PostgreSQL trouvé. Soit un serveur local (PGBIN=/usr/lib/postgresql/16/bin),"
    echo "soit : pip install pgserver --break-system-packages"
    exit 1
fi
export PATH="$PGBIN:$PATH"

DATA="$BANC/pgdata"
rm -rf "$BANC"; mkdir -p "$BANC"
initdb -D "$DATA" -U postgres --no-sync >/dev/null
pg_ctl -D "$DATA" -o "-k $DATA -h ''" -l "$BANC/pg.log" start >/dev/null
trap 'pg_ctl -D "$DATA" stop -m immediate >/dev/null 2>&1 || true' EXIT

export PGHOST="$DATA" PGUSER=postgres
psql -d postgres -q -c "CREATE DATABASE histgis;"
export PGDATABASE=histgis

cd "$RACINE"

sed -e 's/^CREATE EXTENSION IF NOT EXISTS postgis;/-- (banc) postgis hors sujet/' \
    -e 's/^CREATE EXTENSION IF NOT EXISTS btree_gist;.*$/-- (banc) btree_gist remplacée par des déclencheurs/' \
    -e 's/EXCLUDE USING gist (unit_id WITH =, periode WITH \&\&)/CHECK (true) \/* banc : voir déclencheur *\//' \
    -e 's/EXCLUDE USING gist (atom_id WITH =, niveau WITH =, periode WITH \&\&)/CHECK (true) \/* banc : voir déclencheur *\//' \
    sql/01_schema.sql > "$BANC/01_banc.sql"
psql -q -f "$BANC/01_banc.sql"

psql -q -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;

CREATE FUNCTION banc_membership_non_chevauchant() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = NEW.atom_id AND m.niveau = NEW.niveau
                  AND m.membership_id <> coalesce(NEW.membership_id, -1)
                  AND m.periode && daterange(NEW.valid_from, NEW.valid_to, '[)')) THEN
        RAISE EXCEPTION
          'membership_non_chevauchant (banc) : atome % niveau % déjà rattaché sur [%, %)',
          NEW.atom_id, NEW.niveau, NEW.valid_from, NEW.valid_to;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER banc_membership_excl BEFORE INSERT OR UPDATE ON membership
FOR EACH ROW EXECUTE FUNCTION banc_membership_non_chevauchant();

CREATE FUNCTION banc_unit_version_non_chevauchant() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM unit_version v
                WHERE v.unit_id = NEW.unit_id
                  AND v.unit_version_id <> coalesce(NEW.unit_version_id, -1)
                  AND v.periode && daterange(NEW.valid_from, NEW.valid_to, '[)')) THEN
        RAISE EXCEPTION 'unit_version_non_chevauchant (banc) : unité %', NEW.unit_id;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER banc_unit_version_excl BEFORE INSERT OR UPDATE ON unit_version
FOR EACH ROW EXECUTE FUNCTION banc_unit_version_non_chevauchant();
SQL

psql -q -f sql/03_functions.sql
psql -q -v ON_ERROR_STOP=1 -f sql/banc_75_donnees.sql
echo "== schéma et données synthétiques posés"

joue () {   # joue <fichier> <étiquette>
    if ! psql -v ON_ERROR_STOP=1 -f "$1" > "$BANC/$2.out" 2>&1; then
        echo "== ÉCHEC $2"; tail -40 "$BANC/$2.out"; exit 1
    fi
    echo "== $2 joué"
}

joue sql/72_registre_actes.sql              72
joue sql/74_yvelines_1967.sql               74
joue sql/75_composition_1973_1982.sql       75
joue sql/76_composition_salves_restantes.sql 76
python3 cantons/transferts_insee.py > "$BANC/transferts.out" 2>&1 || true
joue sql/77_transferts_dates.sql            77
joue sql/79_report_1999_arriere.sql         79
joue sql/81_report_1968_avant.sql           81

# --- ce que seul ce banc peut dire -----------------------------------------
echo
echo "== 1. les deux reports se recouvrent-ils ? (doit valoir 0)"
psql -c "SELECT count(*) AS chevauchements
           FROM histgis.membership a
           JOIN histgis.membership b
             ON a.atom_id = b.atom_id AND a.niveau = b.niveau
            AND a.membership_id < b.membership_id AND a.periode && b.periode
          WHERE a.niveau = 'canton';"

echo "== 2. qui a posé quoi"
psql -c "SELECT (SELECT count(*) FROM histgis.p75_trace WHERE quoi='membership') AS par_75,
                (SELECT count(*) FROM histgis.p76_trace WHERE quoi='membership') AS par_76,
                (SELECT count(*) FROM histgis.p77_trace WHERE quoi='membership') AS par_77,
                (SELECT count(*) FROM histgis.p79_trace WHERE quoi='membership') AS par_79,
                (SELECT count(*) FROM histgis.p81_trace WHERE quoi='membership') AS par_81;"

# ATTENTION À LA LECTURE — au banc, la couche de 1999 est bâtie DEPUIS les
# compositions de décrets, donc presque tout atome y est « nommé » et le
# dénominateur des jamais-nommés est minuscule. Le § 10 bis affiche pour cette
# raison une majorité de « non mesurable » et de « trop peu d'atomes » : c'est
# un artefact du banc, pas un défaut de `81`. Sur la vraie base, 3 065 atomes
# sont nommés sur 32 842. *Un banc calibré sur la source qu'il teste ne teste
# pas la source* — déjà écrit le 28 août à propos de la couche 1999 de `banc_75`.
echo "== 3. le taux mesuré du § 5 de 81 — il ne doit PAS valoir 100 %"
echo "      (un sixième du jalon synthétique est délibérément faux ;"
echo "       s'il rendait 100, c'est la mesure qui serait cassée)"
psql -c "SELECT count(*) AS departements,
                round(avg(pct_jamais_nommes), 1) AS taux_moyen,
                min(pct_jamais_nommes) AS mini, max(pct_jamais_nommes) AS maxi
           FROM histgis.p81_accord WHERE pct_jamais_nommes IS NOT NULL;"

echo "== 4. rejouabilité de 81 (le compte doit être identique)"
AVANT=$(psql -tAc "SELECT count(*) FROM histgis.p81_trace WHERE quoi='membership';")
psql -q -v ON_ERROR_STOP=1 -f sql/81_report_1968_avant.sql > "$BANC/81.rejeu.out" 2>&1 \
    || { echo "== ÉCHEC AU REJEU"; tail -40 "$BANC/81.rejeu.out"; exit 1; }
APRES=$(psql -tAc "SELECT count(*) FROM histgis.p81_trace WHERE quoi='membership';")
if [ "$AVANT" = "$APRES" ]; then
    echo "   $AVANT puis $APRES — idempotent"
else
    echo "   REJEU NON IDEMPOTENT : $AVANT puis $APRES"; exit 1
fi

echo "== 5. et 79 est-il intact après le passage de 81 ?"
psql -c "SELECT count(*) AS lignes_de_79_encore_en_base
           FROM histgis.p79_trace t
           JOIN histgis.membership m ON m.membership_id = t.cle::bigint
          WHERE t.quoi = 'membership';"

echo
cat "$BANC/81.out"

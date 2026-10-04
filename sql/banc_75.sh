#!/usr/bin/env bash
# ============================================================================
# banc_75.sh — banc d'essai de sql/75 sur un PostgreSQL jetable
#
# Pourquoi ce fichier existe : `72` et `73` ont été livrés le 28 août 2026
# SANS avoir été exécutés, faute de PostgreSQL dans l'environnement d'écriture.
# La réserve était honnête, mais elle ne devait pas devenir une habitude.
#
# Ce banc ne remplace pas la base d'Adrien : il ne contient ni géométrie, ni
# TRF-GIS, ni COG. Il monte le SCHÉMA RÉEL (01_schema.sql, sans postgis), y
# pose des données SYNTHÉTIQUES calibrées pour exercer chaque chemin de `75`
# — résolution, désaccord, collision, place occupée, Corse recodée — puis joue
# `72` et `75` sur les VRAIS CSV du dépôt.
#
# Ce qu'il prouve : la syntaxe, les jointures, les garde-fous, les contraintes.
# Ce qu'il ne prouve pas : les effectifs, qui dépendent de la vraie couche 1999.
#
#   bash sql/banc_75.sh        (depuis la racine du dépôt)
# ============================================================================
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
BANC="${BANC:-/tmp/banc_histgis}"
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

# --- le schéma réel, adapté au banc ----------------------------------------
# Deux extensions manquent au PostgreSQL embarqué : `postgis`, dont `75` n'a
# aucun besoin, et `btree_gist`, sans laquelle les deux contraintes EXCLUDE ne
# peuvent pas être créées. On ne les supprime pas : on les REMPLACE par des
# déclencheurs qui refusent exactement les mêmes lignes. Ce qui est éprouvé
# reste donc le comportement réel — un chevauchement fait échouer l'écriture.
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
echo "== schéma monté (EXCLUDE simulées par déclencheurs)"

# --- cm_atome et la couche 1999 synthétiques -------------------------------
# Un atome par code INSEE cité dans les compositions ; une unité de 1999 par
# canton de décret ; le rattachement 1999 recopie la composition du décret.
# On perturbe ensuite pour exercer les chemins de refus.
psql -q -v ON_ERROR_STOP=1 -f sql/banc_75_donnees.sql
echo "== données synthétiques posées"

# --- les vrais fichiers ----------------------------------------------------
psql -v ON_ERROR_STOP=1 -f sql/72_registre_actes.sql > "$BANC/72.out" 2>&1 \
    || { echo "ÉCHEC 72"; tail -30 "$BANC/72.out"; exit 1; }
echo "== 72 joué"

# `74` d'abord : lui aussi écrit dans `membership`, et sur une période que la
# salve de 1967 ne couvre pas mais que le voisinage frôle. Le faire jouer ici
# est le seul moyen de vérifier que les trois fichiers cohabitent.
STATUT=0
psql -v ON_ERROR_STOP=1 -f sql/74_yvelines_1967.sql > "$BANC/74.out" 2>&1 || STATUT=$?
echo "== 74 joué (statut $STATUT)"
[ "$STATUT" = 0 ] || tail -20 "$BANC/74.out"

psql -v ON_ERROR_STOP=1 -f sql/75_composition_1973_1982.sql > "$BANC/75.out" 2>&1 || STATUT=$?
echo "== 75 joué (statut $STATUT)"

# `76` — la longue traîne, sur la convention de `75`. Il est joué DANS LE
# MÊME banc, et pas dans un autre : ce qu'on veut éprouver, c'est que les deux
# fichiers cohabitent sans se marcher dessus dans le `membership`.
if [ "$STATUT" = 0 ]; then
    psql -v ON_ERROR_STOP=1 -f sql/76_composition_salves_restantes.sql \
        > "$BANC/76.out" 2>&1 || STATUT=$?
    echo "== 76 joué (statut $STATUT)"
    [ "$STATUT" = 0 ] || tail -30 "$BANC/76.out"
fi

# `77` — les transferts datés. Il écrit lui aussi dans `membership`, sur des
# périodes que `76` frôle : c'est exactement le genre de voisinage qu'un banc
# doit éprouver.
if [ "$STATUT" = 0 ]; then
    python3 cantons/transferts_insee.py > "$BANC/transferts.out" 2>&1 || true
    psql -v ON_ERROR_STOP=1 -f sql/77_transferts_dates.sql \
        > "$BANC/77.out" 2>&1 || STATUT=$?
    echo "== 77 joué (statut $STATUT)"
    [ "$STATUT" = 0 ] || tail -30 "$BANC/77.out"
fi

# REJOUABILITÉ — l'en-tête de `75` l'affirme, le banc le vérifie. Un fichier
# qui ne se rejoue pas ne se découvre qu'au pire moment, quand la chaîne est
# à demi reconstruite (leçon du 17 août 2026, `24` laissé en plan).
if [ "$STATUT" = 0 ]; then
    AVANT=$(psql -tAc "SELECT (SELECT count(*) FROM histgis.p75_trace WHERE quoi='membership')
                            + (SELECT count(*) FROM histgis.p76_trace WHERE quoi='membership')
                            + (SELECT count(*) FROM histgis.p77_trace WHERE quoi='membership');")
    psql -q -v ON_ERROR_STOP=1 -f sql/75_composition_1973_1982.sql > "$BANC/75.rejeu.out" 2>&1 || STATUT=$?
    psql -q -v ON_ERROR_STOP=1 -f sql/76_composition_salves_restantes.sql >> "$BANC/75.rejeu.out" 2>&1 || STATUT=$?
    psql -q -v ON_ERROR_STOP=1 -f sql/77_transferts_dates.sql >> "$BANC/75.rejeu.out" 2>&1 || STATUT=$?
    APRES=$(psql -tAc "SELECT (SELECT count(*) FROM histgis.p75_trace WHERE quoi='membership')
                            + (SELECT count(*) FROM histgis.p76_trace WHERE quoi='membership')
                            + (SELECT count(*) FROM histgis.p77_trace WHERE quoi='membership');")
    TOTAL=$(psql -tAc "SELECT count(*) FROM histgis.membership WHERE niveau='canton';")
    if [ "$STATUT" = 0 ] && [ "$AVANT" = "$APRES" ]; then
        echo "== rejeu : $AVANT puis $APRES rattachements — idempotent (membership total $TOTAL)"
    else
        echo "== REJEU EN ÉCHEC (statut $STATUT, $AVANT puis $APRES)"
        tail -20 "$BANC/75.rejeu.out"
        STATUT=${STATUT:-1}; [ "$STATUT" = 0 ] && STATUT=1
    fi
fi

# Le contrôle des titres ne dépend QUE de `72` — donc que des vrais CSV, pas
# de la couche de 1999 synthétique. Ses chiffres valent tels quels.
if [ "${TITRES:-}" = 1 ]; then
    echo "== contrôle des titres"
    psql -v ON_ERROR_STOP=1 -f sql/diag_titre_composition.sql
fi

# Un fichier de diagnostic, s'il en traîne un : on veut pouvoir REGARDER la
# base même quand 75 s'est arrêté sur un garde-fou. C'est justement là qu'il y
# a quelque chose à voir.
if [ -n "${DIAG:-}" ] && [ -f "$DIAG" ]; then
    echo "== diagnostic ($DIAG)"
    psql -f "$DIAG" || true
fi

# Le contrôle qui compte vraiment quand deux fichiers écrivent dans la même
# table : personne ne se recouvre. La contrainte l'aurait refusé, mais on veut
# le VOIR — et voir aussi que 74, 75 et 76 tiennent ensemble.
psql -c "SELECT (SELECT count(*) FROM histgis.membership a JOIN histgis.membership b
                   ON a.atom_id=b.atom_id AND a.niveau=b.niveau
                  AND a.membership_id<b.membership_id AND a.periode && b.periode
                 WHERE a.niveau='canton')                       AS chevauchements,
                (SELECT count(*) FROM histgis.y67_trace
                  WHERE to_regclass('histgis.y67_trace') IS NOT NULL) AS pose_par_74,
                (SELECT count(*) FROM histgis.p75_trace)        AS pose_par_75,
                (SELECT count(*) FROM histgis.p76_trace)        AS pose_par_76,
                (SELECT count(*) FROM histgis.p77_trace)        AS pose_par_77;"

echo
cat "$BANC/75.out"
echo
cat "$BANC/76.out" 2>/dev/null
exit $STATUT

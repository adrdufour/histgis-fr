#!/usr/bin/env bash
# ============================================================================
# banc_38_39.sh — banc d'essai des traces de `38` et `39` sur un PostgreSQL
#                 jetable
#
# Même dispositif que `banc_75.sh` et `banc_81.sh` : le VRAI schéma
# (`01_schema.sql`) sans postgis, les deux `EXCLUDE` remplacées par des
# déclencheurs équivalents, et des données synthétiques minimales — ici posées
# dans ce fichier même, parce que `38` et `39` ne touchent qu'une poignée
# d'unités nommément désignées.
#
# POURQUOI CE BANC EXISTE
# -----------------------
# `38` et `39` viennent de recevoir une table de trace (2 septembre 2026). Ce
# qu'une trace doit garantir ne se lit pas dans le code : il faut le jouer.
# Cinq scénarios, chacun un chemin que la vraie base ne montrerait pas tous :
#
#   A. 39 sur une base FRAÎCHE           — 29 unités tracées, dep passé à 54
#   B. 39 sur une base DÉJÀ CONFORME     — 29 unités tracées quand même. C'est
#      (trace perdue, dep déjà à 54)       LE point : viser `dep = '99'` aurait
#                                          donné une trace vide, donc la fausse
#                                          alarme « joué puis défait ? »
#   C. 38 sur une base fraîche           — 3 + 3 + 3 tracés, rejeu idempotent
#   D. 38 quand la fenêtre 1982-1999     — pose 2 sur 3, NOMME l'occupant et
#      est prise pour une commune          lève un WARNING au lieu de se taire
#   E. 38 quand la fenêtre est prise     — refus explicite et lisible, pas une
#      pour une FRACTION                   violation d'EXCLUDE opaque
#   F. 38 quand `24` a déjà créé sa     — les deux déclarations de la table
#      trace vide, comme dans la chaîne   doivent coïncider, `avant` compris
#
# Ce qu'il prouve : la syntaxe, le retrait, la rejouabilité, le comportement
#                   aux deux pièges, et que la trace n'est jamais vide quand le
#                   fichier est passé.
# Ce qu'il ne prouve pas : les effectifs de la vraie base (29 cantons de la
#                   Meurthe, six lignes au 1er juin 1986) — il n'en porte que
#                   des doublures.
#
#   bash sql/bancs/banc_38_39.sh        (depuis la racine du dépôt)
# ============================================================================
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/../.." && pwd)"
BANC="${BANC:-/tmp/banc_histgis_38_39}"
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

cd "$RACINE"

# --- le schéma réel, amputé de ce que ce PostgreSQL n'a pas ------------------
sed -e 's/^CREATE EXTENSION IF NOT EXISTS postgis;/-- (banc) postgis hors sujet/' \
    -e 's/^CREATE EXTENSION IF NOT EXISTS btree_gist;.*$/-- (banc) btree_gist remplacée par des déclencheurs/' \
    -e 's/EXCLUDE USING gist (unit_id WITH =, periode WITH \&\&)/CHECK (true) \/* banc : voir déclencheur *\//' \
    -e 's/EXCLUDE USING gist (atom_id WITH =, niveau WITH =, periode WITH \&\&)/CHECK (true) \/* banc : voir déclencheur *\//' \
    sql/01_schema.sql > "$BANC/01_banc.sql"

# --- une base neuve par scénario --------------------------------------------
# Chaque scénario part d'un état propre : un banc qui enchaîne cinq cas dans la
# même base ne mesure plus le cinquième mais la somme des quatre premiers.
prepare () {   # prepare <base>
    psql -d postgres -q -c "DROP DATABASE IF EXISTS $1;" -c "CREATE DATABASE $1;"
    PGDATABASE=$1 psql -q -f "$BANC/01_banc.sql"
    PGDATABASE=$1 psql -q -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;

-- Les deux contraintes EXCLUDE, en déclencheurs. Ce sont ELLES que `38` § 3
-- doit devancer ; sans elles le banc ne testerait rien du scénario E.
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

-- `39` la lit en dernier ; elle est posée par `19_noms_geofla.sql` dans la
-- vraie chaîne.
CREATE TABLE noms_geofla (insee char(5) PRIMARY KEY, nom text);

-- ------------------------------------------------------------------ 38 -----
-- Bourg-en-Bresse (01053) coupée en trois par les cantons 0105, 0137, 0138,
-- chacun tenant une fraction. Trois communes entières autour.
INSERT INTO unit (unit_id, niveau, dep, nom) VALUES
    ('0105', 'canton', '01', 'Bourg-en-Bresse-Est'),
    ('0137', 'canton', '01', 'Bourg-en-Bresse-Nord-Centre'),
    ('0138', 'canton', '01', 'Bourg-en-Bresse-Sud');

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to) VALUES
    ('0105', 'Bourg-en-Bresse-Est',         '1999-01-01', '2013-01-01'),
    ('0137', 'Bourg-en-Bresse-Nord-Centre', '1999-01-01', '2013-01-01'),
    ('0138', 'Bourg-en-Bresse-Sud',         '1999-01-01', '2013-01-01');

INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla) VALUES
    ('5260#0105', '5260', true,  1, '01053'),
    ('5260#0137', '5260', true,  1, '01053'),
    ('5260#0138', '5260', true,  1, '01053'),
    ('31254',     '31254', false, 1, '01254'),
    ('31369',     '31369', false, 1, '01369'),
    ('31344',     '31344', false, 1, '01344');

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to) VALUES
    ('5260#0105', '0105', 'canton', '1999-01-01', '2013-01-01'),
    ('5260#0137', '0137', 'canton', '1999-01-01', '2013-01-01'),
    ('5260#0138', '0138', 'canton', '1999-01-01', '2013-01-01'),
    ('31254',     '0105', 'canton', '1999-01-01', '2013-01-01'),
    ('31369',     '0105', 'canton', '1999-01-01', '2013-01-01'),
    ('31344',     '0138', 'canton', '1999-01-01', '2013-01-01');

-- ------------------------------------------------------------------ 39 -----
-- Vingt-neuf cantons de la Meurthe rangés sous le département fictif `99`,
-- une commune chacun, sur [1870-01-01, 1871-01-01). Plus deux cantons de
-- Meurthe-et-Moselle déjà en `54` : ils ne doivent PAS être tracés.
INSERT INTO unit (unit_id, niveau, dep, nom)
SELECT format('99%s', lpad(i::text, 2, '0')), 'canton', '99', 'Meurthe-' || i
  FROM generate_series(1, 29) i;
INSERT INTO unit (unit_id, niveau, dep, nom) VALUES
    ('5401', 'canton', '54', 'Nancy-Nord'),
    ('5402', 'canton', '54', 'Briey');

INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
SELECT format('9%04s', i), format('9%04s', i), false, 3, format('54%03s', i)
  FROM generate_series(1, 29) i;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT format('9%04s', i), format('99%s', lpad(i::text, 2, '0')),
       'canton', '1870-01-01', '1871-01-01'
  FROM generate_series(1, 29) i;
SQL
}

joue () {   # joue <base> <fichier> <étiquette>   — rend le code de retour
    if PGDATABASE=$1 psql -v ON_ERROR_STOP=1 -f "$2" > "$BANC/$3.out" 2>&1; then
        return 0
    else
        return 1
    fi
}

q () { PGDATABASE=$1 psql -tAc "$2"; }

ECHECS=0
verifie () {   # verifie <libellé> <attendu> <obtenu>
    if [ "$2" = "$3" ]; then
        printf '   ok   %-58s %s\n' "$1" "$3"
    else
        printf '   NON  %-58s attendu %s, obtenu %s\n' "$1" "$2" "$3"
        ECHECS=$((ECHECS + 1))
    fi
}

# ===========================================================================
echo "== A. 39 sur une base fraîche (les 29 unités portent dep = 99)"
# ===========================================================================
prepare banc_a
joue banc_a sql/39_meurthe_1870.sql 39a || { echo "ÉCHEC"; cat "$BANC/39a.out"; exit 1; }
verifie "unités tracées"                29 "$(q banc_a "SELECT count(*) FROM histgis.p39_trace WHERE quoi='unit_dep';")"
verifie "cantons restés en 99"           0 "$(q banc_a "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='99';")"
verifie "cantons en 54 (29 + 2 déjà là)" 31 "$(q banc_a "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='54';")"
verifie "avant = 99 partout"            29 "$(q banc_a "SELECT count(*) FROM histgis.p39_trace WHERE avant='99';")"
verifie "les 5401/5402 ne sont pas tracés" 0 "$(q banc_a "SELECT count(*) FROM histgis.p39_trace WHERE cle IN ('5401','5402');")"

echo "   -- rejeu"
joue banc_a sql/39_meurthe_1870.sql 39a2 || { echo "ÉCHEC AU REJEU"; cat "$BANC/39a2.out"; exit 1; }
verifie "trace après rejeu (idempotent)" 29 "$(q banc_a "SELECT count(*) FROM histgis.p39_trace WHERE quoi='unit_dep';")"
verifie "toujours 0 en 99"                0 "$(q banc_a "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='99';")"

echo "   -- le retrait rend bien le 99 de la source"
PGDATABASE=banc_a psql -q -c "UPDATE histgis.unit u SET dep = t.avant::char(2)
                                FROM histgis.p39_trace t
                               WHERE t.quoi='unit_dep' AND t.cle = u.unit_id;"
verifie "cantons rendus au 99"           29 "$(q banc_a "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='99';")"

# ===========================================================================
echo
echo "== B. 39 sur une base DÉJÀ CONFORME dont la trace est perdue"
echo "      (c'est l'état de la vraie base au 2 septembre 2026)"
# ===========================================================================
prepare banc_b
PGDATABASE=banc_b psql -q -c "UPDATE histgis.unit SET dep='54' WHERE niveau='canton' AND dep='99';"
verifie "état de départ : 0 canton en 99" 0 "$(q banc_b "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='99';")"
joue banc_b sql/39_meurthe_1870.sql 39b || { echo "ÉCHEC"; cat "$BANC/39b.out"; exit 1; }
verifie "unités tracées MALGRÉ TOUT"     29 "$(q banc_b "SELECT count(*) FROM histgis.p39_trace WHERE quoi='unit_dep';")"
verifie "toujours 0 en 99"                0 "$(q banc_b "SELECT count(*) FROM histgis.unit WHERE niveau='canton' AND dep='99';")"
echo "      (une trace visant \`dep = '99'\` aurait rendu 0 ici, donc le verdict"
echo "       « vide — joué puis défait ? » de diag_passages sur une base saine)"

# ===========================================================================
echo
echo "== C. 38 sur une base fraîche"
# ===========================================================================
prepare banc_c
joue banc_c sql/38_decret_1982_ain.sql 38c || { echo "ÉCHEC"; cat "$BANC/38c.out"; exit 1; }
verifie "fractions remontées, tracées"    3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership_remontee';")"
verifie "noms de 1982, tracés"            3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='unit_version';")"
verifie "communes entières, tracées"      3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership';")"
verifie "fractions démarrant en 1982"     3 "$(q banc_c "SELECT count(*) FROM histgis.membership WHERE valid_from='1982-01-26' AND atom_id LIKE '5260#%';")"
verifie "lignes au 1er juin 1986"         6 "$(q banc_c "SELECT count(*) FROM histgis.membership m JOIN histgis.atom a USING (atom_id) WHERE m.niveau='canton' AND m.periode @> DATE '1986-06-01' AND a.insee_geofla IN ('01053','01254','01369','01344');")"
verifie "aucun WARNING"                   0 "$(grep -c 'ATTENTION\|WARNING' "$BANC/38c.out" || true)"

echo "   -- rejeu : le § 2 doit défaire avant de refaire"
joue banc_c sql/38_decret_1982_ain.sql 38c2 || { echo "ÉCHEC AU REJEU"; cat "$BANC/38c2.out"; exit 1; }
verifie "remontées après rejeu"           3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership_remontee';")"
verifie "unit_version après rejeu"        3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='unit_version';")"
verifie "communes après rejeu"            3 "$(q banc_c "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership';")"
verifie "pas de doublon d'unit_version"   3 "$(q banc_c "SELECT count(*) FROM histgis.unit_version WHERE valid_from='1982-01-26';")"
verifie "pas de doublon de membership"    6 "$(q banc_c "SELECT count(*) FROM histgis.membership WHERE valid_from='1982-01-26';")"

echo "   -- le retrait complet, par le § 2 seul"
PGDATABASE=banc_c psql -q <<'SQL'
SET search_path TO histgis, public;
DELETE FROM membership m USING p38_trace t
 WHERE t.quoi='membership' AND t.cle = m.membership_id::text;
DELETE FROM unit_version v USING p38_trace t
 WHERE t.quoi='unit_version' AND t.cle = v.unit_version_id::text;
UPDATE membership m SET valid_from = t.avant::date FROM p38_trace t
 WHERE t.quoi='membership_remontee' AND t.cle = m.membership_id::text;
TRUNCATE p38_trace;
SQL
verifie "plus rien en 1982 après retrait" 0 "$(q banc_c "SELECT count(*) FROM histgis.membership WHERE valid_from='1982-01-26';")"
verifie "fractions rendues à 1999"        3 "$(q banc_c "SELECT count(*) FROM histgis.membership WHERE valid_from='1999-01-01' AND atom_id LIKE '5260#%';")"
verifie "état de Bourg identique au départ" 6 "$(q banc_c "SELECT count(*) FROM histgis.membership WHERE atom_id IN ('5260#0105','5260#0137','5260#0138','31254','31369','31344');")"

# ===========================================================================
echo
echo "== D. 38 quand un autre fichier occupe déjà 1982-1999 pour Montagnat"
echo "      (c'est ce que font 75, 76 et 79 depuis fin août)"
# ===========================================================================
prepare banc_d
PGDATABASE=banc_d psql -q <<'SQL'
SET search_path TO histgis, public;
-- Un rival, comme en poserait `75` : Montagnat rattachée à 0137 sur 1982-1999.
UPDATE membership SET valid_from = '1982-01-26'
 WHERE atom_id = '31254' AND unit_id = '0105';
SQL
joue banc_d sql/38_decret_1982_ain.sql 38d || { echo "ÉCHEC"; cat "$BANC/38d.out"; exit 1; }
verifie "communes posées (2 sur 3)"       2 "$(q banc_d "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership';")"
verifie "le WARNING est levé"             1 "$(grep -c 'ATTENTION\|WARNING' "$BANC/38d.out" || true)"
verifie "l'occupant est nommé"            1 "$(grep -c 'OCCUPEE' "$BANC/38d.out" || true)"
echo "      → sans ce WARNING, ce scénario rendait un code de retour nul et"
echo "        un silence complet. C'est le piège que RESTE_A_FAIRE § 0.3 décrit."

# ===========================================================================
echo
echo "== E. 38 quand la fenêtre est prise pour une FRACTION (blocage franc)"
# ===========================================================================
prepare banc_e
PGDATABASE=banc_e psql -q <<'SQL'
SET search_path TO histgis, public;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
VALUES ('5260#0105', '0137', 'canton', '1985-01-01', '1990-01-01');
SQL
if joue banc_e sql/38_decret_1982_ain.sql 38e; then
    echo "   NON  38 aurait dû refuser, il a réussi"
    ECHECS=$((ECHECS + 1))
else
    verifie "refus explicite du § 3"      1 "$(grep -c 'REMONTEE IMPOSSIBLE' "$BANC/38e.out" || true)"
    verifie "l'occupant est nommé"        1 "$(grep -c '5260#0105 occupe par 0137' "$BANC/38e.out" || true)"
    # La transaction entière est annulée, `CREATE TABLE IF NOT EXISTS` compris :
    # un fichier qui refuse ne laisse même pas sa trace. C'est ce qu'on veut —
    # une trace vide se lirait comme « joué puis défait ».
    verifie "aucune trace laissée"        "" "$(q banc_e "SELECT to_regclass('histgis.p38_trace');")"
    verifie "rien n'a été écrit en 1982"   0 "$(q banc_e "SELECT count(*) FROM histgis.membership WHERE valid_from='1982-01-26';")"
fi

# ===========================================================================
echo
echo "== F. 38 quand \`24\` a déjà créé p38_trace vide (l'ordre réel de la chaîne)"
# ===========================================================================
# `24` tourne AVANT `38` et crée les traces vides des fichiers qui le suivent,
# pour que sa recette de filiation puisse les lire. Sa déclaration de
# `p38_trace` doit donc être IDENTIQUE à celle de `38` : `CREATE TABLE IF NOT
# EXISTS` n'ajoute pas de colonne à une table existante, et un `avant` manquant
# ferait échouer `38` sur une base pourtant saine. Le banc copie ici la ligne de
# `24` telle quelle.
prepare banc_f
PGDATABASE=banc_f psql -q -c "SET search_path TO histgis, public;
  CREATE TABLE IF NOT EXISTS p38_trace (quoi text NOT NULL, cle text NOT NULL, avant text, pose timestamptz NOT NULL DEFAULT now());"
joue banc_f sql/38_decret_1982_ain.sql 38f || { echo "ÉCHEC"; cat "$BANC/38f.out"; exit 1; }
verifie "remontées tracées malgré la table préexistante" 3 "$(q banc_f "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership_remontee';")"
verifie "communes tracées"                3 "$(q banc_f "SELECT count(*) FROM histgis.p38_trace WHERE quoi='membership';")"
verifie "la colonne avant est renseignée" 3 "$(q banc_f "SELECT count(*) FROM histgis.p38_trace WHERE avant IS NOT NULL;")"

# ===========================================================================
echo
if [ "$ECHECS" = 0 ]; then
    echo "== BANC VERT — les six scénarios passent"
else
    echo "== $ECHECS CONTRÔLE(S) EN ÉCHEC"
    exit 1
fi

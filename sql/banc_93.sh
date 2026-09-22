#!/usr/bin/env bash
# ============================================================================
# banc_93.sh — banc d'essai de sql/93 sur un PostgreSQL jetable
#
# Même dispositif que `banc_75.sh` et `banc_81.sh` : schéma réel sans postgis,
# les deux `EXCLUDE` remplacées par des déclencheurs équivalents. La cible est
# `banc_93_donnees.sql`, faite pour qu'aucune des cinq classes du § 4 ne soit
# vide et pour que chaque garde-fou ait de quoi mordre.
#
# CE QU'IL PROUVE : la syntaxe, les jointures, le classement des cinq classes,
#   la borne des décrets, le tamis d'occupation, les garde-fous, la
#   rejouabilité, et que le report ne mord ni sur 1940 ni sur le jalon de 1954.
# CE QU'IL NE PROUVE PAS : les effectifs et les taux d'accord, qui n'ont de
#   sens que sur les vraies couches. Le banc ne dit rien de 98,78 % ni de
#   99,50 % — c'est `70` qui les a mesurés, sur la vraie base.
#
#   bash sql/banc_93.sh        (depuis la racine du dépôt)
# ============================================================================
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
BANC="${BANC:-/tmp/banc_histgis_93}"
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

-- `histgis.` en toutes lettres : un déclencheur qui lit une table NON qualifiée
-- dépend du `search_path` de la session qui déclenche l'écriture. Une session
-- venue d'ailleurs — le § 9 en est une — le ferait échouer sur « relation
-- membership does not exist », ce qui RESSEMBLE à un refus et n'en est pas.
-- *Un garde-fou qui échoue pour la mauvaise raison se lit comme un succès.*
CREATE FUNCTION banc_membership_non_chevauchant() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM histgis.membership m
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
SQL

psql -q -v ON_ERROR_STOP=1 -f sql/banc_93_donnees.sql
echo "== schéma et cible synthétique posés"

if ! psql -v ON_ERROR_STOP=1 -f sql/93_report_1940_1954.sql > "$BANC/93.out" 2>&1; then
    echo "== ÉCHEC 93"; tail -60 "$BANC/93.out"; exit 1
fi
echo "== 93 joué"

echoq () { psql -tAc "$1"; }
verifie () {   # verifie <libellé> <attendu> <requête>
    local got; got="$(echoq "$3")"
    if [ "$got" = "$2" ]; then
        printf '   OK   %-46s %s\n' "$1" "$got"
    else
        printf '   FAUX %-46s attendu %s, obtenu %s\n' "$1" "$2" "$got"
        ECHECS=$((ECHECS + 1))
    fi
}
ECHECS=0

echo
echo "== 1. le classement des cinq classes"
verifie "accord"              9 "SELECT count(*) FROM histgis.p93_verdict WHERE verdict='accord';"
verifie "desaccord"          12 "SELECT count(*) FROM histgis.p93_verdict WHERE verdict='desaccord';"
verifie "absent_de_1954"      2 "SELECT count(*) FROM histgis.p93_verdict WHERE verdict='absent_de_1954';"
verifie "fraction"            1 "SELECT count(*) FROM histgis.p93_verdict WHERE verdict='fraction';"
verifie "serie_1940_ecourtee" 1 "SELECT count(*) FROM histgis.p93_verdict WHERE verdict='serie_1940_ecourtee';"
verifie "le tamis se reboucle" 25 "SELECT count(*) FROM histgis.p93_verdict;"

echo
echo "== 2. ce qui a été posé"
verifie "lignes posées"       19 "SELECT count(*) FROM histgis.p93_trace WHERE quoi='membership';"
verifie "dont accord"          8 "SELECT count(*) FROM histgis.p93_qualite WHERE fondement='accord_deux_bouts';"
verifie "dont sous décret"    11 "SELECT count(*) FROM histgis.p93_qualite WHERE fondement='sous_decret';"
verifie "écartées pour occupation" 1 \
    "SELECT (SELECT count(*) FROM histgis.p93_pose)-(SELECT count(*) FROM histgis.p93_libre);"

echo
echo "== 3. les bornes — aucune ligne ne mord sur les couches voisines"
verifie "avant 1941"           0 "SELECT count(*) FROM histgis.membership m JOIN histgis.p93_qualite q USING (membership_id) WHERE m.valid_from < DATE '1941-01-01';"
verifie "après 1954"           0 "SELECT count(*) FROM histgis.membership m JOIN histgis.p93_qualite q USING (membership_id) WHERE m.valid_to > DATE '1954-01-01';"
verifie "Sousceyrac s'arrête au décret" 4 \
    "SELECT count(*) FROM histgis.membership m JOIN histgis.p93_qualite q USING (membership_id) WHERE q.unit_id='4610' AND m.valid_to=DATE '1949-09-05';"
verifie "Brive s'arrête au décret" 7 \
    "SELECT count(*) FROM histgis.membership m JOIN histgis.p93_qualite q USING (membership_id) WHERE q.unit_id='1910' AND m.valid_to=DATE '1951-09-13';"

echo
echo "== 4. la qualité"
verifie "contrôle indépendant" 6 "SELECT count(*) FROM histgis.p93_qualite WHERE fondement='accord_deux_bouts' AND controle_independant;"
verifie "ferme_canton (non indépendant)" 1 "SELECT count(*) FROM histgis.p93_qualite WHERE appariement='ferme_canton';"
verifie "hors_c54 (le cas de 87)" 1 "SELECT count(*) FROM histgis.p93_qualite WHERE appariement='hors_c54';"
verifie "chrono_trouee"        1 "SELECT count(*) FROM histgis.p93_qualite WHERE chrono_trouee;"
verifie "toute ligne a sa qualité" 0 \
    "SELECT count(*) FROM histgis.p93_trace t WHERE t.quoi='membership' AND NOT EXISTS (SELECT 1 FROM histgis.p93_qualite q WHERE q.membership_id=t.cle::bigint);"

echo
echo "== 5. aucun chevauchement dans toute la couche cantonale"
verifie "chevauchements"       0 \
    "SELECT count(*) FROM histgis.membership a JOIN histgis.membership b ON a.atom_id=b.atom_id AND a.niveau=b.niveau AND a.membership_id<b.membership_id AND a.periode && b.periode WHERE a.niveau='canton';"

echo
echo "== 6. les couches voisines sont intactes"
verifie "couche 1940"         25 "SELECT count(*) FROM histgis.membership WHERE niveau='canton' AND periode @> DATE '1940-06-01';"
verifie "jalon 1954"          22 "SELECT count(*) FROM histgis.membership WHERE niveau='canton' AND periode @> DATE '1954-06-01';"

echo
echo "== 7. le vide est comblé là où il devait l'être"
verifie "à 1942 (accord + 11 décrets)" 19 "SELECT count(*) FROM histgis.membership WHERE niveau='canton' AND periode @> DATE '1942-06-01';"
verifie "à 1950 (Sousceyrac est sorti)" 15 "SELECT count(*) FROM histgis.membership WHERE niveau='canton' AND periode @> DATE '1950-06-01';"
verifie "à 1953 (Brive est sorti aussi)"  8 "SELECT count(*) FROM histgis.membership WHERE niveau='canton' AND periode @> DATE '1953-06-01';"

echo
echo "== 8. rejouabilité (le compte doit être identique)"
AVANT=$(echoq "SELECT count(*) FROM histgis.p93_trace WHERE quoi='membership';")
psql -q -v ON_ERROR_STOP=1 -f sql/93_report_1940_1954.sql > "$BANC/93.rejeu.out" 2>&1 \
    || { echo "== ÉCHEC AU REJEU"; tail -60 "$BANC/93.rejeu.out"; exit 1; }
APRES=$(echoq "SELECT count(*) FROM histgis.p93_trace WHERE quoi='membership';")
if [ "$AVANT" = "$APRES" ]; then
    echo "   OK   $AVANT puis $APRES — idempotent"
else
    echo "   FAUX rejeu non idempotent : $AVANT puis $APRES"; ECHECS=$((ECHECS + 1))
fi
verifie "aucun doublon après rejeu" 0 \
    "SELECT count(*) FROM histgis.membership a JOIN histgis.membership b ON a.atom_id=b.atom_id AND a.niveau=b.niveau AND a.membership_id<b.membership_id AND a.periode && b.periode WHERE a.niveau='canton';"

echo
echo '== 9. 94, le diagnostic des absents, tourne-t-il et classe-t-il ?'
if ! psql -v ON_ERROR_STOP=1 -f sql/94_absents_1954_diag.sql > "$BANC/94.out" 2>&1; then
    echo "   FAUX 94 a échoué"; tail -30 "$BANC/94.out"; ECHECS=$((ECHECS + 1))
else
    verifie "94 : morte dans la fenêtre (b14)" 1 \
        "SELECT count(*) FROM histgis.d94_absent WHERE classe='MORTE_DANS_LA_FENETRE';"
    verifie "94 : vivante en 1954 (b07)" 1 \
        "SELECT count(*) FROM histgis.d94_absent WHERE classe='vivante_en_1954';"
    verifie "94 : le classement se reboucle" 2 \
        "SELECT count(*) FROM histgis.d94_absent;"
    verifie "94 : n'écrit rien dans membership" 19 \
        "SELECT count(*) FROM histgis.p93_trace WHERE quoi='membership';"
fi

echo
echo "== 10. le banc a-t-il des dents ?"
# Tous les zéros ci-dessus ne valent que si la contrainte est vivante. On
# tente une ligne qui chevauche délibérément un report posé : elle DOIT être
# refusée. *Un contrôle qui ne peut pas échouer ne contrôle rien* — et c'est
# ici que se vérifie que le déclencheur du banc remplace bien l'EXCLUDE.
if psql -q -v ON_ERROR_STOP=1 -c \
    "INSERT INTO histgis.membership (atom_id, unit_id, niveau, valid_from, valid_to)
     VALUES ('b01', '0111', 'canton', DATE '1945-01-01', DATE '1946-01-01');" \
    > "$BANC/dents.out" 2>&1; then
    echo "   FAUX un chevauchement a été ACCEPTÉ — les zéros ci-dessus ne prouvent rien"
    ECHECS=$((ECHECS + 1))
else
    echo "   OK   chevauchement refusé : $(grep -m1 -E '^(ERROR|ERREUR)' "$BANC/dents.out" | cut -c1-110)"
fi

echo
if [ "$ECHECS" -eq 0 ]; then
    echo "== BANC PASSÉ — aucune ligne fausse"
else
    echo "== $ECHECS CONTRÔLE(S) FAUX — voir ci-dessus"
    exit 1
fi

echo
echo "--- sortie complète de 93 ---"
cat "$BANC/93.out"

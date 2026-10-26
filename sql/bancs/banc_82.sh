#!/usr/bin/env bash
# ============================================================================
# banc_82.sh — banc d'essai de sql/82 sur un PostgreSQL jetable
#
# Même dispositif que `banc_75.sh` et `banc_81.sh` : PostgreSQL sans postgis,
# `EXCLUDE` remplacée par un déclencheur équivalent. Mais `82` est un fichier
# ENTIÈREMENT géométrique, ce qui pose au banc un problème que les précédents
# n'avaient pas.
#
# LA GÉOMÉTRIE Y DEVIENT SON EMPREINTE, ET CE N'EST PAS UN AVEU DE FAIBLESSE
# =========================================================================
# `sql/bancs/banc_82_anr.csv` porte les 47 784 lignes d'attributs réelles
# d'ANR-COMMUNES, où la colonne `geom` vaut **l'empreinte MD5 du WKB réel** du
# polygone, et `banc_82_aires.csv` porte l'aire de chacune.
#
# Conséquence : **R2 est exercée pour de vrai**. Le dédoublonnage de `82` porte
# sur `(poly_id, md5(ST_AsBinary(geom)), fenêtre)` ; au banc, `geom` EST cette
# empreinte, donc deux lignes que le vrai PostGIS jugerait identiques le sont ici aussi, et
# les 66 doublons du jeu doivent tomber exactement pareil. Même chose pour
# l'aire : le § 7 recompte une emprise, et il la recompte sur les vraies aires.
#
# CE QUE CE BANC PROUVE
#   - la syntaxe et les jointures de `82` ;
#   - **le pont `atom.cassini = anr.id_com` sur les VRAIS atomes** — `atom.csv`
#     et `membership_canton.csv` du dépôt sont chargés tels quels, ce n'est pas
#     de la donnée synthétique ;
#   - R1 (fenêtres semi-ouvertes), R2 (66 doublons), R3 (le verdict des
#     variantes), l'exclusion des fractions ;
#   - qu'aucun atome ne reçoit deux polygones sur des périodes qui se
#     recouvrent — c'est le déclencheur qui remplace `EXCLUDE` ;
#   - la rejouabilité.
#
# CE QU'IL NE PROUVE PAS
#   - le recouvrement de 101,0 km², qui demande `ST_Intersection` et donc un
#     vrai PostGIS. Il a été mesuré hors base le 1er septembre, contre l'étalon
#     GEOFLA, et c'est là qu'il faut le relire.
#   - la validité des polygones.
# *Un banc qui ne peut pas mentir sur ce qu'il ne teste pas vaut mieux qu'un
# banc complet qu'on ne peut pas faire tourner.*
#
#   bash sql/bancs/banc_82.sh        (depuis la racine du dépôt)
# ============================================================================
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/../.." && pwd)"
BANC="${BANC:-/tmp/banc_histgis_82}"
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

# --- 1. le strict nécessaire du schéma réel, sans postgis -------------------
psql -q -v ON_ERROR_STOP=1 <<'SQL'
CREATE SCHEMA histgis;
SET search_path TO histgis, public;

CREATE TABLE atom (
    atom_id      text PRIMARY KEY,
    cassini      text NOT NULL,
    fraction     boolean NOT NULL DEFAULT false,
    com_act      smallint,
    insee_geofla char(5)
);
CREATE INDEX atom_cassini_idx ON atom (cassini);

CREATE TABLE membership (
    membership_id bigserial PRIMARY KEY,
    atom_id    text NOT NULL REFERENCES atom(atom_id) ON DELETE CASCADE,
    niveau     text NOT NULL,
    unit_id    text NOT NULL,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[)')) STORED
);
CREATE INDEX membership_atom_idx ON membership (atom_id);

CREATE TABLE unit (unit_id text, niveau text, dep char(2), nom text,
                   PRIMARY KEY (unit_id, niveau));
CREATE TABLE unit_version (unit_id text, nom text, periode daterange);

CREATE TABLE atom_geom (
    atom_id  text PRIMARY KEY REFERENCES atom(atom_id) ON DELETE CASCADE,
    geom     text NOT NULL,
    source   text NOT NULL,
    partagee boolean NOT NULL DEFAULT false
);
CREATE TABLE atom_geom_source (source text PRIMARY KEY, pose_par text NOT NULL, note text);
INSERT INTO atom_geom_source VALUES ('geofla', 'banc', 'repli');
SQL

# --- 2. les VRAIS atomes et rattachements du dépôt --------------------------
psql -q -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;
CREATE TEMP TABLE atom_src (atom_id text, cassini text, insee text, fraction text);
\copy atom_src FROM 'build/atom.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO atom (atom_id, cassini, fraction, insee_geofla)
SELECT atom_id, cassini, fraction = 'true', nullif(insee, '') FROM atom_src;

CREATE TEMP TABLE mb_src (atom_id text, cassini text, insee text, unit_id text,
                          valid_from date, valid_to date);
\copy mb_src FROM 'build/membership_canton.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO membership (atom_id, niveau, unit_id, valid_from, valid_to)
SELECT s.atom_id, 'canton', s.unit_id, s.valid_from, s.valid_to
FROM   mb_src s JOIN atom a ON a.atom_id = s.atom_id;

INSERT INTO unit (unit_id, niveau, dep, nom)
SELECT DISTINCT unit_id, 'canton', left(unit_id, 2), 'canton ' || unit_id FROM membership;

-- repli R5 : tout atome a une géométrie « GEOFLA » d'avant, comme en vrai
INSERT INTO atom_geom (atom_id, geom, source)
SELECT atom_id, 'geofla:' || atom_id, 'geofla' FROM atom;
SQL

# --- 3. la couche ANR : attributs réels, géométrie = empreinte du WKB -------
psql -q -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;
CREATE TABLE anr_commune (
    gid serial PRIMARY KEY,
    id_com text, namecom text, poly_id text,
    startdt text, enddt text, pseudo_t text, geom text
);
\copy anr_commune (id_com, namecom, poly_id, startdt, enddt, pseudo_t, geom) FROM 'sql/bancs/banc_82_anr.csv' WITH (FORMAT csv, HEADER true)

CREATE TABLE banc_aire (geom text PRIMARY KEY, aire_m2 double precision);
\copy banc_aire FROM 'sql/bancs/banc_82_aires.csv' WITH (FORMAT csv, HEADER true)

-- succédanés de PostGIS, juste ce que 82 appelle
CREATE FUNCTION st_multi(t text)     RETURNS text AS $$ SELECT t $$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION st_asbinary(t text)  RETURNS text AS $$ SELECT t $$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION st_isvalid(t text)   RETURNS boolean AS $$ SELECT true $$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION st_unaryunion(t text) RETURNS text AS $$ SELECT t $$ LANGUAGE sql IMMUTABLE;
-- ST_Collect est un AGRÉGAT dans PostGIS, et `82` l'appelle comme tel : le
-- succédané doit l'être aussi, sans quoi le banc réclamerait un GROUP BY que
-- le vrai fichier n'a pas besoin d'écrire.
CREATE FUNCTION banc_premier(a text, b text) RETURNS text
    AS $$ SELECT coalesce(a, b) $$ LANGUAGE sql IMMUTABLE;
CREATE AGGREGATE st_collect(text) (SFUNC = banc_premier, STYPE = text);
CREATE FUNCTION st_intersects(a text, b text) RETURNS boolean AS $$ SELECT false $$ LANGUAGE sql IMMUTABLE;
-- `&&` sur des géométries teste le recouvrement des boîtes englobantes, et
-- c'est LUI qui consulte l'index gist. Sur des empreintes il ne veut rien dire :
-- le succédané renvoie faux, comme ST_Intersects. Le banc ne mesure donc aucun
-- recouvrement — il vérifie seulement que la requête est bien formée.
CREATE FUNCTION banc_bbox(a text, b text) RETURNS boolean AS $$ SELECT false $$ LANGUAGE sql IMMUTABLE;
CREATE OPERATOR && (LEFTARG = text, RIGHTARG = text, PROCEDURE = banc_bbox);
CREATE FUNCTION st_intersection(a text, b text) RETURNS text AS $$ SELECT NULL::text $$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION st_area(t text) RETURNS double precision
    AS $$ SELECT coalesce((SELECT aire_m2 FROM banc_aire WHERE geom = t), 0) $$ LANGUAGE sql STABLE;
SQL

# L'emprise du § 7 passe par `ST_UnaryUnion(ST_Collect(geom))`, qui n'a pas de
# sens sur des empreintes : le sed du § 4 la remplace par une somme d'aires.
# Substitution déclarée — au banc l'emprise est donc la SOMME, pas l'union, et
# elle vaut 548 932 + 101 km² de recouvrement. C'est voulu, et c'est dit.

# --- 4. la copie de banc de 82 ---------------------------------------------
sed -e "s/geometry(MultiPolygon, 2154)/text/g" \
    -e "s/EXCLUDE USING gist (atom_id WITH =, periode WITH \&\&)/CHECK (true) \/* banc : voir déclencheur *\//" \
    -e "s/CREATE INDEX atom_geom_anr_geom_idx ON atom_geom_anr USING gist (geom);/-- (banc) pas d'index gist sans postgis/" \
    -e "s/round((ST_Area(ST_UnaryUnion(ST_Collect(geom))) \/ 1e6)::numeric, 0)/round((sum(ST_Area(geom)) \/ 1e6)::numeric, 0)/" \
    -e "s/IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'btree_gist') THEN/IF false THEN/" \
    sql/82_anr_geom.sql > "$BANC/82_banc.sql"

psql -q -v ON_ERROR_STOP=1 <<'SQL'
SET search_path TO histgis, public;
CREATE FUNCTION banc_atom_geom_anr_excl() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM atom_geom_anr g
                WHERE g.atom_id = NEW.atom_id AND g.periode && NEW.periode) THEN
        RAISE EXCEPTION
          'atom_geom_anr (banc) : atome % a déjà un polygone sur %', NEW.atom_id, NEW.periode;
    END IF;
    RETURN NEW;
END $$;
SQL

echo "== schéma, atomes réels et couche ANR posés"

if ! psql -v ON_ERROR_STOP=1 -v variantes=build/anr_variantes.csv \
        -f "$BANC/82_banc.sql" > "$BANC/82.out" 2>&1; then
    echo "== ÉCHEC 82"; tail -40 "$BANC/82.out"; exit 1
fi
# le déclencheur ne peut être posé qu'après la création de la table par 82
psql -q -c "CREATE TRIGGER banc_excl BEFORE INSERT ON histgis.atom_geom_anr
            FOR EACH ROW EXECUTE FUNCTION histgis.banc_atom_geom_anr_excl();"
echo "== 82 joué"

# --- 5. ce que seul ce banc peut dire ---------------------------------------
echo
echo "== 1. un polygone par atome et par date (doit valoir 0)"
psql -c "SELECT count(*) AS chevauchements
           FROM histgis.atom_geom_anr a JOIN histgis.atom_geom_anr b
             ON a.atom_id = b.atom_id AND a.ctid < b.ctid AND a.periode && b.periode;"

echo "== 2. effectifs attendus : 37 618 à 1870, 38 006 à 1940"
psql -c "SELECT count(*) FILTER (WHERE periode @> '1870-01-01'::date) AS a_1870,
                count(*) FILTER (WHERE periode @> '1940-01-01'::date) AS a_1940
           FROM histgis.atom_geom_anr;"

echo "== 3. R2 : les 66 doublons exacts sont-ils tombés ?"
psql -c "SELECT (SELECT count(*) FROM histgis.anr_commune) AS lignes_anr,
                (SELECT count(DISTINCT (poly_id, geom, startdt, enddt)) FROM histgis.anr_commune) AS distinctes;"

echo "== 4. aucune fraction n'a reçu de polygone ANR (doit valoir 0)"
psql -c "SELECT count(*) FROM histgis.atom_geom_anr g
           JOIN histgis.atom a ON a.atom_id = g.atom_id WHERE a.fraction;"

echo "== 5. R3 : les variantes écartées sont-elles absentes ? (doit valoir 0)"
psql -c "SELECT count(*) FROM histgis.atom_geom_anr g
           JOIN histgis.anr_variante v ON v.poly_id = g.poly_id
          WHERE v.verdict <> 'retenu';"

echo "== 6. rejouabilité (le compte doit être identique)"
AVANT=$(psql -tAc "SELECT count(*) FROM histgis.atom_geom_anr;")
psql -q -v ON_ERROR_STOP=1 -v variantes=build/anr_variantes.csv \
     -f "$BANC/82_banc.sql" > "$BANC/82.rejeu.out" 2>&1 \
    || { echo "== ÉCHEC AU REJEU"; tail -40 "$BANC/82.rejeu.out"; exit 1; }
APRES=$(psql -tAc "SELECT count(*) FROM histgis.atom_geom_anr;")
if [ "$AVANT" = "$APRES" ]; then echo "   $AVANT puis $APRES — idempotent"
else echo "   REJEU NON IDEMPOTENT : $AVANT puis $APRES"; exit 1; fi

echo "== 7. les atomes doublons qu'ANR tranche"
psql -c "SELECT count(*) AS n FROM histgis.a82_doublon;"

echo
cat "$BANC/82.out"

# --- 8. 83_anr_ecart_couverture.sql, en lecture seule --------------------------
# Le banc n'a pas `scission_trace` : le fichier doit s'en passer sans échouer,
# et c'est précisément ce qu'on vérifie ici. Les effectifs, eux, ne valent rien —
# le banc n'a pas les atomes que `11`, `15`, `41` et `46` ajoutent à la base.
echo
echo "== 8. 83 (diagnostic) passe-t-il sans scission_trace ?"
sed -e "s/geometry(MultiPolygon, 2154)/text/g" sql/83_anr_ecart_couverture.sql > "$BANC/83_banc.sql"
if psql -v ON_ERROR_STOP=1 -v date=1870-01-01 -f "$BANC/83_banc.sql" > "$BANC/83.out" 2>&1; then
    echo "   oui"
    sed -n '/1. de quoi/,/^$/p' "$BANC/83.out" | head -12
else
    echo "== ÉCHEC 83"; tail -30 "$BANC/83.out"; exit 1
fi

-- ============================================================================
-- histgis — 25_pseudo_canton.sql : Marseille et Lyon, 1999-2012
--
--   psql -d histgis -1 -f 25_pseudo_canton.sql
--
-- Le problème, et pourquoi il n'a pas de solution fine
-- ---------------------------------------------------
-- `24` a posé les cantons de toute la France sauf deux villes. Marseille a 22
-- cantons pour 16 arrondissements, Lyon 13 pour 9 : nos atomes sont les
-- arrondissements, et le COG n'associe aucun canton à un arrondissement — il
-- les rattache à la commune entière, `typct = 4`, `cheflieu` valant 13055 ou
-- 69123.
--
-- GEOFLA tranche la question, par la négative et sans appel. Sa couche CANTON
-- (édition 2014) ne compte qu'UN canton pour Marseille et UN pour Lyon, codés
-- `CODE_CANT = '99'`, de chef-lieu 13201 et 69381. Même dispositif pour toutes
-- les communes partagées : Villeurbanne 98, Vénissieux 97, Aix 97, Arles 98,
-- Istres 95, Martigues 96. D'où 3 708 cantons GEOFLA contre 3 876 au COG.
--
-- La raison est la nôtre : GEOFLA est bâti sur la trame communale, et une
-- trame communale ne sait pas couper une commune. L'IGN bute au même endroit
-- que Gay en 1870 et que nous en 2012. **Le pseudo-canton n'est donc pas un
-- pis-aller, c'est la convention du domaine.**
--
-- Ce qui est posé ici
-- -------------------
-- Une unité par ville, portant le canton réuni de GEOFLA, à laquelle se
-- rattachent les 16 arrondissements marseillais et les 9 lyonnais. Les 35
-- cantons réels du COG ne sont PAS représentés : nous ne savons pas quel
-- arrondissement relève duquel, et l'inventer serait exactement ce que le
-- projet s'interdit depuis le garde-fou 4 de `11`.
--
-- Le rattachement n'est pas codé en dur : chaque arrondissement est affecté au
-- canton GEOFLA qui CONTIENT son point intérieur. Si les 16 arrondissements de
-- Marseille n'atterrissaient pas tous dans le même, on l'apprendrait — et ce
-- serait une information, pas un échec.
--
-- Prérequis
-- ---------
--   24_canton_moderne.sql, et la couche CANTON de GEOFLA chargée :
--
--   ogr2ogr -f PostgreSQL PG:"dbname=histgis" \
--       "$(find sources/geofla/canton2014 -name CANTON.SHP | head -1)" \
--       -nln histgis.geofla_canton -nlt MULTIPOLYGON \
--       -lco GEOMETRY_NAME=geom -a_srs EPSG:2154 -overwrite
--
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set debut '1999-01-01'
\set fin   '2013-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.geofla_canton') IS NULL THEN
        RAISE EXCEPTION 'geofla_canton absente : charger CANTON.SHP avec ogr2ogr (cf. en-tête).';
    END IF;
    IF to_regclass('histgis.cog_rat') IS NULL THEN
        RAISE EXCEPTION 'cog_rat absente : lancer load_cog.sh.';
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS geofla_canton_geom_idx ON geofla_canton USING gist (geom);

-- ---------------------------------------------------------------------------
-- 0. Trace et retrait d'un passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pseudo_canton_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM pseudo_canton_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM pseudo_canton_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM pseudo_canton_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE pseudo_canton_trace;

\echo ''
\echo '============================================================'
\echo ' MARSEILLE ET LYON — pseudo-cantons 1999-2012'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Où tombe chaque arrondissement ?
--
-- Test par point intérieur, comme partout ailleurs dans ce projet. On ne
-- suppose pas que les 16 arrondissements marseillais relèvent du même canton
-- GEOFLA : on le vérifie.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pc_arr;
CREATE TABLE pc_arr AS
SELECT a.atom_id,
       a.insee_geofla                              AS code_arr,
       g.code_dept || g.code_cant                  AS canton_geofla,
       g.code_cant, g.code_dept, g.nom_chf,
       g.code_dept || g.code_chf                   AS cheflieu
FROM   atom a
JOIN   atom_geom ag ON ag.atom_id = a.atom_id AND ag.source = 'arrondissement'
LEFT   JOIN geofla_canton g
       ON g.geom && ag.geom
      AND ST_Contains(g.geom, ST_PointOnSurface(ag.geom));

\echo ''
\echo '=== 1. Arrondissements et canton GEOFLA qui les contient ==='
SELECT canton_geofla, code_cant, nom_chf, cheflieu,
       count(*)                       AS arrondissements,
       string_agg(code_arr, ' ' ORDER BY code_arr) AS codes
FROM   pc_arr GROUP BY 1, 2, 3, 4 ORDER BY 1;

\echo ''
\echo '--- arrondissements sans canton GEOFLA (doit être vide) ---'
SELECT atom_id, code_arr FROM pc_arr WHERE canton_geofla IS NULL ORDER BY code_arr;

-- ---------------------------------------------------------------------------
-- 2. CONTRÔLE PRÉALABLE
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM pc_arr WHERE canton_geofla IS NULL;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % arrondissements hors de tout canton GEOFLA.', n;
    END IF;

    -- chaque arrondissement dans un seul canton : la jointure ne doit pas avoir
    -- dupliqué de ligne
    SELECT count(*) INTO n FROM (
        SELECT atom_id FROM pc_arr GROUP BY atom_id HAVING count(*) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % arrondissements dans plusieurs cantons GEOFLA.', n;
    END IF;

    -- l'unité visée ne doit pas déjà porter de rattachement sur 1999-2012
    SELECT count(*) INTO n
      FROM (SELECT DISTINCT canton_geofla FROM pc_arr) c
      JOIN membership mm ON mm.unit_id = c.canton_geofla AND mm.niveau = 'canton'
     WHERE mm.periode && daterange('1999-01-01', '2013-01-01', '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 3 : % rattachements existent déjà sur ces unités en 1999-2012.', n;
    END IF;

    RAISE NOTICE 'Contrôle préalable : les trois assertions passent.';
END $$;

\echo ''
\echo '=== 2. Les cantons COG que le pseudo-canton remplace ==='
\echo '    Ils ne seront PAS représentés : on ignore quel arrondissement'
\echo '    relève duquel, et l''inventer serait un rattachement au jugé.'
SELECT annee, code, count(DISTINCT canton_cog) AS cantons_cog
FROM   cog_rat WHERE code IN ('13055', '69123')
GROUP  BY annee, code ORDER BY code, annee;

-- ---------------------------------------------------------------------------
-- 3. Les unités
-- ---------------------------------------------------------------------------
WITH nouveau AS (
    SELECT DISTINCT canton_geofla, code_dept, code_cant,
           initcap(nom_chf) || ' (cantons réunis)' AS nom
    FROM   pc_arr
),
ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT n.canton_geofla, 'canton', n.code_dept::char(2), n.code_cant,
           NULL, NULL, n.nom, false
    FROM   nouveau n
    WHERE  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = n.canton_geofla)
    RETURNING unit_id
)
INSERT INTO pseudo_canton_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT DISTINCT canton_geofla, initcap(nom_chf) || ' (cantons réunis)',
           :'debut'::date, :'fin'::date
    FROM   pc_arr
    RETURNING unit_version_id
)
INSERT INTO pseudo_canton_trace (quoi, cle)
SELECT 'unit_version', unit_version_id::text FROM ins;

-- ---------------------------------------------------------------------------
-- 4. Les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, canton_geofla, 'canton', :'debut'::date, :'fin'::date
    FROM   pc_arr
    RETURNING membership_id
)
INSERT INTO pseudo_canton_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership; ANALYZE unit;

\echo ''
\echo '=== 3. Ce qui a été posé ==='
SELECT quoi, count(*) FROM pseudo_canton_trace GROUP BY quoi ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recettes ==='
\echo '--- chevauchements de membership (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- le trou 1941-1998 reste vide (doit valoir 0) ---'
SELECT count(*) AS rattachements_dans_le_trou
FROM   membership WHERE niveau = 'canton'
  AND  periode && daterange('1941-01-01', '1999-01-01', '[)');

\echo ''
\echo '--- effectifs cantonaux ---'
\echo '    1999-2012 doit gagner exactement 2 unités par rapport à 24.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1940-06-01'), ('1999-06-01'), ('2012-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'canton' ORDER BY 1;

\echo ''
\echo '--- Marseille et Lyon sont-ils couverts ? ---'
\echo '    Les 25 arrondissements doivent tous avoir un canton à ces dates.'
SELECT d::date AS date, count(*) AS arrondissements_rattaches
FROM   (VALUES ('1999-06-01'), ('2005-06-01'), ('2012-06-01')) AS t(d)
JOIN   atom_geom ag ON ag.source = 'arrondissement'
JOIN   membership m ON m.atom_id = ag.atom_id AND m.niveau = 'canton'
                   AND m.periode @> d::date
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo 'Pour tout défaire : DELETE via pseudo_canton_trace (membership, puis'
\echo 'unit_version, puis unit), puis TRUNCATE pseudo_canton_trace.'
\echo ''
\echo 'Limite à porter en note de méthode : les 22 cantons de Marseille et les'
\echo '13 de Lyon ne sont pas représentés. La ville forme un canton unique,'
\echo 'comme chez l''IGN et pour la même raison — la trame communale ne sait'
\echo 'pas couper une commune.'

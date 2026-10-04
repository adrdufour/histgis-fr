-- ============================================================================
-- 53_paris_geom_iris.sql — mettre TOUT Paris sur la même trame
--
--   python3 circo/paris_quartiers.py     # paris_quartier doit exister
--   psql -d histgis -f sql/53_paris_geom_iris.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/53_paris_geom_iris.sql
--
-- Le défaut, vu sur la carte
-- --------------------------
-- Depuis que `52` pose les circonscriptions de 1986 sur les quartiers, les
-- contours se superposent mal à partir de 1999 : des segments droits traversent
-- les circonscriptions, sans rapport avec aucune limite réelle.
--
-- Ce ne sont pas deux dessins du même territoire, ce sont **deux trames** :
--
--   les quartiers viennent de CONTOURS-IRIS ;
--   les arrondissements et les cantons parisiens viennent de GEOFLA 2011.
--
-- Les deux sont de l'IGN, mais à des niveaux de généralisation différents.
-- L'écart se mesure : **105,43 km² pour l'union des quartiers, 104,90 pour
-- GEOFLA**. Un demi-kilomètre carré, et des sommets qui ne tombent jamais au
-- même endroit.
--
-- Ce que fait ce fichier
-- ----------------------
--   « L'arrondissement de Paris est l'union de ses quatre quartiers. »
--
-- Ce n'est pas une approximation mais une identité : la trame IRIS de Paris est
-- calée sur les limites d'arrondissement, de quartier et les tronçons de rue.
-- `paris_quartiers.py` le vérifie déjà — 80 quartiers, quatre par
-- arrondissement, aucun orphelin.
--
-- Tous les atomes parisiens reçoivent donc leur géométrie de la même source,
-- et les couches coïncident au sommet près.
--
-- Deux gains, un coût
-- -------------------
-- **Gain de cohérence** : plus aucun segment parasite entre couches.
-- **Gain d'exactitude** : 105,4 km² est la surface officielle de Paris, bois
-- compris. GEOFLA 2011 en perdait un demi.
--
-- **Coût** : l'empreinte du polygone change, et c'est la clé de regroupement de
-- la carte (`md5(ST_AsEWKB(geom))`, cf. `cartes_cantons.py` — « un code est une
-- reconstruction, l'empreinte est un fait »). Les groupes parisiens seront
-- recalculés au prochain export. Rien à faire, mais il faut le savoir.
--
-- Ce que ce fichier ne touche pas
-- -------------------------------
-- Les atomes `PQ01`…`PQ80` posés par `52` : ils portent DÉJÀ la géométrie de
-- leur quartier. Les inclure reviendrait à leur donner l'arrondissement entier
-- — exactement le défaut qu'on corrige.
--
-- Réversible : `paris_geom_trace` garde la géométrie antérieure, en entier.
-- Prérequis : `paris_quartier` reconstruite ; `05_geom.sql` joué.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.paris_quartier') IS NULL THEN
        RAISE EXCEPTION E'paris_quartier absente.\n'
            '  python3 circo/paris_quartiers.py';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. L'arrondissement, reconstruit depuis ses quartiers
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_arr;
CREATE TEMP TABLE pg_arr AS
SELECT arrondissement AS insee,
       count(*)       AS quartiers,
       ST_Multi(ST_UnaryUnion(ST_Collect(geom))) AS geom
  FROM paris_quartier
 GROUP BY arrondissement;

\echo ''
\echo '=== 1. Les vingt arrondissements, depuis la trame IRIS ==='
SELECT count(*) AS arrondissements,
       min(quartiers) AS min_quartiers, max(quartiers) AS max_quartiers,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 2) AS km2
  FROM pg_arr;
-- Attendu : 20 arrondissements, 4 quartiers chacun, 105,43 km².

-- ---------------------------------------------------------------------------
-- 2. Les atomes concernés
--
-- Tout atome dont le code INSEE est parisien, SAUF ceux que `52` a posés : ils
-- portent déjà leur quartier, et leur donner l'arrondissement serait le défaut
-- même qu'on corrige.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_cible;
CREATE TEMP TABLE pg_cible AS
SELECT ag.atom_id, a.insee_geofla, a.fraction, ag.source,
       ST_Area(ag.geom) AS aire_avant,
       r.geom           AS geom_apres
  FROM atom_geom ag
  JOIN atom a ON a.atom_id = ag.atom_id
  JOIN pg_arr r ON r.insee = a.insee_geofla
 WHERE a.atom_id NOT LIKE 'PQ%';

\echo ''
\echo '=== 2. Atomes a realigner ==='
SELECT count(*) AS atomes,
       count(*) FILTER (WHERE fraction) AS dont_fractions,
       count(DISTINCT insee_geofla) AS arrondissements,
       count(DISTINCT source) AS sources_actuelles,
       round((sum(aire_avant) / 1e6)::numeric, 2) AS km2_avant
  FROM pg_cible;

\echo ''
\echo '=== 3. Ecart par arrondissement, avant / apres ==='
SELECT c.insee_geofla,
       round((c.aire_avant / 1e6)::numeric, 3)          AS km2_geofla,
       round((ST_Area(c.geom_apres) / 1e6)::numeric, 3) AS km2_iris,
       round(((ST_Area(c.geom_apres) - c.aire_avant) / 1e6)::numeric, 3) AS ecart
  FROM pg_cible c
 WHERE NOT c.fraction
 ORDER BY abs(ST_Area(c.geom_apres) - c.aire_avant) DESC
 LIMIT 8;
-- Les plus gros écarts doivent être les 16e et 12e — les bois de Boulogne et
-- de Vincennes. S'ils sont ailleurs, la trame IRIS ne dit pas ce qu'on croit.

\if :{?appliquer}

DROP TABLE IF EXISTS paris_geom_trace;
CREATE TABLE paris_geom_trace AS
SELECT ag.atom_id, ag.geom AS geom_avant, ag.source AS source_avant,
       now() AS pose_le
  FROM atom_geom ag
 WHERE ag.atom_id IN (SELECT atom_id FROM pg_cible);

INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('paris_iris', '53_paris_geom_iris.sql',
     'arrondissement = union de ses quartiers (CONTOURS-IRIS, Licence Ouverte 2.0)')
ON CONFLICT (source) DO NOTHING;

UPDATE atom_geom ag
   SET geom = c.geom_apres, source = 'paris_iris'
  FROM pg_cible c
 WHERE c.atom_id = ag.atom_id;

ANALYZE atom_geom;

\echo ''
\echo '=== 4. Apres alignement ==='
SELECT count(*) AS atomes_realignes,
       round((sum(ST_Area(ag.geom)) FILTER (WHERE NOT a.fraction) / 1e6)::numeric, 2)
           AS km2_paris_entiers
  FROM atom_geom ag
  JOIN atom a ON a.atom_id = ag.atom_id
 WHERE ag.source = 'paris_iris';
-- km2_paris_entiers doit valoir 105,43 : les vingt arrondissements, une fois.

\echo ''
\echo '=== 5. Les quartiers coincident-ils avec leur arrondissement ? ==='
SELECT count(*) AS quartiers_hors_de_leur_arrondissement
  FROM paris_quartier q
  JOIN pg_arr r ON r.insee = q.arrondissement
 WHERE NOT ST_CoveredBy(q.geom, ST_Buffer(r.geom, 0.01));
-- Attendu : 0. C'est vrai par construction — l'union contient ses parts — mais
-- une geometrie invalide le ferait echouer, et il vaut mieux le savoir ici.

\echo ''
\echo '=== 6. Pour tout defaire ==='
\echo '    UPDATE atom_geom ag SET geom = t.geom_avant, source = t.source_avant'
\echo '      FROM paris_geom_trace t WHERE t.atom_id = ag.atom_id;'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

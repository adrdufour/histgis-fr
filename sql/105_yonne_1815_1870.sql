-- ============================================================================
-- histgis — 105_yonne_1815_1870.sql : l'Yonne avant 1870, cantons et circos
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/105_yonne_1815_1870.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/105_yonne_1815_1870.sql
--
-- Prérequis : `82` (atom_geom_anr, anr_commune) et `64` (c15_composition).
-- `64` n'est PAS dans `rejouer_apres_rebuild.sh` : après un rebuild, le jouer
-- à la main avant celui-ci.
--
-- POURQUOI ON PEUT ÉCRIRE, ALORS QUE `64` S'Y REFUSAIT
-- ====================================================
-- `64` (22 août) : « les communes ont bougé de 1815 à 1870, et nous n'avons
-- aucune source ». ANR en est une depuis `82`. `sql/diag_yonne_1815.sql`,
-- joué le 4 octobre 2026, a mesuré ce qu'elle dit pour le 89 :
--
--   * 481 communes ANR en 1815, AUCUNE disparue avant 1870 ; 473 au polygone
--     identique en 1870, 8 retouchées (35,16 km² d'écart cumulé) ;
--   * couverture complète : 0,00 km² de 1870 sans commune en 1815 ;
--   * 477 communes entièrement dans un canton de 1870, et c'est le canton de
--     leur atome ;
--   * 4 « à cheval », toutes expliquées :
--       - Sens et Auxerre : les 4 fractions, dont la géométrie de repli est la
--         commune entière — la limite connue des fractions, pas un désaccord.
--         Sens-Nord/Sud sont dans la même circo à toutes les périodes, et
--         Auxerre-Est/Ouest aussi : AUCUNE VILLE À COUPER avant 1870 ;
--       - Nailly (Sens-Sud) et Brannay (Chéroy) : Saint-Sérotin naît en 1861
--         de leurs morceaux, et de Lixy, Villeperrot, Pont-sur-Yonne, et va au
--         canton de Pont-sur-Yonne. Une parcelle change donc de canton en 1861 —
--         mais le modèle est par commune, et les polygones ANR datés suivent :
--         avant 1861 Nailly est entière dans Sens-Sud. Les quatre cantons sont
--         dans la même circonscription à toutes les périodes.
--
-- Le rattachement de 1815 n'est donc pas deviné : **chaque atome garde son
-- canton de 1870**, ce que Gaudillère (aucun canton modifié 1815-1870) et ANR
-- (aucune commune à cheval hors fractions et Saint-Sérotin) disent ensemble.
--
-- LA VIE NE COMMENCE PAS AVANT LA NAISSANCE — la règle de `90` et `91`
-- =====================================================================
-- Un atome n'est rattaché qu'à partir de son premier polygone ANR :
--     Foissy-lès-Vézelay   1837   (prise sur Saint-Père, canton de Vézelay)
--     Saint-Sérotin        1861   (Pont-sur-Yonne)
--     Thory                1869   (prise sur Lucy-le-Bois, Avallon)
--     Sougères-sur-Sinotte 1870   (prise sur Gurgy, Seignelay) -> rien avant 1870
--     Les Clérimois        1888 chez ANR : son rattachement de 1870 est une
--                          inférence de `11` ; rien n'est posé avant.
-- Les 4 fractions (Sens, Auxerre) n'ont pas de polygone ANR (`82`) : leur
-- naissance est lue sur la commune-mère dans `anr_commune`.
--
-- CE QUI EST POSÉ
-- ===============
--   * CANTON : chaque atome, de max(1815, naissance) au 1er janvier 1870, dans
--     son canton de 1870. Premiers rattachements cantonaux d'avant 1870 de la
--     base — la Seine (`91`) n'a posé que des circos.
--   * CIRCO, d'après `c15_composition` (lue par `circo/remonte_1815.py`) :
--         1815-1820   5 collèges d'arrondissement   89-Auxerre@1815 …
--         1820-1831   3 circonscriptions            89-01@1820 …
--         1831-1848   5, « même découpage qu'en 1815 »  89-Auxerre@1831 …
--         1852-1870   3 circonscriptions            89-01@1852 …
--   * 1848-1852 : l'unité départementale `L8901@1848`, scrutin de liste —
--     comme `57`/`90` pour la Seine. `64` et `remonte_1815.py` laissent cette
--     période vide parce qu'il n'y a pas de DÉCOUPAGE à transcrire ; il y a
--     pourtant une circonscription, le département, et `L8901@1870` en est
--     la sœur. Mettre `-v sans1848=1` pour ne pas la poser.
--
-- LE RÉGIME, ET CE QU'IL N'AFFIRME PAS — la règle de `54`
-- ========================================================
-- `unit` impose 'liste' ou 'uninominal'. Les collèges de la Restauration et de
-- la monarchie de Juillet n'entrent dans aucune des deux cases : `uninominal`
-- y est inscrit faute de mieux, avec `provisoire = true`. Le Second Empire
-- (1852-1870) est réellement uninominal, et 1848-1852 réellement de liste :
-- `provisoire = false`.
--
-- CONVENTION D'IDENTIFIANT — celle de `54` : département, circonscription,
-- millésime d'ouverture de la division. Les collèges sont nommés par leur
-- arrondissement, comme l'atlas les nomme.
--
-- Réversible : `yonne_1815_trace`. Le fichier retire sa trace avant de
-- reposer, et se rejoue sans risque.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set dep '89'
\set d70 '1870-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL
       OR to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql (et charger anr_commune).';
    END IF;
    IF to_regclass('histgis.c15_composition') IS NULL THEN
        RAISE EXCEPTION E'PRÉREQUIS : c15_composition absente.\n'
            '  psql -d histgis -f sql/64_composition_1815_stage.sql';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS yonne_1815_trace (
    quoi text NOT NULL, cle text NOT NULL, valeur text,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- ---------------------------------------------------------------------------
-- 1. Les atomes de l'Yonne à 1870, leur canton, leur naissance
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS y15_atome;
CREATE TEMP TABLE y15_atome AS
WITH a70 AS (
    SELECT m.atom_id, a.cassini, a.fraction, m.unit_id AS canton_id,
           u.nom AS canton
      FROM membership m
      JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
      JOIN atom a ON a.atom_id = m.atom_id
     WHERE m.niveau = 'canton' AND m.periode @> :'d70'::date
       AND u.dep = :'dep'
), ne_anr AS (                 -- les atomes non-fractions : leur propre polygone
    SELECT atom_id, min(lower(periode)) AS ne_le
      FROM atom_geom_anr GROUP BY atom_id
), ne_mere AS (                -- les fractions : la commune-mère, dans ANR brut
    SELECT an.id_com::text AS cassini,
           make_date(min((nullif(an.startdt::text, ''))::numeric::int), 1, 1) AS ne_le
      FROM anr_commune an
     WHERE an.id_com::text IN (SELECT cassini FROM a70 WHERE fraction)
     GROUP BY 1
)
SELECT a70.*,
       CASE WHEN a70.fraction THEN nm.ne_le ELSE na.ne_le END AS ne_le
  FROM a70
  LEFT JOIN ne_anr  na ON na.atom_id = a70.atom_id
  LEFT JOIN ne_mere nm ON nm.cassini = a70.cassini;

\echo ''
\echo '=== 1. Les atomes de l''Yonne à 1870, et quand ils naissent ==='
SELECT count(*)                                              AS atomes,
       count(*) FILTER (WHERE fraction)                      AS fractions,
       count(*) FILTER (WHERE ne_le <= DATE '1815-01-01')    AS vivants_en_1815,
       count(*) FILTER (WHERE ne_le >  DATE '1815-01-01'
                          AND ne_le <  :'d70'::date)         AS nes_1815_1870,
       count(*) FILTER (WHERE ne_le >= :'d70'::date)         AS nes_en_1870_ou_apres,
       count(*) FILTER (WHERE ne_le IS NULL)                 AS sans_naissance
  FROM y15_atome;
-- Attendu : 488 atomes, 4 fractions, 483 vivants en 1815, 3 nés entre-temps,
-- 2 nés en 1870 ou après (Sougères, Les Clérimois), 0 sans naissance.

SELECT atom_id, cassini, canton, ne_le
  FROM y15_atome
 WHERE ne_le > DATE '1815-01-01' OR ne_le IS NULL
 ORDER BY ne_le NULLS FIRST;
-- Attendu : Foissy 1837, Saint-Sérotin 1861, Thory 1869, Sougères 1870,
-- Les Clérimois 1888.

-- ---------------------------------------------------------------------------
-- 2. Les divisions et leurs unités
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS y15_div;
CREATE TEMP TABLE y15_div AS
SELECT DISTINCT
       c.depuis, c.jusqu, c.circonscription, c.canton,
       make_date(c.depuis, 1, 1) AS du,
       make_date(c.jusqu,  1, 1) AS au,
       CASE WHEN c.circonscription ~ '^[0-9]+$'
            THEN :'dep' || '-' || lpad(c.circonscription, 2, '0')
            ELSE :'dep' || '-' || c.circonscription END
         || '@' || c.depuis                                  AS unit_id,
       CASE WHEN c.circonscription ~ '^[0-9]+$'
            THEN 'Yonne ' || c.circonscription
                 || CASE WHEN c.circonscription = '1' THEN 're' ELSE 'e' END
                 || ' circonscription'
            ELSE 'Yonne — collège '
                 || CASE WHEN c.circonscription ~* '^[aeiouyéèêâîôû]'
                         THEN 'd''' ELSE 'de ' END
                 || c.circonscription END                    AS nom,
       (c.depuis < 1848)                                     AS provisoire
  FROM c15_composition c
 WHERE c.dep = :'dep';

\if :{?sans1848}
\else
-- 1848-1852 : le département entier, une seule unité, de liste. Elle n'a pas
-- de canton dans `c15_composition` : chaque canton vivant y est ajouté.
INSERT INTO y15_div
SELECT DISTINCT 1848, 1852, 'département', canton,
       DATE '1848-01-01', DATE '1852-01-01',
       'L' || :'dep' || '01@1848',
       'Yonne — scrutin de liste départemental', false
  FROM y15_atome;
\endif

\echo ''
\echo '=== 2. Les divisions ==='
SELECT depuis, jusqu, count(DISTINCT unit_id) AS circos,
       count(*) AS cantons,
       string_agg(DISTINCT unit_id, ', ') AS unites
  FROM y15_div GROUP BY 1, 2 ORDER BY 1;
-- Attendu : 1815 5/37, 1820 3/37, 1831 5/37, 1848 1/37, 1852 3/37.

\echo ''
\echo '=== 2 bis. Garde-fou : tout canton de 1870 trouve-t-il sa circo à chaque division ? ==='
SELECT d.depuis, k.canton AS canton_sans_circo
  FROM (SELECT DISTINCT depuis FROM y15_div) d
 CROSS JOIN (SELECT DISTINCT canton FROM y15_atome) k
 WHERE NOT EXISTS (SELECT 1 FROM y15_div x
                    WHERE x.depuis = d.depuis AND x.canton = k.canton)
 ORDER BY 1, 2;
-- Attendu : aucune ligne.

-- ---------------------------------------------------------------------------
-- 3. Ce qui va être posé
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS y15_pose;
CREATE TEMP TABLE y15_pose AS
SELECT 'canton'::text AS niveau, 'cantons 1815-1870'::text AS division,
       a.atom_id, a.canton_id AS unit_id,
       greatest(DATE '1815-01-01', a.ne_le) AS valid_from,
       :'d70'::date                          AS valid_to,
       a.ne_le
  FROM y15_atome a
 WHERE a.ne_le < :'d70'::date
UNION ALL
SELECT 'circo', d.depuis || '-' || d.jusqu,
       a.atom_id, d.unit_id,
       greatest(d.du, a.ne_le), d.au, a.ne_le
  FROM y15_atome a
  JOIN y15_div d ON d.canton = a.canton
 WHERE a.ne_le < d.au;

\echo ''
\echo '=== 3. Ce que chaque division recevra ==='
SELECT niveau, division,
       count(DISTINCT unit_id)                                   AS unites,
       count(*)                                                  AS rattachements,
       count(*) FILTER (WHERE valid_from > (SELECT min(p2.valid_from)
                                              FROM y15_pose p2
                                             WHERE p2.division = p.division)) AS entrees_en_cours
  FROM y15_pose p
 GROUP BY 1, 2 ORDER BY 1, 2;
-- Attendu :
--     canton   cantons 1815-1870   37 unités   486   (3 entrées en cours)
--     circo    1815-1820            5          483   0
--     circo    1820-1831            3          483   0
--     circo    1831-1848            5          484   1  (Foissy, 1837)
--     circo    1848-1852            1          484   0
--     circo    1852-1870            3          486   2  (Saint-Sérotin, Thory)
--     total circo 2 420, et 2 906 rattachements en tout.

\echo ''
\echo '=== 4. Garde-fou : ces périodes sont-elles libres pour ces atomes ? ==='
SELECT p.niveau, p.division, count(*) AS rattachements_deja_presents
  FROM y15_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
 WHERE NOT EXISTS (SELECT 1 FROM yonne_1815_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle = m.membership_id::text)
 GROUP BY 1, 2 ORDER BY 1, 2;
-- Attendu : aucune ligne.

\if :{?appliquer}

-- Retirer sa trace AVANT de juger — la leçon de `55`.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM yonne_1815_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM yonne_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM yonne_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE yonne_1815_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM y15_atome WHERE ne_le IS NULL;
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) sans naissance ANR. Voir la recette 1.', n;
    END IF;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT depuis FROM y15_div) d
     CROSS JOIN (SELECT DISTINCT canton FROM y15_atome) k
     WHERE NOT EXISTS (SELECT 1 FROM y15_div x
                        WHERE x.depuis = d.depuis AND x.canton = k.canton);
    IF n > 0 THEN
        RAISE EXCEPTION '% (division, canton) sans circonscription. Voir la '
            'recette 2 bis.', n;
    END IF;

    SELECT count(*) INTO n
      FROM y15_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) existent déjà. Ce fichier COMBLE, '
            'il ne remplace pas. Voir la recette 4.', n;
    END IF;

    SELECT count(*) INTO n FROM y15_pose WHERE valid_from >= valid_to;
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) de durée nulle ou négative.', n;
    END IF;

    -- Une unité neuve ne doit pas déjà exister : ce fichier ne s'approprie
    -- pas l'unité d'un autre.
    SELECT count(*) INTO n
      FROM (SELECT DISTINCT unit_id FROM y15_div) d
      JOIN unit u ON u.unit_id = d.unit_id;
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) de ce fichier existent déjà en base, hors '
            'de sa trace.', n;
    END IF;
END $$;

-- Les unités.
WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT DISTINCT d.unit_id, 'circo', :'dep',
           split_part(d.unit_id, '@', 1),
           CASE WHEN d.depuis = 1848 THEN 'liste' ELSE 'uninominal' END,
           d.depuis, d.nom, d.provisoire
      FROM y15_div d
    RETURNING unit_id
)
INSERT INTO yonne_1815_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT d.unit_id, d.nom, d.du, d.au FROM y15_div d;

-- Les rattachements.
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM y15_pose
    RETURNING membership_id
)
INSERT INTO yonne_1815_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM yonne_1815_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 17 unités, 2 906 rattachements (486 canton + 2 420 circo) ;
-- 16 unités et 2 422 avec -v sans1848=1.

\echo ''
\echo '=== 6. L''Yonne année par année ==='
SELECT v.d AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'canton') AS atomes_canton,
       count(DISTINCT m.unit_id) FILTER (WHERE m.niveau = 'canton') AS cantons,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'circo')  AS atomes_circo,
       count(DISTINCT m.unit_id) FILTER (WHERE m.niveau = 'circo')  AS circos
  FROM (VALUES ('1817-06-01'::date), ('1825-06-01'), ('1840-06-01'),
               ('1850-06-01'), ('1855-06-01'), ('1865-06-01'),
               ('1869-06-01'), ('1870-06-01')) v(d)
  JOIN membership m ON m.periode @> v.d
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau AND u.dep = :'dep'
 GROUP BY v.d ORDER BY v.d;
-- Attendu :
--     1817  483 / 37   483 / 5
--     1825  483 / 37   483 / 3
--     1840  484 / 37   484 / 5
--     1850  484 / 37   484 / 1
--     1855  484 / 37   484 / 3
--     1865  485 / 37   485 / 3
--     1869  486 / 37   486 / 3
--     1870  ce que la base avait déjà : 488 atomes au canton.

\echo ''
\echo '=== 7. Aucun atome dans deux unités à la même date, France entière ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode FROM membership
         GROUP BY 1, 2, 3 HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY 1;
-- Attendu : aucune ligne (la contrainte EXCLUDE l'interdit déjà).

\echo ''
\echo '=== 8. Ce que la carte rend ==='
SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'carte_partition_atome')
       AS a_84 \gset
\if :a_84
-- UNE DATE PAR REQUÊTE. Depuis `99` (3 octobre 2026), `carte_partition_atome`
-- est en plpgsql et passe par des tables temporaires (`t84_*`, `t99_*`) qu'elle
-- crée et détruit à chaque appel. Appelée pour plusieurs dates dans UNE requête
-- (`LATERAL` sur un `VALUES`), le deuxième appel détruit les tables que le
-- premier lit encore : « could not open relation with OID ». Premier jeu du
-- 4 octobre, et la recette a emporté la pose entière, le fichier étant joué
-- en `-1`.
--
-- D'où aussi les deux réglages : une RECETTE ne doit jamais annuler une POSE.
-- `ON_ERROR_ROLLBACK` fait de chaque requête un point de reprise ; un échec
-- ici s'affiche, et la transaction continue jusqu'au COMMIT.
\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on
SELECT DATE '1817-06-01' AS a_la_date, count(*) AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 1) AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                          AS recouvrement_km2
  FROM carte_partition_atome(DATE '1817-06-01', :'dep');
SELECT DATE '1840-06-01' AS a_la_date, count(*) AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 1) AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                          AS recouvrement_km2
  FROM carte_partition_atome(DATE '1840-06-01', :'dep');
SELECT DATE '1855-06-01' AS a_la_date, count(*) AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 1) AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                          AS recouvrement_km2
  FROM carte_partition_atome(DATE '1855-06-01', :'dep');
SELECT DATE '1870-06-01' AS a_la_date, count(*) AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 1) AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                          AS recouvrement_km2
  FROM carte_partition_atome(DATE '1870-06-01', :'dep');
\set ON_ERROR_ROLLBACK off
\set ON_ERROR_STOP on
-- Attendu : autour de 7 450 km² à chaque date (`diag_yonne_1815` : 7 450,0
-- à 1870, 7 451,9 pour la trame de 1815), 483 / 484 / 484 / 488 atomes.
\else
\echo '    84 pas encore joué : recette à relire après lui, en rejouant'
\echo '    ce fichier avec -v appliquer=1 (il retire sa trace avant de reposer).'
\endif

\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

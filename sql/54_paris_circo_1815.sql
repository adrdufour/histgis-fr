-- ============================================================================
-- 54_paris_circo_1815.sql — la base remonte à 1815, pour Paris
--
--   python3 circo/paris_quartiers_1815.py    # charge paris_quartier_1815
--   python3 circo/paris_circo_1815.py        # produit paris_circo_1815.csv
--   psql -d histgis -v src=circo/paris_circo_1815.csv \
--        -f sql/54_paris_circo_1815.sql                       -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -v src=circo/paris_circo_1815.csv \
--        -f sql/54_paris_circo_1815.sql
--
-- Ce que ce fichier ajoute
-- ------------------------
-- Les cinq divisions électorales que `paris_circo.py` écarte — **1815,
-- 1820-1831, 1831-1848, 1852-1857, 1857-1863** — parce qu'elles emploient le
-- système des douze arrondissements et quarante-huit quartiers, et non celui
-- des 80. « Ce n'est pas un échec mais une frontière », dit le script. La
-- frontière tombe ici : ALPAGE fournit la trame des 48.
--
-- **La base commençait en 1870. Elle commencera en 1815**, pour Paris seul.
--
-- Ce qui a été vérifié avant d'arriver ici
-- ----------------------------------------
--   * la trame : 48 quartiers, 12 arrondissements, quatre chacun, numéros 1 à
--     48 sans trou ; **0,000 km² hors du Paris de 1860** — l'annexion n'a fait
--     qu'ajouter, et l'emboîtement le confirme ;
--   * le vocabulaire : 48 clés, dont 41 directes et 7 corrections nommées une
--     à une, y compris le renommage du Jardin du Roi en Jardin des Plantes ;
--   * la partition : **les cinq divisions citent 48 quartiers sur 48**, sans un
--     non résolu ni un quartier coupé. Une division électorale partitionne la
--     ville ; cette contrainte ne vient pas de nous, et 48 éléments ne
--     tombent pas juste par hasard cinq fois de suite.
--
-- Trois réserves, portées dans la donnée et pas seulement ici
-- -----------------------------------------------------------
-- **1. La trame n'est pas un instantané.** Les levés de Vasserot s'étalent de
-- 1810 à 1836. Une limite de 1815 peut être dessinée d'après un levé de 1836 :
-- anachronisme d'un quart de siècle, inhérent à la source. La colonne
-- `date_leve` de `paris_quartier_1815` le porte quartier par quartier.
--
-- **2. Le régime de scrutin est une contrainte du modèle, pas une donnée.**
-- `unit` impose `regime IN ('liste','uninominal')`. Les scrutins de la
-- Restauration et de la monarchie de Juillet — collèges d'arrondissement, cens,
-- double vote — n'entrent dans aucune des deux cases. On inscrit `uninominal`
-- parce qu'il faut inscrire quelque chose. **Cette valeur n'est pas une
-- affirmation**, et `provisoire = true` le dit dans la donnée elle-même.
--
-- **3. 1848-1852 n'est pas transcrit, et ce n'est pas une lacune.** Le
-- gouvernement provisoire de 1848 rétablit le scrutin plurinominal dans le
-- cadre du DÉPARTEMENT : il n'existe aucune circonscription à l'intérieur de
-- Paris entre 1848 et 1852, donc rien à transcrire. C'est
-- `57_paris_circo_1848.sql` qui pose l'unité départementale unique.
--
-- Et le trou 1863-1870 n'est pas comblé ici : les divisions 1863-1869 et
-- 1869-1870 existent dans la transcription mais relèvent de la trame des 80.
--
-- Licence
-- -------
-- Géométrie ALPAGE, couche 42 (atlas Perrot sur plans Vasserot). Base sous
-- ODbL, **cartes produites sous CC-BY-SA 2.0 obligatoire**, crédit nominatif
-- « © ALPAGE : Anne-Laure Bethe ». Voir
-- `42-Vasserot_quartiers_v1L93/LICENCE_ET_CREDIT.md`.
--
-- Réversible : `paris_1815_trace`, section 6.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?src}
\else
  \set src 'circo/paris_circo_1815.csv'
\endif

DO $$
BEGIN
    IF to_regclass('histgis.paris_quartier_1815') IS NULL THEN
        RAISE EXCEPTION E'paris_quartier_1815 absente.\n'
            '  python3 circo/paris_quartiers_1815.py';
    END IF;
END $$;

DROP TABLE IF EXISTS pv_src;
CREATE TABLE pv_src (
    periode text, du date, au date, circo text, quartier smallint, nom text
);
\set cmd '\\copy pv_src FROM ' :'src' ' WITH (FORMAT csv, HEADER true)'
:cmd

-- L'identifiant d'unité suit la convention du projet — `75-01@1986` pour la
-- métropole moderne : département, numéro, millésime du découpage. Le millésime
-- est ici l'année d'ouverture de la division.
DROP TABLE IF EXISTS pv_ligne;
CREATE TEMP TABLE pv_ligne AS
SELECT s.*,
       '75-' || lpad(s.circo, 2, '0') || '@'
              || extract(year FROM s.du)::int         AS unit_id,
       'PV'  || lpad(s.quartier::text, 2, '0')        AS atom_id,
       extract(year FROM s.du)::int                   AS segment
  FROM pv_src s;

\echo ''
\echo '=== 1. Ce que la source donne ==='
SELECT periode, min(du) AS du, max(au) AS au,
       count(DISTINCT unit_id) AS circos,
       count(DISTINCT quartier) AS quartiers
  FROM pv_ligne GROUP BY periode ORDER BY min(du);
-- Attendu : 4, 7, 12, 7 et 8 circonscriptions, 48 quartiers chacune.

\echo ''
\echo '=== 2. Un quartier dans deux circonscriptions a la meme date ? ==='
SELECT periode, quartier, count(DISTINCT unit_id) AS circos
  FROM pv_ligne GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1;
-- Attendu : aucune ligne. La contrainte EXCLUDE de `membership` refuserait.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS paris_1815_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM paris_1815_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM paris_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM atom a
 WHERE EXISTS (SELECT 1 FROM paris_1815_trace t
                WHERE t.quoi = 'atom' AND t.cle = a.atom_id);
TRUNCATE paris_1815_trace;

-- ---------------------------------------------------------------------------
-- 1. Les 48 atomes
--
-- `insee_geofla` reçoit l'arrondissement MODERNE qui contient le quartier.
-- Ce n'est pas une identité historique — les douze de 1815 ne sont pas les
-- vingt d'aujourd'hui — mais un rattachement de localisation, qui donne à
-- l'atome un nom et un département sur la carte. L'affirmation est faible et
-- vérifiable : « ce territoire est aujourd'hui dans tel arrondissement ».
-- ---------------------------------------------------------------------------
INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('vasserot', '54_paris_circo_1815.sql',
     'ALPAGE couche 42 — atlas Perrot sur plans Vasserot 1810-1836. ODbL ; '
     'cartes produites en CC-BY-SA 2.0, credit © ALPAGE : Anne-Laure Bethe')
ON CONFLICT (source) DO NOTHING;

WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, insee_geofla)
    SELECT 'PV' || lpad(v.quartier::text, 2, '0'),
           'PV' || lpad(v.quartier::text, 2, '0'),
           true,
           (SELECT a.insee_geofla
              FROM atom a
              JOIN atom_geom g ON g.atom_id = a.atom_id
             WHERE a.insee_geofla LIKE '751%'
               AND a.atom_id NOT LIKE 'P%'
               AND ST_Intersects(g.geom, ST_PointOnSurface(v.geom))
             LIMIT 1)
      FROM paris_quartier_1815 v
    RETURNING atom_id
)
INSERT INTO paris_1815_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT 'PV' || lpad(quartier::text, 2, '0'), geom, 'vasserot', false
  FROM paris_quartier_1815;

-- ---------------------------------------------------------------------------
-- 2. Les unités — `provisoire` marque le régime non attesté
-- ---------------------------------------------------------------------------
WITH u AS (
    SELECT DISTINCT unit_id, circo, segment, periode FROM pv_ligne
), ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT u.unit_id, 'circo', '75', '75-' || lpad(u.circo, 2, '0'),
           'uninominal', u.segment,
           'Paris ' || u.circo || 'e circonscription (' || u.periode || ')',
           true
      FROM u
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO paris_1815_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT l.unit_id,
       'Paris ' || l.circo || 'e circonscription', l.du, l.au
  FROM pv_ligne l
 WHERE EXISTS (SELECT 1 FROM paris_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = l.unit_id);

-- ---------------------------------------------------------------------------
-- 3. Les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT l.atom_id, l.unit_id, 'circo', l.du, l.au FROM pv_ligne l
    RETURNING membership_id
)
INSERT INTO paris_1815_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE atom; ANALYZE atom_geom; ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Pose ==='
SELECT quoi, count(*) FROM paris_1815_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 48 atomes, 38 unites, 240 rattachements.

\echo ''
\echo '=== 4. Paris a cinq dates, avant 1870 ==='
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) AS quartiers,
       count(DISTINCT m.unit_id) AS circonscriptions,
       round((ST_Area(ST_Union(g.geom)) / 1e6)::numeric, 2) AS km2
  FROM (VALUES ('1816-06-01'::date), ('1825-06-01'), ('1840-06-01'),
               ('1850-06-01'), ('1855-06-01'), ('1860-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN atom_geom g ON g.atom_id = m.atom_id
 GROUP BY d ORDER BY d;
-- 1850 doit etre VIDE : c'est le trou 1848-1852, et il doit se voir.
-- Les autres : 48 quartiers, 32,70 km².

\echo ''
\echo '=== 5. La base commence desormais en... ==='
SELECT min(valid_from) AS premiere_date, max(valid_to) AS derniere
  FROM membership;

\echo ''
\echo '=== 6. Pour tout defaire ==='
\echo '    DELETE membership, puis unit, puis atom, via paris_1815_trace.'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

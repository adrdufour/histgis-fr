-- ============================================================================
-- histgis — 31_marseille_inventaire.sql : ce que la base porte pour Marseille
--
--   psql -d histgis -f 31_marseille_inventaire.sql
--
-- Avant de géoréférencer les cartes de Gaudillère, savoir combien de polygones
-- sont nécessaires, pour quels atomes et sur quelles périodes.
--
-- Ce que l'atlas annonce, à confronter :
--   1801-1886 :  6 cantons
--   1886-1901 :  8 cantons
--   1901-1973 : 12 cantons
--
-- Et ce que la base porte aujourd'hui : des atomes-fractions qui partagent
-- TOUS le polygone de la ville entière (source `union_prefixe`), d'où les
-- 1 176 km² de double comptage du groupe `132` mesurés par `12`.
--
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' MARSEILLE — inventaire avant géoréférencement'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Les atomes marseillais, toutes époques
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Les atomes ==='
SELECT ag.source, a.fraction,
       count(*)                                        AS atomes,
       round(avg(ST_Area(ag.geom) / 1e6)::numeric, 2)  AS km2_moyen,
       count(DISTINCT ST_AsEWKB(ag.geom))              AS geometries_distinctes,
       left(string_agg(a.atom_id, ' ' ORDER BY a.atom_id), 70) AS exemples
FROM   atom a JOIN atom_geom ag ON ag.atom_id = a.atom_id
WHERE  a.insee_geofla = '13055'
   OR  a.insee_geofla LIKE '132__'
GROUP  BY ag.source, a.fraction
ORDER  BY 3 DESC;

-- ---------------------------------------------------------------------------
-- 2. Combien de cantons distincts, année par année, pour la période ancienne
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Cantons de Marseille selon la base, 1870-1940 ==='
\echo '    À confronter à l''atlas : 6 jusqu''en 1886, 8 de 1886 à 1901,'
\echo '    12 de 1901 à 1973.'
SELECT d::date AS date,
       count(DISTINCT m.unit_id) AS cantons,
       count(DISTINCT m.atom_id) AS atomes,
       string_agg(DISTINCT m.unit_id, ' ' ORDER BY m.unit_id) AS unit_ids
FROM   (VALUES ('1870-06-01'), ('1880-06-01'), ('1885-06-01'), ('1887-06-01'),
               ('1895-06-01'), ('1900-06-01'), ('1902-06-01'), ('1910-06-01'),
               ('1930-06-01'), ('1940-06-01')) AS t(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla = '13055'
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- les noms de ces cantons, à la fin de la série ---'
SELECT m.unit_id, coalesce(uv.nom, u.nom) AS nom,
       m.atom_id, min(m.valid_from) OVER (PARTITION BY m.unit_id) AS depuis
FROM   membership m
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla = '13055'
JOIN   unit u ON u.unit_id = m.unit_id
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> '1940-06-01'::date
WHERE  m.niveau = 'canton' AND m.periode @> '1940-06-01'::date
ORDER  BY m.unit_id;

-- ---------------------------------------------------------------------------
-- 3. Le coût actuel du polygone partagé
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Ce que coûte le polygone unique ==='
\echo '    Chaque fraction porte la ville entière : le territoire est compté'
\echo '    autant de fois qu''il y a de cantons.'
SELECT d::date AS date,
       count(DISTINCT m.atom_id)                                   AS fractions,
       round((max(ST_Area(ag.geom)) / 1e6)::numeric, 2)            AS km2_ville,
       round((max(ST_Area(ag.geom)) / 1e6
              * (count(DISTINCT m.unit_id) - 1))::numeric, 1)      AS km2_comptes_en_trop
FROM   (VALUES ('1870-06-01'), ('1900-06-01'), ('1940-06-01')) AS t(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla = '13055'
JOIN   atom_geom ag ON ag.atom_id = a.atom_id
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. Les arrondissements, période moderne
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Les arrondissements (période moderne) ==='
SELECT a.insee_geofla, a.atom_id,
       round((ST_Area(ag.geom) / 1e6)::numeric, 2) AS km2,
       (SELECT count(*) FROM membership m WHERE m.atom_id = a.atom_id AND m.niveau = 'canton') AS n_canton,
       (SELECT count(*) FROM membership m WHERE m.atom_id = a.atom_id AND m.niveau = 'circo')  AS n_circo
FROM   atom a JOIN atom_geom ag ON ag.atom_id = a.atom_id
WHERE  ag.source = 'arrondissement' AND a.insee_geofla LIKE '132%'
ORDER  BY a.insee_geofla;

\echo ''
\echo '=== Ce qu''il faudrait dessiner ==='
\echo '    Un polygone par canton et par période, soit selon l''atlas :'
\echo '      6 pour 1801-1886, 8 pour 1886-1901, 12 pour 1901-1973 = 26.'
\echo '    Mais les périodes 1886 et 1901 sont des MODIFICATIONS de la'
\echo '    précédente : en pratique 6 polygones, puis les lignes de division'
\echo '    ajoutées, ce qui réduit beaucoup le travail de saisie.'
\echo ''
\echo '    La base ne couvrant que 1870-1940, seules trois configurations'
\echo '    servent : 1870-1886, 1886-1901, 1901-1940.'

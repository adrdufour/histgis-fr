-- ===========================================================================
-- diag_99.sql — LECTURE SEULE. Deux questions laissées par la première recette
-- de `99`, le 3 octobre 2026 :
--
--   A. Avant 1941, aucune ville n'entre dans le bilan (1880, 1900 : zéro ligne,
--      Moulins compris, dont la ligne vaut depuis 1870). Le treillis de `84`
--      rend-il les fractions anciennes ? Sinon, qui prend leur sol ?
--   B. Saint-Quentin en 2000 : 5,3 ha perdus sur le polygone net, alors que la
--      ligne est conforme sur `cible_ville()`. Où sont-ils ?
--
--   psql -d histgis -f sql/diag_99.sql > sorties/diag_99.txt 2>&1
--
-- Deux treillis départementaux (03, 02) : quelques minutes.
-- ===========================================================================
\set ON_ERROR_STOP on
\pset pager off
SET search_path TO histgis, public;

\echo ''
\echo '== A1. Moulins (03190) au 1900-12-01 : atomes, appartenances, polygones'
SELECT a.atom_id, a.cassini, a.fraction, m.niveau, m.unit_id, m.valid_from, m.valid_to,
       ag.source AS src_atom_geom,
       (ga.atom_id IS NOT NULL) AS anr_a_la_date,
       round((ST_Area(coalesce(ga.geom, ag.geom)) / 1e4)::numeric, 1) AS ha
FROM   atom a
LEFT   JOIN membership m ON m.atom_id = a.atom_id AND m.periode @> DATE '1900-12-01'
LEFT   JOIN atom_geom ag ON ag.atom_id = a.atom_id
LEFT   JOIN atom_geom_anr ga ON ga.atom_id = a.atom_id AND ga.periode @> DATE '1900-12-01'
WHERE  a.insee_geofla = '03190'
   OR  a.cassini IN (SELECT cassini FROM atom WHERE insee_geofla = '03190')
ORDER  BY a.atom_id, m.niveau;

\echo ''
\echo '== A2. Les polygones ANR à la date qui couvrent le cœur de Moulins'
SELECT ga.atom_id, a.insee_geofla, a.fraction,
       round((ST_Area(ga.geom) / 1e4)::numeric, 1) AS ha,
       (SELECT string_agg(m.niveau || ':' || m.unit_id, ', ') FROM membership m
         WHERE m.atom_id = ga.atom_id AND m.periode @> DATE '1900-12-01') AS vivant_dans
FROM   atom_geom_anr ga
JOIN   atom a USING (atom_id)
WHERE  ga.periode @> DATE '1900-12-01'
  AND  ST_Intersects(ga.geom,
         (SELECT ST_PointOnSurface(cible_ville('03190', DATE '1900-12-01'))));

\echo ''
\echo '== A3. Ce que partition_un_dep (84, sans 99) rend pour Moulins au 1900-12-01'
CREATE TEMP TABLE d_a3 AS
SELECT p.atom_id, p.source, p.motif, p.dedans, p.geom
FROM   partition_un_dep(DATE '1900-12-01', '03') p;
SELECT p.atom_id, p.source, p.motif, p.dedans,
       round((ST_Area(p.geom) / 1e4)::numeric, 1) AS ha
FROM   d_a3 p JOIN atom a USING (atom_id)
WHERE  a.insee_geofla = '03190'
   OR  a.cassini IN (SELECT cassini FROM atom WHERE insee_geofla = '03190');
\echo '-- et qui, dans cette sortie, couvre le cœur de Moulins :'
SELECT p.atom_id, a.insee_geofla, a.fraction, p.source,
       round((ST_Area(p.geom) / 1e4)::numeric, 1) AS ha
FROM   d_a3 p JOIN atom a USING (atom_id)
WHERE  ST_Intersects(p.geom,
         (SELECT ST_PointOnSurface(cible_ville('03190', DATE '1900-12-01'))));

\echo ''
\echo '== A4. Combien de fractions anciennes (#, hors fraction_cog) le treillis'
\echo '       de l Allier rend-il au 1900-12-01, sur combien de vivantes ?'
SELECT (SELECT count(DISTINCT m.atom_id) FROM membership m
          JOIN atom a ON a.atom_id = m.atom_id AND a.atom_id LIKE '%#%'
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.periode @> DATE '1900-12-01' AND u.dep = '03') AS fractions_vivantes,
       (SELECT count(*) FROM d_a3 p WHERE p.atom_id LIKE '%#%') AS fractions_rendues;

\echo ''
\echo '== B1. Saint-Quentin (02691) au 2000-12-01 : polygone net contre cible ANR'
CREATE TEMP TABLE d_b AS
SELECT p.atom_id, p.geom
FROM   partition_un_dep(DATE '2000-12-01', '02') p
JOIN   atom a USING (atom_id)
WHERE  a.insee_geofla = '02691' AND a.atom_id LIKE '%#%';
SELECT atom_id, round((ST_Area(geom) / 1e4)::numeric, 2) AS ha FROM d_b;

WITH net AS (SELECT ST_UnaryUnion(ST_Collect(geom)) g FROM d_b),
     ci  AS (SELECT cible_ville('02691', DATE '2000-12-01') g)
SELECT round((ST_Area(net.g) / 1e4)::numeric, 2)                        AS ha_net,
       round((ST_Area(ci.g) / 1e4)::numeric, 2)                         AS ha_cible,
       round((ST_Area(ST_Difference(net.g, ci.g)) / 1e4)::numeric, 2)   AS net_hors_cible,
       round((ST_Area(ST_Difference(ci.g, net.g)) / 1e4)::numeric, 2)   AS cible_hors_net
FROM   net, ci;

\echo ''
\echo '== B2. Ce que la découpe du net laisse sans propriétaire (> 100 m²)'
WITH net AS (SELECT ST_UnaryUnion(ST_Collect(geom)) g FROM d_b),
     mo  AS (SELECT * FROM carte_coupe_ville_sur('02691', DATE '2000-12-01',
                                                 (SELECT g FROM net))),
     reste AS (SELECT (ST_Dump(ST_Difference((SELECT g FROM net),
                                             (SELECT ST_Union(geom) FROM mo)))).geom g)
SELECT round((ST_Area(g) / 1e4)::numeric, 2) AS ha,
       ST_AsText(ST_PointOnSurface(g))       AS point,
       (SELECT string_agg(c.coupe_id, ', ') FROM coupe_ville c
         WHERE c.insee = '02691' AND c.periode @> DATE '2000-12-01'
           AND ST_DWithin(c.geom, g, 50))    AS lignes_a_50m
FROM   reste WHERE ST_Area(g) > 100 ORDER BY 1 DESC;

\echo ''
\echo '== B3. Les ancres de Saint-Quentin : dans le net ? dans la cible ?'
WITH net AS (SELECT ST_UnaryUnion(ST_Collect(geom)) g FROM d_b),
     ci  AS (SELECT cible_ville('02691', DATE '2000-12-01') g)
SELECT an.atom_id, left(an.note, 50) AS note, an.valid_from, an.valid_to,
       ST_Contains(net.g, an.geom) AS dans_net,
       ST_Contains(ci.g, an.geom)  AS dans_cible,
       ST_AsText(an.geom)          AS point
FROM   coupe_ville_ancre an
JOIN   atom a ON a.atom_id = an.atom_id AND a.insee_geofla = '02691', net, ci
ORDER  BY 1;

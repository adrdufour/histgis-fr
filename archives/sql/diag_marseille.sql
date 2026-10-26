-- ============================================================================
-- Diagnostic ponctuel : pourquoi Marseille reste-t-il amputé ?
--
-- Fait : après rebuild.sh, le pseudo-canton 1383 mesure toujours 152,03 km²
-- contre 294,25 chez Gay. Le correctif `1320` → `132` de
-- geom_correspondance.csv n'a donc pas produit son effet.
--
-- L'arithmétique dit pourtant que le diagnostic était bon :
--   294,25 (Gay) − 152,03 (nous) = 142,22
--   arrondissements 10 à 16 (133,66) + Plan-de-Cuques (8,57) = 142,23
-- À l'hectare près. Il nous manque bien exactement les arrondissements 10-16.
--
-- Quatre hypothèses, ce script les départage :
--   A. le CSV lu par la base porte encore `1320` (fichier non propagé)
--   B. GEOFLA ne contient pas les arrondissements sous 132xx
--   C. l'atome Marseille est servi par une autre source que union_prefixe
--   D. `cible` est stocké avec du remplissage, et le LIKE ne mord plus
--
--   psql -d histgis -f archives/sql/diag_marseille.sql
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '=== A. Ce que la base a lu de geom_correspondance.csv ==='
\echo '    `cible` doit valoir 132 pour Marseille. S''il vaut 1320, le fichier'
\echo '    n''a pas été propagé jusqu''à la machine qui exécute psql.'
SELECT insee, methode, cible, length(cible) AS longueur_cible,
       left(commentaire, 60) AS debut_commentaire
FROM   diag_geom_correspondance
WHERE  methode = 'union_prefixe'
ORDER  BY insee;

\echo ''
\echo '=== B. Ce que GEOFLA connaît sous 13055 et 132xx ==='
SELECT insee_com, nom_comm,
       round((ST_Area(geom) / 1e6)::numeric, 2) AS km2
FROM   geofla_commune
WHERE  insee_com = '13055' OR insee_com LIKE '132%'
ORDER  BY insee_com;

\echo ''
\echo '--- totaux ---'
SELECT count(*) FILTER (WHERE insee_com = '13055')     AS commune_13055,
       count(*) FILTER (WHERE insee_com LIKE '132%')   AS arrondissements_132xx,
       count(*) FILTER (WHERE insee_com LIKE '1320%')  AS dont_1320x,
       round((sum(ST_Area(geom)) FILTER (WHERE insee_com LIKE '132%') / 1e6)::numeric, 2)
                                                       AS km2_tous_132xx,
       round((sum(ST_Area(geom)) FILTER (WHERE insee_com LIKE '1320%') / 1e6)::numeric, 2)
                                                       AS km2_1320x
FROM   geofla_commune;

\echo ''
\echo '=== C. Nos atomes marseillais, et d''où vient leur géométrie ==='
SELECT a.atom_id, a.insee_geofla, a.fraction, g.source, g.partagee,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
FROM   atom a
LEFT   JOIN atom_geom g ON g.atom_id = a.atom_id
WHERE  a.insee_geofla IN ('13055', '69123')
ORDER  BY a.insee_geofla, a.atom_id;

\echo ''
\echo '=== D. Ce que donnerait la jointure du correctif, à blanc ==='
\echo '    Si ce compte est nul alors que `cible` vaut 132, le LIKE ne mord'
\echo '    pas — remplissage de la colonne, ou codes absents de GEOFLA.'
SELECT d.insee, d.cible,
       count(g.insee_com)                                    AS communes_captees,
       round((sum(ST_Area(g.geom)) / 1e6)::numeric, 2)       AS km2_captes
FROM   diag_geom_correspondance d
LEFT   JOIN geofla_commune g ON g.insee_com LIKE d.cible || '%'
WHERE  d.methode = 'union_prefixe'
GROUP  BY d.insee, d.cible ORDER BY d.insee;

\echo ''
\echo '=== E. Le pseudo-canton 1383 en 1870, commune par commune ==='
\echo '    Pour voir ce qui manque, et non plus seulement combien.'
SELECT m.atom_id, a.insee_geofla, ag.source,
       round((ST_Area(ag.geom) / 1e6)::numeric, 2) AS km2
FROM   membership m
JOIN   atom a      ON a.atom_id = m.atom_id
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
WHERE  m.niveau = 'canton'
  AND  m.periode @> '1870-06-01'::date
  AND  m.unit_id IN (SELECT unit_id FROM ctrl_corr
                      WHERE annee = 1870 AND deppct = '1383')
ORDER  BY 4 DESC NULLS LAST;

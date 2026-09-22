-- diag_deux_vides.sql — les deux atomes de la trappe du vide, jugés dans LEUR
-- département, c'est-à-dire dans le seul cadre où la carte travaille.
--
--     psql -d histgis -f sql/diag_deux_vides.sql
--
-- CE QUE LE PREMIER PASSAGE A RÉPONDU, LE 5 SEPTEMBRE 2026, ET CE QU'IL CHANGE
-- ---------------------------------------------------------------------------
--     13202  L'Étang-Bertrand  dep 50  servi_en_local = t  reçu 0,000  repli 8,525
--     10603  Courbiac          dep 47  servi_en_local = t  reçu 0,000  repli 9,013
--
-- Les deux sont SERVIS chez eux, et servis avec RIEN. Ce n'est donc pas le
-- `MULTIPOLYGON EMPTY` du national : une géométrie vide serait écartée par le
-- `HAVING NOT ST_IsEmpty(…)` posé le matin même dans `partition_reprise`, et
-- `servi_en_local` vaudrait `f`. Ce qu'ils reçoivent n'est pas vide, c'est
-- NÉGLIGEABLE — et un filtre sur le vide ne voit pas un miette.
--
-- *Le cadre ne change pas seulement qui gagne : il change la NATURE du
-- résultat. Le même couple rend un vide au national et une miette en local.*
--
-- D'où ce fichier, qui pose les trois questions que la première version ne
-- posait pas : combien exactement (en m², sans arrondi), est-ce vide au sens de
-- PostGIS, et de quelle fratrie viennent-ils. Courbiac a pour mère
-- Tournon-d'Agenais en 1876 — la fratrie de six du § 8-7 de `84`, celle où
-- `ST_Dump` ne sépare pas deux filles contiguës et où une sœur reçoit tout.
-- Si `fratrie > 1` pour les deux, alors ces deux-là ne sont pas un défaut de
-- plus : ce sont deux victimes du défaut 7, et la trappe du vide n'a jamais eu
-- de victime sur la carte.
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '--- Les deux, dans leur département, sans arrondi ----------------------'
\echo '    `vide` = t  : le HAVING aurait dû les écarter, donc il ne tourne pas.'
\echo '    `vide` = f et `m2_recu` proche de 0 : ils reçoivent une MIETTE, ce'
\echo '    qu''aucun filtre sur le vide ne peut voir. `fratrie` dit alors s''il'
\echo '    s''agit du défaut 7 — deux filles contiguës, un seul morceau.'
\echo ''

SELECT a.atom_id,
       coalesce(n.nom, '[' || at.insee_geofla || ']')            AS nom,
       d.dep,
       r.mere_id,
       r.an_reprise,
       r.fratrie,
       ST_IsEmpty(r.geom)                                        AS vide,
       ST_NumGeometries(r.geom)                                  AS n_morceaux,
       round(ST_Area(r.geom)::numeric, 1)                        AS m2_recu,
       round(ST_Area(ag.geom)::numeric, 1)                       AS m2_repli
FROM  (VALUES ('13202'), ('10603')) a(atom_id)
JOIN   atom at ON at.atom_id = a.atom_id
LEFT   JOIN noms_geofla n ON n.insee = at.insee_geofla
LEFT   JOIN atom_geom ag ON ag.atom_id = a.atom_id
CROSS  JOIN LATERAL (
       SELECT min(u.dep) AS dep
       FROM   membership m
       JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
       WHERE  m.atom_id = a.atom_id AND m.periode @> '1870-12-01'::date) d
LEFT   JOIN LATERAL (
       SELECT * FROM partition_reprise('1870-12-01', d.dep) x
        WHERE x.atom_id = a.atom_id) r ON true;

\echo ''
\echo '--- Leurs sœurs, servies par la même mère au même millésime ------------'
\echo '    C''est la contrepartie : si une sœur reçoit beaucoup plus que son'
\echo '    propre repli, le sol de la muette est chez elle, et la somme est'
\echo '    conservée — ce qu''aucune recette de surface ne peut attraper.'
\echo ''

SELECT r.atom_id,
       coalesce(n.nom, '[' || at.insee_geofla || ']')            AS nom,
       r.mere_id, r.an_reprise, r.fratrie,
       round((ST_Area(r.geom) / 1e6)::numeric, 3)                AS km2_recu,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3)               AS km2_repli
FROM  (VALUES ('50'), ('47')) dd(dep)
CROSS  JOIN LATERAL partition_reprise('1870-12-01', dd.dep) r
JOIN   atom at ON at.atom_id = r.atom_id
LEFT   JOIN noms_geofla n ON n.insee = at.insee_geofla
LEFT   JOIN atom_geom ag ON ag.atom_id = r.atom_id
WHERE  (r.mere_id, r.an_reprise) IN (
         SELECT x.mere_id, x.an_reprise
         FROM   partition_reprise('1870-12-01', '50') x
          WHERE x.atom_id = '13202'
         UNION ALL
         SELECT x.mere_id, x.an_reprise
         FROM   partition_reprise('1870-12-01', '47') x
          WHERE x.atom_id = '10603')
ORDER  BY r.mere_id, 6 DESC;

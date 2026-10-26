-- ============================================================================
-- histgis — diag_fratrie_carte.sql : ce que la CARTE dessine finalement pour
-- une fratrie contiguë, une fois le treillis passé
--
--     psql -d histgis -f sql/diag/diag_fratrie_carte.sql
--
-- LECTURE SEULE. Quelques dizaines de secondes : `partition_un_dep` est appelée
-- sur les seuls départements où vivent les filles des deux mères observées.
--
-- LA QUESTION, ET POURQUOI ELLE N'EST PAS CELLE D'HIER
-- ----------------------------------------------------
-- `diag_reprise_nulle.sql` mesure la REPRISE, c'est-à-dire l'entrée du
-- treillis. Le 5 septembre 2026 il a rendu ceci, et c'est brutal :
--
--     le MÊME morceau de 73,518 km² est donné à TROIS filles différentes,
--     une par passe départementale — Anthé (82), Thézac (46), Bourlens (47) —
--     alors qu'aucune n'a un repli de plus de 15,6 km².
--
-- C'est le corollaire du point 6 du § 8 de `84`, mesuré au lieu d'être craint :
-- « une fratrie à cheval sur deux départements se verrait attribuer le même
-- morceau plusieurs fois ». Et la fratrie elle-même CHANGE DE TAILLE selon le
-- cadre — `fratrie = 3` vu de 46 et 82, `= 6` vu de 47, pour le même atome, la
-- même mère et le même millésime.
--
-- MAIS LA REPRISE N'EST PAS LA CARTE. Entre les deux il y a le treillis, qui
-- arbitre face par face et ne rend que les atomes `dedans`. Il peut très bien
-- rogner ces trois polygones jusqu'à ce qu'ils ne se recouvrent plus — c'est
-- même ce que suggère la ligne « couture entre départements » de
-- `check_partition`, qui vaut 0,019 km² et non 150.
--
-- *Une entrée fausse ne fait pas une sortie fausse quand une étape ultérieure
-- arbitre. Mesurer l'entrée ne dispense pas de mesurer la sortie, et l'inverse
-- non plus.*
--
-- CE FICHIER MESURE LA SORTIE, sur les deux fratries connues :
--   mère 37892 (Tournon-d'Agenais, 1876) — six filles, dont Courbiac ;
--   mère  5988 (Bricquebec, 1895)        — deux filles, dont L'Étang-Bertrand.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

\echo ''
\echo '--- Qui compose les deux fratries, et où vivent-elles -------------------'
\echo ''

DROP TABLE IF EXISTS dfc_fille;
CREATE TEMP TABLE dfc_fille AS
SELECT r.atom_id, r.mere_id, r.an_reprise, r.fratrie,
       a.insee_geofla,
       coalesce(n.nom, '[' || a.insee_geofla || ']') AS nom,
       (SELECT min(u.dep)
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.atom_id = r.atom_id AND m.periode @> :'date'::date) AS dep,
       ST_Area(r.geom)                               AS m2_reprise
FROM   partition_reprise(:'date'::date, NULL) r
JOIN   atom a ON a.atom_id = r.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  r.mere_id IN ('37892', '5988');

SELECT dep, atom_id, nom, mere_id, an_reprise, fratrie,
       round((m2_reprise / 1e6)::numeric, 3) AS km2_reprise_national
FROM   dfc_fille ORDER BY mere_id, 7 DESC;

\echo ''
\echo '--- La carte, département par département (ce qui sort du treillis) -----'
\echo ''

\timing on
DROP TABLE IF EXISTS dfc;
CREATE TEMP TABLE dfc AS
SELECT d.dep AS dep_passe, p.*
FROM  (SELECT DISTINCT dep FROM dfc_fille WHERE dep IS NOT NULL) d
CROSS  JOIN LATERAL partition_un_dep(:'date'::date, d.dep) p;
CREATE INDEX ON dfc USING gist (geom);
CREATE INDEX ON dfc (atom_id);
ANALYZE dfc;
\timing off

\echo ''
\echo '=== 1. Ce que chaque fille reçoit VRAIMENT sur la carte ================='
\echo '    `km2_reprise` est ce que la règle lui donnait en entrée ;'
\echo '    `km2_carte` est ce que le treillis lui laisse, et c''est le seul'
\echo '    chiffre qui se dessine. `km2_repli` est ce qu''elle aurait eu sans'
\echo '    aucune reprise — l''ordre de grandeur attendu, pas une vérité.'
\echo ''

SELECT f.dep, f.atom_id, f.nom, f.mere_id, f.an_reprise,
       round((f.m2_reprise / 1e6)::numeric, 3)              AS km2_reprise,
       round((ST_Area(c.geom) / 1e6)::numeric, 3)           AS km2_carte,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3)          AS km2_repli,
       c.source, c.motif
FROM   dfc_fille f
LEFT   JOIN dfc c ON c.atom_id = f.atom_id AND c.dep_passe = f.dep
LEFT   JOIN atom_geom ag ON ag.atom_id = f.atom_id
ORDER  BY f.mere_id, 7 DESC NULLS LAST;

\echo ''
\echo '=== 2. Ces filles se recouvrent-elles sur la carte ? ===================='
\echo '    Zéro ligne = le treillis a réparé l''entrée, et le triple don de'
\echo '    73,518 km² ne se voit pas sur le dessin. Des lignes = le même sol'
\echo '    est dessiné deux fois, et la ligne « couture entre départements »'
\echo '    de check_partition devrait le porter.'
\echo ''

SELECT a.atom_id AS atom_a, fa.nom AS nom_a, a.dep_passe AS passe_a,
       b.atom_id AS atom_b, fb.nom AS nom_b, b.dep_passe AS passe_b,
       round((ST_Area(ST_Intersection(a.geom, b.geom)) / 1e6)::numeric, 4)
                                                            AS km2_commun
FROM   dfc a
JOIN   dfc b ON a.atom_id < b.atom_id
            AND a.geom && b.geom
            AND ST_Intersects(a.geom, b.geom)
JOIN   dfc_fille fa ON fa.atom_id = a.atom_id
JOIN   dfc_fille fb ON fb.atom_id = b.atom_id
WHERE  ST_Area(ST_Intersection(a.geom, b.geom)) > 0
ORDER  BY 7 DESC;

\echo ''
\echo '=== 3. Et la mère ? ====================================================='
\echo '    Elle doit avoir rendu à ses filles ce qu''elles ont pris, et pas'
\echo '    davantage. Une mère plus grande que son polygone ANR voudrait dire'
\echo '    que le retranchement du § (a) de 84 n''a pas eu lieu dans ce cadre.'
\echo ''

SELECT c.dep_passe, c.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')        AS nom,
       round((ST_Area(c.geom) / 1e6)::numeric, 3)           AS km2_carte,
       round((ST_Area(ga.geom) / 1e6)::numeric, 3)          AS km2_anr,
       c.source, c.motif
FROM   dfc c
JOIN   atom a ON a.atom_id = c.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
LEFT   JOIN atom_geom_anr ga ON ga.atom_id = c.atom_id
                            AND ga.periode @> :'date'::date
WHERE  c.atom_id IN ('37892', '5988')
ORDER  BY 1;

\echo ''
\echo '--- Fin. `dfc` et `dfc_fille` restent disponibles dans CETTE session.'
\echo ''

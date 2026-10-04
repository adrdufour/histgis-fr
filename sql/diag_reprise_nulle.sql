-- ============================================================================
-- histgis — diag_reprise_nulle.sql : les filles servies avec zéro surface
--
--     psql -d histgis -f sql/diag_reprise_nulle.sql
--     psql -d histgis -v date=1870-12-01 -f sql/diag_reprise_nulle.sql
--
-- LECTURE SEULE. Compte plusieurs minutes : la reprise est demandée une fois
-- par département — c'est-à-dire exactement comme la carte la demande.
--
-- POURQUOI CE FICHIER, ET CE QU'IL CORRIGE DANS MA PROPRE LECTURE
-- ---------------------------------------------------------------
-- Le 5 septembre 2026 au matin, `diag_sans_geometrie.sql` § 7 i a trouvé deux
-- atomes « servis avec un polygone vide » et j'ai fermé la trappe dans `84` :
-- `HAVING NOT ST_IsEmpty(…)`. Le contrôle de l'après-midi montre que **cette
-- lecture était juste au national et fausse sur la carte** :
--
--     13202 L'Étang-Bertrand  dep 50  mère 5988   1895  fratrie 2
--                             vide = f · 6 morceaux · 0,0 m² · repli 8 524 833
--     10603 Courbiac          dep 47  mère 37892  1876  fratrie 6
--                             vide = f · 33 morceaux · 0,0 m² · repli 9 012 650
--
-- Ce ne sont PAS des géométries vides. Ce sont des MULTIPOLYGONES de 6 et 33
-- morceaux dont l'aire totale est nulle : des lisières effondrées, ce que
-- `ST_Difference` laisse quand deux bords coïncident. `ST_IsEmpty` les déclare
-- pleins, `ST_NumGeometries` en compte des dizaines, et ils ne dessinent rien.
--
-- *Un filtre sur le vide ne voit pas un polygone d'aire nulle. « Avoir des
-- points » et « avoir une surface » sont deux propriétés distinctes, et
-- PostGIS ne confond que celui qui les confond.*
--
-- ET LE MÉCANISME EST CELUI DU DÉFAUT 7, MESURÉ SUR LA CARTE CETTE FOIS. Leurs
-- sœurs, servies par la même mère au même millésime, reçoivent le sol :
--
--     Bourlens    73,518 km² pour un repli de 15,578   (fratrie de 6)
--     Rocheville  19,080 km² pour un repli de 10,417   (fratrie de 2)
--
-- La somme est conservée, donc aucune recette de surface ne peut l'attraper.
-- Ces deux-là ne sont pas un défaut de plus : ce sont deux victimes du défaut
-- 7 du § 8 de `84` — `ST_Dump` ne sépare que les composantes déconnectées, et
-- deux filles contiguës se disputent un seul morceau que `DISTINCT ON (mid)`
-- donne à une seule.
--
-- CE QUE CE FICHIER MESURE, ET CE QU'IL NE DÉCIDE PAS
-- ---------------------------------------------------
-- Combien de filles la carte sert avec zéro surface, et combien avec presque
-- rien. La sortie est une DISTRIBUTION et non un compte au-dessus d'un seuil :
-- le seuil est précisément ce qu'il ne faut pas choisir avant d'avoir vu la
-- forme de la distribution. Si tout est à zéro exact, le remède est un filtre
-- sur l'aire — et zéro n'est pas un seuil, c'est l'absence de surface. Si le
-- nuage s'étale, alors il faudra trancher en le disant.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

\timing on
\echo ''
\echo '--- Les reprises telles que la CARTE les calcule (une par département) --'
\echo ''

DROP TABLE IF EXISTS drn;
CREATE TEMP TABLE drn AS
WITH dep AS (
    SELECT DISTINCT u.dep
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.periode @> :'date'::date
)
SELECT d.dep, r.atom_id, r.mere_id, r.an_reprise, r.fratrie,
       ST_IsEmpty(r.geom)       AS vide,
       ST_NumGeometries(r.geom) AS n_morceaux,
       ST_Area(r.geom)          AS m2_recu
FROM   dep d
CROSS  JOIN LATERAL partition_reprise(:'date'::date, d.dep) r;

CREATE INDEX ON drn (atom_id);
ANALYZE drn;
\timing off

\echo ''
\echo '=== 1. La distribution des surfaces reçues =============================='
\echo '    Aucun seuil n''est appliqué : les classes sont là pour montrer la'
\echo '    FORME. Si la classe « aire exactement nulle » contient tout ce qui'
\echo '    n''est pas franc, le remède est un filtre sur l''aire et il ne décide'
\echo '    de rien. Si le nuage s''étale entre 0 et quelques hectares, alors'
\echo '    tout filtre devient un arbitrage, et il faudra le dire.'
\echo ''

SELECT CASE WHEN vide             THEN '0. vide (MULTIPOLYGON EMPTY)'
            WHEN m2_recu = 0      THEN '1. non vide, aire EXACTEMENT nulle'
            WHEN m2_recu < 1      THEN '2. moins de 1 m²'
            WHEN m2_recu < 1e4    THEN '3. moins de 1 ha'
            WHEN m2_recu < 1e6    THEN '4. moins de 1 km²'
            ELSE                       '5. 1 km² ou plus' END   AS classe,
       count(*)                                                 AS n,
       round(sum(m2_recu)::numeric / 1e6, 3)                    AS km2_total,
       round(avg(n_morceaux)::numeric, 1)                       AS morceaux_moyen
FROM   drn
GROUP  BY 1
ORDER  BY 1;

\echo ''
\echo '=== 2. Les filles servies avec moins d''un hectare, nommées ============='
\echo '    `km2_repli` est ce qu''elles auraient eu sans reprise, donc l''ordre'
\echo '    de grandeur du sol qui leur manque. `fratrie > 1` désigne le défaut'
\echo '    7 ; `fratrie = 1` serait autre chose, et il faudrait le regarder.'
\echo ''

SELECT r.dep, r.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')             AS nom,
       r.mere_id, r.an_reprise, r.fratrie, r.n_morceaux,
       round(r.m2_recu::numeric, 1)                              AS m2_recu,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3)               AS km2_repli
FROM   drn r
JOIN   atom a ON a.atom_id = r.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
LEFT   JOIN atom_geom ag ON ag.atom_id = r.atom_id
WHERE  r.m2_recu < 1e4
ORDER  BY r.m2_recu, 9 DESC;

\echo ''
\echo '=== 3. Leurs sœurs, et le sol qui a changé de main ======================'
\echo '    Une sœur qui reçoit nettement plus que son propre repli tient le sol'
\echo '    de la muette. La SOMME EST CONSERVÉE — c''est pourquoi ni l''emprise'
\echo '    nationale, ni le recouvrement, ni aucune recette de surface ne'
\echo '    pouvait signaler quoi que ce soit.'
\echo ''

SELECT s.dep, s.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')             AS nom,
       s.mere_id, s.an_reprise, s.fratrie,
       round((s.m2_recu / 1e6)::numeric, 3)                      AS km2_recu,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3)               AS km2_repli,
       round(((s.m2_recu - ST_Area(ag.geom)) / 1e6)::numeric, 3) AS ecart
FROM   drn s
JOIN   atom a ON a.atom_id = s.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
LEFT   JOIN atom_geom ag ON ag.atom_id = s.atom_id
WHERE  (s.mere_id, s.an_reprise) IN (SELECT m.mere_id, m.an_reprise
                                       FROM drn m WHERE m.m2_recu < 1e4)
ORDER  BY s.mere_id, s.an_reprise, 7 DESC;

\echo ''
\echo '=== 4. Le même compte au NATIONAL, pour mesurer l''effet de cadre ======='
\echo '    `partition_reprise(date, NULL)` ne calcule pas ce que la carte'
\echo '    calcule : le bloc `mere` ignore le département, donc plus de filles'
\echo '    concourent. C''est le point 6 du § 8 de `84`. L''écart entre ce'
\echo '    compte et celui du § 1 EST la mesure de ce défaut-là.'
\echo '    NOTE : depuis le correctif du 5 septembre, la classe « vide » doit'
\echo '    être introuvable ici — le HAVING l''écarte. Zéro y vaut preuve.'
\echo ''

SELECT CASE WHEN ST_IsEmpty(geom)   THEN '0. vide (ne devrait plus exister)'
            WHEN ST_Area(geom) = 0  THEN '1. non vide, aire EXACTEMENT nulle'
            WHEN ST_Area(geom) < 1e4 THEN '2. moins de 1 ha'
            ELSE                         '3. franc' END          AS classe,
       count(*)                                                  AS n
FROM   partition_reprise(:'date'::date, NULL)
GROUP  BY 1
ORDER  BY 1;

\echo ''
\echo '--- Fin. `drn` reste disponible dans CETTE session.'
\echo ''

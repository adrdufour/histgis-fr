-- ============================================================================
-- histgis — 29_villes_a_verifier.sql : les communes que la trame ne sait pas
--                                       découper
--
--   psql -d histgis -f 29_villes_a_verifier.sql
--
-- Produit `villes_a_verifier.csv` : la liste des communes dont le découpage
-- cantonal ou législatif dépasse ce que la trame communale de 2011 peut
-- porter. C'est la feuille de route pour une saisie depuis l'atlas Gaudillère
-- ou toute autre source de composition.
--
-- Quatre motifs, du plus au moins grave
-- -------------------------------------
--   1. PSEUDO-CANTON — Marseille et Lyon, dont les cantons de 1999-2012 ne
--      sont pas représentés du tout : la ville forme un canton unique
--      (§ 6.2 quinquies de METHODE.md).
--   2. CIRCO ÉCARTÉE — l'atome relève de deux circonscriptions et a été laissé
--      sans rattachement, en 1986 ou en 2012.
--   3. MULTICANTONALE — la commune est partagée entre plusieurs cantons ; ses
--      atomes-fractions partagent son polygone, d'où le double comptage du
--      § 6.1.
--   4. FRACTION ANCIENNE — la commune était déjà partagée en 1870-1940.
--
-- Paris est un cas à part et figure en tête : ses circonscriptions incluent
-- des fractions de quartier définies par listes de voies, donc AUCUNE trame
-- administrative ne les porte. Le signaler ne sert qu'à ne pas le chercher.
--
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DROP TABLE IF EXISTS villes_a_verifier;
CREATE TABLE villes_a_verifier AS
WITH commune AS (
    -- une ligne par code INSEE portant au moins un atome
    SELECT DISTINCT a.insee_geofla AS insee
    FROM   atom a WHERE a.insee_geofla IS NOT NULL
),
nom AS (
    SELECT DISTINCT ON (dep || com) dep || com AS insee,
           trim(both '()' from coalesce(artmin, '')) || ' ' || nccenr AS nom
    FROM   cog_commune_src WHERE annee = 2012 AND actual = '1'
    ORDER  BY dep || com, cdc
),
geom AS (
    SELECT g.insee_com AS insee,
           round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2,
           g.nom_comm
    FROM   geofla_commune g
),
-- cantons portés par les atomes de cette commune, aux deux époques
ct_ancien AS (
    SELECT a.insee_geofla AS insee, count(DISTINCT m.unit_id) AS n
    FROM   atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
    WHERE  m.valid_from < '1941-01-01'::date
    GROUP  BY 1
),
ct_moderne AS (
    SELECT a.insee_geofla AS insee, count(DISTINCT m.unit_id) AS n
    FROM   atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
    WHERE  m.valid_from >= '1999-01-01'::date
    GROUP  BY 1
),
circo12 AS (
    SELECT a.insee_geofla AS insee, count(DISTINCT m.unit_id) AS n
    FROM   atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'circo'
    WHERE  m.periode @> '2012-06-01'::date
    GROUP  BY 1
),
circo86 AS (
    SELECT a.insee_geofla AS insee, count(DISTINCT m.unit_id) AS n
    FROM   atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'circo'
    WHERE  m.periode @> '1997-06-01'::date
    GROUP  BY 1
),
-- atomes écartés faute de pouvoir trancher
ecarte AS (
    SELECT a.insee_geofla AS insee,
           count(*) FILTER (WHERE p.atom_id IS NOT NULL)  AS ecart_2012,
           count(*) FILTER (WHERE q.atom_id IS NOT NULL)  AS ecart_1986,
           string_agg(DISTINCT coalesce(p.circos, q.circos), ' ; ') AS circos_en_conflit
    FROM   atom a
    LEFT   JOIN circo_partage   p ON p.atom_id = a.atom_id
    LEFT   JOIN circo86_partage q ON q.atom_id = a.atom_id
    WHERE  p.atom_id IS NOT NULL OR q.atom_id IS NOT NULL
    GROUP  BY 1
),
pseudo AS (
    SELECT DISTINCT a.insee_geofla AS insee
    FROM   atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
    WHERE  m.unit_id IN ('1399', '6999') AND m.valid_from >= '1999-01-01'::date
)
SELECT c.insee,
       coalesce(n.nom, g.nom_comm)                      AS nom,
       left(c.insee, 2)                                 AS dep,
       g.km2,
       coalesce(ca.n, 0)                                AS cantons_1870_1940,
       coalesce(cm.n, 0)                                AS cantons_1999_2012,
       coalesce(c86.n, 0)                               AS circos_1986,
       coalesce(c12.n, 0)                               AS circos_2012,
       coalesce(e.ecart_1986, 0)                        AS atomes_ecartes_1986,
       coalesce(e.ecart_2012, 0)                        AS atomes_ecartes_2012,
       e.circos_en_conflit,
       CASE WHEN left(c.insee, 2) = '75'                THEN '0 - Paris, irreductible'
            WHEN p.insee IS NOT NULL                    THEN '1 - pseudo-canton'
            WHEN coalesce(e.ecart_2012, 0) + coalesce(e.ecart_1986, 0) > 0
                                                        THEN '2 - circo ecartee'
            WHEN coalesce(cm.n, 0) > 1                  THEN '3 - multicantonale'
            ELSE                                             '4 - fraction ancienne'
       END                                              AS motif
FROM   commune c
LEFT   JOIN nom n        ON n.insee = c.insee
LEFT   JOIN geom g       ON g.insee = c.insee
LEFT   JOIN ct_ancien ca ON ca.insee = c.insee
LEFT   JOIN ct_moderne cm ON cm.insee = c.insee
LEFT   JOIN circo12 c12  ON c12.insee = c.insee
LEFT   JOIN circo86 c86  ON c86.insee = c.insee
LEFT   JOIN ecarte e     ON e.insee = c.insee
LEFT   JOIN pseudo p     ON p.insee = c.insee
WHERE  left(c.insee, 2) = '75'
   OR  p.insee IS NOT NULL
   OR  coalesce(e.ecart_2012, 0) + coalesce(e.ecart_1986, 0) > 0
   OR  coalesce(cm.n, 0) > 1
   OR  coalesce(ca.n, 0) > 1;

\echo ''
\echo '============================================================'
\echo ' COMMUNES QUE LA TRAME NE SAIT PAS DÉCOUPER'
\echo '============================================================'

\echo ''
\echo '=== Par motif ==='
SELECT motif, count(*) AS communes, round(sum(km2), 0) AS km2
FROM   villes_a_verifier GROUP BY motif ORDER BY motif;

\echo ''
\echo '=== Les cas les plus lourds : cantons ou circonscriptions perdus ==='
SELECT insee, nom, dep, km2, cantons_1999_2012 AS ct12,
       circos_1986 AS c86, circos_2012 AS c12,
       atomes_ecartes_1986 AS ec86, atomes_ecartes_2012 AS ec12
FROM   villes_a_verifier
WHERE  motif <= '2'
ORDER  BY motif, km2 DESC NULLS LAST;

\echo ''
\echo '=== Les 30 communes multicantonales les plus étendues ==='
SELECT insee, nom, dep, km2, cantons_1870_1940 AS ct_ancien,
       cantons_1999_2012 AS ct_moderne, circos_2012 AS c12
FROM   villes_a_verifier WHERE motif = '3 - multicantonale'
ORDER  BY km2 DESC NULLS LAST LIMIT 30;

\echo ''
\echo '=== Communes déjà partagées en 1870-1940 ==='
SELECT count(*) AS communes,
       count(*) FILTER (WHERE cantons_1999_2012 > 1) AS encore_partagees_en_2012,
       round(sum(km2), 0) AS km2
FROM   villes_a_verifier WHERE cantons_1870_1940 > 1;

\echo ''
\echo '--- export ---'
\copy (SELECT * FROM histgis.villes_a_verifier ORDER BY motif, km2 DESC NULLS LAST) TO 'villes_a_verifier.csv' WITH (FORMAT csv, HEADER true)

\echo 'écrit : villes_a_verifier.csv (dans le répertoire courant de psql)'
\echo ''
\echo 'Table laissée en base : histgis.villes_a_verifier'

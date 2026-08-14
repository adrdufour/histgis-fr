-- ============================================================================
-- histgis — 35_atomes_hors_departement.sql : les atomes dont la géométrie
--                                            tombe dans un autre département
--
--   psql -d histgis -f 35_atomes_hors_departement.sql
--
-- D'où vient le soupçon
-- ---------------------
-- Escaufourt (02285) était une commune de l'Aisne, absorbée en 1973 par
-- Saint-Souplet — qui est dans le **Nord**. N'ayant pas de commune GEOFLA 2011
-- à son code, son atome a pris la géométrie de son successeur par la route
-- `commune_successeur`. Il est donc rattaché à un canton de l'Aisne et dessiné
-- dans le Nord.
--
-- Repéré à l'œil sur une planche engendrée, pas par une recette. C'est le
-- genre de défaut qu'aucun contrôle de cohérence ne voit : tout est cohérent,
-- simplement le polygone n'est pas au bon endroit.
--
-- Ce que le script mesure, et pourquoi ainsi
-- ------------------------------------------
-- On ne cherche pas les atomes issus de telle ou telle route — ce serait
-- énumérer un mécanisme supposé. On mesure une **propriété** : le polygone
-- d'un atome tombe-t-il dans le département que son code annonce ?
--
-- Le test est géométrique et ne suppose rien de la provenance : point
-- représentatif du polygone, commune GEOFLA qui le contient, comparaison des
-- deux premiers caractères. Il attrapera donc aussi les cas produits par
-- d'autres routes, y compris ceux auxquels on ne pense pas.
--
-- Portée
-- ------
-- Un atome mal placé fausse la géométrie de son canton à toutes les dates, et
-- se compte dans les mesures de recouvrement et de couverture. Le volume
-- décidera s'il faut corriger, déclarer, ou retirer ces atomes.
--
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' ATOMES DONT LA GÉOMÉTRIE EST HORS DÉPARTEMENT'
\echo '============================================================'

DROP TABLE IF EXISTS hd;
CREATE TEMP TABLE hd AS
SELECT a.atom_id,
       a.insee_geofla,
       left(a.insee_geofla, 2)  AS dep_annonce,
       ag.source,
       g.insee_com              AS commune_du_polygone,
       g.nom_comm               AS nom_du_polygone,
       left(g.insee_com, 2)     AS dep_reel,
       round((ST_Area(ag.geom) / 1e6)::numeric, 2) AS km2
FROM   atom a
JOIN   atom_geom ag ON ag.atom_id = a.atom_id
LEFT   JOIN LATERAL (
    SELECT gc.insee_com, gc.nom_comm
    FROM   geofla_commune gc
    WHERE  gc.geom && ST_PointOnSurface(ag.geom)
      AND  ST_Contains(gc.geom, ST_PointOnSurface(ag.geom))
    LIMIT  1
) g ON true
WHERE  a.insee_geofla IS NOT NULL;

CREATE INDEX hd_idx ON hd (dep_annonce, dep_reel);
ANALYZE hd;

-- ---------------------------------------------------------------------------
-- Les recodages départementaux, qui ne sont PAS des déplacements
-- ---------------------------------------------------------------------------
-- Le test suppose que les deux premiers caractères d'un code Insee désignent
-- un département stable. C'est faux deux fois :
--   - la Corse passe du code 20 à 2A et 2B en 1976 ;
--   - la Seine (75) et la Seine-et-Oise (78) sont démembrées en 1968 au
--     profit des 91, 92, 93, 94 et 95.
-- Dans ces cas le code change et le territoire ne bouge pas. Les compter
-- comme des atomes mal placés serait mesurer ma propre hypothèse.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS hd_recodage;
CREATE TEMP TABLE hd_recodage (avant char(2), apres char(2));
INSERT INTO hd_recodage VALUES
    ('20','2A'), ('20','2B'),
    ('75','92'), ('75','93'), ('75','94'),
    ('78','91'), ('78','92'), ('78','93'), ('78','94'), ('78','95');

ALTER TABLE hd ADD COLUMN nature text;
UPDATE hd SET nature =
    CASE
      WHEN dep_reel IS NULL                THEN 'hors_geofla'
      WHEN dep_reel = dep_annonce          THEN 'en_place'
      WHEN EXISTS (SELECT 1 FROM hd_recodage r
                   WHERE r.avant = hd.dep_annonce AND r.apres = hd.dep_reel)
                                           THEN 'recodage_departemental'
      ELSE 'deplace'
    END;

-- ---------------------------------------------------------------------------
-- 1. L'ampleur
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Bilan ==='
SELECT nature, count(*) AS atomes, round(sum(km2), 1) AS km2
FROM   hd GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '    en_place : le polygone est dans le departement annonce.'
\echo '    recodage_departemental : Corse 20 -> 2A/2B, Seine et Seine-et-Oise'
\echo '        demembrees en 1968. Le code a change, pas le territoire :'
\echo '        ce ne sont PAS des atomes mal places.'
\echo '    deplace : le polygone est ailleurs. C''est le seul chiffre a citer.'
\echo '    hors_geofla : point representatif dans aucune commune GEOFLA.'

-- ---------------------------------------------------------------------------
-- 2. Par route de géométrie : laquelle produit le défaut ?
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Par source de geometrie ==='
SELECT source,
       count(*)                                        AS atomes,
       count(*) FILTER (WHERE nature = 'deplace') AS deplaces,
       round(100.0 * count(*) FILTER (WHERE nature = 'deplace')
             / nullif(count(*), 0), 2)                 AS pct
FROM   hd WHERE nature <> 'hors_geofla'
GROUP  BY source ORDER BY 3 DESC, 1;

-- ---------------------------------------------------------------------------
-- 3. Les couples de départements concernés
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Les glissements, par couple de departements ==='
\echo '    Des departements limitrophes signalent une fusion transfrontaliere,'
\echo '    ce qui est explicable. Des departements eloignes signalent une'
\echo '    erreur de rattachement, ce qui ne l''est pas.'
SELECT dep_annonce, dep_reel, count(*) AS atomes,
       round(sum(km2), 1) AS km2,
       left(string_agg(insee_geofla || ' ' || coalesce(nom_du_polygone, '?'),
                       ', ' ORDER BY insee_geofla), 90) AS exemples
FROM   hd WHERE nature = 'deplace'
GROUP  BY 1, 2 ORDER BY 3 DESC, 1, 2;

-- ---------------------------------------------------------------------------
-- 4. Le détail, pour instruire
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Le detail ==='
SELECT atom_id, insee_geofla, dep_annonce, source,
       commune_du_polygone, nom_du_polygone, dep_reel, km2
FROM   hd WHERE nature = 'deplace'
ORDER  BY km2 DESC LIMIT 60;

-- ---------------------------------------------------------------------------
-- 5. Ce que ça coûte aux cantons
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Les cantons touches ==='
\echo '    Un canton qui compte un atome mal place a une geometrie fausse a'
\echo '    toutes les dates, et pese a tort dans les mesures de recouvrement.'
SELECT m.unit_id, u.nom, m.niveau,
       count(DISTINCT h.atom_id) AS atomes_mal_places,
       round(sum(DISTINCT h.km2), 1) AS km2
FROM   hd h
JOIN   membership m ON m.atom_id = h.atom_id
JOIN   unit u ON u.unit_id = m.unit_id
WHERE  h.nature = 'deplace'
GROUP  BY 1, 2, 3 ORDER BY 4 DESC, 1 LIMIT 40;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    Quelques dizaines d''atomes entre departements limitrophes :'
\echo '        consequence connue de la trame 2011, a declarer et chiffrer.'
\echo '    Des centaines, ou des departements non limitrophes : defaut de'
\echo '        rattachement a instruire dans `06` et `commune_successeur`.'
\echo ''
\echo 'Rappel : ce defaut ne se voit dans AUCUNE recette de coherence. Tout'
\echo 'est coherent — le polygone est simplement au mauvais endroit. Il a'
\echo 'fallu regarder une carte pour le trouver.'

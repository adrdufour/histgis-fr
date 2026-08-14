-- ============================================================================
-- histgis — 06_insee_mvt.sql : rattraper les communes disparues avant 2011
--
-- Les atomes dont le code INSEE d'époque a disparu (fusions, pour l'essentiel
-- celles de la loi Marcellin de 1971) n'ont pas de polygone GEOFLA. On suit
-- les mouvements de communes publiés par l'INSEE jusqu'au 1er janvier 2011
-- pour trouver la commune qui les a absorbés.
--
-- Prérequis : 05_geom.sql exécuté, et le fichier INSEE téléchargé :
--   curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv
--
-- Usage :
--   psql -d histgis -v mvt=/chemin/v_mvt_commune_2025.csv -f 06_insee_mvt.sql
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Millésime GEOFLA : on ne rejoue les mouvements que jusque-là.
\set butoir '2011-01-01'

-- ---------------------------------------------------------------------------
-- 1. Les mouvements, tels que publiés
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS insee_mvt;
CREATE TABLE insee_mvt (
    mod         text,   -- type de mouvement (31 fusion, 32-34 commune nouvelle…)
    date_eff    date,
    typecom_av  text, com_av text, tncc_av text, ncc_av text,
    nccenr_av   text, libelle_av text,
    typecom_ap  text, com_ap text, tncc_ap text, ncc_ap text,
    nccenr_ap   text, libelle_ap text
);

\set cmd '\\copy insee_mvt FROM ' :'mvt' ' WITH (FORMAT csv, HEADER true)'
:cmd

CREATE INDEX insee_mvt_av_idx ON insee_mvt (com_av);

-- ---------------------------------------------------------------------------
-- 2. Fermeture transitive : ancien code -> code vivant en 2011
--
--    Modalités retenues, celles qui font disparaître un code au profit d'un
--    autre : 31 fusion simple, 32/33 commune nouvelle, 34 transformation de
--    fusion-association, 41 changement de département, 50 transfert de
--    chef-lieu. Les changements de nom (10) ne touchent pas le code, les
--    rétablissements (21) vont dans l'autre sens.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS commune_successeur;
CREATE TABLE commune_successeur (
    insee_ancien char(5) PRIMARY KEY,
    insee_2011   char(5) NOT NULL,
    n_sauts      smallint NOT NULL,
    dans_geofla  boolean NOT NULL
);

WITH RECURSIVE arcs AS (
    SELECT DISTINCT com_av, com_ap
    FROM   insee_mvt
    WHERE  mod IN ('31', '32', '33', '34', '41', '50')
      AND  com_av IS DISTINCT FROM com_ap
      AND  date_eff <= :'butoir'::date
),
chaine (depart, courant, n, vus) AS (
    SELECT com_av, com_ap, 1, ARRAY[com_av, com_ap]
    FROM   arcs
    UNION ALL
    -- `vus` coupe les cycles : une commune peut être absorbée puis rétablie
    SELECT c.depart, a.com_ap, c.n + 1, c.vus || a.com_ap
    FROM   chaine c
    JOIN   arcs a ON a.com_av = c.courant
    WHERE  c.n < 10 AND NOT (a.com_ap = ANY (c.vus))
)
INSERT INTO commune_successeur (insee_ancien, insee_2011, n_sauts, dans_geofla)
SELECT DISTINCT ON (depart)
       depart, courant, n,
       EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = courant)
FROM   chaine
-- une commune encore présente dans GEOFLA n'a pas besoin de successeur :
-- l'exclure évite de la réécrire au passage d'un aller-retour absorption /
-- rétablissement
WHERE  NOT EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = depart)
-- on préfère un aboutissement réellement présent dans GEOFLA, et le plus
-- tardif possible : c'est l'état de la commune au millésime 2011
ORDER  BY depart,
          EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = courant) DESC,
          n DESC;

ANALYZE commune_successeur;

-- ---------------------------------------------------------------------------
-- 3. Étape 4 du chargement géométrique
-- ---------------------------------------------------------------------------
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       'successeur'
FROM   atom a
JOIN   commune_successeur s ON s.insee_ancien = a.insee_geofla
JOIN   geofla_commune g     ON g.insee_com   = s.insee_2011
WHERE  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
GROUP  BY a.atom_id;

-- le partage de polygone s'étend forcément : plusieurs communes absorbées
-- par la même commune actuelle pointent désormais vers le même polygone
UPDATE atom_geom ag SET partagee = true
FROM  (SELECT ag2.geom
       FROM   atom_geom ag2
       GROUP  BY ag2.geom HAVING count(*) > 1) d
WHERE ST_Equals(ag.geom, d.geom) AND NOT ag.partagee;

ANALYZE atom_geom;

\echo ''
\echo '=== Correspondances construites ==='
SELECT count(*) AS successions,
       count(*) FILTER (WHERE dans_geofla) AS aboutissant_dans_geofla,
       max(n_sauts) AS chaine_la_plus_longue
FROM   commune_successeur;

\echo ''
\echo '=== Géométries après rattrapage ==='
SELECT * FROM check_geom();

\echo ''
\echo '=== Ce qui résiste (par département) ==='
SELECT left(a.insee_geofla, 2) AS dep, count(*)
FROM   atom a
WHERE  NOT EXISTS (SELECT 1 FROM atom_geom g WHERE g.atom_id = a.atom_id)
GROUP  BY 1 ORDER BY 2 DESC LIMIT 10;

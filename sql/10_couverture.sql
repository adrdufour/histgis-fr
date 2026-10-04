-- ============================================================================
-- histgis — 10_couverture.sql : le territoire que nous ne couvrons pas
--
-- Ce que 09 a établi, et qui oriente tout ce fichier :
--
--   `km2_nous_seul` vaut 0,0 dans TOUS les départements, aux deux dates.
--   Nous ne revendiquons jamais un territoire que Gay n'a pas. L'écart est
--   à sens unique : il nous manque 5 926 km² en 1870, 744 en 1940.
--
-- Un écart à sens unique n'est pas une erreur d'attribution — une commune mal
-- rattachée se retrouverait en trop quelque part. C'est un trou de couverture :
-- des polygones GEOFLA qu'aucun de nos atomes ne réclame.
--
-- L'hypothèse, et la raison pour laquelle elle est vérifiable ici
-- --------------------------------------------------------------
-- Nos atomes sont des communes d'époque, rattachées à la trame 2011 par un
-- code INSEE. Cette correspondance est plusieurs-vers-un : quand une commune
-- de 1870 s'est scindée depuis, nous ne retenons qu'un des codes issus de la
-- scission, et le territoire de l'autre n'est réclamé par personne. Gay, lui,
-- part de la trame 2011 et affecte chaque commune actuelle à un canton
-- d'époque : il n'a pas de trou par construction.
--
-- Trois faits déjà au dossier appuient l'hypothèse :
--   - le déficit est huit fois plus grand en 1870 qu'en 1940, et il s'est
--     produit huit fois plus de scissions depuis 1870 que depuis 1940 ;
--   - il est réparti sur presque tous les départements, sans concentration ;
--   - les Bouches-du-Rhône passent de 557,9 km² manquants en 1870 à 150,0 en
--     1940 — Port-Saint-Louis-du-Rhône, détaché d'Arles en 1904, pèse une
--     centaine de km² et tombe exactement entre les deux dates.
--
-- Ce fichier nomme les communes concernées et confronte chacune aux créations
-- publiées par l'INSEE. Si l'hypothèse tient, la liste est faite de communes
-- récentes et la somme de leurs surfaces retombe sur `km2_gay_seul`.
--
-- Prérequis : 08 et 09 passés. `insee_mvt` (06) utilisée si présente.
-- Rejouable. Ne modifie rien : aucun atome n'est créé ici.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.ctrl_nous') IS NULL THEN
        RAISE EXCEPTION 'ctrl_nous absente : lancer 08_controle_gay.sql avant.';
    END IF;
    -- Une référence à une table absente casse à l'analyse, pas à l'exécution :
    -- un test `to_regclass` dans la requête ne protégerait de rien. On crée
    -- donc une table vide, que 06 remplacera à son prochain passage.
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE WARNING 'insee_mvt absente : confrontation aux créations INSEE impossible. Relancer 06_insee_mvt.sql.';
        CREATE TABLE insee_mvt (
            mod text, date_eff date,
            typecom_av text, com_av text, tncc_av text, ncc_av text,
            nccenr_av text, libelle_av text,
            typecom_ap text, com_ap text, tncc_ap text, ncc_ap text,
            nccenr_ap text, libelle_ap text
        );
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les communes que personne ne réclame
--
-- Test par point intérieur : les deux couches reposent sur les mêmes polygones
-- GEOFLA, un point intérieur à une commune est donc soit dans un de nos
-- cantons, soit dans aucun. Pas de demi-mesure à arbitrer.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_non_couvert;
CREATE TABLE ctrl_non_couvert AS
WITH y AS (SELECT DISTINCT annee FROM ctrl_gay),
     c AS (SELECT insee_com, nom_comm, code_dept, geom,
                  ST_PointOnSurface(geom) AS p
           FROM   geofla_commune)
SELECT y.annee,
       c.insee_com,
       c.nom_comm,
       c.code_dept                                AS dep,
       round((ST_Area(c.geom) / 1e6)::numeric, 2) AS km2,
       (SELECT e.deppct FROM ctrl_eux e
         WHERE e.annee = y.annee AND ST_Contains(e.geom, c.p) LIMIT 1) AS pct_gay,
       ST_Multi(c.geom)                           AS geom
FROM   y CROSS JOIN c
WHERE  NOT EXISTS (SELECT 1 FROM ctrl_nous n
                    WHERE n.annee = y.annee AND ST_Contains(n.geom, c.p));

ALTER TABLE ctrl_non_couvert ADD PRIMARY KEY (annee, insee_com);
CREATE INDEX ctrl_non_couvert_dep_idx ON ctrl_non_couvert (annee, dep);

-- ---------------------------------------------------------------------------
-- 2. Confrontation aux mouvements de communes
--
-- Réserve à garder en tête : le fichier INSEE ne remonte qu'à 1943. Une
-- commune créée entre 1870 et 1943 n'y figure pas et ressortira « non
-- documentée » sans que cela infirme quoi que ce soit. C'est le sens de la
-- colonne `anteriorite`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_non_couvert_expl;
CREATE TABLE ctrl_non_couvert_expl AS
SELECT n.annee, n.insee_com, n.nom_comm, n.dep, n.km2, n.pct_gay,
       m.mod, m.date_eff, m.libelle_av AS issue_de,
       CASE WHEN m.mod IS NOT NULL THEN 'creation INSEE documentee'
            ELSE 'non documentee (creation anterieure a 1943 ?)'
       END AS anteriorite
FROM   ctrl_non_couvert n
LEFT   JOIN LATERAL (
           SELECT i.mod, i.date_eff, i.libelle_av
           FROM   insee_mvt i
           WHERE  i.com_ap = n.insee_com
             AND  i.mod IN ('20', '21')
             AND  i.date_eff > make_date(n.annee, 6, 1)
           ORDER  BY i.date_eff
           LIMIT  1
       ) m ON true;

-- ---------------------------------------------------------------------------
-- 3. Rapport
-- ---------------------------------------------------------------------------
\echo ''
\echo '============================================================'
\echo ' TERRITOIRE NON COUVERT — communes GEOFLA sans atome'
\echo '============================================================'

\echo ''
\echo '=== 1. Volumétrie ==='
\echo '    Le total doit retomber sur le km2_gay_seul de 09 : 5 926 km² en'
\echo '    1870, 744 en 1940 — mais seulement une fois écartées les communes'
\echo '    que Gay ne couvre pas non plus (pct_gay IS NULL). Ce sont Tende et'
\echo '    La Brigue, italiennes jusqu''au traité de Paris de 1947 : présentes'
\echo '    dans GEOFLA 2011, absentes de la France de 1870 comme de 1940.'
SELECT annee,
       count(*)                  AS n_communes,
       round(sum(km2), 0)        AS km2_total,
       count(*) FILTER (WHERE pct_gay IS NULL)               AS hors_france,
       round(sum(km2) FILTER (WHERE pct_gay IS NULL), 1)     AS km2_hors_france,
       round(sum(km2) FILTER (WHERE pct_gay IS NOT NULL), 0) AS km2_a_comparer,
       count(DISTINCT dep)       AS n_departements
FROM   ctrl_non_couvert GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- ce que Gay ne couvre pas non plus ---'
SELECT annee, insee_com, nom_comm, dep, km2
FROM   ctrl_non_couvert WHERE pct_gay IS NULL ORDER BY annee, km2 DESC;

\echo ''
\echo '=== 2. Ces communes sont-elles postérieures à la date ? ==='
SELECT annee, anteriorite, count(*) AS n_communes, round(sum(km2), 0) AS km2
FROM   ctrl_non_couvert_expl GROUP BY 1, 2 ORDER BY 1, 4 DESC;

\echo ''
\echo '--- créations documentées : quand ? ---'
SELECT annee,
       (extract(decade FROM date_eff) * 10)::int AS decennie,
       count(*) AS n_communes, round(sum(km2), 0) AS km2
FROM   ctrl_non_couvert_expl WHERE date_eff IS NOT NULL
GROUP  BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 3. Les 30 plus grandes surfaces non couvertes ==='
SELECT annee, insee_com, nom_comm, dep, km2, pct_gay, anteriorite, date_eff
FROM   ctrl_non_couvert_expl ORDER BY km2 DESC LIMIT 30;

\echo ''
\echo '=== 4. Par département, confronté à 09 ==='
\echo '    `km2_gay_seul` vient de ctrl_dep. Les deux colonnes doivent'
\echo '    coïncider ; un résidu signale une autre cause que la couverture.'
\echo '    Réserve sur le résidu : les deux colonnes ne parlent pas du même'
\echo '    code. `ctrl_non_couvert.dep` vient de GEOFLA (département actuel),'
\echo '    `ctrl_dep.dep` de Gay (département d''époque). En Lorraine, le'
\echo '    partage de 1871 suffit à créer un résidu sans anomalie.'
SELECT n.annee, n.dep,
       count(*)                AS n_communes,
       round(sum(n.km2), 1)    AS km2_non_couvert,
       d.km2_gay_seul,
       round(sum(n.km2) - d.km2_gay_seul, 1) AS residu
FROM   ctrl_non_couvert n
LEFT   JOIN ctrl_dep d ON d.annee = n.annee AND d.dep = n.dep
WHERE  n.pct_gay IS NOT NULL
GROUP  BY n.annee, n.dep, d.km2_gay_seul
ORDER  BY km2_non_couvert DESC LIMIT 20;

\echo ''
\echo '=== 5. Le cas témoin : Bouches-du-Rhône ==='
\echo '    557,9 km² manquants en 1870, 150,0 en 1940. Si l''hypothèse tient,'
\echo '    la différence est faite de communes créées entre les deux dates.'
SELECT annee, insee_com, nom_comm, km2, pct_gay, date_eff, anteriorite
FROM   ctrl_non_couvert_expl WHERE dep = '13' ORDER BY annee, km2 DESC;

\echo ''
\echo '=== 6. Combien d''atomes faudrait-il ajouter ? ==='
\echo '    Une commune non couverte à une date l''est en général aux deux.'
SELECT count(DISTINCT insee_com) AS communes_distinctes,
       count(*)                  AS occurrences_annee_commune
FROM   ctrl_non_couvert;

\echo ''
\echo 'Tables : ctrl_non_couvert (avec geom), ctrl_non_couvert_expl.'

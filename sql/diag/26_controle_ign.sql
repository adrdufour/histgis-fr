-- ============================================================================
-- histgis — 26_controle_ign.sql : contrôle indépendant de 1999-2012
--
-- Ce que les cantons dissous de Victor Gay sont à 1870-1940, la couche CANTON
-- de GEOFLA l'est à la période moderne : une source qui ne passe par aucune
-- ligne de notre code.
--
-- Deux réserves, à lire avant les chiffres
-- ---------------------------------------
-- 1. Ce contrôle est PLUS FAIBLE que celui de Gay. Ses cantons dissous étaient
--    bâtis sur GEOFLA ED111, exactement la trame de nos communes ; la couche
--    CANTON dont nous disposons est l'édition ED141, de 2014. Un écart de
--    tracé peut donc venir d'une reprise de limites. Seuls les écarts
--    d'ATTRIBUTION, qui portent sur des communes entières, sont concluants.
--
-- 2. Le repliement est le même piège qu'en `08`, et le premier jet de ce
--    fichier y est tombé. GEOFLA fusionne les cantons d'une commune partagée
--    en une entité codée 9x — mais cette entité **ne porte que la commune
--    indivise**, les communes entières restant sous le code du canton réel.
--    Exactement la structure des `pct_type = 'Pseudo canton'` de Gay. Replier
--    un seul côté revient à comparer deux cantons à un bout de ville.
--
--    Le premier jet déduisait en outre le repliement de l'affectation
--    géométrique des atomes — c'est-à-dire de la réponse qu'il fallait
--    tester. Circulaire.
--
-- Le repliement, correctement
-- ---------------------------
-- Il se déduit de NOTRE nomenclature, pas de la géométrie de l'IGN : deux de
-- nos cantons appartiennent au même pseudo-canton s'ils se partagent une
-- commune. Les composantes connexes de cette relation donnent les groupes.
--
-- Côté IGN, les cantons dont le code correspond à l'un des nôtres se replient
-- par identité — la nomenclature est la même (§ 6.2 quinquies de METHODE.md).
-- Restent les entités 9x, propres à l'IGN : chacune est rattachée au groupe de
-- la commune qu'elle porte. C'est le seul endroit où la géométrie sert à
-- construire la comparaison, et il ne concerne que les communes déjà connues
-- comme partagées.
--
-- Lecture seule. Prérequis : 24, 25, et `geofla_canton` chargée.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set date_ref '2012-06-01'

DO $$
BEGIN
    IF to_regclass('histgis.geofla_canton') IS NULL THEN
        RAISE EXCEPTION 'geofla_canton absente : charger CANTON.SHP avec ogr2ogr.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' CONTRÔLE INDÉPENDANT 1999-2012 — cantons GEOFLA (ED141)'
\echo '============================================================'
\echo '(date de référence : 2012-06-01 ; couche IGN : édition 2014)'

-- ---------------------------------------------------------------------------
-- 1. Chaque atome, son canton chez nous, et l'entité IGN qui le contient
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_ign_atome;
CREATE TABLE ctrl_ign_atome AS
SELECT m.atom_id,
       a.insee_geofla,
       m.unit_id                                   AS canton_nous,
       g.code_dept || g.code_cant                  AS canton_ign,
       ag.source, ag.partagee,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3) AS km2
FROM   membership m
JOIN   atom a       ON a.atom_id = m.atom_id
JOIN   atom_geom ag ON ag.atom_id = m.atom_id
LEFT   JOIN geofla_canton g
       ON g.geom && ag.geom
      AND ST_Contains(g.geom, ST_PointOnSurface(ag.geom))
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_ref'::date;

CREATE INDEX ctrl_ign_atome_idx  ON ctrl_ign_atome (canton_nous);
CREATE INDEX ctrl_ign_atome_ign  ON ctrl_ign_atome (canton_ign);
CREATE INDEX ctrl_ign_atome_code ON ctrl_ign_atome (insee_geofla);

\echo ''
\echo '=== 1. Atomes rattachés à cette date ==='
SELECT count(*)                                   AS atomes,
       count(*) FILTER (WHERE canton_ign IS NULL) AS hors_couverture_ign,
       count(DISTINCT canton_nous)                AS cantons_chez_nous,
       (SELECT count(*) FROM geofla_canton)       AS entites_ign
FROM   ctrl_ign_atome;

-- ---------------------------------------------------------------------------
-- 2. Le repliement, déduit de NOTRE nomenclature
--
-- Deux cantons se replient ensemble s'ils partagent une commune. Composantes
-- connexes par propagation d'étiquette : chaque groupe reçoit le plus petit
-- identifiant de ses membres.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_ign_pct;
CREATE TABLE ctrl_ign_pct AS
WITH RECURSIVE arete AS (
    SELECT DISTINCT x.canton_nous AS a, y.canton_nous AS b
    FROM   ctrl_ign_atome x
    JOIN   ctrl_ign_atome y ON y.insee_geofla = x.insee_geofla
                           AND y.canton_nous <> x.canton_nous
    WHERE  x.insee_geofla IS NOT NULL
),
sym AS (
    SELECT a, b FROM arete
    UNION SELECT b, a FROM arete
    UNION SELECT DISTINCT canton_nous, canton_nous FROM ctrl_ign_atome
),
cc (n, lab) AS (
    SELECT DISTINCT canton_nous, canton_nous FROM ctrl_ign_atome
    UNION
    SELECT s.b, c.lab FROM cc c JOIN sym s ON s.a = c.n
)
SELECT n AS canton_nous, min(lab) AS pct FROM cc GROUP BY n;

ALTER TABLE ctrl_ign_pct ADD PRIMARY KEY (canton_nous);
CREATE INDEX ctrl_ign_pct_idx ON ctrl_ign_pct (pct);

\echo ''
\echo '=== 2. Pseudo-cantons déduits de nos partages de communes ==='
SELECT n_cantons, count(*) AS pseudo_cantons FROM (
    SELECT pct, count(*) AS n_cantons FROM ctrl_ign_pct GROUP BY pct) x
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 3. Le côté IGN : identité de code, sauf pour les entités 9x
--
-- Une entité IGN dont le code est l'un des nôtres se replie par identité. Les
-- autres — les 9x — portent une commune partagée : on les rattache au groupe
-- de cette commune.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_ign_corr;
CREATE TABLE ctrl_ign_corr AS
WITH ign AS (SELECT DISTINCT code_dept || code_cant AS canton_ign FROM geofla_canton),
identite AS (
    SELECT i.canton_ign, p.pct, 'identite'::text AS origine
    FROM   ign i JOIN ctrl_ign_pct p ON p.canton_nous = i.canton_ign
),
-- une entité 9x contient des communes : on prend le groupe majoritaire de nos
-- atomes qui y tombent
fusion AS (
    SELECT DISTINCT ON (a.canton_ign) a.canton_ign, p.pct, 'fusion'::text
    FROM   ctrl_ign_atome a
    JOIN   ctrl_ign_pct p ON p.canton_nous = a.canton_nous
    WHERE  a.canton_ign IS NOT NULL
      AND  NOT EXISTS (SELECT 1 FROM identite d WHERE d.canton_ign = a.canton_ign)
    GROUP  BY a.canton_ign, p.pct
    ORDER  BY a.canton_ign, count(*) DESC, sum(a.km2) DESC
)
SELECT * FROM identite UNION ALL SELECT * FROM fusion;

ALTER TABLE ctrl_ign_corr ADD PRIMARY KEY (canton_ign);

\echo ''
\echo '=== 3. Repliement du côté IGN ==='
SELECT origine, count(*) AS entites FROM ctrl_ign_corr GROUP BY origine ORDER BY 2 DESC;

\echo ''
\echo '--- entités IGN sans groupe (doit être vide ou marginal) ---'
SELECT count(*) AS sans_groupe FROM (
    SELECT DISTINCT code_dept || code_cant AS c FROM geofla_canton) g
WHERE  NOT EXISTS (SELECT 1 FROM ctrl_ign_corr x WHERE x.canton_ign = g.c);

-- ---------------------------------------------------------------------------
-- 4. Les deux couches, dissoutes au même niveau
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_ign_nous;
CREATE TABLE ctrl_ign_nous AS
SELECT p.pct,
       count(DISTINCT p.canton_nous) AS n_cantons,
       string_agg(DISTINCT p.canton_nous, ';' ORDER BY p.canton_nous) AS cantons,
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(sg.geom)), 3)) AS geom
FROM   ctrl_ign_pct p
JOIN   snapshot_geom(:'date_ref'::date, 'canton') sg ON sg.unit_id = p.canton_nous
GROUP  BY p.pct;

ALTER TABLE ctrl_ign_nous ADD PRIMARY KEY (pct);

DROP TABLE IF EXISTS ctrl_ign_eux;
CREATE TABLE ctrl_ign_eux AS
SELECT c.pct,
       count(*) AS n_entites,
       string_agg(DISTINCT c.canton_ign, ';' ORDER BY c.canton_ign) AS entites,
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(g.geom)), 3)) AS geom
FROM   ctrl_ign_corr c
JOIN   geofla_canton g ON g.code_dept || g.code_cant = c.canton_ign
GROUP  BY c.pct;

ALTER TABLE ctrl_ign_eux ADD PRIMARY KEY (pct);

DROP TABLE IF EXISTS ctrl_ign_ecart;
CREATE TABLE ctrl_ign_ecart AS
SELECT coalesce(n.pct, e.pct) AS pct,
       n.n_cantons, n.cantons, e.n_entites, e.entites,
       round((ST_Area(n.geom) / 1e6)::numeric, 2) AS km2_nous,
       round((ST_Area(e.geom) / 1e6)::numeric, 2) AS km2_eux,
       CASE WHEN n.geom IS NULL OR e.geom IS NULL THEN NULL
            ELSE round((ST_Area(ST_Intersection(n.geom, e.geom))
                        / nullif(ST_Area(ST_Union(n.geom, e.geom)), 0))::numeric, 5)
       END AS iou,
       CASE WHEN n.geom IS NULL THEN 'absent chez nous'
            WHEN e.geom IS NULL THEN 'absent chez IGN'
            ELSE 'apparie' END AS statut
FROM   ctrl_ign_nous n FULL JOIN ctrl_ign_eux e USING (pct);

\echo ''
\echo '=== 4. Appariement ==='
SELECT statut, count(*) FROM ctrl_ign_ecart GROUP BY statut ORDER BY 2 DESC;

\echo ''
\echo '=== 5. Distribution de l''IoU ==='
\echo '    Rappel : nos communes sont de l''édition 2011, ces cantons de 2014.'
\echo '    Un IoU sous 1 peut venir de là et ne prouve rien seul.'
SELECT count(*)                                            AS n,
       count(*) FILTER (WHERE iou >= 0.999)                AS "999_pour_mille",
       count(*) FILTER (WHERE iou >= 0.99 AND iou < 0.999) AS "99_pour_cent",
       count(*) FILTER (WHERE iou >= 0.90 AND iou < 0.99)  AS "90_a_99",
       count(*) FILTER (WHERE iou <  0.90)                 AS sous_90,
       round(min(iou), 4)                                  AS pire,
       round(avg(iou), 5)                                  AS moyenne
FROM   ctrl_ign_ecart WHERE statut = 'apparie';

\echo ''
\echo '--- surfaces d''ensemble ---'
\echo '    Un excédent important côté « nous » signale du double comptage :'
\echo '    des communes partagées revendiquées par plusieurs cantons.'
SELECT round(sum(km2_nous), 0) AS km2_nous,
       round(sum(km2_eux), 0)  AS km2_eux,
       round(sum(km2_nous) - sum(km2_eux), 0) AS ecart,
       round(100 * (sum(km2_nous) - sum(km2_eux)) / nullif(sum(km2_eux), 0), 3) AS pct
FROM   ctrl_ign_ecart WHERE statut = 'apparie';

\echo ''
\echo '=== 6. Les 25 pires écarts ==='
SELECT pct, n_cantons, n_entites, km2_nous, km2_eux, iou,
       left(cantons, 28) AS nos_cantons, left(entites, 28) AS entites_ign
FROM   ctrl_ign_ecart WHERE statut = 'apparie'
ORDER  BY iou ASC LIMIT 25;

-- ---------------------------------------------------------------------------
-- 5. LA mesure : les atomes rangés ailleurs
--
-- Le groupe de notre canton, contre le groupe de l'entité IGN qui contient
-- l'atome. Les deux repliements étant construits indépendamment de cette
-- affectation, la comparaison n'est pas circulaire.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 7. Atomes rangés ailleurs par l''IGN ==='
\echo '    Un écart de tracé peut venir de la différence d''édition ; un atome'
\echo '    mal rangé, non — c''est une commune entière.'
DROP TABLE IF EXISTS ctrl_ign_juge;
CREATE TABLE ctrl_ign_juge AS
SELECT a.*, p.pct AS pct_nous, c.pct AS pct_ign,
       (p.pct IS DISTINCT FROM c.pct) AS desaccord
FROM   ctrl_ign_atome a
JOIN   ctrl_ign_pct p  ON p.canton_nous = a.canton_nous
LEFT   JOIN ctrl_ign_corr c ON c.canton_ign = a.canton_ign
WHERE  a.canton_ign IS NOT NULL;

SELECT source, partagee, count(*) AS atomes,
       count(*) FILTER (WHERE desaccord) AS en_desaccord,
       round(100.0 * count(*) FILTER (WHERE desaccord) / count(*), 2) AS pct
FROM   ctrl_ign_juge GROUP BY source, partagee ORDER BY 5 DESC NULLS LAST;

\echo ''
\echo '--- les 25 désaccords les plus étendus ---'
SELECT j.atom_id, j.insee_geofla, j.source, j.canton_nous,
       j.pct_nous, j.pct_ign, j.canton_ign, j.km2
FROM   ctrl_ign_juge j WHERE j.desaccord
ORDER  BY j.km2 DESC LIMIT 25;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    § 7 proche de zéro sur `geofla` non partagé → les attributions'
\echo '        1999-2012 sont justes, comme le § 7 de METHODE.md l''établit'
\echo '        pour 1870-1940.'
\echo '    § 5 excédent de surface important → double comptage des communes'
\echo '        partagées, phénomène du § 6.1 mesuré sur la période moderne.'
\echo '    § 4 « absent chez nous » non nul → une entité IGN n''a pas trouvé'
\echo '        son groupe : le repliement est incomplet.'
\echo ''
\echo 'Tables : ctrl_ign_atome, ctrl_ign_pct, ctrl_ign_corr, ctrl_ign_nous,'
\echo 'ctrl_ign_eux, ctrl_ign_ecart, ctrl_ign_juge.'

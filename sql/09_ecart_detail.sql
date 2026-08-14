-- ============================================================================
-- histgis — 09_ecart_detail.sql : d'où viennent les écarts ?
--
-- 08 mesure. 09 explique. Trois questions, dans cet ordre :
--
--   1. Les contours de département coïncident-ils ? Si oui, les écarts sont
--      une redistribution interne entre cantons voisins, ce qui est un
--      problème d'attribution. Sinon, c'est la composition du département qui
--      diverge, ce qui est plus grave.
--   2. Quel territoire n'est couvert que d'un seul côté, et où ? Le premier
--      rapport laisse 5 926 km² de moins chez nous qu'à Gay en 1870, contre
--      743 km² seulement en 1940 : ce n'est pas du bruit, c'est une zone.
--   3. Atome par atome : lequel tombe dans un autre canton chez Gay ? Et
--      surtout — ces atomes-là sont-ils ceux que nos limites connues
--      désignent (communes disparues rattrapées par successeur, polygones
--      partagés, hac_partage) ou d'autres ?
--
-- La question 3 est la seule qui décide. Si les atomes litigieux sont ceux
-- qu'on savait fragiles, le contrôle valide la chaîne. S'ils sont ailleurs,
-- il y a une erreur d'attribution à corriger.
--
-- Prérequis : 08_controle_gay.sql passé (tables ctrl_*).
-- Rejouable.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.ctrl_ecart') IS NULL THEN
        RAISE EXCEPTION 'ctrl_ecart absente : lancer 08_controle_gay.sql avant.';
    END IF;
    -- 11_scission.sql est facultatif ; la section 8 reste vide sans lui.
    -- Une table absente casse à l'analyse, pas à l'exécution : on la crée
    -- vide plutôt que de tester son existence dans les requêtes.
    IF to_regclass('histgis.scission_trace') IS NULL THEN
        CREATE TABLE scission_trace (
            membership_id bigint PRIMARY KEY,
            atom_id       text NOT NULL,
            unit_id       text NOT NULL,
            niveau        text NOT NULL,
            valid_from    date NOT NULL,
            valid_to      date NOT NULL,
            debut_reel    date NOT NULL,
            pose_le       timestamptz NOT NULL DEFAULT now()
        );
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Niveau département
--
-- On remonte d'un cran : union de tous nos pseudo-cantons d'un département
-- contre celle de Gay. À ce niveau, toute erreur d'attribution entre deux
-- cantons du même département s'annule. Ce qui reste est un désaccord sur le
-- contenu du département lui-même.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_dep;
CREATE TABLE ctrl_dep AS
WITH n AS (
    SELECT c.annee, c.dep, ST_Union(x.geom) AS geom
    FROM   ctrl_ecart c JOIN ctrl_nous x USING (annee, deppct)
    WHERE  c.statut = 'apparie' AND c.dep IS NOT NULL
    GROUP  BY 1, 2
), g AS (
    SELECT c.annee, c.dep, ST_Union(x.geom) AS geom
    FROM   ctrl_ecart c JOIN ctrl_eux x USING (annee, deppct)
    WHERE  c.statut = 'apparie' AND c.dep IS NOT NULL
    GROUP  BY 1, 2
)
SELECT n.annee, n.dep,
       round((ST_Area(n.geom) / 1e6)::numeric, 1) AS km2_nous,
       round((ST_Area(g.geom) / 1e6)::numeric, 1) AS km2_gay,
       round((ST_Area(ST_Difference(n.geom, g.geom)) / 1e6)::numeric, 1) AS km2_nous_seul,
       round((ST_Area(ST_Difference(g.geom, n.geom)) / 1e6)::numeric, 1) AS km2_gay_seul,
       round((ST_Area(ST_Intersection(n.geom, g.geom))
              / nullif(ST_Area(ST_Union(n.geom, g.geom)), 0))::numeric, 5) AS iou,
       ST_Multi(ST_CollectionExtract(
           ST_MakeValid(ST_SymDifference(n.geom, g.geom)), 3)) AS geom_ecart
FROM   n JOIN g USING (annee, dep);

ALTER TABLE ctrl_dep ADD PRIMARY KEY (annee, dep);

-- ---------------------------------------------------------------------------
-- 2. Chaque atome, et le canton où Gay le range
--
-- Les deux couches sont bâties sur les mêmes polygones GEOFLA 2011, et celles
-- de Gay sont disjointes (double comptage nul, vérifié en 08). Un point
-- intérieur à l'atome tombe donc dans un et un seul pseudo-canton de Gay :
-- ST_PointOnSurface suffit, sans recourir à un calcul de recouvrement.
--
-- Réserve : les 333 atomes-fractions partagent le polygone de leur commune.
-- Ils reçoivent tous le même pseudo-canton, ce qui est faux pour tous sauf un.
-- La colonne `partagee` permet de les écarter de la lecture.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_atome;
CREATE TABLE ctrl_atome AS
WITH pt AS (
    SELECT atom_id, source, partagee, ST_PointOnSurface(geom) AS p
    FROM   atom_geom
), nous AS (
    SELECT y.annee, m.atom_id, m.unit_id, c.deppct
    FROM   (SELECT DISTINCT annee FROM ctrl_gay) y
    JOIN   membership m
           ON m.niveau = 'canton' AND m.periode @> make_date(y.annee, 6, 1)
    JOIN   ctrl_corr c ON c.annee = y.annee AND c.unit_id = m.unit_id
)
SELECT nous.annee,
       nous.atom_id,
       nous.unit_id,
       nous.deppct AS pct_nous,
       e.deppct    AS pct_gay,
       pt.source,
       pt.partagee
FROM   nous
JOIN   pt ON pt.atom_id = nous.atom_id
LEFT   JOIN ctrl_eux e ON e.annee = nous.annee AND ST_Contains(e.geom, pt.p);

CREATE INDEX ctrl_atome_idx ON ctrl_atome (annee, pct_nous, pct_gay);

-- ---------------------------------------------------------------------------
-- 3. Rapport
-- ---------------------------------------------------------------------------
\echo ''
\echo '============================================================'
\echo ' D''OÙ VIENNENT LES ÉCARTS'
\echo '============================================================'

\echo ''
\echo '=== 1. Contours de département : concordent-ils ? ==='
\echo '    Un IoU proche de 1 ici, alors que les cantons divergent, signifie'
\echo '    que les écarts sont une redistribution INTERNE au département.'
SELECT annee,
       count(*)                                AS n_dep,
       count(*) FILTER (WHERE iou >= 0.9999)   AS identiques,
       count(*) FILTER (WHERE iou <  0.99)     AS sous_99,
       round(avg(iou), 5)                      AS iou_moyen,
       round(sum(km2_nous_seul), 0)            AS km2_nous_seul,
       round(sum(km2_gay_seul), 0)             AS km2_gay_seul
FROM   ctrl_dep GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- départements dont le contour diverge (top 15) ---'
SELECT annee, dep, km2_nous, km2_gay, km2_nous_seul, km2_gay_seul, iou
FROM   ctrl_dep ORDER BY iou ASC LIMIT 15;

\echo ''
\echo '=== 2. Territoire couvert par un seul des deux ==='
\echo '    C''est ici que doivent apparaître les 5 926 km² manquants de 1870.'
SELECT annee, dep, km2_gay_seul, km2_nous_seul, iou
FROM   ctrl_dep WHERE km2_gay_seul > 50
ORDER  BY km2_gay_seul DESC LIMIT 20;

\echo ''
\echo '--- atomes sans géométrie, par année ---'
\echo '    Une autre explication possible du déficit de surface.'
SELECT y.annee, count(*) AS atomes_sans_geom
FROM   (SELECT DISTINCT annee FROM ctrl_gay) y
JOIN   membership m
       ON m.niveau = 'canton' AND m.periode @> make_date(y.annee, 6, 1)
LEFT   JOIN atom_geom g ON g.atom_id = m.atom_id
WHERE  g.atom_id IS NULL
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Atomes rangés ailleurs par Gay ==='
SELECT annee,
       count(*)                                              AS n_atomes,
       count(*) FILTER (WHERE pct_gay IS NULL)               AS hors_couverture,
       count(*) FILTER (WHERE pct_nous IS DISTINCT FROM pct_gay
                          AND pct_gay IS NOT NULL)           AS mal_places,
       round(100.0 * count(*) FILTER (WHERE pct_nous IS DISTINCT FROM pct_gay
                                        AND pct_gay IS NOT NULL) / count(*), 2)
                                                             AS pct_mal_places
FROM   ctrl_atome GROUP BY annee ORDER BY annee;

\echo ''
\echo '=== 4. LA question : les limites connues expliquent-elles ces atomes ? ==='
\echo '    `geofla` + non partagé = atome sans excuse. Un taux élevé de'
\echo '    désaccord dans cette ligne est une vraie erreur d''attribution.'
SELECT annee,
       source,
       partagee,
       count(*)                                                       AS n_atomes,
       count(*) FILTER (WHERE pct_nous IS DISTINCT FROM pct_gay)      AS en_desaccord,
       round(100.0 * count(*) FILTER (WHERE pct_nous IS DISTINCT FROM pct_gay)
             / count(*), 2)                                           AS pct
FROM   ctrl_atome
GROUP  BY annee, source, partagee
ORDER  BY annee, 6 DESC;

\echo ''
\echo '=== 5. Paires de cantons qui échangent des atomes (top 25) ==='
\echo '    Un échange réciproque entre deux cantons voisins évoque une erreur'
\echo '    de lecture de nomenclature ; un flux à sens unique, une commune'
\echo '    rattachée au mauvais canton.'
SELECT a.annee, a.pct_nous, a.pct_gay,
       en.pct_name AS nom_chez_nous,
       eg.pct_name AS nom_chez_gay,
       count(*)    AS n_atomes,
       count(*) FILTER (WHERE a.source <> 'geofla' OR a.partagee) AS dont_fragiles
FROM   ctrl_atome a
LEFT   JOIN ctrl_eux en ON en.annee = a.annee AND en.deppct = a.pct_nous
LEFT   JOIN ctrl_eux eg ON eg.annee = a.annee AND eg.deppct = a.pct_gay
WHERE  a.pct_gay IS NOT NULL AND a.pct_nous IS DISTINCT FROM a.pct_gay
GROUP  BY 1, 2, 3, 4, 5 ORDER BY 6 DESC LIMIT 25;

\echo ''
\echo '=== 6. Détail des cinq cantons les plus en écart ==='
WITH pires AS (
    SELECT annee, deppct FROM ctrl_ecart
    WHERE  statut = 'apparie' AND n_pseudo = 0
    ORDER  BY iou ASC LIMIT 5
)
SELECT a.annee, a.pct_nous, a.atom_id, at.insee_geofla, a.pct_gay,
       a.source, a.partagee
FROM   ctrl_atome a
JOIN   pires p ON p.annee = a.annee AND p.deppct = a.pct_nous
JOIN   atom at ON at.atom_id = a.atom_id
WHERE  a.pct_nous IS DISTINCT FROM a.pct_gay
ORDER  BY a.annee, a.pct_nous, a.atom_id LIMIT 60;

\echo ''
\echo '=== 7. Le département 99 ==='
\echo '    Codes Cassini d''un département disparu. Ce que nous en disons :'
SELECT DISTINCT u.dep AS notre_dep, count(*) AS n_unites
FROM   ctrl_ecart c
JOIN   unit u ON u.unit_id = c.deppct AND u.niveau = 'canton'
WHERE  c.dep = '99'
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '=== 8. Le correctif de scission, noté par Gay ==='
\echo '    11_scission.sql prolonge vers l''arrière le rattachement des atomes'
\echo '    apparus en cours de série, en pariant qu''une commune nouvelle reste'
\echo '    dans le canton de sa mère. Voici le score du pari.'
SELECT a.annee,
       count(*)                                                   AS atomes_prolonges,
       count(*) FILTER (WHERE a.pct_nous IS DISTINCT FROM a.pct_gay) AS pari_perdu,
       round(100.0 * count(*) FILTER (WHERE a.pct_nous IS NOT DISTINCT FROM a.pct_gay)
             / nullif(count(*), 0), 2)                            AS pct_pari_gagne
FROM   ctrl_atome a
WHERE  EXISTS (
           SELECT 1 FROM scission_trace t
           WHERE  t.atom_id = a.atom_id AND t.niveau = 'canton'
             AND  daterange(t.valid_from, t.valid_to, '[)') @> make_date(a.annee, 6, 1)
       )
GROUP  BY a.annee ORDER BY a.annee;

\echo ''
\echo '--- les communes qui n''ont pas suivi le canton de leur mère ---'
\echo '    Chacune est un rattachement à corriger à la main, ou à retirer.'
SELECT a.annee, a.atom_id, at.insee_geofla,
       a.pct_nous, en.pct_name AS ou_nous_la_mettons,
       a.pct_gay,  eg.pct_name AS ou_gay_la_met,
       t.debut_reel,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2,
       a.source
FROM   ctrl_atome a
JOIN   scission_trace t ON t.atom_id = a.atom_id AND t.niveau = 'canton'
                       AND daterange(t.valid_from, t.valid_to, '[)')
                           @> make_date(a.annee, 6, 1)
JOIN   atom at     ON at.atom_id = a.atom_id
JOIN   atom_geom g ON g.atom_id = a.atom_id
LEFT   JOIN ctrl_eux en ON en.annee = a.annee AND en.deppct = a.pct_nous
LEFT   JOIN ctrl_eux eg ON eg.annee = a.annee AND eg.deppct = a.pct_gay
WHERE  a.pct_nous IS DISTINCT FROM a.pct_gay
ORDER  BY ST_Area(g.geom) DESC, a.annee LIMIT 40;

\echo ''
\echo 'Tables laissées en base : ctrl_dep (avec geom_ecart), ctrl_atome.'

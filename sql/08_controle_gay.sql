-- ============================================================================
-- histgis — 08_controle_gay.sql : contrôle indépendant
--
-- On compare `snapshot_geom(date, 'canton')` aux cantons DÉJÀ dissous par
-- Victor Gay pour 1870 et 1940. Ces polygones ne passent par aucune ligne de
-- notre code : si les deux coïncident, c'est toute la chaîne qui est validée —
-- extraction, attributions, rattrapages de communes disparues, dissolution.
--
-- Le point à comprendre avant de lire les chiffres
-- ------------------------------------------------
-- Les shapefiles de Gay sont découpés en PSEUDO-CANTONS (`deppct`), pas en
-- cantons réels (`depct`). Un pseudo-canton regroupe les cantons urbains d'une
-- même ville : Montluçon-Est (0320) et Montluçon-Ouest (0321) ne forment qu'un
-- seul polygone « Montluçon » (0380), parce que la trame communale ne sait pas
-- couper une commune en deux. La comparaison se fait donc au niveau du
-- pseudo-canton, seul niveau où les deux côtés sont commensurables.
--
-- `COG_CANTONS_YYYY_MAPPING.tab` ne liste que ces regroupements. Pour tout
-- canton absent du fichier, deppct = depct : c'est l'identité posée plus bas.
--
-- Prérequis : base chargée (load.sh, puis 05 → 06 → 07), tables ctrl_gay_YYYY
-- présentes (ogr2ogr), variable psql `mapping` pointant le CSV.
-- Rejouable : toutes les tables ctrl_* sont recréées.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom') IS NULL THEN
        RAISE EXCEPTION 'atom_geom absente : lancer 05_geom.sql avant ce contrôle.';
    END IF;
    IF to_regclass('histgis.ctrl_gay_1870') IS NULL
       AND to_regclass('histgis.ctrl_gay_1940') IS NULL THEN
        RAISE EXCEPTION 'aucune table ctrl_gay_YYYY : lancer controle_gay.sh, pas ce fichier seul.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les polygones de Gay, réunis en une table
--
-- ogr2ogr crée une table par année. On les empile, en normalisant les codes :
-- le DBF les stocke en numérique (dep 6, deppct 604), nous en texte cadré
-- ('06', '0604').
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_gay CASCADE;
CREATE TABLE ctrl_gay (
    annee     int  NOT NULL,
    deppct    text NOT NULL,
    dep       char(2) NOT NULL,
    pct_name  text,
    pct_type  text,
    geom      geometry(MultiPolygon, 2154) NOT NULL
);

DO $$
DECLARE
    t record;
    a int;
BEGIN
    FOR t IN
        SELECT c.relname
        FROM   pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE  n.nspname = 'histgis' AND c.relkind = 'r'
          AND  c.relname ~ '^ctrl_gay_[0-9]{4}$'
        ORDER  BY 1
    LOOP
        a := substring(t.relname from '([0-9]{4})$')::int;
        EXECUTE format($f$
            INSERT INTO ctrl_gay (annee, deppct, dep, pct_name, pct_type, geom)
            SELECT %s,
                   lpad((deppct::numeric::bigint)::text, 4, '0'),
                   lpad((dep::numeric::bigint)::text, 2, '0'),
                   pct_name, pct_type,
                   -- ST_MakeValid peut rendre une GeometryCollection ;
                   -- CollectionExtract(.,3) n'en garde que les surfaces.
                   ST_Multi(ST_CollectionExtract(ST_MakeValid(geom), 3))
            FROM   histgis.%I
            WHERE  geom IS NOT NULL
        $f$, a, t.relname);
        RAISE NOTICE 'ctrl_gay : % lignes reprises de %',
              (SELECT count(*) FROM ctrl_gay WHERE annee = a), t.relname;
    END LOOP;
END $$;

CREATE INDEX ctrl_gay_cle_idx ON ctrl_gay (annee, deppct);

-- ---------------------------------------------------------------------------
-- 2. Correspondance canton réel → pseudo-canton
--
-- Le fichier ne contient que les exceptions ; l'identité vaut pour le reste.
--
-- Le repliement s'applique AUX DEUX CÔTÉS, et c'est le point où le premier
-- passage s'est trompé. Chez Gay, un ensemble urbain n'est pas un polygone
-- mais plusieurs : le pseudo-canton (`pct_type = 'Pseudo canton'`) ne porte
-- que la commune indivise — la ville — tandis que les communes entières de
-- chaque canton restent dans des polygones séparés, portant le code du canton
-- réel. Moulins : `0381` = les 8 km² de la ville, `0323` et `0324` = les
-- communes rurales de Moulins-Est et Moulins-Ouest. Ne replier que notre côté
-- revient à comparer deux cantons à un centre-ville.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_mapping_src;
CREATE TABLE ctrl_mapping_src (
    annee    int  NOT NULL,
    dep      text,
    depct    text NOT NULL,
    ct_name  text,
    deppct   text NOT NULL,
    pct_name text
);

-- \copy n'interpole pas les variables : même contournement qu'en 02_load.sql.
\set cmd '\\copy ctrl_mapping_src FROM ' :'mapping' ' WITH (FORMAT csv, HEADER true)'
:cmd

-- Collision de codes : un même code servirait de canton réel ici et de
-- pseudo-canton là, et le repliement mélangerait les deux. Les codes de
-- pseudo-cantons finissent en 80-89, donc le risque n'existe que dans les
-- départements à plus de 80 cantons. Vérifié plutôt que supposé.
DROP TABLE IF EXISTS ctrl_collision;
CREATE TABLE ctrl_collision AS
SELECT annee, depct AS code FROM ctrl_mapping_src
INTERSECT
SELECT annee, deppct FROM ctrl_mapping_src;

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM ctrl_collision;
    IF n > 0 THEN
        RAISE WARNING 'ctrl_collision : % codes ambigus (canton réel ET pseudo-canton). Le repliement est faussé pour ceux-là.', n;
    END IF;
END $$;

DROP TABLE IF EXISTS ctrl_corr;
CREATE TABLE ctrl_corr (
    annee    int  NOT NULL,
    unit_id  text NOT NULL,
    deppct   text NOT NULL,
    origine  text NOT NULL CHECK (origine IN ('mapping', 'identite')),
    PRIMARY KEY (annee, unit_id)
);

INSERT INTO ctrl_corr (annee, unit_id, deppct, origine)
SELECT a.annee,
       s.unit_id,
       coalesce(m.deppct, s.unit_id),
       CASE WHEN m.deppct IS NULL THEN 'identite' ELSE 'mapping' END
FROM   (SELECT DISTINCT annee FROM ctrl_gay) a
CROSS  JOIN LATERAL snapshot(make_date(a.annee, 6, 1), 'canton') s
LEFT   JOIN ctrl_mapping_src m
       ON m.annee = a.annee AND m.depct = s.unit_id;

CREATE INDEX ctrl_corr_pct_idx ON ctrl_corr (annee, deppct);

-- ---------------------------------------------------------------------------
-- 3. Les deux couches à comparer, dissoutes au même niveau
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_nous;
CREATE TABLE ctrl_nous AS
SELECT c.annee,
       c.deppct,
       count(*)                                    AS n_cantons,
       string_agg(sg.unit_id, ';' ORDER BY sg.unit_id) AS cantons,
       sum(sg.n_sans_geom)                         AS n_sans_geom,
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(sg.geom)), 3)) AS geom
FROM   (SELECT DISTINCT annee FROM ctrl_gay) y
CROSS  JOIN LATERAL snapshot_geom(make_date(y.annee, 6, 1), 'canton') sg
JOIN   ctrl_corr c ON c.annee = y.annee AND c.unit_id = sg.unit_id
GROUP  BY c.annee, c.deppct;

ALTER TABLE ctrl_nous ADD PRIMARY KEY (annee, deppct);

DROP TABLE IF EXISTS ctrl_eux;
CREATE TABLE ctrl_eux AS
SELECT g.annee,
       coalesce(m.deppct, g.deppct)              AS deppct,
       min(g.dep)                                AS dep,
       -- le nom du pseudo-canton quand il y en a un, sinon celui du canton
       coalesce(min(m.pct_name), min(g.pct_name)) AS pct_name,
       count(*)                                  AS n_polygones,
       count(*) FILTER (WHERE g.pct_type = 'Pseudo canton') AS n_pseudo,
       string_agg(DISTINCT g.deppct, ';' ORDER BY g.deppct) AS codes_gay,
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(g.geom)), 3)) AS geom
FROM   ctrl_gay g
LEFT   JOIN ctrl_mapping_src m
       ON m.annee = g.annee AND m.depct = g.deppct
GROUP  BY g.annee, coalesce(m.deppct, g.deppct);

ALTER TABLE ctrl_eux ADD PRIMARY KEY (annee, deppct);

-- ---------------------------------------------------------------------------
-- 4. La comparaison
--
-- `iou` = surface de l'intersection / surface de l'union. 1 = polygones
-- identiques, 0 = disjoints. C'est la mesure honnête ici : insensible à la
-- taille du canton, et symétrique — elle ne privilégie aucune des deux sources.
--
-- Jointure externe des deux côtés : un pseudo-canton présent d'un seul côté
-- est une anomalie de clé, pas de géométrie, et doit rester visible.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_ecart;
CREATE TABLE ctrl_ecart AS
SELECT coalesce(n.annee, e.annee)   AS annee,
       coalesce(n.deppct, e.deppct) AS deppct,
       e.dep,
       e.pct_name,
       n.cantons,
       n.n_cantons,
       n.n_sans_geom,
       e.n_polygones,
       e.n_pseudo,
       e.codes_gay,
       round((ST_Area(n.geom) / 1e6)::numeric, 2) AS km2_nous,
       round((ST_Area(e.geom) / 1e6)::numeric, 2) AS km2_eux,
       round((ST_Area(ST_Intersection(n.geom, e.geom)) / 1e6)::numeric, 2) AS km2_commun,
       CASE WHEN n.geom IS NULL OR e.geom IS NULL THEN NULL
            ELSE round((ST_Area(ST_Intersection(n.geom, e.geom))
                        / nullif(ST_Area(ST_Union(n.geom, e.geom)), 0))::numeric, 5)
       END AS iou,
       CASE WHEN n.geom IS NULL THEN 'absent chez nous'
            WHEN e.geom IS NULL THEN 'absent chez Gay'
            ELSE 'apparie' END AS statut
FROM   ctrl_nous n
FULL   JOIN ctrl_eux e ON e.annee = n.annee AND e.deppct = n.deppct;

CREATE INDEX ctrl_ecart_idx ON ctrl_ecart (annee, iou);

-- ---------------------------------------------------------------------------
-- 5. Rapport
-- ---------------------------------------------------------------------------
\echo ''
\echo '============================================================'
\echo ' CONTRÔLE INDÉPENDANT — cantons dissous par Victor Gay'
\echo '============================================================'

\echo ''
\echo '=== 1. Ce qui a été chargé ==='
SELECT annee,
       count(*)                                  AS polygones_gay,
       count(DISTINCT deppct)                    AS pseudo_cantons,
       count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalides
FROM   ctrl_gay GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- types de pseudo-cantons (pct_type) ---'
SELECT annee, pct_type, count(*) FROM ctrl_gay GROUP BY 1, 2 ORDER BY 1, 3 DESC;

\echo ''
\echo '=== 2. Appariement des clés (avant toute géométrie) ==='
\echo '    Un écart ici est un problème de nomenclature, pas de tracé.'
SELECT annee,
       count(*) FILTER (WHERE statut = 'apparie')          AS apparies,
       count(*) FILTER (WHERE statut = 'absent chez Gay')  AS chez_nous_seulement,
       count(*) FILTER (WHERE statut = 'absent chez nous') AS chez_gay_seulement
FROM   ctrl_ecart GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- origine de la correspondance canton → pseudo-canton ---'
SELECT annee, origine, count(*) AS n_cantons
FROM   ctrl_corr GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '--- clés orphelines (20 premières) ---'
SELECT annee, deppct, statut, pct_name, cantons
FROM   ctrl_ecart WHERE statut <> 'apparie'
ORDER  BY annee, deppct LIMIT 20;

\echo ''
\echo '--- collisions de codes (doit être vide) ---'
SELECT * FROM ctrl_collision ORDER BY 1, 2 LIMIT 10;

\echo ''
\echo '--- composition des groupes repliés chez Gay ---'
\echo '    Un groupe replié = 1 polygone « Pseudo canton » (la ville indivise)'
\echo '    + n polygones de cantons réels (leurs communes entières).'
SELECT annee, n_pseudo, count(*) AS n_groupes,
       round(avg(n_polygones), 2) AS polygones_par_groupe
FROM   ctrl_ecart WHERE statut = 'apparie'
GROUP  BY annee, n_pseudo ORDER BY annee, n_pseudo;

\echo ''
\echo '=== 3. Surfaces d''ensemble ==='
\echo '    Le total France valide la trame ; il ne dit rien des attributions.'
SELECT annee,
       round(sum(km2_nous), 0)  AS km2_nous,
       round(sum(km2_eux), 0)   AS km2_eux,
       round(sum(km2_nous) - sum(km2_eux), 0) AS ecart,
       round(100 * (sum(km2_nous) - sum(km2_eux)) / nullif(sum(km2_eux), 0), 3) AS ecart_pct
FROM   ctrl_ecart WHERE statut = 'apparie' GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- somme des surfaces vs surface de l''union ---'
\echo '    La somme compte deux fois les communes revendiquées par deux cantons.'
\echo '    L''écart entre les deux colonnes CHIFFRE ce double comptage ; la'
\echo '    surface de l''union, elle, doit valoir la France de l''époque'
\echo '    (~543 900 km² pour le territoire actuel, trame GEOFLA 2011).'
SELECT annee, cote,
       round(somme, 0) AS km2_somme,
       round(union_, 0) AS km2_union,
       round(somme - union_, 0) AS double_comptage
FROM (
    SELECT annee, 'nous' AS cote,
           (sum(ST_Area(geom)) / 1e6)::numeric AS somme,
           (ST_Area(ST_Union(geom)) / 1e6)::numeric AS union_
    FROM   ctrl_nous GROUP BY annee
    UNION ALL
    SELECT annee, 'gay',
           (sum(ST_Area(geom)) / 1e6)::numeric,
           (ST_Area(ST_Union(geom)) / 1e6)::numeric
    FROM   ctrl_eux GROUP BY annee
) t ORDER BY annee, cote;

\echo ''
\echo '--- codes département hors 01-95 (à identifier) ---'
SELECT annee, dep, count(*) AS n_pct,
       (array_agg(pct_name ORDER BY pct_name))[1:5] AS exemples
FROM   ctrl_ecart
WHERE  dep !~ '^(0[1-9]|[1-8][0-9]|9[0-5])$'
GROUP  BY annee, dep ORDER BY annee, dep;

\echo ''
\echo '=== 4. Distribution de l''IoU — le vrai résultat ==='
\echo '    IoU = intersection / union. 1 = tracés identiques.'
SELECT annee,
       count(*)                                        AS n,
       count(*) FILTER (WHERE iou >= 0.9999)           AS "identiques",
       count(*) FILTER (WHERE iou >= 0.999 AND iou < 0.9999) AS "999_pour_mille",
       count(*) FILTER (WHERE iou >= 0.99  AND iou < 0.999)  AS "99_pour_cent",
       count(*) FILTER (WHERE iou >= 0.9   AND iou < 0.99)   AS "90_a_99",
       count(*) FILTER (WHERE iou <  0.9)              AS "sous_90",
       round(min(iou), 4)                              AS pire,
       round(avg(iou), 5)                              AS moyenne
FROM   ctrl_ecart WHERE statut = 'apparie' GROUP BY annee ORDER BY annee;

\echo ''
\echo '=== 5. Les 25 pires écarts ==='
\echo '    À lire avec les limites connues : communes partagées entre cantons,'
\echo '    communes disparues rattrapées par successeur, choix hac_partage.'
SELECT annee, deppct, dep, pct_name, n_cantons, n_polygones, n_sans_geom,
       km2_nous, km2_eux, iou
FROM   ctrl_ecart WHERE statut = 'apparie'
ORDER  BY iou ASC, annee LIMIT 25;

\echo ''
\echo '--- même chose, hors ensembles urbains (n_pseudo = 0) ---'
\echo '    Les cantons ruraux ne subissent aucun repliement : un écart ici'
\echo '    met en cause nos attributions, pas la structure de la comparaison.'
SELECT annee, deppct, dep, pct_name, n_cantons, n_sans_geom,
       km2_nous, km2_eux, iou
FROM   ctrl_ecart WHERE statut = 'apparie' AND n_pseudo = 0
ORDER  BY iou ASC, annee LIMIT 25;

\echo ''
\echo '=== 6. Départements les plus en écart (surface non partagée, km²) ==='
SELECT annee, dep,
       count(*) AS n_pct,
       round(sum(km2_nous + km2_eux - 2 * km2_commun), 1) AS km2_divergents,
       round(avg(iou), 4) AS iou_moyen
FROM   ctrl_ecart WHERE statut = 'apparie'
GROUP  BY annee, dep
ORDER  BY 4 DESC NULLS LAST LIMIT 15;

\echo ''
\echo '=== 7. Verdict ==='
SELECT annee,
       round(100.0 * count(*) FILTER (WHERE iou >= 0.999) / count(*), 2)
           AS pct_pseudo_cantons_conformes,
       round(100.0 * sum(km2_commun) / nullif(sum(km2_nous + km2_eux - km2_commun), 0), 3)
           AS pct_surface_commune
FROM   ctrl_ecart WHERE statut = 'apparie' GROUP BY annee ORDER BY annee;

\echo ''
\echo '--- verdict restreint aux cantons ruraux (aucun repliement) ---'
SELECT annee,
       count(*) AS n,
       round(100.0 * count(*) FILTER (WHERE iou >= 0.999) / count(*), 2)
           AS pct_conformes,
       round(avg(iou), 5) AS iou_moyen
FROM   ctrl_ecart WHERE statut = 'apparie' AND n_pseudo = 0
GROUP  BY annee ORDER BY annee;

\echo ''
\echo 'Détail interrogeable dans histgis.ctrl_ecart (une ligne par pseudo-canton).'
\echo 'Cartographie d''un écart :'
\echo '  SELECT ST_SymDifference(n.geom, e.geom) FROM ctrl_nous n JOIN ctrl_eux e'
\echo '    USING (annee, deppct) WHERE annee = 1870 AND deppct = ''0380'';'

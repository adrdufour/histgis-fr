-- ============================================================================
-- histgis — 14_cle_partage.sql : d'où viennent les 108 km² d'écart ?
--
-- Le problème
-- -----------
-- `13` mesure le double comptage de deux façons et trouve 108 km² d'écart,
-- IDENTIQUES aux deux niveaux (12 930 vs 12 822, 3 945 vs 3 837). Un décalage
-- rigoureusement constant ne s'explique pas par du bruit : il désigne une cause
-- unique. Et comme la méthode géométrique ne suppose rien, c'est la méthode par
-- nomenclature qui se trompe — donc sa clé de regroupement.
--
-- L'hypothèse
-- -----------
-- `12` groupe par `code_2011 = coalesce(cs.insee_2011, d.cible, a.insee_geofla)`.
-- Ce coalesce ignore `atom_geom.source`, alors que c'est elle qui décide d'où
-- vient le polygone :
--
--   source = 'geofla'        → polygone de a.insee_geofla
--   source = 'successeur'    → polygone de cs.insee_2011
--   source = 'union_prefixe' → union du préfixe d.cible
--   source = 'absorbee'      → polygone de d.cible
--   source = 'hac', 'hac_partage' → rattaché par NOM, aucune colonne ne le dit
--
-- Deux dérives possibles, et elles vont en sens contraire :
--   a) un atome dont le code a survécu dans GEOFLA (source 'geofla') mais qui
--      figure aussi comme `insee_ancien` dans commune_successeur reçoit
--      `cs.insee_2011` par le coalesce — une clé qui n'est pas celle de son
--      polygone. Il est alors groupé avec des atomes qu'il ne recouvre pas, ou
--      séparé de ceux qu'il recouvre ;
--   b) les 17 atomes `hac`/`hac_partage` tombent sur `a.insee_geofla`, un code
--      d'époque absent de GEOFLA : chacun forme un groupe d'un seul, alors que
--      son polygone est celui d'une commune que d'autres atomes portent aussi.
--
-- La méthode
-- ----------
-- Ne plus faire confiance à aucune clé et grouper par la GÉOMÉTRIE. Deux atomes
-- portant le même polygone ont, dans `05`, exactement la même géométrie : elle
-- est construite par le même ST_UnaryUnion(ST_Collect(...)) sur le même jeu de
-- communes GEOFLA. Une empreinte binaire suffit donc à les réunir, sans passer
-- par aucun code.
--
-- Si le regroupement par empreinte reproduit les chiffres géométriques de `13`
-- au km² près, l'écart est entièrement imputable à la clé, et les atomes que les
-- deux regroupements séparent sont nommés en § 3.
--
-- Prérequis : base chargée, controle_gay.sh (ctrl_corr), 12 (conflit_atome).
-- Lecture seule. Aucune table créée.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set date_ref '1870-06-01'
\set annee_ref 1870

DO $$
BEGIN
    IF to_regclass('histgis.ctrl_corr') IS NULL THEN
        RAISE EXCEPTION 'ctrl_corr absente : lancer controle_gay.sh avant.';
    END IF;
    IF to_regclass('histgis.conflit_atome') IS NULL THEN
        RAISE EXCEPTION 'conflit_atome absente : lancer 12_conflit_successeur.sql avant.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' LA CLÉ DE PARTAGE — attribuer les 108 km² de `13`'
\echo '============================================================'
\echo '(date de référence : 1870-06-01)'

-- ---------------------------------------------------------------------------
-- Socle : chaque atome vivant à la date, avec ses trois clés possibles.
--
--   cle_12       : celle de 12, coalesce aveugle à la source
--   cle_source   : la même, mais dictée par atom_geom.source
--   cle_geom     : l'empreinte du polygone — la seule qui ne suppose rien
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_cle_atome;
CREATE TEMP VIEW v_cle_atome AS
SELECT m.atom_id,
       m.unit_id,
       u.dep,
       ag.source,
       a.insee_geofla,
       coalesce(cc.deppct, m.unit_id)                     AS deppct,
       coalesce(cs.insee_2011, d.cible, a.insee_geofla)   AS cle_12,
       CASE ag.source
            WHEN 'successeur'    THEN cs.insee_2011
            WHEN 'union_prefixe' THEN d.cible
            WHEN 'absorbee'      THEN d.cible
            ELSE                      a.insee_geofla
       END                                                AS cle_source,
       md5(ST_AsEWKB(ag.geom))                            AS cle_geom,
       ST_Area(ag.geom) / 1e6                             AS km2
FROM   membership m
JOIN   atom a       ON a.atom_id = m.atom_id
JOIN   atom_geom ag ON ag.atom_id = m.atom_id
JOIN   unit u       ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN commune_successeur cs      ON cs.insee_ancien = a.insee_geofla
LEFT   JOIN diag_geom_correspondance d ON d.insee        = a.insee_geofla
LEFT   JOIN ctrl_corr cc ON cc.annee = :annee_ref AND cc.unit_id = m.unit_id
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_ref'::date;

-- ---------------------------------------------------------------------------
-- 1. Le même calcul, avec les trois clés
--
-- Un polygone réclamé par k cantons pèse (k-1) fois sa surface ; après
-- repliement, (p-1) fois. Seule la clé change d'une ligne à l'autre.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Double comptage selon la clé de regroupement ==='
\echo '    Cible : 12 930 et 3 945, les mesures géométriques de `13` § 1.'
WITH par_cle AS (
    SELECT 'cle_12 (celle de 12)' AS cle, cle_12 AS k, unit_id, deppct, km2 FROM v_cle_atome
    UNION ALL
    SELECT 'cle_source (corrigee)', cle_source, unit_id, deppct, km2 FROM v_cle_atome
    UNION ALL
    SELECT 'cle_geom (empreinte)',  cle_geom,   unit_id, deppct, km2 FROM v_cle_atome
),
g AS (
    SELECT cle, k,
           max(km2)                       AS km2,
           count(DISTINCT unit_id)        AS k_cantons,
           count(DISTINCT deppct)         AS p_pseudo
    FROM   par_cle GROUP BY cle, k
)
SELECT cle,
       count(*)                                        AS groupes,
       count(*) FILTER (WHERE k_cantons > 1)           AS groupes_eclates,
       round(sum(km2 * (k_cantons - 1))::numeric, 0)   AS double_canton_reel,
       round(sum(km2 * (p_pseudo  - 1))::numeric, 0)   AS double_apres_repliement
FROM   g GROUP BY cle ORDER BY 1;

\echo ''
\echo '    Si `cle_geom` donne 12 930 et 3 945, l''écart de `13` est entièrement'
\echo '    imputable à la clé, et la mesure géométrique avait raison.'
\echo '    Si `cle_source` y arrive aussi, le correctif à porter dans `12` est'
\echo '    de rendre le coalesce sensible à `atom_geom.source`.'

-- ---------------------------------------------------------------------------
-- 2. Combien d'atomes les clés séparent-elles ?
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Où les clés divergent-elles ? ==='
SELECT count(*)                                             AS atomes,
       count(*) FILTER (WHERE cle_12 IS DISTINCT FROM cle_source) AS cle12_vs_source,
       count(*) FILTER (WHERE cle_source IS NULL)           AS cle_source_nulle,
       count(*) FILTER (WHERE source IN ('hac', 'hac_partage')) AS atomes_hac
FROM   v_cle_atome;

\echo ''
\echo '--- par source ---'
SELECT source,
       count(*)                                                   AS atomes,
       count(*) FILTER (WHERE cle_12 IS DISTINCT FROM cle_source) AS cle_faussee,
       round(sum(km2) FILTER (WHERE cle_12 IS DISTINCT FROM cle_source)::numeric, 1)
                                                                  AS km2_concernes
FROM   v_cle_atome GROUP BY source ORDER BY 3 DESC, 1;

\echo ''
\echo '    Hypothèse (a) : des atomes `geofla` qui figurent aussi comme'
\echo '    `insee_ancien` dans commune_successeur et reçoivent donc à tort la'
\echo '    clé du successeur. Ils apparaissent ici en `cle_faussee`.'

-- ---------------------------------------------------------------------------
-- 3. Les groupes que la géométrie réunit et que `12` séparait
--
-- Ce sont eux qui portent les 108 km². Un groupe d'empreinte couvrant
-- plusieurs `cle_12` est un double comptage réel que `12` ne voyait pas.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Ce que la géométrie réunit et que `12` séparait ==='
\echo '    Ces groupes portent le double comptage manquant.'
WITH g AS (
    SELECT cle_geom,
           max(km2)                     AS km2,
           count(DISTINCT unit_id)      AS k_cantons,
           count(DISTINCT deppct)       AS p_pseudo,
           count(DISTINCT cle_12)       AS n_cles_12,
           string_agg(DISTINCT source,  ',' ORDER BY source)  AS sources,
           string_agg(DISTINCT cle_12,  ';' ORDER BY cle_12)  AS cles_12,
           string_agg(DISTINCT insee_geofla, ';' ORDER BY insee_geofla) AS insee_epoque,
           string_agg(DISTINCT dep::text, ';' ORDER BY dep::text)       AS deps
    FROM   v_cle_atome GROUP BY cle_geom
)
SELECT round(km2::numeric, 2) AS km2_polygone, k_cantons, p_pseudo, n_cles_12,
       sources, left(cles_12, 30) AS cles_12,
       left(insee_epoque, 30) AS insee_epoque, deps
FROM   g
WHERE  n_cles_12 > 1 AND k_cantons > 1
ORDER  BY km2 * (k_cantons - 1) DESC LIMIT 30;

\echo ''
\echo '--- total porté par ces groupes ---'
WITH g AS (
    SELECT cle_geom, max(km2) AS km2,
           count(DISTINCT unit_id) AS k_cantons,
           count(DISTINCT deppct)  AS p_pseudo,
           count(DISTINCT cle_12)  AS n_cles_12
    FROM   v_cle_atome GROUP BY cle_geom
)
SELECT count(*)                                            AS groupes,
       round(sum(km2 * (k_cantons - 1))::numeric, 1)       AS km2_canton_reel,
       round(sum(km2 * (p_pseudo  - 1))::numeric, 1)       AS km2_apres_repliement
FROM   g WHERE n_cles_12 > 1 AND k_cantons > 1;

\echo ''
\echo '    Attendu : ~108 km² dans les deux colonnes — c''est ce qui rendrait'
\echo '    compte de l''écart, et de sa constance d''un niveau à l''autre.'

-- ---------------------------------------------------------------------------
-- 4. Le cas inverse : ce que `12` réunissait à tort
--
-- Un `cle_12` couvrant plusieurs empreintes signale des atomes groupés
-- ensemble alors qu'ils ne partagent aucun polygone. Effet en sens contraire.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Le cas inverse : ce que `12` réunissait à tort ==='
WITH g AS (
    SELECT cle_12,
           count(DISTINCT cle_geom) AS n_empreintes,
           count(DISTINCT unit_id)  AS k_cantons,
           round(max(km2)::numeric, 2) AS km2_max,
           round(min(km2)::numeric, 2) AS km2_min,
           string_agg(DISTINCT source, ',' ORDER BY source) AS sources
    FROM   v_cle_atome GROUP BY cle_12
)
SELECT * FROM g WHERE n_empreintes > 1 ORDER BY km2_max - km2_min DESC LIMIT 15;

\echo ''
\echo '    `12` prenait max(km2_polygone) par groupe : quand un groupe mêle'
\echo '    deux polygones de tailles différentes, il surestime. La colonne'
\echo '    km2_max - km2_min mesure ce que cette approximation coûte.'

-- ---------------------------------------------------------------------------
-- 5. Les 17 atomes rattachés par nom, nommés un par un
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Les atomes `hac` et `hac_partage` ==='
\echo '    Rattachés par nom : aucune colonne ne dit quel polygone ils portent.'
\echo '    `partage_avec` compte les autres atomes de même empreinte.'
SELECT v.atom_id, v.insee_geofla, v.source, v.unit_id, v.dep,
       round(v.km2::numeric, 2) AS km2,
       (SELECT count(*) - 1 FROM v_cle_atome w WHERE w.cle_geom = v.cle_geom)
                                                        AS partage_avec,
       (SELECT count(DISTINCT w.unit_id) FROM v_cle_atome w WHERE w.cle_geom = v.cle_geom)
                                                        AS cantons_sur_ce_polygone
FROM   v_cle_atome v
WHERE  v.source IN ('hac', 'hac_partage')
ORDER  BY v.source, v.km2 DESC;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    § 1 `cle_geom` = 12 930 / 3 945  → l''écart est une affaire de clé,'
\echo '        la mesure géométrique de `13` fait foi, et il n''y a AUCUNE'
\echo '        erreur d''attribution derrière ces 108 km².'
\echo '    § 1 `cle_source` = idem          → correctif à porter dans `12` :'
\echo '        rendre le coalesce sensible à atom_geom.source.'
\echo '    § 3 ≈ 108 km²                    → les coupables sont nommés.'
\echo '    § 1 `cle_geom` ≠ 12 930          → il reste un recouvrement PARTIEL'
\echo '        entre polygones distincts, à chercher par ST_Intersection.'

-- ============================================================================
-- histgis — 13_double_comptage.sql : réconcilier les 12 822 km² de `12`
--                                    avec les 3 945 km² de `08`
--
-- Le problème
-- -----------
-- `12_conflit_successeur.sql` § 2 mesure 12 822 km² comptés en double, et
-- annonce que le chiffre doit « ressembler » aux 3 945 km² de `08` § 3. Il est
-- 3,25 fois plus grand. L'un des deux se trompe, ou ils ne mesurent pas la
-- même chose.
--
-- L'hypothèse
-- -----------
-- Ils ne mesurent pas la même chose, et c'est le repliement qui les sépare.
--
-- `12` compte entre CANTONS RÉELS : un polygone réclamé par k cantons y pèse
-- (k-1) fois sa surface. `08` compte sur `ctrl_nous`, qui est dissous par
-- `deppct` — donc APRÈS repliement en pseudo-cantons. Or le repliement réunit
-- précisément les cantons qui se partagent une commune : c'est sa raison
-- d'être. Marseille, Lyon, Nantes, Toulouse, Bordeaux — les groupes les plus
-- coûteux de `12` § 3 sont tous des ensembles urbains, donc tous repliés.
--
-- Si l'hypothèse tient, le double comptage se décompose exactement en deux :
-- la part absorbée par le repliement, et celle qui y survit — cette dernière
-- devant valoir les 3 945 km² de `08`.
--
-- Ce que le fichier vérifie, et il le fait deux fois
-- -------------------------------------------------
-- Un tableau 2×2 : {canton réel, pseudo-canton} × {mesuré sur la géométrie,
-- calculé depuis la nomenclature}. Les deux méthodes sont indépendantes — la
-- première unionne des polygones, la seconde compte des unités par groupe de
-- partage. Si les quatre cases se recoupent, la décomposition est établie.
--
-- Note, après coup
-- -----------------
-- Ce fichier groupe par `conflit_atome.code_2011`. `14` a montré que cette clé
-- manque 108 km², et `12` groupe désormais sur l'empreinte géométrique. La
-- colonne `code_2011` reste dans `conflit_atome` comme étiquette, donc ce
-- fichier tourne toujours — et c'est voulu : il DOIT garder l'ancienne clé,
-- puisque son objet est de documenter l'écart entre les deux méthodes. Ne pas
-- le « corriger ». Pour la ventilation rural/urbain du § 3 en revanche, la
-- rejouer sur `cle_geom` la préciserait de 108 km².
--
-- Prérequis : base chargée, controle_gay.sh (ctrl_nous, ctrl_corr), puis
-- 12_conflit_successeur.sql (conflit_atome, conflit_groupe).
-- Lecture seule. Aucune table créée.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set date_ref '1870-06-01'
\set annee_ref 1870

DO $$
BEGIN
    IF to_regclass('histgis.conflit_groupe') IS NULL THEN
        RAISE EXCEPTION 'conflit_groupe absente : lancer 12_conflit_successeur.sql avant.';
    END IF;
    IF to_regclass('histgis.ctrl_nous') IS NULL THEN
        RAISE EXCEPTION 'ctrl_nous absente : lancer controle_gay.sh avant.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' DOUBLE COMPTAGE — 12 822 ou 3 945 km² ?'
\echo '============================================================'
\echo '(date de référence : 1870-06-01)'

-- ---------------------------------------------------------------------------
-- 1. Mesure géométrique, aux deux niveaux
--
-- Somme des surfaces moins surface de l'union. Aucune nomenclature n'entre
-- ici : on unionne des polygones et on compare. Le niveau canton réel vient
-- de snapshot_geom, le niveau pseudo-canton de ctrl_nous, déjà replié par 08.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Mesure géométrique : sum(surfaces) - surface(union) ==='
\echo '    Aucune nomenclature ici, uniquement des unions de polygones.'
WITH reels AS (
    SELECT ST_Union(sg.geom) AS u, sum(ST_Area(sg.geom)) AS s
    FROM   snapshot_geom(:'date_ref'::date, 'canton') sg
    WHERE  sg.geom IS NOT NULL
),
pseudo AS (
    SELECT ST_Union(geom) AS u, sum(ST_Area(geom)) AS s
    FROM   ctrl_nous WHERE annee = :annee_ref
)
SELECT 'canton reel'   AS niveau,
       round((s / 1e6)::numeric, 0)                  AS km2_somme,
       round((ST_Area(u) / 1e6)::numeric, 0)         AS km2_union,
       round(((s - ST_Area(u)) / 1e6)::numeric, 0)   AS double_comptage
FROM   reels
UNION ALL
SELECT 'pseudo-canton',
       round((s / 1e6)::numeric, 0),
       round((ST_Area(u) / 1e6)::numeric, 0),
       round(((s - ST_Area(u)) / 1e6)::numeric, 0)
FROM   pseudo;

\echo ''
\echo '    Attendu si l''hypothèse tient : ~12 822 sur la première ligne,'
\echo '    ~3 945 sur la seconde. Les deux colonnes km2_union doivent être'
\echo '    identiques — le repliement ne change pas le territoire couvert.'

-- ---------------------------------------------------------------------------
-- 2. Décomposition par la nomenclature
--
-- Pour chaque groupe de partage, on compte les unités (cantons réels) et les
-- pseudo-cantons distincts auxquels elles se replient. Un polygone réclamé
-- par k cantons qui se replient en p pseudo-cantons pèse :
--   (k-1) × surface au niveau réel,  (p-1) × surface après repliement.
-- La différence, (k-p) × surface, est ce que le repliement absorbe.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Décomposition par la nomenclature ==='
\echo '    Même phénomène, compté par groupe de partage au lieu d''être mesuré'
\echo '    sur les polygones. Méthode indépendante de la section 1.'
WITH g AS (
    SELECT c.code_2011,
           max(c.km2_polygone)                                  AS km2,
           count(DISTINCT c.unit_id)                            AS k_cantons,
           count(DISTINCT coalesce(cc.deppct, c.unit_id))       AS p_pseudo
    FROM   conflit_atome c
    LEFT   JOIN ctrl_corr cc ON cc.annee = :annee_ref AND cc.unit_id = c.unit_id
    GROUP  BY c.code_2011
)
SELECT round(sum(km2 * (k_cantons - 1)), 0)             AS double_canton_reel,
       round(sum(km2 * (k_cantons - p_pseudo)), 0)      AS absorbe_par_repliement,
       round(sum(km2 * (p_pseudo  - 1)), 0)             AS survit_au_repliement,
       count(*) FILTER (WHERE k_cantons > 1)            AS groupes_eclates,
       count(*) FILTER (WHERE p_pseudo  > 1)            AS groupes_eclates_apres_repliement
FROM   g;

\echo ''
\echo '    `survit_au_repliement` est la prédiction de la section 1, ligne 2.'
\echo '    `groupes_eclates_apres_repliement` sont les seuls cas que le'
\echo '    repliement ne règle pas : ce sont eux, et eux seuls, que le'
\echo '    contrôle Gay voit encore.'

-- ---------------------------------------------------------------------------
-- 3. Ce que le repliement absorbe, et pourquoi
--
-- Si l'hypothèse est la bonne, les groupes absorbés sont les ensembles urbains
-- et l'origine de leur correspondance doit être 'mapping', pas 'identite'.
-- C'est le test le plus direct : le repliement n'absorbe que ce que le fichier
-- MAPPING de TRF-GIS déclare comme regroupement urbain.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Le repliement n''absorbe-t-il que des groupes urbains ? ==='
\echo '    Origine de la correspondance canton → pseudo-canton, pour les'
\echo '    unités des groupes éclatés. `mapping` = regroupement urbain déclaré'
\echo '    par TRF-GIS, `identite` = canton ordinaire.'
WITH g AS (
    SELECT c.code_2011,
           max(c.km2_polygone)                            AS km2,
           count(DISTINCT c.unit_id)                      AS k_cantons,
           count(DISTINCT coalesce(cc.deppct, c.unit_id)) AS p_pseudo,
           bool_or(cc.origine = 'mapping')                AS touche_mapping
    FROM   conflit_atome c
    LEFT   JOIN ctrl_corr cc ON cc.annee = :annee_ref AND cc.unit_id = c.unit_id
    GROUP  BY c.code_2011
)
SELECT CASE WHEN touche_mapping THEN 'au moins un canton replie (mapping)'
            ELSE                     'aucun repliement (identite)' END AS situation,
       count(*)                                  AS groupes,
       round(sum(km2 * (k_cantons - 1)), 0)      AS km2_double_canton_reel,
       round(sum(km2 * (k_cantons - p_pseudo)), 0) AS km2_absorbe,
       round(sum(km2 * (p_pseudo  - 1)), 0)      AS km2_residuel
FROM   g WHERE k_cantons > 1
GROUP  BY 1 ORDER BY 3 DESC;

-- ---------------------------------------------------------------------------
-- 4. Les groupes que le repliement ne règle pas
--
-- Ceux-là sont le vrai coût, celui que le contrôle Gay enregistre. On attend
-- des communes partagées entre cantons ruraux distincts, et non des villes.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Les 25 groupes dont le double comptage survit au repliement ==='
\echo '    Le vrai coût : ce que le contrôle Gay voit encore. Comparer aux'
\echo '    25 pires de `12` § 3, qui étaient tous des villes.'
WITH g AS (
    SELECT c.code_2011,
           max(c.km2_polygone)                            AS km2,
           count(DISTINCT c.unit_id)                      AS k_cantons,
           count(DISTINCT coalesce(cc.deppct, c.unit_id)) AS p_pseudo,
           count(DISTINCT c.dep)                          AS deps,
           count(*) FILTER (WHERE c.desaccord)            AS en_desaccord,
           string_agg(DISTINCT c.source, ',' ORDER BY c.source) AS sources,
           string_agg(DISTINCT coalesce(cc.deppct, c.unit_id), ';'
                      ORDER BY coalesce(cc.deppct, c.unit_id))  AS pseudo_ids
    FROM   conflit_atome c
    LEFT   JOIN ctrl_corr cc ON cc.annee = :annee_ref AND cc.unit_id = c.unit_id
    GROUP  BY c.code_2011
)
SELECT code_2011, km2 AS km2_polygone, k_cantons, p_pseudo, deps,
       round(km2 * (p_pseudo - 1), 1) AS km2_residuel,
       en_desaccord, sources, left(pseudo_ids, 40) AS pseudo_cantons
FROM   g WHERE p_pseudo > 1
ORDER  BY km2 * (p_pseudo - 1) DESC LIMIT 25;

-- ---------------------------------------------------------------------------
-- 5. Contrôle croisé : et chez Gay ?
--
-- Ses polygones sont annoncés parfaitement disjoints. Si c'est vrai, son
-- double comptage est nul aux deux niveaux — ce qui confirme au passage que
-- le phénomène est bien chez nous, et non un artefact de la comparaison.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Contrôle croisé : le double comptage chez Gay ==='
\echo '    Doit être nul. Sinon, le phénomène n''est pas ce qu''on croit.'
SELECT round((sum(ST_Area(geom)) / 1e6)::numeric, 0)                  AS km2_somme,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 0)             AS km2_union,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 1)
                                                                      AS double_comptage
FROM   ctrl_eux WHERE annee = :annee_ref;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    Hypothèse établie si : § 1 ligne 1 ≈ § 2 `double_canton_reel` ≈ 12 822,'
\echo '    § 1 ligne 2 ≈ § 2 `survit_au_repliement` ≈ 3 945, et § 3 montre que'
\echo '    l''essentiel de l''absorption tient aux groupes `mapping`.'
\echo '    Hypothèse fausse si § 1 et § 2 divergent : l''erreur serait alors'
\echo '    dans `km2_en_trop` de 12 (max(km2_polygone) par groupe), à revoir.'

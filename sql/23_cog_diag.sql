-- ============================================================================
-- histgis — 23_cog_diag.sql : ce que le COG 1999-2012 contient, et ce qu'il
--                             faudra créer pour l'accueillir
--
-- Lecture seule. Il mesure avant qu'on écrive, comme `20` l'a fait pour la
-- trame communale — et pour la même raison : `21` a demandé quatre passages
-- parce que des propriétés n'avaient pas été mesurées d'abord.
--
-- Quatre questions, dans l'ordre où elles engagent la suite :
--
--   1. Les millésimes se recoupent-ils ? Un canton qui disparaît puis revient,
--      une commune qui change de canton : c'est ce que le fichier historique
--      ne consigne pas avant 1995 et que le diff des instantanés révèle.
--   2. Combien d'unités `canton` faut-il créer, et sous quel identifiant ?
--   3. Combien d'atomes-fractions ? Une commune multicantonale ne peut pas
--      appartenir à deux cantons à la fois — `membership_non_chevauchant` —
--      donc il lui faut une fraction par canton, comme en 1870-1940.
--   4. Toutes les communes du COG ont-elles un atome dans `commune_moderne` ?
--
-- Prérequis : ./load_cog.sh (tables cog_*_src), 21_atomes_modernes.sql
-- (table commune_moderne).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.cog_commune_src') IS NULL THEN
        RAISE EXCEPTION 'cog_commune_src absente : lancer load_cog.sh.';
    END IF;
    IF to_regclass('histgis.commune_moderne') IS NULL THEN
        RAISE EXCEPTION 'commune_moderne absente : lancer 21_atomes_modernes.sql.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' COG 1999-2012 — inventaire avant écriture'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Le rattachement commune → canton, millésime par millésime
--
-- On retient les lignes qui portent une appartenance réelle : ACTUAL = 1 pour
-- une commune monocantonale, 6 pour une fraction. On écarte l'enregistrement
-- « canton non précisé » (CDC = 2), qui n'est qu'un pivot de nomenclature, et
-- l'outre-mer, hors périmètre de la trame GEOFLA.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cog_rat;
CREATE TABLE cog_rat AS
SELECT annee,
       dep || com                       AS code,
       dep || ct                        AS canton_cog,
       cdc = '1'                        AS fraction,
       nullif(trim(nccct), '')          AS nom_canton
FROM   cog_commune_src
WHERE  actual IN ('1', '6')
  AND  cdc <> '2'
  AND  ct IS NOT NULL AND trim(ct) <> ''
  AND  left(dep, 2) NOT IN ('97', '98')
  AND  dep NOT IN ('976');

CREATE INDEX cog_rat_idx     ON cog_rat (code, annee);
CREATE INDEX cog_rat_cant_idx ON cog_rat (canton_cog);
ANALYZE cog_rat;

-- La liste des cantons, précalculée une fois.
--
-- Sans elle, l'exemple de collisions du § 3 faisait une sous-requête corrélée
-- sur les 522 000 lignes de `cog_rat`, pour chacune de ces lignes. La requête
-- ne rendait pas la main. 3 886 lignes suffisent à dire la même chose.
DROP TABLE IF EXISTS cog_canton_liste;
CREATE TABLE cog_canton_liste AS
SELECT canton_cog,
       max(nom_canton)      AS nom,
       min(annee)           AS depuis,
       max(annee)           AS jusqu_a,
       count(DISTINCT annee) AS n_millesimes
FROM   cog_rat GROUP BY canton_cog;

ALTER TABLE cog_canton_liste ADD PRIMARY KEY (canton_cog);

\echo ''
\echo '=== 1. Volumétrie retenue (métropole) ==='
SELECT annee,
       count(*)                                   AS rattachements,
       count(DISTINCT code)                       AS communes,
       count(*) FILTER (WHERE fraction)           AS fractions,
       count(DISTINCT canton_cog)                 AS cantons
FROM   cog_rat GROUP BY annee ORDER BY annee;

-- ---------------------------------------------------------------------------
-- 1. Ce que le diff des millésimes révèle
--
-- Le fichier historique ne consigne aucun changement de canton avant 1995.
-- Quatorze instantanés annuels valent mieux : toute différence entre deux
-- millésimes consécutifs EST un changement, qu'il ait été consigné ou non.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Changements détectés par diff des millésimes ==='
\echo '    Une commune qui change de canton d''un 1er janvier à l''autre.'
\echo '    À rapprocher des 66 événements de modalité 43 du fichier'
\echo '    historique, tous antérieurs à 1999 : ce que le diff trouve ici,'
\echo '    aucune source ne le consigne.'
WITH paires AS (
    SELECT a.code, a.annee AS de, b.annee AS vers,
           a.canton_cog AS avant, b.canton_cog AS apres
    FROM   cog_rat a
    JOIN   cog_rat b ON b.code = a.code AND b.annee = a.annee + 1
                    AND NOT a.fraction AND NOT b.fraction
    WHERE  a.canton_cog <> b.canton_cog
)
SELECT vers AS au_1er_janvier, count(*) AS communes_changeant_de_canton
FROM   paires GROUP BY vers ORDER BY vers;

\echo ''
\echo '--- cantons apparus et disparus, par millésime ---'
WITH c AS (SELECT DISTINCT annee, canton_cog FROM cog_rat)
SELECT b.annee,
       count(*) FILTER (WHERE a.canton_cog IS NULL) AS apparus,
       (SELECT count(*) FROM c x WHERE x.annee = b.annee - 1
         AND NOT EXISTS (SELECT 1 FROM c y
                          WHERE y.annee = b.annee AND y.canton_cog = x.canton_cog))
                                                    AS disparus
FROM   c b
LEFT   JOIN c a ON a.annee = b.annee - 1 AND a.canton_cog = b.canton_cog
WHERE  b.annee > (SELECT min(annee) FROM cog_rat)
GROUP  BY b.annee ORDER BY b.annee;

-- ---------------------------------------------------------------------------
-- 2. Les unités à créer
--
-- Piège d'identifiant : `unit_id` d'un canton de 1870-1940 vaut 'DDNN', et un
-- canton du COG aussi. Les deux nomenclatures n'ont RIEN à voir — 59 ans les
-- séparent, et rien ne prouve la continuité d'un code à l'autre. Les fondre
-- serait affirmer une identité que le trou 1943-1999 interdit d'établir.
-- On les mettra donc dans un espace de noms distinct.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Unités canton à créer ==='
SELECT count(*)                                              AS cantons_distincts,
       count(*) FILTER
         (WHERE EXISTS (SELECT 1 FROM unit u
                         WHERE u.niveau = 'canton' AND u.unit_id = canton_cog))
                                                             AS collisions_avec_1870_1940
FROM   cog_canton_liste;

\echo ''
\echo '--- exemples de collisions d''identifiant (même code, deux époques) ---'
\echo '    Le même `unit_id` désignerait deux cantons étrangers l''un à'
\echo '    l''autre. Comparer les deux noms suffit à s''en convaincre.'
SELECT l.canton_cog, u.nom AS nom_1870_1940, l.nom AS nom_cog
FROM   cog_canton_liste l
JOIN   unit u ON u.niveau = 'canton' AND u.unit_id = l.canton_cog
ORDER  BY l.canton_cog LIMIT 12;

\echo ''
\echo '--- cantons du COG absents de tout millésime intermédiaire ---'
\echo '    `n_millesimes` < 14 : le canton n''a pas existé sur toute la'
\echo '    période. C''est ce que le membership devra dater.'
SELECT n_millesimes, count(*) AS cantons
FROM   cog_canton_liste GROUP BY n_millesimes ORDER BY n_millesimes;

-- ---------------------------------------------------------------------------
-- 3. Les atomes-fractions à créer
--
-- Une commune multicantonale ne peut pas appartenir à deux cantons au même
-- instant : la contrainte l'interdit, et c'est ce qui a fait échouer
-- l'éclatement rétroactif des arrondissements. Il lui faut donc une fraction
-- par canton, exactement comme TRF-GIS en fournit pour 1870-1940.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Atomes-fractions requis ==='
SELECT count(DISTINCT code)                        AS communes_multicantonales,
       count(DISTINCT (code, canton_cog))          AS fractions_a_creer,
       count(DISTINCT (code, canton_cog))
         - count(DISTINCT code)                    AS atomes_supplementaires
FROM   cog_rat WHERE fraction;

\echo ''
\echo '--- les 15 communes les plus découpées ---'
SELECT code,
       count(DISTINCT canton_cog) AS cantons,
       min(annee) AS des, max(annee) AS jusqu_a,
       left(string_agg(DISTINCT nom_canton, ' | '), 60) AS exemples
FROM   cog_rat WHERE fraction
GROUP  BY code ORDER BY 2 DESC, 1 LIMIT 15;

-- ---------------------------------------------------------------------------
-- 4. Le raccord aux atomes déjà posés
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Raccord à commune_moderne ==='
\echo '    Toute commune du COG doit avoir un atome, et être vivante à la date'
\echo '    du millésime. Un écart ici est une divergence entre notre'
\echo '    chronologie reconstituée et la nomenclature officielle.'
SELECT r.annee,
       count(DISTINCT r.code)                                       AS communes_cog,
       count(DISTINCT r.code) FILTER (WHERE m.atom_id IS NOT NULL)  AS avec_atome,
       count(DISTINCT r.code) FILTER (WHERE m.atom_id IS NULL)      AS sans_atome
FROM   (SELECT DISTINCT annee, code FROM cog_rat) r
LEFT   JOIN commune_moderne m
       ON m.code = r.code
      AND daterange(m.valid_from, m.valid_to, '[)') @> make_date(r.annee, 1, 1)
GROUP  BY r.annee ORDER BY r.annee;

\echo ''
\echo '--- communes du COG sans atome à cette date (20 premières) ---'
SELECT r.annee, r.code, max(r.nom_canton) AS canton
FROM   (SELECT DISTINCT annee, code, nom_canton FROM cog_rat) r
WHERE  NOT EXISTS (SELECT 1 FROM commune_moderne m
                    WHERE m.code = r.code
                      AND daterange(m.valid_from, m.valid_to, '[)') @> make_date(r.annee, 1, 1))
GROUP  BY r.annee, r.code ORDER BY r.annee, r.code LIMIT 20;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    § 5 `sans_atome` à zéro → la chronologie de `20` et la nomenclature'
\echo '        officielle concordent, on peut poser les rattachements.'
\echo '    § 2 non nul → des changements cantonaux existent entre 1999 et 2012'
\echo '        que le fichier historique ne consigne pas. Le diff fait foi.'
\echo '    § 3 `collisions` non nul → confirmer l''espace de noms distinct pour'
\echo '        les cantons du COG : même code, deux nomenclatures étrangères'
\echo '        l''une à l''autre, 59 ans d''écart et aucune preuve de continuité.'
\echo ''
\echo 'Tables : cog_commune_src, cog_canton_src, cog_rat, cog_canton_liste.'
\echo 'Rien n''a été écrit dans le modèle.'

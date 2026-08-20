-- ============================================================================
-- histgis — 24_canton_moderne.sql : les cantons de 1999 à 2012
--
-- Premier fichier qui pose des `membership` pour la période moderne. À lancer
-- en une seule transaction :  psql -d histgis -1 -f 24_canton_moderne.sql
--
-- Les décisions, prises sur pièces
-- -------------------------------
--
-- 1. UN SEUL ESPACE DE NOMS. Un canton garde le même `unit_id` de 1870 à 2012.
--    Ce n'est pas une commodité : `source_code/input/cantons/ct_codes.do` du
--    dépôt TRF-GIS s'intitule « ADJUST CANTONS CODES TO MATCH 1954 COG » et
--    aligne les codes de Gay sur le COG de 1954. La filiation 1954 → 1999 est
--    celle de l'Insee. La continuité de la NOMENCLATURE est donc documentée,
--    et 92,4 % des 2 943 codes partagés portent le même nom.
--
--    Ce qui est affirmé : l'identité du canton. Ce qui ne l'est PAS : sa
--    composition entre 1941 et 1998. `Moulins-Est` devenu `Moulins-Sud` garde
--    son code en ayant vraisemblablement changé de contours. Le `membership`
--    s'arrête donc en 1941 et reprend en 1999, avec RIEN entre les deux :
--    `snapshot(1970)` ne renverra pas un canton faux, il n'en renverra aucun.
--
-- 2. PARIS EST RÉSOLU PAR LA DONNÉE. Paris n'a pas de cantons au sens
--    électoral ; ses arrondissements en tiennent lieu dans les nomenclatures
--    de l'Insee. Et le fichier cantons le dit : `cheflieu` vaut 75101 pour le
--    canton 15, 75102 pour le 16, jusqu'à 75120 pour le 34. Chaque « canton »
--    parisien se rattache donc à l'atome de son arrondissement, sans fraction
--    ni supposition.
--
-- 3. MARSEILLE ET LYON SONT REPORTÉS. Leurs cantons ont `typct = 4` et
--    `cheflieu` renvoie la commune entière : 22 cantons pour 16
--    arrondissements, 13 pour 9. Les deux découpages se croisent, et seule une
--    couche cantonale géométrique (GEOFLA, absente du dépôt de reproduction)
--    peut trancher. Ils sont exclus ici et le resteront jusque-là — déclarés
--    inconnus plutôt que rattachés au jugé.
--
-- 4. LES FRACTIONS. Une commune multicantonale ne peut pas appartenir à deux
--    cantons au même instant : `membership_non_chevauchant` l'interdit. Il lui
--    faut donc un atome par canton, `<atome>#<canton>`, portant le polygone de
--    la commune et marqué `partagee`. C'est le mécanisme de TRF-GIS, et sa
--    limite : le territoire sera compté autant de fois qu'il y a de fractions.
--    Même phénomène que les 3 945 km² du § 6.1, même remède — ANR-COMMUNES.
--
-- La leçon de `21`, appliquée
-- ---------------------------
-- `21` a demandé quatre passages parce que des propriétés n'avaient pas été
-- mesurées avant d'écrire. Ici, la section 2 est un CONTRÔLE PRÉALABLE : trois
-- assertions qui lèvent une exception et annulent la transaction si elles
-- échouent. Rien n'est écrit tant qu'elles ne passent pas.
--
-- Prérequis : load_cog.sh (cog_rat), 21_atomes_modernes.sql (commune_moderne).
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set fin_serie '2013-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.cog_rat') IS NULL THEN
        RAISE EXCEPTION 'cog_rat absente : lancer load_cog.sh.';
    END IF;
    IF to_regclass('histgis.commune_moderne') IS NULL THEN
        RAISE EXCEPTION 'commune_moderne absente : lancer 21_atomes_modernes.sql.';
    END IF;
END $$;

-- Déclaration additive de la source posée ici. Voir l'explication en tête de
-- `15_creation_arriere.sql` : une liste exhaustive écrite dans chaque fichier
-- invalide les sources des autres au moindre rejeu.
CREATE TABLE IF NOT EXISTS atom_geom_source (
    source   text PRIMARY KEY,
    pose_par text NOT NULL,
    note     text
);

INSERT INTO atom_geom_source (source, pose_par, note)
SELECT DISTINCT ag.source, 'préexistant',
       'trouvée en base lors de la conversion du CHECK en table'
FROM   atom_geom ag
WHERE  ag.source IS NOT NULL
ON     CONFLICT (source) DO NOTHING;

INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('fraction_cog', '24_canton_moderne.sql',
     'fraction de commune coupée entre plusieurs cantons du COG')
ON CONFLICT (source) DO NOTHING;

ALTER TABLE atom_geom DROP CONSTRAINT IF EXISTS atom_geom_source_check;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                    WHERE conname = 'atom_geom_source_fk') THEN
        ALTER TABLE atom_geom
            ADD CONSTRAINT atom_geom_source_fk
            FOREIGN KEY (source) REFERENCES atom_geom_source (source);
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS canton_moderne_trace (
    quoi    text NOT NULL,          -- unit | unit_version | atom | membership
    cle     text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM canton_moderne_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM atom a
 WHERE EXISTS (SELECT 1 FROM canton_moderne_trace t
                WHERE t.quoi = 'atom' AND t.cle = a.atom_id);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM canton_moderne_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM canton_moderne_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE canton_moderne_trace;

\echo ''
\echo '============================================================'
\echo ' CANTONS 1999-2012'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Résolution : quel atome porte quel canton, quelle année ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cmc_rat;
CREATE TABLE cmc_rat AS
WITH base AS (
    SELECT r.annee, r.code, r.canton_cog, r.fraction, r.nom_canton,
           -- Paris : le « canton » EST un arrondissement, que le chef-lieu nomme
           CASE WHEN r.code = '75056'
                THEN (SELECT c.cheflieu FROM cog_canton_src c
                       WHERE c.annee = r.annee AND c.dep || c.canton = r.canton_cog
                       LIMIT 1)
                ELSE r.code
           END AS code_atome,
           r.code = '75056' AS paris
    FROM   cog_rat r
    WHERE  r.code NOT IN ('13055', '69123')      -- reportés, cf. en-tête § 3
)
SELECT b.annee, b.code, b.code_atome, b.canton_cog, b.fraction, b.paris,
       b.nom_canton,
       m.atom_id                                            AS atome_commune,
       CASE WHEN b.fraction AND NOT b.paris
            THEN m.atom_id || '#' || b.canton_cog
            ELSE m.atom_id
       END                                                  AS atome_final
FROM   base b
LEFT   JOIN commune_moderne m ON m.code = b.code_atome
       AND daterange(m.valid_from, m.valid_to, '[)') @> make_date(b.annee, 1, 1);

CREATE INDEX cmc_rat_idx ON cmc_rat (atome_final, annee);

\echo ''
\echo '=== 1. Résolution ==='
SELECT count(*)                                       AS rattachements,
       count(*) FILTER (WHERE paris)                  AS dont_paris,
       count(*) FILTER (WHERE fraction AND NOT paris) AS dont_fractions,
       count(*) FILTER (WHERE atome_final IS NULL)    AS sans_atome,
       count(DISTINCT canton_cog)                     AS cantons
FROM   cmc_rat;

\echo ''
\echo '--- rattachements sans atome (doit être vide) ---'
SELECT annee, code, code_atome, canton_cog, nom_canton
FROM   cmc_rat WHERE atome_final IS NULL ORDER BY annee, code LIMIT 20;

-- ---------------------------------------------------------------------------
-- 2. CONTRÔLE PRÉALABLE — rien n'est écrit tant qu'il ne passe pas
--
-- `21` a demandé quatre passages faute d'avoir mesuré avant d'écrire. Ici, une
-- assertion fausse annule la transaction entière.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM cmc_rat WHERE atome_final IS NULL;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % rattachements sans atome. Voir la liste ci-dessus.', n;
    END IF;

    -- un atome ne peut pas relever de deux cantons la même année
    SELECT count(*) INTO n FROM (
        SELECT atome_final, annee FROM cmc_rat
        GROUP BY 1, 2 HAVING count(DISTINCT canton_cog) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % couples (atome, année) portant deux cantons. La contrainte EXCLUDE refuserait.', n;
    END IF;

    -- un identifiant de canton ne doit pas déjà servir à une circonscription
    SELECT count(*) INTO n
      FROM (SELECT DISTINCT canton_cog FROM cmc_rat) c
      JOIN unit u ON u.unit_id = c.canton_cog AND u.niveau <> 'canton';
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 3 : % identifiants déjà pris par une unité d''un autre niveau.', n;
    END IF;

    RAISE NOTICE 'Contrôle préalable : les trois assertions passent.';
END $$;

-- ---------------------------------------------------------------------------
-- 3. Les unités canton
--
-- Celles qui existent déjà — 2 943 héritées de 1870-1940 — sont RÉUTILISÉES :
-- c'est la décision d'espace de noms unique. Seules les nouvelles sont créées,
-- et tracées pour pouvoir être retirées.
-- ---------------------------------------------------------------------------
WITH nouveau AS (
    SELECT DISTINCT c.canton_cog, left(c.canton_cog, 2) AS dep
    FROM   cmc_rat c
    WHERE  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = c.canton_cog)
),
ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT n.canton_cog, 'canton', n.dep::char(2), n.canton_cog, NULL, NULL,
           (SELECT max(x.nom_canton) FROM cmc_rat x
             WHERE x.canton_cog = n.canton_cog AND x.annee = 2012),
           false
    FROM   nouveau n
    RETURNING unit_id
)
INSERT INTO canton_moderne_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

-- les noms, datés : un intervalle par suite d'années portant le même nom
DROP TABLE IF EXISTS cmc_nom;
CREATE TABLE cmc_nom AS
WITH n AS (
    SELECT DISTINCT canton_cog, annee, nom_canton FROM cmc_rat WHERE nom_canton IS NOT NULL
),
iles AS (
    SELECT canton_cog, nom_canton, annee,
           annee - row_number() OVER (PARTITION BY canton_cog, nom_canton ORDER BY annee) AS ilot
    FROM   n
)
SELECT canton_cog, nom_canton,
       make_date(min(annee), 1, 1)     AS valid_from,
       make_date(max(annee) + 1, 1, 1) AS valid_to
FROM   iles GROUP BY canton_cog, nom_canton, ilot;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT canton_cog, nom_canton, valid_from,
           CASE WHEN valid_to > :'fin_serie'::date THEN :'fin_serie'::date ELSE valid_to END
    FROM   cmc_nom
    RETURNING unit_version_id
)
INSERT INTO canton_moderne_trace (quoi, cle)
SELECT 'unit_version', unit_version_id::text FROM ins;

\echo ''
\echo '=== 2. Unités ==='
SELECT (SELECT count(*) FROM canton_moderne_trace WHERE quoi = 'unit')         AS unites_creees,
       (SELECT count(DISTINCT canton_cog) FROM cmc_rat)                        AS cantons_total,
       (SELECT count(*) FROM canton_moderne_trace WHERE quoi = 'unit_version') AS versions_de_nom;

-- ---------------------------------------------------------------------------
-- 4. Les atomes-fractions
--
-- Le polygone est celui de la commune : une fraction cantonale n'a pas de
-- géométrie propre, et n'en aura pas tant que la trame sera celle de 2011.
-- `partagee` le dit des deux côtés.
-- ---------------------------------------------------------------------------
-- Certaines fractions EXISTENT DÉJÀ, et c'est la conséquence logique de
-- l'espace de noms unique. Un atome-fraction se nomme « la part de la commune
-- X dans le canton Y » : si le canton garde son code de 1870 à 2012, la
-- fraction garde le sien. TRF-GIS avait créé `10142#1614` pour 1870-1940, et
-- c'est le même atome — la même notion territoriale, sans qu'aucune géométrie
-- soit affirmée puisque les fractions n'ont pas de polygone propre.
--
-- On les réutilise donc, et on ne trace que les nouvelles : les anciennes ne
-- doivent pas disparaître au retrait de ce script.
DROP TABLE IF EXISTS cmc_frac;
CREATE TABLE cmc_frac AS
SELECT DISTINCT c.atome_final, c.atome_commune,
       EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = c.atome_final) AS deja_la
FROM   cmc_rat c WHERE c.fraction AND NOT c.paris;

WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT f.atome_final, a.cassini, true, NULL::smallint, a.insee_geofla
    FROM   cmc_frac f JOIN atom a ON a.atom_id = f.atome_commune
    WHERE  NOT f.deja_la
    RETURNING atom_id
)
INSERT INTO canton_moderne_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT DISTINCT f.atome_final, ag.geom, 'fraction_cog', true
FROM   cmc_frac f
JOIN   atom_geom ag ON ag.atom_id = f.atome_commune
WHERE  NOT EXISTS (SELECT 1 FROM atom_geom g WHERE g.atom_id = f.atome_final);

UPDATE atom_geom ag SET partagee = true
FROM   (SELECT DISTINCT atome_commune FROM cmc_rat WHERE fraction AND NOT paris) f
WHERE  ag.atom_id = f.atome_commune AND NOT ag.partagee;

\echo ''
\echo '=== 3. Atomes-fractions ==='
\echo '    `heritees` : des fractions que TRF-GIS avait déjà créées pour'
\echo '    1870-1940, et que le même code de canton fait retrouver. Leur'
\echo '    membership ancien et le nouveau ne se chevauchent pas — 58 ans les'
\echo '    séparent — donc l''atome sert deux fois sans conflit.'
SELECT count(*)                                  AS fractions_totales,
       count(*) FILTER (WHERE deja_la)           AS heritees_de_1870_1940,
       count(*) FILTER (WHERE NOT deja_la)       AS creees_ici
FROM   cmc_frac;

-- ---------------------------------------------------------------------------
-- 5. Les rattachements
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cmc_periode;
CREATE TABLE cmc_periode AS
WITH iles AS (
    SELECT atome_final, canton_cog, annee,
           annee - row_number() OVER (PARTITION BY atome_final, canton_cog ORDER BY annee) AS ilot
    FROM   (SELECT DISTINCT atome_final, canton_cog, annee FROM cmc_rat) d
)
SELECT atome_final, canton_cog,
       make_date(min(annee), 1, 1)     AS valid_from,
       least(make_date(max(annee) + 1, 1, 1), :'fin_serie'::date) AS valid_to,
       count(*) AS n_annees
FROM   iles GROUP BY atome_final, canton_cog, ilot;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atome_final, canton_cog, 'canton', valid_from, valid_to
    FROM   cmc_periode
    RETURNING membership_id
)
INSERT INTO canton_moderne_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE atom; ANALYZE atom_geom; ANALYZE membership; ANALYZE unit;

\echo ''
\echo '=== 4. Rattachements posés ==='
SELECT count(*) AS intervalles, count(DISTINCT atome_final) AS atomes,
       count(DISTINCT canton_cog) AS cantons,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   cmc_periode;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recettes ==='
\echo '--- chevauchements de membership (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- le trou 1941-1998 est-il bien vide ? (doit valoir 0) ---'
\echo '    Aucun rattachement cantonal ne doit exister entre la fin de la'
\echo '    série TRF-GIS et le premier millésime du COG. C''est la lacune'
\echo '    assumée, et elle doit se voir.'
SELECT count(*) AS rattachements_dans_le_trou
FROM   membership
WHERE  niveau = 'canton'
  AND  periode && daterange('1941-01-01', '1999-01-01', '[)');

\echo ''
\echo '--- effectifs cantonaux à quelques dates ---'
\echo '    1870-1940 doit être inchangé. 1970 doit être VIDE. 1999-2012 doit'
\echo '    donner ~3 850 cantons — un peu moins que les 3 876 du COG, Marseille'
\echo '    et Lyon étant reportés.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1940-06-01'), ('1970-06-01'),
               ('1999-06-01'), ('2005-06-01'), ('2012-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'canton' ORDER BY 1;

\echo ''
\echo '--- cantons à cheval sur les deux époques ---'
\echo '    Un même unit_id portant des rattachements avant 1941 ET après 1999 :'
\echo '    c''est la décision d''espace de noms unique, rendue visible.'
SELECT count(*) AS cantons_des_deux_epoques
FROM   (SELECT m.unit_id FROM membership m WHERE m.niveau = 'canton'
        GROUP BY m.unit_id
        HAVING min(m.valid_from) < '1941-01-01'::date
           AND max(m.valid_to)   > '1999-01-01'::date) x;

\echo ''
\echo '--- géométries ---'
SELECT * FROM check_geom();

\echo ''
\echo 'Pour tout défaire :'
\echo '  DELETE FROM histgis.membership m USING histgis.canton_moderne_trace t'
\echo '   WHERE t.quoi = ''membership'' AND t.cle = m.membership_id::text;'
\echo '  DELETE FROM histgis.atom a USING histgis.canton_moderne_trace t'
\echo '   WHERE t.quoi = ''atom'' AND t.cle = a.atom_id;'
\echo '  (puis unit_version, unit, et TRUNCATE canton_moderne_trace)'
\echo ''
\echo 'Reste à faire : Marseille (13055) et Lyon (69123), qui demandent une'
\echo 'couche cantonale géométrique — GEOFLA, IGN ou data.gouv.fr.'

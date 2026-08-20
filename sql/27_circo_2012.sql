-- ============================================================================
-- histgis — 27_circo_2012.sql : les circonscriptions législatives de 2012
--
--   cd circo && python3 extrait_circo.py
--   cd ../sql && psql -d histgis -1 -v circo=../circo/circo_2012.csv \
--       -f 27_circo_2012.sql
--
-- Source : tableau de correspondance du ministère de l'Intérieur, Licence
-- Ouverte / Etalab. Lecture et pièges : note_circonscriptions.md.
--
-- Le découpage
-- ------------
-- Ordonnance du 29 juillet 2009, ratifiée par la loi du 23 février 2010, en
-- vigueur pour le renouvellement de juin 2012 (et identique en 2017).
-- 539 circonscriptions métropolitaines — le compte officiel, retrouvé sans
-- correction par la somme des maxima départementaux.
--
-- La période retenue court du **23 février 2010**, promulgation de la loi de
-- ratification, à la fin de la série. Le choix mérite d'être dit : aucune
-- élection législative n'a eu lieu entre 2007 et 2012, la borne aurait donc pu
-- être placée n'importe où dans cet intervalle. La promulgation est la date à
-- laquelle la carte devient le droit.
--
-- Le raccord
-- ----------
-- Chaque ligne source est un couple (canton, entité). L'atome se retrouve par
-- son `insee_geofla`, et se départage par son canton quand la commune est
-- multicantonale — c'est-à-dire quand elle a des atomes-fractions. Pour
-- Marseille et Lyon, dont les arrondissements sont rattachés à un
-- pseudo-canton (§ 6.2 quinquies de METHODE.md), le code INSEE suffit : il n'y
-- a qu'un atome par arrondissement.
--
-- Ce qui ne sera pas posé
-- ----------------------
-- 35 couples (canton, entité) relèvent de DEUX circonscriptions à la fois. La
-- trame ne descend pas plus bas, et choisir serait un rattachement au jugé. Ils
-- sont écartés, comptés et nommés — comme les 3 945 km² du § 6.1.
--
-- Prérequis : 24, 25. Rejouable : retire son propre passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set debut '2010-02-23'
\set fin   '2013-01-01'
\set date_canton '2012-06-01'

-- ---------------------------------------------------------------------------
-- 0. Trace et retrait
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS circo_moderne_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_moderne_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_moderne_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_moderne_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE circo_moderne_trace;

-- ---------------------------------------------------------------------------
-- 1. La source
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS circo_src;
CREATE TABLE circo_src (
    canton text, insee text, niveau text, nom text, circo text
);
\set cmd '\\copy circo_src FROM ' :'circo' ' WITH (FORMAT csv, HEADER true)'
:cmd

CREATE INDEX circo_src_idx ON circo_src (insee, canton);

\echo ''
\echo '============================================================'
\echo ' CIRCONSCRIPTIONS LÉGISLATIVES 2012'
\echo '============================================================'

\echo ''
\echo '=== 1. Source ==='
SELECT count(*) AS lignes, count(DISTINCT circo) AS circonscriptions,
       count(DISTINCT insee) AS entites, count(DISTINCT canton) AS cantons,
       count(*) FILTER (WHERE niveau = 'AR') AS lignes_arrondissement
FROM   circo_src;

-- ---------------------------------------------------------------------------
-- 2. Le raccord aux atomes
--
-- `DISTINCT ON` avec un tri qui préfère la correspondance de canton : pour une
-- commune multicantonale, la fraction du bon canton ; sinon l'atome unique.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS circo_rat;
CREATE TABLE circo_rat AS
-- Le canton ne sert qu'à DÉPARTAGER, il ne conditionne pas le raccord.
--
-- Défaut trouvé le 20 août 2026 par Bihorel. La jointure était INTERNE :
-- l'atome devait avoir un canton au 1er juin 2012 pour être retenu. Or Bihorel
-- a fusionné dans Bois-Guillaume le 1er janvier 2012 — sa ligne cantonale
-- 1999-2012 s'arrête là, et celle qui couvre 2012 est posée par `41`, QUI
-- S'EXÉCUTE APRÈS CE FICHIER. La commune disparaissait donc du raccord en
-- silence, comptée parmi les « lignes source sans atome ».
--
-- Le canton n'a jamais servi qu'à choisir entre plusieurs atomes portant le
-- même code INSEE. Une commune qui n'en a qu'un n'a pas besoin d'être
-- départagée. `LEFT JOIN` + `DESC NULLS LAST` : la préférence demeure, la
-- condition disparaît.
SELECT DISTINCT ON (s.canton, s.insee, s.circo)
       s.canton, s.insee, s.niveau, s.circo,
       a.atom_id,
       m.unit_id                       AS canton_pose,
       coalesce(m.unit_id = s.canton, false) AS canton_concorde
FROM   circo_src s
JOIN   atom a       ON a.insee_geofla = s.insee
LEFT   JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> :'date_canton'::date
ORDER  BY s.canton, s.insee, s.circo, (m.unit_id = s.canton) DESC NULLS LAST, a.atom_id;

CREATE INDEX circo_rat_idx ON circo_rat (atom_id);

\echo ''
\echo '=== 2. Raccord ==='
SELECT count(*)                                        AS resolus,
       count(*) FILTER (WHERE canton_concorde)         AS par_canton,
       count(*) FILTER (WHERE NOT canton_concorde)     AS par_code_seul,
       (SELECT count(*) FROM circo_src)                AS lignes_source
FROM   circo_rat;

\echo ''
\echo '--- lignes source sans atome ---'
\echo '    Attendu : quelques communes du millésime 2012 absentes de notre'
\echo '    chronologie. Un nombre élevé signalerait un défaut de raccord.'
SELECT s.insee, s.nom, s.canton, s.circo
FROM   circo_src s
WHERE  NOT EXISTS (SELECT 1 FROM circo_rat r
                    WHERE r.canton = s.canton AND r.insee = s.insee AND r.circo = s.circo)
ORDER  BY s.insee LIMIT 20;

\echo ''
\echo '--- raccords par code seul (Marseille, Lyon : pseudo-canton) ---'
SELECT canton_pose, count(*) AS lignes, count(DISTINCT insee) AS entites
FROM   circo_rat WHERE NOT canton_concorde
GROUP  BY canton_pose ORDER BY 2 DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- 3. CONTRÔLE PRÉALABLE
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n
      FROM circo_src s
     WHERE NOT EXISTS (SELECT 1 FROM circo_rat r
                        WHERE r.canton = s.canton AND r.insee = s.insee AND r.circo = s.circo);
    IF n > 100 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % lignes source sans atome — défaut de raccord, pas un résidu.', n;
    END IF;
    RAISE NOTICE 'Lignes source sans atome : % (tolérées, déclarées).', n;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT canton, insee, circo FROM circo_src) x
      JOIN unit u ON u.unit_id = x.circo || '@2009' AND u.niveau <> 'circo';
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % identifiants déjà pris par une unité d''un autre niveau.', n;
    END IF;

    SELECT count(*) INTO n
      FROM membership WHERE niveau = 'circo'
       AND periode && daterange('2010-02-23', '2013-01-01', '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 3 : % rattachements circo existent déjà sur la période.', n;
    END IF;

    RAISE NOTICE 'Contrôle préalable : les trois assertions passent.';
END $$;

-- ---------------------------------------------------------------------------
-- 4. Les atomes indivisibles entre deux circonscriptions
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS circo_partage;
CREATE TABLE circo_partage AS
SELECT atom_id, count(DISTINCT circo) AS n_circos,
       string_agg(DISTINCT circo, ' / ' ORDER BY circo) AS circos
FROM   circo_rat GROUP BY atom_id HAVING count(DISTINCT circo) > 1;

\echo ''
\echo '=== 3. Atomes relevant de deux circonscriptions ==='
\echo '    Écartés : la trame ne descend pas plus bas, et choisir serait un'
\echo '    rattachement au jugé. Déclarés, comme les 3 945 km² du § 6.1.'
SELECT p.atom_id, a.insee_geofla, p.circos,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
FROM   circo_partage p
JOIN   atom a      ON a.atom_id = p.atom_id
LEFT   JOIN atom_geom g ON g.atom_id = p.atom_id
ORDER  BY 4 DESC NULLS LAST;

-- ---------------------------------------------------------------------------
-- 5. Les unités
--
-- `unit_id` = « 01-05@2009 ». La convention @AAAA est celle des
-- circonscriptions de 1870-1940 (L…@AAAA, U…@AAAA) : même idée, segment de
-- découpage daté, sans risque de collision.
-- Le schéma exige `regime` et `segment_depuis` pour une circonscription.
-- ---------------------------------------------------------------------------
WITH nouveau AS (
    SELECT DISTINCT circo, left(circo, 2) AS dep FROM circo_src
),
ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT n.circo || '@2009', 'circo', n.dep::char(2), n.circo,
           'uninominal', 2009,
           n.dep || 'e circonscription n° ' || right(n.circo, 2), false
    FROM   nouveau n
    WHERE  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = n.circo || '@2009')
    RETURNING unit_id
)
INSERT INTO circo_moderne_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

-- ---------------------------------------------------------------------------
-- 6. Les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT r.atom_id, r.circo || '@2009', 'circo',
           :'debut'::date, :'fin'::date
    FROM   circo_rat r
    WHERE  NOT EXISTS (SELECT 1 FROM circo_partage p WHERE p.atom_id = r.atom_id)
    RETURNING membership_id
)
INSERT INTO circo_moderne_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership; ANALYZE unit;

\echo ''
\echo '=== 4. Ce qui a été posé ==='
SELECT quoi, count(*) FROM circo_moderne_trace GROUP BY quoi ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 7. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recettes ==='
\echo '--- chevauchements (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- effectifs ==='
\echo '    1870-1940 inchangé. 1970 et 2000 doivent être VIDES au niveau circo'
\echo '    — le trou, et l''absence du découpage de 1986. 2012 doit donner 539.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1914-06-01'), ('1940-06-01'),
               ('1970-06-01'), ('2000-06-01'), ('2012-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'circo' ORDER BY 1;

\echo ''
\echo '--- couverture : atomes sans circonscription en 2012 ---'
\echo '    Les 35 indivisibles, plus les éventuels non raccordés.'
SELECT count(*) AS atomes_sans_circo
FROM   membership m
WHERE  m.niveau = 'canton' AND m.periode @> '2012-06-01'::date
  AND  NOT EXISTS (SELECT 1 FROM membership c
                    WHERE c.atom_id = m.atom_id AND c.niveau = 'circo'
                      AND c.periode @> '2012-06-01'::date);

\echo ''
\echo '--- nombre de circonscriptions par département (5 plus grands) ---'
SELECT dep, count(*) AS circos FROM unit
WHERE  niveau = 'circo' AND segment_depuis = 2009
GROUP  BY dep ORDER BY 2 DESC LIMIT 5;

\echo ''
\echo 'Pour tout défaire : DELETE via circo_moderne_trace (membership, puis'
\echo 'unit_version, puis unit), puis TRUNCATE circo_moderne_trace.'
\echo ''
\echo 'Reste : le découpage de 1986 (Paris inutilisable, 145 valeurs'
\echo 'textuelles) et celui de 1958, suspendu au trou cantonal.'

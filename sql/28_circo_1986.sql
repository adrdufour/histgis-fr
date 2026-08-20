-- ============================================================================
-- histgis — 28_circo_1986.sql : les circonscriptions législatives de 1986
--
--   psql -d histgis -1 -v circo=../circo/circo_1986.csv -f 28_circo_1986.sql
--
-- Loi du 24 novembre 1986. Attention au calendrier : l'élection de mars 1986
-- s'est tenue à la PROPORTIONNELLE DÉPARTEMENTALE, sans circonscriptions. La
-- carte dite « de 1986 » sert donc aux scrutins de 1988, 1993, 1997, 2002 et
-- 2007, et cède la place au découpage de 2009 le 23 février 2010.
--
-- Période retenue : du **24 novembre 1986**, promulgation de la loi, au
-- **22 février 2010** inclus. Même convention qu'en `27` — la carte devient le
-- droit à sa promulgation, indépendamment de la date du premier scrutin.
--
-- Deux amputations, et elles sont déclarées
-- -----------------------------------------
--   * PARIS EST ABSENT. Toutes ses lignes portent « 42 » comme numéro de
--     circonscription, alors que Paris en comptait 21. La preuve par le total
--     est nette : la somme des maxima départementaux donne 576 sièges
--     métropolitains au lieu de 555, et 576 − 42 + 21 = 555 exactement.
--     L'anomalie est entièrement localisée à Paris ; le reste du fichier est
--     juste. 35 lignes écartées.
--   * 135 LIGNES À VALEUR TEXTUELLE — « 1 et 2 », « 3  4 et 5 ». Un canton à
--     cheval sur plusieurs circonscriptions, noté ainsi plutôt que dupliqué.
--     La trame ne descend pas plus bas : écartées, comme les 31 atomes
--     indivisibles de 2012.
--
-- Ce qui reste : **534 circonscriptions pour 534 sièges**, soit exactement les
-- 555 de la carte de 1986 moins les 21 parisiens. Et zéro couple
-- (canton, entité) partagé — les valeurs textuelles étaient le seul mécanisme
-- de partage, et elles sont parties avec.
--
-- Une remarque sur le raccord. Le fichier exprime les circonscriptions de 1986
-- EN CANTONS DE 2012 : c'est une table de correspondance de 2012. Résoudre les
-- atomes par la structure cantonale de 2012 n'ajoute donc aucune hypothèse —
-- c'est ce que fait la source.
--
-- Prérequis : 24, 25, 27. Rejouable : retire son propre passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set debut '1986-11-24'
\set fin   '2010-02-23'
\set date_canton '2012-06-01'

CREATE TABLE IF NOT EXISTS circo1986_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo1986_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo1986_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE circo1986_trace;

DROP TABLE IF EXISTS circo86_src;
CREATE TABLE circo86_src (canton text, insee text, niveau text, nom text, circo text);
\set cmd '\\copy circo86_src FROM ' :'circo' ' WITH (FORMAT csv, HEADER true)'
:cmd
CREATE INDEX circo86_src_idx ON circo86_src (insee, canton);

\echo ''
\echo '============================================================'
\echo ' CIRCONSCRIPTIONS LÉGISLATIVES 1986 (scrutins 1988-2007)'
\echo '============================================================'

\echo ''
\echo '=== 1. Source ==='
SELECT count(*) AS lignes, count(DISTINCT circo) AS circonscriptions,
       count(DISTINCT insee) AS entites, count(DISTINCT canton) AS cantons,
       count(*) FILTER (WHERE left(circo, 2) = '75') AS lignes_paris
FROM   circo86_src;

-- ---------------------------------------------------------------------------
-- 2. Raccord aux atomes — même résolution qu'en 27
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS circo86_rat;
CREATE TABLE circo86_rat AS
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
       s.canton, s.insee, s.circo, a.atom_id,
       coalesce(m.unit_id = s.canton, false) AS canton_concorde
FROM   circo86_src s
JOIN   atom a       ON a.insee_geofla = s.insee
LEFT   JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> :'date_canton'::date
ORDER  BY s.canton, s.insee, s.circo, (m.unit_id = s.canton) DESC NULLS LAST, a.atom_id;

CREATE INDEX circo86_rat_idx ON circo86_rat (atom_id);

\echo ''
\echo '=== 2. Raccord ==='
SELECT count(*) AS resolus,
       count(*) FILTER (WHERE canton_concorde)     AS par_canton,
       count(*) FILTER (WHERE NOT canton_concorde) AS par_code_seul,
       (SELECT count(*) FROM circo86_src)          AS lignes_source
FROM   circo86_rat;

\echo ''
\echo '--- lignes source sans atome ---'
SELECT s.insee, s.nom, s.canton, s.circo FROM circo86_src s
WHERE  NOT EXISTS (SELECT 1 FROM circo86_rat r
                    WHERE r.canton = s.canton AND r.insee = s.insee AND r.circo = s.circo)
ORDER  BY s.insee LIMIT 20;

-- ---------------------------------------------------------------------------
-- 3. CONTRÔLE PRÉALABLE
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM circo86_src s
     WHERE NOT EXISTS (SELECT 1 FROM circo86_rat r
                        WHERE r.canton = s.canton AND r.insee = s.insee AND r.circo = s.circo);
    IF n > 100 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % lignes sans atome — défaut de raccord.', n;
    END IF;
    RAISE NOTICE 'Lignes source sans atome : % (tolérées).', n;

    SELECT count(*) INTO n FROM membership
     WHERE niveau = 'circo' AND periode && daterange('1986-11-24', '2010-02-23', '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % rattachements circo existent déjà sur la période.', n;
    END IF;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT circo FROM circo86_src) x
      JOIN unit u ON u.unit_id = x.circo || '@1986' AND u.niveau <> 'circo';
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 3 : % identifiants pris par un autre niveau.', n;
    END IF;

    RAISE NOTICE 'Contrôle préalable : les trois assertions passent.';
END $$;

-- ---------------------------------------------------------------------------
-- 4. Atomes relevant de deux circonscriptions (attendu : aucun)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS circo86_partage;
CREATE TABLE circo86_partage AS
SELECT atom_id, count(DISTINCT circo) AS n_circos,
       string_agg(DISTINCT circo, ' / ' ORDER BY circo) AS circos
FROM   circo86_rat GROUP BY atom_id HAVING count(DISTINCT circo) > 1;

\echo ''
\echo '=== 3. Atomes relevant de deux circonscriptions ==='
\echo '    Attendu vide : les valeurs textuelles étaient le seul mécanisme de'
\echo '    partage en 1986, et elles ont été écartées à l''extraction.'
SELECT p.atom_id, a.insee_geofla, p.circos
FROM   circo86_partage p JOIN atom a ON a.atom_id = p.atom_id ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. Unités et rattachements
-- ---------------------------------------------------------------------------
WITH nouveau AS (SELECT DISTINCT circo, left(circo, 2) AS dep FROM circo86_src),
ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT n.circo || '@1986', 'circo', n.dep::char(2), n.circo,
           'uninominal', 1986,
           n.dep || 'e circonscription n° ' || right(n.circo, 2), false
    FROM   nouveau n
    WHERE  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = n.circo || '@1986')
    RETURNING unit_id
)
INSERT INTO circo1986_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT r.atom_id, r.circo || '@1986', 'circo', :'debut'::date, :'fin'::date
    FROM   circo86_rat r
    WHERE  NOT EXISTS (SELECT 1 FROM circo86_partage p WHERE p.atom_id = r.atom_id)
    RETURNING membership_id
)
INSERT INTO circo1986_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership; ANALYZE unit;

\echo ''
\echo '=== 4. Ce qui a été posé ==='
SELECT quoi, count(*) FROM circo1986_trace GROUP BY quoi ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recettes ==='
\echo '--- chevauchements (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- effectifs par date ---'
\echo '    1870-1940 inchangé. 1970 VIDE (trou). 1988 à 2007 : 534.'
\echo '    2012 : 524, inchangé par ce fichier.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1940-06-01'), ('1970-06-01'),
               ('1988-06-12'), ('1997-06-01'), ('2007-06-10'),
               ('2011-06-01'), ('2012-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'circo' ORDER BY 1;

\echo ''
\echo '--- Paris est-il bien absent en 1986 ? (doit valoir 0) ---'
SELECT count(*) AS unites_paris_1986
FROM   unit WHERE niveau = 'circo' AND segment_depuis = 1986 AND dep = '75';

\echo ''
\echo '--- la bascule du 23 février 2010 ---'
\echo '    Un atome ne doit jamais relever des deux découpages à la fois.'
SELECT count(*) AS atomes_aux_deux_decoupages
FROM   membership a JOIN membership b ON b.atom_id = a.atom_id
WHERE  a.niveau = 'circo' AND b.niveau = 'circo'
  AND  a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo 'Pour tout défaire : DELETE via circo1986_trace, puis TRUNCATE.'
\echo ''
\echo 'Limites à porter en note de méthode : Paris absent du découpage de 1986'
\echo '(21 circonscriptions), et 135 lignes écartées pour valeur textuelle.'

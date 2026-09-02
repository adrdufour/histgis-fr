-- ============================================================================
-- histgis — 69_pont_seine_et_oise.sql : le pont entre deux numérotations
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour le \copy
--   psql -d histgis -f sql/69_pont_seine_et_oise.sql
--
-- LECTURE SEULE. Produit `cog1954/pont_departements_disparus.csv`.
--
-- LE PROBLÈME, DÉCOUVERT LE 28 AOÛT 2026 EN VOULANT POSER 549 CODES
-- ==================================================================
-- Deux départements de 1954 n'existent plus : la **Seine-et-Oise**, éclatée en
-- 1968 entre 78, 91, 92, 93, 94 et 95, et la **Seine**, partagée entre 75, 92,
-- 93 et 94. Leurs communes n'ont pas seulement changé de département : elles ont
-- changé de CODE.
--
-- La base le modélise correctement — et c'est ce qui a failli me piéger :
--
--     codes 78xxx vivants au 10 mai 1954 ......... 691
--     codes 75xxx vivants au 10 mai 1954 ......... 100
--     codes 91, 92, 93, 94, 95 vivants en 1954 ..... 0
--
-- L'appariement par le nom, lui, ne peut travailler que sur le référentiel
-- MODERNE : `build/noms_geofla.csv` est la trame de 2011, et sur les 691 codes
-- de 1954 **seuls 454 portent un nom** dans `noms_1954.csv` — les 237 autres ne
-- sont jamais nommés par les mouvements INSEE.
--
-- Il apparie donc vers `95008`, `91225`, `92072`… que `cm_commune` ne connaît
-- pas vivants en 1954. Posés tels quels, ces 549 codes auraient donné
-- `commune_vivante = false` et **zéro rattachement**, sans message d'erreur.
--
-- *Deux ensembles de même effectif — 691 d'un côté, 691 de l'autre — décrits par
-- deux numérotations différentes. J'ai pris la coïncidence des comptes pour une
-- identité des clés.*
--
-- LE PONT : L'ATOME, PAS LE CODE
-- ===============================
-- C'est la raison d'être du modèle. **L'atome est la maille du territoire**, et
-- il ne change pas quand l'INSEE renumérote : `cm_atome` atteint le même atome
-- par le code de 1954 et par le code moderne. Le pont est mécanique, il ne
-- suppose rien, et il se mesure — cf. § 4.
--
-- CE QUE CE FICHIER N'ÉCRIT PAS
-- ==============================
-- Rien dans `atom`, rien dans `membership`, rien dans `c54_*`. Il produit une
-- table de correspondance que `cog1954/seine_et_oise.py` consommera pour viser
-- le bon code. La décision d'appariement reste au script, la traduction reste
-- ici : chacun fait ce qu'il sait faire.
--
-- Prérequis : `20_commune_moderne.sql` (cm_commune, cm_atome).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set date_1954 '1954-05-10'
\set date_now  '2012-01-01'

\echo ''
\echo '============================================================'
\echo ' Le pont entre la numérotation de 1954 et la moderne'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.cm_commune') IS NULL
       OR to_regclass('histgis.cm_atome') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20_commune_moderne.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les deux départements disparus, tels que 1954 les connaît
--
-- On les repère par le PRÉFIXE du code, pas par une liste de communes : c'est
-- la seule information dont on dispose avant d'avoir construit le pont.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p78_1954;
CREATE TABLE p78_1954 AS
SELECT DISTINCT c.code                              AS code_1954,
       left(c.code, 2)                              AS dep_1954
FROM   cm_commune c
WHERE  daterange(c.valid_from, c.valid_to, '[)') @> :'date_1954'::date
  AND  left(c.code, 2) IN ('78', '75');

CREATE INDEX p78_1954_idx ON p78_1954 (code_1954);

\echo ''
\echo '-- 1. communes vivantes au 10 mai 1954 dans les deux départements'
SELECT dep_1954,
       CASE dep_1954 WHEN '78' THEN 'Seine-et-Oise'
                     WHEN '75' THEN 'Seine' END     AS nom,
       count(*)                                     AS communes
FROM   p78_1954 GROUP BY dep_1954 ORDER BY dep_1954;

-- ---------------------------------------------------------------------------
-- 2. L'atome de chacune, puis le code moderne de cet atome
--
-- `cm_atome` est une UNION ALL : un code peut porter plusieurs atomes. On
-- compte au lieu de joindre naïvement — la faute évitée dans `58` et `66`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p78_pont;
CREATE TABLE p78_pont AS
WITH atome_1954 AS (
    SELECT v.code_1954, v.dep_1954, a.atom_id
    FROM   p78_1954 v
    JOIN   cm_atome a ON a.code = v.code_1954
),
-- Le code « moderne » est celui que porte l'atome à une date où la
-- numérotation actuelle est en vigueur. 2012 est la borne haute de la base.
moderne AS (
    SELECT a.atom_id, a.code AS code_moderne
    FROM   cm_atome a
    JOIN   cm_commune c ON c.code = a.code
    WHERE  daterange(c.valid_from, c.valid_to, '[)') @> :'date_now'::date
)
SELECT x.code_1954,
       x.dep_1954,
       x.atom_id,
       m.code_moderne
FROM   atome_1954 x
LEFT   JOIN moderne m ON m.atom_id = x.atom_id;

CREATE INDEX p78_pont_1954_idx    ON p78_pont (code_1954);
CREATE INDEX p78_pont_moderne_idx ON p78_pont (code_moderne);

\echo ''
\echo '-- 2. le pont, par département'
SELECT dep_1954,
       count(DISTINCT code_1954)                                AS codes_1954,
       count(DISTINCT code_1954) FILTER (WHERE code_moderne IS NOT NULL)
                                                                AS avec_un_code_moderne,
       count(DISTINCT code_moderne)                             AS codes_modernes,
       count(DISTINCT atom_id)                                  AS atomes
FROM   p78_pont GROUP BY dep_1954 ORDER BY dep_1954;

-- ---------------------------------------------------------------------------
-- 3. Les cas où le pont n'est pas une bijection
--
-- Ils ne sont pas des défauts : une fusion postérieure fait converger deux
-- codes de 1954 vers un seul code moderne, et c'est exact. Mais ils rendent la
-- traduction ambiguë DANS L'AUTRE SENS — du moderne vers 1954 — qui est
-- justement le sens dont l'appariement a besoin. On les compte pour savoir
-- combien de lignes seront concernées.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. ambiguïtés du sens moderne -> 1954 (fusions postérieures)'
SELECT count(*)                                     AS codes_modernes_ambigus,
       sum(n)                                       AS codes_1954_concernes
FROM  (SELECT code_moderne, count(DISTINCT code_1954) AS n
       FROM   p78_pont WHERE code_moderne IS NOT NULL
       GROUP  BY code_moderne HAVING count(DISTINCT code_1954) > 1) x;

\echo ''
\echo '   dix exemples — plusieurs communes de 1954 sous un code d''aujourd''hui :'
SELECT code_moderne, count(DISTINCT code_1954) AS n,
       string_agg(DISTINCT code_1954, ',' ORDER BY code_1954) AS codes_1954
FROM   p78_pont WHERE code_moderne IS NOT NULL
GROUP  BY code_moderne HAVING count(DISTINCT code_1954) > 1
ORDER  BY n DESC, code_moderne LIMIT 10;

\echo ''
\echo '   et les communes de 1954 sans code moderne — disparues sans successeur'
\echo '   identifiable, ou absentes de cm_atome :'
SELECT dep_1954, count(*) AS sans_code_moderne
FROM   p78_pont WHERE code_moderne IS NULL
GROUP  BY dep_1954 ORDER BY dep_1954;

-- ---------------------------------------------------------------------------
-- 4. LE CONTRÔLE : le pont dit-il la même chose que la géographie ?
--
-- Un pont mécanique se vérifie. Le département moderne d'une commune de
-- Seine-et-Oise doit être l'un des SIX successeurs, et celui d'une commune de
-- la Seine l'un des QUATRE. Un code moderne hors de ces listes signalerait que
-- l'atome fait passer la commune par un successeur qu'elle n'a jamais eu.
--
-- Ce contrôle ne doit RIEN au pont lui-même : les successeurs sont un fait
-- historique, pas une sortie de la base.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. contrôle : le département moderne est-il un successeur légitime ?'
SELECT p.dep_1954,
       left(p.code_moderne, 2)                      AS dep_moderne,
       count(DISTINCT p.code_1954)                  AS communes,
       CASE
         WHEN p.dep_1954 = '78'
              AND left(p.code_moderne, 2) IN ('78','91','92','93','94','95')
              THEN 'successeur légitime'
         WHEN p.dep_1954 = '75'
              AND left(p.code_moderne, 2) IN ('75','92','93','94')
              THEN 'successeur légitime'
         ELSE '*** INATTENDU ***'
       END                                          AS verdict
FROM   p78_pont p WHERE p.code_moderne IS NOT NULL
GROUP  BY 1, 2, 4 ORDER BY 1, 3 DESC;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM p78_pont p
     WHERE p.code_moderne IS NOT NULL
       AND NOT ((p.dep_1954 = '78' AND left(p.code_moderne, 2)
                     IN ('78','91','92','93','94','95'))
             OR (p.dep_1954 = '75' AND left(p.code_moderne, 2)
                     IN ('75','92','93','94')));
    IF n > 0 THEN
        RAISE WARNING 'CONTRÔLE : % communes atterrissent hors des successeurs '
                      'connus — le pont est à examiner avant usage.', n;
    ELSE
        RAISE NOTICE 'Contrôle : tous les codes modernes tombent dans un '
                     'département successeur légitime.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 5. Export
-- ---------------------------------------------------------------------------
\copy (SELECT code_1954, dep_1954, atom_id, coalesce(code_moderne, '') AS code_moderne FROM p78_pont ORDER BY code_1954, code_moderne) TO 'cog1954/pont_departements_disparus.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo 'cog1954/pont_departements_disparus.csv écrit.'
\echo ''
\echo 'Enchaîner :'
\echo '   python3 cog1954/seine_et_oise.py               # à blanc'
\echo '   python3 cog1954/seine_et_oise.py --appliquer'
\echo '   psql -d histgis -f  sql/66_cog1954_stage.sql'
\echo '   psql -d histgis -1 -f sql/67_cantons_1949_1951.sql'
\echo '   psql -d histgis -1 -f sql/68_cog1954_membership.sql'
\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo '============================================================'

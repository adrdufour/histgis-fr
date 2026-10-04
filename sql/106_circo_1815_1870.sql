-- ============================================================================
-- histgis — 106_circo_1815_1870.sql : les circonscriptions de 1815 à 1870,
--                                     un département à la fois
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/64_composition_1815_stage.sql            -- recharger
--   psql -d histgis -v dep=21 -f sql/106_circo_1815_1870.sql         -- à blanc
--   psql -d histgis -1 -v appliquer=1 -v dep=21 -f sql/106_circo_1815_1870.sql
--
--   # les 43 départements lus le 4 octobre 2026 (21 à 63, la Meurthe en 99,
--   # sans la Moselle), d'un coup ; la boucle s'arrête au premier refus :
--   for d in 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 \
--            42 43 44 45 46 47 48 49 50 51 52 53 55 56 58 59 60 61 62 63 99; do
--     psql -d histgis -P pager=off -1 -v appliquer=1 -v dep=$d \
--          -f sql/106_circo_1815_1870.sql > build/p106_$d.log || break
--   done
--
-- Prérequis : `82` (atom_geom_anr, anr_commune) et `64` (c15_composition),
-- RECHARGÉE : `circo/composition_1815_1870.csv` est passé de 14 à 57
-- départements le 4 octobre 2026. `64` n'est pas dans
-- `rejouer_apres_rebuild.sh`.
--
-- CE QUE CE FICHIER EST
-- =====================
-- `105` généralisé. `105` a été écrit pour l'Yonne, après un diagnostic
-- (`diag_yonne_1815`) qui montrait que la carte communale de 1815 y est celle
-- de 1870. Celui-ci pose, pour un département `dep`, les CIRCONSCRIPTIONS de
-- `c15_composition` sur les atomes de 1870, par leur canton de 1870.
--
-- CE QU'IL AFFIRME, ET CE QU'IL N'AFFIRME PAS
-- ===========================================
-- Il affirme ce que dit l'atlas : tel canton était dans telle circonscription.
-- Il en déduit qu'un atome y était aussi, par le canton qu'il a en 1870. C'est
-- exact tant que la commune n'a pas changé de canton entre-temps. Pour l'Yonne
-- on l'a mesuré ; ailleurs ON NE L'A PAS MESURÉ. Avant de poser un
-- département, jouer `diag_yonne_1815.sql -v dep=XX` est la prudence.
--
-- Les cas connus où l'hypothèse est fausse, à l'échelle du canton :
--   * cantons créés entre 1815 et 1870, que l'atlas ne dessine pas encore :
--     le Gard (Bessèges, La Grand-Combe, Alès-Est/-Ouest avant 1863),
--     Saint-Étienne (deux cantons avant 1857, quatre après), Saint-Paul-
--     Trois-Châteaux (Drôme, avant 1852), Étables (Côtes-du-Nord, avant 1831),
--     Calais-Sud-Est (Pas-de-Calais). Ils sont rangés dans la circonscription
--     du canton dont ils sont issus — c'est une approximation, notée dans
--     `circo/regles_1815_21_63.py` ;
--   * cantons PARTAGÉS entre deux circonscriptions (Bordeaux 1820-1848,
--     Orléans-Sud 1857-1870, Thouarcé 1820-1831, Prayssas et Lavardac
--     1820-1831) : posés entiers d'un seul côté. À reprendre à l'atome.
-- Voir `circo/verif_1815_21_63.md`.
--
-- LES CANTONS NE SONT PAS POSÉS PAR DÉFAUT
-- ========================================
-- `105` posait aussi les CANTONS avant 1870, parce que Gaudillère garantit
-- qu'aucun canton de l'Yonne n'a bougé. Ce n'est pas vrai partout (ci-dessus).
-- Comme `91` pour la Seine, ce fichier ne pose donc que des circonscriptions.
-- `-v cantons=1` pose aussi les cantons, pour un département dont on sait les
-- cantons stables.
--
-- CE QUI EST POSÉ
-- ===============
--   * CIRCO, chaque division de `c15_composition` pour `dep` :
--         collèges 1815-1820  dep-<nom>@1815      (nommés par l'atlas)
--         numérotées          dep-NN@<millésime>
--   * 1848-1852 : `L<dep>01@1848`, scrutin de liste départemental — si le
--     département a une division antérieure à 1848 (pas la Haute-Savoie).
--     `-v sans1848=1` pour ne pas la poser.
--   * collèges de département (« pas de découpage ») : la Lozère 1820-1831 et
--     1852-1870, les Vosges 1820-1824 et 1828-1831 : `<dep>-D@<millésime>`,
--     une unité, provisoire. Table `t106_college` ci-dessous ; `-v
--     sans_college=1` pour ne pas les poser.
--   * RIEN pour la Mayenne 1852-1870 : la carte n'a pas été photographiée.
--
-- REFUSÉS
-- =======
--   75  la Seine : `87` à `91`.
--   89  l'Yonne : `105`.
--   57  la Moselle : la base n'a pas sa trame de 1870 (le code 57 porte déjà
--       le Bezirk Lothringen au 1er janvier 1870, et l'arrondissement de Briey
--       n'a aucun atome avant 1871). Les règles sont écrites, elles attendent.
--
-- TROUS VOULUS — « absents » de `remonte_1815.py`
-- ==============================================
-- Montbéliard et Audincourt ne sont pas au Doubs en 1815 (rattachés en 1816) :
-- ils n'ont pas de circonscription du Doubs en 1815-1820. Table `t106_absent`.
--
-- NOMS ABÎMÉS
-- ===========
-- Quatre noms de `unit` (Saint-Étienne-Nord-/Sud-Ouest, Orléans-Est/-Ouest)
-- portent deux U+FFFD à la place d'une lettre accentuée. La jointure se fait
-- sur le nom RÉPARÉ, comme `remonte_1815.py` : « É » en tête de mot, « é »
-- ailleurs. La source reste à corriger.
--
-- RÉGIME — la règle de `54` et `105` : avant 1848, `uninominal` faute de case
-- (`provisoire = true`) ; 1848-1852 `liste` ; 1852-1870 `uninominal`.
--
-- Réversible : `circo_1815_trace`, par département. Le fichier retire la
-- trace de `dep` avant de reposer, et se rejoue sans risque.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?dep}
\else
    \echo 'Il faut -v dep=XX.'
    \quit
\endif
\set d70 '1870-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL
       OR to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql (et charger anr_commune).';
    END IF;
    IF to_regclass('histgis.creation_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : creation_trace absente (sql/15_creation_arriere.sql).';
    END IF;
    IF to_regclass('histgis.c15_composition') IS NULL THEN
        RAISE EXCEPTION E'PRÉREQUIS : c15_composition absente.\n'
            '  psql -d histgis -f sql/64_composition_1815_stage.sql';
    END IF;
END $$;

SELECT :'dep' IN ('75', '89', '57') AS refuse \gset
\if :refuse
    \echo ''
    \echo 'REFUSÉ : 75 (voir 87-91), 89 (voir 105), 57 (pas de trame 1870 — voir l''en-tête).'
    \quit
\endif

SELECT count(*) AS n_c15 FROM c15_composition WHERE dep = :'dep' \gset
SELECT :n_c15 = 0 AS vide \gset
\if :vide
    \echo ''
    \echo 'Aucune ligne pour ce département dans c15_composition. Recharger :'
    \echo '  psql -d histgis -f sql/64_composition_1815_stage.sql'
    \quit
\endif

CREATE TABLE IF NOT EXISTS circo_1815_trace (
    dep  text NOT NULL, quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- Les trous voulus, et les collèges de département.
DROP TABLE IF EXISTS t106_absent;
CREATE TEMP TABLE t106_absent (dep text, depuis int, canton text);
INSERT INTO t106_absent VALUES
    ('25', 1815, 'Montbéliard'), ('25', 1815, 'Audincourt');

DROP TABLE IF EXISTS t106_college;
CREATE TEMP TABLE t106_college (dep text, depuis int, jusqu int);
\if :{?sans_college}
\else
INSERT INTO t106_college VALUES
    ('48', 1820, 1831), ('48', 1852, 1870),
    ('88', 1820, 1824), ('88', 1828, 1831);
\endif

-- La réparation des noms, une seule fois.
CREATE OR REPLACE FUNCTION pg_temp.repare(nom text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT replace(regexp_replace(nom, '(^|[- ])' || chr(65533) || chr(65533),
                                  '\1É', 'g'),
                   chr(65533) || chr(65533), 'é')
$f$;

-- ---------------------------------------------------------------------------
-- 1. Les atomes du département à 1870, leur canton, leur naissance
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t106_atome;
CREATE TEMP TABLE t106_atome AS
WITH a70 AS (
    SELECT m.atom_id, a.cassini, a.fraction, m.unit_id AS canton_id,
           pg_temp.repare(u.nom) AS canton
      FROM membership m
      JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
      JOIN atom a ON a.atom_id = m.atom_id
     WHERE m.niveau = 'canton' AND m.periode @> :'d70'::date
       AND u.dep = :'dep'
), ne_anr AS (
    SELECT atom_id, min(lower(periode)) AS ne_le
      FROM atom_geom_anr GROUP BY atom_id
), ne_mere AS (
    SELECT an.id_com::text AS cassini,
           make_date(min((nullif(an.startdt::text, ''))::numeric::int), 1, 1) AS ne_le
      FROM anr_commune an
     WHERE an.id_com::text IN (SELECT cassini FROM a70 WHERE fraction)
     GROUP BY 1
), ne_n AS (
    -- Les atomes « N » de `15` (creation_arriere) : un territoire détaché de
    -- sa mère APRÈS la série, qui lui appartenait avant. Ni polygone ANR ni
    -- commune ANR à son nom : il naît avec sa (ses) mère(s), lue(s) dans
    -- `creation_trace`. Mère non-fraction : son polygone ANR ; mère fraction :
    -- sa commune dans `anr_commune`.
    SELECT t.atom_id,
           min(coalesce(na.ne_le,
                        (SELECT make_date(min((nullif(an.startdt::text, ''))
                                              ::numeric::int), 1, 1)
                           FROM anr_commune an
                          WHERE an.id_com::text = am.cassini))) AS ne_le
      FROM creation_trace t
     CROSS JOIN LATERAL unnest(string_to_array(t.meres, ';')) AS m(id)
      JOIN atom am ON am.atom_id = m.id
      LEFT JOIN ne_anr na ON na.atom_id = m.id
     WHERE t.atom_id IN (SELECT atom_id FROM a70)
     GROUP BY t.atom_id
)
SELECT a70.*,
       CASE WHEN a70.atom_id LIKE 'N%' THEN nn.ne_le
            WHEN a70.fraction          THEN nm.ne_le
            ELSE na.ne_le END AS ne_le
  FROM a70
  LEFT JOIN ne_anr  na ON na.atom_id = a70.atom_id
  LEFT JOIN ne_mere nm ON nm.cassini = a70.cassini
  LEFT JOIN ne_n    nn ON nn.atom_id = a70.atom_id;

\echo ''
\echo '=== 1. Les atomes du département à 1870, et quand ils naissent ==='
SELECT count(*)                                              AS atomes,
       count(DISTINCT canton)                                AS cantons,
       count(*) FILTER (WHERE fraction)                      AS fractions,
       count(*) FILTER (WHERE ne_le <= DATE '1815-01-01')    AS vivants_en_1815,
       count(*) FILTER (WHERE ne_le >  DATE '1815-01-01'
                          AND ne_le <  :'d70'::date)         AS nes_1815_1870,
       count(*) FILTER (WHERE ne_le >= :'d70'::date)         AS nes_en_1870_ou_apres,
       count(*) FILTER (WHERE ne_le IS NULL)                 AS sans_naissance
  FROM t106_atome;

SELECT atom_id, cassini, canton, ne_le
  FROM t106_atome
 WHERE ne_le > DATE '1815-01-01' OR ne_le IS NULL
 ORDER BY ne_le NULLS FIRST, canton;
-- « sans_naissance » doit être 0 : la pose refuse sinon.

-- ---------------------------------------------------------------------------
-- 2. Les divisions et leurs unités
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t106_div;
CREATE TEMP TABLE t106_div AS
SELECT DISTINCT
       c.depuis::int AS depuis, c.jusqu::int AS jusqu, c.circonscription,
       c.canton,
       make_date(c.depuis, 1, 1) AS du,
       make_date(c.jusqu,  1, 1) AS au,
       CASE WHEN c.circonscription ~ '^[0-9]+$'
            THEN :'dep' || '-' || lpad(c.circonscription, 2, '0')
            ELSE :'dep' || '-' || c.circonscription END
         || '@' || c.depuis                                  AS unit_id,
       CASE WHEN c.circonscription ~ '^[0-9]+$'
            THEN c.departement || ' ' || c.circonscription
                 || CASE WHEN c.circonscription = '1' THEN 're' ELSE 'e' END
                 || ' circonscription'
            ELSE c.departement || ' — collège '
                 || CASE WHEN c.circonscription ~* '^[aeiouyéèêâîôûh]'
                         THEN 'd''' ELSE 'de ' END
                 || c.circonscription END                    AS nom,
       (c.depuis < 1848)                                     AS provisoire,
       'uninominal'::text                                    AS regime
  FROM c15_composition c
 WHERE c.dep = :'dep';

SELECT min(departement) AS nom_dep FROM c15_composition WHERE dep = :'dep' \gset
SELECT EXISTS (SELECT 1 FROM t106_div WHERE depuis < 1848) AS avant_1848 \gset

\if :{?sans1848}
\else
\if :avant_1848
INSERT INTO t106_div
SELECT DISTINCT 1848, 1852, 'département', canton,
       DATE '1848-01-01', DATE '1852-01-01',
       'L' || :'dep' || '01@1848',
       :'nom_dep' || ' — scrutin de liste départemental', false, 'liste'
  FROM t106_atome;
\endif
\endif

-- Les collèges de département : une unité, tout le département.
INSERT INTO t106_div
SELECT DISTINCT k.depuis, k.jusqu, 'département', a.canton,
       make_date(k.depuis, 1, 1), make_date(k.jusqu, 1, 1),
       :'dep' || '-D@' || k.depuis,
       :'nom_dep' || ' — collège de département', true, 'uninominal'
  FROM t106_college k CROSS JOIN t106_atome a
 WHERE k.dep = :'dep';

\echo ''
\echo '=== 2. Les divisions ==='
SELECT depuis, jusqu, count(DISTINCT unit_id) AS circos,
       count(*) AS cantons,
       left(string_agg(DISTINCT unit_id, ', '), 100) AS unites
  FROM t106_div GROUP BY 1, 2 ORDER BY 1;

\echo ''
\echo '=== 2 bis. Garde-fou : tout canton de 1870 trouve-t-il sa circo à chaque division ? ==='
DROP TABLE IF EXISTS t106_trou;
CREATE TEMP TABLE t106_trou AS
SELECT d.depuis, k.canton,
       EXISTS (SELECT 1 FROM t106_absent x
                WHERE x.dep = :'dep' AND x.depuis = d.depuis
                  AND x.canton = k.canton) AS voulu
  FROM (SELECT DISTINCT depuis FROM t106_div) d
 CROSS JOIN (SELECT DISTINCT canton FROM t106_atome) k
 WHERE NOT EXISTS (SELECT 1 FROM t106_div x
                    WHERE x.depuis = d.depuis AND x.canton = k.canton);
SELECT * FROM t106_trou ORDER BY voulu, depuis, canton;
-- Attendu : aucune ligne, ou seulement des trous « voulu = t » (Doubs 1815).
-- Un trou non voulu est presque toujours un NOM : le canton de l'atlas ne
-- s'écrit pas comme celui de `unit`. Voir aussi la recette 2 ter.

\echo ''
\echo '=== 2 ter. Cantons de c15_composition sans atome à 1870 ==='
SELECT DISTINCT d.depuis, d.canton
  FROM t106_div d
 WHERE d.circonscription <> 'département'
   AND NOT EXISTS (SELECT 1 FROM t106_atome a WHERE a.canton = d.canton)
 ORDER BY 1, 2;
-- Attendu : aucune ligne. Une ligne ici et une en 2 bis = un nom à accorder.

-- ---------------------------------------------------------------------------
-- 3. Ce qui va être posé
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t106_pose;
CREATE TEMP TABLE t106_pose AS
SELECT 'circo'::text AS niveau, d.depuis || '-' || d.jusqu AS division,
       a.atom_id, d.unit_id,
       greatest(d.du, a.ne_le) AS valid_from, d.au AS valid_to, a.ne_le
  FROM t106_atome a
  JOIN t106_div d ON d.canton = a.canton
 WHERE a.ne_le < d.au;

\if :{?cantons}
-- Les cantons, sur option : de la première division où le canton figure, ou
-- de la naissance de l'atome, jusqu'en 1870.
INSERT INTO t106_pose
SELECT 'canton', 'cantons avant 1870', a.atom_id, a.canton_id,
       greatest(f.du, a.ne_le), :'d70'::date, a.ne_le
  FROM t106_atome a
  JOIN (SELECT canton, min(du) AS du FROM t106_div GROUP BY canton) f
    ON f.canton = a.canton
 WHERE a.ne_le < :'d70'::date;
\endif

\echo ''
\echo '=== 3. Ce que chaque division recevra ==='
SELECT niveau, division,
       count(DISTINCT unit_id)                                   AS unites,
       count(*)                                                  AS rattachements,
       count(*) FILTER (WHERE valid_from > (SELECT min(p2.valid_from)
                                              FROM t106_pose p2
                                             WHERE p2.division = p.division)) AS entrees_en_cours
  FROM t106_pose p
 GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 4. Garde-fou : ces périodes sont-elles libres pour ces atomes ? ==='
SELECT p.niveau, p.division, count(*) AS rattachements_deja_presents
  FROM t106_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
 WHERE NOT EXISTS (SELECT 1 FROM circo_1815_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle = m.membership_id::text)
 GROUP BY 1, 2 ORDER BY 1, 2;
-- Attendu : aucune ligne.

\if :{?appliquer}

-- Retirer la trace de CE département avant de juger — la leçon de `55`.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_1815_trace t
                WHERE t.dep = :'dep' AND t.quoi = 'membership'
                  AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_1815_trace t
                WHERE t.dep = :'dep' AND t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_1815_trace t
                WHERE t.dep = :'dep' AND t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_1815_trace WHERE dep = :'dep';

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t106_atome WHERE ne_le IS NULL;
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) sans naissance ANR. Voir la recette 1.', n;
    END IF;

    SELECT count(*) INTO n FROM t106_trou WHERE NOT voulu;
    IF n > 0 THEN
        RAISE EXCEPTION '% (division, canton) sans circonscription. Voir la '
            'recette 2 bis.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t106_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) existent déjà. Ce fichier COMBLE, '
            'il ne remplace pas. Voir la recette 4.', n;
    END IF;

    SELECT count(*) INTO n FROM t106_pose WHERE valid_from >= valid_to;
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) de durée nulle ou négative.', n;
    END IF;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT unit_id FROM t106_div) d
      JOIN unit u ON u.unit_id = d.unit_id;
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) de ce fichier existent déjà en base, hors '
            'de sa trace.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT DISTINCT d.unit_id, 'circo', :'dep',
           split_part(d.unit_id, '@', 1), d.regime, d.depuis, d.nom,
           d.provisoire
      FROM t106_div d
    RETURNING unit_id
)
INSERT INTO circo_1815_trace (dep, quoi, cle)
SELECT :'dep', 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT d.unit_id, d.nom, d.du, d.au FROM t106_div d;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM t106_pose
    RETURNING membership_id
)
INSERT INTO circo_1815_trace (dep, quoi, cle)
SELECT :'dep', 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM circo_1815_trace WHERE dep = :'dep'
 GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 6. Le département, date par date ==='
SELECT v.d AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'canton') AS atomes_canton,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'circo')  AS atomes_circo,
       count(DISTINCT m.unit_id) FILTER (WHERE m.niveau = 'circo')  AS circos
  FROM (VALUES ('1817-06-01'::date), ('1822-06-01'), ('1826-06-01'),
               ('1840-06-01'), ('1850-06-01'), ('1855-06-01'), ('1860-06-01'),
               ('1865-06-01'), ('1869-06-01')) v(d)
  JOIN membership m ON m.periode @> v.d
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau AND u.dep = :'dep'
 GROUP BY v.d ORDER BY v.d;
-- Attendu : à chaque date, atomes_circo = les atomes nés à cette date
-- (recette 1), et le nombre de circonscriptions de la recette 2.

\echo ''
\echo '=== 7. Aucun atome dans deux unités à la même date, France entière ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode FROM membership
         GROUP BY 1, 2, 3 HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY 1;
-- Attendu : aucune ligne (la contrainte EXCLUDE l'interdit déjà).

\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 -v dep=' :dep
\endif

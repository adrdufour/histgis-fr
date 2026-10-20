-- ============================================================================
-- histgis — 113_circo_1958.sql : les circonscriptions de 1958 à 1986,
--                                d'après les cartes de Gaudillère
--
--   cd ~/Téléchargements/projet_carte
--   python3 circo/composition_1958.py                        -- refaire les CSV
--   psql -d histgis -f sql/113_circo_1958.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/113_circo_1958.sql
--   psql -d histgis -1 -v defaire=1 -f sql/113_circo_1958.sql    -- tout retirer
--
-- CE QUE CE FICHIER EST
-- =====================
-- La base n'avait, entre 1958 et 1986, que les circonscriptions de la Seine.
-- `circo/regles_1958_1986.py` transcrit les cartes « 1958-1986 » de l'atlas
-- (photos du 13 octobre 2026) ; `circo/composition_1958.py` rapproche chaque
-- canton de l'atlas d'une unité de la base et dit quels départements sont
-- POSABLES (`circo/composition_1958_etat.csv`). Celui-ci pose ceux-là, et
-- seulement ceux-là.
--
-- CE QU'IL AFFIRME, ET CE QU'IL N'AFFIRME PAS
-- ===========================================
-- L'atlas dit : tel canton était dans telle circonscription. Le découpage de
-- 1958 est défini sur les cantons de 1958 et n'a pas suivi les remaniements
-- cantonaux de 1973, 1982 et 1985 : un atome garde donc, de 1958 à 1986, la
-- circonscription du canton qu'il avait À LA DATE DE RÉFÉRENCE (1er décembre
-- 1958).
--   * REPLI : un atome sans canton à cette date, mais dont le PREMIER canton
--     connu dans la fenêtre est un canton de 1958, prend la circonscription
--     de ce canton. C'est une hypothèse (il a pu changer de canton entre-
--     temps) ; ces rattachements sont comptés à part (recette 2) et
--     `-v sans_repli=1` ne les pose pas.
--   * La transcription est une LECTURE DE CARTE sur photo, avec une trentaine
--     de « DOUTE » notés dans `regles_1958_1986.py`. Le tableau annexé à
--     l'ordonnance n° 58-945 du 13 octobre 1958 n'a pas été confronté.
--   * Les cantons de ville que la base n'a pas en 1958 (Brest-1 et -3,
--     Toulon-1 à -3, Reims-2…) ne reçoivent rien : colonne `atlas_sans_unite`
--     de l'état.
--
-- NON POSÉS — voir `composition_1958_etat.csv`, colonne `raison`
-- ==========================================================
--   * cantons divisés entre deux circonscriptions (13, 33, 37, 38, 62, 69,
--     76, 78, 90) : il faut descendre à l'atome ;
--   * trame cantonale de 1958 absente de la base (61, 71, 72, 73, 74, 77) ;
--   * lecture qui ne fait pas une partition (06, 44, 59, 68, 2A, 2B) ;
--   * 39 et 70 : non photographiés. 75 : déjà en base.
--
-- BORNES — celles de la Seine déjà en base : [1958-01-01, 1986-11-24).
-- La Corse s'arrête au 1er janvier 1978 (deux départements ensuite).
-- UNITÉS — `<dep>-NN@1958`, régime `uninominal`, non provisoires.
--
-- Réversible : `circo_1958_trace`. Le fichier retire sa trace avant de
-- reposer, et se rejoue sans risque.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set fin '1986-11-24'

CREATE TABLE IF NOT EXISTS circo_1958_trace (
    dep  text NOT NULL, quoi text NOT NULL, cle text NOT NULL,
    repli boolean NOT NULL DEFAULT false,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DROP TABLE IF EXISTS t113_comp;
CREATE TEMP TABLE t113_comp (
    dep text, departement text, depuis int, jusqu int, reference date,
    circonscription text, canton_atlas text, canton_id text, canton_base text,
    note text);
\copy t113_comp FROM 'circo/composition_1958_1986.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS t113_etat;
CREATE TEMP TABLE t113_etat (
    dep text, departement text, depuis int, jusqu int, circos int,
    cantons_base int, posable text, raison text, atlas_sans_unite text);
\copy t113_etat FROM 'circo/composition_1958_etat.csv' WITH (FORMAT csv, HEADER true)

-- la division : canton de la base → unité de circonscription
DROP TABLE IF EXISTS t113_div;
CREATE TEMP TABLE t113_div AS
SELECT DISTINCT c.dep, c.departement, c.reference, c.canton_id,
       make_date(c.depuis, 1, 1)                                    AS du,
       CASE WHEN c.jusqu = 1986 THEN :'fin'::date
            ELSE make_date(c.jusqu, 1, 1) END                       AS au,
       c.dep || '-' || lpad(c.circonscription, 2, '0') || '@' || c.depuis AS unit_id,
       c.departement || ' ' || c.circonscription
           || CASE WHEN c.circonscription = '1' THEN 're' ELSE 'e' END
           || ' circonscription'                                    AS nom,
       c.depuis
  FROM t113_comp c
  JOIN t113_etat e ON e.dep = c.dep AND e.depuis = c.depuis AND e.posable = 'oui'
 WHERE c.canton_id <> ''
\if :{?dep}
   AND c.dep = :'dep'
\endif
;

\echo ''
\echo '=== 1. Ce qui est posable ==='
SELECT count(DISTINCT dep) AS departements, count(DISTINCT unit_id) AS circos,
       count(*) AS cantons FROM t113_div;

-- garde-fou : l'unité citée existe, est un canton, et porte bien ce nom
DROP TABLE IF EXISTS t113_ko;
CREATE TEMP TABLE t113_ko AS
SELECT c.dep, c.canton_id, c.canton_base, u.nom AS nom_en_base
  FROM t113_comp c
  LEFT JOIN unit u ON u.unit_id = c.canton_id AND u.niveau = 'canton'
 WHERE c.canton_id <> ''
   AND (u.unit_id IS NULL
        OR replace(replace(u.nom, '-' || chr(65533) || chr(65533), '-É'),
                   chr(65533) || chr(65533), 'é') <> c.canton_base);
\echo ''
\echo '=== 1 bis. Garde-fou : unités du CSV introuvables ou renommées (attendu : zéro) ==='
SELECT * FROM t113_ko;

-- l'atome et son canton : à la date de référence, sinon le premier connu
DROP TABLE IF EXISTS t113_pose;
CREATE TEMP TABLE t113_pose AS
WITH fen AS (                       -- la vie cantonale de l'atome dans la fenêtre
    SELECT m.atom_id, m.unit_id, m.valid_from, m.valid_to, d.dep, d.du, d.au,
           d.reference, d.unit_id AS circo, m.periode @> d.reference AS a_la_ref
      FROM t113_div d
      JOIN membership m ON m.niveau = 'canton' AND m.unit_id = d.canton_id
                       AND m.periode && daterange(d.du, d.au, '[)')
), vie AS (                         -- quand l'atome a un canton, quel qu'il soit
    SELECT m.atom_id, min(m.valid_from) AS ne, max(m.valid_to) AS mort
      FROM membership m
     WHERE m.niveau = 'canton'
       AND m.atom_id IN (SELECT atom_id FROM fen)
       AND m.periode && daterange('1958-01-01', :'fin'::date, '[)')
     GROUP BY 1
), premier AS (                     -- premier canton connu dans la fenêtre
    SELECT DISTINCT ON (m.atom_id) m.atom_id, m.unit_id
      FROM membership m
     WHERE m.niveau = 'canton'
       AND m.atom_id IN (SELECT atom_id FROM fen)
       AND m.periode && daterange('1958-01-01', :'fin'::date, '[)')
     ORDER BY m.atom_id, m.valid_from
), choix AS (
    SELECT DISTINCT f.atom_id, f.dep, f.circo, f.du, f.au, false AS repli
      FROM fen f WHERE f.a_la_ref
    UNION
    SELECT DISTINCT f.atom_id, f.dep, f.circo, f.du, f.au, true
      FROM fen f
      JOIN premier p ON p.atom_id = f.atom_id AND p.unit_id = f.unit_id
     WHERE NOT EXISTS (SELECT 1 FROM membership m
                        WHERE m.atom_id = f.atom_id AND m.niveau = 'canton'
                          AND m.periode @> f.reference)
)
SELECT c.atom_id, c.dep, c.circo AS unit_id, c.repli,
       greatest(c.du, v.ne)   AS valid_from,
       least(c.au, v.mort)    AS valid_to
  FROM choix c JOIN vie v USING (atom_id)
 WHERE greatest(c.du, v.ne) < least(c.au, v.mort)
\if :{?sans_repli}
   AND NOT c.repli
\endif
;

\echo ''
\echo '=== 2. Ce que chaque département recevra ==='
SELECT dep, count(DISTINCT unit_id) AS circos, count(*) AS rattachements,
       count(*) FILTER (WHERE repli) AS dont_repli,
       count(*) FILTER (WHERE valid_from > '1958-01-01') AS nes_apres,
       count(*) FILTER (WHERE valid_to < :'fin'::date AND dep <> '20') AS morts_avant
  FROM t113_pose GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Garde-fou : un atome dans deux circonscriptions (attendu : zéro) ==='
SELECT a.atom_id, a.unit_id, b.unit_id AS autre
  FROM t113_pose a JOIN t113_pose b
    ON b.atom_id = a.atom_id AND b.unit_id > a.unit_id
   AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);

\echo ''
\echo '=== 4. Garde-fou : ces périodes sont-elles libres ? (attendu : zéro) ==='
SELECT p.dep, count(*) AS rattachements_deja_presents
  FROM t113_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
 WHERE NOT EXISTS (SELECT 1 FROM circo_1958_trace t
                    WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text)
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 4 bis. Atomes à canton connu en 1958-1986, dans un département posé, et sans circonscription ==='
SELECT u.dep, count(DISTINCT m.atom_id) AS atomes_sans_circo,
       left(string_agg(DISTINCT u.nom, ', '), 110) AS dans_les_cantons
  FROM membership m JOIN unit u ON u.unit_id = m.unit_id
 WHERE m.niveau = 'canton'
   AND m.periode && daterange('1958-01-01', :'fin'::date, '[)')
   AND u.dep IN (SELECT dep FROM t113_div)
   AND NOT EXISTS (SELECT 1 FROM t113_pose p WHERE p.atom_id = m.atom_id)
   AND NOT EXISTS (SELECT 1 FROM membership x WHERE x.atom_id = m.atom_id
                      AND x.niveau = 'circo'
                      AND x.periode && daterange('1958-01-01', :'fin'::date, '[)'))
 GROUP BY 1 ORDER BY 1;

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_1958_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_1958_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_1958_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_1958_trace;
\endif

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t113_pose;
    IF n = 0 THEN RAISE EXCEPTION 'Rien à poser.'; END IF;

    SELECT count(*) INTO n FROM t113_ko;
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) du CSV introuvables ou renommées : refaire '
            'circo/composition_1958.py. Voir la recette 1 bis.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t113_pose a JOIN t113_pose b
        ON b.atom_id = a.atom_id AND b.unit_id > a.unit_id
       AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) dans deux circonscriptions. Voir la recette 3.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t113_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) existent déjà. Ce fichier COMBLE, '
            'il ne remplace pas. Voir la recette 4.', n;
    END IF;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT unit_id FROM t113_div) d JOIN unit u USING (unit_id);
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) de ce fichier existent déjà en base, hors '
            'de sa trace.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT DISTINCT d.unit_id, 'circo', d.dep, split_part(d.unit_id, '@', 1),
           'uninominal', d.depuis, d.nom, false
      FROM t113_div d
     WHERE d.unit_id IN (SELECT unit_id FROM t113_pose)
    RETURNING unit_id, dep
)
INSERT INTO circo_1958_trace (dep, quoi, cle)
SELECT dep, 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT d.unit_id, d.nom, d.du, d.au FROM t113_div d
 WHERE d.unit_id IN (SELECT unit_id FROM t113_pose);

-- un rattachement à la fois : la trace doit porter `repli` ligne à ligne
DO $$
DECLARE r record; id bigint;
BEGIN
    FOR r IN SELECT * FROM t113_pose LOOP
        INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
        VALUES (r.atom_id, r.unit_id, 'circo', r.valid_from, r.valid_to)
        RETURNING membership_id INTO id;
        INSERT INTO circo_1958_trace (dep, quoi, cle, repli)
        VALUES (r.dep, 'membership', id::text, r.repli);
    END LOOP;
END $$;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*), count(*) FILTER (WHERE repli) AS dont_repli,
       count(DISTINCT dep) AS departements
  FROM circo_1958_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 6. La France, date par date ==='
SELECT v.d AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'canton') AS atomes_canton,
       count(DISTINCT m.atom_id) FILTER (WHERE m.niveau = 'circo')  AS atomes_circo,
       count(DISTINCT m.unit_id) FILTER (WHERE m.niveau = 'circo')  AS circos
  FROM (VALUES ('1957-06-01'::date), ('1958-12-01'), ('1965-06-01'),
               ('1975-06-01'), ('1980-06-01'), ('1986-06-01'),
               ('1987-06-01')) v(d)
  JOIN membership m ON m.periode @> v.d
 GROUP BY v.d ORDER BY v.d;

\echo ''
\echo '=== 7. Aucun atome dans deux unités à la même date, France entière (attendu : rien) ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT a.atom_id, a.niveau FROM membership a JOIN membership b
          ON b.atom_id = a.atom_id AND b.niveau = a.niveau
         AND b.membership_id > a.membership_id AND b.periode && a.periode
         WHERE a.niveau = 'circo'
           AND a.periode && daterange('1958-01-01', :'fin'::date, '[)')) x
 GROUP BY 1;
\else
\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

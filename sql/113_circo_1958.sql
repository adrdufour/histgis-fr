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
--   * COMMUNE : un atome qu'aucune des deux règles ne trouve (fraction d'une
--     ville coupée après 1958 sous un canton neuf) prend la circonscription
--     des autres atomes de sa commune, si elle est unique. Recette 2,
--     `dont_commune` ; `-v sans_commune=1` ne les pose pas.
--   * Les cantons de ville que la base n'a pas en 1958 (Brest-1 et -3,
--     Toulon-1 à -3, Reims-2…) ne reçoivent rien : colonne `atlas_sans_unite`
--     de l'état.
--
-- NON POSÉS — voir `composition_1958_etat.csv`, colonne `raison`
-- ==========================================================
--   * cantons divisés entre deux circonscriptions (13, 33, 37, 38, 62, 69,
--     76, 90) : il faut descendre à l'atome. La Seine-et-Oise (78), dont
--     les six cantons divisés le sont par COMMUNES, est posée depuis le
--     24 octobre 2026 : `composition_1958.py` la descend à la commune
--     (`circo/composition_1958_communes.csv`, colonne `insee` de `t113_div`),
--     sur les cantons que `127` lui a rendus ;
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
    commune boolean NOT NULL DEFAULT false,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);
ALTER TABLE circo_1958_trace ADD COLUMN IF NOT EXISTS commune boolean NOT NULL DEFAULT false;

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

-- Les cantons divisés résolus à la commune (Seine-et-Oise, 24 octobre 2026) :
-- une ligne par (canton, code INSEE de l'atome), voir `composition_1958.py`.
DROP TABLE IF EXISTS t113_comm;
CREATE TEMP TABLE t113_comm (
    dep text, departement text, depuis int, jusqu int, reference date,
    circonscription text, jeton_atlas text, canton_id text, canton_base text,
    insee text);
\copy t113_comm FROM 'circo/composition_1958_communes.csv' WITH (FORMAT csv, HEADER true)

-- la division : canton de la base → unité de circonscription ; `insee` n'est
-- renseigné que pour un canton divisé, rangé commune par commune
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
       c.depuis, c.insee
  FROM (SELECT dep, departement, depuis, jusqu, reference, circonscription,
               canton_id, NULL::text AS insee FROM t113_comp
        UNION ALL
        SELECT dep, departement, depuis, jusqu, reference, circonscription,
               canton_id, insee FROM t113_comm) c
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
      JOIN atom a ON a.atom_id = m.atom_id
     WHERE d.insee IS NULL OR d.insee = a.insee_geofla
), vie AS (                         -- quand l'atome a un canton DU DÉPARTEMENT
    -- Dans le département de la division seulement : Genay et Montanay
    -- passent de l'Ain au Rhône le 20 avril 1969 (canton 6925) et gardaient
    -- jusqu'en 1986 la 3e circonscription de l'Ain — la carte de l'Ain les
    -- dessinait en blanc, sans canton (20 octobre 2026). La Corse change de
    -- code en 1976 (20 → 2A, 2B) sans changer de département.
    SELECT m.atom_id, u.dep2 AS dep, min(m.valid_from) AS ne, max(m.valid_to) AS mort
      FROM membership m
      JOIN (SELECT unit_id, CASE WHEN dep IN ('2A', '2B') THEN '20' ELSE dep::text END AS dep2
              FROM unit WHERE niveau = 'canton') u USING (unit_id)
     WHERE m.niveau = 'canton'
       AND m.atom_id IN (SELECT atom_id FROM fen)
       AND m.periode && daterange('1958-01-01', :'fin'::date, '[)')
     GROUP BY 1, 2
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
  FROM choix c JOIN vie v ON v.atom_id = c.atom_id AND v.dep = c.dep
 WHERE greatest(c.du, v.ne) < least(c.au, v.mort)
\if :{?sans_repli}
   AND NOT c.repli
\endif
;
ALTER TABLE t113_pose ADD COLUMN commune boolean NOT NULL DEFAULT false;

-- HÉRITAGE PAR LA COMMUNE — ajouté le 21 octobre 2026, signalé par Adrien
-- (Bourg-en-Bresse, Oyonnax). Une ville coupée APRÈS 1958 entre un canton de
-- 1958 et un canton neuf (Oyonnax-Nord et -Sud en 1973, Bourg-Nord-Centre en
-- 1982) a une fraction dont aucun canton n'est dans l'atlas : ni la date de
-- référence ni le repli ne la trouvent, et elle restait sans circonscription
-- jusqu'en 1986. Or le découpage de 1958 ne suit pas les cantons créés ensuite :
-- le territoire reste dans la circonscription où il était. Une telle fraction
-- prend donc celle des autres atomes de sa commune — si elle est UNIQUE. Une
-- ville déjà partagée entre deux circonscriptions en 1958 ne lègue rien : il
-- faudrait savoir de quel côté vient la fraction. `-v sans_commune=1` pour ne
-- pas poser ces rattachements ; ils sont comptés à part (recette 2).
\if :{?sans_commune}
\else
INSERT INTO t113_pose (atom_id, dep, unit_id, repli, valid_from, valid_to, commune)
WITH bornes AS (
    SELECT dep, min(du) AS du, max(au) AS au FROM t113_div GROUP BY dep
), vie AS (                         -- comme plus haut : canton DU DÉPARTEMENT
    SELECT m.atom_id, a.cassini, u.dep2 AS dep,
           min(m.valid_from) AS ne, max(m.valid_to) AS mort
      FROM membership m
      JOIN atom a USING (atom_id)
      JOIN (SELECT unit_id, CASE WHEN dep IN ('2A', '2B') THEN '20' ELSE dep::text END AS dep2
              FROM unit WHERE niveau = 'canton') u USING (unit_id)
     WHERE m.niveau = 'canton'
       AND m.periode && daterange('1958-01-01', :'fin'::date, '[)')
       AND m.atom_id NOT IN (SELECT atom_id FROM t113_pose)
     GROUP BY 1, 2, 3
), legue AS (                       -- la circonscription unique de la commune
    SELECT a.cassini, p.dep, min(p.unit_id) AS unit_id
      FROM t113_pose p JOIN atom a USING (atom_id)
     GROUP BY 1, 2
    HAVING count(DISTINCT p.unit_id) = 1
)
SELECT v.atom_id, v.dep, l.unit_id, false,
       greatest(b.du, v.ne), least(b.au, v.mort), true
  FROM vie v
  JOIN bornes b ON b.dep = v.dep
  JOIN legue l ON l.cassini = v.cassini AND l.dep = v.dep
 WHERE greatest(b.du, v.ne) < least(b.au, v.mort)
   AND NOT EXISTS (SELECT 1 FROM membership x
                    WHERE x.atom_id = v.atom_id AND x.niveau = 'circo'
                      AND x.periode && daterange('1958-01-01', :'fin'::date, '[)')
                      AND NOT EXISTS (SELECT 1 FROM circo_1958_trace t
                                       WHERE t.quoi = 'membership'
                                         AND t.cle = x.membership_id::text));
\endif

\echo ''
\echo '=== 2. Ce que chaque département recevra ==='
SELECT dep, count(DISTINCT unit_id) AS circos, count(*) AS rattachements,
       count(*) FILTER (WHERE repli) AS dont_repli,
       count(*) FILTER (WHERE commune) AS dont_commune,
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
        INSERT INTO circo_1958_trace (dep, quoi, cle, repli, commune)
        VALUES (r.dep, 'membership', id::text, r.repli, r.commune);
    END LOOP;
END $$;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*), count(*) FILTER (WHERE repli) AS dont_repli,
       count(*) FILTER (WHERE commune) AS dont_commune,
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

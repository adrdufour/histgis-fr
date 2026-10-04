-- ============================================================================
-- 56_paris_circo_1876.sql — Paris au quartier de 1876 à 1941
--
--   python3 circo/paris_quartiers.py && python3 circo/paris_circo.py
--   psql -d histgis -f sql/56_paris_circo_1876.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/56_paris_circo_1876.sql
--
-- CE FICHIER REMPLACE DE LA DONNÉE. C'est le seul de la série parisienne dans
-- ce cas, et il faut le lire avant de l'appliquer.
--
-- Ce que TRF-GIS pose, et pourquoi ce n'est pas ce qu'on croit
-- ------------------------------------------------------------
-- Mesuré le 21 août 2026, aux périodes uninominales : **vingt unités nommées
-- `Paris-1` à `Paris-20`, un arrondissement chacune**. Ce ne sont pas des
-- circonscriptions approximatives — ce sont les arrondissements, étiquetés
-- circonscriptions. Paris en comptait trente-sept en 1893 et quarante en 1902.
--
-- **Ses périodes de LISTE sont justes**, en revanche : une unité « Seine » en
-- 1872 et 1887, **trois** en 1922. Et la transcription donne elle aussi trois
-- pour 1919-1928. Les deux sources concordent exactement là où TRF-GIS décrit
-- un objet réel — ce qui est la meilleure raison de croire qu'ailleurs il
-- décrit autre chose.
--
-- Il n'y a donc pas de conflit à arbitrer : l'une des deux sources répond à
-- côté de la question. Ce qui tient lieu de contrôle est ailleurs :
--
--   * la transcription **partitionne les 80 quartiers** sur chacune des douze
--     divisions postérieures à 1860, sans un orphelin ni un inventé ;
--   * l'alternance liste/uninominal qu'elle produit **retrouve celle de
--     TRF-GIS**, sans qu'on la lui ait donnée : 3 circonscriptions en
--     1919-1928 des deux côtés.
--
-- Ce qui n'est PAS touché
-- -----------------------
-- **1870-1876 et 1885-1889**, scrutins de liste : la transcription n'a rien, et
-- l'unité « Seine » de TRF-GIS est correcte. On la laisse.
--
-- La division sans date, posée en 1898-1902
-- ------------------------------------------
-- `note_paris.md` sort une division sous le libellé `?-?` : sa période est
-- inconnue, elle fusionne le 4e et dédouble le 16e par rapport à 1893-1898.
--
-- Les intervalles non couverts entre 1863 et 1945 sont **1870-1876**,
-- **1885-1889**, **1898-1902** et **1940-1945**. Les trois autres s'expliquent
-- — deux scrutins de liste et la guerre. Il reste un intervalle uninominal sans
-- division, et une division sans date. La correspondance est forte, et le sens
-- du mouvement démographique la confirme : le 4e se dépeuple, le 16e se
-- remplit.
--
-- **C'est une inférence, et elle est marquée comme telle** : `provisoire = true`
-- sur ces unités, et `circo_serie = '?-?'` dans la trace. Une relecture de
-- l'atlas peut la confirmer ou la déplacer sans rien défaire.
--
-- Une borne étendue, déclarée
-- ---------------------------
-- La dernière division transcrite est `1928-1940`. La série TRF-GIS s'arrête au
-- 1er janvier 1941. On étend donc jusqu'à 1941, faute de quoi l'année 1940
-- retomberait sur les arrondissements qu'on vient de retirer. Aucun
-- redécoupage n'est intervenu entre 1940 et 1941 — il n'y a pas eu d'élection.
--
-- Ce que ce fichier ne règle pas
-- ------------------------------
-- Les vingt atomes d'arrondissement gardent leurs rattachements CANTONAUX.
-- Paris reste donc porté par deux jeux d'atomes, et **105 km² sont comptés deux
-- fois** de 1876 à 1941, comme ils le sont déjà de 1986 à 2012. Le résoudre
-- demanderait la composition cantonale de Paris au quartier, que nous n'avons
-- pas.
--
-- Réversible : `paris_1876_trace` garde les rattachements retirés en entier.
-- Prérequis : `52` joué (atomes PQ01…PQ80), `paris_circo` reconstruite.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.paris_circo') IS NULL THEN
        RAISE EXCEPTION E'paris_circo absente.\n'
            '  python3 circo/paris_quartiers.py && python3 circo/paris_circo.py';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = 'PQ01') THEN
        RAISE EXCEPTION E'Atomes PQ01…PQ80 absents.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/52_paris_circo_1986.sql';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les dix divisions, leurs bornes et leur régime
--
-- Le régime n'est pas déduit du nombre de circonscriptions : il est celui de la
-- loi électorale en vigueur. 1919 et 1924 se sont tenues au scrutin de liste,
-- le reste de la période à l'uninominal d'arrondissement.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pq_periode;
CREATE TEMP TABLE pq_periode (
    periode text PRIMARY KEY, du date, au date, regime text, infere boolean
);
INSERT INTO pq_periode VALUES
    ('1876-1881', DATE '1876-01-01', DATE '1881-01-01', 'uninominal', false),
    ('1881-1885', DATE '1881-01-01', DATE '1885-01-01', 'uninominal', false),
    -- 1885-1889 : scrutin de liste. TRF-GIS a raison, on ne touche pas.
    ('1889-1893', DATE '1889-01-01', DATE '1893-01-01', 'uninominal', false),
    ('1893-1898', DATE '1893-01-01', DATE '1898-01-01', 'uninominal', false),
    ('?-?',       DATE '1898-01-01', DATE '1902-01-01', 'uninominal', true),
    ('1902-1910', DATE '1902-01-01', DATE '1910-01-01', 'uninominal', false),
    ('1910-1914', DATE '1910-01-01', DATE '1914-01-01', 'uninominal', false),
    ('1914-1919', DATE '1914-01-01', DATE '1919-01-01', 'uninominal', false),
    ('1919-1928', DATE '1919-01-01', DATE '1928-01-01', 'liste',      false),
    ('1928-1940', DATE '1928-01-01', DATE '1941-01-01', 'uninominal', false);

DROP TABLE IF EXISTS pq_ligne;
CREATE TEMP TABLE pq_ligne AS
SELECT p.periode, p.du, p.au, p.regime, p.infere, c.circo, c.source,
       unnest(c.q_list)                             AS quartier,
       'PQ' || lpad(unnest(c.q_list)::text, 2, '0') AS atom_id,
       'Q' || replace(replace(p.periode, '-', '_'), '?', 'X')
           || '#' || c.circo                        AS unit_id,
       extract(year FROM p.du)::int                 AS segment
  FROM paris_circo c
  JOIN pq_periode p ON p.periode = c.periode;

DROP TABLE IF EXISTS pq_coupe;
CREATE TEMP TABLE pq_coupe AS
SELECT periode, quartier FROM pq_ligne
 GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1;

DROP TABLE IF EXISTS pq_pose;
CREATE TEMP TABLE pq_pose AS
SELECT l.* FROM pq_ligne l
 WHERE NOT EXISTS (SELECT 1 FROM pq_coupe c
                    WHERE c.periode = l.periode AND c.quartier = l.quartier);

-- Ce qui va être RETIRÉ : les rattachements des vingt atomes d'arrondissement
-- qui chevauchent une période posée. Les périodes de liste non traitées
-- (1870-1876, 1885-1889) ne chevauchent aucune d'elles, et survivent donc.
DROP TABLE IF EXISTS pq_retrait;
CREATE TEMP TABLE pq_retrait AS
SELECT DISTINCT m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
  FROM membership m
  JOIN atom a ON a.atom_id = m.atom_id
             AND a.insee_geofla LIKE '751%' AND a.atom_id NOT LIKE 'P%'
  JOIN pq_periode p ON m.periode && daterange(p.du, p.au, '[)')
 WHERE m.niveau = 'circo';

\echo ''
\echo '=== 1. Ce que la transcription donne ==='
SELECT l.periode, min(l.du) AS du, max(l.au) AS au, min(l.regime) AS regime,
       bool_or(l.infere) AS infere,
       count(DISTINCT l.unit_id) AS circos,
       count(DISTINCT l.quartier) AS quartiers,
       (SELECT count(*) FROM pq_coupe c WHERE c.periode = l.periode) AS coupes
  FROM pq_ligne l GROUP BY l.periode ORDER BY min(l.du);

\echo ''
\echo '=== 2. Ce que TRF-GIS posait, et qui sera retire ==='
SELECT extract(year FROM valid_from)::int AS depuis,
       extract(year FROM valid_to)::int   AS jusqu_a,
       count(*) AS rattachements, count(DISTINCT unit_id) AS unites
  FROM pq_retrait GROUP BY 1, 2 ORDER BY 1;

\echo ''
\echo '=== 3. Le compte, avant et apres ==='
SELECT p.periode, p.du,
       (SELECT count(DISTINCT r.unit_id) FROM pq_retrait r
         WHERE daterange(r.valid_from, r.valid_to, '[)')
               && daterange(p.du, p.au, '[)'))          AS trfgis,
       (SELECT count(DISTINCT l.unit_id) FROM pq_ligne l
         WHERE l.periode = p.periode)                   AS transcription
  FROM pq_periode p ORDER BY p.du;
-- TRF-GIS doit donner 20 partout sauf 1919-1928, ou il donne 3 comme la
-- transcription. C'est la concordance qui autorise le remplacement ailleurs.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS paris_1876_trace (
    quoi         text NOT NULL,
    cle          text NOT NULL,
    atom_id      text,
    unit_id      text,
    valid_from   date,
    valid_to     date,
    circo_serie  text,
    pose_le      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- Rejeu : on remet d'abord ce qu'on avait retiré, puis on retire ce qu'on
-- avait posé. Sans quoi un second passage supprimerait les rattachements de
-- TRF-GIS une deuxième fois sans pouvoir les rendre.
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT t.atom_id, t.unit_id, 'circo', t.valid_from, t.valid_to
  FROM paris_1876_trace t WHERE t.quoi = 'retire'
ON CONFLICT DO NOTHING;

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM paris_1876_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM paris_1876_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE paris_1876_trace;

-- --- retrait, integralement trace ------------------------------------------
INSERT INTO paris_1876_trace (quoi, cle, atom_id, unit_id, valid_from, valid_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, valid_from, valid_to
  FROM pq_retrait;

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM pq_retrait r WHERE r.membership_id = m.membership_id);

-- --- pose ------------------------------------------------------------------
WITH u AS (
    SELECT DISTINCT unit_id, circo, segment, periode, regime, infere
      FROM pq_ligne
), ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT u.unit_id, 'circo', '75', '75-' || u.circo, u.regime, u.segment,
           'Paris ' || u.circo || 'e circonscription (' || u.periode || ')',
           u.infere
      FROM u
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO paris_1876_trace (quoi, cle, unit_id)
SELECT 'unit', unit_id, unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT l.unit_id, 'Paris ' || l.circo || 'e circonscription',
       l.du, l.au
  FROM pq_ligne l
 WHERE EXISTS (SELECT 1 FROM paris_1876_trace t
                WHERE t.quoi = 'unit' AND t.cle = l.unit_id);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT atom_id, unit_id, 'circo', du, au FROM pq_pose
    RETURNING membership_id, atom_id, unit_id
)
INSERT INTO paris_1876_trace (quoi, cle, atom_id, unit_id, circo_serie)
SELECT 'membership', i.membership_id::text, i.atom_id, i.unit_id,
       (SELECT min(p.periode) FROM pq_pose p WHERE p.unit_id = i.unit_id)
  FROM ins i;

ANALYZE membership;

\echo ''
\echo '=== 4. Bilan ==='
SELECT quoi, count(*) FROM paris_1876_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 5. Paris, de 1815 a 2012 ==='
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) AS atomes,
       count(DISTINCT m.unit_id) AS circos,
       string_agg(DISTINCT u.regime, ', ') AS regime
  FROM (VALUES ('1816-06-01'::date),('1850-06-01'),('1865-06-01'),
               ('1872-06-01'),('1878-06-01'),('1887-06-01'),('1895-06-01'),
               ('1900-06-01'),('1905-06-01'),('1922-06-01'),('1935-06-01'),
               ('1943-06-01'),('1950-06-01'),('1970-06-01'),('1990-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN atom a ON a.atom_id = m.atom_id AND a.insee_geofla LIKE '751%'
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo'
 WHERE a.atom_id IS NOT NULL OR m.atom_id IS NULL
 GROUP BY d ORDER BY d;
-- 1872 et 1887 doivent rester a 1 circonscription, en LISTE, sur 20 atomes :
-- ce sont les periodes ou TRF-GIS a raison et qu'on n'a pas touchees.
-- 1850 et 1943 doivent rester vides.

\echo ''
\echo '=== 6. Quartiers coupes, non poses ==='
SELECT c.periode, count(*) AS quartiers,
       string_agg(q.nom, ', ' ORDER BY q.nom) AS lesquels
  FROM pq_coupe c LEFT JOIN paris_quartier q ON q.quartier = c.quartier
 GROUP BY c.periode ORDER BY c.periode;

\echo ''
\echo '=== 7. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\echo ''
\echo '=== 8. Pour tout defaire ==='
\echo '    INSERT les lignes quoi=''retire'' de paris_1876_trace dans membership,'
\echo '    puis DELETE les quoi=''membership'' et les quoi=''unit''.'
\echo '    Le fichier le fait lui-meme au debut de chaque rejeu.'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

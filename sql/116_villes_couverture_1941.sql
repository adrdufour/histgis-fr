-- ============================================================================
-- histgis — 116_villes_couverture_1941.sql : les fractions des villes de 1941
--           à la reprise de leur régime
--
--   psql -d histgis -f sql/116_villes_couverture_1941.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/116_villes_couverture_1941.sql
--
-- ARBITRAGE D'ADRIEN, 13 octobre 2026 : « la base doit couvrir le maximum
-- entre 1815 et 2025 ». Le trou général de 1941 touche toutes les fractions :
-- la base les arrête au 1941-01-01 et ne les reprend qu'au COG de 1968.
--
-- DEUX RÈGLES
--   A. GÉNÉRALE — la ville a exactement les mêmes fractions au 31 décembre
--      1940 et au 1er janvier 1968, et rien entre les deux : le régime est le
--      même, les fractions sont posées de 1941 à 1968 sous leur canton.
--   B. NOMMÉE — le régime de 1940 a pris fin à une date connue (chronologie
--      cantonale, Gaudillère ; c'est la fin des lignes de `coupes_ville.csv`) :
--      les fractions de 1940 sont posées de 1941 à cette date.
--        Tours 1956-08-04 ; Angers, Le Havre, Toulon, Versailles 1964-01-28 ;
--        Le Mans 1967-08-08 ; Caen 1967-09-24 ; Metz 1968 (le COG prend la suite) ;
--        Marseille, Nantes, Montpellier, Chalon-sur-Saône, Montluçon,
--        La Rochelle 1973-09-23 ; Rouen 1982-03-14.
--      La Rochelle : l'atome entier de Laleu (`18407`) quitte La Rochelle-Est
--      en 1968-1973, les deux fractions sont sur `29365`.
--   C. MOULINS — Est / Ouest de 1941 à 1973, Sud / Ouest (décret 73-713) de
--      1973 à 1985, à la place de l'atome entier de 1968-1973.
--
-- CE QUE CE FICHIER NE FAIT PAS : les régimes intermédiaires (Le Mans
-- 1967-1982, Le Havre 1964-1992, Tours 1956-1968, Angers 1964-1973…), qui
-- demandent leurs lignes ; les villes dont les fractions diffèrent en 1940 et
-- à la reprise sans date connue (Lille, Lyon, Strasbourg, Limoges, Orléans,
-- Brest, Amiens, Grenoble…) ; les communes rurales (`93`, `95`, `97`).
--
-- Même modèle que `114` ; après `115`, AVANT `98`. RÉVERSIBLE : `p116_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p116_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | membership_borne | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité ; 'atome|unité|du|au' pour un retrait ; 'du|au' pour une borne
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p116_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p116_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
-- Les bornes d'Aubagne se rendent en deux temps, à cause de l'exclusion
-- `membership_non_chevauchant` : d'abord les fins qui reculent… non : ici
-- toutes les lignes reculent ou avancent du même pas, on rend les débuts puis
-- les fins dans l'ordre qui n'empiète jamais.
UPDATE membership m SET valid_from = split_part(t.avant, '|', 1)::date
  FROM p116_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_from <> split_part(t.avant, '|', 1)::date;
UPDATE membership m SET valid_to = split_part(t.avant, '|', 2)::date
  FROM p116_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_to <> split_part(t.avant, '|', 2)::date;
-- Rennes est une permutation : l'exclusion ne porte pas sur l'unité, un seul
-- UPDATE suffit.
UPDATE membership m SET unit_id = t.avant FROM p116_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p116_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p116_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée,'
\echo '=== et les comptes qui suivent décrivent un second passage.'
SELECT quoi, count(*) FROM p116_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t116_unite, t116_retire, t116_pose, t116_nom, t116_borne, t116_retire_v, t116_1940;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t116_unite AS
SELECT 0 AS par, m.membership_id, m.atom_id, m.unit_id AS avant, m.unit_id AS apres, m.valid_from, m.valid_to
FROM membership m WHERE false;

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t116_retire_v (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t116_retire_v VALUES
  (110, '18407', '1723', '1968-01-01', '1973-09-23'),   -- Laleu entière dans La Rochelle-Est
  ( 14, '24214', '0323', '1968-01-01', '1973-09-23');   -- Moulins entière dans Moulins-Est
CREATE TEMP TABLE t116_retire AS
SELECT r.par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   t116_retire_v r
JOIN   membership m ON m.niveau = 'canton' AND m.atom_id = r.atom_id AND m.unit_id = r.unit_id
                   AND m.periode <@ daterange(r.du, r.au, '[)');

-- ---------------------------------------------------------------------------
-- 3. Les bornes d'Aubagne — n° 92, décret 2003-156, cantonales du 21 mars 2004
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t116_borne AS
SELECT 92 AS par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN m.valid_from = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_from END AS du,
       CASE WHEN m.valid_to   = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_to   END AS au
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  false;

-- ---------------------------------------------------------------------------
-- 4. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t116_pose (par int, atom_id text, unit_id text, du date, au date);
-- Les fractions vivantes au 31 décembre 1940, par ville.
CREATE TEMP TABLE t116_1940 AS
SELECT a.cassini AS ville, a.insee_geofla AS insee, m.atom_id, m.unit_id
FROM   membership m JOIN atom a USING (atom_id)
WHERE  m.niveau = 'canton' AND a.fraction AND m.atom_id LIKE '%#%' AND a.cassini !~ '^PQ'
  AND  m.valid_to = DATE '1941-01-01';
-- A. Mêmes fractions en 1968, rien entre les deux.
INSERT INTO t116_pose
SELECT 0, f.atom_id, f.unit_id, DATE '1941-01-01', DATE '1968-01-01'
FROM   t116_1940 f
WHERE  (SELECT array_agg(x.atom_id ORDER BY x.atom_id) FROM t116_1940 x WHERE x.ville = f.ville)
     = (SELECT array_agg(DISTINCT m.atom_id ORDER BY m.atom_id) FROM membership m JOIN atom a USING (atom_id)
         WHERE m.niveau = 'canton' AND a.cassini = f.ville AND a.fraction AND m.valid_from = DATE '1968-01-01')
  AND  NOT EXISTS (SELECT 1 FROM membership m JOIN atom a USING (atom_id)
                    WHERE m.niveau = 'canton' AND a.cassini = f.ville
                      AND m.periode && daterange(DATE '1941-01-01', DATE '1968-01-01', '[)'));
-- B. La fin connue du régime de 1940.
INSERT INTO t116_pose
SELECT 1, f.atom_id, f.unit_id, DATE '1941-01-01', v.au
FROM   (VALUES ('37911', DATE '1956-08-04'),   -- Tours
               ('804',   DATE '1964-01-28'),   -- Angers
               ('16833', DATE '1964-01-28'),   -- Le Havre
               ('37812', DATE '1964-01-28'),   -- Toulon
               ('39569', DATE '1964-01-28'),   -- Versailles
               ('20932', DATE '1967-08-08'),   -- Le Mans
               ('6530',  DATE '1967-09-24'),   -- Caen (les quatre cantons de 1967 prennent la suite, § C)
               ('22347', DATE '1968-01-01'),   -- Metz
               ('21387', DATE '1973-09-23'),   -- Marseille
               ('24557', DATE '1973-09-23'),   -- Nantes
               ('23741', DATE '1973-09-23'),   -- Montpellier
               ('7729',  DATE '1973-09-23'),   -- Chalon-sur-Saône
               ('23649', DATE '1973-09-23'),   -- Montluçon
               ('29365', DATE '1973-09-23'),   -- La Rochelle
               ('29752', DATE '1982-03-14'))   -- Rouen
       AS v(ville, au)
JOIN   t116_1940 f ON f.ville = v.ville;
-- C. Moulins (n° 14) : Est / Ouest de l'an X à 1973, Sud / Ouest du décret
-- 73-713 de 1973 à 1985 — mêmes unités, autre limite (ligne `03190-2`).
INSERT INTO t116_pose VALUES
  (14, '24214#0323', '0323', '1941-01-01', '1973-09-23'),
  (14, '24214#0324', '0324', '1941-01-01', '1973-09-23'),
  (14, '24214#0323', '0323', '1973-09-23', '1985-03-10'),
  (14, '24214#0324', '0324', '1973-09-23', '1985-03-10'),
  -- Caen (n° 101) : Ouest, Nord, Est, Sud du décret du 8 août 1967, des
  -- cantonales du 24 septembre 1967 au COG de 1968 (lignes `14118-1` à `-4`).
  (101, '6530#1408', '1408', '1967-09-24', '1968-01-01'),
  (101, '6530#1409', '1409', '1967-09-24', '1968-01-01'),
  (101, '6530#1439', '1439', '1967-09-24', '1968-01-01'),
  (101, '6530#1440', '1440', '1967-09-24', '1968-01-01');

CREATE TEMP TABLE t116_nom (par int, unit_id text, nom text, du date, au date);
\echo ''
\echo '=== 1. Ce qui sera fait, par entrée ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t116_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t116_retire GROUP BY 1
UNION ALL SELECT par, 'borne', count(*), min(du), max(au) FROM t116_borne GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t116_pose GROUP BY 1
UNION ALL SELECT par, 'nom', count(*), min(du), max(au) FROM t116_nom GROUP BY 1
ORDER BY 1, 2;
-- Attendu au premier passage : 188 poses (119 par la règle A, 61 par la B, 4 pour Moulins, 4 pour Caen), 4 retraits.

-- ---------------------------------------------------------------------------
-- 5. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p116_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    SELECT count(*) INTO n FROM t116_unite;
    IF n <> 0 THEN RAISE EXCEPTION 'UNITÉ : % ligne(s) à changer, 35 attendues '
                                    '(30 à Rennes, 2 pour Javrezac, 3 à Nice).', n; END IF;
    SELECT count(*) INTO n FROM t116_retire;
    IF n <> 4 THEN RAISE EXCEPTION 'RETRAIT : % ligne(s), 22 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t116_borne;
    IF n <> 0 THEN RAISE EXCEPTION 'AUBAGNE : % borne(s) à déplacer, 13 attendues.', n; END IF;

    SELECT count(*) INTO n FROM t116_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t116_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % unité(s) inconnues.', n; END IF;
    -- Une fraction porte le code de son canton : `X#NNNN` ne va que dans NNNN.
    SELECT count(*) INTO n FROM t116_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) posées hors de leur canton.', n; END IF;
    -- Les poses ne se recouvrent pas entre elles…
    SELECT count(*) INTO n FROM t116_pose a JOIN t116_pose b
        ON a.atom_id = b.atom_id AND a.ctid < b.ctid
       AND daterange(a.du, a.au, '[)') && daterange(b.du, b.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % paire(s) de poses se recouvrent.', n; END IF;
    -- … et la période de chacune doit être libre, hors ce qui va être retiré.
    SELECT count(*) INTO n FROM t116_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM t116_retire r WHERE r.membership_id = m.membership_id);
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 2 ci-dessous).', n;
    END IF;
    -- Chaque pose doit TOUCHER une période existante du même atome, à gauche
    -- ou à droite : on comble un trou, on ne pose pas une période isolée.
    SELECT count(*) INTO n FROM t116_pose p
     WHERE NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                          AND (m.valid_to = p.du OR m.valid_from = p.au))
       AND NOT EXISTS (SELECT 1 FROM t116_pose q WHERE q.atom_id = p.atom_id
                          AND (q.au = p.du OR q.du = p.au))
       -- … sauf la fraction oubliée de 1968 : ses sœurs ont déjà la période.
       AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.niveau = 'canton'
                          AND m.atom_id <> p.atom_id AND m.atom_id LIKE '%#%'
                          AND split_part(m.atom_id, '#', 1) = split_part(p.atom_id, '#', 1)
                          AND m.valid_from = p.du);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) isolées, sans voisine.', n; END IF;

    SELECT count(*) INTO n FROM t116_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t116_nom p WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % unité(s) inconnues.', n; END IF;

END $$;

\echo ''
\echo '=== 2. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t116_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p116_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text)
  AND  NOT EXISTS (SELECT 1 FROM t116_retire r WHERE r.membership_id = m.membership_id);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 6. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p116_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t116_unite;
UPDATE membership m SET unit_id = u.apres FROM t116_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p116_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t116_retire;
DELETE FROM membership m USING t116_retire r WHERE r.membership_id = m.membership_id;

-- Aubagne : les fins reculent d'abord, les débuts ensuite — jamais de
-- chevauchement entre l'atome entier et ses fractions.
INSERT INTO p116_trace (quoi, cle, avant)
SELECT 'membership_borne', membership_id::text, valid_from || '|' || valid_to FROM t116_borne;
UPDATE membership m SET valid_to = b.au FROM t116_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_to <> b.au;
UPDATE membership m SET valid_from = b.du FROM t116_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_from <> b.du;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t116_pose
    RETURNING membership_id
)
INSERT INTO p116_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t116_nom
    RETURNING unit_version_id
)
INSERT INTO p116_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Écrit ==='
SELECT quoi, count(*) FROM p116_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 7. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recette : chaque canton du lot au milieu de chaque période posée ==='
WITH dates AS (
    SELECT DISTINCT par, unit_id, (du + (au - du) / 2) AS d FROM t116_pose
)
SELECT d.par, d.d AS a_la_date, d.unit_id, coalesce(v.nom, u.nom) AS canton,
       count(m.*) FILTER (WHERE m.atom_id NOT LIKE '%#%') AS communes,
       string_agg(m.atom_id, ' ' ORDER BY m.atom_id) FILTER (WHERE m.atom_id LIKE '%#%') AS fractions
FROM   dates d
JOIN   unit u ON u.unit_id = d.unit_id AND u.niveau = 'canton'
LEFT   JOIN unit_version v ON v.unit_id = d.unit_id AND v.periode @> d.d
LEFT   JOIN membership m ON m.niveau = 'canton' AND m.unit_id = d.unit_id AND m.periode @> d.d
GROUP  BY 1, 2, 3, 4 ORDER BY 1, 3, 2;

\echo ''
\echo '=== 5. Une ville ne doit jamais avoir à la fois son atome entier et ses fractions ==='
SELECT e.atom_id AS entier, e.unit_id, e.periode, f.atom_id AS fraction, f.periode AS periode_fraction
FROM   membership f
JOIN   membership e ON e.niveau = 'canton' AND e.atom_id = split_part(f.atom_id, '#', 1)
                   AND e.periode && f.periode
WHERE  f.niveau = 'canton' AND f.atom_id LIKE '%#%'
  AND  split_part(f.atom_id, '#', 1) IN (SELECT DISTINCT split_part(atom_id, '#', 1) FROM t116_pose);
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

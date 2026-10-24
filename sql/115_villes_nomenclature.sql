-- ============================================================================
-- histgis — 115_villes_nomenclature.sql : troisième lot de
--           `cartes/a_inscrire_en_base.md` — les régimes de 1973 (1961, 1967,
--           1976) que l'on croyait sans unité
--
--   psql -d histgis -f sql/115_villes_nomenclature.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/115_villes_nomenclature.sql
--
-- NOMENCLATURE — arbitrage d'Adrien, 13 octobre 2026, sur les cartes de
-- `cartes/sorties/nomenclature/` : un canton disparu ne reçoit pas d'unité
-- nouvelle, il est porté par l'unité du régime suivant qui hérite de la plus
-- grande part de son territoire dans la ville. Donné par Adrien pour Antibes,
-- Cannes, Chambéry et Manosque ; appliqué de même, à sa demande, à Bourg, Gap,
-- Sarcelles, Montluçon-Nord et Caen-Nord (hectares communs entre parenthèses) :
--   ANTIBES   Nord 1973 -> 0601 Antibes-Biot (767) ; Sud 1973 -> 0647 Centre (574)
--   CANNES    Ouest 1973 -> 0649 Cannes-Centre (606, contre 535 à 0636) ;
--             Est 1973, Lérins comprises -> 0606 Cannes-Est (657)
--   MANOSQUE  Nord -> 0413 ; Sud 1973 -> 0432 Manosque-Sud-Est (1 361)
--   CHAMBÉRY  les terres annexées en 1961 (Bissy, Chambéry-le-Vieux) -> 7309
--             Chambéry-Nord : c'est une ancre, pas une appartenance
--   BOURG     I -> 0137 Nord-Centre (266) ; II -> 0105 Est (1 137) ; III -> 0138 Sud (627)
--   GAP       Campagne -> 0509 ; Centre -> 0526 ; Est -> 0529 Sud-Est (1 929) ;
--             Ouest -> 0530 Sud-Ouest (1 526)
--   SARCELLES Est 1976 -> 9523 Nord-Est (404) ; Saint-Brice 1976 -> 9533 Sud-Ouest
--   MONTLUÇON Nord 1973 -> 0331 Nord-Est (495)
--   CAEN      Nord 1967 -> 1439, qui porte déjà ses communes en 1968-1973
-- Les communes rurales suivent leur canton sous le même code ; le nom du
-- décret est posé dans `unit_version` sur la période. Conséquence à savoir :
-- Mandelieu et Théoule sont sous 0649 de 1973 à 1985, puis sous 0636 ; Vallauris
-- sous 0647 puis 0635 ; Montfuron et Pierrevert sous 0432 puis 0433 — un
-- changement de code en 1985 sans changement de canton pour elles.
--
-- Les ancres datées qui vont avec sont dans `cartes/coupes_ville_ancres.csv`.
-- Même modèle que `114` ; après `114`, AVANT `98`. Rien n'est créé : ni unité,
-- ni atome.
--
-- CE QUE CE FICHIER NE FAIT PAS : Caen-V de 1973 (fraction `6530#1441` à
-- créer), La Rochelle (fractions accrochées à Laleu), Charleville 1973 et
-- Chalon Ville / Périphérie (lignes non tracées), Bourg-Couronne, Saint-Martin-
-- les-Eaux (double compte 1974-1980), Sarcelles avant 1976, Chambéry 1973-1985.
--
-- RÉVERSIBLE ET REJOUABLE : `p115_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p115_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | membership_borne | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité ; 'atome|unité|du|au' pour un retrait ; 'du|au' pour une borne
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p115_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p115_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
-- Les bornes d'Aubagne se rendent en deux temps, à cause de l'exclusion
-- `membership_non_chevauchant` : d'abord les fins qui reculent… non : ici
-- toutes les lignes reculent ou avancent du même pas, on rend les débuts puis
-- les fins dans l'ordre qui n'empiète jamais.
UPDATE membership m SET valid_from = split_part(t.avant, '|', 1)::date
  FROM p115_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_from <> split_part(t.avant, '|', 1)::date;
UPDATE membership m SET valid_to = split_part(t.avant, '|', 2)::date
  FROM p115_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_to <> split_part(t.avant, '|', 2)::date;
-- Rennes est une permutation : l'exclusion ne porte pas sur l'unité, un seul
-- UPDATE suffit.
UPDATE membership m SET unit_id = t.avant FROM p115_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p115_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p115_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée,'
\echo '=== et les comptes qui suivent décrivent un second passage.'
SELECT quoi, count(*) FROM p115_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t115_unite, t115_retire, t115_pose, t115_nom, t115_borne, t115_retire_v;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t115_unite AS
SELECT 0 AS par, m.membership_id, m.atom_id, m.unit_id AS avant, m.unit_id AS apres, m.valid_from, m.valid_to
FROM membership m WHERE false;

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t115_retire_v (par int, atom_id text, unit_id text, du date, au date);
CREATE TEMP TABLE t115_retire AS
SELECT r.par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   t115_retire_v r
JOIN   membership m ON m.niveau = 'canton' AND m.atom_id = r.atom_id AND m.unit_id = r.unit_id
                   AND m.periode <@ daterange(r.du, r.au, '[)');

-- ---------------------------------------------------------------------------
-- 3. Les bornes d'Aubagne — n° 92, décret 2003-156, cantonales du 21 mars 2004
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t115_borne AS
SELECT 92 AS par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN m.valid_from = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_from END AS du,
       CASE WHEN m.valid_to   = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_to   END AS au
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  false;

-- ---------------------------------------------------------------------------
-- 4. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t115_pose (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t115_pose VALUES
  -- 20 — Antibes
  ( 20, '951#0601',   '0601', '1973-09-23', '1985-03-10'),
  ( 20, '951#0647',   '0647', '1973-09-23', '1985-03-10'),
  ( 20, '951#0601',   '0601', '1985-03-10', '1998-03-15'),
  ( 20, '951#0647',   '0647', '1985-03-10', '1998-03-15'),
  ( 20, '951#0635',   '0635', '1985-03-10', '1998-03-15'),
  ( 20, '4314',       '0601', '1973-09-23', '1998-03-15'),   -- Biot
  ( 20, '38705',      '0647', '1973-09-23', '1985-03-10'),   -- Vallauris
  ( 20, '38705',      '0635', '1985-03-10', '1998-03-15'),
  -- 22 — Cannes
  ( 22, '6806#0649',  '0649', '1973-09-23', '1985-03-10'),
  ( 22, '6806#0606',  '0606', '1973-09-23', '1985-03-10'),
  ( 22, '6806#0649',  '0649', '1985-03-10', '1998-03-15'),
  ( 22, '6806#0606',  '0606', '1985-03-10', '1998-03-15'),
  ( 22, '6806#0636',  '0636', '1985-03-10', '1998-03-15'),
  ( 22, '20874',      '0649', '1973-09-23', '1985-03-10'),   -- Mandelieu-la-Napoule
  ( 22, '20874',      '0636', '1985-03-10', '1998-03-15'),
  ( 22, '37367',      '0649', '1973-09-23', '1985-03-10'),   -- Théoule-sur-Mer
  ( 22, '37367',      '0636', '1985-03-10', '1998-03-15'),
  -- 17 — Manosque
  ( 17, '20929#0413', '0413', '1973-09-23', '1985-03-10'),
  ( 17, '20929#0432', '0432', '1973-09-23', '1985-03-10'),
  ( 17, '20929#0413', '0413', '1985-03-10', '1988-09-25'),
  ( 17, '20929#0432', '0432', '1985-03-10', '1988-09-25'),
  ( 17, '20929#0433', '0433', '1985-03-10', '1988-09-25'),
  ( 17, '10263',      '0432', '1973-09-23', '1988-09-25'),   -- Corbières
  ( 17, '34856',      '0432', '1973-09-23', '1988-09-25'),   -- Sainte-Tulle
  ( 17, '23442',      '0432', '1973-09-23', '1985-03-10'),   -- Montfuron
  ( 17, '23442',      '0433', '1985-03-10', '1988-09-25'),
  ( 17, '26839',      '0432', '1973-09-23', '1985-03-10'),   -- Pierrevert
  ( 17, '26839',      '0433', '1985-03-10', '1988-09-25'),
  -- 40 — Chambéry
  ( 40, '7760#7309',  '7309', '1941-01-01', '1973-09-23'),
  ( 40, '7760#7310',  '7310', '1941-01-01', '1973-09-23'),
  -- 1 — Bourg-en-Bresse
  (  1, '5260#0137',  '0137', '1973-09-23', '1982-01-26'),
  (  1, '5260#0105',  '0105', '1973-09-23', '1982-01-26'),
  (  1, '5260#0138',  '0138', '1973-09-23', '1982-01-26'),
  (  1, '27386',      '0137', '1973-09-23', '1982-01-26'),   -- Polliat
  (  1, '31125',      '0137', '1973-09-23', '1982-01-26'),   -- Saint-Denis-lès-Bourg
  (  1, '40820',      '0105', '1973-09-23', '1982-01-26'),   -- Viriat
  (  1, '6212',       '0138', '1973-09-23', '1982-01-26'),   -- Buellas
  (  1, '19208',      '0138', '1973-09-23', '1982-01-26'),   -- Lent
  (  1, '23054',      '0138', '1973-09-23', '1982-01-26'),   -- Montagnat
  (  1, '23250',      '0138', '1973-09-23', '1982-01-26'),   -- Montcet
  (  1, '23767',      '0138', '1973-09-23', '1982-01-26'),   -- Montracol
  (  1, '26510',      '0138', '1973-09-23', '1982-01-26'),   -- Péronnas
  (  1, '30422',      '0138', '1973-09-23', '1982-01-26'),   -- Saint-André-sur-Vieux-Jonc
  (  1, '34391',      '0138', '1973-09-23', '1982-01-26'),   -- Saint-Rémy
  -- Ajoutées le 20 octobre 2026 : le décret 73-810 les nomme (« …Servas, »
  -- en III ; « Viriat et de Saint-Just » en II), mais `composition_jo.py`
  -- perdait le dernier nom d'une liste en « et de X » et ne les lisait pas.
  -- Même arbitrage que leurs voisines.
  (  1, '36195',      '0138', '1973-09-23', '1982-01-26'),   -- Servas
  (  1, '32737',      '0105', '1973-09-23', '1982-01-26'),   -- Saint-Just
  -- 15 — Gap
  ( 15, '15035#0509', '0509', '1973-09-23', '1982-03-14'),
  ( 15, '15035#0526', '0526', '1973-09-23', '1982-03-14'),
  ( 15, '15035#0529', '0529', '1973-09-23', '1982-03-14'),
  ( 15, '15035#0530', '0530', '1973-09-23', '1982-03-14'),
  -- 52 — Sarcelles
  ( 52, '35344#9523', '9523', '1976-03-07', '1985-03-10'),
  ( 52, '35344#9533', '9533', '1976-03-07', '1985-03-10'),
  -- 82 — Montluçon
  ( 82, '23649#0331', '0331', '1973-09-23', '1982-03-14'),
  ( 82, '23649#0320', '0320', '1973-09-23', '1985-03-10'),
  ( 82, '23649#0321', '0321', '1973-09-23', '1985-03-10'),
  ( 82, '23649#0332', '0332', '1973-09-23', '1985-03-10'),
  ( 82, '23649#0331', '0331', '1982-03-14', '1985-03-10'),
  ( 82, '23649#0334', '0334', '1982-03-14', '1985-03-10'),
  ( 82, '11945',      '0331', '1973-09-23', '1982-03-14'),   -- Domérat
  ( 82, '11945',      '0334', '1982-03-14', '1985-03-10'),
  ( 82, '34923',      '0331', '1973-09-23', '1985-03-10'),   -- Saint-Victor
  ( 82, '39103',      '0331', '1973-09-23', '1985-03-10'),   -- Vaux
  -- 101 — Caen-Nord de 1967
  (101, '6530#1439',  '1439', '1968-01-01', '1973-09-23');

CREATE TEMP TABLE t115_nom (par int, unit_id text, nom text, du date, au date);
INSERT INTO t115_nom VALUES
  ( 20, '0601', 'Antibes-Nord',               '1973-09-23', '1985-03-10'),
  ( 20, '0601', 'Antibes-Biot',               '1985-03-10', '1999-01-01'),
  ( 20, '0647', 'Antibes-Sud',                '1973-09-23', '1985-03-10'),
  ( 20, '0647', 'Antibes-Centre',             '1985-03-10', '1999-01-01'),
  ( 20, '0635', 'Vallauris-Antibes-Ouest',    '1985-03-10', '1999-01-01'),
  ( 22, '0649', 'Cannes-Ouest',               '1973-09-23', '1985-03-10'),
  ( 22, '0649', 'Cannes-Centre',              '1985-03-10', '1999-01-01'),
  ( 22, '0606', 'Cannes-Est',                 '1973-09-23', '1999-01-01'),
  ( 22, '0636', 'Mandelieu-Cannes-Ouest',     '1985-03-10', '1999-01-01'),
  ( 17, '0413', 'Manosque-Nord',              '1973-09-23', '1999-01-01'),
  ( 17, '0432', 'Manosque-Sud',               '1973-09-23', '1985-03-10'),
  ( 17, '0432', 'Manosque-Sud-Est',           '1985-03-10', '1999-01-01'),
  ( 17, '0433', 'Manosque-Sud-Ouest',         '1985-03-10', '1999-01-01'),
  (  1, '0137', 'Bourg-en-Bresse-I',          '1973-09-23', '1982-01-26'),
  (  1, '0105', 'Bourg-en-Bresse-II',         '1973-09-23', '1982-01-26'),
  (  1, '0138', 'Bourg-en-Bresse-III',        '1973-09-23', '1982-01-26'),
  ( 15, '0509', 'Gap-Campagne',               '1973-09-23', '1999-01-01'),
  ( 15, '0529', 'Gap-Est',                    '1973-09-23', '1982-03-14'),
  ( 15, '0530', 'Gap-Ouest',                  '1973-09-23', '1982-03-14'),
  ( 52, '9523', 'Sarcelles-Est',              '1976-03-07', '1985-03-10'),
  ( 52, '9533', 'Sarcelles-Saint-Brice',      '1976-03-07', '1985-03-10'),
  ( 82, '0331', 'Montluçon-Nord',             '1973-09-23', '1982-03-14');

\echo ''
\echo '=== 1. Ce qui sera fait, par entrée ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t115_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t115_retire GROUP BY 1
UNION ALL SELECT par, 'borne', count(*), min(du), max(au) FROM t115_borne GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t115_pose GROUP BY 1
UNION ALL SELECT par, 'nom', count(*), min(du), max(au) FROM t115_nom GROUP BY 1
ORDER BY 1, 2;
-- Attendu au premier passage : 61 poses, 22 noms, rien d'autre.

-- ---------------------------------------------------------------------------
-- 5. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p115_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    SELECT count(*) INTO n FROM t115_unite;
    IF n <> 0 THEN RAISE EXCEPTION 'UNITÉ : % ligne(s) à changer, 35 attendues '
                                    '(30 à Rennes, 2 pour Javrezac, 3 à Nice).', n; END IF;
    SELECT count(*) INTO n FROM t115_retire;
    IF n <> 0 THEN RAISE EXCEPTION 'RETRAIT : % ligne(s), 22 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t115_borne;
    IF n <> 0 THEN RAISE EXCEPTION 'AUBAGNE : % borne(s) à déplacer, 13 attendues.', n; END IF;

    SELECT count(*) INTO n FROM t115_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t115_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % unité(s) inconnues.', n; END IF;
    -- Une fraction porte le code de son canton : `X#NNNN` ne va que dans NNNN.
    SELECT count(*) INTO n FROM t115_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) posées hors de leur canton.', n; END IF;
    -- Les poses ne se recouvrent pas entre elles…
    SELECT count(*) INTO n FROM t115_pose a JOIN t115_pose b
        ON a.atom_id = b.atom_id AND a.ctid < b.ctid
       AND daterange(a.du, a.au, '[)') && daterange(b.du, b.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % paire(s) de poses se recouvrent.', n; END IF;
    -- … et la période de chacune doit être libre, hors ce qui va être retiré.
    SELECT count(*) INTO n FROM t115_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM t115_retire r WHERE r.membership_id = m.membership_id);
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 2 ci-dessous).', n;
    END IF;
    -- Chaque pose doit TOUCHER une période existante du même atome, à gauche
    -- ou à droite : on comble un trou, on ne pose pas une période isolée.
    SELECT count(*) INTO n FROM t115_pose p
     WHERE p.atom_id NOT IN ('40820', '6212')   -- Viriat, Buellas : trou avant, Bourg-Couronne (sans unité) après
       AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                          AND (m.valid_to = p.du OR m.valid_from = p.au))
       AND NOT EXISTS (SELECT 1 FROM t115_pose q WHERE q.atom_id = p.atom_id
                          AND (q.au = p.du OR q.du = p.au))
       -- … sauf la fraction oubliée de 1968 : ses sœurs ont déjà la période.
       AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.niveau = 'canton'
                          AND m.atom_id <> p.atom_id AND m.atom_id LIKE '%#%'
                          AND split_part(m.atom_id, '#', 1) = split_part(p.atom_id, '#', 1)
                          AND m.valid_from = p.du);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) isolées, sans voisine.', n; END IF;

    SELECT count(*) INTO n FROM t115_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t115_nom p WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % unité(s) inconnues.', n; END IF;

END $$;

\echo ''
\echo '=== 2. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t115_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p115_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text)
  AND  NOT EXISTS (SELECT 1 FROM t115_retire r WHERE r.membership_id = m.membership_id);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 6. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p115_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t115_unite;
UPDATE membership m SET unit_id = u.apres FROM t115_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p115_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t115_retire;
DELETE FROM membership m USING t115_retire r WHERE r.membership_id = m.membership_id;

-- Aubagne : les fins reculent d'abord, les débuts ensuite — jamais de
-- chevauchement entre l'atome entier et ses fractions.
INSERT INTO p115_trace (quoi, cle, avant)
SELECT 'membership_borne', membership_id::text, valid_from || '|' || valid_to FROM t115_borne;
UPDATE membership m SET valid_to = b.au FROM t115_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_to <> b.au;
UPDATE membership m SET valid_from = b.du FROM t115_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_from <> b.du;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t115_pose
    RETURNING membership_id
)
INSERT INTO p115_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t115_nom
    RETURNING unit_version_id
)
INSERT INTO p115_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Écrit ==='
SELECT quoi, count(*) FROM p115_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 7. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recette : chaque canton du lot au milieu de chaque période posée ==='
WITH dates AS (
    SELECT DISTINCT par, unit_id, (du + (au - du) / 2) AS d FROM t115_pose
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
  AND  split_part(f.atom_id, '#', 1) IN (SELECT DISTINCT split_part(atom_id, '#', 1) FROM t115_pose);
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

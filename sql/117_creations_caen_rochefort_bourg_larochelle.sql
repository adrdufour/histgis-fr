-- ============================================================================
-- histgis — 117_creations_caen_rochefort_bourg_larochelle.sql : ce que les
--           lots 114 à 116 ne pouvaient pas faire sans créer
--
--   psql -d histgis -f sql/117_creations_caen_rochefort_bourg_larochelle.sql      -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/117_creations_caen_rochefort_bourg_larochelle.sql
--
-- ACCORD D'ADRIEN, 13 octobre 2026 : « tu peux créer pour Caen, Rochefort,
-- Bourg-Couronne […] pour La Rochelle on déplace ».
--
--   CAEN (n° 101) — décret 73-763 : Caen-V de 1973 est une part de la ville
--     seule (404 ha), que l'unité 1441 portera (elle devient Hérouville-Saint-
--     Clair (Caen-V) en 1982). Fraction `6530#1441` CRÉÉE, posée de 1973 à
--     1982. Avec elle : `#1408` (I), `#1409` (II), `#1439` (III), `#1442` (VI)
--     de 1973 à 1982, et les neuf fractions du décret 82-132 de 1982 à 1998.
--   ROCHEFORT (n° 107 a) — loi du 29 juin 1852 : avant elle un seul canton.
--     Unité `C17-Rochefort` CRÉÉE ; la ville entière et les communes des deux
--     cantons y sont de 1815 au 1852-06-29 ; les fractions et les communes ne
--     commencent dans Rochefort-Nord et -Sud qu'à cette date.
--   BOURG-COURONNE (n° 2) — décret 82-77, supprimé le 24 décembre 1984 :
--     unité `C01-Bourg-Couronne` CRÉÉE, onze communes du 1982-01-26 au
--     1985-03-10 ; Viriat dans son canton (0143) de 1985 à 1998.
--   LA ROCHELLE (n° 110 a, c) — les neuf fractions de 1985 étaient accrochées
--     à l'atome de Laleu (`18407`, commune réunie en 1880) : elles passent sur
--     `29365`, La Rochelle (sept fractions créées, les appartenances changent
--     d'atome). Puis les cantons I à IV de 1973 et I à VI de 1982, par numéro
--     (I = 1723, II = 1724, III = 1741, IV = 1742, V = 1744, VI = 1745).
--     Les ancres de `cartes/coupes_ville_ancres.csv` suivent (`29365#…`).
--
-- Après `116`, AVANT `98`. RÉVERSIBLE ET REJOUABLE : `p117_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p117_trace (
    quoi  text NOT NULL,   -- unit | atom | membership_atome | membership_borne | membership_pose | unit_version_pose
    cle   text NOT NULL,
    avant text,
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- 0. Défaire le passage précédent
DELETE FROM unit_version v USING p117_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p117_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
UPDATE membership m SET valid_from = t.avant::date FROM p117_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text;
UPDATE membership m SET atom_id = t.avant FROM p117_trace t
 WHERE t.quoi = 'membership_atome' AND t.cle = m.membership_id::text;
DELETE FROM atom a USING p117_trace t WHERE t.quoi = 'atom' AND t.cle = a.atom_id;   -- atom_geom suit (cascade)
DELETE FROM unit u USING p117_trace t WHERE t.quoi = 'unit' AND t.cle = u.unit_id;
TRUNCATE p117_trace;
\else
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée.'
SELECT quoi, count(*) FROM p117_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t117_unit, t117_atom, t117_atome, t117_borne, t117_pose, t117_nom;

CREATE TEMP TABLE t117_unit (unit_id text, dep text, nom text);
INSERT INTO t117_unit VALUES ('C17-Rochefort', '17', 'Rochefort'), ('C01-Bourg-Couronne', '01', 'Bourg-Couronne');

-- Les fractions à créer : même forme et même source que leur sœur.
CREATE TEMP TABLE t117_atom (atom_id text, soeur text);
INSERT INTO t117_atom VALUES ('6530#1441', '6530#1440'),
  ('29365#1741', '29365#1723'), ('29365#1742', '29365#1723'), ('29365#1744', '29365#1723'),
  ('29365#1745', '29365#1723'), ('29365#1748', '29365#1723'), ('29365#1749', '29365#1723'),
  ('29365#1750', '29365#1723');

-- La Rochelle : toute appartenance d'une fraction de Laleu passe sur La Rochelle.
CREATE TEMP TABLE t117_atome AS
SELECT m.membership_id, m.atom_id AS avant, '29365#' || split_part(m.atom_id, '#', 2) AS apres,
       m.niveau, m.valid_from, m.valid_to
FROM   membership m WHERE m.atom_id LIKE '18407#17%';

-- Rochefort : ce qui commence trop tôt dans Rochefort-Nord et -Sud.
CREATE TEMP TABLE t117_borne AS
SELECT m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id IN ('1721', '1722')
  AND  m.valid_from < DATE '1852-06-29' AND m.valid_to > DATE '1852-06-29';

CREATE TEMP TABLE t117_pose (par int, atom_id text, unit_id text, du date, au date);
-- Rochefort avant 1852 : la ville entière, et chaque commune à la place de ce qu'on raccourcit
INSERT INTO t117_pose
SELECT DISTINCT 107, split_part(b.atom_id, '#', 1), 'C17-Rochefort', b.valid_from, DATE '1852-06-29'
FROM   t117_borne b;
INSERT INTO t117_pose VALUES
  -- Bourg-Couronne
  (  2, '26510', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Péronnas
  (  2, '6212',  'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Buellas
  (  2, '19208', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Lent
  (  2, '23250', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Montcet
  (  2, '23767', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Montracol
  (  2, '27386', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Polliat
  (  2, '30422', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Saint-André-sur-Vieux-Jonc
  (  2, '34391', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Saint-Rémy
  (  2, '36195', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Servas
  (  2, '38807', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Vandeins
  (  2, '40820', 'C01-Bourg-Couronne', '1982-01-26', '1985-03-10'),   -- Viriat
  (  2, '40820', '0143',               '1985-03-10', '1998-03-15'),
  -- Caen 1973-1982
  (101, '6530#1408', '1408', '1973-09-23', '1982-03-14'),
  (101, '6530#1409', '1409', '1973-09-23', '1982-03-14'),
  (101, '6530#1439', '1439', '1973-09-23', '1982-03-14'),
  (101, '6530#1441', '1441', '1973-09-23', '1982-03-14'),
  (101, '6530#1442', '1442', '1973-09-23', '1982-03-14'),
  -- Caen 1982-1998
  (101, '6530#1408', '1408', '1982-03-14', '1998-03-15'),
  (101, '6530#1409', '1409', '1982-03-14', '1998-03-15'),
  (101, '6530#1439', '1439', '1982-03-14', '1998-03-15'),
  (101, '6530#1440', '1440', '1982-03-14', '1998-03-15'),
  (101, '6530#1442', '1442', '1982-03-14', '1998-03-15'),
  (101, '6530#1443', '1443', '1982-03-14', '1998-03-15'),
  (101, '6530#1444', '1444', '1982-03-14', '1998-03-15'),
  (101, '6530#1445', '1445', '1982-03-14', '1998-03-15'),
  (101, '6530#1446', '1446', '1982-03-14', '1998-03-15'),
  -- La Rochelle 1973-1982 et 1982-1985
  (110, '29365#1723', '1723', '1973-09-23', '1982-03-14'),
  (110, '29365#1724', '1724', '1973-09-23', '1982-03-14'),
  (110, '29365#1741', '1741', '1973-09-23', '1982-03-14'),
  (110, '29365#1742', '1742', '1973-09-23', '1982-03-14'),
  (110, '29365#1723', '1723', '1982-03-14', '1985-03-10'),
  (110, '29365#1724', '1724', '1982-03-14', '1985-03-10'),
  (110, '29365#1741', '1741', '1982-03-14', '1985-03-10'),
  (110, '29365#1742', '1742', '1982-03-14', '1985-03-10'),
  (110, '29365#1744', '1744', '1982-03-14', '1985-03-10'),
  (110, '29365#1745', '1745', '1982-03-14', '1985-03-10');

CREATE TEMP TABLE t117_nom (par int, unit_id text, nom text, du date, au date);
INSERT INTO t117_nom VALUES (101, '1441', 'Caen-V', '1973-09-23', '1982-03-14');

\echo '=== 1. Ce qui sera fait ==='
SELECT 'unités créées' quoi, count(*) FROM t117_unit
UNION ALL SELECT 'fractions créées', count(*) FROM t117_atom
UNION ALL SELECT 'appartenances changées d''atome (La Rochelle)', count(*) FROM t117_atome
UNION ALL SELECT 'bornes (Rochefort 1852)', count(*) FROM t117_borne
UNION ALL SELECT 'poses', count(*) FROM t117_pose
UNION ALL SELECT 'noms', count(*) FROM t117_nom;
\echo '=== 2. Rochefort : ce qui est raccourci au 1852-06-29 ==='
SELECT atom_id, unit_id, valid_from, valid_to FROM t117_borne ORDER BY 2, 1;

DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p117_trace) THEN
        RAISE NOTICE 'Trace non vide : garde-fous sautés.'; RETURN;
    END IF;
    SELECT count(*) INTO n FROM t117_unit t JOIN unit u USING (unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'UNITÉ : % existe(nt) déjà.', n; END IF;
    SELECT count(*) INTO n FROM t117_atom t JOIN atom a USING (atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'FRACTION : % existe(nt) déjà.', n; END IF;
    SELECT count(*) INTO n FROM t117_atom t WHERE NOT EXISTS (SELECT 1 FROM atom_geom g WHERE g.atom_id = t.soeur);
    IF n > 0 THEN RAISE EXCEPTION 'FRACTION : % sœur(s) sans géométrie.', n; END IF;
    SELECT count(*) INTO n FROM t117_atome;
    IF n = 0 THEN RAISE EXCEPTION 'LA ROCHELLE : aucune appartenance sur 18407#17… — déjà déplacées ?'; END IF;
    SELECT count(*) INTO n FROM t117_borne WHERE atom_id IN ('29352#1721', '29352#1722');
    IF n <> 2 THEN RAISE EXCEPTION 'ROCHEFORT : % fraction(s) à raccourcir, 2 attendues.', n; END IF;
    -- Une pose ne recouvre rien, hors ce qui va être raccourci (Rochefort).
    SELECT count(*) INTO n FROM t117_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM t117_borne b WHERE b.membership_id = m.membership_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) déjà occupée(s).', n; END IF;
    SELECT count(*) INTO n FROM t117_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) hors de leur canton.', n; END IF;
END $$;

\echo '=== 3. Périodes à poser déjà occupées (attendu : aucune ligne) ==='
SELECT p.par, p.atom_id, p.du, p.au, m.unit_id, m.periode
FROM   t117_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM t117_borne b WHERE b.membership_id = m.membership_id)
  AND  NOT EXISTS (SELECT 1 FROM p117_trace t WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text);

\if :{?appliquer}
INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
SELECT unit_id, 'canton', dep, unit_id, NULL, NULL, nom, true FROM t117_unit;
INSERT INTO p117_trace (quoi, cle) SELECT 'unit', unit_id FROM t117_unit;

INSERT INTO atom (atom_id, cassini, fraction, insee_geofla)
SELECT t.atom_id, s.cassini, true, s.insee_geofla FROM t117_atom t JOIN atom s ON s.atom_id = t.soeur;
INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT t.atom_id, g.geom, g.source, true FROM t117_atom t JOIN atom_geom g ON g.atom_id = t.soeur;
INSERT INTO p117_trace (quoi, cle) SELECT 'atom', atom_id FROM t117_atom;

INSERT INTO p117_trace (quoi, cle, avant) SELECT 'membership_atome', membership_id::text, avant FROM t117_atome;
UPDATE membership m SET atom_id = a.apres FROM t117_atome a WHERE a.membership_id = m.membership_id;

INSERT INTO p117_trace (quoi, cle, avant) SELECT 'membership_borne', membership_id::text, valid_from::text FROM t117_borne;
UPDATE membership m SET valid_from = DATE '1852-06-29' FROM t117_borne b WHERE b.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t117_pose RETURNING membership_id)
INSERT INTO p117_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;
WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t117_nom RETURNING unit_version_id)
INSERT INTO p117_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;
ANALYZE membership;
\echo '=== 4. Écrit ==='
SELECT quoi, count(*) FROM p117_trace GROUP BY 1 ORDER BY 1;
\endif

\echo '=== 5. Atome entier et fractions en même temps (attendu : aucune ligne) ==='
SELECT e.atom_id AS entier, e.unit_id, e.periode, f.atom_id AS fraction, f.periode AS periode_fraction
FROM   membership f
JOIN   membership e ON e.niveau = 'canton' AND e.atom_id = split_part(f.atom_id, '#', 1)
                   AND e.periode && f.periode
WHERE  f.niveau = 'canton' AND f.atom_id LIKE '%#%'
  AND  split_part(f.atom_id, '#', 1) IN ('6530', '29352', '29365', '18407');

\if :{?appliquer}
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

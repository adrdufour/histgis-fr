-- ============================================================================
-- histgis — 109_ville_angouleme.sql : Angoulême de 1941 à 1982, deux fractions
--           en continu, et les noms de 1973 et de 1982
--
--   psql -d histgis -f sql/109_ville_angouleme.sql                      -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/109_ville_angouleme.sql
--
-- Inscrit l'entrée n° 77 de `cartes/a_inscrire_en_base.md`, à la demande
-- d'Adrien (10 octobre 2026). Même modèle que `108` ; à jouer AVANT `98`.
--
-- LES TEXTES
-- ==========
-- Deux cantons, Angoulême-1 et Angoulême-2, jusqu'en 1973 (limite fixée le
-- 16 mai 1863, `cantons/chronologie_cantonale.csv`).
-- Décret n° 73-654 du 13 juillet 1973 (JO du 17 juillet 1973,
-- `jorf_txt/JORF_19730717_164_col.txt`, l. 1209-1219) : Angoulême-Ville-I et
-- Angoulême-Ville-II sont « la portion de territoire de la ville d'Angoulême
-- comprise dans l'ancien premier (deuxième) canton » — la limite dans la ville
-- ne change pas ; les communes rurales vont à La Couronne, Ruelle et Soyaux.
-- Décret n° 82-25 du 15 janvier 1982 (JO du 16 janvier 1982,
-- `jorf_txt/JORF_19820116_13_col.txt`, l. 938-990) : Angoulême-Ouest, -Est et
-- -Nord remplacent les deux cantons. Codes du COG : 1602 = Est, 1603 = Nord,
-- 1634 = Ouest. Avant 1982, 1602 est le 1er canton (l'ouest et le sud de la
-- ville) et 1603 le 2e (l'est et le nord) : le code 1602 change de secteur en
-- 1982, les ancres des lignes de coupe sont donc datées.
--
-- CE QUE LA BASE AVAIT
-- ====================
--   1815-1941  `853#1602` et `853#1603`                       juste
--   1941-1968  rien pour la ville
--   1968-1973  l'atome entier 853 dans 1603 (Angoulême-2)     artefact du COG
--   1973-1982  rien
--   1982-2013  `853#1602`, `#1603`, `#1634`                   juste
--
--   § 1  l'atome entier 853 quitte 1603 sur 1968 → 1973-09-23 ;
--   § 2  les fractions `853#1602` et `853#1603` reçoivent 1941 → 1973-09-23 et
--        1973-09-23 → 1982-03-14 ;
--   § 3  les noms : Angoulême-Ville-I et -Ville-II (1973-09-23 → 1982-03-14),
--        Angoulême-Est, -Nord et -Ouest dès le 1982-03-14 (`unit_version` ne
--        les avait qu'à partir de 1999).
--
-- Réversible et rejouable : `p109_trace`. Ensuite `98` sous `appliquer`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p109_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_retire | unit_version_pose
    cle   text NOT NULL,
    avant text,            -- 'atome|unité|du|au' pour un retrait
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
DELETE FROM unit_version v USING p109_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p109_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p109_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p109_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est déjà corrigée.'
SELECT quoi, count(*) FROM p109_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t109_retire, t109_pose, t109_nom;

CREATE TEMP TABLE t109_retire AS
SELECT m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.atom_id = '853' AND m.unit_id = '1603'
  AND  m.periode <@ daterange(DATE '1941-01-01', DATE '1982-03-14', '[)');

CREATE TEMP TABLE t109_pose (atom_id text, unit_id text, du date, au date);
INSERT INTO t109_pose VALUES
  -- coupé au 1973-09-23 : la limite ne change pas, mais le canton change de nom
  -- et perd ses communes rurales ; une ligne par régime, comme partout ailleurs
  ('853#1602', '1602', '1941-01-01', '1973-09-23'),
  ('853#1603', '1603', '1941-01-01', '1973-09-23'),
  ('853#1602', '1602', '1973-09-23', '1982-03-14'),
  ('853#1603', '1603', '1973-09-23', '1982-03-14');

CREATE TEMP TABLE t109_nom (unit_id text, nom text, du date, au date);
INSERT INTO t109_nom VALUES
  ('1602', 'Angoulême-Ville-I',  '1973-09-23', '1982-03-14'),
  ('1603', 'Angoulême-Ville-II', '1973-09-23', '1982-03-14'),
  ('1602', 'Angoulême-Est',      '1982-03-14', '1999-01-01'),
  ('1603', 'Angoulême-Nord',     '1982-03-14', '1999-01-01'),
  ('1634', 'Angoulême-Ouest',    '1982-03-14', '1999-01-01');

\echo ''
\echo '=== 1. Ce qui sera fait ==='
SELECT 'retiré' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au FROM t109_retire
UNION ALL SELECT 'posé', count(*), min(du), max(au) FROM t109_pose
UNION ALL SELECT 'nom', count(*), min(du), max(au) FROM t109_nom;
-- Attendu au premier passage : 2 retirés (1968 → 1973-09-23), 4 posés, 5 noms.

DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p109_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;
    SELECT count(*) INTO n FROM t109_retire;
    IF n <> 2 THEN RAISE EXCEPTION '§ 1 : % ligne(s) à retirer, 2 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t109_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION '§ 2 : % appartenance(s) occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t109_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION '§ 3 : % version(s) d''unité occupent déjà la période.', n; END IF;
    -- Le témoin des codes : en 1990, chacune des trois unités ne porte que sa fraction.
    SELECT count(*) INTO n FROM membership m
     WHERE m.niveau = 'canton' AND m.unit_id IN ('1602', '1603', '1634')
       AND m.periode @> DATE '1990-01-01' AND m.atom_id LIKE '853#%';
    IF n <> 3 THEN RAISE EXCEPTION 'TÉMOIN : % fraction(s) d''Angoulême en 1990, 3 attendues.', n; END IF;
END $$;

\if :{?appliquer}
INSERT INTO p109_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t109_retire;
DELETE FROM membership m USING t109_retire r WHERE r.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t109_pose
    RETURNING membership_id
)
INSERT INTO p109_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t109_nom
    RETURNING unit_version_id
)
INSERT INTO p109_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 2. Écrit ==='
SELECT quoi, count(*) FROM p109_trace GROUP BY 1 ORDER BY 1;
\endif

\echo ''
\echo '=== 3. Recette : la ville à une date de chaque régime ==='
SELECT d.d AS a_la_date, m.atom_id, m.unit_id, coalesce(v.nom, u.nom) AS canton
FROM   (VALUES (DATE '1900-01-01'), (DATE '1960-01-01'), (DATE '1970-01-01'),
               (DATE '1975-01-01'), (DATE '1990-01-01')) d(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d.d AND m.atom_id ~ '^853(#|$)'
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN unit_version v ON v.unit_id = m.unit_id AND v.periode @> d.d
ORDER  BY 1, 2;
-- Attendu après application : deux fractions jusqu'en 1982 (jamais l'atome
-- entier 853), trois ensuite ; Ville-I et Ville-II en 1975 ; Est, Nord et
-- Ouest en 1990.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\echo '          python3 cartes/export_web.py 16 --partition --role histgis_carte'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

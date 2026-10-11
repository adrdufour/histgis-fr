-- ============================================================================
-- histgis — 108_villes_aurillac_falaise_saintflour.sql : ce que la découpe de
--           trois villes a montré de faux ou de manquant dans les cantons
--
--   psql -d histgis -f sql/108_villes_aurillac_falaise_saintflour.sql       -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/108_villes_aurillac_falaise_saintflour.sql
--
-- Inscrit les entrées n° 97, 103 et 104 de `cartes/a_inscrire_en_base.md`,
-- à la demande d'Adrien (10 octobre 2026). À jouer APRÈS `107` et AVANT `98` :
-- `98` juge les villes sur les appartenances de leurs fractions.
--
-- FALAISE (14258) — n° 97 : Nord et Sud intervertis de 1815 à 1941
-- ================================================================
-- Arrêté du 6 brumaire an X (Bulletin des lois, 3e série, t. 4, n° 129, acte
-- n° 986) : la 1re partie a Damblainville, Eraines, Fresné-la-Mère, La
-- Hoguette, Ners, Pertheville, Versainville, Villy ; la 2e Aubigny, Potigny,
-- Soulangy… Conseil général du 28 août 1856 et décret du 27 novembre 1859 :
-- la 1re prend le nom de Falaise-Sud, la 2e de Falaise-Nord.
--
-- La base donne les huit communes de la 1re partie à 1417 « Falaise-Nord » de
-- 1815 à 1941, et à 1418 « Falaise-Sud » à partir de 1954 — ce qui est juste.
-- Aucun acte entre les deux : c'est la nomenclature de 1940 qui croise les
-- deux codes, pas un transfert (`71` l'avait relevé comme « échange croisé »).
--
--   § F1  les communes entières de 1417 et 1418 échangent leur unité sur toute
--         appartenance close au plus tard le 1er janvier 1941 (66 lignes) ;
--   § F2  les deux FRACTIONS de la ville ne sont pas échangées : `13442#1417`
--         reste dans 1417, qui redevient le vrai Nord. C'est la ligne de coupe
--         qui change d'ancres (`14258-1`, une seule ligne de 1815 à 2013) ;
--   § F3  les fractions reçoivent les appartenances qui leur manquent,
--         1941 → 1968 et 1973-09-23 → 1998-03-15 : régime continu de l'an X à
--         2015, aucun acte dans `cantons/chronologie_cantonale.csv`.
--
-- Ce que ce fichier NE fait PAS pour Falaise : retirer les deux « transferts »
-- 1940-1999 de `cantons/mouvements_cantonaux.csv` (l. 211-212). Ce CSV est
-- produit par `33` à partir de la base ; il se corrigera en rejouant `33`, puis
-- `72` qui le charge. Ni combler 1941-1954 pour les 35 communes rurales : c'est
-- le trou général, suivi par `93` et `97`, qui s'arrêtaient sur ce désaccord
-- des deux bouts et le lèveront d'eux-mêmes au prochain passage.
--
-- SAINT-FLOUR (15187) — n° 104 : deux fractions en continu
-- ========================================================
-- Arrêté du 27 vendémiaire an X (Bulletin des lois, an X, n° 935) : « le
-- Faubourg » au Nord, « la Ville » au Sud. Aucun acte avant 2014.
--
--   § S1  l'atome entier 31781 quitte Saint-Flour-Nord sur 1968 → 1973-09-23
--         (artefact du COG de 1968 : une commune, un code de canton) ;
--   § S2  les fractions `31781#1519` et `#1520` reçoivent 1941 → 1985-03-10.
--
-- AURILLAC (15014) — n° 103 : quatre cantons de 1973 à 1985
-- =========================================================
-- Décrets n° 73-716 (JO du 25 juillet 1973), 82-51 (JO du 22 janvier 1982),
-- 85-73 (JO du 23 janvier 1985), tous trois dans `jorf_txt/`.
--   1973 : I (Crandelles, Jussac, Naucelles-Reilhac, Teissières-de-Cornet),
--          II (Saint-Paul-des-Landes, Sansac-de-Marmiesse, Ytrac),
--          III (Arpajon-sur-Cère, Labrousse, Prunet, Vézac, Vezels-Roussy),
--          IV (Giou-de-Mamou, Laroquevieille, Lascelle, Mandailles, Marmanhac,
--          Saint-Cirgues-de-Jordanne, Saint-Simon, Velzic, Yolet) ;
--   1982 : Arpajon-sur-Cère sort du III, qui n'a plus que sa part de ville ;
--   1985 : Jussac sort du I, qui n'a plus que sa part de ville.
-- Codes : 1502 = I, 1503 = II, 1524 = III, 1525 = IV (lu sur 1985 : 1503 porte
-- Saint-Paul, Sansac et Ytrac, 1502 la seule fraction, comme le décret).
--
--   § A1  l'atome entier 1915 quitte Aurillac-Nord sur 1968 → 1973-09-23 ;
--   § A2  fractions `1915#1502` (Nord) et `#1503` (Sud) sur 1941 → 1973-09-23 ;
--   § A3  quatre fractions sur 1973-09-23 → 1985-03-10 ;
--   § A4  Crandelles, Jussac, Naucelles, Teissières-de-Cornet : de 1527 (Jussac,
--         créé en 1985) à 1502, sur 1973-09-23 → 1985-03-10 ;
--   § A5  Arpajon, Labrousse, Prunet, Vézac, Vezels-Roussy : de 1526 (Arpajon,
--         créé en 1982) à 1524, sur 1973-09-23 → 1982-03-14 ;
--   § A6  Reilhac (atome 28822) : fondue dans Naucelles-Reilhac, sans canton en
--         base de 1973 à 1985 ; posée dans 1502 sur 1973-09-23 → 1985-03-10 ;
--   § A7  les noms : `unit_version` n'a rien entre 1941 et 1999. Aurillac-I à
--         IV (1973), I-Nord, II-Ouest, III-Sud (1982), I à III (1985-1999).
--
-- RÉVERSIBLE ET REJOUABLE : `p108_trace` porte ce qui a été posé, ce qui a
-- changé d'unité (avec l'ancienne) et ce qui a été retiré (avec son contenu).
-- Sous `appliquer`, le passage précédent est défait avant tout calcul.
--
-- Ensuite : `98` sous `appliquer` (recette des villes), puis l'export des
-- départements 14 et 15.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p108_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité, ou 'atome|unité|du|au' pour un retrait
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p108_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p108_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
UPDATE membership m SET unit_id = t.avant FROM p108_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p108_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p108_trace;
\else
\echo ''
\echo '=== À blanc : si la trace ci-dessous n est pas vide, la base est DÉJÀ corrigée'
\echo '=== et les comptes qui suivent décrivent un second passage, pas le premier.'
SELECT quoi, count(*) FROM p108_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t108_unite, t108_retire, t108_pose, t108_nom;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t108_unite AS
-- § F1 — Falaise : les communes entières, tout ce qui se clôt avant 1941
SELECT 'F1' AS par, m.membership_id, m.atom_id, m.unit_id AS avant,
       CASE m.unit_id WHEN '1417' THEN '1418' ELSE '1417' END AS apres,
       m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id IN ('1417', '1418')
  AND  m.valid_to <= DATE '1941-01-01'
  AND  m.atom_id NOT LIKE '%#%'
UNION ALL
-- § A4 — Aurillac-I avant Jussac
SELECT 'A4', m.membership_id, m.atom_id, m.unit_id, '1502', m.valid_from, m.valid_to
FROM   membership m JOIN atom a USING (atom_id)
WHERE  m.niveau = 'canton' AND m.unit_id = '1527'
  AND  a.insee_geofla IN ('15056', '15083', '15140', '15233')
  AND  m.periode <@ daterange(DATE '1973-09-23', DATE '1985-03-10', '[)')
UNION ALL
-- § A5 — Aurillac-III avant Arpajon-sur-Cère
SELECT 'A5', m.membership_id, m.atom_id, m.unit_id, '1524', m.valid_from, m.valid_to
FROM   membership m JOIN atom a USING (atom_id)
WHERE  m.niveau = 'canton' AND m.unit_id = '1526'
  AND  a.insee_geofla IN ('15012', '15085', '15156', '15255', '15257')
  AND  m.periode <@ daterange(DATE '1973-09-23', DATE '1982-03-14', '[)');

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré : l'atome entier là où la ville a deux cantons
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t108_retire AS
SELECT CASE m.atom_id WHEN '1915' THEN 'A1' ELSE 'S1' END AS par,
       m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  ((m.atom_id = '1915'  AND m.unit_id = '1502')
     OR (m.atom_id = '31781' AND m.unit_id = '1519'))
  AND  m.periode <@ daterange(DATE '1941-01-01', DATE '1973-09-23', '[)');

-- ---------------------------------------------------------------------------
-- 3. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t108_pose (par text, atom_id text, unit_id text, du date, au date);
INSERT INTO t108_pose VALUES
  ('F3', '13442#1417', '1417', '1941-01-01', '1968-01-01'),
  ('F3', '13442#1418', '1418', '1941-01-01', '1968-01-01'),
  ('F3', '13442#1417', '1417', '1973-09-23', '1998-03-15'),
  ('F3', '13442#1418', '1418', '1973-09-23', '1998-03-15'),
  ('S2', '31781#1519', '1519', '1941-01-01', '1985-03-10'),
  ('S2', '31781#1520', '1520', '1941-01-01', '1985-03-10'),
  ('A2', '1915#1502',  '1502', '1941-01-01', '1973-09-23'),
  ('A2', '1915#1503',  '1503', '1941-01-01', '1973-09-23'),
  ('A3', '1915#1502',  '1502', '1973-09-23', '1985-03-10'),
  ('A3', '1915#1503',  '1503', '1973-09-23', '1985-03-10'),
  ('A3', '1915#1524',  '1524', '1973-09-23', '1985-03-10'),
  ('A3', '1915#1525',  '1525', '1973-09-23', '1985-03-10'),
  ('A6', '28822',      '1502', '1973-09-23', '1985-03-10');

CREATE TEMP TABLE t108_nom (unit_id text, nom text, du date, au date);
INSERT INTO t108_nom VALUES
  ('1502', 'Aurillac-I',        '1973-09-23', '1982-03-14'),
  ('1502', 'Aurillac-I-Nord',   '1982-03-14', '1985-03-10'),
  ('1502', 'Aurillac-I',        '1985-03-10', '1999-01-01'),
  ('1503', 'Aurillac-II',       '1973-09-23', '1982-03-14'),
  ('1503', 'Aurillac-II-Ouest', '1982-03-14', '1985-03-10'),
  ('1503', 'Aurillac-II',       '1985-03-10', '1999-01-01'),
  ('1524', 'Aurillac-III',      '1973-09-23', '1982-03-14'),
  ('1524', 'Aurillac-III-Sud',  '1982-03-14', '1985-03-10'),
  ('1524', 'Aurillac-III',      '1985-03-10', '1999-01-01'),
  ('1525', 'Aurillac-IV',       '1973-09-23', '1999-01-01');

\echo ''
\echo '=== 1. Ce qui sera fait, par paragraphe ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t108_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t108_retire GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t108_pose GROUP BY 1
ORDER BY 1;
-- Attendu au premier passage : F1 66, A4 8, A5 5 ; A1 2, S1 2 ; F3 4, S2 2,
-- A2 2, A3 4, A6 1.

\echo ''
\echo '=== 2. Falaise : qui change de canton (communes, 1815-1941) ==='
SELECT u.avant || ' → ' || u.apres AS echange, count(DISTINCT u.atom_id) AS communes,
       string_agg(DISTINCT n.nom, ', ' ORDER BY n.nom) AS noms
FROM   t108_unite u JOIN atom a USING (atom_id)
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  u.par = 'F1' GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; deja boolean;
BEGIN
    SELECT EXISTS (SELECT 1 FROM p108_trace) INTO deja;
    IF deja THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    -- Falaise : l'état fautif doit être celui qu'on corrige. Si Damblainville
    -- (14216) est déjà dans 1418 en 1900, la source a été corrigée en amont et
    -- l'échange referait l'erreur dans l'autre sens.
    SELECT count(*) INTO n FROM membership m JOIN atom a USING (atom_id)
     WHERE m.niveau = 'canton' AND a.insee_geofla = '14216' AND m.atom_id NOT LIKE '%#%'
       AND m.periode @> DATE '1900-01-01' AND m.unit_id = '1417';
    IF n <> 1 THEN
        RAISE EXCEPTION 'FALAISE : Damblainville n''est pas dans 1417 en 1900 (% ligne). '
                        'L''inversion a peut-être été corrigée à la source : retirer le § F1.', n;
    END IF;
    -- … et l'état juste d'après 1968 doit être l'inverse.
    SELECT count(*) INTO n FROM membership m JOIN atom a USING (atom_id)
     WHERE m.niveau = 'canton' AND a.insee_geofla = '14216'
       AND m.periode @> DATE '1970-01-01' AND m.unit_id = '1418';
    IF n <> 1 THEN
        RAISE EXCEPTION 'FALAISE : Damblainville n''est pas dans 1418 en 1970 (% ligne) : '
                        'le témoin de l''inversion a disparu.', n;
    END IF;

    SELECT count(*) INTO n FROM t108_unite WHERE par = 'F1';
    IF n <> 66 THEN RAISE EXCEPTION 'F1 : % lignes à échanger, 66 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t108_unite WHERE par = 'A4';
    IF n <> 8 THEN RAISE EXCEPTION 'A4 : % lignes, 8 attendues (4 communes, 2 périodes).', n; END IF;
    SELECT count(*) INTO n FROM t108_unite WHERE par = 'A5';
    IF n <> 5 THEN RAISE EXCEPTION 'A5 : % lignes, 5 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t108_retire;
    IF n <> 4 THEN RAISE EXCEPTION 'A1 + S1 : % lignes à retirer, 4 attendues.', n; END IF;

    -- La période de chaque pose doit être libre pour son atome.
    SELECT count(*) INTO n FROM t108_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 3 ci-dessous).', n;
    END IF;
    SELECT count(*) INTO n FROM t108_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t108_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
END $$;

\echo ''
\echo '=== 3. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t108_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p108_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 5. Écrire
-- ---------------------------------------------------------------------------
-- 1417 et 1418 s'échangent : aucune contrainte ne porte sur l'unité (l'exclusion
-- est sur l'atome, le niveau et la période), l'échange se fait en un passage.
INSERT INTO p108_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t108_unite;
UPDATE membership m SET unit_id = u.apres FROM t108_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p108_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t108_retire;
DELETE FROM membership m USING t108_retire r WHERE r.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t108_pose
    RETURNING membership_id
)
INSERT INTO p108_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t108_nom
    RETURNING unit_version_id
)
INSERT INTO p108_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 4. Écrit ==='
SELECT quoi, count(*) FROM p108_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 6. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recette : communes et fractions par canton, à une date de chaque régime ==='
SELECT d.d AS a_la_date, m.unit_id, coalesce(v.nom, u.nom) AS canton,
       count(*) FILTER (WHERE m.atom_id NOT LIKE '%#%') AS communes,
       string_agg(m.atom_id, ' ' ORDER BY m.atom_id) FILTER (WHERE m.atom_id LIKE '%#%') AS fractions
FROM   (VALUES (DATE '1900-01-01'), (DATE '1960-01-01'), (DATE '1970-01-01'),
               (DATE '1975-01-01'), (DATE '1983-01-01'), (DATE '1990-01-01')) d(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d.d
                   AND m.unit_id IN ('1417', '1418', '1519', '1520',
                                     '1502', '1503', '1524', '1525', '1526', '1527')
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN unit_version v ON v.unit_id = m.unit_id AND v.periode @> d.d
GROUP  BY 1, 2, 3 ORDER BY 1, 2;
-- Attendu après application :
--   Falaise    1900 : 1417 = 27 communes + #1417 ; 1418 = 8 communes + #1418
--   Aurillac   1975 : 1502 = 4 (+ Reilhac = 5) ; 1503 = 3 ; 1524 = 5 ; 1525 = 9 ;
--                     1526 et 1527 vides
--              1983 : 1502 = 5 ; 1503 = 3 ; 1524 = fraction seule ; 1525 = 9 ; 1526 = 6
--              1990 : 1502 = fraction seule ; 1527 = 5
--   Saint-Flour      : les deux fractions à toutes les dates

\echo ''
\echo '=== 6. Une ville ne doit jamais avoir à la fois son atome entier et ses fractions ==='
SELECT m.atom_id, m.unit_id, m.periode
FROM   membership m
WHERE  m.niveau = 'canton' AND m.atom_id IN ('1915', '31781', '13442');
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\echo '          python3 cartes/export_web.py 14 15 --partition --role histgis_carte'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

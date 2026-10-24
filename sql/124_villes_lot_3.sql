-- ============================================================================
-- histgis — 124_villes_lot_3.sql : quatrième lot de
--           `cartes/a_inscrire_en_base.md` (après `112`, `114`, `115`) — les
--           entrées 111 à 128, écrites
--           du 14 au 21 octobre 2026 en découpant les villes
--
--   psql -d histgis -f sql/124_villes_lot_3.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/124_villes_lot_3.sql
--
-- Inscrit, à la demande d'Adrien (23 octobre 2026 : « met à jour la base avec
-- inscrire en base »), les entrées n° 111 (Vierzon), 112 (Dinan), 113 (Brive),
-- 114 (Guéret), 115 (Périgueux), 116 (Montbéliard), 117 (Montélimar),
-- 118 (Romans), 119 (Crest), 120 (Dijon), 121 (Besançon), 122 (Louviers),
-- 123 (Bernay), 125 (Valence), 126 (Vernon) et 128 (Toulouse). Même modèle
-- que `114` ; même place : après `117`, AVANT `98`.
--
-- La base a bougé depuis l'écriture des entrées : `120` (19 octobre) a comblé
-- par la règle A la plupart des trous de communes rurales qu'elles signalaient
-- (Bethoncourt, Ancône, La Touche, Montmiral, Aouste, Gigors, Saou, Cosnac et
-- Malemort de 1955 à 1968, Caouënnec), et `96` a rendu Bézu-la-Forêt entière
-- à Lyons (n° 124 : plus rien à faire). Ce fichier ne pose que ce qui manque
-- au 23 octobre 2026, et ses garde-fous refusent toute période déjà occupée.
--
-- QUATRE GESTES, comme `114`
-- ==========================
--   posé     les fractions des villes sur le régime du décret ; les communes
--            rurales encore sans canton (Brive-Sud 1951-1954, les communes du
--            sud de Valence 1941/1955-1968, Bourg-lès-Valence et
--            Saint-Marcel 1973-1985, Toulouse IX, XI, XII, XV 1973-1998,
--            Mondonville 1955-1973) ;
--   retiré   l'atome entier là où la ville a ses fractions (Brive 1968-1982,
--            Valence 1968-1973) ; les deux fractions fantômes du COG de 1968
--            rangées dans Lannion (2219) : `11851#2219` (Dinan, ligne de
--            Caouënnec lue sous le code 050) et `17035#2219` (L'Hermitage-Lorge,
--            dont l'atome entier est dans 2234 sur la même période — « à
--            vérifier » dans l'entrée 112, vérifié ici : même défaut), avec
--            sa sœur `17035#2234`, qui double l'atome entier dans son canton ;
--   changé d'unité  Beauzelle, Blagnac, Colomiers, Cornebarrieu, Mondonville
--            de 1973 à 1998 : Toulouse-XIII au décret 73-815 (3148), et non le
--            canton de Blagnac (3151), qui ne naît qu'au décret de 1997 ;
--   borne    la fin de l'atome entier ramenée au décret qui coupe la ville :
--            Brive au 1951-09-13, Valence au 1964-03-08.
--
-- VALENCE 1973 (n° 125 b) : l'entrée tenait la correspondance I / II / III =
-- 2629 / 2630 / 2631 pour SUPPOSÉE. Elle est retenue : le décret 84-1224 garde
-- la même géographie (I au nord contre Bourg, II au sud contre Portes, III à
-- l'est contre Saint-Marcel), et les codes de 1985 sont ceux de ses numéros
-- (2629 = 1er canton, 2630 = 2e, 2631 = 3e, 2636 = 4e créé en 1985).
--
-- DATES : règle de `75` et de `112`, le premier tour qui suit le décret
-- (1964-03-08, 1973-09-23, 1982-03-14, 1985-03-10, 1992-03-22, 1998-03-15) ;
-- Brive au décret du 13 septembre 1951 lui-même, comme ses communes rurales
-- dans la base (et la ligne `19031-51`).
--
-- CE QUE CE FICHIER NE FAIT PAS (reste dans `a_inscrire_en_base.md`)
--   Dreux (n° 127 : deux unités de 1973 à créer) ; Dijon VI à VIII (noms non
--   confirmés par la base) ; Portet, Cugnaux et Tournefeuille du 1998-03-15
--   au 1998-04-01 (leur canton de 1998 commence au COG) ; tout ce qui demande
--   une ligne, un texte ou un arbitrage.
--
-- RÉVERSIBLE ET REJOUABLE : `p124_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p124_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | membership_borne | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité ; 'atome|unité|du|au' pour un retrait ; 'du|au' pour une borne
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p124_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p124_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
-- Les bornes ne font que reculer des fins : on les rend avant de remettre les
-- lignes retirées, qui commencent à l'ancienne fin.
UPDATE membership m SET valid_from = split_part(t.avant, '|', 1)::date,
                        valid_to   = split_part(t.avant, '|', 2)::date
  FROM p124_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text;
UPDATE membership m SET unit_id = t.avant FROM p124_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p124_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p124_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée,'
\echo '=== et les comptes qui suivent décrivent un second passage.'
SELECT quoi, count(*) FROM p124_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t124_unite, t124_retire_v, t124_retire, t124_borne_v, t124_borne, t124_pose, t124_nom;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t124_unite AS
-- n° 128 — Toulouse-XIII (décret 73-815) : Beauzelle, Blagnac, Colomiers,
-- Cornebarrieu, Mondonville et une part de la ville ; Blagnac (3151) est du
-- décret de 1997.
SELECT 128 AS par, m.membership_id, m.atom_id, m.unit_id AS avant, '3148'::text AS apres,
       m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id = '3151'
  AND  m.atom_id IN ('2594', '4388', '9948', '10343', '22893')
  AND  m.periode <@ daterange(DATE '1973-09-23', DATE '1998-03-15', '[)');

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t124_retire_v (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t124_retire_v VALUES
  (112, '11851#2219', '2219', '1968-01-01', '1982-03-14'),   -- Dinan dans Lannion (Caouënnec lue 050)
  (112, '17035#2219', '2219', '1968-01-01', '1982-03-14'),   -- L'Hermitage-Lorge dans Lannion, même défaut
  (112, '17035#2234', '2234', '1968-01-01', '1982-03-14'),   -- … et sa sœur, doublon de l'atome entier (2234)
  (113, '6008',       '1906', '1968-01-01', '1982-03-14'),   -- Brive entière dans Brive-Nord
  (125, '38655',      '2629', '1968-01-01', '1973-09-23');   -- Valence entière dans Valence-Nord
CREATE TEMP TABLE t124_retire AS
SELECT r.par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   t124_retire_v r
JOIN   membership m ON m.niveau = 'canton' AND m.atom_id = r.atom_id AND m.unit_id = r.unit_id
                   AND m.periode <@ daterange(r.du, r.au, '[)');

-- ---------------------------------------------------------------------------
-- 3. Les bornes — l'atome entier s'arrête au décret qui coupe la ville
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t124_borne_v (par int, atom_id text, unit_id text, du_avant date, au_avant date, au date);
INSERT INTO t124_borne_v VALUES
  (113, '6008',  '1906', '1941-01-01', '1968-01-01', '1951-09-13'),   -- décret du 13 septembre 1951
  (125, '38655', '2629', '1955-01-01', '1968-01-01', '1964-03-08');   -- décret du 28 janvier 1964
CREATE TEMP TABLE t124_borne AS
SELECT b.par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to,
       m.valid_from AS du, b.au
FROM   t124_borne_v b
JOIN   membership m ON m.niveau = 'canton' AND m.atom_id = b.atom_id AND m.unit_id = b.unit_id
                   AND m.valid_from = b.du_avant AND m.valid_to = b.au_avant;

-- ---------------------------------------------------------------------------
-- 4. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t124_pose (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t124_pose VALUES
  -- 111 — Vierzon : décret 73-764, Vierzon-I et Vierzon-II
  (111, '39847#1829', '1829', '1973-09-23', '1982-03-14'),
  (111, '39847#1830', '1830', '1973-09-23', '1982-03-14'),
  -- 112 — Dinan : même régime de l'an X à 2015
  (112, '11851#2211', '2211', '1941-01-01', '1968-01-01'),
  (112, '11851#2212', '2212', '1941-01-01', '1968-01-01'),
  -- 113 — Brive : Nord / Sud en 1951, cinq cantons en 1982 (82-120)
  (113, '6008#1906',  '1906', '1951-09-13', '1982-03-14'),
  (113, '6008#1930',  '1930', '1951-09-13', '1982-03-14'),
  (113, '6008#1906',  '1906', '1982-03-14', '1985-03-10'),
  (113, '6008#1930',  '1930', '1982-03-14', '1985-03-10'),
  (113, '6008#1931',  '1931', '1982-03-14', '1985-03-10'),
  (113, '6008#1932',  '1932', '1982-03-14', '1985-03-10'),
  (113, '6008#1933',  '1933', '1982-03-14', '1985-03-10'),
  (113, '10415',      '1930', '1951-09-13', '1954-01-01'),   -- Cosnac
  (113, '17976',      '1930', '1951-09-13', '1954-01-01'),   -- Jugeals-Nazareth
  (113, '20803',      '1930', '1951-09-13', '1954-01-01'),   -- Malemort
  (113, '25069',      '1930', '1951-09-13', '1954-01-01'),   -- Noailles
  (113, '13138',      '1930', '1951-09-13', '1954-01-01'),   -- Estivals
  (113, '24721',      '1930', '1951-09-13', '1954-01-01'),   -- Nespouls
  (113, '28143',      '1930', '1951-09-13', '1954-01-01'),   -- La Chapelle-aux-Brocs
  (113, '20803',      '1934', '1982-03-14', '1985-03-10'),   -- Malemort, chef-lieu de 1934
  -- 116 — Montbéliard : un canton jusqu'en 1973 (73-814), Est / Ouest ensuite
  (116, '23194',      '2514', '1955-01-01', '1973-09-23'),
  (116, '23194#2514', '2514', '1973-09-23', '1982-03-14'),
  (116, '23194#2530', '2530', '1973-09-23', '1982-03-14'),
  -- 117 — Montélimar : au nord / au sud du Roubion (73-718)
  (117, '23337#2616', '2616', '1973-09-23', '1985-03-10'),
  (117, '23337#2633', '2633', '1973-09-23', '1985-03-10'),
  -- 118 — Romans (73-718)
  (118, '29521#2621', '2621', '1973-09-23', '1985-03-10'),
  (118, '29521#2635', '2635', '1973-09-23', '1985-03-10'),
  -- 119 — Crest : la Drôme, de l'an X à 2015
  (119, '11045#2607', '2607', '1973-09-23', '1985-03-10'),
  (119, '11045#2608', '2608', '1973-09-23', '1985-03-10'),
  -- 121 — Besançon : Nord divisé en Nord, Est, Ouest (73-814)
  (121, '3928#2505',  '2505', '1973-09-23', '1982-03-14'),
  (121, '3928#2506',  '2506', '1973-09-23', '1982-03-14'),
  (121, '3928#2528',  '2528', '1973-09-23', '1982-03-14'),
  (121, '3928#2529',  '2529', '1973-09-23', '1982-03-14'),
  (121, '7738',       '2528', '1973-09-23', '1982-03-14'),   -- Chalezeule
  (121, '7700',       '2528', '1973-09-23', '1982-03-14'),   -- Chalèze
  -- 122 — Louviers (82-56)
  (122, '20191#2721', '2721', '1982-03-14', '1992-03-22'),
  (122, '20191#2739', '2739', '1982-03-14', '1992-03-22'),
  -- 123 — Bernay : entière jusqu'au décret 85-145
  (123, '3797',       '2705', '1982-03-14', '1985-03-10'),
  (123, '3797#2705',  '2705', '1985-03-10', '1992-03-22'),
  (123, '3797#2741',  '2741', '1985-03-10', '1992-03-22'),
  -- 125 — Valence : Nord / Sud en 1964, I à III en 1973 (73-718)
  (125, '38655#2629', '2629', '1964-03-08', '1973-09-23'),
  (125, '38655#2630', '2630', '1964-03-08', '1973-09-23'),
  (125, '38655#2629', '2629', '1973-09-23', '1985-03-10'),
  (125, '38655#2630', '2630', '1973-09-23', '1985-03-10'),
  (125, '38655#2631', '2631', '1973-09-23', '1985-03-10'),
  (125, '13241',      '2629', '1941-01-01', '1964-03-08'),   -- Étoile-sur-Rhône
  (125, '13241',      '2630', '1964-03-08', '1968-01-01'),
  (125, '3238',       '2629', '1955-01-01', '1964-03-08'),   -- Beaumont-lès-Valence
  (125, '3238',       '2630', '1964-03-08', '1968-01-01'),
  (125, '38534',      '2629', '1955-01-01', '1964-03-08'),   -- Beauvallon
  (125, '38534',      '2630', '1964-03-08', '1968-01-01'),
  (125, '13841',      '2629', '1955-01-01', '1964-03-08'),   -- Portes-lès-Valence
  (125, '13841',      '2630', '1964-03-08', '1968-01-01'),
  (125, '23626',      '2629', '1955-01-01', '1964-03-08'),   -- Montéléger
  (125, '23626',      '2630', '1964-03-08', '1973-09-23'),
  (125, '5304',       '2632', '1973-09-23', '1985-03-10'),   -- Bourg-lès-Valence
  (125, '33151',      '2632', '1973-09-23', '1985-03-10'),   -- Saint-Marcel-lès-Valence
  -- 126 — Vernon (82-56)
  (126, '39507#2736', '2736', '1982-03-14', '1992-03-22'),
  (126, '39507#2740', '2740', '1982-03-14', '1992-03-22'),
  -- 128 — Toulouse : quinze cantons (73-815), jusqu'au décret de 1997
  (128, '37818#3133', '3133', '1973-09-23', '1998-03-15'),
  (128, '37818#3134', '3134', '1973-09-23', '1998-03-15'),
  (128, '37818#3135', '3135', '1973-09-23', '1998-03-15'),
  (128, '37818#3136', '3136', '1973-09-23', '1998-03-15'),
  (128, '37818#3140', '3140', '1973-09-23', '1998-03-15'),
  (128, '37818#3141', '3141', '1973-09-23', '1998-03-15'),
  (128, '37818#3142', '3142', '1973-09-23', '1998-03-15'),
  (128, '37818#3143', '3143', '1973-09-23', '1998-03-15'),
  (128, '37818#3144', '3144', '1973-09-23', '1998-03-15'),
  (128, '37818#3145', '3145', '1973-09-23', '1998-03-15'),
  (128, '37818#3146', '3146', '1973-09-23', '1998-03-15'),
  (128, '37818#3147', '3147', '1973-09-23', '1998-03-15'),
  (128, '37818#3148', '3148', '1973-09-23', '1998-03-15'),
  (128, '37818#3149', '3149', '1973-09-23', '1998-03-15'),
  (128, '37818#3150', '3150', '1973-09-23', '1998-03-15'),
  (128, '28599',      '3144', '1973-09-23', '1998-03-15'),   -- Ramonville (IX)
  (128, '27672',      '3146', '1973-09-23', '1998-03-15'),   -- Portet (XI)
  (128, '11297',      '3147', '1973-09-23', '1998-03-15'),   -- Cugnaux (XII)
  (128, '37878',      '3147', '1973-09-23', '1998-03-15'),   -- Tournefeuille (XII)
  (128, '33013',      '3150', '1973-09-23', '1998-03-15'),   -- Saint-Loup-Cammas (XV)
  (128, '22893',      '3135', '1955-01-01', '1973-09-23');   -- Mondonville, Toulouse-Ouest jusqu'au décret

CREATE TEMP TABLE t124_nom (par int, unit_id text, nom text, du date, au date);
INSERT INTO t124_nom VALUES
  (111, '1829', 'Vierzon-I',                    '1973-09-23', '1999-01-01'),
  (111, '1830', 'Vierzon-II',                   '1973-09-23', '1999-01-01'),
  (113, '1906', 'Brive-Nord',                   '1951-09-13', '1982-03-14'),
  (113, '1906', 'Brive-la-Gaillarde-Nord-Est',  '1982-03-14', '1999-01-01'),
  (113, '1930', 'Brive-Sud',                    '1951-09-13', '1982-03-14'),
  (114, '2319', 'Guéret',                       '1941-01-01', '1973-09-23'),
  (114, '2319', 'Guéret-Nord',                  '1973-09-23', '1999-01-01'),
  (115, '2427', 'Périgueux',                    '1941-01-01', '1973-09-23'),
  (115, '2427', 'Périgueux-Centre',             '1973-09-23', '1999-01-01'),
  (116, '2514', 'Montbéliard-Est',              '1973-09-23', '1999-01-01'),
  (117, '2616', 'Montélimar-I',                 '1973-09-23', '1999-01-01'),
  (117, '2633', 'Montélimar-II',                '1973-09-23', '1999-01-01'),
  (118, '2621', 'Romans-sur-Isère',             '1941-01-01', '1973-09-23'),
  (118, '2621', 'Romans-sur-Isère-I',           '1973-09-23', '1999-01-01'),
  (118, '2635', 'Romans-sur-Isère-II',          '1973-09-23', '1999-01-01'),
  (120, '2109', 'Dijon-I',                      '1973-09-23', '1999-01-01'),
  (120, '2110', 'Dijon-II',                     '1973-09-23', '1999-01-01'),
  (120, '2111', 'Dijon-III',                    '1973-09-23', '1999-01-01'),
  (120, '2139', 'Dijon-V',                      '1973-09-23', '1999-01-01'),
  (121, '2505', 'Besançon-Nord-Est',            '1982-03-14', '1999-01-01'),
  (122, '2721', 'Louviers-Nord',                '1982-03-14', '1999-01-01'),
  (123, '2705', 'Bernay-Ouest',                 '1985-03-10', '1999-01-01'),
  (123, '2741', 'Bernay-Est',                   '1985-03-10', '1999-01-01'),
  (125, '2629', 'Valence-Nord',                 '1964-03-08', '1973-09-23'),
  (125, '2629', 'Valence-I',                    '1973-09-23', '1999-01-01'),
  (125, '2630', 'Valence-Sud',                  '1964-03-08', '1973-09-23'),
  (125, '2630', 'Valence-II',                   '1973-09-23', '1999-01-01'),
  (125, '2631', 'Valence-III',                  '1973-09-23', '1999-01-01'),
  (125, '2636', 'Valence-IV',                   '1985-03-10', '1999-01-01'),
  (126, '2736', 'Vernon-Nord',                  '1982-03-14', '1999-01-01'),
  (126, '2740', 'Vernon-Sud',                   '1982-03-14', '1999-01-01'),
  (128, '3133', 'Toulouse-I',                   '1973-09-23', '1999-01-01'),
  (128, '3134', 'Toulouse-II',                  '1973-09-23', '1999-01-01'),
  (128, '3135', 'Toulouse-III',                 '1973-09-23', '1999-01-01'),
  (128, '3136', 'Toulouse-IV',                  '1973-09-23', '1999-01-01'),
  (128, '3140', 'Toulouse-V',                   '1973-09-23', '1999-01-01'),
  (128, '3141', 'Toulouse-VI',                  '1973-09-23', '1999-01-01'),
  (128, '3142', 'Toulouse-VII',                 '1973-09-23', '1999-01-01'),
  (128, '3143', 'Toulouse-VIII',                '1973-09-23', '1999-01-01'),
  (128, '3144', 'Toulouse-IX',                  '1973-09-23', '1999-01-01'),
  (128, '3145', 'Toulouse-X',                   '1973-09-23', '1999-01-01'),
  (128, '3146', 'Toulouse-XI',                  '1973-09-23', '1999-01-01'),
  (128, '3147', 'Toulouse-XII',                 '1973-09-23', '1999-01-01'),
  (128, '3148', 'Toulouse-XIII',                '1973-09-23', '1999-01-01'),
  (128, '3149', 'Toulouse-XIV',                 '1973-09-23', '1999-01-01'),
  (128, '3150', 'Toulouse-XV',                  '1973-09-23', '1999-01-01');

\echo ''
\echo '=== 1. Ce qui sera fait, par entrée ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t124_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t124_retire GROUP BY 1
UNION ALL SELECT par, 'borne', count(*), min(du), max(au) FROM t124_borne GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t124_pose GROUP BY 1
UNION ALL SELECT par, 'nom', count(*), min(du), max(au) FROM t124_nom GROUP BY 1
ORDER BY 1, 2;
-- Attendu au premier passage : 5 changements d'unité (Toulouse-XIII),
-- 10 retraits (Dinan 2, L'Hermitage-Lorge 4, Brive 2, Valence 2 : le COG de
-- 1968 coupe chaque période au 1969-01-01), 2 bornes, 79 poses, 46 noms.

-- ---------------------------------------------------------------------------
-- 5. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p124_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    SELECT count(*) INTO n FROM t124_unite;
    IF n <> 5 THEN RAISE EXCEPTION 'UNITÉ : % ligne(s) à changer, 5 attendues (Toulouse-XIII).', n; END IF;
    SELECT count(*) INTO n FROM t124_retire;
    IF n <> 10 THEN RAISE EXCEPTION 'RETRAIT : % ligne(s), 10 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t124_borne;
    IF n <> 2 THEN RAISE EXCEPTION 'BORNE : % ligne(s), 2 attendues (Brive, Valence).', n; END IF;

    SELECT count(*) INTO n FROM t124_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t124_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % unité(s) inconnues.', n; END IF;
    -- Une fraction porte le code de son canton : `X#NNNN` ne va que dans NNNN.
    SELECT count(*) INTO n FROM t124_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) posées hors de leur canton.', n; END IF;
    -- Les poses ne se recouvrent pas entre elles…
    SELECT count(*) INTO n FROM t124_pose a JOIN t124_pose b
        ON a.atom_id = b.atom_id AND a.ctid < b.ctid
       AND daterange(a.du, a.au, '[)') && daterange(b.du, b.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % paire(s) de poses se recouvrent.', n; END IF;
    -- … et la période de chacune doit être libre, hors ce qui va être retiré
    -- ou raccourci.
    SELECT count(*) INTO n FROM t124_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM t124_retire r WHERE r.membership_id = m.membership_id)
       AND NOT EXISTS (SELECT 1 FROM t124_borne b WHERE b.membership_id = m.membership_id
                          AND daterange(b.du, b.au, '[)') * daterange(p.du, p.au, '[)') = 'empty');
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 2 ci-dessous).', n;
    END IF;
    -- Chaque pose doit TOUCHER une période existante du même atome, à gauche
    -- ou à droite (ou la borne qui la précède) : on comble un trou, on ne pose
    -- pas une période isolée.
    SELECT count(*) INTO n FROM t124_pose p
     WHERE NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                          AND (m.valid_to = p.du OR m.valid_from = p.au))
       AND NOT EXISTS (SELECT 1 FROM t124_pose q WHERE q.atom_id = p.atom_id
                          AND (q.au = p.du OR q.du = p.au))
       AND NOT EXISTS (SELECT 1 FROM t124_borne b WHERE b.atom_id = split_part(p.atom_id, '#', 1)
                          AND b.au = p.du);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) isolées, sans voisine.', n; END IF;

    SELECT count(*) INTO n FROM t124_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t124_nom p WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % unité(s) inconnues.', n; END IF;
    SELECT count(*) INTO n FROM t124_pose;
    IF n <> 79 THEN RAISE EXCEPTION 'POSE : % ligne(s), 79 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t124_nom;
    IF n <> 46 THEN RAISE EXCEPTION 'NOMS : % ligne(s), 46 attendues.', n; END IF;
END $$;

\echo ''
\echo '=== 2. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t124_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p124_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text)
  AND  NOT EXISTS (SELECT 1 FROM t124_retire r WHERE r.membership_id = m.membership_id)
  AND  NOT EXISTS (SELECT 1 FROM t124_borne b WHERE b.membership_id = m.membership_id);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 6. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p124_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t124_unite;
UPDATE membership m SET unit_id = u.apres FROM t124_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p124_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t124_retire;
DELETE FROM membership m USING t124_retire r WHERE r.membership_id = m.membership_id;

INSERT INTO p124_trace (quoi, cle, avant)
SELECT 'membership_borne', membership_id::text, valid_from || '|' || valid_to FROM t124_borne;
UPDATE membership m SET valid_to = b.au FROM t124_borne b
 WHERE b.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t124_pose
    RETURNING membership_id
)
INSERT INTO p124_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t124_nom
    RETURNING unit_version_id
)
INSERT INTO p124_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Écrit ==='
SELECT quoi, count(*) FROM p124_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 7. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recette : chaque canton du lot au milieu de chaque période posée ==='
WITH dates AS (
    SELECT DISTINCT par, unit_id, (du + (au - du) / 2) AS d FROM t124_pose
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
  AND  split_part(f.atom_id, '#', 1) IN (SELECT DISTINCT split_part(atom_id, '#', 1) FROM t124_pose
                                         UNION SELECT '17035');
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

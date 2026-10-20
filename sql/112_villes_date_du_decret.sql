-- ============================================================================
-- histgis — 112_villes_date_du_decret.sql : premier lot de
--           `cartes/a_inscrire_en_base.md` — les villes que la base date du
--           COG et que le Journal officiel date du décret
--
--   psql -d histgis -f sql/112_villes_date_du_decret.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/112_villes_date_du_decret.sql
--
-- Inscrit, à la demande d'Adrien (11 octobre 2026), les entrées n° 3, 8, 9,
-- 11, 12, 13, 16, 18, 19, 30, 36, 48, 49, 80, 81, 83, 84, 85, 86, 88, 89, 90,
-- 91, 95 et 99 de `cartes/a_inscrire_en_base.md`. Même modèle que `108` et
-- `109` ; même place : après `107`, AVANT `98`.
--
-- CE QUE CE LOT A EN COMMUN
-- =========================
-- Les unités existent, les fractions existent. La base fait commencer les
-- fractions à la date où le COG les montre (1982, 1985, 1988, 1992, 1998) ;
-- le décret les crée plus tôt, et entre les deux la ville n'a aucun canton.
-- Rien n'est créé ici : ni unité, ni atome. Ce qui demande une unité nouvelle
-- (Bourg-I à III, Gap-Est, Manosque-Sud, Antibes-Nord, Cannes-Ouest,
-- Chalon-Ville, Montluçon-Nord…), un arbitrage ou un texte reste dans
-- `a_inscrire_en_base.md`.
--
-- DATES : celles de la base autour du trou. Une recomposition vaut au premier
-- tour du renouvellement qui suit (règle de `75`, reprise par `110`) :
-- 1973-09-23, 1982-03-14, 1985-03-10, 1992-03-22, 1998-03-15. Les trous
-- finissent à la date COG de la fraction (1988-09-25 dans l'Aube, l'Aveyron
-- et les Alpes-de-Haute-Provence).
--
-- PAR ENTRÉE (`par` = n° de l'entrée)
-- ===================================
--   3  OYONNAX — décret 82-77 (JO du 26 janvier 1982, art. 2). La ville
--      entière dans 0123 de 1973 à 1982, puis `25988#0123` (Nord) et `#0141`
--      (Sud) de 1982 à 1998 ; Bellignat, Groissiat, Martignat et Géovreisset
--      dans 0123 puis 0141. Le JO écrit « Géovreissiat » (01170, canton de
--      Nantua) : c'est Géovreisset (01171), limitrophe d'Oyonnax, que la base
--      et le COG mettent dans Oyonnax-Sud en 1998.
--   8  TROYES — décret 73-652 (JO du 17 juillet 1973, art. 1er à 3). Les sept
--      fractions de 1973 à 1988. Communes rurales lues au décret :
--      Saint-Parres-aux-Tertres (I, 1022) ; Villeloup (IV, 1029) ;
--      Laines-aux-Bois, Saint-André-les-Vergers, Saint-Germain (VI, 1031) ;
--      Bréviandes, Saint-Julien-les-Villas, Rosières (VII, 1032).
--  85  LA CHAPELLE-SAINT-LUC — décret 85-71 (JO du 23 janvier 1985) :
--      `8317#1033` et `8317#1029` de 1985 à 1988. Canton de Sainte-Savine
--      (1028, décret 73-652, art. 2) : Macey, Montgueux, La Rivière-de-Corps,
--      Sainte-Savine, Torvilliers de 1973 à 1988 ; Les Noës-près-Troyes dans
--      1028 jusqu'en 1985, puis dans 1033.
--  13  VICHY — décret 73-713 (JO du 25 juillet 1973) : `39750#0329` (Nord) et
--      `#0330` (Sud) de 1973 à 1985. Abrest, Saint-Yorre et Le Vernet passent
--      de 0335 (Cusset-Sud, créé en 1985) à 0330 (Vichy-Sud) sur 1973-1985.
--  19  CUSSET — décret 85-82 (JO du 24 janvier 1985) : avant lui le canton de
--      Cusset (0306) est entier. La ville, Busset, Mariol, Molles et La
--      Chapelle dans 0306 de 1973 à 1985.
--  16  BRIANÇON — décret 73-651 : `5879#0506` (Nord) et `#0525` (Sud) de 1973
--      à 1982.
--  18  DIGNE — décret 73-714 : `11835#0408` (Est) et `#0431` (Ouest) de 1973 à
--      1988 ; Entrages, La Robine-sur-Galabre et Marcoux dans 0408.
--  30  CREIL — décret 73-668 : `10978#6011` et `#6038` de 1973 à 1998 ;
--      Nogent-sur-Oise et Villers-Saint-Paul dans 6011.
--  36  MAYENNE — la Mayenne sépare Est et Ouest depuis 1802, aucun acte
--      ensuite : les deux fractions de 1941 à 1992 ; l'atome entier quitte
--      Mayenne-Ouest en 1968-1973 (artefact du COG de 1968).
--  49  POITIERS — limite fixée le 16 avril 1862, cinq cantons en 1973 : Nord
--      et Sud de 1941 à 1973 ; l'atome entier quitte Poitiers-Sud en
--      1968-1973. Le régime de 1973-1982 (cinq cantons) n'est PAS inscrit.
--  80  GRASSE — décret 85-143 : la ville entière dans 0610 de 1973 à 1985,
--      `16069#0610` (Sud) et `#0651` (Nord) de 1985 à 1998.
--  81  MENTON — décret du 21 février 1997, effet en mars 1998 : Menton,
--      Gorbio, Roquebrune-Cap-Martin et Sainte-Agnès dans 0613 de 1973 à 1998.
--  83  SEDAN — décret 73-715 : `35814#0826`, `#0827`, `#0836` de 1973 à 1982.
--  84  ROMILLY-SUR-SEINE — décret 73-652, art. 4 : `29547#1020` et `#1027` de
--      1973 à 1988.
--  86  PAMIERS — décret 84-1223 : la ville entière dans 0912 de 1955 à 1985.
--  88  NARBONNE — décret 73-653 : les trois fractions et Bages (1134) de 1973
--      à 1998.
--  89  MILLAU — décret 73-762 : `22497#1217` (Est) et `#1244` (Ouest) de 1973
--      à 1988.
--  90  RODEZ — décrets 73-762 et 82-24 : `29437#1245` (Ouest) et `#1228` (Est)
--      de 1973 à 1988, `#1246` (Nord) de 1982 à 1988 ; Le Monastère et
--      Sainte-Radegonde dans 1228 ; Onet-le-Château et Sébazac-Concourès dans
--      1228 puis 1246 ; Olemps dans 1245 de 1982 à 1988.
--  91  ISTRES — décret 91-209, effet en mars 1992 : Istres, Fos-sur-Mer et
--      Saint-Mitre-les-Remparts dans 1311 de 1973 à 1992. Miramas n'est PAS
--      posée : son passage de Salon à Istres reste à dater.
--  95  MARTIGUES — même décret : Martigues et Port-de-Bouc dans 1325 de 1973
--      à 1992.
--  99  USSEL — décret 85-129 : la ville entière dans 1927 de 1955 à 1985 ;
--      Chaveroche, Lignareix, Saint-Angel et Saint-Pardoux-le-Vieux dans 1927
--      de 1982 à 1985.
--
-- LES NOMS (`unit_version` n'a rien entre 1941 et 1999 pour ces unités)
--   9, 11, 12, 48 : Soissons-Nord, Laon-Nord, Saint-Quentin-Centre, La
--   Roche-sur-Yon-Nord dès 1973 ; et, pour les entrées ci-dessus qui le
--   demandent, le nom que le décret donne à sa date.
--
-- CE QUE CE FICHIER NE FAIT PAS
--   le trou général 1941-1968 des communes (`93`, `97`) ; les régimes que
--   seule une unité nouvelle porterait ; les ancres et les lignes de coupe,
--   qui sont dans `cartes/coupes_ville*.csv` et que `98` relit.
--
-- RÉVERSIBLE ET REJOUABLE : `p112_trace`, comme `p108_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p112_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité, ou 'atome|unité|du|au' pour un retrait
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p112_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p112_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
UPDATE membership m SET unit_id = t.avant FROM p112_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p112_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p112_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée,'
\echo '=== et les comptes qui suivent décrivent un second passage.'
SELECT quoi, count(*) FROM p112_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t112_unite, t112_retire, t112_pose, t112_nom, t112_deja;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité — n° 13 : Vichy-Sud avant Cusset-Sud
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t112_unite AS
SELECT 13 AS par, m.membership_id, m.atom_id, m.unit_id AS avant, '0330'::text AS apres,
       m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id = '0335'
  AND  m.atom_id IN ('75', '35031', '39463')        -- Abrest, Saint-Yorre, Le Vernet
  AND  m.periode <@ daterange(DATE '1973-09-23', DATE '1985-03-10', '[)');

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré : l'atome entier là où la ville a deux cantons
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t112_retire AS
SELECT CASE m.atom_id WHEN '21721' THEN 36 ELSE 49 END AS par,
       m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  ((m.atom_id = '21721' AND m.unit_id = '5321')      -- Mayenne dans Mayenne-Ouest
     OR (m.atom_id = '27358' AND m.unit_id = '8622'))     -- Poitiers dans Poitiers-Sud
  AND  m.periode <@ daterange(DATE '1941-01-01', DATE '1973-09-23', '[)');

-- ---------------------------------------------------------------------------
-- 3. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t112_pose (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t112_pose VALUES
  -- 3 — Oyonnax
  ( 3, '25988',      '0123', '1973-09-23', '1982-03-14'),
  ( 3, '25988#0123', '0123', '1982-03-14', '1998-03-15'),
  ( 3, '25988#0141', '0141', '1982-03-14', '1998-03-15'),
  ( 3, '3478',       '0123', '1973-09-23', '1982-03-14'),   -- Bellignat
  ( 3, '3478',       '0141', '1982-03-14', '1998-03-15'),
  ( 3, '15332',      '0123', '1973-09-23', '1982-03-14'),   -- Géovreisset
  ( 3, '15332',      '0141', '1982-03-14', '1998-03-15'),
  ( 3, '16248',      '0123', '1973-09-23', '1982-03-14'),   -- Groissiat
  ( 3, '16248',      '0141', '1982-03-14', '1998-03-15'),
  ( 3, '21425',      '0123', '1973-09-23', '1982-03-14'),   -- Martignat
  ( 3, '21425',      '0141', '1982-03-14', '1998-03-15'),
  -- 8 — Troyes
  ( 8, '38334#1022', '1022', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1023', '1023', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1024', '1024', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1029', '1029', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1030', '1030', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1031', '1031', '1973-09-23', '1988-09-25'),
  ( 8, '38334#1032', '1032', '1973-09-23', '1988-09-25'),
  ( 8, '34098',      '1022', '1973-09-23', '1988-09-25'),   -- Saint-Parres-aux-Tertres
  ( 8, '40243',      '1029', '1973-09-23', '1988-09-25'),   -- Villeloup
  ( 8, '18378',      '1031', '1973-09-23', '1988-09-25'),   -- Laines-aux-Bois
  ( 8, '30372',      '1031', '1973-09-23', '1988-09-25'),   -- Saint-André-les-Vergers
  ( 8, '32021',      '1031', '1973-09-23', '1988-09-25'),   -- Saint-Germain
  ( 8, '5859',       '1032', '1973-09-23', '1988-09-25'),   -- Bréviandes
  ( 8, '32638',      '1032', '1973-09-23', '1988-09-25'),   -- Saint-Julien-les-Villas
  ( 8, '29958',      '1032', '1973-09-23', '1988-09-25'),   -- Rosières-près-Troyes
  -- 85 — La Chapelle-Saint-Luc et le canton de Sainte-Savine
  (85, '8317#1029',  '1029', '1985-03-10', '1988-09-25'),
  (85, '8317#1033',  '1033', '1985-03-10', '1988-09-25'),
  (85, '25092',      '1028', '1973-09-23', '1985-03-10'),   -- Les Noës-près-Troyes
  (85, '25092',      '1033', '1985-03-10', '1988-09-25'),
  (85, '20478',      '1028', '1973-09-23', '1988-09-25'),   -- Macey
  (85, '23478',      '1028', '1973-09-23', '1988-09-25'),   -- Montgueux
  (85, '29268',      '1028', '1973-09-23', '1988-09-25'),   -- La Rivière-de-Corps
  (85, '31585',      '1028', '1973-09-23', '1988-09-25'),   -- Sainte-Savine
  (85, '37780',      '1028', '1973-09-23', '1988-09-25'),   -- Torvilliers
  -- 13 — Vichy
  (13, '39750#0329', '0329', '1973-09-23', '1985-03-10'),
  (13, '39750#0330', '0330', '1973-09-23', '1985-03-10'),
  -- 19 — Cusset
  (19, '11413',      '0306', '1973-09-23', '1985-03-10'),
  (19, '6363',       '0306', '1973-09-23', '1985-03-10'),   -- Busset
  (19, '21241',      '0306', '1973-09-23', '1985-03-10'),   -- Mariol
  (19, '22757',      '0306', '1973-09-23', '1985-03-10'),   -- Molles
  (19, '8160',       '0306', '1973-09-23', '1985-03-10'),   -- La Chapelle
  -- 16 — Briançon
  (16, '5879#0506',  '0506', '1973-09-23', '1982-03-14'),
  (16, '5879#0525',  '0525', '1973-09-23', '1982-03-14'),
  -- 18 — Digne
  (18, '11835#0408', '0408', '1973-09-23', '1988-09-25'),
  (18, '11835#0431', '0431', '1973-09-23', '1988-09-25'),
  (18, '12658',      '0408', '1973-09-23', '1988-09-25'),   -- Entrages
  (18, '29301',      '0408', '1973-09-23', '1988-09-25'),   -- La Robine-sur-Galabre
  (18, '21097',      '0408', '1973-09-23', '1988-09-25'),   -- Marcoux
  -- 30 — Creil
  (30, '10978#6011', '6011', '1973-09-23', '1998-03-15'),
  (30, '10978#6038', '6038', '1973-09-23', '1998-03-15'),
  (30, '25108',      '6011', '1973-09-23', '1998-03-15'),   -- Nogent-sur-Oise
  (30, '40522',      '6011', '1973-09-23', '1998-03-15'),   -- Villers-Saint-Paul
  -- 36 — Mayenne
  (36, '21721#5320', '5320', '1941-01-01', '1992-03-22'),
  (36, '21721#5321', '5321', '1941-01-01', '1992-03-22'),
  -- 49 — Poitiers
  (49, '27358#8621', '8621', '1941-01-01', '1973-09-23'),
  (49, '27358#8622', '8622', '1941-01-01', '1973-09-23'),
  -- 80 — Grasse
  (80, '16069',      '0610', '1973-09-23', '1985-03-10'),
  (80, '16069#0610', '0610', '1985-03-10', '1998-03-15'),
  (80, '16069#0651', '0651', '1985-03-10', '1998-03-15'),
  -- 81 — Menton
  (81, '22015',      '0613', '1973-09-23', '1998-03-15'),
  (81, '15734',      '0613', '1973-09-23', '1998-03-15'),   -- Gorbio
  (81, '29422',      '0613', '1973-09-23', '1998-03-15'),   -- Roquebrune-Cap-Martin
  (81, '31238',      '0613', '1973-09-23', '1998-03-15'),   -- Sainte-Agnès
  -- 83 — Sedan
  (83, '35814#0826', '0826', '1973-09-23', '1982-03-14'),
  (83, '35814#0827', '0827', '1973-09-23', '1982-03-14'),
  (83, '35814#0836', '0836', '1973-09-23', '1982-03-14'),
  -- 84 — Romilly-sur-Seine
  (84, '29547#1020', '1020', '1973-09-23', '1988-09-25'),
  (84, '29547#1027', '1027', '1973-09-23', '1988-09-25'),
  -- 86 — Pamiers
  (86, '26103',      '0912', '1955-01-01', '1985-03-10'),
  -- 88 — Narbonne
  (88, '24587#1124', '1124', '1973-09-23', '1998-03-15'),
  (88, '24587#1133', '1133', '1973-09-23', '1998-03-15'),
  (88, '24587#1134', '1134', '1973-09-23', '1998-03-15'),
  (88, '2358',       '1134', '1973-09-23', '1998-03-15'),   -- Bages
  -- 89 — Millau
  (89, '22497#1217', '1217', '1973-09-23', '1988-09-25'),
  (89, '22497#1244', '1244', '1973-09-23', '1988-09-25'),
  -- 90 — Rodez : une ligne par régime pour la ville, la limite change en 1982
  (90, '29437#1228', '1228', '1973-09-23', '1982-03-14'),
  (90, '29437#1245', '1245', '1973-09-23', '1982-03-14'),
  (90, '29437#1228', '1228', '1982-03-14', '1988-09-25'),
  (90, '29437#1245', '1245', '1982-03-14', '1988-09-25'),
  (90, '29437#1246', '1246', '1982-03-14', '1988-09-25'),
  (90, '22792',      '1228', '1973-09-23', '1988-09-25'),   -- Le Monastère
  (90, '31565',      '1228', '1973-09-23', '1988-09-25'),   -- Sainte-Radegonde
  (90, '25606',      '1228', '1973-09-23', '1982-03-14'),   -- Onet-le-Château
  (90, '25606',      '1246', '1982-03-14', '1988-09-25'),
  (90, '10075',      '1228', '1973-09-23', '1982-03-14'),   -- Sébazac-Concourès
  (90, '10075',      '1246', '1982-03-14', '1988-09-25'),
  (90, '25528',      '1245', '1982-03-14', '1988-09-25'),   -- Olemps
  -- 91 — Istres
  (91, '17661',      '1311', '1973-09-23', '1992-03-22'),
  (91, '14545',      '1311', '1973-09-23', '1992-03-22'),   -- Fos-sur-Mer
  (91, '33741',      '1311', '1973-09-23', '1992-03-22'),   -- Saint-Mitre-les-Remparts
  -- 95 — Martigues
  (95, '21437',      '1325', '1973-09-23', '1992-03-22'),
  (95, '27653',      '1325', '1973-09-23', '1992-03-22'),   -- Port-de-Bouc
  -- 99 — Ussel
  (99, '38492',      '1927', '1955-01-01', '1985-03-10'),
  (99, '9026',       '1927', '1982-03-14', '1985-03-10'),   -- Chaveroche
  (99, '19527',      '1927', '1982-03-14', '1985-03-10'),   -- Lignareix
  (99, '30432',      '1927', '1982-03-14', '1985-03-10'),   -- Saint-Angel
  (99, '33945',      '1927', '1982-03-14', '1985-03-10');   -- Saint-Pardoux-le-Vieux

CREATE TEMP TABLE t112_nom (par int, unit_id text, nom text, du date, au date);
INSERT INTO t112_nom VALUES
  ( 9, '0231', 'Soissons-Nord',           '1973-09-23', '1999-01-01'),
  (11, '0218', 'Laon-Nord',               '1973-09-23', '1999-01-01'),
  (12, '0228', 'Saint-Quentin-Centre',    '1973-09-23', '1999-01-01'),
  (48, '8523', 'La Roche-sur-Yon-Nord',   '1973-09-23', '1999-01-01'),
  (30, '6011', 'Creil-Nogent-sur-Oise',   '1973-09-23', '1999-01-01'),
  (80, '0610', 'Grasse-Sud',              '1985-03-10', '1999-01-01'),
  (83, '0827', 'Sedan-Est',               '1973-09-23', '1999-01-01'),
  (84, '1020', 'Romilly-sur-Seine-I',     '1973-09-23', '1999-01-01'),
  (84, '1027', 'Romilly-sur-Seine-II',    '1973-09-23', '1999-01-01'),
  (86, '0912', 'Pamiers-Ouest',           '1985-03-10', '1999-01-01'),
  (88, '1124', 'Narbonne-Est',            '1973-09-23', '1999-01-01'),
  (88, '1133', 'Narbonne-Ouest',          '1973-09-23', '1999-01-01'),
  (88, '1134', 'Narbonne-Sud',            '1973-09-23', '1999-01-01'),
  (89, '1217', 'Millau-Est',              '1973-09-23', '1999-01-01'),
  (90, '1228', 'Rodez-Est',               '1973-09-23', '1999-01-01'),
  (91, '1311', 'Istres-Nord',             '1992-03-22', '1999-01-01'),
  (95, '1325', 'Martigues-Est',           '1992-03-22', '1999-01-01'),
  (99, '1927', 'Ussel-Est',               '1985-03-10', '1999-01-01');

-- Une pose que la base porte DÉJÀ, sur toute sa période et au MÊME canton,
-- n'est pas un conflit : c'est ce fichier qui arrive après une lecture qui
-- l'a rattrapé. Cas du 19 octobre 2026 : `composition_jo.py` lit désormais
-- les communes de Troyes-VI et VII (décret 73-652) qu'il perdait, `75` et
-- `95` y posent les six communes rurales du n° 8 à la même unité et aux mêmes
-- dates. On les retire de la pose, et on le dit ; tout autre recouvrement
-- reste refusé par le § 4.
CREATE TEMP TABLE t112_deja AS
SELECT p.* FROM t112_pose p
WHERE  NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.du, p.au, '[)') AND m.unit_id <> p.unit_id)
  AND  (SELECT sum(upper(m.periode * daterange(p.du, p.au, '[)')) - lower(m.periode * daterange(p.du, p.au, '[)')))
          FROM membership m
         WHERE m.atom_id = p.atom_id AND m.niveau = 'canton' AND m.unit_id = p.unit_id
           AND m.periode && daterange(p.du, p.au, '[)')
           AND NOT EXISTS (SELECT 1 FROM p112_trace t
                            WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text))
       = p.au - p.du;
DELETE FROM t112_pose p USING t112_deja d
 WHERE d.atom_id = p.atom_id AND d.du = p.du AND d.unit_id = p.unit_id;

\echo ''
\echo '=== 0. Poses déjà portées par la base, au même canton (retirées de la pose) ==='
SELECT par, atom_id, unit_id, du, au FROM t112_deja ORDER BY par, atom_id;

\echo ''
\echo '=== 1. Ce qui sera fait, par entrée ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t112_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t112_retire GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t112_pose GROUP BY 1
UNION ALL SELECT par, 'nom', count(*), min(du), max(au) FROM t112_nom GROUP BY 1
ORDER BY 1, 2;
-- Attendu au premier passage : 6 changements d'unité (n° 13), 4 retraits
-- (n° 36 et 49, deux chacun), 98 poses, 18 noms.

-- ---------------------------------------------------------------------------
-- 4. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p112_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    SELECT count(*) INTO n FROM t112_unite;
    IF n <> 6 THEN RAISE EXCEPTION 'N° 13 : % ligne(s) à changer d''unité, 6 attendues '
                                   '(Abrest, Saint-Yorre, Le Vernet, deux périodes).', n; END IF;
    SELECT count(*) INTO n FROM t112_retire;
    IF n <> 4 THEN RAISE EXCEPTION 'N° 36 et 49 : % ligne(s) à retirer, 4 attendues.', n; END IF;

    SELECT count(*) INTO n FROM t112_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t112_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % unité(s) inconnues.', n; END IF;
    -- Une fraction porte le code de son canton : `X#NNNN` ne va que dans NNNN.
    SELECT count(*) INTO n FROM t112_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) posées hors de leur canton.', n; END IF;
    -- Les poses ne se recouvrent pas entre elles…
    SELECT count(*) INTO n FROM t112_pose a JOIN t112_pose b
        ON a.atom_id = b.atom_id AND a.ctid < b.ctid
       AND daterange(a.du, a.au, '[)') && daterange(b.du, b.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % paire(s) de poses se recouvrent.', n; END IF;
    -- … et la période de chacune doit être libre, hors ce qui va être retiré.
    SELECT count(*) INTO n FROM t112_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 2 ci-dessous).', n;
    END IF;
    -- Chaque pose doit TOUCHER une période existante du même atome, à gauche
    -- ou à droite : on comble un trou, on ne pose pas une période isolée.
    SELECT count(*) INTO n FROM t112_pose p
     WHERE NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                          AND (m.valid_to = p.du OR m.valid_from = p.au))
       AND NOT EXISTS (SELECT 1 FROM t112_pose q WHERE q.atom_id = p.atom_id
                          AND (q.au = p.du OR q.du = p.au));
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) isolées, sans voisine.', n; END IF;

    SELECT count(*) INTO n FROM t112_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t112_nom p WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % unité(s) inconnues.', n; END IF;

    -- Témoin du n° 13 : Vichy-Sud (0330) n'a aucune commune entière avant 1985.
    SELECT count(*) INTO n FROM membership m
     WHERE m.niveau = 'canton' AND m.unit_id = '0330' AND m.atom_id NOT LIKE '%#%'
       AND m.periode && daterange(DATE '1973-09-23', DATE '1985-03-10', '[)');
    IF n <> 0 THEN RAISE EXCEPTION 'N° 13 : 0330 a déjà % commune(s) entre 1973 et 1985.', n; END IF;
END $$;

\echo ''
\echo '=== 2. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t112_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p112_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 5. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p112_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t112_unite;
UPDATE membership m SET unit_id = u.apres FROM t112_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p112_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t112_retire;
DELETE FROM membership m USING t112_retire r WHERE r.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t112_pose
    RETURNING membership_id
)
INSERT INTO p112_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t112_nom
    RETURNING unit_version_id
)
INSERT INTO p112_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Écrit ==='
SELECT quoi, count(*) FROM p112_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 6. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recette : chaque canton du lot au milieu de chaque période posée ==='
WITH dates AS (
    SELECT DISTINCT par, unit_id, (du + (au - du) / 2) AS d FROM t112_pose
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
  AND  split_part(f.atom_id, '#', 1) IN (SELECT DISTINCT split_part(atom_id, '#', 1) FROM t112_pose);
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

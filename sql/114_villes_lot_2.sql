-- ============================================================================
-- histgis — 114_villes_lot_2.sql : deuxième lot de
--           `cartes/a_inscrire_en_base.md` — ce qui s'inscrit sans créer
--           d'unité ni de fraction
--
--   psql -d histgis -f sql/114_villes_lot_2.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/114_villes_lot_2.sql
--
-- Inscrit, avec l'accord d'Adrien (13 octobre 2026), tout ou partie des
-- entrées n° 4, 21, 24, 25, 27, 28, 29, 31, 32, 33, 34, 35, 37, 41, 50, 51,
-- 53, 55, 59, 60, 64, 67, 71, 72, 73, 75, 79, 87, 92, 94, 96, 98, 102, 105,
-- 106, 107, 108 et 109. Même modèle que `112` ; même place : après `112`,
-- AVANT `98`.
--
-- QUATRE GESTES
-- =============
--   posé     une période sans canton reçoit le sien (fraction, ville entière
--            ou commune rurale nommée par l'entrée) ;
--   retiré   l'atome entier là où la ville a ses fractions (artefact du COG
--            de 1968), ou une fraction rangée sous le code d'un autre canton
--            (Douai sous Dunkerque-Est, Valenciennes sous Hautmont, Boulogne
--            sous Calais-Nord-Ouest, Carcassonne entière en 1968,
--            Cognac sous Confolens-Sud), ou une appartenance sans objet
--            (Wattrelos à Roubaix-Ouest après 1892, Lamécourt de l'Oise dans
--            Sedan-Est) ;
--   changé d'unité  Rennes 1815-1941 (les communes rurales étaient décalées
--            d'un canton : 3530 → 3531 → 3532 → 3530), Javrezac hors de
--            Confolens-Sud, Falicon, Saint-André et La Trinité dans Nice-VII
--            de 1973 à 1982 ;
--   borne déplacée  Aubagne : 2004-03-21 (cantonales) au lieu du 2005-01-01
--            (COG), pour la ville et les cinq communes d'Aubagne-Est.
--
-- DATES : règle de `75` et de `112`, le premier tour qui suit le décret
-- (1973-09-23, 1976-03-07, 1982-03-14, 1985-03-10, 1992-03-22, 1998-03-15,
-- 2004-03-21). Un régime sans acte connu est posé en continu depuis 1941.
--
-- CE QUE CE FICHIER NE FAIT PAS (reste dans `a_inscrire_en_base.md`)
--   toute unité ou fraction à créer (Bourg, Gap, Manosque, Antibes, Cannes,
--   Chalon, Montluçon-Nord, Caen-V, La Rochelle…) ; Rochefort avant 1852 ;
--   Melun de 1941 à 1976 ; Méricourt de 1973 à 1985 ; Le Cannet de 1955 à
--   1968 ; les communes rurales que l'entrée ne nomme pas ; les fractions de
--   1968 accrochées à un autre atome (Saint-Brieuc `30713#2244`, Tulle
--   `15794#1925` et `15506#1926`, Rennes `25690#3532`, Caen `29307#1409`,
--   Cognac `28814#1613`), qui restent en place.
--
-- RÉVERSIBLE ET REJOUABLE : `p114_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p114_trace (
    quoi  text NOT NULL,   -- membership_pose | membership_unite | membership_retire | membership_borne | unit_version_pose
    cle   text NOT NULL,   -- membership_id ou unit_version_id
    avant text,            -- ancienne unité ; 'atome|unité|du|au' pour un retrait ; 'du|au' pour une borne
    pose  timestamptz NOT NULL DEFAULT now()
);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
DELETE FROM unit_version v USING p114_trace t
 WHERE t.quoi = 'unit_version_pose' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m USING p114_trace t
 WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text;
-- Les bornes d'Aubagne se rendent en deux temps, à cause de l'exclusion
-- `membership_non_chevauchant` : d'abord les fins qui reculent… non : ici
-- toutes les lignes reculent ou avancent du même pas, on rend les débuts puis
-- les fins dans l'ordre qui n'empiète jamais.
UPDATE membership m SET valid_from = split_part(t.avant, '|', 1)::date
  FROM p114_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_from <> split_part(t.avant, '|', 1)::date;
UPDATE membership m SET valid_to = split_part(t.avant, '|', 2)::date
  FROM p114_trace t
 WHERE t.quoi = 'membership_borne' AND t.cle = m.membership_id::text
   AND m.valid_to <> split_part(t.avant, '|', 2)::date;
-- Rennes est une permutation : l'exclusion ne porte pas sur l'unité, un seul
-- UPDATE suffit.
UPDATE membership m SET unit_id = t.avant FROM p114_trace t
 WHERE t.quoi = 'membership_unite' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT split_part(t.avant, '|', 1), split_part(t.avant, '|', 2), 'canton',
       split_part(t.avant, '|', 3)::date, split_part(t.avant, '|', 4)::date
FROM   p114_trace t WHERE t.quoi = 'membership_retire';
TRUNCATE p114_trace;
\else
\echo ''
\echo '=== À blanc : une trace non vide veut dire que la base est DÉJÀ corrigée,'
\echo '=== et les comptes qui suivent décrivent un second passage.'
SELECT quoi, count(*) FROM p114_trace GROUP BY 1 ORDER BY 1;
\endif

DROP TABLE IF EXISTS t114_unite, t114_retire, t114_pose, t114_nom, t114_borne, t114_retire_v, t114_deja, t114_fait_amont;

-- ---------------------------------------------------------------------------
-- 1. Ce qui change d'unité
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t114_unite AS
-- n° 64 — Rennes, 1815-1941 : Cesson, Chantepie, Acigné, Vern au Sud-Est ;
-- Saint-Jacques, Vezin, Bruz, Noyal… au Sud-Ouest ; Pacé, Parthenay au
-- Nord-Ouest. De 1954 à 1973 la base les range déjà ainsi.
SELECT 64 AS par, m.membership_id, m.atom_id, m.unit_id AS avant,
       CASE m.unit_id WHEN '3530' THEN '3531' WHEN '3531' THEN '3532' ELSE '3530' END AS apres,
       m.valid_from, m.valid_to
FROM   membership m JOIN atom a USING (atom_id)
WHERE  m.niveau = 'canton' AND m.unit_id IN ('3530', '3531', '3532') AND NOT a.fraction
  AND  m.periode <@ daterange(DATE '1815-01-01', DATE '1941-01-01', '[)')
UNION ALL
-- n° 106 — Javrezac (canton de Cognac) sous Confolens-Sud en 1968-1973
SELECT 106, m.membership_id, m.atom_id, m.unit_id, '1613', m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id = '1615' AND m.atom_id = '17815'
  AND  m.periode <@ daterange(DATE '1968-01-01', DATE '1973-09-23', '[)')
UNION ALL
-- n° 102 — Falicon, Saint-André, La Trinité : Nice-VII (décret 73-811), le
-- XIII n'est créé qu'en 1982
SELECT 102, m.membership_id, m.atom_id, m.unit_id, '0637', m.valid_from, m.valid_to
FROM   membership m
WHERE  m.niveau = 'canton' AND m.unit_id = '0643' AND m.atom_id IN ('13451', '30364', '38247')
  AND  m.periode <@ daterange(DATE '1973-09-23', DATE '1982-03-14', '[)');

-- ---------------------------------------------------------------------------
-- 2. Ce qui est retiré
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t114_retire_v (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t114_retire_v VALUES
  ( 29, '3332',       '6004', '1968-01-01', '1973-09-23'),   -- Beauvais entière au Sud-Ouest
  ( 35, '25044',      '7920', '1968-01-01', '1973-09-23'),   -- Niort entière dans Niort-1
  ( 37, '38367',      '1926', '1968-01-01', '1982-03-14'),   -- Tulle entière dans Tulle-Sud
  ( 41, '35529',      '4929', '1968-01-01', '1973-09-23'),   -- Saumur entière au Sud
  (105, '9804',       '1615', '1968-01-01', '1973-09-23'),   -- Cognac sous Confolens-Sud
  (107, '29352',      '1721', '1968-01-01', '1973-09-23'),   -- Rochefort entière au Nord
  ( 27, '38657#5969', '5969', '1968-01-01', '1982-03-14'),   -- Valenciennes sous Hautmont
  ( 53, '12105#5925', '5925', '1968-01-01', '1982-03-14'),   -- Douai sous Dunkerque-Est
  ( 31, '5200#6215',  '6215', '1968-01-01', '1973-09-23'),   -- Boulogne sous Calais-Nord-Ouest
  -- Carcassonne : jusqu'au 21 octobre 2026, une ligne de Cenne-Monestiés lue sous le
  -- code de Carcassonne (Castelnaudary-Nord) la coupait en deux fractions, #1107 et
  -- #1109, et l'on retirait #1109. `58` retire désormais cette ligne
  -- (`cog1968/c68_codes_corriges.csv`) : Carcassonne arrive ENTIÈRE dans 1107, et
  -- c'est l'atome entier qu'on retire, ses fractions 1107 et 1108 étant posées au § 4.
  ( 87, '6912',       '1107', '1968-01-01', '1973-09-23'),   -- Carcassonne entière dans Carcassonne-I
  ( 28, '41221#5954', '5954', '1892-01-01', '1941-01-01'),   -- Wattrelos à Roubaix-Ouest après 1892
  ( 83, '18451',      '0827', '1973-09-23', '1982-03-14');   -- Lamécourt (Oise) dans Sedan-Est
CREATE TEMP TABLE t114_retire AS
SELECT r.par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to
FROM   t114_retire_v r
JOIN   membership m ON m.niveau = 'canton' AND m.atom_id = r.atom_id AND m.unit_id = r.unit_id
                   AND m.periode <@ daterange(r.du, r.au, '[)');

-- ---------------------------------------------------------------------------
-- 3. Les bornes d'Aubagne — n° 92, décret 2003-156, cantonales du 21 mars 2004
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t114_borne AS
SELECT 92 AS par, m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN m.valid_from = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_from END AS du,
       CASE WHEN m.valid_to   = DATE '2005-01-01' THEN DATE '2004-03-21' ELSE m.valid_to   END AS au
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  m.atom_id IN ('1600', '1600#1305', '1600#1354',
                     '11295', '15233', '29622', '7049', 'N13119')   -- Cuges, Gémenos, Roquefort, Cassis, Carnoux
  AND  (m.valid_from = DATE '2005-01-01' OR m.valid_to = DATE '2005-01-01');

-- ---------------------------------------------------------------------------
-- 4. Ce qui est posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t114_pose (par int, atom_id text, unit_id text, du date, au date);
INSERT INTO t114_pose VALUES
  -- 4 — Aix : Nord / Sud continu de 1801 à 1982, trois cantons en 1982 (82-119)
  (  4, '320#1301',   '1301', '1941-01-01', '1968-01-01'),
  (  4, '320#1302',   '1302', '1941-01-01', '1968-01-01'),
  (  4, '320#1301',   '1301', '1973-09-23', '1982-03-14'),
  (  4, '320#1302',   '1302', '1973-09-23', '1982-03-14'),
  (  4, '320#1301',   '1301', '1982-03-14', '1992-03-22'),
  (  4, '320#1302',   '1302', '1982-03-14', '1992-03-22'),
  (  4, '320#1347',   '1347', '1982-03-14', '1992-03-22'),
  (  4, '12545',      '1302', '1973-09-23', '1992-03-22'),   -- Éguilles
  (  4, '21864',      '1302', '1973-09-23', '1992-03-22'),   -- Meyreuil
  -- 21 — Cagnes : canton entier jusqu'en 1982, deux puis trois cantons
  ( 21, '6536',       '0605', '1973-09-23', '1982-03-14'),
  ( 21, '32881',      '0605', '1973-09-23', '1998-03-15'),   -- Saint-Laurent-du-Var
  ( 21, '33975',      '0605', '1973-09-23', '1982-03-14'),   -- Saint-Paul
  ( 21, '40307',      '0605', '1973-09-23', '1982-03-14'),   -- Villeneuve-Loubet
  ( 21, '9863',       '0605', '1973-09-23', '1982-03-14'),   -- La Colle-sur-Loup
  ( 21, '6536#0605',  '0605', '1982-03-14', '1985-03-10'),
  ( 21, '6536#0645',  '0645', '1982-03-14', '1985-03-10'),
  ( 21, '6536#0605',  '0605', '1985-03-10', '1998-03-15'),
  ( 21, '6536#0645',  '0645', '1985-03-10', '1998-03-15'),
  ( 21, '6536#0648',  '0648', '1985-03-10', '1998-03-15'),
  -- 24, 25 — Roubaix-Ouest et Tourcoing-Nord-Est dans leur ville
  ( 24, '29736#5954', '5954', '1968-01-01', '1982-03-14'),
  ( 25, '38378#5962', '5962', '1968-01-01', '1982-03-14'),
  -- 27, 53 — la fraction rangée sous un autre canton reprend le sien
  ( 27, '38657#5965', '5965', '1968-01-01', '1982-03-14'),
  ( 53, '12105#5923', '5923', '1968-01-01', '1982-03-14'),
  -- 29 — Beauvais
  ( 29, '3332#6003',  '6003', '1941-01-01', '1982-03-14'),
  ( 29, '3332#6004',  '6004', '1941-01-01', '1982-03-14'),
  ( 29, '3332#6003',  '6003', '1982-03-14', '1998-03-15'),
  ( 29, '3332#6004',  '6004', '1982-03-14', '1998-03-15'),
  ( 29, '3332#6040',  '6040', '1982-03-14', '1998-03-15'),
  -- 31 — Boulogne
  ( 31, '5200#6213',  '6213', '1968-01-01', '1973-09-23'),
  ( 31, '5200#6213',  '6213', '1973-09-23', '1985-03-10'),
  ( 31, '5200#6214',  '6214', '1973-09-23', '1985-03-10'),
  ( 31, '5200#6213',  '6213', '1985-03-10', '1992-03-22'),
  ( 31, '5200#6214',  '6214', '1985-03-10', '1992-03-22'),
  ( 31, '5200#6265',  '6265', '1985-03-10', '1992-03-22'),
  -- 32 — Méricourt
  ( 32, '22076#6252', '6252', '1985-03-10', '1992-03-22'),
  ( 32, '22076#6267', '6267', '1985-03-10', '1992-03-22'),
  -- 33 — Meaux
  ( 33, '21801',      '7717', '1955-01-01', '1976-03-07'),
  ( 33, '21801#7717', '7717', '1976-03-07', '1994-03-20'),
  ( 33, '21801#7731', '7731', '1976-03-07', '1994-03-20'),
  -- 34 — Melun
  ( 34, '21914#7718', '7718', '1976-03-07', '1994-03-20'),
  ( 34, '21914#7719', '7719', '1976-03-07', '1994-03-20'),
  -- 35 — Niort
  ( 35, '25044#7920', '7920', '1941-01-01', '1973-09-23'),
  ( 35, '25044#7921', '7921', '1941-01-01', '1973-09-23'),
  -- 37 — Tulle
  ( 37, '38367#1925', '1925', '1941-01-01', '1982-03-14'),
  ( 37, '38367#1926', '1926', '1941-01-01', '1982-03-14'),
  ( 37, '38367#1925', '1925', '1982-03-14', '1985-03-10'),
  ( 37, '38367#1926', '1926', '1982-03-14', '1985-03-10'),
  -- 41 — Saumur : le Nord-Est quitte la ville le 30 mai 1963
  ( 41, '35529#4927', '4927', '1941-01-01', '1963-05-30'),
  ( 41, '35529#4928', '4928', '1941-01-01', '1985-03-10'),
  ( 41, '35529#4929', '4929', '1941-01-01', '1985-03-10'),
  -- 50 — Meudon
  ( 50, '22356#9222', '9222', '1968-01-01', '1998-03-15'),
  ( 50, '22356#9226', '9226', '1968-01-01', '1998-03-15'),
  -- 51 — Gentilly, et Arcueil avec elle
  ( 51, '15323',      '9434', '1976-03-07', '1985-03-10'),
  ( 51, '15323#9434', '9434', '1985-03-10', '1994-03-20'),
  ( 51, '15323#9416', '9416', '1985-03-10', '1994-03-20'),
  ( 51, '1129',       '9434', '1976-03-07', '1994-03-20'),   -- Arcueil
  -- 55, 67, 72, 75, 64 — la fraction oubliée de 1968-1973
  ( 55, '24537#5419', '5419', '1968-01-01', '1973-09-23'),
  ( 67, '37818#3133', '3133', '1968-01-01', '1973-09-23'),
  ( 67, '37818#3135', '3135', '1968-01-01', '1973-09-23'),
  ( 72, '11845#2110', '2110', '1968-01-01', '1973-09-23'),
  ( 72, '11845#2112', '2112', '1968-01-01', '1973-09-23'),
  ( 75, '4923#3309',  '3309', '1968-01-01', '1973-09-23'),
  ( 75, '4923#3313',  '3313', '1968-01-01', '1973-09-23'),
  ( 64, '28930#3529', '3529', '1968-01-01', '1973-09-23'),
  -- 59 — Fontaine
  ( 59, '14156',      '3832', '1973-09-23', '1985-03-10'),
  ( 59, '14156#3832', '3832', '1985-03-10', '1998-03-15'),
  ( 59, '14156#3856', '3856', '1985-03-10', '1998-03-15'),
  ( 59, '26210',      '3832', '1973-09-23', '1985-03-10'),   -- Seyssinet-Pariset
  ( 59, '26210',      '3856', '1985-03-10', '1998-03-15'),
  ( 59, '36283',      '3832', '1973-09-23', '1985-03-10'),   -- Seyssins
  ( 59, '36283',      '3856', '1985-03-10', '1998-03-15'),
  ( 59, '12627',      '3832', '1973-09-23', '1985-03-10'),   -- Engins
  ( 59, '33817',      '3832', '1973-09-23', '1985-03-10'),   -- Saint-Nizier-du-Moucherotte
  -- 60 — Bourgoin-Jallieu
  ( 60, '5316',       '3804', '1973-09-23', '1985-03-10'),
  ( 60, '5316#3804',  '3804', '1985-03-10', '1998-03-15'),
  ( 60, '5316#3853',  '3853', '1985-03-10', '1998-03-15'),
  -- 71 — Évreux
  ( 71, '13353#2716', '2716', '1941-01-01', '1968-01-01'),
  ( 71, '13353#2717', '2717', '1941-01-01', '1968-01-01'),
  ( 71, '13353#2716', '2716', '1982-03-14', '1992-03-22'),
  ( 71, '13353#2717', '2717', '1982-03-14', '1992-03-22'),
  ( 71, '13353#2737', '2737', '1982-03-14', '1992-03-22'),
  ( 71, '13353#2738', '2738', '1982-03-14', '1992-03-22'),
  -- 73 — Saint-Brieuc
  ( 73, '30795#2244', '2244', '1941-01-01', '1982-03-14'),
  ( 73, '30795#2245', '2245', '1941-01-01', '1982-03-14'),
  -- 79 — Le Cannet
  ( 79, '6809',       '0634', '1973-09-23', '1982-03-14'),
  ( 79, '24140',      '0634', '1973-09-23', '1982-03-14'),   -- Mouans-Sartoux
  ( 79, '24163',      '0634', '1973-09-23', '1982-03-14'),   -- Mougins
  ( 79, '29658',      '0634', '1973-09-23', '1982-03-14'),   -- La Roquette-sur-Siagne
  ( 79, '6809#0634',  '0634', '1982-03-14', '1998-03-15'),
  ( 79, '6809#0646',  '0646', '1982-03-14', '1998-03-15'),
  -- 87 — Carcassonne : la limite II / III change en 1985
  ( 87, '6912#1107',  '1107', '1968-01-01', '1973-09-23'),   -- voir § 2 : depuis la correction de `58`
  ( 87, '6912#1108',  '1108', '1968-01-01', '1973-09-23'),
  ( 87, '6912#1107',  '1107', '1973-09-23', '1998-03-15'),
  ( 87, '6912#1108',  '1108', '1973-09-23', '1985-03-10'),
  ( 87, '6912#1132',  '1132', '1973-09-23', '1985-03-10'),
  ( 87, '6912#1108',  '1108', '1985-03-10', '1998-03-15'),
  ( 87, '6912#1132',  '1132', '1985-03-10', '1998-03-15'),
  ( 87, '26409',      '1108', '1973-09-23', '1998-03-15'),   -- Pennautier
  -- 94 — Arles
  ( 94, '1256#1303',  '1303', '1941-01-01', '1968-01-01'),
  ( 94, '1256#1304',  '1304', '1941-01-01', '1968-01-01'),
  ( 94, '1256#1303',  '1303', '1973-09-23', '1992-03-22'),
  ( 94, '1256#1304',  '1304', '1973-09-23', '1992-03-22'),
  -- 96 — Hérouville-Saint-Clair : entière dans Caen-IV, coupée en 1982
  ( 96, '17048',      '1440', '1973-09-23', '1982-03-14'),
  ( 96, '17048#1441', '1441', '1982-03-14', '1998-03-15'),
  ( 96, '17048#1442', '1442', '1982-03-14', '1998-03-15'),
  -- 102 — Nice : I à XI en 1973, I à XIV en 1982 (les limites de I, II, III
  -- changent encore en 1985, les fractions non)
  (102, '24984#0614', '0614', '1973-09-23', '1982-03-14'),
  (102, '24984#0615', '0615', '1973-09-23', '1982-03-14'),
  (102, '24984#0616', '0616', '1973-09-23', '1982-03-14'),
  (102, '24984#0617', '0617', '1973-09-23', '1982-03-14'),
  (102, '24984#0632', '0632', '1973-09-23', '1982-03-14'),
  (102, '24984#0633', '0633', '1973-09-23', '1982-03-14'),
  (102, '24984#0637', '0637', '1973-09-23', '1982-03-14'),
  (102, '24984#0638', '0638', '1973-09-23', '1982-03-14'),
  (102, '24984#0639', '0639', '1973-09-23', '1982-03-14'),
  (102, '24984#0640', '0640', '1973-09-23', '1982-03-14'),
  (102, '24984#0641', '0641', '1973-09-23', '1982-03-14'),
  (102, '24984#0614', '0614', '1982-03-14', '1998-03-15'),
  (102, '24984#0615', '0615', '1982-03-14', '1998-03-15'),
  (102, '24984#0616', '0616', '1982-03-14', '1998-03-15'),
  (102, '24984#0617', '0617', '1982-03-14', '1998-03-15'),
  (102, '24984#0632', '0632', '1982-03-14', '1998-03-15'),
  (102, '24984#0633', '0633', '1982-03-14', '1998-03-15'),
  (102, '24984#0637', '0637', '1982-03-14', '1998-03-15'),
  (102, '24984#0638', '0638', '1982-03-14', '1998-03-15'),
  (102, '24984#0639', '0639', '1982-03-14', '1998-03-15'),
  (102, '24984#0640', '0640', '1982-03-14', '1998-03-15'),
  (102, '24984#0641', '0641', '1982-03-14', '1998-03-15'),
  (102, '24984#0642', '0642', '1982-03-14', '1998-03-15'),
  (102, '24984#0643', '0643', '1982-03-14', '1998-03-15'),
  (102, '24984#0644', '0644', '1982-03-14', '1998-03-15'),
  -- 105 — Cognac
  (105, '9804',       '1613', '1955-01-01', '1973-09-23'),
  (105, '9804#1613',  '1613', '1973-09-23', '1982-03-14'),
  (105, '9804#1633',  '1633', '1973-09-23', '1982-03-14'),
  -- 106 — Confolens, Abzac, Javrezac
  (106, '10142#1614', '1614', '1941-01-01', '1968-01-01'),
  (106, '10142#1615', '1615', '1941-01-01', '1968-01-01'),
  (106, '10142#1614', '1614', '1973-09-23', '1982-03-14'),
  (106, '10142#1615', '1615', '1973-09-23', '1982-03-14'),
  (106, '55',         '1615', '1955-01-01', '1982-03-14'),   -- Abzac
  (106, '17815',      '1613', '1955-01-01', '1968-01-01'),   -- Javrezac
  -- 107 — Rochefort (loi de 1852, aucun acte avant 1985)
  (107, '29352#1721', '1721', '1941-01-01', '1985-03-10'),
  (107, '29352#1722', '1722', '1941-01-01', '1985-03-10'),
  (107, '14529',      '1722', '1973-09-23', '1985-03-10'),   -- Fouras
  (107, '32848',      '1722', '1973-09-23', '1985-03-10'),   -- Saint-Laurent-de-la-Prée
  (107, '39396',      '1722', '1973-09-23', '1985-03-10'),   -- Vergeroux
  (107, '17486',      '1722', '1941-01-01', '1985-03-10'),   -- Île-d'Aix
  -- 108 — Saintes (arrêté de l'an X, aucun acte avant 1985)
  (108, '31580#1734', '1734', '1941-01-01', '1968-01-01'),
  (108, '31580#1735', '1735', '1941-01-01', '1968-01-01'),
  (108, '31580#1734', '1734', '1973-09-23', '1985-03-10'),
  (108, '31580#1735', '1735', '1973-09-23', '1985-03-10'),
  (108, '8074',       '1734', '1973-09-23', '1985-03-10'),   -- Chaniers
  (108, '8225',       '1734', '1973-09-23', '1985-03-10'),   -- La Chapelle-des-Pots
  (108, '9940',       '1735', '1973-09-23', '1985-03-10'),   -- Colombiers
  (108, '10673',      '1735', '1973-09-23', '1985-03-10'),   -- Courcoury
  (108, '31710',      '1734', '1955-01-01', '1985-03-10'),   -- Saint-Vaize
  (108, '12502',      '1735', '1955-01-01', '1985-03-10'),   -- Écurat
  (108, '37348',      '1735', '1955-01-01', '1985-03-10'),   -- Thénac
  (108, '18388',      '1735', '1955-01-01', '1985-03-10'),   -- La Jard
  (108, '15709',      '1735', '1955-01-01', '1985-03-10'),   -- Les Gonds
  -- 109 — Bourges
  (109, '5289#1805',  '1805', '1973-09-23', '1982-03-14'),
  (109, '5289#1831',  '1831', '1973-09-23', '1982-03-14'),
  (109, '5289#1832',  '1832', '1973-09-23', '1982-03-14'),
  (109, '5289#1833',  '1833', '1973-09-23', '1982-03-14'),
  (109, '31231',      '1820', '1973-09-23', '1982-03-14'),   -- Saint-Doulchard
  (109, '8331',       '1820', '1973-09-23', '1982-03-14'),   -- La Chapelle-Saint-Ursin
  (109, '21269',      '1820', '1973-09-23', '1982-03-14'),   -- Marmagne
  (109, '14943',      '1823', '1955-01-01', '1982-03-14');   -- Fussy

CREATE TEMP TABLE t114_nom (par int, unit_id text, nom text, du date, au date);
INSERT INTO t114_nom VALUES
  (  4, '1301', 'Aix-en-Provence-Nord-Est',                 '1982-03-14', '1999-01-01'),
  (  4, '1302', 'Aix-en-Provence-Sud-Ouest',                '1982-03-14', '1999-01-01'),
  (  4, '1347', 'Aix-en-Provence-Centre',                   '1982-03-14', '1999-01-01'),
  ( 21, '0605', 'Cagnes-Est',                               '1982-03-14', '1985-03-10'),
  ( 21, '0605', 'Saint-Laurent-du-Var-Cagnes-sur-Mer-Est',  '1985-03-10', '1999-01-01'),
  ( 21, '0645', 'Cagnes-Ouest',                             '1982-03-14', '1985-03-10'),
  ( 21, '0645', 'Cagnes-sur-Mer-Ouest',                     '1985-03-10', '1999-01-01'),
  ( 21, '0648', 'Cagnes-sur-Mer-Centre',                    '1985-03-10', '1999-01-01'),
  ( 31, '6213', 'Boulogne-sur-Mer-Nord-Est',                '1985-03-10', '1999-01-01'),
  ( 33, '7717', 'Meaux-Nord',                               '1976-03-07', '1999-01-01'),
  ( 35, '7920', 'Niort-Nord',                               '1973-09-23', '1999-01-01'),
  ( 35, '7921', 'Niort-Ouest',                              '1973-09-23', '1999-01-01'),
  ( 37, '1925', 'Tulle-Urbain-Nord',                        '1982-03-14', '1999-01-01'),
  ( 37, '1926', 'Tulle-Urbain-Sud',                         '1982-03-14', '1999-01-01'),
  ( 59, '3832', 'Fontaine-Sassenage',                       '1985-03-10', '1999-01-01'),
  ( 59, '3856', 'Fontaine-Seyssinet',                       '1985-03-10', '1999-01-01'),
  ( 60, '3804', 'Bourgoin-Jallieu-Sud',                     '1985-03-10', '1999-01-01'),
  ( 87, '1107', 'Carcassonne-I',                            '1973-09-23', '1999-01-01'),
  ( 87, '1108', 'Carcassonne-II',                           '1973-09-23', '1998-03-15'),
  ( 87, '1108', 'Carcassonne-II-Nord',                      '1998-03-15', '1999-01-01'),
  ( 87, '1132', 'Carcassonne-III',                          '1973-09-23', '1999-01-01'),
  ( 87, '1135', 'Carcassonne-II-Sud',                       '1998-03-15', '1999-01-01'),
  ( 96, '1441', 'Hérouville-Saint-Clair (Caen-V)',          '1982-03-14', '1999-01-01'),
  ( 96, '1442', 'Caen-Hérouville (Caen-VI)',                '1982-03-14', '1999-01-01'),
  ( 98, '2112', 'Dijon-IV',                                 '1973-09-23', '1999-01-01'),
  (105, '1613', 'Cognac-Nord',                              '1973-09-23', '1999-01-01'),
  (105, '1633', 'Cognac-Sud',                               '1973-09-23', '1999-01-01'),
  (108, '1735', 'Saintes-Ouest',                            '1985-03-10', '1999-01-01'),
  (109, '1805', 'Bourges-I',                                '1973-09-23', '1999-01-01'),
  (109, '1831', 'Bourges-II',                               '1973-09-23', '1999-01-01'),
  (109, '1832', 'Bourges-III',                              '1973-09-23', '1999-01-01'),
  (109, '1833', 'Bourges-IV',                               '1973-09-23', '1999-01-01'),
  (109, '1834', 'Bourges-V',                                '1982-03-14', '1999-01-01');

\echo ''
-- ---------------------------------------------------------------------------
-- Ce que `96` a déjà fait — 20 octobre 2026
--
-- `96` juge désormais aussi les lectures de 1968 qui se portaient garantes les
-- unes des autres, et corrige Cognac et Javrezac lues dans Confolens-Sud
-- (1615) : 1613, exactement les n° 105 et 106. Leurs poses sont alors déjà
-- portées par la base au même canton (`95`, `97` reportent le jalon corrigé),
-- et les lignes à changer ou à retirer n'existent plus. On retire de la pose
-- ce qui est déjà porté au MÊME canton, et les garde-fous comptent ce qui a
-- été fait en amont ; tout autre écart reste refusé.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t114_deja AS
SELECT p.* FROM t114_pose p
WHERE  NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.du, p.au, '[)') AND m.unit_id <> p.unit_id)
  AND  (SELECT sum(upper(m.periode * daterange(p.du, p.au, '[)')) - lower(m.periode * daterange(p.du, p.au, '[)')))
          FROM membership m
         WHERE m.atom_id = p.atom_id AND m.niveau = 'canton' AND m.unit_id = p.unit_id
           AND m.periode && daterange(p.du, p.au, '[)')
           AND NOT EXISTS (SELECT 1 FROM p114_trace t
                            WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text))
       = p.au - p.du;
DELETE FROM t114_pose p USING t114_deja d
 WHERE d.atom_id = p.atom_id AND d.du = p.du AND d.unit_id = p.unit_id;

-- les changements d'unité et retraits du n° 105-106 que `96` a rendus sans objet
CREATE TEMP TABLE t114_fait_amont AS
SELECT 'unite'::text AS quoi, count(*)::int AS n FROM membership m
 WHERE m.niveau = 'canton' AND m.atom_id = '17815' AND m.unit_id = '1613'
   AND m.periode <@ daterange(DATE '1968-01-01', DATE '1973-09-23', '[)')
   AND EXISTS (SELECT 1 FROM p96_trace t WHERE t.atom_id = '17815' AND t.unit_pose = '1613')
UNION ALL
SELECT 'retrait', count(*)::int FROM membership m
 WHERE m.niveau = 'canton' AND m.atom_id = '9804' AND m.unit_id = '1613'
   AND m.periode <@ daterange(DATE '1968-01-01', DATE '1973-09-23', '[)')
   AND EXISTS (SELECT 1 FROM p96_trace t WHERE t.atom_id = '9804' AND t.unit_pose = '1613')
   AND NOT EXISTS (SELECT 1 FROM membership x WHERE x.niveau = 'canton'
                    AND x.atom_id = '9804' AND x.unit_id = '1615'
                    AND x.periode <@ daterange(DATE '1968-01-01', DATE '1973-09-23', '[)'));

\echo ''
\echo '=== 0. Déjà fait en amont par `96` (retiré de ce passage) ==='
SELECT par, atom_id, unit_id, du, au FROM t114_deja ORDER BY par, atom_id;
SELECT * FROM t114_fait_amont;

\echo '=== 1. Ce qui sera fait, par entrée ==='
SELECT par, 'change d unité' AS quoi, count(*) AS lignes, min(valid_from) AS du, max(valid_to) AS au
FROM t114_unite GROUP BY 1
UNION ALL SELECT par, 'retiré', count(*), min(valid_from), max(valid_to) FROM t114_retire GROUP BY 1
UNION ALL SELECT par, 'borne', count(*), min(du), max(au) FROM t114_borne GROUP BY 1
UNION ALL SELECT par, 'posé', count(*), min(du), max(au) FROM t114_pose GROUP BY 1
UNION ALL SELECT par, 'nom', count(*), min(du), max(au) FROM t114_nom GROUP BY 1
ORDER BY 1, 2;
-- Attendu au premier passage : 35 changements d'unité (30 à Rennes, 2 pour
-- Javrezac, 3 à Nice), 22 retraits, 13 bornes, 165 poses, 33 noms.

-- ---------------------------------------------------------------------------
-- 5. Garde-fous — évalués à blanc comme sous `appliquer`
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM p114_trace) THEN
        RAISE NOTICE 'Trace non vide : passage à blanc sur une base déjà corrigée, garde-fous sautés.';
        RETURN;
    END IF;

    SELECT count(*) + (SELECT f.n FROM t114_fait_amont f WHERE f.quoi = 'unite') INTO n FROM t114_unite;
    IF n <> 35 THEN RAISE EXCEPTION 'UNITÉ : % ligne(s) à changer, 35 attendues '
                                    '(30 à Rennes, 2 pour Javrezac, 3 à Nice).', n; END IF;
    SELECT count(*) + (SELECT f.n FROM t114_fait_amont f WHERE f.quoi = 'retrait') INTO n FROM t114_retire;
    IF n <> 22 THEN RAISE EXCEPTION 'RETRAIT : % ligne(s), 22 attendues.', n; END IF;
    SELECT count(*) INTO n FROM t114_borne;
    IF n <> 13 THEN RAISE EXCEPTION 'AUBAGNE : % borne(s) à déplacer, 13 attendues.', n; END IF;

    SELECT count(*) INTO n FROM t114_pose p WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = p.atom_id);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % atome(s) inconnus.', n; END IF;
    SELECT count(*) INTO n FROM t114_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % unité(s) inconnues.', n; END IF;
    -- Une fraction porte le code de son canton : `X#NNNN` ne va que dans NNNN.
    SELECT count(*) INTO n FROM t114_pose p
     WHERE p.atom_id LIKE '%#%' AND split_part(p.atom_id, '#', 2) <> p.unit_id;
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % fraction(s) posées hors de leur canton.', n; END IF;
    -- Les poses ne se recouvrent pas entre elles…
    SELECT count(*) INTO n FROM t114_pose a JOIN t114_pose b
        ON a.atom_id = b.atom_id AND a.ctid < b.ctid
       AND daterange(a.du, a.au, '[)') && daterange(b.du, b.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % paire(s) de poses se recouvrent.', n; END IF;
    -- … et la période de chacune doit être libre, hors ce qui va être retiré.
    SELECT count(*) INTO n FROM t114_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM t114_retire r WHERE r.membership_id = m.membership_id);
    IF n > 0 THEN
        RAISE EXCEPTION 'POSE : % appartenance(s) occupent déjà une période à poser '
                        '(voir la requête 2 ci-dessous).', n;
    END IF;
    -- Chaque pose doit TOUCHER une période existante du même atome, à gauche
    -- ou à droite : on comble un trou, on ne pose pas une période isolée.
    SELECT count(*) INTO n FROM t114_pose p
     WHERE NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                          AND (m.valid_to = p.du OR m.valid_from = p.au))
       AND NOT EXISTS (SELECT 1 FROM t114_pose q WHERE q.atom_id = p.atom_id
                          AND (q.au = p.du OR q.du = p.au))
       -- … sauf la fraction oubliée de 1968 : ses sœurs ont déjà la période.
       AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.niveau = 'canton'
                          AND m.atom_id <> p.atom_id AND m.atom_id LIKE '%#%'
                          AND split_part(m.atom_id, '#', 1) = split_part(p.atom_id, '#', 1)
                          AND m.valid_from = p.du);
    IF n > 0 THEN RAISE EXCEPTION 'POSE : % période(s) isolées, sans voisine.', n; END IF;

    SELECT count(*) INTO n FROM t114_nom p
      JOIN unit_version v ON v.unit_id = p.unit_id AND v.periode && daterange(p.du, p.au, '[)');
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % version(s) d''unité occupent déjà la période.', n; END IF;
    SELECT count(*) INTO n FROM t114_nom p WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.unit_id);
    IF n > 0 THEN RAISE EXCEPTION 'NOMS : % unité(s) inconnues.', n; END IF;

END $$;

\echo ''
\echo '=== 2. Périodes à poser déjà occupées (attendu : aucune ligne au premier passage) ==='
SELECT p.par, p.atom_id, m.unit_id, m.periode
FROM   t114_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  NOT EXISTS (SELECT 1 FROM p114_trace t
                    WHERE t.quoi = 'membership_pose' AND t.cle = m.membership_id::text)
  AND  NOT EXISTS (SELECT 1 FROM t114_retire r WHERE r.membership_id = m.membership_id);

\if :{?appliquer}
-- ---------------------------------------------------------------------------
-- 6. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p114_trace (quoi, cle, avant)
SELECT 'membership_unite', membership_id::text, avant FROM t114_unite;
UPDATE membership m SET unit_id = u.apres FROM t114_unite u
 WHERE u.membership_id = m.membership_id;

INSERT INTO p114_trace (quoi, cle, avant)
SELECT 'membership_retire', membership_id::text,
       atom_id || '|' || unit_id || '|' || valid_from || '|' || valid_to
FROM   t114_retire;
DELETE FROM membership m USING t114_retire r WHERE r.membership_id = m.membership_id;

-- Aubagne : les fins reculent d'abord, les débuts ensuite — jamais de
-- chevauchement entre l'atome entier et ses fractions.
INSERT INTO p114_trace (quoi, cle, avant)
SELECT 'membership_borne', membership_id::text, valid_from || '|' || valid_to FROM t114_borne;
UPDATE membership m SET valid_to = b.au FROM t114_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_to <> b.au;
UPDATE membership m SET valid_from = b.du FROM t114_borne b
 WHERE b.membership_id = m.membership_id AND m.valid_from <> b.du;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t114_pose
    RETURNING membership_id
)
INSERT INTO p114_trace (quoi, cle) SELECT 'membership_pose', membership_id::text FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t114_nom
    RETURNING unit_version_id
)
INSERT INTO p114_trace (quoi, cle) SELECT 'unit_version_pose', unit_version_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Écrit ==='
SELECT quoi, count(*) FROM p114_trace GROUP BY 1 ORDER BY 1;
\endif

-- ---------------------------------------------------------------------------
-- 7. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recette : chaque canton du lot au milieu de chaque période posée ==='
WITH dates AS (
    SELECT DISTINCT par, unit_id, (du + (au - du) / 2) AS d FROM t114_pose
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
  AND  split_part(f.atom_id, '#', 1) IN (SELECT DISTINCT split_part(atom_id, '#', 1) FROM t114_pose);
-- Attendu après application : aucune ligne.

\if :{?appliquer}
\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql'
\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

-- ============================================================================
-- histgis — 130_cantons_petite_couronne_1968_1998.sql : les communes ENTIÈRES
--           des 92, 93 et 94 restées sans canton entre les décrets de 1967 et
--           les cantons de 1994-1998
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/130_cantons_petite_couronne_1968_1998.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/130_cantons_petite_couronne_1968_1998.sql
--   psql -d histgis -1 -v defaire=1 -f sql/130_cantons_petite_couronne_1968_1998.sql
--
-- LE TROU
-- =======
-- Les décrets n° 76-76 et 76-77 (Seine-Saint-Denis, Val-de-Marne, effet au
-- 7 mars 1976) et n° 84-1241 et 84-1242 (Hauts-de-Seine, Val-de-Marne, effet
-- au 10 mars 1985) sont lus dans `acte_composition`, mais leurs articles qui
-- créent un canton à partir de communes entières ont échappé à la lecture
-- (« Les communes de Pierrefitte et de Villetaneuse forment un nouveau
-- canton… »). Les communes restaient sans canton jusqu'au bout droit — les
-- cantons de 1994 (94) ou de 1998 (92, 93) — et `120` ne comble que deux bouts
-- identiques.
--
-- LA SOURCE
-- =========
-- Le texte des décrets, relu le 24 octobre 2026 dans l'OCR des numéros du JO
-- (`jorf_txt/JORF_19760129_24_col.txt`, p. 722-725 ;
-- `jorf_txt/JORF_19841230_305_col.txt`, p. 4153-4165), et les compositions de
-- 1967 (n° 67-590 à 67-592, `acte_composition`). Chaque ligne ci-dessous cite
-- l'article qui la fonde. L'unité posée est celle que la base porte au bout
-- droit (même code, même chef-lieu) ou au bout gauche.
--
-- HYPOTHÈSE, une seule : les décrets de « modification de limites
-- cantonales » de 1986 à 1996 (`acte_cantonal`, textes non lus) ne déplacent
-- aucune de ces communes entières. Ils sont postérieurs aux créations qu'on
-- pose ici, et chacune de ces communes retrouve au bout droit le canton que
-- le dernier décret lu lui donne : l'hypothèse est contrôlée par les deux bouts.
--
-- CE QU'IL NE FAIT PAS : les villes coupées par des rues (Pantin, Montreuil,
-- Bondy, Saint-Denis, Créteil, Villejuif, Vitry, Champigny, Colombes,
-- Nanterre…). Ce sont des coupes (`decoupe-ville`), décret par décret.
--
-- Réversible : `p130_trace`. Rejouable. Après `120` et `127`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p130_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM p130_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM p130_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t130_lu;
CREATE TEMP TABLE t130_lu (insee text, nom text, unit_id text, du date, au date, fonde text);
INSERT INTO t130_lu VALUES
-- Hauts-de-Seine (bout droit : 1998-03-15)
('92032','Fontenay-aux-Roses','9210','1968-01-01','1985-03-10','67-590 : canton de Châtillon'),
('92032','Fontenay-aux-Roses','9243','1985-03-10','1998-03-15','84-1241 art. 4 : canton de Fontenay-aux-Roses'),
('92046','Malakoff','9225','1968-01-01','1998-03-15','67-590 : canton de Malakoff ; non touché en 1985'),
('92047','Marnes-la-Coquette','9211','1968-01-01','1998-03-15','67-590 : canton de Chaville ; non touché en 1985'),
('92060','Le Plessis-Robinson','9232','1968-01-01','1998-03-15','canton de Clamart (9232, bout gauche de Clamart) ; non touché en 1985'),
('92062','Puteaux','9233','1968-01-01','1998-03-15','67-590 : canton de Puteaux ; non touché en 1985'),
-- Seine-Saint-Denis (bout droit : 1998-03-15)
('93027','La Courneuve','9310','1968-01-01','1998-03-15','67-591 : canton de La Courneuve ; non touché en 1976'),
('93050','Neuilly-sur-Marne','9337','1976-03-07','1998-03-15','76-76 art. 8 : nouveau canton de Neuilly-sur-Marne'),
('93059','Pierrefitte-sur-Seine','9339','1976-03-07','1998-03-15','76-76 art. 1er : Pierrefitte et Villetaneuse'),
('93079','Villetaneuse','9339','1976-03-07','1998-03-15','76-76 art. 1er : Pierrefitte et Villetaneuse'),
('93078','Villepinte','9340','1976-03-07','1998-03-15','76-76 art. 8 : nouveau canton de Villepinte'),
-- Val-de-Marne (bout droit : 1994-03-20)
('94038','L''Haÿ-les-Roses','9412','1968-01-01','1994-03-20','67-592, 76-77 art. 2, 84-1242 art. 1er : canton de L''Haÿ-les-Roses'),
('94034','Fresnes','9437','1976-03-07','1994-03-20','76-77 art. 3 : nouveau canton de Fresnes'),
('94021','Chevilly-Larue','9425','1976-03-07','1985-03-10','76-77 art. 4 : canton de Thiais'),
('94021','Chevilly-Larue','9442','1985-03-10','1994-03-20','84-1242 art. 2 : canton de Chevilly-Larue'),
('94065','Rungis','9425','1976-03-07','1985-03-10','76-77 art. 4 : canton de Thiais'),
('94065','Rungis','9442','1985-03-10','1994-03-20','84-1242 art. 2 : canton de Chevilly-Larue'),
('94044','Limeil-Brévannes','9426','1976-03-07','1985-03-10','canton de Villecresnes (bout gauche), non touché en 1976'),
('94044','Limeil-Brévannes','9402','1985-03-10','1994-03-20','84-1242 art. 7 : canton de Boissy-Saint-Léger'),
('94071','Sucy-en-Brie','9402','1976-03-07','1985-03-10','canton de Boissy-Saint-Léger (bout gauche), non touché en 1976'),
('94071','Sucy-en-Brie','9446','1985-03-10','1994-03-20','84-1242 art. 7 : canton de Sucy-en-Brie'),
('94074','Valenton','9429','1976-03-07','1985-03-10','canton de Villeneuve-Saint-Georges (bout gauche), non touché en 1976'),
('94074','Valenton','9447','1985-03-10','1994-03-20','84-1242 art. 6 : canton de Valenton'),
('94053','Noiseau','9408','1976-03-07','1985-03-10','76-77 art. 9 : canton de Chennevières-sur-Marne'),
('94053','Noiseau','9444','1985-03-10','1994-03-20','84-1242 art. 9 : canton d''Ormesson-sur-Marne'),
('94055','Ormesson-sur-Marne','9408','1976-03-07','1985-03-10','76-77 art. 9 : canton de Chennevières-sur-Marne'),
('94055','Ormesson-sur-Marne','9444','1985-03-10','1994-03-20','84-1242 art. 9 : canton d''Ormesson-sur-Marne'),
('94060','La Queue-en-Brie','9408','1976-03-07','1985-03-10','76-77 art. 9 : canton de Chennevières-sur-Marne'),
('94060','La Queue-en-Brie','9444','1985-03-10','1994-03-20','84-1242 art. 9 : canton d''Ormesson-sur-Marne'),
('94059','Le Plessis-Trévise','9438','1976-03-07','1994-03-20','76-77 art. 9 : canton de Villiers-sur-Marne'),
('94079','Villiers-sur-Marne','9438','1976-03-07','1994-03-20','76-77 art. 9 : canton de Villiers-sur-Marne');

DROP TABLE IF EXISTS t130_pose;
CREATE TEMP TABLE t130_pose AS
SELECT a.atom_id, l.*
  FROM t130_lu l JOIN atom a ON a.insee_geofla = l.insee;

\echo ''
\echo '=== 1. Garde-fous : une commune = un atome, unités en base (attendu : rien) ==='
SELECT insee, count(DISTINCT atom_id) AS atomes FROM t130_pose GROUP BY 1 HAVING count(DISTINCT atom_id) <> 1;
SELECT DISTINCT unit_id AS unite_absente FROM t130_lu
 WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = t130_lu.unit_id AND u.niveau = 'canton');

\echo ''
\echo '=== 2. Les bouts : la ligne raccorde-t-elle les rattachements voisins ? ==='
SELECT p.insee, p.nom, p.unit_id, p.du, p.au,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_to = p.du) AS gauche,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_from = p.au) AS droite
  FROM t130_pose p ORDER BY 1, 4;

\echo ''
\echo '=== 3. Garde-fou : périodes déjà prises (attendu : zéro) ==='
DROP TABLE IF EXISTS t130_pris;
CREATE TEMP TABLE t130_pris AS
SELECT p.insee, m.unit_id, m.valid_from, m.valid_to
  FROM t130_pose p JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
   AND m.periode && daterange(p.du, p.au, '[)');
SELECT * FROM t130_pris;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t130_pris;
    IF n > 0 THEN RAISE EXCEPTION '% période(s) déjà prise(s). Recette 3.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t130_pose GROUP BY 1
                                  HAVING count(DISTINCT atom_id) <> 1) d;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) à plusieurs atomes. Recette 1.', n; END IF;
END $$;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t130_pose
    RETURNING membership_id
)
INSERT INTO p130_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;
ANALYZE membership;

\echo ''
\echo '=== 4. Posé ==='
SELECT count(*) AS rattachements FROM p130_trace;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

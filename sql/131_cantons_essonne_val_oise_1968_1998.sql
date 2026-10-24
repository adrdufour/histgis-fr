-- ============================================================================
-- histgis — 131_cantons_essonne_val_oise_1968_1998.sql : les communes ENTIÈRES
--           de l'Essonne et du Val-d'Oise sans canton entre les décrets de
--           1967 et ceux de 1985 (95) ou 1998 (91)
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/131_cantons_essonne_val_oise_1968_1998.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/131_cantons_essonne_val_oise_1968_1998.sql
--   psql -d histgis -1 -v defaire=1 -f sql/131_cantons_essonne_val_oise_1968_1998.sql
--
-- Le pendant de `130` pour la grande couronne. Même trou, même cause : les
-- articles qui forment un canton de communes entières n'ont pas été lus, et
-- `120` ne comble que deux bouts identiques.
--
-- LA SOURCE : l'OCR des numéros du JO, relus le 25 octobre 2026 —
--   n° 75-1116 du 25 novembre 1975 (Essonne), JO du 7 décembre 1975,
--     `jorf_txt/JORF_19751207_284_col.txt` (effet « au 1er janvier 1976 »,
--     posé au 7 mars 1976 comme toute la base : premier tour qui suit) ;
--   n° 76-78 du 22 janvier 1976 (Val-d'Oise), JO du 29 janvier 1976,
--     `jorf_txt/JORF_19760129_24_col.txt` ;
--   n° 85-83 du 23 janvier 1985 (Essonne), JO du 24 janvier 1985,
--     `jorf_txt/JORF_19850124_20_col.txt` ;
-- et les compositions de 1967 (n° 67-589, 67-593, `acte_composition`).
-- Chaque ligne raccorde ses deux bouts (recette 2) ; l'unité posée est
-- celle du bout droit ou du bout gauche, même chef-lieu.
--
-- HYPOTHÈSE : les décrets de « modification de limites » de 1986-1997 ne
-- déplacent pas ces communes entières — contrôlée par le bout droit.
--
-- Les Ulis, commune née en 1977, ne reçoit que [1985, 1998), le canton créé
-- pour elle (85-83 art. 6) ; de 1977 à 1985 elle était au canton d'Orsay,
-- mais l'atome porte une vie antérieure à sa naissance qu'on n'étend pas.
--
-- Réversible : `p131_trace`. Rejouable. Après `130`, avant `128`.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p131_trace (
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
 WHERE EXISTS (SELECT 1 FROM p131_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM p131_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t131_lu;
CREATE TEMP TABLE t131_lu (insee text, nom text, unit_id text, du date, au date, fonde text);
INSERT INTO t131_lu VALUES
-- Essonne
('91201','Draveil','9141','1968-01-01','1976-03-07','67-589 : canton de Juvisy-sur-Orge'),
('91201','Draveil','9129','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Draveil'),
('91022','Arrancourt','9117','1968-01-01','1998-03-15','67-589 : canton de Méréville, jamais touché'),
('91546','Saint-Cyr-sous-Dourdan','9124','1968-01-01','1998-03-15','67-589 : canton de Saint-Chéron, jamais touché'),
('91272','Gif-sur-Yvette','9130','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Gif-sur-Yvette'),
('91661','Villebon-sur-Yvette','9135','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Villebon'),
('91666','Villejust','9135','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Villebon'),
('91044','Ballainvilliers','9135','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Villebon'),
('91136','Champlan','9135','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Villebon'),
('91587','Saulx-les-Chartreux','9135','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Villebon'),
('91161','Chilly-Mazarin','9128','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Chilly-Mazarin'),
('91432','Morangis','9128','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Chilly-Mazarin'),
('91689','Wissous','9128','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Chilly-Mazarin'),
('91235','Fleury-Mérogis','9131','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Morsang-sur-Orge'),
('91434','Morsang-sur-Orge','9131','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Morsang-sur-Orge'),
('91286','Grigny','9131','1976-03-07','1985-03-10','75-1116 art. 1er : canton de Morsang-sur-Orge'),
('91286','Grigny','9140','1985-03-10','1998-03-15','85-83 art. 5 : canton de Grigny'),
('91570','Saint-Michel-sur-Orge','9133','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Michel-sur-Orge'),
('91657','Vigneux-sur-Seine','9134','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Vigneux-sur-Seine'),
('91191','Crosne','9136','1976-03-07','1998-03-15','75-1116 art. 1er : canton d''Yerres'),
('91691','Yerres','9136','1976-03-07','1998-03-15','75-1116 art. 1er : canton d''Yerres'),
('91225','Étiolles','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91600','Soisy-sur-Seine','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91435','Morsang-sur-Seine','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91577','Saintry-sur-Seine','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91553','Saint-Germain-lès-Corbeil','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91573','Saint-Pierre-du-Perray','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91617','Tigery','9132','1976-03-07','1998-03-15','75-1116 art. 1er : canton de Saint-Germain-lès-Corbeil'),
('91216','Épinay-sur-Orge','9114','1976-03-07','1998-03-15','75-1116 art. 2 : rattachée au canton de Longjumeau'),
('91667','Villemoisson-sur-Orge','9114','1976-03-07','1998-03-15','75-1116 art. 2 : rattachée au canton de Longjumeau'),
('91685','Villiers-sur-Orge','9114','1976-03-07','1998-03-15','75-1116 art. 2 : rattachée au canton de Longjumeau'),
('91333','Leuville-sur-Orge','9101','1976-03-07','1998-03-15','75-1116 art. 2 : rattachée au canton d''Arpajon'),
('91086','Bondoufle','9110','1976-03-07','1998-03-15','75-1116 art. 2 : canton d''Évry, Évry-Sud en 1985'),
('91182','Courcouronnes','9110','1976-03-07','1985-03-10','canton d''Évry (bout gauche), non touché en 1976'),
('91182','Courcouronnes','9139','1985-03-10','1998-03-15','85-83 art. 3 : canton d''Évry-Nord'),
('91692','Les Ulis','9143','1985-03-10','1998-03-15','85-83 art. 6 : canton des Ulis'),
-- Val-d'Oise
('95392','Mériel','9514','1968-01-01','1976-03-07','67-593 : canton de L''Isle-Adam'),
('95141','Charmont','9516','1968-01-01','1985-03-10','67-593 : canton de Magny-en-Vexin, non touché en 1976'),
('95690','Wy-dit-Joli-Village','9516','1968-01-01','1985-03-10','67-593 : canton de Magny-en-Vexin, non touché en 1976'),
('95633','Vaudherland','9513','1968-01-01','1985-03-10','67-593 puis 76-78 art. 5 : canton de Gonesse'),
('95094','Bouqueval','9513','1976-03-07','1985-03-10','76-78 art. 5 : canton de Gonesse'),
('95019','Arnouville','9535','1976-03-07','1985-03-10','76-78 art. 4 : canton de Villiers-le-Bel'),
('95680','Villiers-le-Bel','9535','1976-03-07','1985-03-10','76-78 art. 4 : canton de Villiers-le-Bel'),
('95280','Goussainville','9530','1976-03-07','1985-03-10','76-78 art. 4 : canton de Goussainville'),
('95351','Louvres','9530','1976-03-07','1985-03-10','76-78 art. 4 : canton de Goussainville'),
('95039','Auvers-sur-Oise','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95120','Butry-sur-Oise','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95211','Ennery','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95258','Frouville','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95271','Génicourt','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95304','Hédouville','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95308','Hérouville','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95328','Labbeville','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95341','Livilliers','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95446','Nesles-la-Vallée','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95627','Vallangoujard','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95628','Valmondois','9534','1976-03-07','1985-03-10','76-78 art. 1er : La Vallée du Sausseron'),
('95051','Beauchamp','9528','1976-03-07','1985-03-10','76-78 art. 1er : canton de Beauchamp'),
('95488','Pierrelaye','9528','1976-03-07','1985-03-10','76-78 art. 1er : canton de Beauchamp'),
('95491','Le Plessis-Bouchard','9528','1976-03-07','1985-03-10','76-78 art. 1er : canton de Beauchamp'),
('95257','La Frette-sur-Seine','9531','1976-03-07','1985-03-10','76-78 art. 3 : canton d''Herblay'),
('95306','Herblay','9531','1976-03-07','1985-03-10','76-78 art. 3 : canton d''Herblay'),
('95424','Montigny-lès-Cormeilles','9505','1976-03-07','1985-03-10','76-78 art. 3 : canton de Cormeilles-en-Parisis'),
('95394','Méry-sur-Oise','9525','1976-03-07','1985-03-10','76-78 art. 2 : canton de Taverny'),
('95572','Saint-Ouen-l''Aumône','9521','1976-03-07','1985-03-10','76-78 art. 2 : canton de Saint-Ouen-l''Aumône');

DROP TABLE IF EXISTS t131_pose;
CREATE TEMP TABLE t131_pose AS
SELECT a.atom_id, l.*
  FROM t131_lu l JOIN atom a ON a.insee_geofla = l.insee;

\echo ''
\echo '=== 1. Garde-fous : une commune = un atome, unités en base (attendu : rien) ==='
SELECT insee, count(DISTINCT atom_id) AS atomes FROM t131_pose GROUP BY 1 HAVING count(DISTINCT atom_id) <> 1;
SELECT DISTINCT unit_id AS unite_absente FROM t131_lu
 WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = t131_lu.unit_id AND u.niveau = 'canton');

\echo ''
\echo '=== 2. Les bouts : la ligne raccorde-t-elle les rattachements voisins ? ==='
SELECT p.insee, p.nom, p.unit_id, p.du, p.au,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_to = p.du) AS gauche,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_from = p.au) AS droite
  FROM t131_pose p ORDER BY 1, 4;

\echo ''
\echo '=== 3. Garde-fou : périodes déjà prises (attendu : zéro) ==='
DROP TABLE IF EXISTS t131_pris;
CREATE TEMP TABLE t131_pris AS
SELECT p.insee, m.unit_id, m.valid_from, m.valid_to
  FROM t131_pose p JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
   AND m.periode && daterange(p.du, p.au, '[)');
SELECT * FROM t131_pris;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t131_pris;
    IF n > 0 THEN RAISE EXCEPTION '% période(s) déjà prise(s). Recette 3.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t131_pose GROUP BY 1
                                  HAVING count(DISTINCT atom_id) <> 1) d;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) à plusieurs atomes. Recette 1.', n; END IF;
END $$;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t131_pose
    RETURNING membership_id
)
INSERT INTO p131_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;
ANALYZE membership;

\echo ''
\echo '=== 4. Posé ==='
SELECT count(*) AS rattachements FROM p131_trace;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

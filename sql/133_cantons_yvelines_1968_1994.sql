-- ============================================================================
-- histgis — 133_cantons_yvelines_1968_1994.sql : les communes ENTIÈRES des
--           Yvelines sans canton entre le décret de 1967 et les cantons de 1994
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/133_cantons_yvelines_1968_1994.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/133_cantons_yvelines_1968_1994.sql
--   psql -d histgis -1 -v defaire=1 -f sql/133_cantons_yvelines_1968_1994.sql
--
-- Le pendant de `130` et `131` pour le 78. Le bout gauche y est souvent un
-- canton de Seine-et-Oise (1964-1967), le bout droit un canton de 1994 : la
-- chaîne des actes entre les deux n'avait été posée nulle part.
--
-- LA SOURCE : l'OCR des numéros du JO, relus le 25 octobre 2026 —
--   n° 67-594 du 20 juillet 1967, JO du 22 juillet 1967, p. 7362-7363
--     (`jorf_txt/JORF_19670722_169_col.txt`) : les 31 cantons des Yvelines,
--     dont Saint-Germain-en-Laye-Nord et -Sud, Poissy-Nord et -Sud, que la
--     lecture automatique avait manqués ;
--   n° 76-57 du 15 janvier 1976, JO du 22 janvier 1976
--     (`jorf_txt/JORF_19760122_18_col.txt`) : Le Chesnay, Saint-Cyr-l'École,
--     Vélizy-Villacoublay, Mantes-la-Ville, Maurepas, Le Pecq ; Jouars-
--     Pontchartrain et Saint-Rémy-lès-Chevreuse à Montfort-l'Amaury ;
--   n° 82-38 (Plaisir, `acte_composition`), n° 85-151 du 31 janvier 1985
--     (Andrésy, `jorf_txt/JORF_19850201_27_col.txt`), et l'acte du
--     27 février 1991 (Montigny-le-Bretonneux, `acte_composition`, posé au
--     22 mars 1992 comme les 6 497 autres rattachements de cet acte-là).
--
-- LES UNITÉS : celles des Yvelines portent les codes 7801-7839 de la
-- Seine-et-Oise (`132`) ; on prend celle dont le nom de 1999 est le canton du
-- décret. Une seule n'a pas d'unité : Versailles-Ouest de 1967 (Guyancourt,
-- Montigny-le-Bretonneux, Saint-Cyr-l'École et l'ouest de Versailles), son
-- code `7839` étant pris par Andrésy dès 1985. Elle est créée ici,
-- `Y78-Versailles-Ouest`, sur [1968-01-01, 1992-03-22).
--
-- Châteaufort et Toussus-le-Noble, rattachés aux Yvelines au 21 novembre
-- 1969, sont posés à Versailles-Sud de 1976 à 1994, le canton que la base
-- leur donne aux deux bouts.
--
-- CE QU'IL NE FAIT PAS : Versailles, Saint-Germain-en-Laye, Poissy (villes
-- coupées), et les communes mortes avant 1968 (Arthieul, Blamécourt,
-- Congerville, Craches, Maincourt, Thionville-sur-Opton).
--
-- Réversible : `p133_trace`. Rejouable. Après `132`, avant `128`.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p133_trace (
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
 WHERE EXISTS (SELECT 1 FROM p133_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM p133_trace t WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM p133_trace t WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM p133_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t133_lu;
CREATE TEMP TABLE t133_lu (insee text, nom text, unit_id text, du date, au date, fonde text);
INSERT INTO t133_lu VALUES
('78005','Achères','7820','1968-01-01','1994-03-20','67-594 §7 : Saint-Germain-en-Laye-Nord'),
('78007','Aigremont','7821','1968-01-01','1994-03-20','67-594 §8 : Saint-Germain-en-Laye-Sud'),
('78133','Chambourcy','7821','1968-01-01','1994-03-20','67-594 §8 : Saint-Germain-en-Laye-Sud'),
('78251','Fourqueux','7821','1968-01-01','1976-03-07','67-594 §8 : Saint-Germain-en-Laye-Sud'),
('78251','Fourqueux','7835','1976-03-07','1994-03-20','76-57 art. 1er : canton du Pecq'),
('78367','Mareil-Marly','7821','1968-01-01','1976-03-07','67-594 §8 : Saint-Germain-en-Laye-Sud'),
('78367','Mareil-Marly','7835','1976-03-07','1994-03-20','76-57 art. 1er : canton du Pecq'),
('78481','Le Pecq','7821','1968-01-01','1976-03-07','67-594 §8 : Saint-Germain-en-Laye-Sud'),
('78481','Le Pecq','7835','1976-03-07','1994-03-20','76-57 art. 1er : canton du Pecq'),
('78010','Les Alluets-le-Roi','7817','1968-01-01','1994-03-20','67-594 §10 : Poissy-Sud'),
('78189','Crespières','7817','1968-01-01','1994-03-20','67-594 §10 : Poissy-Sud'),
('78196','Davron','7817','1968-01-01','1994-03-20','67-594 §10 : Poissy-Sud'),
('78431','Morainvilliers','7817','1968-01-01','1994-03-20','67-594 §10 : Poissy-Sud'),
('78466','Orgeval','7817','1968-01-01','1994-03-20','67-594 §10 : Poissy-Sud'),
('78123','Carrières-sous-Poissy','7816','1968-01-01','1994-03-20','67-594 §9 : Poissy-Nord'),
('78384','Médan','7816','1968-01-01','1994-03-20','67-594 §9 : Poissy-Nord'),
('78672','Villennes-sur-Seine','7816','1968-01-01','1994-03-20','67-594 §9 : Poissy-Nord'),
('78015','Andrésy','7806','1968-01-01','1985-03-10','67-594 §14 : Conflans-Sainte-Honorine'),
('78138','Chanteloup-les-Vignes','7806','1968-01-01','1985-03-10','67-594 §14 : Conflans-Sainte-Honorine'),
('78382','Maurecourt','7806','1968-01-01','1985-03-10','67-594 §14 : Conflans-Sainte-Honorine'),
('78172','Conflans-Sainte-Honorine','7806','1968-01-01','1994-03-20','67-594 §14 : Conflans-Sainte-Honorine'),
('78092','Bougival','7803','1968-01-01','1994-03-20','67-594 §11 : La Celle-Saint-Cloud'),
('78126','La Celle-Saint-Cloud','7803','1968-01-01','1994-03-20','67-594 §11 : La Celle-Saint-Cloud'),
('78146','Chatou','7804','1968-01-01','1994-03-20','67-594 §12 : Chatou'),
('78190','Croissy-sur-Seine','7804','1968-01-01','1994-03-20','67-594 §12 : Chatou'),
('78418','Montesson','7830','1968-01-01','1994-03-20','67-594 §13 : Le Vésinet'),
('78650','Le Vésinet','7830','1968-01-01','1994-03-20','67-594 §13 : Le Vésinet'),
('78311','Houilles','7809','1968-01-01','1994-03-20','67-594 : Houilles'),
('78124','Carrières-sur-Seine','7809','1968-01-01','1994-03-20','67-594 : Houilles'),
('78358','Maisons-Laffitte','7811','1968-01-01','1994-03-20','67-594 : Maisons-Laffitte'),
('78396','Le Mesnil-le-Roi','7811','1968-01-01','1994-03-20','67-594 : Maisons-Laffitte'),
('78586','Sartrouville','7823','1968-01-01','1994-03-20','67-594 §18 : Sartrouville'),
('78224','L''Étang-la-Ville','7822','1968-01-01','1994-03-20','67-594 §20 : Saint-Nom-la-Bretèche'),
('78686','Viroflay','7831','1968-01-01','1994-03-20','67-594 §5 : Viroflay'),
('78640','Vélizy-Villacoublay','7831','1968-01-01','1976-03-07','67-594 §5 : Viroflay'),
('78640','Vélizy-Villacoublay','7837','1976-03-07','1994-03-20','76-57 art. 1er : canton de Vélizy-Villacoublay'),
('78158','Le Chesnay','7827','1968-01-01','1976-03-07','67-594 §3 : Versailles-Nord-Ouest'),
('78158','Le Chesnay','7832','1976-03-07','1994-03-20','76-57 art. 1er : canton du Chesnay'),
('78524','Rocquencourt','7827','1968-01-01','1976-03-07','67-594 §3 : Versailles-Nord-Ouest'),
('78524','Rocquencourt','7832','1976-03-07','1994-03-20','76-57 art. 1er : canton du Chesnay'),
('78545','Saint-Cyr-l''École','Y78-Versailles-Ouest','1968-01-01','1976-03-07','67-594 §4 : Versailles-Ouest'),
('78545','Saint-Cyr-l''École','7836','1976-03-07','1994-03-20','76-57 art. 1er : canton de Saint-Cyr-l''École'),
('78073','Bois-d''Arcy','7824','1968-01-01','1976-03-07','67-594 §6 : Trappes'),
('78073','Bois-d''Arcy','7836','1976-03-07','1994-03-20','76-57 art. 1er : canton de Saint-Cyr-l''École'),
('78242','Fontenay-le-Fleury','7824','1968-01-01','1976-03-07','67-594 §6 : Trappes'),
('78242','Fontenay-le-Fleury','7836','1976-03-07','1994-03-20','76-57 art. 1er : canton de Saint-Cyr-l''École'),
('78117','Buc','7829','1968-01-01','1994-03-20','67-594 §2 : Versailles-Sud'),
('78322','Jouy-en-Josas','7829','1968-01-01','1994-03-20','67-594 §2 : Versailles-Sud'),
('78343','Les Loges-en-Josas','7829','1968-01-01','1994-03-20','67-594 §2 : Versailles-Sud'),
('78143','Châteaufort','7829','1976-03-07','1994-03-20','Versailles-Sud aux deux bouts (Yvelines au 21 novembre 1969)'),
('78620','Toussus-le-Noble','7829','1976-03-07','1994-03-20','Versailles-Sud aux deux bouts (Yvelines au 21 novembre 1969)'),
('78297','Guyancourt','Y78-Versailles-Ouest','1968-01-01','1992-03-22','67-594 §4 : Versailles-Ouest'),
('78297','Guyancourt','7828','1992-03-22','1994-03-20','acte du 27 février 1991 : canton de Montigny-le-Bretonneux'),
('78423','Montigny-le-Bretonneux','Y78-Versailles-Ouest','1968-01-01','1992-03-22','67-594 §4 : Versailles-Ouest'),
('78423','Montigny-le-Bretonneux','7828','1992-03-22','1994-03-20','acte du 27 février 1991 : canton de Montigny-le-Bretonneux'),
('78490','Plaisir','7824','1968-01-01','1982-03-14','67-594 §6 : Trappes'),
('78165','Les Clayes-sous-Bois','7824','1968-01-01','1982-03-14','67-594 §6 : Trappes'),
('78615','Thiverval-Grignon','7824','1968-01-01','1982-03-14','67-594 §6 : Trappes'),
('78621','Trappes','7824','1968-01-01','1994-03-20','67-594 §6 : Trappes'),
('78128','Cernay-la-Ville','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78160','Chevreuse','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78162','Choisel','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78193','Dampierre-en-Yvelines','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78334','Lévis-Saint-Nom','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78356','Magny-les-Hameaux','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78397','Le Mesnil-Saint-Denis','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78406','Milon-la-Chapelle','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78548','Saint-Forget','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78561','Saint-Lambert','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78590','Senlisse','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78688','Voisins-le-Bretonneux','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse'),
('78576','Saint-Rémy-l''Honoré','7805','1968-01-01','1994-03-20','67-594 §23 : Chevreuse, non touchée en 1976'),
('78321','Jouars-Pontchartrain','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78321','Jouars-Pontchartrain','7815','1976-03-07','1994-03-20','76-57 art. 2 : rattachée au canton de Montfort-l''Amaury'),
('78575','Saint-Rémy-lès-Chevreuse','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78575','Saint-Rémy-lès-Chevreuse','7815','1976-03-07','1994-03-20','76-57 art. 2 : rattachée au canton de Montfort-l''Amaury'),
('78168','Coignières','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78168','Coignières','7834','1976-03-07','1994-03-20','76-57 art. 1er : canton de Maurepas'),
('78208','Élancourt','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78208','Élancourt','7834','1976-03-07','1994-03-20','76-57 art. 1er : canton de Maurepas'),
('78383','Maurepas','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78383','Maurepas','7834','1976-03-07','1994-03-20','76-57 art. 1er : canton de Maurepas'),
('78644','La Verrière','7805','1968-01-01','1976-03-07','67-594 §23 : Chevreuse'),
('78644','La Verrière','7834','1976-03-07','1994-03-20','76-57 art. 1er : canton de Maurepas'),
('78465','Orgerus','7815','1976-03-07','1994-03-20','67-594 : Montfort-l''Amaury, non touchée en 1976'),
('78605','Tacoignières','7815','1976-03-07','1994-03-20','67-594 : Montfort-l''Amaury, non touchée en 1976'),
('78140','Chapet','7801','1976-03-07','1994-03-20','67-594 : Aubergenville, non touchée en 1976');

-- L'unité Versailles-Ouest de 1967
INSERT INTO unit (unit_id, niveau, dep, code, nom, provisoire)
SELECT 'Y78-Versailles-Ouest', 'canton', '78', NULL, 'Versailles-Ouest', false
 WHERE NOT EXISTS (SELECT 1 FROM unit WHERE unit_id = 'Y78-Versailles-Ouest');
\if :{?appliquer}
INSERT INTO p133_trace (quoi, cle)
SELECT 'unit', 'Y78-Versailles-Ouest'
 WHERE NOT EXISTS (SELECT 1 FROM p133_trace WHERE cle = 'Y78-Versailles-Ouest');
INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT 'Y78-Versailles-Ouest', 'Versailles-Ouest', '1968-01-01', '1992-03-22'
 WHERE NOT EXISTS (SELECT 1 FROM unit_version WHERE unit_id = 'Y78-Versailles-Ouest');
\endif

DROP TABLE IF EXISTS t133_pose;
CREATE TEMP TABLE t133_pose AS
SELECT a.atom_id, l.*
  FROM t133_lu l JOIN atom a ON a.insee_geofla = l.insee;

\echo ''
\echo '=== 1. Garde-fous : une commune = un atome, unités en base (attendu : rien) ==='
SELECT insee, count(DISTINCT atom_id) AS atomes FROM t133_pose GROUP BY 1 HAVING count(DISTINCT atom_id) <> 1;
SELECT DISTINCT unit_id AS unite_absente FROM t133_lu
 WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = t133_lu.unit_id AND u.niveau = 'canton');

\echo ''
\echo '=== 2. Les bouts : la ligne raccorde-t-elle les rattachements voisins ? ==='
SELECT p.insee, p.nom, p.unit_id, p.du, p.au,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_to = p.du) AS gauche,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
           AND m.valid_from = p.au) AS droite
  FROM t133_pose p ORDER BY 1, 4;

\echo ''
\echo '=== 3. Garde-fou : périodes déjà prises (attendu : zéro) ==='
DROP TABLE IF EXISTS t133_pris;
CREATE TEMP TABLE t133_pris AS
SELECT p.insee, m.unit_id, m.valid_from, m.valid_to
  FROM t133_pose p JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
   AND m.periode && daterange(p.du, p.au, '[)');
SELECT * FROM t133_pris;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t133_pris;
    IF n > 0 THEN RAISE EXCEPTION '% période(s) déjà prise(s). Recette 3.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t133_pose GROUP BY 1
                                  HAVING count(DISTINCT atom_id) <> 1) d;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) à plusieurs atomes. Recette 1.', n; END IF;
END $$;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t133_pose
    RETURNING membership_id
)
INSERT INTO p133_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;
ANALYZE membership;

\echo ''
\echo '=== 4. Posé ==='
SELECT quoi, count(*) FROM p133_trace GROUP BY 1;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

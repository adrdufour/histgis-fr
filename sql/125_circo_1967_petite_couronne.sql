-- ============================================================================
-- histgis — 125_circo_1967_petite_couronne.sql : les circonscriptions de la
--           loi du 12 juillet 1966 dans les Hauts-de-Seine, la
--           Seine-Saint-Denis et le Val-de-Marne
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/125_circo_1967_petite_couronne.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/125_circo_1967_petite_couronne.sql
--   psql -d histgis -1 -v defaire=1 -f sql/125_circo_1967_petite_couronne.sql
--
-- LE TROU
-- =======
-- De 1968 au 24 novembre 1986, les 123 communes des 92, 93 et 94 n'avaient
-- aucune circonscription : `88` arrête la Seine au 1er janvier 1968, la
-- Seine-et-Oise de 1958 n'est pas transcrite, et `28` ne commence qu'en 1986.
-- C'est la ligne « 1968-1985 — la banlieue passe aux 92, 93, 94 » du § 4 bis
-- de RESTE_A_FAIRE.
--
-- LA SOURCE
-- =========
-- Gaudillère, cartes « 1967-1986 (1) — 1 : Loi du 12 juillet 1966 » des
-- trois départements (photos 130 à 132 de `photos/1940_1995/`, p. 683 sq.).
-- Le fond est COMMUNAL (« N.B. : le fond de carte représente les communes, et
-- non les cantons ») et aucune commune n'y est divisée : la règle est donc une
-- liste de communes par circonscription, lue le 24 octobre 2026. Contrôle de
-- lecture : chaque département est couvert exactement, 36 + 40 + 47 communes,
-- ni absente ni double (recette 1).
--
-- Lectures qui ont demandé un agrandissement : Vaucresson est séparée de
-- Rueil et de Garches par le trait fort, pas de Marnes (9e et non 8e) ; le
-- trait Stains / La Courneuve est fin (Stains en 3e avec La Courneuve et
-- Aubervilliers) ; Joinville est séparée de Nogent et de Saint-Maurice, pas de
-- Saint-Maur (5e), et Champigny n'est séparée de Nogent que par un trait fin
-- (6e).
--
-- LA DATE
-- =======
-- La loi a joué aux législatives de mars 1967. La base fait pourtant commencer
-- ces unités au 1er janvier 1968, date à laquelle les départements naissent :
-- `88` a posé les circonscriptions de la Seine de 1958 jusqu'à cette date, et
-- une unité `dep = 92` portée par des atomes encore rangés dans la Seine
-- referait le « 99 fantôme » de la Meurthe (RESTE_A_FAIRE § 0 bis a). Les dix
-- mois de 1967 restent donc dans la Seine de 1958 : un écart CONNU, écrit ici,
-- à reprendre avec `88` le jour où l'on bougera la naissance des départements.
--
-- QUELS ATOMES
-- ============
-- Une commune entière va dans une circonscription : il suffit de choisir les
-- atomes qui la DESSINENT à chaque date. Règle, intervalle par intervalle
-- (les bornes sont celles des rattachements cantonaux des atomes de la
-- commune dans la fenêtre) :
--   * les atomes qui ont un canton à cette date ;
--   * à défaut — trou cantonal, Colombes de 1968 à 1998 par exemple —, les
--     atomes qui portent la circonscription de 1986 au 24 novembre 1986 :
--     ce sont eux que la carte dessine juste après, et c'est la continuité
--     que la page montrera ;
--   * à défaut encore, l'atome non fractionnaire de la commune.
-- Le défaut est compté en recette 3 : ce sont des communes dont la carte
-- cantonale est vide et la carte des circonscriptions pleine.
--
-- Réversible : `circo_1967_trace`. Rejouable : retire sa trace avant de poser.
-- Il LIT les cantons : il passe après ce qui en pose, à côté de `122`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set du '1968-01-01'
\set au '1986-11-24'

CREATE TABLE IF NOT EXISTS circo_1967_trace (
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
 WHERE EXISTS (SELECT 1 FROM circo_1967_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_1967_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_1967_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_1967_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- ---------------------------------------------------------------------------
-- La lecture de l'atlas : département, circonscription, INSEE, nom lu
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t125_lu;
CREATE TEMP TABLE t125_lu (dep text, circo int, insee text, nom text);
INSERT INTO t125_lu VALUES
('92', 1,'92036','Gennevilliers'), ('92', 1,'92078','Villeneuve-la-Garenne'),
('92', 2,'92004','Asnières-sur-Seine'),
('92', 3,'92025','Colombes'), ('92', 3,'92009','Bois-Colombes'),
('92', 4,'92024','Clichy'), ('92', 4,'92044','Levallois-Perret'),
('92', 5,'92026','Courbevoie'), ('92', 5,'92035','La Garenne-Colombes'),
('92', 6,'92051','Neuilly-sur-Seine'), ('92', 6,'92062','Puteaux'),
('92', 7,'92050','Nanterre'), ('92', 7,'92073','Suresnes'),
('92', 8,'92063','Rueil-Malmaison'), ('92', 8,'92033','Garches'),
('92', 8,'92064','Saint-Cloud'),
('92', 9,'92076','Vaucresson'), ('92', 9,'92047','Marnes-la-Coquette'),
('92', 9,'92077','Ville-d''Avray'), ('92', 9,'92072','Sèvres'),
('92', 9,'92022','Chaville'), ('92', 9,'92048','Meudon'),
('92',10,'92012','Boulogne-Billancourt'),
('92',11,'92040','Issy-les-Moulineaux'), ('92',11,'92075','Vanves'),
('92',11,'92046','Malakoff'),
('92',12,'92023','Clamart'), ('92',12,'92020','Châtillon'),
('92',12,'92032','Fontenay-aux-Roses'), ('92',12,'92060','Le Plessis-Robinson'),
('92',12,'92071','Sceaux'), ('92',12,'92019','Châtenay-Malabry'),
('92',13,'92049','Montrouge'), ('92',13,'92007','Bagneux'),
('92',13,'92014','Bourg-la-Reine'), ('92',13,'92002','Antony'),

('93', 1,'93031','Épinay-sur-Seine'), ('93', 1,'93079','Villetaneuse'),
('93', 1,'93059','Pierrefitte-sur-Seine'), ('93', 1,'93039','L''Île-Saint-Denis'),
('93', 1,'93070','Saint-Ouen'),
('93', 2,'93066','Saint-Denis'),
('93', 3,'93072','Stains'), ('93', 3,'93027','La Courneuve'),
('93', 3,'93001','Aubervilliers'),
('93', 4,'93030','Dugny'), ('93', 4,'93013','Le Bourget'),
('93', 4,'93029','Drancy'), ('93', 4,'93008','Bobigny'),
('93', 5,'93010','Bondy'), ('93', 5,'93057','Les Pavillons-sous-Bois'),
('93', 5,'93077','Villemomble'), ('93', 5,'93053','Noisy-le-Sec'),
('93', 5,'93063','Romainville'),
('93', 6,'93055','Pantin'), ('93', 6,'93061','Le Pré-Saint-Gervais'),
('93', 6,'93045','Les Lilas'), ('93', 6,'93006','Bagnolet'),
('93', 7,'93048','Montreuil'), ('93', 7,'93064','Rosny-sous-Bois'),
('93', 8,'93007','Le Blanc-Mesnil'), ('93', 8,'93005','Aulnay-sous-Bois'),
('93', 8,'93071','Sevran'), ('93', 8,'93078','Villepinte'),
('93', 8,'93073','Tremblay-lès-Gonesse'),
('93', 9,'93046','Livry-Gargan'), ('93', 9,'93062','Le Raincy'),
('93', 9,'93014','Clichy-sous-Bois'), ('93', 9,'93015','Coubron'),
('93', 9,'93074','Vaujours'), ('93', 9,'93047','Montfermeil'),
('93', 9,'93032','Gagny'), ('93', 9,'93049','Neuilly-Plaisance'),
('93', 9,'93050','Neuilly-sur-Marne'), ('93', 9,'93033','Gournay-sur-Marne'),
('93', 9,'93051','Noisy-le-Grand'),

('94', 1,'94037','Gentilly'), ('94', 1,'94003','Arcueil'),
('94', 1,'94043','Le Kremlin-Bicêtre'), ('94', 1,'94016','Cachan'),
('94', 1,'94076','Villejuif'),
('94', 2,'94038','L''Haÿ-les-Roses'), ('94', 2,'94021','Chevilly-Larue'),
('94', 2,'94034','Fresnes'), ('94', 2,'94065','Rungis'),
('94', 2,'94073','Thiais'), ('94', 2,'94022','Choisy-le-Roi'),
('94', 2,'94054','Orly'),
('94', 3,'94041','Ivry-sur-Seine'), ('94', 3,'94081','Vitry-sur-Seine'),
('94', 4,'94018','Charenton-le-Pont'), ('94', 4,'94069','Saint-Maurice'),
('94', 4,'94002','Alfortville'), ('94', 4,'94046','Maisons-Alfort'),
('94', 5,'94068','Saint-Maur-des-Fossés'), ('94', 5,'94028','Créteil'),
('94', 5,'94011','Bonneuil-sur-Marne'), ('94', 5,'94042','Joinville-le-Pont'),
('94', 6,'94052','Nogent-sur-Marne'), ('94', 6,'94058','Le Perreux-sur-Marne'),
('94', 6,'94015','Bry-sur-Marne'), ('94', 6,'94017','Champigny-sur-Marne'),
('94', 7,'94080','Vincennes'), ('94', 7,'94067','Saint-Mandé'),
('94', 7,'94033','Fontenay-sous-Bois'),
('94', 8,'94077','Villeneuve-le-Roi'), ('94', 8,'94001','Ablon-sur-Seine'),
('94', 8,'94078','Villeneuve-Saint-Georges'), ('94', 8,'94074','Valenton'),
('94', 8,'94044','Limeil-Brévannes'), ('94', 8,'94004','Boissy-Saint-Léger'),
('94', 8,'94071','Sucy-en-Brie'), ('94', 8,'94048','Marolles-en-Brie'),
('94', 8,'94070','Santeny'), ('94', 8,'94075','Villecresnes'),
('94', 8,'94047','Mandres-les-Roses'), ('94', 8,'94056','Périgny'),
('94', 8,'94053','Noiseau'), ('94', 8,'94055','Ormesson-sur-Marne'),
('94', 8,'94060','La Queue-en-Brie'), ('94', 8,'94019','Chennevières-sur-Marne'),
('94', 8,'94059','Le Plessis-Trévise'), ('94', 8,'94079','Villiers-sur-Marne');

DROP TABLE IF EXISTS t125_nom;
CREATE TEMP TABLE t125_nom (dep text, nom text);
INSERT INTO t125_nom VALUES ('92','Hauts-de-Seine'), ('93','Seine-Saint-Denis'),
                            ('94','Val-de-Marne');

\echo ''
\echo '=== 1. Lecture : chaque commune une fois, chaque département entier ==='
\echo '    (attendu : 36 / 40 / 47, doubles 0, absentes 0, inconnues 0)'
SELECT l.dep, count(*) AS lues, count(DISTINCT l.insee) AS distinctes,
       count(DISTINCT l.circo) AS circos,
       (SELECT count(DISTINCT a.insee_geofla) FROM atom a
         WHERE left(a.insee_geofla, 2) = l.dep) AS communes_base,
       (SELECT count(DISTINCT a.insee_geofla) FROM atom a
         WHERE left(a.insee_geofla, 2) = l.dep
           AND a.insee_geofla NOT IN (SELECT insee FROM t125_lu)) AS absentes,
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM atom a
                                           WHERE a.insee_geofla = l.insee)) AS inconnues
  FROM t125_lu l GROUP BY l.dep ORDER BY 1;

-- ---------------------------------------------------------------------------
-- Les intervalles : bornes cantonales des atomes de la commune dans la fenêtre
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t125_borne;
CREATE TEMP TABLE t125_borne AS
SELECT DISTINCT l.insee, b AS d
  FROM t125_lu l
  JOIN LATERAL (
        SELECT :'du'::date AS b UNION SELECT :'au'::date
        UNION
        SELECT x FROM membership m JOIN atom a USING (atom_id),
               LATERAL (VALUES (m.valid_from), (m.valid_to)) v(x)
         WHERE a.insee_geofla = l.insee AND m.niveau = 'canton'
           AND x > :'du'::date AND x < :'au'::date) z ON true;

DROP TABLE IF EXISTS t125_inter;
CREATE TEMP TABLE t125_inter AS
SELECT insee, d AS du, lead(d) OVER (PARTITION BY insee ORDER BY d) AS au
  FROM t125_borne;
DELETE FROM t125_inter WHERE au IS NULL;

DROP TABLE IF EXISTS t125_brut;
CREATE TEMP TABLE t125_brut AS
WITH actifs AS (
    SELECT i.insee, i.du, i.au, a.atom_id, 'canton'::text AS voie
      FROM t125_inter i
      JOIN atom a ON a.insee_geofla = i.insee
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id
                    AND m.niveau = 'canton' AND m.periode @> i.du)
), repli86 AS (
    SELECT i.insee, i.du, i.au, a.atom_id, 'circo_1986'::text AS voie
      FROM t125_inter i
      JOIN atom a ON a.insee_geofla = i.insee
     WHERE NOT EXISTS (SELECT 1 FROM actifs x WHERE x.insee = i.insee AND x.du = i.du)
       AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id
                    AND m.niveau = 'circo' AND m.periode @> :'au'::date)
), entier AS (
    SELECT i.insee, i.du, i.au, a.atom_id, 'entier'::text AS voie
      FROM t125_inter i
      JOIN atom a ON a.insee_geofla = i.insee AND NOT a.fraction
     WHERE NOT EXISTS (SELECT 1 FROM actifs x WHERE x.insee = i.insee AND x.du = i.du)
       AND NOT EXISTS (SELECT 1 FROM repli86 x WHERE x.insee = i.insee AND x.du = i.du)
)
SELECT * FROM actifs UNION ALL SELECT * FROM repli86 UNION ALL SELECT * FROM entier;

-- Fusion des intervalles contigus d'un même atome (îlots)
DROP TABLE IF EXISTS t125_pose;
CREATE TEMP TABLE t125_pose AS
WITH o AS (
    SELECT b.*, l.dep, l.dep || '-' || lpad(l.circo::text, 2, '0') || '@1967' AS unit_id,
           CASE WHEN b.du = lag(b.au) OVER (PARTITION BY b.atom_id ORDER BY b.du)
                THEN 0 ELSE 1 END AS neuf
      FROM t125_brut b JOIN t125_lu l USING (insee)
), g AS (
    SELECT o.*, sum(neuf) OVER (PARTITION BY atom_id ORDER BY du) AS ilot FROM o
)
SELECT atom_id, insee, dep, unit_id, min(du) AS valid_from, max(au) AS valid_to,
       string_agg(DISTINCT voie, '+') AS voie
  FROM g GROUP BY atom_id, insee, dep, unit_id, ilot;

\echo ''
\echo '=== 2. Ce qui sera posé ==='
SELECT dep, count(DISTINCT unit_id) AS circos, count(DISTINCT insee) AS communes,
       count(DISTINCT atom_id) AS atomes, count(*) AS rattachements
  FROM t125_pose GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Communes portées hors canton (trou cantonal dans la fenêtre) ==='
SELECT p.dep, p.insee, l.nom, p.voie, min(p.valid_from) AS du, max(p.valid_to) AS au,
       count(DISTINCT p.atom_id) AS atomes
  FROM t125_pose p JOIN t125_lu l USING (insee)
 WHERE p.voie <> 'canton'
 GROUP BY 1, 2, 3, 4 ORDER BY 1, 2;

\echo ''
\echo '=== 4. Garde-fou : couverture sans trou de [1968, 1986-11-24) par commune (attendu : zéro) ==='
SELECT l.insee, l.nom
  FROM t125_lu l
 WHERE NOT EXISTS (
       SELECT 1 FROM (SELECT range_agg(daterange(valid_from, valid_to)) r
                        FROM t125_pose p WHERE p.insee = l.insee) z
        WHERE z.r = datemultirange(daterange(:'du', :'au')));

\echo ''
\echo '=== 5. Garde-fou : périodes déjà prises au niveau circo (attendu : zéro) ==='
DROP TABLE IF EXISTS t125_pris;
CREATE TEMP TABLE t125_pris AS
SELECT p.atom_id, p.insee, m.unit_id, m.valid_from, m.valid_to
  FROM t125_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
SELECT * FROM t125_pris ORDER BY 1 LIMIT 30;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t125_lu l
     WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.insee_geofla = l.insee);
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) lue(s) sans atome. Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t125_lu GROUP BY 1 HAVING count(*) > 1) d;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) lue(s) deux fois. Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM t125_pris;
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) existent déjà. Ce fichier COMBLE. Recette 5.', n;
    END IF;
    SELECT count(*) INTO n FROM (SELECT DISTINCT unit_id FROM t125_pose) d JOIN unit u USING (unit_id);
    IF n > 0 THEN RAISE EXCEPTION '% unité(s) déjà en base hors trace.', n; END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT DISTINCT p.unit_id, 'circo', p.dep, split_part(p.unit_id, '@', 1),
           'uninominal', 1967,
           n.nom || ' ' || ltrim(substr(p.unit_id, 4, 2), '0')
             || CASE WHEN substr(p.unit_id, 4, 2) = '01' THEN 're' ELSE 'e' END
             || ' circonscription (1967-1986)', false
      FROM t125_pose p JOIN t125_nom n USING (dep)
    RETURNING unit_id
)
INSERT INTO circo_1967_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT p.unit_id,
       n.nom || ' ' || ltrim(substr(p.unit_id, 4, 2), '0')
         || CASE WHEN substr(p.unit_id, 4, 2) = '01' THEN 're' ELSE 'e' END
         || ' circonscription', :'du'::date, :'au'::date
  FROM t125_pose p JOIN t125_nom n USING (dep);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM t125_pose
    RETURNING membership_id
)
INSERT INTO circo_1967_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 6. Posé ==='
SELECT quoi, count(*) FROM circo_1967_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 7. Communes des 92, 93, 94 sans aucune circonscription, au 1er juillet (attendu : 0 partout) ==='
SELECT y AS annee,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership m JOIN atom a USING (atom_id)
            WHERE a.insee_geofla = l.insee AND m.niveau = 'circo'
              AND m.periode @> make_date(y, 7, 1))) AS sans_circo
  FROM t125_lu l, generate_series(1968, 1986) y
 GROUP BY y ORDER BY y;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

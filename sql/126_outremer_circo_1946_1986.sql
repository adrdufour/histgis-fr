-- ============================================================================
-- histgis — 126_outremer_circo_1946_1986.sql : les circonscriptions des quatre
--           DOM entre la départementalisation et 1986
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/126_outremer_circo_1946_1986.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/126_outremer_circo_1946_1986.sql
--   psql -d histgis -1 -v defaire=1 -f sql/126_outremer_circo_1946_1986.sql
--
-- LE TROU
-- =======
-- `40` ne pose que 1986 et 2012 : de 1946 au 24 novembre 1986, la Guadeloupe,
-- la Martinique, la Guyane et La Réunion n'avaient aucune circonscription.
--
-- CE QUE CE FICHIER POSE
-- ======================
-- * [1946-03-19, 1958-01-01) — le scrutin de liste départemental de la
--   Quatrième République, comme `122` en métropole : une unité par DOM,
--   régime `liste`. La borne basse est la départementalisation (loi du
--   19 mars 1946), celle des cantons de `40` ; la haute est celle de `122`.
-- * [1958-01-01, 1986-11-24) — l'ordonnance de 1958 : Guadeloupe 3,
--   Martinique 3, La Réunion 3, Guyane 1. Bornes de `113`.
--
-- LA SOURCE (1958-1986)
-- =====================
-- Gaudillère, cartes « 1958-1986 » de la Guadeloupe, de la Martinique et de
-- La Réunion (photos 134, 136 et 139 de `photos/1940_1995/`), lues le
-- 24 octobre 2026. Le fond est communal et aucune commune n'est divisée. Les
-- îles hors carte viennent des notes de la planche de la Guadeloupe :
-- « Marie-Galante, Saint-Barthélemy et Saint-Martin : 3ème circonscription.
-- Les Saintes : 2ème circonscription. La Désirade : 1ère circonscription. »
-- (Saint-Barthélemy et Saint-Martin ne sont pas dans la trame GEOFLA 2015.)
-- La Guyane n'élit qu'un député jusqu'en 1986 : une unité pour le
-- département entier. Cilaos, détachée de Saint-Louis en 1965, est rangée
-- avec elle (2e) ; la trame n'ayant pas de date, elle porte cette
-- circonscription dès 1958.
--
-- Mayotte n'est pas département avant 2011 : rien n'est posé.
--
-- Réversible : `om_circo_1946_trace`. Rejouable. À jouer APRÈS `40`, qui
-- recrée les tables `om_*` et effacerait ce passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set debut_dep '1946-03-19'
\set bascule   '1958-01-01'
\set debut_86  '1986-11-24'

CREATE TABLE IF NOT EXISTS om_circo_1946_trace (
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
DELETE FROM om_membership m
 WHERE EXISTS (SELECT 1 FROM om_circo_1946_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.om_membership_id::text);
DELETE FROM om_unit_version v
 WHERE EXISTS (SELECT 1 FROM om_circo_1946_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM om_unit u
 WHERE EXISTS (SELECT 1 FROM om_circo_1946_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM om_circo_1946_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t126_dep;
CREATE TEMP TABLE t126_dep (dep text, nom text);
INSERT INTO t126_dep VALUES ('971','Guadeloupe'), ('972','Martinique'),
                            ('973','Guyane'), ('974','La Réunion');

-- 1958-1986 : département, circonscription, INSEE, nom lu
DROP TABLE IF EXISTS t126_lu;
CREATE TEMP TABLE t126_lu (dep text, circo int, insee text, nom text);
INSERT INTO t126_lu VALUES
-- Guadeloupe — Grande-Terre et Pointe-à-Pitre, plus La Désirade
('971',1,'97120','Pointe-à-Pitre'), ('971',1,'97113','Le Gosier'),
('971',1,'97128','Sainte-Anne'), ('971',1,'97125','Saint-François'),
('971',1,'97117','Le Moule'), ('971',1,'97119','Petit-Canal'),
('971',1,'97122','Port-Louis'), ('971',1,'97102','Anse-Bertrand'),
('971',1,'97110','La Désirade'),
-- Les Abymes, Morne-à-l'Eau, le nord et l'est de la Basse-Terre, Les Saintes
('971',2,'97101','Les Abymes'), ('971',2,'97116','Morne-à-l''Eau'),
('971',2,'97129','Sainte-Rose'), ('971',2,'97115','Lamentin'),
('971',2,'97103','Baie-Mahault'), ('971',2,'97118','Petit-Bourg'),
('971',2,'97114','Goyave'), ('971',2,'97107','Capesterre-Belle-Eau'),
('971',2,'97130','Terre-de-Bas'), ('971',2,'97131','Terre-de-Haut'),
-- La côte sous le vent, Basse-Terre, Marie-Galante
('971',3,'97111','Deshaies'), ('971',3,'97121','Pointe-Noire'),
('971',3,'97106','Bouillante'), ('971',3,'97134','Vieux-Habitants'),
('971',3,'97104','Baillif'), ('971',3,'97105','Basse-Terre'),
('971',3,'97124','Saint-Claude'), ('971',3,'97109','Gourbeyre'),
('971',3,'97133','Vieux-Fort'), ('971',3,'97132','Trois-Rivières'),
('971',3,'97112','Grand-Bourg'), ('971',3,'97108','Capesterre-de-Marie-Galante'),
('971',3,'97126','Saint-Louis'),
-- Martinique — le nord et la côte caraïbe jusqu'à Schœlcher
('972',1,'97211','Grand''Rivière'), ('972',1,'97215','Macouba'),
('972',1,'97203','Basse-Pointe'), ('972',1,'97219','Le Prêcheur'),
('972',1,'97201','L''Ajoupa-Bouillon'), ('972',1,'97214','Le Lorrain'),
('972',1,'97216','Le Marigot'), ('972',1,'97225','Saint-Pierre'),
('972',1,'97218','Le Morne-Rouge'), ('972',1,'97228','Sainte-Marie'),
('972',1,'97204','Le Carbet'), ('972',1,'97208','Fonds-Saint-Denis'),
('972',1,'97233','Le Morne-Vert'), ('972',1,'97234','Bellefontaine'),
('972',1,'97205','Case-Pilote'), ('972',1,'97229','Schœlcher'),
('972',1,'97212','Gros-Morne'), ('972',1,'97230','La Trinité'),
-- Fort-de-France, Saint-Joseph, Le Lamentin
('972',2,'97209','Fort-de-France'), ('972',2,'97224','Saint-Joseph'),
('972',2,'97213','Le Lamentin'),
-- le sud
('972',3,'97222','Le Robert'), ('972',3,'97210','Le François'),
('972',3,'97207','Ducos'), ('972',3,'97223','Saint-Esprit'),
('972',3,'97232','Le Vauclin'), ('972',3,'97220','Rivière-Pilote'),
('972',3,'97217','Le Marin'), ('972',3,'97226','Sainte-Anne'),
('972',3,'97227','Sainte-Luce'), ('972',3,'97221','Rivière-Salée'),
('972',3,'97206','Le Diamant'), ('972',3,'97231','Les Trois-Îlets'),
('972',3,'97202','Les Anses-d''Arlet'),
-- La Réunion — le nord et l'est jusqu'à Saint-Benoît
('974',1,'97411','Saint-Denis'), ('974',1,'97418','Sainte-Marie'),
('974',1,'97420','Sainte-Suzanne'), ('974',1,'97409','Saint-André'),
('974',1,'97402','Bras-Panon'), ('974',1,'97421','Salazie'),
('974',1,'97410','Saint-Benoît'),
-- l'ouest
('974',2,'97407','Le Port'), ('974',2,'97408','La Possession'),
('974',2,'97415','Saint-Paul'), ('974',2,'97423','Les Trois-Bassins'),
('974',2,'97413','Saint-Leu'), ('974',2,'97401','Les Avirons'),
('974',2,'97404','L''Étang-Salé'), ('974',2,'97414','Saint-Louis'),
('974',2,'97403','Entre-Deux'), ('974',2,'97424','Cilaos'),
-- le sud et l'est sauvage
('974',3,'97406','La Plaine-des-Palmistes'), ('974',3,'97419','Sainte-Rose'),
('974',3,'97417','Saint-Philippe'), ('974',3,'97412','Saint-Joseph'),
('974',3,'97405','Petite-Île'), ('974',3,'97416','Saint-Pierre'),
('974',3,'97422','Le Tampon');
-- Guyane : le département entier
INSERT INTO t126_lu
SELECT '973', 1, atom_id, nom FROM om_atom WHERE dep = '973';

\echo ''
\echo '=== 1. Lecture : chaque commune une fois, chaque DOM entier ==='
\echo '    (attendu 32 / 34 / 22 / 24, absentes 0, inconnues 0)'
SELECT l.dep, count(*) AS lues, count(DISTINCT l.insee) AS distinctes,
       count(DISTINCT l.circo) AS circos,
       (SELECT count(*) FROM om_atom a WHERE a.dep = l.dep) AS communes_base,
       (SELECT count(*) FROM om_atom a WHERE a.dep = l.dep
           AND a.atom_id NOT IN (SELECT insee FROM t126_lu)) AS absentes,
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM om_atom a
                                           WHERE a.atom_id = l.insee)) AS inconnues
  FROM t126_lu l GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 1 bis. Noms lus contre noms de la trame (pour relecture) ==='
SELECT l.insee, l.nom AS lu, a.nom AS trame
  FROM t126_lu l JOIN om_atom a ON a.atom_id = l.insee
 WHERE l.dep <> '973'
   AND upper(translate(replace(replace(l.nom, 'œ', 'oe'), '''', ' '),
                       'àâéèêîôûüçÀÂÉÈÊÎÔÛÜÇ-', 'aaeeeiouucAAEEEIOUUC '))
       <> upper(translate(replace(a.nom, '''', ' '), '-', ' '));

DROP TABLE IF EXISTS t126_pose;
CREATE TEMP TABLE t126_pose AS
SELECT a.atom_id, a.dep, a.dep || '-L@1946' AS unit_id,
       :'debut_dep'::date AS valid_from, :'bascule'::date AS valid_to
  FROM om_atom a WHERE a.dep IN (SELECT dep FROM t126_dep)
UNION ALL
SELECT l.insee, l.dep, l.dep || '-' || lpad(l.circo::text, 2, '0') || '@1958',
       :'bascule'::date, :'debut_86'::date
  FROM t126_lu l;

\echo ''
\echo '=== 2. Garde-fou : périodes déjà prises (attendu : zéro) ==='
DROP TABLE IF EXISTS t126_pris;
CREATE TEMP TABLE t126_pris AS
SELECT p.atom_id, m.unit_id, m.valid_from, m.valid_to
  FROM t126_pose p
  JOIN om_membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                      AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
SELECT * FROM t126_pris;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t126_lu l
     WHERE NOT EXISTS (SELECT 1 FROM om_atom a WHERE a.atom_id = l.insee);
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) lue(s) inconnue(s). Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t126_lu GROUP BY 1 HAVING count(*) > 1) d;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) lue(s) deux fois. Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM om_atom a
     WHERE a.dep IN ('971','972','973','974')
       AND NOT EXISTS (SELECT 1 FROM t126_lu l WHERE l.insee = a.atom_id);
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) de la trame non lue(s). Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM t126_pris;
    IF n > 0 THEN RAISE EXCEPTION '% rattachement(s) existent déjà. Recette 2.', n; END IF;
END $$;

WITH u AS (
    SELECT d.dep, d.dep || '-L@1946' AS unit_id, d.dep || '-L' AS code,
           'liste' AS regime, 1946 AS seg,
           d.nom || ' — scrutin de liste départemental' AS nom,
           :'debut_dep'::date AS du, :'bascule'::date AS au
      FROM t126_dep d
    UNION ALL
    SELECT DISTINCT l.dep, l.dep || '-' || lpad(l.circo::text, 2, '0') || '@1958',
           l.dep || '-' || lpad(l.circo::text, 2, '0'), 'uninominal', 1958,
           CASE WHEN l.dep = '973' THEN 'Guyane — circonscription unique'
                ELSE l.circo || CASE l.circo WHEN 1 THEN 're' ELSE 'e' END
                     || ' circonscription' END,
           :'bascule'::date, :'debut_86'::date
      FROM t126_lu l
), iu AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
    SELECT unit_id, 'circo', dep, code, regime, seg, nom FROM u
    RETURNING unit_id
), iv AS (
    INSERT INTO om_unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM u
    RETURNING unit_id
)
INSERT INTO om_circo_1946_trace (quoi, cle) SELECT 'unit', unit_id FROM iu;

WITH ins AS (
    INSERT INTO om_membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM t126_pose
    RETURNING om_membership_id
)
INSERT INTO om_circo_1946_trace (quoi, cle)
SELECT 'membership', om_membership_id::text FROM ins;

ANALYZE om_unit; ANALYZE om_membership;

\echo ''
\echo '=== 3. Posé ==='
SELECT quoi, count(*) FROM om_circo_1946_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 4. Communes sans circonscription, par DOM et par date (attendu : 0 hors Mayotte) ==='
SELECT a.dep, d,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM om_membership m WHERE m.atom_id = a.atom_id
              AND m.niveau = 'circo' AND m.periode @> d)) AS sans_circo,
       count(*) AS communes
  FROM om_atom a,
       unnest(ARRAY['1950-06-01','1962-06-01','1975-06-01','1986-06-01',
                    '1990-06-01']::date[]) d
 GROUP BY 1, 2 ORDER BY 1, 2;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

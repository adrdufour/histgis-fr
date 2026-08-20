-- ============================================================================
-- histgis — 07_reliquat.sql : les 17 communes que l'INSEE ne rattrape pas
--
-- Elles ont disparu avant 1943 (hors du champ du fichier des mouvements), ou
-- portent un code 2A/2B forgé par TRF-GIS pour la Corse. Leur devenir est
-- documenté par la base HAC (source_data/HAC/communal.tab), colonne des
-- fusions : « réunie en AAAA, à X / Y ».
--
-- Le rattachement se fait par NOM contre GEOFLA, pas par code : ces codes
-- n'existent nulle part ailleurs.
--
-- Usage : psql -d histgis -f 07_reliquat.sql   (après 05 et 06)
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Les sources d'`atom_geom` sont déclarées dans une table, pas dans un CHECK :
-- ce fichier ne connaît pas celles que 15, 21 et 24 poseront après lui, et une
-- liste écrite ici les invaliderait au moindre rejeu. Voir l'explication
-- complète en tête de `15_creation_arriere.sql`.
CREATE TABLE IF NOT EXISTS atom_geom_source (
    source   text PRIMARY KEY,
    pose_par text NOT NULL,
    note     text
);

INSERT INTO atom_geom_source (source, pose_par, note)
SELECT DISTINCT ag.source, 'préexistant',
       'trouvée en base lors de la conversion du CHECK en table'
FROM   atom_geom ag
WHERE  ag.source IS NOT NULL
ON     CONFLICT (source) DO NOTHING;

INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('geofla',        '07_reliquat.sql', 'polygone GEOFLA 2011 tel quel'),
    ('union_prefixe', '07_reliquat.sql', 'union des arrondissements municipaux'),
    ('absorbee',      '07_reliquat.sql', 'commune absorbée, polygone du successeur'),
    ('successeur',    '07_reliquat.sql', 'résolue par la chaîne des mouvements'),
    ('hac',           '07_reliquat.sql', 'fusion ancienne documentée par HAC'),
    ('hac_partage',   '07_reliquat.sql', 'HAC, territoire réparti : premier successeur retenu')
ON CONFLICT (source) DO NOTHING;

ALTER TABLE atom_geom DROP CONSTRAINT IF EXISTS atom_geom_source_check;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                    WHERE conname = 'atom_geom_source_fk') THEN
        ALTER TABLE atom_geom
            ADD CONSTRAINT atom_geom_source_fk
            FOREIGN KEY (source) REFERENCES atom_geom_source (source);
    END IF;
END $$;

-- Comparaison de noms tolérante : GEOFLA écrit en capitales sans accents,
-- HAC avec accents et apostrophes typographiques.
CREATE OR REPLACE FUNCTION nom_cle(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT replace(replace(replace(upper(translate(t,
               'àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ''’',
               'aaaeeeeiioouuucAAAEEEEIIOOUUUC  ')),
           ' ', ''), '-', ''), '.', '');
$$;

-- ---------------------------------------------------------------------------
-- Le relevé, tiré de HAC. `partage` = la commune a été répartie entre
-- plusieurs successeurs ; on retient le premier et on note les autres.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE reliquat (
    insee_ancien char(5),
    ancien_nom   text,
    cible_nom    text,
    partage      boolean,
    autres       text
);

INSERT INTO reliquat VALUES
 ('01220', 'Lompnes',                   'Hauteville-Lompnes',        false, NULL),
 ('2A237', 'Poggio',                    'Sainte-Lucie-de-Tallano',   false, NULL),
 ('2A294', 'Sant''Andrea',              'Sainte-Lucie-de-Tallano',   false, NULL),
 ('2A325', 'Tivolaggio',                'Propriano',                 false, NULL),
 ('2B044', 'Brustico',                  'Carcheto-Brustico',         false, NULL),
 ('2B076', 'Cassano',                   'Montegrosso',               false, NULL),
 ('2B151', 'Lunghignano',               'Montegrosso',               false, NULL),
 ('54448', 'Regniéville',               'Thiaucourt-Regniéville',    false, NULL),
 ('54454', 'Remenauville',              'Limey-Remenauville',        false, NULL),
 ('66131', 'Palalda',                   'Amélie-les-Bains-Palalda',  false, NULL),
 ('08227', 'Hocmont',                   'Guignicourt-sur-Vence',     true,  'Touligny'),
 ('45117', 'Creuzy',                    'Chevilly',                  true,  'Sougy'),
 ('51385', 'Moronvilliers',             'Pontfaverger-Moronvilliers', true, 'Saint-Hilaire-le-Petit / Saint-Martin-l''Heureux'),
 ('51606', 'Verdey',                    'Les Essarts-lès-Sézanne',   true,  'Lachy / Moeurs-Verdey'),
 ('60606', 'Sarron',                    'Pont-Sainte-Maxence',       true,  'Saint-Martin-Longueau'),
 ('77362', 'Pierrelez',                 'Cerneux',                   true,  'Sancy-lès-Provins');
-- 69232 Saint-Rambert-l'Île-Barbe, réunie à Lyon en 1963, est traitée à part :
-- Lyon n'existe dans GEOFLA que sous forme d'arrondissements (6938x).

-- ---------------------------------------------------------------------------
-- Rattachement par nom
-- ---------------------------------------------------------------------------
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       CASE WHEN r.partage THEN 'hac_partage' ELSE 'hac' END
FROM   atom a
JOIN   reliquat r       ON r.insee_ancien = a.insee_geofla
JOIN   geofla_commune g ON nom_cle(g.nom_comm) = nom_cle(r.cible_nom)
WHERE  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
GROUP  BY a.atom_id, r.partage;

-- Saint-Rambert-l'Île-Barbe -> Lyon, c'est-à-dire l'union des arrondissements
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       'hac'
FROM   atom a
JOIN   geofla_commune g ON g.insee_com LIKE '6938%'
WHERE  a.insee_geofla = '69232'
  AND  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
GROUP  BY a.atom_id;

ANALYZE atom_geom;

-- ---------------------------------------------------------------------------
-- Contrôles
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== Noms HAC introuvables dans GEOFLA (doit être vide) ==='
SELECT r.insee_ancien, r.ancien_nom, r.cible_nom
FROM   reliquat r
WHERE  NOT EXISTS (SELECT 1 FROM geofla_commune g
                   WHERE nom_cle(g.nom_comm) = nom_cle(r.cible_nom));

\echo ''
\echo '=== Noms HAC ambigus (plusieurs communes GEOFLA du même nom) ==='
SELECT r.insee_ancien, r.cible_nom, count(*) AS n_communes,
       array_agg(g.insee_com ORDER BY g.insee_com) AS codes
FROM   reliquat r
JOIN   geofla_commune g ON nom_cle(g.nom_comm) = nom_cle(r.cible_nom)
GROUP  BY r.insee_ancien, r.cible_nom
HAVING count(*) > 1;

\echo ''
\echo '=== Géométries, état final ==='
SELECT * FROM check_geom();

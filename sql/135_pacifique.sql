-- ============================================================================
-- histgis — 135_pacifique.sql : la Polynésie française et la Nouvelle-Calédonie
--
--   cd ~/Téléchargements/projet_carte
--   bash sql/charger_pacifique.sh                                   -- trames
--   psql -d histgis -f sql/135_pacifique.sql                        -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/135_pacifique.sql
--   psql -d histgis -1 -v defaire=1 -f sql/135_pacifique.sql
--
-- CE QUE CE FICHIER POSE
-- ======================
-- Dans l'espace `om_*` de `40` — 4326, `dep` sur trois caractères — deux
-- territoires de plus : 48 communes polynésiennes (987) et 33 calédoniennes
-- (988), avec leurs circonscriptions législatives de 1945 à 2012. Pas de
-- cantons : ni l'un ni l'autre territoire n'en a jamais eu.
--
-- LES TRAMES, ET LEURS LICENCES
-- =============================
-- Voir l'en-tête de `charger_pacifique.sh`. En bref : ISPF (ODbL) pour la
-- Polynésie, data.gouv.nc (Licence Ouverte 2.0) pour la Nouvelle-Calédonie ;
-- le `.gdb` du DITTT, sous CGU non commerciales, n'est pas lu. La source de
-- chaque forme est écrite dans `om_atom_geom.source` (`ispf2021`, `gnc2024`),
-- et c'est elle que l'export et la page lisent pour citer la bonne trame.
--
-- La forme posée est `geom_carte`, pas `geom` : `sql/trame_pacifique.py`
-- recoud la trame calédonienne, dont les communes voisines ne partagent plus
-- leurs limites (simplifiées une à une par le portail), et allège les deux à
-- 20 m sans défaire le partage des limites. Ni l'une ni l'autre ne déplace une
-- limite au-delà de cette tolérance ; le pourquoi est en tête du script.
--
-- Les codes INSEE sont `987` || IDCom de l'ISPF (Anaa 98711 … Uturoa 98758,
-- Papeete 98735) et le `code_com` du portail calédonien tel quel (Belep 98801
-- … Kouaoua 98833). Les noms sont ceux du Code officiel géographique, qui
-- sont aussi ceux des textes électoraux : l'ISPF écrit « Faa'a » et
-- « Bora Bora », la loi « Faaa » et « Bora-Bora ».
--
-- LES CIRCONSCRIPTIONS, ET LEURS SOURCES
-- ======================================
-- * [1945-10-21, 1978-03-12) — un député par territoire, circonscription
--   unique. La borne basse est l'élection de la première Constituante, où la
--   Nouvelle-Calédonie et les Établissements français de l'Océanie élisent
--   leur premier député (Charles Vernier pour l'Océanie). Avant, aucun siège :
--   ce n'est pas une lacune, il n'y a rien à poser.
-- * [1978-03-12, 1986-11-24) — loi n° 77-1340 du 8 décembre 1977 (JO
--   p. 5727), deux députés par territoire. Tableau annexé lu dans le texte
--   adopté par l'Assemblée le 6 octobre 1977 (Sénat, n° 7, 1977-1978), dont
--   l'article qui le porte a été voté conforme par le Sénat le 27 octobre
--   (Sénat, T.A. n° 6). La loi prend effet au renouvellement suivant : premier
--   tour du 12 mars 1978, comme `40` fait basculer 2012 au 10 juin.
--     Nouvelle-Calédonie : 1re « Est-Loyauté » (et les ressortissants français
--     des Nouvelles-Hébrides, sans territoire à dessiner), 2e « Ouest ».
--     Polynésie : 1re « Ouest et Sud », 2e « Est », définies en partie par
--     subdivisions administratives (Îles Sous-le-Vent, Australes ; Tuamotu-
--     Gambier, Marquises) — que la trame de l'ISPF porte commune par commune.
-- * [1986-11-24, 2013-01-01) pour la Nouvelle-Calédonie, [1986-11-24,
--   2012-06-10) pour la Polynésie — loi n° 86-1197 du 24 novembre 1986, tableau
--   n° 2, lu dans le texte définitif (Sénat, T.A. n° 6, 1986-1987). Borne basse
--   de `113` et `126`. Les législatives du 16 mars 1986, à la proportionnelle
--   sur le territoire entier (loi n° 85-691), ne sont pas posées : `113` et
--   `126` ne les posent pas non plus, et les deux espaces doivent dire la
--   même chose à la même date.
-- * [2012-06-10, 2013-01-01) pour la Polynésie — ordonnance n° 2009-935 du
--   29 juillet 2009, tableau n° 1 bis : trois circonscriptions. La
--   Nouvelle-Calédonie y est « sans changement » : ses unités de 1986 courent
--   donc jusqu'au bout de la période, sans segment 2012.
--
-- Kouaoua (98833) n'existe que depuis le 28 avril 1995, détachée de Canala.
-- Son atome suit donc Canala avant cette date : unique, puis Est-Loyauté, puis
-- 2e — c'est la circonscription de son territoire, non de la commune, et la
-- base n'a pas d'autre maille. Son nom, lui, est anachronique avant 1995.
--
-- CE QUE CE FICHIER NE FAIT PAS
-- =============================
-- Pas de géométrie datée : la trame est un instantané récent, comme GEOFLA
-- 2015 pour les DOM. Les communes polynésiennes datent de 1972 (Papeete est
-- plus ancienne), les calédoniennes de 1961-1969 : avant, l'atome est un
-- morceau de territoire nommé d'après la commune qui l'occupera.
--
-- Pas de Wallis-et-Futuna : pas de commune de droit, pas de trame ouverte.
--
-- Réversible : `om_pacifique_trace`. Rejouable. À jouer APRÈS `40`, qui
-- recrée les tables `om_*` et effacerait ce passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set debut_45  '1945-10-21'
\set debut_78  '1978-03-12'
\set debut_86  '1986-11-24'
\set debut_12  '2012-06-10'
\set fin_12    '2013-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.om_atom') IS NULL THEN
        RAISE EXCEPTION 'om_atom absente : jouer 40_outremer.sql d''abord.';
    END IF;
    IF to_regclass('histgis.om_pf_src') IS NULL
       OR to_regclass('histgis.om_nc_src') IS NULL THEN
        RAISE EXCEPTION 'om_pf_src ou om_nc_src absente : lancer '
                        'bash sql/charger_pacifique.sh.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'histgis' AND column_name = 'geom_carte'
                      AND table_name IN ('om_pf_src', 'om_nc_src')
                   HAVING count(*) = 2) THEN
        RAISE EXCEPTION 'geom_carte absente : charger_pacifique.sh n''est pas '
                        'allé jusqu''à trame_pacifique.py.';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS om_pacifique_trace (
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
 WHERE EXISTS (SELECT 1 FROM om_pacifique_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.om_membership_id::text);
DELETE FROM om_unit_version v
 WHERE EXISTS (SELECT 1 FROM om_pacifique_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM om_unit u
 WHERE EXISTS (SELECT 1 FROM om_pacifique_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
-- `om_atom_geom` suit par ON DELETE CASCADE
DELETE FROM om_atom a
 WHERE EXISTS (SELECT 1 FROM om_pacifique_trace t
                WHERE t.quoi = 'atom' AND t.cle = a.atom_id);
DELETE FROM om_pacifique_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- ---------------------------------------------------------------------------
-- 1. Les communes : code, nom du COG, source
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t135_com;
CREATE TEMP TABLE t135_com (insee text PRIMARY KEY, nom text NOT NULL);
INSERT INTO t135_com VALUES
('98711','Anaa'), ('98712','Arue'), ('98713','Arutua'), ('98714','Bora-Bora'),
('98715','Faaa'), ('98716','Fakarava'), ('98717','Fangatau'),
('98718','Fatu-Hiva'), ('98719','Gambier'), ('98720','Hao'),
('98721','Hikueru'), ('98722','Hitiaa O Te Ra'), ('98723','Hiva-Oa'),
('98724','Huahine'), ('98725','Mahina'), ('98726','Makemo'),
('98727','Manihi'), ('98728','Maupiti'), ('98729','Moorea-Maiao'),
('98730','Napuka'), ('98731','Nuku-Hiva'), ('98732','Nukutavake'),
('98733','Paea'), ('98734','Papara'), ('98735','Papeete'), ('98736','Pirae'),
('98737','Pukapuka'), ('98738','Punaauia'), ('98739','Raivavae'),
('98740','Rangiroa'), ('98741','Rapa'), ('98742','Reao'),
('98743','Rimatara'), ('98744','Rurutu'), ('98745','Tahaa'),
('98746','Tahuata'), ('98747','Taiarapu-Est'), ('98748','Taiarapu-Ouest'),
('98749','Takaroa'), ('98750','Taputapuatea'), ('98751','Tatakoto'),
('98752','Teva I Uta'), ('98753','Tubuai'), ('98754','Tumaraa'),
('98755','Tureia'), ('98756','Ua-Huka'), ('98757','Ua-Pou'),
('98758','Uturoa'),
('98801','Belep'), ('98802','Boulouparis'), ('98803','Bourail'),
('98804','Canala'), ('98805','Dumbéa'), ('98806','Farino'),
('98807','Hienghène'), ('98808','Houaïlou'), ('98809','L''Île-des-Pins'),
('98810','Kaala-Gomen'), ('98811','Koné'), ('98812','Koumac'),
('98813','La Foa'), ('98814','Lifou'), ('98815','Maré'),
('98816','Moindou'), ('98817','Le Mont-Dore'), ('98818','Nouméa'),
('98819','Ouégoa'), ('98820','Ouvéa'), ('98821','Païta'),
('98822','Poindimié'), ('98823','Ponérihouen'), ('98824','Pouébo'),
('98825','Pouembout'), ('98826','Poum'), ('98827','Poya'),
('98828','Sarraméa'), ('98829','Thio'), ('98830','Touho'), ('98831','Voh'),
('98832','Yaté'), ('98833','Kouaoua');

DROP TABLE IF EXISTS t135_src;
CREATE TEMP TABLE t135_src AS
SELECT '987' || p.idcom::text AS insee, p.commune AS nom_src, p.sub,
       p.geom_carte AS geom, 'ispf2021' AS source
  FROM om_pf_src p
UNION ALL
SELECT n.code_com, n.nom_minus, NULL, n.geom_carte, 'gnc2024'
  FROM om_nc_src n;

\echo ''
\echo '=== 1. Trames : 48 + 33, chaque code une fois, chaque nom reconnu ==='
SELECT left(s.insee, 3) AS dep, count(*) AS communes,
       count(DISTINCT s.insee) AS codes,
       count(*) FILTER (WHERE c.insee IS NULL) AS hors_liste,
       round(sum(ST_Area(s.geom::geography))/1e6) AS km2
  FROM t135_src s LEFT JOIN t135_com c ON c.insee = s.insee
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '--- noms de la trame contre noms retenus (pour relecture) ---'
SELECT s.insee, s.nom_src AS trame, c.nom AS retenu
  FROM t135_src s JOIN t135_com c ON c.insee = s.insee
 WHERE upper(translate(regexp_replace(s.nom_src, '[^[:alpha:]]', '', 'g'),
                       'éèêëïîôöüàâç', 'eeeeiioouaac'))
    <> upper(translate(regexp_replace(c.nom, '[^[:alpha:]]', '', 'g'),
                       'éèêëïîôöüàâçÉÎ', 'eeeeiioouaacEI'))
 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 2. Les circonscriptions, commune par commune
-- ---------------------------------------------------------------------------
-- (dep, segment, numéro, insee). Les deux territoires sont entiers jusqu'en
-- 1978 : la circonscription unique se déduit de la trame, plus bas.
DROP TABLE IF EXISTS t135_lu;
CREATE TEMP TABLE t135_lu (dep text, seg int, circo int, insee text);

-- Polynésie 1978 : par communes et par subdivisions, comme le tableau.
-- Le nom de subdivision vient de la trame de l'ISPF.
INSERT INTO t135_lu
SELECT '987', 1978,
       CASE WHEN s.insee IN ('98735','98715','98738','98733','98734','98752',
                             '98748','98729')            -- Papeete … Moorea-Maiao
              OR s.sub IN ('Iles Sous-Le-Vent','Australes') THEN 1
            WHEN s.insee IN ('98736','98712','98725','98722','98747')
              OR s.sub IN ('Tuamotu-Gambier','Marquises') THEN 2 END,
       s.insee
  FROM t135_src s WHERE s.insee LIKE '987%';

INSERT INTO t135_lu
SELECT '988', 1978,
       CASE WHEN c.insee IN ('98824','98807','98830','98822','98823','98808',
                             '98804','98829','98832','98809','98815','98814',
                             '98820',
                             '98833')            -- Kouaoua, alors dans Canala
            THEN 1 ELSE 2 END,
       c.insee
  FROM t135_com c WHERE c.insee LIKE '988%';

-- 1986 : la Nouvelle-Calédonie par sa 1re (L'Île-des-Pins, Lifou, Maré,
-- Nouméa, Ouvéa), la 2e étant « le reste » — 27 communes nommées, plus
-- Kouaoua, détachée de Canala en 1995.
INSERT INTO t135_lu
SELECT '988', 1986,
       CASE WHEN c.insee IN ('98809','98814','98815','98818','98820')
            THEN 1 ELSE 2 END, c.insee
  FROM t135_com c WHERE c.insee LIKE '988%';

INSERT INTO t135_lu
SELECT '987', 1986,
       CASE WHEN c.nom IN ('Bora-Bora','Faaa','Huahine','Maupiti',
                           'Moorea-Maiao','Paea','Papeete','Punaauia',
                           'Raivavae','Rapa','Rimatara','Rurutu','Tahaa',
                           'Taputapuatea','Tubuai','Tumaraa','Uturoa')
            THEN 1 ELSE 2 END, c.insee
  FROM t135_com c WHERE c.insee LIKE '987%';

INSERT INTO t135_lu
SELECT '987', 2012,
       CASE WHEN c.nom IN ('Anaa','Arue','Arutua','Fakarava','Fangatau',
                           'Fatu-Hiva','Gambier','Hao','Hikueru','Hiva-Oa',
                           'Makemo','Manihi','Moorea-Maiao','Napuka',
                           'Nuku-Hiva','Nukutavake','Papeete','Pirae',
                           'Pukapuka','Rangiroa','Reao','Tahuata','Takaroa',
                           'Tatakoto','Tureia','Ua-Huka','Ua-Pou') THEN 1
            WHEN c.nom IN ('Hitiaa O Te Ra','Mahina','Paea','Papara',
                           'Raivavae','Rapa','Rimatara','Rurutu',
                           'Taiarapu-Est','Taiarapu-Ouest','Teva I Uta',
                           'Tubuai') THEN 2
            WHEN c.nom IN ('Bora-Bora','Faaa','Huahine','Maupiti','Punaauia',
                           'Tahaa','Taputapuatea','Tumaraa','Uturoa') THEN 3
       END, c.insee
  FROM t135_com c WHERE c.insee LIKE '987%';

\echo ''
\echo '=== 2. Lecture : chaque commune une fois par segment, aucune sans circo ==='
\echo '    (attendu 987 : 1978 20+28, 1986 17+31, 2012 27+12+9 ;'
\echo '             988 : 1978 14+19, 1986 5+28)'
SELECT dep, seg, circo, count(*) AS communes
  FROM t135_lu GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;

DROP TABLE IF EXISTS t135_unites;
CREATE TEMP TABLE t135_unites AS
SELECT * FROM (VALUES
  ('987-U@1945', '987', '987-U', 1945, 'Circonscription unique',
   :'debut_45'::date, :'debut_78'::date),
  ('988-U@1945', '988', '988-U', 1945, 'Circonscription unique',
   :'debut_45'::date, :'debut_78'::date),
  ('987-01@1978','987', '987-01', 1978, '1re circonscription (Ouest et Sud)',
   :'debut_78'::date, :'debut_86'::date),
  ('987-02@1978','987', '987-02', 1978, '2e circonscription (Est)',
   :'debut_78'::date, :'debut_86'::date),
  ('988-01@1978','988', '988-01', 1978,
   '1re circonscription (Est-Loyauté)', :'debut_78'::date, :'debut_86'::date),
  ('988-02@1978','988', '988-02', 1978, '2e circonscription (Ouest)',
   :'debut_78'::date, :'debut_86'::date),
  ('987-01@1986','987', '987-01', 1986, '1re circonscription',
   :'debut_86'::date, :'debut_12'::date),
  ('987-02@1986','987', '987-02', 1986, '2e circonscription',
   :'debut_86'::date, :'debut_12'::date),
  ('988-01@1986','988', '988-01', 1986, '1re circonscription',
   :'debut_86'::date, :'fin_12'::date),
  ('988-02@1986','988', '988-02', 1986, '2e circonscription',
   :'debut_86'::date, :'fin_12'::date),
  ('987-01@2012','987', '987-01', 2009, '1re circonscription',
   :'debut_12'::date, :'fin_12'::date),
  ('987-02@2012','987', '987-02', 2009, '2e circonscription',
   :'debut_12'::date, :'fin_12'::date),
  ('987-03@2012','987', '987-03', 2009, '3e circonscription',
   :'debut_12'::date, :'fin_12'::date)
) v (unit_id, dep, code, seg, nom, du, au);

DROP TABLE IF EXISTS t135_pose;
CREATE TEMP TABLE t135_pose AS
SELECT c.insee AS atom_id, left(c.insee, 3) || '-U@1945' AS unit_id
  FROM t135_com c
UNION ALL
SELECT l.insee, l.dep || '-' || lpad(l.circo::text, 2, '0') || '@'
                || CASE l.seg WHEN 1978 THEN '1978' WHEN 1986 THEN '1986'
                              ELSE '2012' END
  FROM t135_lu l;

\echo ''
\echo '=== 3. Garde-fous (attendu : zéro partout) ==='
SELECT (SELECT count(*) FROM t135_lu WHERE circo IS NULL)          AS sans_circo,
       (SELECT count(*) FROM (SELECT dep, seg, insee FROM t135_lu
                               GROUP BY 1, 2, 3 HAVING count(*) > 1) d)
                                                                    AS doublons,
       (SELECT count(*) FROM t135_pose p
         WHERE NOT EXISTS (SELECT 1 FROM t135_unites u
                            WHERE u.unit_id = p.unit_id))           AS unite_inconnue,
       (SELECT count(*) FROM t135_com c
         WHERE NOT EXISTS (SELECT 1 FROM t135_src s WHERE s.insee = c.insee))
                                                                    AS sans_forme,
       (SELECT count(*) FROM om_atom a
         WHERE a.atom_id IN (SELECT insee FROM t135_com))           AS deja_en_base;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t135_lu WHERE circo IS NULL;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) sans circonscription. Recette 2.', n; END IF;
    SELECT count(*) INTO n FROM t135_src s
     WHERE NOT EXISTS (SELECT 1 FROM t135_com c WHERE c.insee = s.insee);
    IF n > 0 THEN RAISE EXCEPTION '% forme(s) hors liste. Recette 1.', n; END IF;
    SELECT count(*) INTO n FROM t135_com c
     WHERE NOT EXISTS (SELECT 1 FROM t135_src s WHERE s.insee = c.insee);
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) sans forme. Recette 3.', n; END IF;
    SELECT count(*) INTO n FROM om_atom a
     WHERE a.atom_id IN (SELECT insee FROM t135_com);
    IF n > 0 THEN RAISE EXCEPTION '% atome(s) déjà en base hors trace. Recette 3.', n; END IF;
END $$;

-- `40` ne connaît qu'une source de forme. On élargit la contrainte plutôt
-- que de la retirer : une valeur imprévue doit continuer d'échouer.
ALTER TABLE om_atom_geom DROP CONSTRAINT IF EXISTS om_atom_geom_source_check;
ALTER TABLE om_atom_geom ADD CONSTRAINT om_atom_geom_source_check
    CHECK (source IN ('geofla2015', 'ispf2021', 'gnc2024'));

WITH ins AS (
    INSERT INTO om_atom (atom_id, dep, nom, multi)
    SELECT c.insee, left(c.insee, 3), c.nom, false FROM t135_com c
    RETURNING atom_id
)
INSERT INTO om_pacifique_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

INSERT INTO om_atom_geom (atom_id, geom, source)
SELECT s.insee, s.geom, s.source FROM t135_src s;

WITH iu AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
    SELECT unit_id, 'circo', dep, code, 'uninominal', seg, nom FROM t135_unites
    RETURNING unit_id
), iv AS (
    INSERT INTO om_unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t135_unites
    RETURNING unit_id
)
INSERT INTO om_pacifique_trace (quoi, cle) SELECT 'unit', unit_id FROM iu;

WITH ins AS (
    INSERT INTO om_membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atom_id, p.unit_id, 'circo', u.du, u.au
      FROM t135_pose p JOIN t135_unites u ON u.unit_id = p.unit_id
    RETURNING om_membership_id
)
INSERT INTO om_pacifique_trace (quoi, cle)
SELECT 'membership', om_membership_id::text FROM ins;

ANALYZE om_atom; ANALYZE om_atom_geom; ANALYZE om_unit; ANALYZE om_membership;

\echo ''
\echo '=== 4. Posé ==='
SELECT quoi, count(*) FROM om_pacifique_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 5. Communes sans circonscription, par date (attendu : 0 partout) ==='
SELECT a.dep, d,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM om_membership m WHERE m.atom_id = a.atom_id
              AND m.niveau = 'circo' AND m.periode @> d)) AS sans_circo,
       count(*) AS communes
  FROM om_atom a,
       unnest(ARRAY['1946-06-01','1977-06-01','1980-06-01','1990-06-01',
                    '2012-12-01']::date[]) d
 WHERE a.dep IN ('987', '988')
 GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 6. Recouvrement : somme - union, doit valoir 0 km² ==='
SELECT a.dep,
       round((sum(ST_Area(g.geom::geography))
              - ST_Area(ST_Union(g.geom)::geography))::numeric/1e6, 1) AS km2_recouvres,
       count(*) FILTER (WHERE NOT ST_IsValid(g.geom)) AS invalides
  FROM om_atom a JOIN om_atom_geom g ON g.atom_id = a.atom_id
 WHERE a.dep IN ('987', '988')
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 7. Pour voir ==='
SELECT unit_id, nom, n_atomes
  FROM om_snapshot('1980-06-01', 'circo') WHERE dep IN ('987','988')
UNION ALL
SELECT unit_id, nom, n_atomes
  FROM om_snapshot('2012-12-01', 'circo') WHERE dep IN ('987','988')
ORDER BY 1;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

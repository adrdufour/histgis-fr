-- ============================================================================
-- histgis — 134_correctifs_04_07_1967.sql : trois trous signalés par Adrien le
--           25 octobre 2026
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/134_correctifs_04_07_1967.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/134_correctifs_04_07_1967.sql
--   psql -d histgis -1 -v defaire=1 -f sql/134_correctifs_04_07_1967.sql
--
-- 1. ALPES-DE-HAUTE-PROVENCE, 1973-1988. Les cantons d'Allos, de Saint-Paul
--    et de Senez s'arrêtaient au 1973-09-23 (premier tour qui suit le décret
--    n° 73-714, qui ne les nomme pas), et leurs communes reparaissaient au
--    1988-09-25 dans Colmars, Barcelonnette, Barrême et Mézel : quinze ans sans
--    canton NI circonscription, donc absentes de la carte. Relus dans l'OCR :
--      n° 73-714 du 23 juillet 1973, `jorf_txt/JORF_19730725_171_col.txt` :
--        Saint-Martin-les-Eaux au canton de Manosque-Nord (art. 3) ;
--      n° 85-127 du 29 janvier 1985, `jorf_txt/JORF_19850130_25_col.txt` :
--        Allos rattachée à Colmars, « qui prend la dénomination
--        d'Allos-Colmars » ; canton d'Allos supprimé (art. 1er) ;
--        Saint-Martin-les-Eaux reste à Manosque-Nord (art. 3) ;
--      n° 86-251 du 20 février 1986, `jorf_txt/JORF_19860226_48_col.txt` :
--        Larche, Meyronnes, Saint-Paul à Barcelonnette ; Blieux et Senez à
--        Barrême, Majastres à Mézel ; cantons de Saint-Paul et de Senez
--        supprimés. Pas de cantonales avant celles du 25 septembre 1988 : la
--        base fait jouer l'acte au premier tour qui suit, comme les décrets
--        n° 88-514 et 88-891 (non lus) qui reprennent la même suppression.
--    Saint-Martin-les-Eaux est réunie à Manosque du 1975-01-01 au 1980-06-12
--    (COG) : rien pendant ce temps-là, comme toute commune absorbée.
--    Les circonscriptions suivent celles de 1958 jusqu'au 1986-11-24.
--    Marcoux (Digne, puis Digne-Est par 73-714 art. 1er) : même canton aux
--    deux bouts, trou de 1955 à 1973 comblé.
--
-- 2. ARDÈCHE, Vesseaux : au canton d'Aubenas jusqu'au jalon de 1954, à celui
--    de Vals-les-Bains dès 1973 ; rien entre les deux, et aucune
--    circonscription de 1955 à 1986. Comblé par le bout gauche (Aubenas,
--    dont les seize autres atomes sont dans la 3e de 1958) puis par la 3e
--    jusqu'en 1986, comme les sept atomes de Vals-les-Bains.
--
-- 3. LA PETITE COURONNE EN 1967. Six communes de l'ancienne Seine-et-Oise
--    (Le Raincy, Saint-Cloud, Sèvres, Chennevières, Juvisy, Argenteuil-atome
--    95014) passaient dans les cantons des nouveaux départements dès le
--    1967-09-24 (cantonales des 92 à 95), avec un trou de circonscription
--    jusqu'au 1968-01-01 : la carte du 1er décembre 1967 dessinait les 92, 93,
--    94 avec une ou deux communes, sans circonscription. Le reste de la petite
--    couronne bascule au 1968-01-01 (`125`, `127`) : ces six-là aussi. Bornes
--    déplacées en place, anciennes valeurs dans la trace.
--
-- Réversible : `p134_trace`. Rejouable. Après `133`.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p134_trace (
    quoi text NOT NULL, cle text NOT NULL,
    ancien_from date, ancien_to date,
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
 WHERE EXISTS (SELECT 1 FROM p134_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM p134_trace t
                WHERE t.quoi = 'version' AND t.cle = v.unit_version_id::text);
-- bornes rendues : d'abord celles qu'on avait allongées, puis les raccourcies
UPDATE membership m SET valid_to = t.ancien_to
  FROM p134_trace t WHERE t.quoi = 'allonge' AND t.cle = m.membership_id::text;
UPDATE membership m SET valid_from = t.ancien_from
  FROM p134_trace t WHERE t.quoi = 'raccourci' AND t.cle = m.membership_id::text;
DELETE FROM p134_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t134_lu;
CREATE TEMP TABLE t134_lu (atom_id text, niveau text, unit_id text, du date, au date, fonde text);
INSERT INTO t134_lu VALUES
-- 1. Alpes-de-Haute-Provence
('18753','canton','0424','1973-09-23','1988-09-25','Larche : canton de Saint-Paul jusqu''à 86-251'),
('21865','canton','0424','1973-09-23','1988-09-25','Meyronnes : canton de Saint-Paul jusqu''à 86-251'),
('33979','canton','0424','1973-09-23','1988-09-25','Saint-Paul : canton de Saint-Paul jusqu''à 86-251'),
('4529', 'canton','0425','1973-09-23','1988-09-25','Blieux : canton de Senez jusqu''à 86-251'),
('35979','canton','0425','1973-09-23','1988-09-25','Senez : canton de Senez jusqu''à 86-251'),
('20747','canton','0425','1973-09-23','1988-09-25','Majastres : canton de Senez jusqu''à 86-251'),
('510',  'canton','0401','1973-09-23','1985-03-10','Allos : canton d''Allos jusqu''à 85-127'),
('510',  'canton','0407','1985-03-10','1988-09-25','Allos : 85-127 art. 1er, Allos-Colmars'),
('33351','canton','0413','1973-09-23','1975-01-01','Saint-Martin-les-Eaux : 73-714 art. 3, Manosque-Nord'),
('33351','canton','0413','1980-06-12','1988-09-25','Saint-Martin-les-Eaux rétablie : 85-127 art. 3, Manosque-Nord'),
('21097','canton','0408','1955-01-01','1973-09-23','Marcoux : canton de Digne aux deux bouts'),
('18753','circo','04-01@1958','1973-09-23','1986-11-24','1958 : canton de Saint-Paul'),
('21865','circo','04-01@1958','1973-09-23','1986-11-24','1958 : canton de Saint-Paul'),
('33979','circo','04-01@1958','1973-09-23','1986-11-24','1958 : canton de Saint-Paul'),
('4529', 'circo','04-02@1958','1973-09-23','1986-11-24','1958 : canton de Senez'),
('35979','circo','04-02@1958','1973-09-23','1986-11-24','1958 : canton de Senez'),
('20747','circo','04-02@1958','1973-09-23','1986-11-24','1958 : canton de Senez'),
('510',  'circo','04-01@1958','1973-09-23','1986-11-24','1958 : canton d''Allos'),
('33351','circo','04-02@1958','1973-09-23','1975-01-01','1958 : Manosque, Reillanne'),
('33351','circo','04-02@1958','1980-06-12','1986-11-24','1958 : Manosque'),
('21097','circo','L0401@1945','1955-01-01','1958-01-01','liste départementale'),
('21097','circo','04-01@1958','1958-01-01','1973-09-23','1958 : canton de Digne'),
-- 2. Ardèche
('38588','canton','0703','1955-01-01','1973-09-23','Vesseaux : canton d''Aubenas (bout gauche)'),
('38588','circo','L0701@1945','1955-01-01','1958-01-01','liste départementale'),
('38588','circo','07-03@1958','1958-01-01','1986-11-24','1958 : Aubenas, puis Vals-les-Bains');

\echo ''
\echo '=== 1-2. À poser (attendu : 25 lignes, aucune collision) ==='
SELECT l.atom_id, l.niveau, l.unit_id, l.du, l.au,
       (SELECT string_agg(m.unit_id||' '||m.valid_from||'→'||m.valid_to, ', ')
          FROM membership m WHERE m.atom_id = l.atom_id AND m.niveau = l.niveau
           AND m.periode && daterange(l.du, l.au, '[)')) AS collision
  FROM t134_lu l ORDER BY 1, 2, 4;

-- 3. Les six bascules du 1967-09-24
DROP TABLE IF EXISTS t134_bascule;
CREATE TEMP TABLE t134_bascule AS
SELECT n.membership_id AS neuf, p.membership_id AS ancien, i.membership_id AS circo, n.atom_id
  FROM membership n
  JOIN unit un ON un.unit_id = n.unit_id
  JOIN membership p ON p.atom_id = n.atom_id AND p.niveau = 'canton' AND p.valid_to = '1967-09-24'
  JOIN unit up ON up.unit_id = p.unit_id
  JOIN membership i ON i.atom_id = n.atom_id AND i.niveau = 'circo' AND i.valid_to = '1967-09-24'
 WHERE n.niveau = 'canton' AND n.valid_from = '1967-09-24'
   AND un.dep IN ('91','92','93','94','95') AND up.dep = '78';

\echo ''
\echo '=== 3. Bascules de 1967 ramenées au 1968-01-01 (attendu : 6) ==='
SELECT b.atom_id, a.insee_geofla, n.unit_id AS neuf, p.unit_id AS ancien, i.unit_id AS circo
  FROM t134_bascule b JOIN atom a USING (atom_id)
  JOIN membership n ON n.membership_id = b.neuf
  JOIN membership p ON p.membership_id = b.ancien
  JOIN membership i ON i.membership_id = b.circo ORDER BY 2;

\if :{?appliquer}
INSERT INTO p134_trace (quoi, cle, ancien_from, ancien_to)
SELECT 'raccourci', m.membership_id::text, m.valid_from, m.valid_to
  FROM membership m WHERE m.membership_id IN (SELECT neuf FROM t134_bascule);
INSERT INTO p134_trace (quoi, cle, ancien_from, ancien_to)
SELECT 'allonge', m.membership_id::text, m.valid_from, m.valid_to
  FROM membership m WHERE m.membership_id IN (SELECT ancien FROM t134_bascule
                                              UNION SELECT circo FROM t134_bascule);
UPDATE membership SET valid_from = '1968-01-01'
 WHERE membership_id IN (SELECT neuf FROM t134_bascule);
UPDATE membership SET valid_to = '1968-01-01'
 WHERE membership_id IN (SELECT ancien FROM t134_bascule UNION SELECT circo FROM t134_bascule);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, du, au FROM t134_lu
  RETURNING membership_id)
INSERT INTO p134_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

WITH ins AS (
  INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
  VALUES ('0407', 'Allos-Colmars', '1985-03-10', '1999-01-01')
  RETURNING unit_version_id)
INSERT INTO p134_trace (quoi, cle) SELECT 'version', unit_version_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p134_trace GROUP BY 1 ORDER BY 1;
\endif
\endif

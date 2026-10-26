-- ============================================================================
-- banc_93_donnees.sql — la cible de `banc_93.sh`
--
-- Une base minuscule, bâtie pour qu'AUCUNE des cinq classes du § 4 de `93` ne
-- soit vide, et pour que chaque garde-fou ait de quoi mordre. Les effectifs ne
-- veulent rien dire ; la RÉPARTITION, si.
--
-- *Un banc qui ne fournit pas de cible ne mesure pas un tir* — trois fois payé
-- en août 2026 (Corse de `75`, couche 1999 de `76`, jalon de `81`). Ici la
-- cible est faite pour être imparfaite : elle contient exprès un désaccord, un
-- absent, une fraction, une série écourtée et une fenêtre déjà occupée.
--
-- Les onze communes des décrets portent leurs VRAIS codes INSEE, parce que
-- `93` § 5 joint `c67_attendu` par ce code : un banc qui inventerait les codes
-- ne testerait pas la jointure qui compte.
-- ============================================================================

SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- 1. Les unités — deux cantons ordinaires, et les quatre des décrets
-- ---------------------------------------------------------------------------
INSERT INTO unit (unit_id, niveau, dep, nom) VALUES
  ('0110', 'canton', '01', 'Bourg-Nord'),
  ('0111', 'canton', '01', 'Bourg-Sud'),
  ('4610', 'canton', '46', 'Latronquière'),
  ('4630', 'canton', '46', 'Sousceyrac'),
  ('1910', 'canton', '19', 'Brive'),
  ('1930', 'canton', '19', 'Brive-Sud'),
  ('0630', 'canton', '06', 'Breil'),
  ('0631', 'canton', '06', 'Tende');

-- ---------------------------------------------------------------------------
-- 2. Les atomes
-- ---------------------------------------------------------------------------
INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla) VALUES
  ('b01', 'b01', false, 1, '01001'),
  ('b02', 'b02', false, 1, '01002'),
  ('b03', 'b03', false, 1, '01003'),
  ('b04', 'b04', false, 1, '01004'),
  ('b05', 'b05', false, 1, '01005'),
  ('b06', 'b06', false, 1, '01006'),
  ('b07', 'b07', false, 1, '01007'),
  ('b08#0110', 'b08', true, 1, '01008'),
  ('b09', 'b09', false, 1, '01009'),
  ('b10', 'b10', false, 1, '01010'),
  ('b11', 'b11', false, 1, '01011'),
  ('b12', 'b12', false, 1, '01012'),
  ('b13', 'b13', false, 1, '01013'),
  ('b14', 'b14', false, 1, '01014'),
  ('c46071', '46071', false, 1, '46071'),
  ('c46141', '46141', false, 1, '46141'),
  ('c46150', '46150', false, 1, '46150'),
  ('c46311', '46311', false, 1, '46311'),
  ('c19043', '19043', false, 1, '19043'),
  ('c19063', '19063', false, 1, '19063'),
  ('c19077', '19077', false, 1, '19077'),
  ('c19093', '19093', false, 1, '19093'),
  ('c19123', '19123', false, 1, '19123'),
  ('c19147', '19147', false, 1, '19147'),
  ('c19151', '19151', false, 1, '19151');

-- ---------------------------------------------------------------------------
-- 3. LA COUCHE 1870-1940 — toutes les lignes finissent au 1941-01-01, sauf b09
--
-- b09 est la série écourtée : sa ligne meurt le 1940-09-01. Elle est vivante
-- au 1940-06-01, donc le § 3 de `93` la voit ; le § 4 doit la classer à part,
-- faute de quoi `93` poserait une ligne qui laisse quatre mois de vide sans
-- que rien ne le dise.
-- ---------------------------------------------------------------------------
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to) VALUES
  ('b01',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b02',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b03',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b04',      '0111', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b05',      '0111', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b06',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b07',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b08#0110', '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b09',      '0110', 'canton', DATE '1870-01-01', DATE '1940-09-01'),
  ('b10',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b11',      '0111', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b12',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b13',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('b14',      '0110', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c46071',   '4610', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c46141',   '4610', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c46150',   '4610', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c46311',   '4610', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19043',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19063',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19077',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19093',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19123',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19147',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01'),
  ('c19151',   '1910', 'canton', DATE '1870-01-01', DATE '1941-01-01');

-- ---------------------------------------------------------------------------
-- 4. UN OCCUPANT DANS LA FENÊTRE — b10, de 1945 à 1950
--
-- Il n'y a aucune raison historique à cette ligne : elle est là pour que le
-- tamis du § 6 ait quelque chose à écarter. Sans elle, « fenêtre entièrement
-- libre » serait une phrase qu'aucun passage n'aurait jamais exercée.
-- ---------------------------------------------------------------------------
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to) VALUES
  ('b10', '0111', 'canton', DATE '1945-01-01', DATE '1950-01-01');

-- ---------------------------------------------------------------------------
-- 5. LE JALON DE 1954 — [1954-01-01, 1955-01-01), et rien de plus
--
-- b07 en est absent : c'est la classe `absent_de_1954`.
-- b06 y change de canton : c'est la classe `desaccord`.
-- Les onze communes des décrets y sont à leur canton NEUF, ce que le report
-- brut ne peut pas deviner — c'est exactement ce que `70` § 3 annonçait.
-- ---------------------------------------------------------------------------
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to) VALUES
  ('b01',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b02',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b03',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b04',    '0111', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b05',    '0111', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b06',    '0111', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b09',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b10',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b11',    '0111', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b12',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('b13',    '0110', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c46071', '4630', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c46141', '4630', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c46150', '4630', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c46311', '4630', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19043', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19063', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19077', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19093', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19123', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19147', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01'),
  ('c19151', '1930', 'canton', DATE '1954-01-01', DATE '1955-01-01');

-- ---------------------------------------------------------------------------
-- 6. `c54_qualite` — les trois classes d'appariement, dont une manquante
--
-- b12 n'a PAS de ligne : c'est le cas de `87`, qui a rendu au jalon quatre
-- communes de la Seine sans les inscrire à la table de qualité. `93` § 3 doit
-- le voir en `hors_c54` et non le perdre. *Lire la table de qualité au lieu de
-- la donnée exclurait en silence ce qu'un correctif ultérieur a ajouté.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_qualite;
CREATE TABLE c54_qualite AS
SELECT m.membership_id,
       a.insee_geofla::char(5)                     AS insee,
       m.unit_id                                   AS canton_id,
       CASE WHEN m.atom_id = 'b11' THEN 'nom_flou_confirme'
            ELSE 'ferme' END                       AS qualite,
       CASE WHEN m.atom_id = 'b11' THEN 'ferme_canton'
            ELSE 'ferme' END                       AS appariement
FROM   membership m
JOIN   atom a ON a.atom_id = m.atom_id
WHERE  m.niveau = 'canton'
  AND  m.valid_from = DATE '1954-01-01'
  AND  m.atom_id <> 'b12';

CREATE INDEX c54_qualite_m_idx ON c54_qualite (membership_id);

-- ---------------------------------------------------------------------------
-- 7. `c67_attendu` — la transcription de `67`, à l'identique
--
-- Les treize communes des trois décrets. Deux d'entre elles — Tende et
-- La Brigue — n'ont AUCUN atome ici, comme dans la vraie base : françaises
-- depuis 1947 seulement, elles n'existent pas dans une trame qui part de 1870.
-- Le § 5 de `93` doit les afficher « aucun atome en 1940 » sans broncher.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c67_attendu;
CREATE TABLE c67_attendu (canton_id text, nom_canton text, dep char(2),
                          insee char(5), nom text, decret text);
INSERT INTO c67_attendu VALUES
  ('1930', 'Brive-Sud', '19', '19043', 'La Chapelle-aux-Brocs', 'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19063', 'Cosnac',                'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19077', 'Estivals',              'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19093', 'Jugeals-Nazareth',      'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19123', 'Malemort-sur-Corrèze',  'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19147', 'Nespouls',              'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19151', 'Noailles',              'D. 13.9.1951'),
  ('4630', 'Sousceyrac', '46', '46071', 'Comiac',           'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46141', 'Lacam-d''Ourcet',  'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46150', 'Lamativie',        'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46311', 'Sousceyrac',       'D. 5.9.1949'),
  ('0631', 'Tende', '06', '06162', 'La Brigue', 'D. 10.9.1951'),
  ('0631', 'Tende', '06', '06163', 'Tende',     'D. 10.9.1951');

-- ---------------------------------------------------------------------------
-- 8. `commune_moderne` — b13 a un trou de chronologie, les autres non
--
-- La table réelle est bâtie par `20`/`21` depuis les mouvements de l'INSEE ;
-- ici seules les colonnes lues par `93` § 9 sont fournies. b13 disparaît en
-- 1947 et revient en 1952 : c'est le signal que `chrono_trouee` doit lever, et
-- qu'il doit lever SANS rien retirer de la base.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS commune_moderne;
CREATE TABLE commune_moderne (code text, valid_from date, valid_to date,
                              atom_id text);
INSERT INTO commune_moderne
SELECT a.insee_geofla, DATE '1943-01-01', DATE '2021-01-01', a.atom_id
FROM   atom a WHERE a.atom_id NOT IN ('b13', 'b14');
INSERT INTO commune_moderne VALUES
  ('01013', DATE '1943-01-01', DATE '1947-01-01', 'b13'),
  ('01013', DATE '1952-01-01', DATE '2021-01-01', 'b13'),
  -- b14 : vivante en 1940, absente du relevé de 1954, et l'INSEE dit pourquoi
  -- — elle meurt en 1948. C'est la cible de `94` : sans elle, sa classe
  -- `MORTE_DANS_LA_FENETRE` resterait vide et le fichier ne mesurerait rien.
  ('01014', DATE '1943-01-01', DATE '1948-07-01', 'b14');
CREATE INDEX commune_moderne_atome_idx ON commune_moderne (atom_id);

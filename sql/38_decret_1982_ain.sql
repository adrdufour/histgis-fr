-- ============================================================================
-- 38_decret_1982_ain.sql — decret n° 82-77 du 25 janvier 1982, cantons de Bourg
--
--   psql -d histgis -f sql/38_decret_1982_ain.sql
--
-- Ce que fait ce fichier
-- ---------------------
-- Fait remonter au 26 janvier 1982 (publication au JO) l'appartenance
-- cantonale des trois fractions de Bourg-en-Bresse, qui ne demarrait qu'au
-- 1999-01-01 — alors que leur appartenance *circo* demarre bien au
-- 1986-11-24. La base portait donc une ville coupee en trois par des cantons
-- qui, a la meme date, n'existaient pas : au 1986-06-01, la composition
-- cantonale des trois unites etait vide.
--
-- Idempotent : ne touche que les lignes encore calees sur 1999-01-01.
--
-- L'arbitrage qu'il applique — REVISE LE 15 AOUT 2026
-- ---------------------------------------------------
-- Premiere version : les trois cantons ne contenaient QUE la commune 01053,
-- chacun une portion de son territoire. Consequence assumee alors, et c'est
-- ce qui a fait revoir la decision : Montagnat, Saint-Just et
-- Saint-Denis-les-Bourg ne relevaient d'AUCUN canton entre 1982 et 1999.
--
-- Un trou de couverture cree volontairement, contre le texte primaire, au
-- profit d'une lecture derivee. Or les deux sources disent la meme chose :
--
--   * `cantons/communes_coupees_1973_1984.csv`, colonne `texte` :
--     « Canton de Bourg-Est comprenant les communes de Montagnat et
--       Saint-Just ainsi que la portion de territoire de la ville de
--       Bourg-en-Bresse delimitee… »
--   * `circo/bourg_en_bresse_1986_delimitations.md`, transcrit depuis
--     `sources/modif_canton/JORF_19820126_21.pdf` : meme phrase.
--
-- Ce n'etait donc pas la source qui hesitait, mais la base a qui il manquait
-- les rattachements. Le decret est suivi.
--
--   0105 Bourg-Est  <- 01254 Montagnat, 01369 Saint-Just
--   0138 Bourg-Sud  <- 01344 Saint-Denis-les-Bourg
--   0137 Bourg-Nord-Centre : aucune commune entiere, le texte n'en cite pas
--
-- Regle appliquee, celle de METHODE.md : le texte fait foi. Un trou de
-- couverture est un fait qu'on constate, jamais un fait qu'on produit.
--
-- Ce que ce fichier NE fait PAS, faute de source
-- ----------------------------------------------
-- `communes_coupees_1973_1984.csv` est un registre de communes *coupees*
-- (579 lignes, 117 decrets), pas une table de composition : ses colonnes
-- structurees sont canton / commune_coupee, jamais canton / commune. Pour le
-- decret 82-77 elle ne porte que 4 lignes — les trois cantons de Bourg et
-- Oyonnax-Sud. `decrets_1973_1984.csv` est un catalogue de 137 decrets, sans
-- composition non plus.
--
-- Restent donc ouverts, et hors de portee de ces deux fichiers :
--
--   * Bourg-Couronne, quatrieme canton cree par le decret, n'a aucun unit_id
--     dans la base. Ses onze communes ne sont listees que dans le texte
--     transcrit a la main dans `circo/bourg_en_bresse_1986_delimitations.md`.
--     La base ne connait que ses deux successeurs de 1999, 0139 Peronnas et
--     0143 Viriat.
--   * le trou 1941 → 1982 subsiste. Il releve du decret n° 73-810 du
--     16 aout 1973 (Bourg-en-Bresse-I, II et III), trois cantons qui n'ont
--     pas davantage d'unit_id.
--
-- Les combler suppose de creer des unites, donc une decision de nomenclature
-- qui n'est pas dans les donnees.
-- ============================================================================

SET search_path TO histgis, public;

BEGIN;

-- Publication au JO. Le decret est signe la veille, le 25 ; le projet date les
-- effets a la publication, comme pour la loi de 1986 (circo au 1986-11-24).
CREATE TEMP TABLE d82(atom_id text, unit_id text, nom text) ON COMMIT DROP;
INSERT INTO d82 VALUES
    ('5260#0105', '0105', 'Bourg-Est'),
    ('5260#0137', '0137', 'Bourg-Nord-Centre'),
    ('5260#0138', '0138', 'Bourg-Sud');

UPDATE membership m
   SET valid_from = DATE '1982-01-26'
  FROM d82
 WHERE m.atom_id    = d82.atom_id
   AND m.unit_id    = d82.unit_id
   AND m.niveau     = 'canton'
   AND m.valid_from = DATE '1999-01-01';

-- Le nom de 1982 n'est pas celui de 1999 : le decret dit « Bourg-Est », le COG
-- « Bourg-en-Bresse-Est ». Deux versions distinctes plutot qu'une periode
-- etiree, sans quoi une carte de 1990 afficherait le libelle de 1999.
INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT d82.unit_id, d82.nom, DATE '1982-01-26', DATE '1999-01-01'
  FROM d82
 WHERE NOT EXISTS (SELECT 1 FROM unit_version uv
                    WHERE uv.unit_id = d82.unit_id
                      AND uv.periode && daterange(DATE '1982-01-26',
                                                  DATE '1999-01-01', '[)'));

-- ---------------------------------------------------------------------------
-- Les trois communes entieres que le decret rattache aux cantons de Bourg.
--
-- On resout par insee_geofla plutot que par atom_id : l'atome d'une commune
-- non fractionnee porte son identifiant Cassini, que ce fichier n'a pas a
-- connaitre. Et on n'insere QUE si la periode est libre — la contrainte
-- EXCLUDE gist ferait echouer la transaction entiere, ce qui est le
-- comportement voulu, mais autant le dire avant plutot que de le subir.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE entieres(insee char(5), unit_id text, nom text) ON COMMIT DROP;
INSERT INTO entieres VALUES
    ('01254', '0105', 'Montagnat'),
    ('01369', '0105', 'Saint-Just'),
    ('01344', '0138', 'Saint-Denis-les-Bourg');

-- Ce qui bloquerait, s'il y a lieu : une appartenance cantonale deja posee
-- sur tout ou partie de 1982-1999. Affiche, pas contourne.
SELECT e.insee, e.nom, m.unit_id AS deja_rattachee_a, m.periode
  FROM entieres e
  JOIN atom a ON a.insee_geofla = e.insee AND NOT a.fraction
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
 WHERE m.periode && daterange(DATE '1982-01-26', DATE '1999-01-01', '[)');

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT a.atom_id, e.unit_id, 'canton', DATE '1982-01-26', DATE '1999-01-01'
  FROM entieres e
  JOIN atom a ON a.insee_geofla = e.insee AND NOT a.fraction
 WHERE NOT EXISTS (
        SELECT 1 FROM membership m
         WHERE m.atom_id = a.atom_id AND m.niveau = 'canton'
           AND m.periode && daterange(DATE '1982-01-26',
                                      DATE '1999-01-01', '[)'));

COMMIT;

-- Recette : les trois cantons doivent desormais exister au 1986-06-01, date a
-- laquelle la requete rendait zero ligne.
SELECT m.unit_id,
       (SELECT nom FROM unit_version uv
         WHERE uv.unit_id = m.unit_id
           AND uv.periode @> DATE '1986-06-01')      AS nom_d_epoque,
       m.atom_id,
       a.insee_geofla,
       m.valid_from
  FROM membership m
  JOIN atom a USING (atom_id)
 WHERE m.niveau = 'canton'
   AND m.periode @> DATE '1986-06-01'
   AND a.insee_geofla IN ('01053', '01254', '01369', '01344')
 ORDER BY m.unit_id, a.insee_geofla;

-- Attendu : six lignes. Les trois fractions de Bourg-en-Bresse, plus
-- Montagnat et Saint-Just sous 0105, Saint-Denis-les-Bourg sous 0138.
-- Si les trois dernieres manquent, c'est que la periode 1982-1999 etait
-- deja prise : la requete de diagnostic ci-dessus dit par quoi.

-- ============================================================================
-- 38_decret_1982_ain.sql — decret n° 82-77 du 25 janvier 1982, cantons de Bourg
--
--   psql -d histgis -1 -f sql/38_decret_1982_ain.sql
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
-- TRACE — ajoutee le 2 septembre 2026
-- -----------------------------------
-- Ce fichier ecrit, donc il porte desormais `p38_trace` et retire son passage
-- avant de recommencer, comme tout le reste du depot. Il ne l'a pas fait
-- pendant trois semaines, et c'est ce qui a bloque la reconstruction de `24` :
-- il posait des rattachements que rien ne savait defaire.
--
-- Il pose TROIS choses distinctes, et la trace les distingue, parce qu'un
-- rejeu partiel en laisse passer une et pas les autres :
--
--   `membership_remontee`  la date de depart des trois fractions ; `avant`
--                          garde la valeur d'origine, seule facon de defaire
--                          une MISE A JOUR (un DELETE ne la defait pas)
--   `unit_version`         les trois noms de 1982
--   `membership`           les trois communes entieres rattachees
--
-- L'idempotence ne suffisait pas : elle protege du rejeu, pas de l'oubli. Un
-- fichier idempotent qu'un `rebuild.sh` a defait se tait exactement comme un
-- fichier qui vient de reussir.
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
-- LE PIEGE DU REJEU, ET CE QUI LE DECOUVRE MAINTENANT
-- ---------------------------------------------------
-- `38` n'insere que si la periode est libre. Depuis que `75`, `76` et `79`
-- ecrivent sur 1982-1999, il peut ne rien poser SANS RIEN DIRE — le code de
-- retour vaut zero dans les deux cas. La recette du § 7 compare donc ce qui
-- est trace a ce qui etait attendu, nomme l'occupant quand il y en a un, et
-- leve un WARNING. **Lire le § 7, jamais le code de retour.**
--
-- Un WARNING et non une EXCEPTION : une periode occupee par un decret mieux
-- date que celui-ci n'est pas une erreur, c'est une meilleure source. Ce qui
-- serait une erreur, c'est de ne pas le savoir.
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

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. CE QUE LE DECRET DIT
--
-- Publication au JO. Le decret est signe la veille, le 25 ; le projet date les
-- effets a la publication, comme pour la loi de 1986 (circo au 1986-11-24).
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE d82(atom_id text, unit_id text, nom text) ON COMMIT DROP;
INSERT INTO d82 VALUES
    ('5260#0105', '0105', 'Bourg-Est'),
    ('5260#0137', '0137', 'Bourg-Nord-Centre'),
    ('5260#0138', '0138', 'Bourg-Sud');

CREATE TEMP TABLE entieres(insee char(5), unit_id text, nom text) ON COMMIT DROP;
INSERT INTO entieres VALUES
    ('01254', '0105', 'Montagnat'),
    ('01369', '0105', 'Saint-Just'),
    ('01344', '0138', 'Saint-Denis-les-Bourg');

-- ---------------------------------------------------------------------------
-- 2. DEFAIRE LE PASSAGE PRECEDENT
--
-- Dans l'ordre inverse de la pose. `p38_trace` ne porte que ce que ce fichier
-- a ecrit lui-meme ; rien d'autre n'est touche, donc rien d'autre n'est a
-- defaire.
--
-- Une MISE A JOUR ne se defait pas par un DELETE : la colonne `avant` garde la
-- valeur d'origine de `valid_from`, et c'est elle qu'on restaure. Retrecir une
-- periode ne peut pas heurter la contrainte EXCLUDE — c'est l'elargir qui le
-- peut, et c'est le § 4 qui s'en garde.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p38_trace (
    quoi  text NOT NULL,          -- 'membership_remontee' | 'unit_version' | 'membership'
    cle   text NOT NULL,
    avant text,                   -- valeur d'origine, pour les mises a jour
    pose  timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p38_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

DELETE FROM unit_version v
 USING p38_trace t
 WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text;

UPDATE membership m
   SET valid_from = t.avant::date
  FROM p38_trace t
 WHERE t.quoi = 'membership_remontee'
   AND t.cle  = m.membership_id::text;

TRUNCATE p38_trace;

-- ---------------------------------------------------------------------------
-- 3. CE QUI BLOQUERAIT LA REMONTEE
--
-- La remontee ELARGIT une periode vers l'arriere. Si un autre fichier occupe
-- deja 1982-1999 pour l'un des trois atomes-fractions, la contrainte EXCLUDE
-- refuse la ligne et la transaction entiere echoue — comportement voulu, mais
-- sur un message opaque. On le dit avant plutot que de le subir.
-- ---------------------------------------------------------------------------
DO $$
DECLARE bloquant text;
BEGIN
    SELECT string_agg(format('%s occupe par %s sur %s',
                             m.atom_id, m.unit_id, m.periode), ' ; ')
      INTO bloquant
      FROM membership m
      JOIN d82 ON d82.atom_id = m.atom_id
     WHERE m.niveau = 'canton'
       AND m.valid_from <> DATE '1999-01-01'
       AND m.periode && daterange(DATE '1982-01-26', DATE '1999-01-01', '[)');
    IF bloquant IS NOT NULL THEN
        RAISE EXCEPTION
          'REMONTEE IMPOSSIBLE — la fenetre 1982-1999 est deja prise : %',
          bloquant
        USING HINT = 'Defaire le fichier qui l''occupe (sa trace), puis rejouer 38.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. LA REMONTEE DES TROIS FRACTIONS
--
-- L'objet et sa trace dans la MEME instruction, par RETURNING : c'est la regle
-- de METHODE.md, et elle vient d'un incident — 25 atomes committes sans trace,
-- donc invisibles au retrait.
-- ---------------------------------------------------------------------------
WITH maj AS (
    UPDATE membership m
       SET valid_from = DATE '1982-01-26'
      FROM d82
     WHERE m.atom_id    = d82.atom_id
       AND m.unit_id    = d82.unit_id
       AND m.niveau     = 'canton'
       AND m.valid_from = DATE '1999-01-01'
    RETURNING m.membership_id
)
INSERT INTO p38_trace (quoi, cle, avant)
SELECT 'membership_remontee', membership_id::text, '1999-01-01' FROM maj;

-- ---------------------------------------------------------------------------
-- 5. LES NOMS DE 1982
--
-- Le nom de 1982 n'est pas celui de 1999 : le decret dit « Bourg-Est », le COG
-- « Bourg-en-Bresse-Est ». Deux versions distinctes plutot qu'une periode
-- etiree, sans quoi une carte de 1990 afficherait le libelle de 1999.
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT d82.unit_id, d82.nom, DATE '1982-01-26', DATE '1999-01-01'
      FROM d82
     WHERE NOT EXISTS (SELECT 1 FROM unit_version uv
                        WHERE uv.unit_id = d82.unit_id
                          AND uv.periode && daterange(DATE '1982-01-26',
                                                      DATE '1999-01-01', '[)'))
    RETURNING unit_version_id
)
INSERT INTO p38_trace (quoi, cle)
SELECT 'unit_version', unit_version_id::text FROM ins;

-- ---------------------------------------------------------------------------
-- 6. LES TROIS COMMUNES ENTIERES QUE LE DECRET RATTACHE
--
-- On resout par insee_geofla plutot que par atom_id : l'atome d'une commune
-- non fractionnee porte son identifiant Cassini, que ce fichier n'a pas a
-- connaitre. Et on n'insere QUE si la periode est libre — c'est ici que se
-- joue le silence du rejeu, que le § 7 rompt.
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT a.atom_id, e.unit_id, 'canton', DATE '1982-01-26', DATE '1999-01-01'
      FROM entieres e
      JOIN atom a ON a.insee_geofla = e.insee AND NOT a.fraction
     WHERE NOT EXISTS (
            SELECT 1 FROM membership m
             WHERE m.atom_id = a.atom_id AND m.niveau = 'canton'
               AND m.periode && daterange(DATE '1982-01-26',
                                          DATE '1999-01-01', '[)'))
    RETURNING membership_id
)
INSERT INTO p38_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

COMMIT;

-- ===========================================================================
-- 7. RECETTE — CE QUI EST TRACE, ET CE QUI MANQUE A L'APPEL
--
-- Trois lignes attendues par categorie. Toute autre valeur est une question,
-- et le § 7 b dit par quoi la place etait prise.
-- ===========================================================================
\echo ''
\echo '-- 7 a. ce que 38 a pose, par categorie (attendu : 3, 3, 3)'

WITH attendu(quoi, n, role) AS (
    VALUES ('membership_remontee', 3, 'les trois fractions remontees a 1982-01-26'),
           ('unit_version',        3, 'les trois noms de 1982'),
           ('membership',          3, 'Montagnat, Saint-Just, Saint-Denis-les-Bourg'))
SELECT a.quoi,
       a.n                                   AS attendu,
       count(t.cle)                          AS trace,
       CASE WHEN count(t.cle) = a.n THEN 'conforme'
            WHEN count(t.cle) = 0   THEN 'RIEN POSE — voir 7 b'
            ELSE                         'POSE PARTIEL — voir 7 b'
       END                                   AS verdict,
       a.role
  FROM attendu a
  LEFT JOIN p38_trace t ON t.quoi = a.quoi
 GROUP BY a.quoi, a.n, a.role
 ORDER BY a.quoi;

\echo ''
\echo '-- 7 b. les communes entieres que 38 n''a PAS pu poser, et l''occupant'
\echo '--      (zero ligne = rien ne manque)'

WITH entieres(insee, unit_id, nom) AS (
    VALUES ('01254','0105','Montagnat'),
           ('01369','0105','Saint-Just'),
           ('01344','0138','Saint-Denis-les-Bourg'))
SELECT e.insee, e.nom, e.unit_id AS attendu,
       m.unit_id                 AS occupe_par,
       m.periode                 AS sur,
       CASE WHEN m.membership_id IS NULL
            THEN 'ABSENTE ET NON OCCUPEE — 38 aurait du poser, a regarder'
            ELSE 'OCCUPEE — 38 s''est taise, la place n''etait pas libre'
       END                       AS verdict
  FROM entieres e
  JOIN atom a ON a.insee_geofla = e.insee AND NOT a.fraction
  LEFT JOIN membership m
         ON m.atom_id = a.atom_id AND m.niveau = 'canton'
        AND m.periode && daterange(DATE '1982-01-26', DATE '1999-01-01', '[)')
 WHERE NOT EXISTS (SELECT 1 FROM p38_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle  = m.membership_id::text);

-- Le WARNING : un code de retour nul ne distingue pas « pose » de « s'est tu ».
DO $$
DECLARE n_pose int; n_att CONSTANT int := 3;
BEGIN
    SELECT count(*) INTO n_pose FROM p38_trace WHERE quoi = 'membership';
    IF n_pose < n_att THEN
        RAISE WARNING
          '38 : % rattachement(s) sur % pose(s) — la fenetre 1982-1999 etait deja prise. Lire le § 7 b.',
          n_pose, n_att;
    END IF;
END $$;

\echo ''
\echo '-- 7 c. l''etat vu par la carte : les trois cantons au 1er juin 1986,'
\echo '--      date a laquelle la requete rendait zero ligne avant 38'

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
--
-- Pour tout defaire sans rejouer : vider p38_trace ne suffit PAS, il faut
-- rejouer le § 2, qui restaure les dates avant de supprimer les lignes.

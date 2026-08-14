-- ============================================================================
-- histgis — 37_reparer_encodage.sql : réparer les noms décodés en Latin-1
--                                     alors qu'ils étaient en Windows-1252
--
--   psql -d histgis -f 37_reparer_encodage.sql          -- diagnostic seul
--   psql -d histgis -1 -v appliquer=1 -f 37_reparer_encodage.sql
--
-- Le diagnostic
-- -------------
-- `36_recette_annexe_vi.sql` § 6 a sorti des noms contenant U+009C :
-- « Vanduvre-lès-Nancy », « Nux-les-Mines », « Marcq-en-Barul ».
--
-- U+009C est un caractère de contrôle C1, qui n'a rien à faire dans un nom de
-- lieu. C'est la signature exacte d'un octet 0x9C de **Windows-1252** — où il
-- code `œ` — décodé comme du **Latin-1**, où cette position est un caractère
-- de contrôle. Les deux jeux ne diffèrent que sur la plage 0x80-0x9F, et c'est
-- précisément là que vivent œ, Œ, les apostrophes typographiques et les tirets
-- cadratins.
--
-- Les fichiers du COG sont en Windows-1252 ; le chargement les a lus en
-- Latin-1. Le défaut est donc systématique, pas accidentel : il touche tout
-- nom contenant un de ces caractères, et lui seul.
--
-- Comment on le sait
-- ------------------
-- `unit.nom` porte « Morteaux-Couliboeuf » — la graphie `oe` de TRF-GIS, saine
-- — quand `unit_version.nom` porte la version cassée. Deux voies de
-- chargement, une seule fautive. Le COG est en cause, pas TRF-GIS.
--
-- La réparation
-- -------------
-- Bijective et sans perte : chaque caractère de contrôle C1 rencontré est
-- remplacé par le caractère que Windows-1252 place à cette position. Aucune
-- ambiguïté, aucun choix — un caractère de contrôle dans un toponyme n'a
-- jamais d'autre origine.
--
-- Sans `-v appliquer=1`, le script ne fait que mesurer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' ENCODAGE — Windows-1252 lu comme Latin-1'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- La table de correspondance, telle que Windows-1252 la définit
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cp1252_fix;
CREATE TEMP TABLE cp1252_fix (casse text, correct text, nom_du_caractere text);
INSERT INTO cp1252_fix VALUES
    (chr(128), '€', 'signe euro'),
    (chr(130), '‚', 'guillemet-virgule inferieur'),
    (chr(131), 'ƒ', 'f hameçon'),
    (chr(132), '„', 'guillemet-virgule double inferieur'),
    (chr(133), '…', 'points de suspension'),
    (chr(134), '†', 'obele'),
    (chr(136), 'ˆ', 'accent circonflexe'),
    (chr(138), 'Š', 'S caron'),
    (chr(139), '‹', 'guillemet simple gauche'),
    (chr(140), 'Œ', 'OE majuscule'),
    (chr(142), 'Ž', 'Z caron'),
    (chr(145), '‘', 'apostrophe gauche'),
    (chr(146), '’', 'apostrophe droite'),
    (chr(147), '“', 'guillemet gauche'),
    (chr(148), '”', 'guillemet droit'),
    (chr(150), '–', 'tiret demi-cadratin'),
    (chr(151), '—', 'tiret cadratin'),
    (chr(154), 'š', 's caron'),
    (chr(155), '›', 'guillemet simple droit'),
    (chr(156), 'œ', 'oe minuscule'),
    (chr(158), 'ž', 'z caron'),
    (chr(159), 'Ÿ', 'Y trema');

-- ---------------------------------------------------------------------------
-- 1. L'ampleur, table par table
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Ampleur ==='

DROP TABLE IF EXISTS enc_diag;
CREATE TEMP TABLE enc_diag AS
SELECT 'unit.nom'          AS colonne, unit_id AS cle, nom AS valeur FROM unit
WHERE  nom ~ '[-]'
UNION ALL
SELECT 'unit_version.nom', unit_id, nom FROM unit_version
WHERE  nom ~ '[-]';

SELECT colonne, count(*) AS valeurs_atteintes FROM enc_diag
GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 2. Quels caracteres, et combien de fois ==='
SELECT f.nom_du_caractere, f.correct AS devrait_etre,
       count(*) AS occurrences
FROM   enc_diag d JOIN cp1252_fix f ON d.valeur LIKE '%' || f.casse || '%'
GROUP  BY 1, 2 ORDER BY 3 DESC;

\echo ''
\echo '=== 3. Le detail ==='
SELECT colonne, cle, valeur AS avant,
       (SELECT string_agg(x.c, '' ORDER BY x.i)
        FROM (SELECT i, coalesce((SELECT f.correct FROM cp1252_fix f
                                  WHERE f.casse = substr(d.valeur, i, 1)),
                                 substr(d.valeur, i, 1)) AS c
              FROM generate_series(1, length(d.valeur)) AS i) x) AS apres
FROM   enc_diag d ORDER BY colonne, cle;

-- ---------------------------------------------------------------------------
-- 4. Appliquer
-- ---------------------------------------------------------------------------
\if :{?appliquer}
\echo ''
\echo '=== 4. Application ==='

DROP TABLE IF EXISTS encodage_trace;
CREATE TABLE encodage_trace AS SELECT colonne, cle, valeur AS avant,
       now() AS repare_le FROM enc_diag;

DO $$
DECLARE f record;
BEGIN
  FOR f IN SELECT casse, correct FROM cp1252_fix LOOP
    UPDATE unit         SET nom = replace(nom, f.casse, f.correct)
     WHERE nom LIKE '%' || f.casse || '%';
    UPDATE unit_version SET nom = replace(nom, f.casse, f.correct)
     WHERE nom LIKE '%' || f.casse || '%';
  END LOOP;
END $$;

SELECT count(*) AS restants_apres_reparation
FROM  (SELECT nom FROM unit UNION ALL SELECT nom FROM unit_version) t
WHERE  nom ~ '[-]';

\echo '    0 restant = repare. Table encodage_trace pour le rollback.'
\else
\echo ''
\echo '=== 4. Rien applique ==='
\echo '    Relancer avec : psql -d histgis -1 -v appliquer=1 -f 37_reparer_encodage.sql'
\endif

\echo ''
\echo '=== A verifier ensuite ==='
\echo '    Le meme defaut touche probablement les tables de chargement du COG'
\echo '    (cog_commune_src, cog_canton_src) et tout ce qui en derive. Le'
\echo '    corriger dans unit/unit_version ne suffira pas si un rebuild'
\echo '    recharge les fichiers de la meme facon : la vraie correction est'
\echo '    dans load_cog.sh, ou il faut declarer ENCODING ''WIN1252'' au \copy.'
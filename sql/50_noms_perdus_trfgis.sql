-- ============================================================================
-- 50_noms_perdus_trfgis.sql — quatre noms détruits DANS la source TRF-GIS
--
--   psql -d histgis -f sql/50_noms_perdus_trfgis.sql        -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/50_noms_perdus_trfgis.sql
--
-- Le constat
-- ----------
-- La carte affiche « Orl<?><?>ans-Est » dans le Loiret. En remontant :
--
--   carte  <- export  <- base  <- build/unit_canton.csv  <- TRF-GIS
--
-- ...la corruption est présente **à chaque étage, y compris le premier**. Les
-- fichiers `sources/trfgis/cantons/Nomenclatures/COG_CANTONS_*_MAPPING.tab`
-- portent déjà les octets `EF BF BD EF BF BD` — deux caractères de
-- remplacement U+FFFD — là où il n'y avait qu'un « é ».
--
-- **Notre chaîne n'y est pour rien.** Deux U+FFFD pour une seule lettre est la
-- signature d'un fichier UTF-8 relu avec un encodage qui ne le comprend pas :
-- les deux octets de « é » (C3 A9) sont devenus deux points d'interrogation,
-- chacun irrécupérable. L'accident a eu lieu avant que la donnée nous parvienne.
--
-- Pourquoi ce n'est pas l'affaire de `37_reparer_encodage.sql`
-- ------------------------------------------------------------
-- `37` répare du Windows-1252 lu en Latin-1 : la table y est **bijective**, et
-- son en-tête le revendique — « aucune ambiguïté, aucun choix ». Ici la lettre
-- est perdue, pas déplacée. Aucune règle ne la reconstitue ; il faut la nommer.
-- Mêler les deux ôterait à `37` ce qui fait sa force.
--
-- Ce qui rend la correction sûre malgré tout
-- ------------------------------------------
-- Elle n'est pas devinée : elle est **contrainte par ce qui reste**. « Orl__ans »
-- et « Saint-__tienne » n'admettent qu'une lecture en toponymie française, et
-- le canton, le département et le millésime concordent. Ce n'est pas le même
-- régime de preuve qu'une attribution de canton — c'est de l'orthographe.
--
-- Les quatre, et rien de plus. Aucun autre nom de `build/` ne porte U+FFFD :
--
--   4221  42  Saint-Étienne-Nord-Ouest
--   4222  42  Saint-Étienne-Sud-Ouest
--   4521  45  Orléans-Est
--   4522  45  Orléans-Ouest
--
-- Sans `-v appliquer=1`, ce fichier ne fait que mesurer.
-- Réversible : `noms_perdus_trace`, section 4.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' NOMS DETRUITS DANS LA SOURCE TRF-GIS (U+FFFD)'
\echo '============================================================'

DROP TABLE IF EXISTS trfgis_nom_perdu;
CREATE TEMP TABLE trfgis_nom_perdu (unit_id text PRIMARY KEY, correct text);
INSERT INTO trfgis_nom_perdu VALUES
    ('4221', 'Saint-Étienne-Nord-Ouest'),
    ('4222', 'Saint-Étienne-Sud-Ouest'),
    ('4521', 'Orléans-Est'),
    ('4522', 'Orléans-Ouest');

\echo ''
\echo '=== 1. Etat actuel de ces quatre unites ==='
SELECT u.unit_id, u.dep, u.nom AS nom_unit,
       (SELECT count(*) FROM unit_version v
         WHERE v.unit_id = u.unit_id AND v.nom LIKE '%' || U&'\FFFD' || '%')
           AS versions_cassees,
       f.correct AS nom_attendu
  FROM trfgis_nom_perdu f
  LEFT JOIN unit u ON u.unit_id = f.unit_id AND u.niveau = 'canton'
 ORDER BY u.unit_id;

\echo ''
\echo '=== 2. Y a-t-il D''AUTRES noms porteurs de U+FFFD ? ==='
-- Si cette requete rend des lignes hors des quatre ci-dessus, la liste est
-- incomplete et il faut la completer AVANT d'appliquer — ne jamais reparer
-- une partie d'un defaut en laissant croire qu'il est traite.
-- `unit_version` ne porte PAS de colonne `niveau` : elle la tient de `unit`
-- par sa clé étrangère. La jointure se fait donc sur `unit_id` seul.
SELECT 'unit' AS table_, u.unit_id AS cle, u.niveau, u.nom
  FROM unit u WHERE u.nom LIKE '%' || U&'\FFFD' || '%'
UNION ALL
SELECT 'unit_version', v.unit_id, u.niveau, v.nom
  FROM unit_version v
  JOIN unit u ON u.unit_id = v.unit_id
 WHERE v.nom LIKE '%' || U&'\FFFD' || '%'
 ORDER BY 2, 1;

\if :{?appliquer}

DROP TABLE IF EXISTS noms_perdus_trace;
CREATE TABLE noms_perdus_trace AS
SELECT 'unit' AS table_, u.unit_id, u.niveau, u.nom AS avant, f.correct AS apres,
       now() AS pose_le
  FROM unit u JOIN trfgis_nom_perdu f ON f.unit_id = u.unit_id
 WHERE u.niveau = 'canton' AND u.nom <> f.correct
UNION ALL
SELECT 'unit_version', v.unit_id, u.niveau, v.nom, f.correct, now()
  FROM unit_version v
  JOIN unit u ON u.unit_id = v.unit_id AND u.niveau = 'canton'
  JOIN trfgis_nom_perdu f ON f.unit_id = v.unit_id
 WHERE v.nom <> f.correct;

UPDATE unit u SET nom = f.correct
  FROM trfgis_nom_perdu f
 WHERE u.unit_id = f.unit_id AND u.niveau = 'canton';

UPDATE unit_version v SET nom = f.correct
  FROM trfgis_nom_perdu f, unit u
 WHERE v.unit_id = f.unit_id
   AND u.unit_id = v.unit_id AND u.niveau = 'canton';

\echo ''
\echo '=== 3. Apres reparation ==='
SELECT u.unit_id, u.dep, u.nom FROM unit u
  JOIN trfgis_nom_perdu f ON f.unit_id = u.unit_id
 WHERE u.niveau = 'canton' ORDER BY u.unit_id;

SELECT count(*) AS lignes_modifiees FROM noms_perdus_trace;

\echo ''
\echo '=== 4. Pour tout defaire ==='
\echo '    UPDATE unit u SET nom = t.avant FROM noms_perdus_trace t'
\echo '     WHERE t.table_ = ''unit'' AND t.unit_id = u.unit_id'
\echo '       AND t.niveau = u.niveau;'
\echo '    (idem unit_version)'

\else
\echo ''
\echo '=== Tourne a blanc ==='
\echo '    Relancer avec :'
\echo '    psql -d histgis -1 -v appliquer=1 -f sql/50_noms_perdus_trfgis.sql'
\endif

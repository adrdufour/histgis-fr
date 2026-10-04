-- ============================================================================
-- 19_noms_geofla.sql — la table des noms de communes, dans la chaîne
--
--   psql -d histgis -f sql/19_noms_geofla.sql
--
-- Pourquoi ce fichier existe
-- --------------------------
-- `noms_geofla` était créée par **`cartes/couverture_cantons_2025.py`**, un
-- script de cartographie extérieur à la chaîne SQL. Six fichiers en dépendent :
-- `39`, `41`, `42`, `43`, `44` et les recettes de `15`.
--
-- Conséquence, constatée le 20 août 2026 : une reconstruction complète échouait
-- systématiquement sur
--
--   ERROR: relation "noms_geofla" does not exist
--
-- et il fallait avoir lancé un script de cartes pour qu'une reconstruction de
-- base aboutisse. **Une dépendance de la chaîne ne peut pas vivre hors de la
-- chaîne.**
--
-- Ce que la table contient
-- ------------------------
-- Une projection de `geofla_commune` : code INSEE, nom, département. Rien de
-- plus. Le commentaire d'origine dit pourquoi elle existe plutôt que d'aller
-- chercher les noms dans `insee_mvt` : *« insee_mvt ne nomme que les communes
-- qui ont bougé : la moitié des villes sortaient sans nom. GEOFLA les nomme
-- toutes. »*
--
-- Sa limite, et elle explique les « ? » des recettes
-- --------------------------------------------------
-- GEOFLA est un millésime **2011**. Une commune rétablie après cette date —
-- 52033, 55138, 76601, les cinq de Haute-Marne — n'y figure pas et reste donc
-- sans nom. Ce n'est pas un défaut de cette table : c'est la date de la trame.
-- Les recettes affichent `?` et c'est honnête.
--
-- Idempotent : la table est reconstruite à chaque passage.
-- Prérequis : `geofla_commune`, chargée par l'étape GEOFLA de `rebuild.sh`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.geofla_commune') IS NULL THEN
        RAISE EXCEPTION 'geofla_commune absente : charger GEOFLA avant '
                        '(étape 2 de rebuild.sh).';
    END IF;
END $$;

DROP TABLE IF EXISTS noms_geofla;
CREATE TABLE noms_geofla (
    insee char(5) PRIMARY KEY,
    nom   text NOT NULL,
    dep   char(3)
);

INSERT INTO noms_geofla (insee, nom, dep)
SELECT g.insee_com, g.nom_comm, g.code_dept
  FROM geofla_commune g
 WHERE g.insee_com IS NOT NULL
ON CONFLICT (insee) DO NOTHING;

ANALYZE noms_geofla;

\echo ''
\echo '=== noms_geofla ==='
SELECT count(*) AS communes, count(DISTINCT dep) AS departements
  FROM noms_geofla;
-- Mesuré le 20 août 2026 : 36 610 communes, 96 départements.

\echo ''
\echo '--- contrôle : les communes que les correctifs vont nommer ---'
SELECT n.insee, n.nom
  FROM noms_geofla n
 WHERE n.insee IN ('14482', '72080', '2B366', '95120', '13075', '64439')
 ORDER BY n.insee;
-- Ouézy, Cherré, Chisa, Butry-sur-Oise, Plan-de-Cuques, Ousse. Six lignes
-- attendues : ce sont les communes que `41`, `42`, `44` et `46` affichent
-- dans leurs recettes.

-- ============================================================================
-- histgis — 22_cog_stage.sql : les tables d'accueil du COG 1999-2012
--
-- Deux tables brutes, une ligne par enregistrement et par millésime. On ne
-- transforme rien ici : c'est le dépôt, et il doit rester relisible à côté des
-- fichiers d'origine.
--
-- Ce que portent les fichiers, et pourquoi les deux sont nécessaires
-- -----------------------------------------------------------------
--   france{A}  toutes les communes ayant existé depuis 1943. ACTUAL = 1 pour
--              une commune vivante, 6 pour chacune de ses FRACTIONS cantonales
--              quand elle est multicantonale, 2 à 5 pour les disparues — qui
--              n'ont pas de canton (champ CT vide, vérifié).
--              CDC = 0 monocantonale, 1 fraction, 2 « canton non précisé ».
--   canton{A}  la nomenclature : nom, chef-lieu, et TYPCT, composition
--              communale du canton.
--
-- `comsimp{A}` ne suffirait pas : une commune multicantonale n'y figure qu'une
-- fois, sous le code « canton non précisé » (97, 98, 99). Les 1 138 fractions
-- de 1999 y sont invisibles.
--
-- Structure vérifiée identique sur les 14 millésimes. L'Insee a changé le
-- format en 2019 ; la borne haute du projet étant 2012, la question ne se pose
-- pas.
--
-- Chargement : ./load_cog.sh — les fichiers sont en latin-1, séparés par des
-- tabulations, terminés en CRLF.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DROP TABLE IF EXISTS cog_commune_src;
CREATE TABLE cog_commune_src (
    annee    smallint,          -- posé après le \copy, qui ne sait pas ajouter de constante
    actual   text, cheflieu text, cdc text, rang text,
    reg      text, dep text, com text, ar text, ct text,
    modif    text, pole text, tncc text,
    artmaj   text, ncc text, artmin text, nccenr text,
    articlct text, nccct text
);

DROP TABLE IF EXISTS cog_canton_src;
CREATE TABLE cog_canton_src (
    annee    smallint,
    region   text, dep text, ar text, canton text, typct text,
    cheflieu text, tncc text,
    artmaj   text, ncc text, artmin text, nccenr text
);

\echo 'Tables d''accueil créées : cog_commune_src, cog_canton_src.'

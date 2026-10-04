-- ============================================================================
-- histgis : schéma espace-temps cantons / circonscriptions (1870-1940, TRF-GIS)
-- 01_schema.sql — structures, contraintes, index
--
-- Prérequis : PostgreSQL >= 13, extensions postgis et btree_gist.
-- Idempotent : DROP SCHEMA ... CASCADE en tête. Ne pas lancer sur une base
-- déjà peuplée sans l'avoir voulu.
-- ============================================================================

\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS btree_gist;   -- indispensable aux EXCLUDE mixtes

DROP SCHEMA IF EXISTS histgis CASCADE;
CREATE SCHEMA histgis;
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- atom : plus petite unité géographique dont le rattachement est stable.
--   - une commune entière  -> atom_id = code Cassini
--   - une fraction de commune (pseudo-canton recouvrant plusieurs cantons
--     réels) -> atom_id = 'cassini#canton', fraction = true
-- La géométrie n'est PAS ici : elle vivra dans atom_geom (passe ultérieure),
-- rattachée à la trame communale GEOFLA 2011 via insee_geofla.
-- ---------------------------------------------------------------------------
CREATE TABLE atom (
    atom_id      text     PRIMARY KEY,
    cassini      text     NOT NULL,
    fraction     boolean  NOT NULL DEFAULT false,
    -- statut TRF-GIS de la commune (colonne com_act de COG_COMMUNES_YYYY) :
    -- 1 = commune actuelle, 2 = ancienne (post-1943), 3 = ancienne (pré-1943)
    com_act      smallint CHECK (com_act BETWEEN 1 AND 3),
    -- rattachement à la trame GEOFLA 2011 ; NULL tant que la passe
    -- géométrique n'a pas été faite (cf. README, section « limite connue »)
    insee_geofla char(5)
);
CREATE INDEX atom_cassini_idx ON atom (cassini);

-- ---------------------------------------------------------------------------
-- unit : canton ou circonscription, identité pérenne (le nom vit dans
-- unit_version). unit_id est unique tous niveaux confondus :
--   canton -> 'DDNN' (dep + pseudo-canton) ; circo -> 'L…@AAAA' / 'U…@AAAA'
-- ---------------------------------------------------------------------------
CREATE TABLE unit (
    unit_id        text PRIMARY KEY,
    niveau         text NOT NULL CHECK (niveau IN ('canton', 'circo')),
    dep            char(2) NOT NULL,
    code           text,      -- circo : code brut département+circo
    regime         text CHECK (regime IN ('liste', 'uninominal')),
    segment_depuis smallint,  -- circo : année d'ouverture du segment de découpage
    nom            text,      -- dernier nom connu (dénormalisé, confort)
    provisoire     boolean NOT NULL DEFAULT false,  -- unité déduite du membership
    -- cohérence par niveau
    CONSTRAINT unit_circo_attrs CHECK (
        niveau <> 'circo' OR (regime IS NOT NULL AND segment_depuis IS NOT NULL)
    ),
    CONSTRAINT unit_canton_attrs CHECK (
        niveau <> 'canton' OR (regime IS NULL AND segment_depuis IS NULL)
    ),
    UNIQUE (unit_id, niveau)   -- support de la FK composite de membership
);
CREATE INDEX unit_niveau_dep_idx ON unit (niveau, dep);

-- ---------------------------------------------------------------------------
-- unit_version : nom d'une unité sur un intervalle. Reconstruit à partir des
-- renommages détectés année par année. Bornes [valid_from, valid_to).
-- ---------------------------------------------------------------------------
CREATE TABLE unit_version (
    unit_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    unit_id    text NOT NULL REFERENCES unit(unit_id) ON DELETE CASCADE,
    nom        text,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS
                   (daterange(valid_from, valid_to, '[)')) STORED,
    CONSTRAINT unit_version_bornes CHECK (valid_from < valid_to),
    -- deux versions d'une même unité ne peuvent se chevaucher
    CONSTRAINT unit_version_non_chevauchant
        EXCLUDE USING gist (unit_id WITH =, periode WITH &&)
);
CREATE INDEX unit_version_periode_idx ON unit_version USING gist (periode);

-- ---------------------------------------------------------------------------
-- membership : rattachement d'un atome à une unité sur un intervalle.
-- C'est le cœur du modèle : la géométrie d'un canton à une date donnée est
-- l'union des atomes qui lui sont rattachés à cette date.
-- Bornes [valid_from, valid_to), valid_to exclusif (1941-01-01 = fin de série).
-- ---------------------------------------------------------------------------
CREATE TABLE membership (
    membership_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atom_id    text NOT NULL REFERENCES atom(atom_id) ON DELETE CASCADE,
    unit_id    text NOT NULL,
    niveau     text NOT NULL CHECK (niveau IN ('canton', 'circo')),
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS
                   (daterange(valid_from, valid_to, '[)')) STORED,
    CONSTRAINT membership_bornes CHECK (valid_from < valid_to),
    CONSTRAINT membership_unit_fk
        FOREIGN KEY (unit_id, niveau) REFERENCES unit(unit_id, niveau),
    -- un atome n'appartient qu'à UNE unité par niveau à un instant donné
    CONSTRAINT membership_non_chevauchant
        EXCLUDE USING gist (atom_id WITH =, niveau WITH =, periode WITH &&)
);
CREATE INDEX membership_unit_idx    ON membership (unit_id, valid_from);
CREATE INDEX membership_periode_idx ON membership USING gist (periode);
CREATE INDEX membership_niveau_idx  ON membership (niveau);

-- ---------------------------------------------------------------------------
-- regime_electoral : régime de scrutin déduit année par année (ratio
-- circonscriptions / départements). Sert à interpréter les unités 'circo'.
-- ---------------------------------------------------------------------------
CREATE TABLE regime_electoral (
    annee    smallint PRIMARY KEY,
    n_dep    smallint NOT NULL,
    n_circo  smallint NOT NULL,
    ratio    numeric(6,3) NOT NULL,
    regime   text NOT NULL CHECK (regime IN ('liste', 'uninominal'))
);

-- ---------------------------------------------------------------------------
-- Tables de diagnostic : elles ne portent pas le modèle, elles tracent les
-- cas douteux rencontrés à l'extraction. À consulter, pas à joindre.
-- ---------------------------------------------------------------------------
CREATE TABLE diag_attribution_ambigue (
    niveau  text NOT NULL,
    insee   text NOT NULL,
    annee   smallint NOT NULL,
    unit_id text NOT NULL,
    libelle text
);

CREATE TABLE diag_commune_fractionnee (
    insee    text NOT NULL,
    annee    smallint NOT NULL,
    pct_type smallint NOT NULL,   -- 2 à 5 : la commune est éclatée
    deppct   text,
    pct_name text
);
CREATE INDEX diag_commune_fractionnee_idx ON diag_commune_fractionnee (insee, annee);

CREATE TABLE diag_pseudo_multi_commune (
    annee    smallint NOT NULL,
    deppct   text NOT NULL,
    communes text NOT NULL        -- codes séparés par ';'
);

CREATE TABLE diag_geom_correspondance (
    insee       text NOT NULL,
    methode     text,
    cible       text,
    nom_cible   text,
    commentaire text
);

COMMENT ON SCHEMA histgis IS
    'Base espace-temps des cantons et circonscriptions françaises. '
    'Source 1870-1940 : TRF-GIS (Victor Gay, Harvard Dataverse). '
    'Géométrie et attribution administrative sont découplées : la géométrie '
    'vit au niveau de l''atome, l''attribution dans membership.';

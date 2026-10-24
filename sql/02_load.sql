-- ============================================================================
-- histgis — 02_load.sql : chargement des CSV produits par extraction/trfgis_extract.py
--
-- Usage :
--   psql -v racine=/chemin/projet_carte -f 02_load.sql
-- (le wrapper load.sh s'en charge). Les CSV attendus sont sous <racine>/build/,
-- sauf geom_correspondance.csv qui est à la racine.
--
-- Les tables stg_* sont temporaires à la session : rien à nettoyer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set build :racine '/build'

-- ---------------------------------------------------------------------------
-- 1. Tables de transit
-- ---------------------------------------------------------------------------
-- La 3e colonne des CSV atom/membership dépend du --geom-col passé à
-- extraction/trfgis_extract.py : code INSEE à 5 caractères avec --geom-col insee,
-- statut 1/2/3 avec --geom-col com_act. On la lit en texte et on la range
-- dans la bonne colonne au moment de l'insertion.
CREATE TEMP TABLE stg_atom (
    atom_id text, cassini text, col3 text, fraction boolean
);
CREATE TEMP TABLE stg_unit_canton (
    unit_id text, dep text, nom text
);
CREATE TEMP TABLE stg_unit_circo (
    unit_id text, regime text, dep text, code text,
    segment_depuis smallint, nom text
);
CREATE TEMP TABLE stg_membership (
    atom_id text, cassini text, col3 text, unit_id text,
    valid_from date, valid_to date, niveau text
);
CREATE TEMP TABLE stg_renames (
    niveau text, unit_id text, annee smallint, nom_avant text, nom_apres text
);
CREATE TEMP TABLE stg_regime (
    annee smallint, n_dep smallint, n_circo smallint, ratio numeric, regime text
);

-- ---------------------------------------------------------------------------
-- 2. COPY. Attention : la 3e colonne des CSV atom/membership est intitulée
--    « insee » : son contenu dépend du --geom-col du build (cf. README).
--    \copy n'interpole pas les variables : on fabrique la méta-commande dans
--    :cmd puis on l'exécute. C'est laid, c'est le seul moyen portable.
-- ---------------------------------------------------------------------------
\set f :build '/atom.csv'
\set cmd '\\copy stg_atom (atom_id, cassini, col3, fraction) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/unit_canton.csv'
\set cmd '\\copy stg_unit_canton (unit_id, dep, nom) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/unit_circo.csv'
\set cmd '\\copy stg_unit_circo (unit_id, regime, dep, code, segment_depuis, nom) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/membership_canton.csv'
\set cmd '\\copy stg_membership (atom_id, cassini, col3, unit_id, valid_from, valid_to) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd
UPDATE stg_membership SET niveau = 'canton' WHERE niveau IS NULL;

\set f :build '/membership_circo.csv'
\set cmd '\\copy stg_membership (atom_id, cassini, col3, unit_id, valid_from, valid_to) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd
UPDATE stg_membership SET niveau = 'circo' WHERE niveau IS NULL;

\set f :build '/unit_renames.csv'
\set cmd '\\copy stg_renames (niveau, unit_id, annee, nom_avant, nom_apres) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/circo_regime.csv'
\set cmd '\\copy stg_regime (annee, n_dep, n_circo, ratio, regime) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/attribution_ambigue.csv'
\set cmd '\\copy diag_attribution_ambigue (niveau, insee, annee, unit_id, libelle) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/communes_fractionnees.csv'
\set cmd '\\copy diag_commune_fractionnee (insee, annee, pct_type, deppct, pct_name) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :build '/pseudo_multi_communes.csv'
\set cmd '\\copy diag_pseudo_multi_commune (annee, deppct, communes) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

\set f :racine '/geom_correspondance.csv'
\set cmd '\\copy diag_geom_correspondance (insee, methode, cible, nom_cible, commentaire) FROM ' :'f' ' WITH (FORMAT csv, HEADER true)'
:cmd

-- ---------------------------------------------------------------------------
-- 3. atom
-- ---------------------------------------------------------------------------
INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
SELECT atom_id,
       cassini,
       coalesce(fraction, false),
       CASE WHEN col3 ~ '^[123]$'                THEN col3::smallint END,
       -- codes communes, Corse comprise (2A/2B, postérieurs à 1976 mais
       -- présents dans la trame GEOFLA 2011 qui sert de référence)
       CASE WHEN col3 ~ '^(2[AB]|[0-9]{2})[0-9]{3}$' THEN col3 END
FROM   stg_atom;

-- ---------------------------------------------------------------------------
-- 4. unit — cantons puis circonscriptions
-- ---------------------------------------------------------------------------
INSERT INTO unit (unit_id, niveau, dep, nom)
SELECT unit_id, 'canton', dep, nullif(nom, '')
FROM   stg_unit_canton;

INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
SELECT unit_id, 'circo', dep, code, regime, segment_depuis, nullif(nom, '')
FROM   stg_unit_circo;

-- Unités citées par le membership mais absentes des nomenclatures (pseudo-
-- circonscriptions de Paris et Marseille, essentiellement). On les crée
-- marquées provisoire = true plutôt que de perdre les rattachements.
INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
SELECT DISTINCT
       m.unit_id,
       'circo',
       substring(m.unit_id from 2 for 2),
       split_part(substring(m.unit_id from 2), '@', 1),
       CASE left(m.unit_id, 1) WHEN 'L' THEN 'liste' ELSE 'uninominal' END,
       split_part(m.unit_id, '@', 2)::smallint,
       NULL,
       true
FROM   stg_membership m
WHERE  m.niveau = 'circo'
  AND  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = m.unit_id);

-- Même filet pour les cantons (attendu : 0 ligne).
INSERT INTO unit (unit_id, niveau, dep, nom, provisoire)
SELECT DISTINCT m.unit_id, 'canton', left(m.unit_id, 2), NULL, true
FROM   stg_membership m
WHERE  m.niveau = 'canton'
  AND  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = m.unit_id);

-- ---------------------------------------------------------------------------
-- 5. membership
-- ---------------------------------------------------------------------------
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, niveau, valid_from, valid_to
FROM   stg_membership
WHERE  valid_from < valid_to;

-- ---------------------------------------------------------------------------
-- 6. unit_version — reconstruction des noms dans le temps
--    unit.nom porte le DERNIER nom connu ; unit_renames donne les bascules.
--    Chaque unité démarre à sa première apparition dans membership et
--    s'achève à sa dernière.
-- ---------------------------------------------------------------------------
WITH bornes AS (
    SELECT unit_id, min(valid_from) AS d0, max(valid_to) AS d1
    FROM   membership
    GROUP  BY unit_id
),
-- nom initial : le nom_avant du premier renommage, sinon le nom courant
premier_nom AS (
    SELECT DISTINCT ON (unit_id) unit_id, nom_avant
    FROM   stg_renames
    ORDER  BY unit_id, annee
),
points AS (
    -- amorce : nom porté à la première apparition de l'unité
    SELECT b.unit_id, b.d0 AS valid_from,
           coalesce(p.nom_avant, u.nom) AS nom, 0 AS prio
    FROM   bornes b
    JOIN   unit u USING (unit_id)
    LEFT   JOIN premier_nom p USING (unit_id)
    UNION ALL
    -- bascules ; un renommage daté avant la première apparition est ramené
    -- à celle-ci et l'emporte alors sur l'amorce (prio 1)
    SELECT r.unit_id, greatest(make_date(r.annee, 1, 1), b.d0), r.nom_apres, 1
    FROM   stg_renames r
    JOIN   bornes b USING (unit_id)
    WHERE  make_date(r.annee, 1, 1) < b.d1
),
dedoublonne AS (
    SELECT DISTINCT ON (unit_id, valid_from) unit_id, valid_from, nom
    FROM   points
    ORDER  BY unit_id, valid_from, prio DESC
),
intervalles AS (
    SELECT d.unit_id, d.nom, d.valid_from,
           coalesce(lead(d.valid_from) OVER (PARTITION BY d.unit_id
                                             ORDER BY d.valid_from),
                    b.d1) AS valid_to
    FROM   dedoublonne d
    JOIN   bornes b USING (unit_id)
)
INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT unit_id, nom, valid_from, valid_to
FROM   intervalles
WHERE  valid_from < valid_to;

-- ---------------------------------------------------------------------------
-- 7. régimes électoraux
-- ---------------------------------------------------------------------------
INSERT INTO regime_electoral (annee, n_dep, n_circo, ratio, regime)
SELECT annee, n_dep, n_circo, ratio, regime FROM stg_regime;

ANALYZE;

-- ---------------------------------------------------------------------------
-- 8. Compte rendu
-- ---------------------------------------------------------------------------
\echo ''
\echo '--- Chargement terminé ---'
SELECT 'atom'             AS table, count(*) FROM atom
UNION ALL SELECT 'unit',            count(*) FROM unit
UNION ALL SELECT '  dont provisoires', count(*) FROM unit WHERE provisoire
UNION ALL SELECT 'unit_version',    count(*) FROM unit_version
UNION ALL SELECT 'membership',      count(*) FROM membership
UNION ALL SELECT 'regime_electoral', count(*) FROM regime_electoral
UNION ALL SELECT 'diag_attribution_ambigue',  count(*) FROM diag_attribution_ambigue
UNION ALL SELECT 'diag_commune_fractionnee',  count(*) FROM diag_commune_fractionnee
UNION ALL SELECT 'diag_pseudo_multi_commune', count(*) FROM diag_pseudo_multi_commune
UNION ALL SELECT 'diag_geom_correspondance',  count(*) FROM diag_geom_correspondance;

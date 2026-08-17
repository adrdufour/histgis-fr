-- ============================================================================
-- histgis — 40_outremer.sql : les 129 communes d'outre-mer
--
-- Pose la trame communale, les cantons et les circonscriptions de 1986 et 2012
-- pour la Guadeloupe, la Martinique, la Guyane, La Réunion et Mayotte.
--
-- Rejouable : recrée ses tables à chaque passage, ne touche à rien d'autre.
--
-- /!\ ÉCRIT LE 16 AOÛT 2026, JAMAIS EXÉCUTÉ. Il n'y avait pas de PostgreSQL
-- dans l'environnement où il a été rédigé. Les chiffres attendus en section 8
-- viennent, eux, de mesures réelles sur les shapefiles
-- (`sources/outremer/recette_outremer.py`) : ce sont les recettes qui diront
-- si le script les atteint. À lancer sur une copie avant la vraie base.
--
--
-- POURQUOI DES TABLES SÉPARÉES
-- ----------------------------
-- Deux raisons, et la seconde suffirait.
--
-- 1. Le SRID. `atom_geom.geom` est typé `geometry(MultiPolygon, 2154)`. Le
--    Lambert-93 n'est défini que pour la métropole : reprojeter l'outre-mer
--    dedans gonfle les surfaces de 1,28× en Guadeloupe à 3,54× à La Réunion,
--    qui passerait de 2 502 à 8 856 km². Mesuré le 16 août 2026, pas estimé.
--    Comme tous les contrôles du projet sont surfaciques, l'outre-mer vit en
--    **EPSG:4326** et ses surfaces se calculent en `geography`.
--
-- 2. `unit.dep` est `char(2)`. Les départements d'outre-mer tiennent sur trois
--    caractères. On pourrait leur donner les codes du ministère de l'Intérieur
--    (`ZA` à `ZD`), qui font bien deux caractères — mais Mayotte n'en a pas, et
--    surtout ce serait faire entrer dans une colonne un code que rien d'autre
--    dans la base n'emploie. `om_unit.dep` est donc `char(3)` et porte le code
--    INSEE, celui qu'on lit partout ailleurs.
--
-- Conséquence assumée : `snapshot()` ne voit pas l'outre-mer. `om_snapshot()`
-- lui répond, avec la même signature. La vue `snapshot_union_geom` plus bas
-- réunit les deux en reprojetant la métropole à la volée, pour qui veut une
-- couche unique.
--
--
-- PRÉREQUIS : LA TRAME, CHARGÉE EN 4326
-- --------------------------------------
-- Les cinq lots GEOFLA sont chacun dans leur propre projection. `-t_srs` les
-- ramène toutes en 4326 — c'est `-t_srs` qu'il faut ici, pas `-a_srs` : le
-- premier reprojette, le second se contente de réétiqueter, ce qui poserait la
-- Guadeloupe à quelques milliers de kilomètres de chez elle sans rien casser
-- de visible.
--
--   bash sql/charger_outremer.sh
--
-- C'est une boucle sur cinq lots — le premier en `-overwrite`, les suivants en
-- `-append` — donc un script, pas une ligne à recopier. Il charge à la fois les
-- communes et les cantons, vérifie les effectifs et le SRID.
--
-- Le même script charge les cantons dans `om_canton_src` — 113 entités, Mayotte
-- n'étant pas dans le fichier du ministère, ses 19 cantons ne viennent que de là.
--
-- Attention : `CODE_DEPT` vaut `97` pour les cinq départements, l'attribut ne
-- les distingue pas. Le département ne peut venir que du lot, d'où le chargement
-- lot par lot et le `CODE_CHF` comme clé communale (`'97' || CODE_CHF`).
--
-- Et la trame IRIS, pour les 28 communes multicantonales :
--   python3 cartes/recupere_iris_outremer.py --charger   -> histgis.iris_om
--
--
-- CE QUE CE FICHIER NE FAIT PAS
-- ------------------------------
-- Il ne découpe pas les 28 communes multicantonales. GEOFLA n'individualise
-- pas leurs cantons : il en fait une entité unique portant un pseudo-code
-- `90`-`99`. 69 polygones cantonaux propres pour 153 cantons réels dans les
-- quatre DOM, soit 45 %. Les 85 communes d'un seul canton sont rattachées ici
-- — leur `CODE_CANT` concorde 85 fois sur 85 avec le fichier du ministère. Les
-- 27 autres attendent le découpage sur trame IRIS, et sont listées en fin de
-- fichier plutôt qu'attribuées au jugé.
--
-- Il ne pose pas 1870-1946. Les DOM ne sont départements que depuis 1946 ;
-- avant, ce sont des colonies avec des députés mais pas de cantons au sens
-- métropolitain. C'est une enquête, pas une extension.
--
--
-- CE QUI EST DÉJÀ VÉRIFIÉ (16 août 2026)
-- ---------------------------------------
-- 129 communes, 0 géométrie invalide, 0,00 km² de recouvrement — le défaut des
-- 3 945 km² comptés deux fois en métropole n'existe pas ici. Codes INSEE
-- identiques au fichier du ministère, 112/112 dans les quatre DOM. Trame
-- communale stable de 1999 à 2012 à deux communes près, Saint-Barthélemy et
-- Saint-Martin, détachées en 2007. Voir `docs/note_outre_mer.md` et
-- `sources/outremer/recette_outremer.py`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Les DOM deviennent départements par la loi du 19 mars 1946. Mayotte le
-- 31 mars 2011. Les bornes des circonscriptions reprennent celles de `27` et
-- `28`, pour que les deux séries se comparent sans conversion.
\set debut_86  '1986-11-24'
\set fin_86    '2010-02-23'
\set debut_12  '2010-02-23'
\set fin_12    '2013-01-01'
\set debut_dep '1946-03-19'

-- Le chemin du `\copy` est relatif au répertoire d'où psql est lancé, pas au
-- fichier SQL. Par défaut on suppose la racine du dépôt, qui est d'où tournent
-- `load.sh` et `rebuild.sh`. Sinon, le passer explicitement :
--   psql -d histgis -v circo_om=/chemin/vers.csv -f sql/40_outremer.sql
SELECT CASE WHEN :'circo_om' = ':circo_om'
            THEN 'circo/circo_outremer_1986_2012.csv'
            ELSE :'circo_om' END AS circo_om \gset

DO $$
BEGIN
    IF to_regclass('histgis.om_commune_src') IS NULL THEN
        RAISE EXCEPTION
          'Table histgis.om_commune_src absente : charger les cinq lots COMMUNE '
          'avec ogr2ogr (voir l''en-tête de ce fichier) avant de le lancer.';
    END IF;
    IF to_regclass('histgis.om_canton_src') IS NULL THEN
        RAISE EXCEPTION
          'Table histgis.om_canton_src absente : charger les cinq lots CANTON. '
          'Sans elle, les 19 cantons de Mayotte n''ont aucune source.';
    END IF;
    IF to_regclass('histgis.iris_om') IS NULL THEN
        RAISE NOTICE
          'histgis.iris_om absente : les recettes sur les 28 communes à '
          'découper compteront zéro IRIS. Lancer recupere_iris_outremer.py '
          '--charger pour les voir.';
    END IF;
END $$;

-- Le contrôle qui attrape `-a_srs` mis pour `-t_srs`. Une trame mal
-- reprojetée reste une trame valide : elle ne se signale que par sa position.
DO $$
DECLARE s int; x float; y float;
BEGIN
    SELECT DISTINCT ST_SRID(geom) INTO s FROM om_commune_src;
    IF s <> 4326 THEN
        RAISE EXCEPTION 'om_commune_src en SRID %, 4326 attendu.', s;
    END IF;
    SELECT ST_X(ST_Centroid(ST_Collect(geom))), ST_Y(ST_Centroid(ST_Collect(geom)))
      INTO x, y FROM om_commune_src WHERE insee_com LIKE '971%';
    IF x NOT BETWEEN -62.0 AND -60.8 OR y NOT BETWEEN 15.8 AND 16.6 THEN
        RAISE EXCEPTION
          'La Guadeloupe est à (%, %), attendue vers (-61,5 ; 16,2). '
          'Reprojection manquée : utiliser -t_srs et non -a_srs.', x, y;
    END IF;
    RAISE NOTICE 'SRID 4326 et Guadeloupe à (%, %) — trame en place.', x, y;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace : ce que ce fichier a écrit, pour pouvoir le défaire
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS om_trace;
CREATE TABLE om_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 1. om_atom : un atome par commune, l'atom_id EST le code INSEE
--
-- Pas de code Cassini ici : la série TRF-GIS ne couvre pas l'outre-mer, et
-- inventer un identifiant intermédiaire n'apporterait rien. Le code INSEE est
-- stable sur toute la période utile — c'est précisément ce que le contrôle
-- 1999/2012 a établi.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS om_membership;
DROP TABLE IF EXISTS om_atom_geom;
DROP TABLE IF EXISTS om_unit_version;
DROP TABLE IF EXISTS om_unit;
DROP TABLE IF EXISTS om_atom;

CREATE TABLE om_atom (
    atom_id  char(5) PRIMARY KEY,          -- code INSEE
    dep      char(3) NOT NULL,
    nom      text    NOT NULL,
    -- vrai si la commune relève de plusieurs cantons : GEOFLA ne la découpe
    -- pas, son rattachement cantonal reste à établir sur trame IRIS
    multi    boolean NOT NULL DEFAULT false
);

INSERT INTO om_atom (atom_id, dep, nom, multi)
SELECT insee_com, left(insee_com, 3), nom_com,
       -- le pseudo-code 90-99 est la façon dont GEOFLA dit « je ne découpe pas »
       (code_cant ~ '^9[0-9]$')
FROM   om_commune_src;

INSERT INTO om_trace (quoi, cle) SELECT 'atom', atom_id FROM om_atom;

CREATE TABLE om_atom_geom (
    atom_id char(5) PRIMARY KEY REFERENCES om_atom(atom_id) ON DELETE CASCADE,
    geom    geometry(MultiPolygon, 4326) NOT NULL,
    source  text NOT NULL CHECK (source IN ('geofla2015'))
);

INSERT INTO om_atom_geom (atom_id, geom, source)
SELECT insee_com, ST_Multi(ST_MakeValid(geom)), 'geofla2015'
FROM   om_commune_src;

CREATE INDEX om_atom_geom_gix ON om_atom_geom USING gist (geom);

-- ---------------------------------------------------------------------------
-- 2. om_unit : cantons et circonscriptions
--
-- `dep` sur trois caractères, code INSEE. Les identifiants reprennent les
-- conventions de la base : canton = dep || code sur deux chiffres,
-- circonscription = code || '@AAAA', segment de découpage daté.
-- ---------------------------------------------------------------------------
CREATE TABLE om_unit (
    unit_id        text PRIMARY KEY,
    niveau         text NOT NULL CHECK (niveau IN ('canton', 'circo')),
    dep            char(3) NOT NULL,
    code           text,
    regime         text CHECK (regime IN ('liste', 'uninominal')),
    segment_depuis smallint,
    nom            text,
    UNIQUE (unit_id, niveau)
);

CREATE TABLE om_unit_version (
    om_unit_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    unit_id    text NOT NULL REFERENCES om_unit(unit_id) ON DELETE CASCADE,
    nom        text,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS
                   (daterange(valid_from, valid_to, '[)')) STORED,
    CONSTRAINT om_unit_version_bornes CHECK (valid_from < valid_to),
    CONSTRAINT om_unit_version_non_chevauchant
        EXCLUDE USING gist (unit_id WITH =, periode WITH &&)
);

-- Les deux contraintes qui font la fiabilité de la base métropolitaine sont
-- reprises telles quelles : un atome n'appartient qu'à une unité par niveau à
-- un instant donné, et les périodes d'une même unité ne se chevauchent pas.
CREATE TABLE om_membership (
    om_membership_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atom_id    char(5) NOT NULL REFERENCES om_atom(atom_id) ON DELETE CASCADE,
    unit_id    text NOT NULL,
    niveau     text NOT NULL CHECK (niveau IN ('canton', 'circo')),
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS
                   (daterange(valid_from, valid_to, '[)')) STORED,
    CONSTRAINT om_membership_bornes CHECK (valid_from < valid_to),
    CONSTRAINT om_membership_unit_fk
        FOREIGN KEY (unit_id, niveau) REFERENCES om_unit(unit_id, niveau),
    CONSTRAINT om_membership_non_chevauchant
        EXCLUDE USING gist (atom_id WITH =, niveau WITH =, periode WITH &&)
);
CREATE INDEX om_membership_unit_idx ON om_membership (unit_id, valid_from);
CREATE INDEX om_membership_per_idx  ON om_membership USING gist (periode);

-- ---------------------------------------------------------------------------
-- 3. Le fichier du ministère : cantons et circonscriptions, 1986 et 2012
--
-- 171 lignes extraites de `circo/correspondance_2012.xls`, qui contenait
-- l'outre-mer depuis le début sous les codes ZA/ZB/ZC/ZD.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS om_src;
CREATE TABLE om_src (
    canton    text, depcant text, dep text, dep_insee char(3),
    nomdep    text, nomct   text, insee char(5), nomcom text,
    c1986     text, c2012   text
);
\echo 'Lecture du fichier du ministère :' :circo_om
\set cmd '\\copy om_src FROM ' :'circo_om' ' WITH (FORMAT csv, HEADER true)'
:cmd

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM om_src;
    IF n <> 171 THEN
        RAISE EXCEPTION '% lignes lues, 171 attendues dans le fichier '
                        'du ministère.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Les cantons
--
-- Tous les cantons du fichier sont créés — y compris ceux qui n'ont pas de
-- polygone propre. Une unité sans géométrie reste une unité : c'est la même
-- décision que pour les 132 circonscriptions `provisoire` de 1870-1940, et
-- elle évite de perdre l'information en attendant la trame.
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, nom)
    SELECT DISTINCT s.canton, 'canton', s.dep_insee, s.depcant, s.nomct
    FROM   om_src s
    RETURNING unit_id
)
INSERT INTO om_trace (quoi, cle) SELECT 'unit_canton', unit_id FROM ins;

-- Mayotte n'est pas dans le fichier du ministère : ses 19 cantons viennent de
-- GEOFLA seul, où 16 sont individualisés et 3 sont noyés dans Mamoudzou.
WITH ins AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, nom)
    SELECT DISTINCT '976' || c.code_cant, 'canton', '976',
           'MYT' || c.code_cant, c.nom_chf
    FROM   om_canton_src c
    WHERE  c.code_cant !~ '^9[0-9]$'
      AND  NOT EXISTS (SELECT 1 FROM om_unit u
                       WHERE u.unit_id = '976' || c.code_cant)
    RETURNING unit_id
)
INSERT INTO om_trace (quoi, cle) SELECT 'unit_canton', unit_id FROM ins;

-- ---------------------------------------------------------------------------
-- 5. Le rattachement cantonal des 85 communes d'un seul canton
--
-- Ces 85 sont celles dont GEOFLA porte un `CODE_CANT` réel. La concordance
-- avec le fichier du ministère a été vérifiée : 85 sur 85, zéro écart, deux
-- sources qui ne se connaissent pas.
--
-- Les 27 multicantonales (plus Mamoudzou) ne reçoivent rien. Le silence est
-- ici la bonne réponse : `om_membership_non_chevauchant` refuserait de toute
-- façon de faire appartenir une commune à ses quatre cantons à la fois, et
-- c'est cette contrainte qui fait la valeur de la base.
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO om_membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT s.insee, s.canton, 'canton',
           :'debut_dep'::date, :'fin_12'::date
    FROM   om_src s
    JOIN   om_atom a ON a.atom_id = s.insee AND NOT a.multi
    RETURNING om_membership_id
)
INSERT INTO om_trace (quoi, cle)
SELECT 'membership_canton', om_membership_id::text FROM ins;

-- ---------------------------------------------------------------------------
-- 6. Les circonscriptions de 1986 et de 2012
--
-- Une commune peut relever de plusieurs cantons et d'une seule circonscription
-- — c'est le cas général outre-mer, où les circonscriptions sont peu
-- nombreuses. Là où une commune est partagée entre deux circonscriptions, elle
-- est écartée par le `HAVING count(DISTINCT ...) = 1` et listée en recette :
-- mieux vaut un trou déclaré qu'une attribution arbitraire.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS om_circo_src;
CREATE TABLE om_circo_src AS
SELECT insee, dep_insee, '1986' AS segment, c1986 AS circo FROM om_src
 WHERE c1986 IS NOT NULL
UNION ALL
SELECT insee, dep_insee, '2012', c2012 FROM om_src
 WHERE c2012 IS NOT NULL;

DROP TABLE IF EXISTS om_circo_unique;
CREATE TABLE om_circo_unique AS
SELECT insee, dep_insee, segment, min(circo) AS circo
FROM   om_circo_src
GROUP  BY insee, dep_insee, segment
HAVING count(DISTINCT circo) = 1;

WITH nouveau AS (
    SELECT DISTINCT dep_insee, segment, circo FROM om_circo_unique
),
ins AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
    SELECT n.dep_insee || '-' || lpad(n.circo, 2, '0') || '@' || n.segment,
           'circo', n.dep_insee,
           n.dep_insee || '-' || lpad(n.circo, 2, '0'),
           'uninominal',
           CASE n.segment WHEN '1986' THEN 1986 ELSE 2009 END,
           n.circo || 'e circonscription'
    FROM   nouveau n
    RETURNING unit_id
)
INSERT INTO om_trace (quoi, cle) SELECT 'unit_circo', unit_id FROM ins;

WITH ins AS (
    INSERT INTO om_membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT u.insee,
           u.dep_insee || '-' || lpad(u.circo, 2, '0') || '@' || u.segment,
           'circo',
           CASE u.segment WHEN '1986' THEN :'debut_86'::date
                          ELSE :'debut_12'::date END,
           CASE u.segment WHEN '1986' THEN :'fin_86'::date
                          ELSE :'fin_12'::date END
    FROM   om_circo_unique u
    RETURNING om_membership_id
)
INSERT INTO om_trace (quoi, cle)
SELECT 'membership_circo', om_membership_id::text FROM ins;

ANALYZE om_atom; ANALYZE om_unit; ANALYZE om_membership;

-- ---------------------------------------------------------------------------
-- 7. om_snapshot() : même signature que snapshot(), un SRID de plus
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION om_snapshot(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (unit_id text, niveau text, dep char(3), nom text,
               n_atomes bigint, atomes text[])
LANGUAGE sql STABLE AS $$
    SELECT u.unit_id, u.niveau, u.dep,
           coalesce(uv.nom, u.nom),
           count(*),
           array_agg(m.atom_id ORDER BY m.atom_id)
    FROM   om_membership m
    JOIN   om_unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    LEFT   JOIN om_unit_version uv
           ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    WHERE  m.niveau = p_niveau AND m.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION om_snapshot(date, text) IS
    'Composition des unités d''outre-mer à une date. Géométries en 4326 : '
    'les surfaces se mesurent en ST_Area(geom::geography), jamais ST_Area(geom).';

CREATE OR REPLACE FUNCTION om_snapshot_geom(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (unit_id text, dep char(3), nom text, geom geometry(MultiPolygon, 4326))
LANGUAGE sql STABLE AS $$
    SELECT u.unit_id, u.dep, coalesce(uv.nom, u.nom),
           ST_Multi(ST_UnaryUnion(ST_Collect(g.geom)))
    FROM   om_membership m
    JOIN   om_unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    JOIN   om_atom_geom g ON g.atom_id = m.atom_id
    LEFT   JOIN om_unit_version uv
           ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    WHERE  m.niveau = p_niveau AND m.periode @> p_date
    GROUP  BY u.unit_id, u.dep, coalesce(uv.nom, u.nom);
$$;

-- ---------------------------------------------------------------------------
-- 8. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Ce qui a été posé ==='
SELECT quoi, count(*) FROM om_trace GROUP BY quoi ORDER BY 1;

\echo ''
\echo '=== 2. Communes par département (attendu 32/34/22/24/17 = 129) ==='
SELECT dep, count(*) AS communes,
       count(*) FILTER (WHERE multi) AS multicantonales
FROM   om_atom GROUP BY dep ORDER BY dep;

\echo ''
\echo '=== 3. Surfaces, en geography (attendu ~1631/1104/83824/2502/362 km²) ==='
SELECT a.dep, round(sum(ST_Area(g.geom::geography))/1e6) AS km2
FROM   om_atom a JOIN om_atom_geom g ON g.atom_id = a.atom_id
GROUP  BY a.dep ORDER BY a.dep;

\echo ''
\echo '--- recouvrement : somme - union, doit valoir 0 km² ---'
SELECT round((sum(ST_Area(g.geom::geography))
              - ST_Area(ST_Union(g.geom)::geography))/1e6) AS km2_recouvres
FROM   om_atom_geom g;

\echo ''
\echo '=== 4. Rattachement cantonal (attendu 85 communes, 27+1 en attente) ==='
SELECT (SELECT count(DISTINCT atom_id) FROM om_membership WHERE niveau='canton')
         AS communes_rattachees,
       (SELECT count(*) FROM om_atom WHERE multi) AS en_attente_de_decoupage;

\echo ''
\echo '--- les communes en attente, et leur trame IRIS ---'
SELECT a.atom_id, a.nom,
       coalesce((SELECT count(*) FROM iris_om i WHERE i.code_insee = a.atom_id), 0)
         AS iris
FROM   om_atom a WHERE a.multi ORDER BY a.dep, a.atom_id;

\echo ''
\echo '=== 5. Circonscriptions (attendu 1986 : 4+4+2+5 ; 2012 : 4+4+2+7) ==='
SELECT segment_depuis, dep, count(*) AS circos
FROM   om_unit WHERE niveau = 'circo'
GROUP  BY segment_depuis, dep ORDER BY segment_depuis, dep;

\echo ''
\echo '--- communes partagées entre deux circonscriptions, donc écartées ---'
SELECT s.segment, s.insee, a.nom, count(DISTINCT s.circo) AS n_circos
FROM   om_circo_src s JOIN om_atom a ON a.atom_id = s.insee
GROUP  BY s.segment, s.insee, a.nom HAVING count(DISTINCT s.circo) > 1
ORDER  BY s.segment, s.insee;

\echo ''
\echo '=== 6. Intégrité ==='
\echo '--- chevauchements de membership (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   om_membership a JOIN om_membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.om_membership_id < b.om_membership_id AND a.periode && b.periode;

\echo '--- géométries invalides (doit valoir 0) ---'
SELECT count(*) AS invalides FROM om_atom_geom WHERE NOT ST_IsValid(geom);

\echo '--- atomes sans géométrie (doit valoir 0) ---'
SELECT count(*) AS sans_geom FROM om_atom a
WHERE NOT EXISTS (SELECT 1 FROM om_atom_geom g WHERE g.atom_id = a.atom_id);

\echo '--- SRID (doit valoir 4326 partout) ---'
SELECT DISTINCT ST_SRID(geom) AS srid FROM om_atom_geom;

\echo ''
\echo '=== 7. Un exemple, pour voir ==='
SELECT unit_id, dep, nom, n_atomes
FROM   om_snapshot('2012-06-01', 'circo') ORDER BY unit_id;

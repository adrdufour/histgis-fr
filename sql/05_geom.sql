-- ============================================================================
-- histgis — 05_geom.sql : géométries
--
-- Prérequis : la trame GEOFLA 2011 doit être chargée AVANT, dans la table
-- histgis.geofla_commune. Voir README, section « Géométrie ».
--
--   ogr2ogr -f PostgreSQL PG:"dbname=histgis" COMMUNE.SHP \
--       -nln histgis.geofla_commune -nlt MULTIPOLYGON \
--       -lco GEOMETRY_NAME=geom -lco FID=gid -a_srs EPSG:2154 -overwrite
--
-- Rejouable : recrée atom_geom à chaque passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.geofla_commune') IS NULL THEN
        RAISE EXCEPTION 'Table histgis.geofla_commune absente : charger COMMUNE.SHP avec ogr2ogr avant ce script.';
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS geofla_commune_insee_idx ON geofla_commune (insee_com);
CREATE INDEX IF NOT EXISTS geofla_commune_geom_idx  ON geofla_commune USING gist (geom);

-- ---------------------------------------------------------------------------
-- atom_geom : un polygone par atome.
--
-- Deux atomes peuvent porter le MÊME polygone, et c'est voulu :
--   - deux communes historiques fusionnées depuis partagent un code INSEE ;
--   - une commune éclatée entre plusieurs cantons donne autant d'atomes-
--     fractions, sans géométrie propre (l'extracteur le dit explicitement).
-- Conséquence à assumer : si ces atomes tombent dans des unités différentes,
-- les polygones dissous se recouvrent. La colonne `partagee` les repère et
-- check_geom_overlap() mesure l'ampleur du phénomène.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS atom_geom;
CREATE TABLE atom_geom (
    atom_id  text PRIMARY KEY REFERENCES atom(atom_id) ON DELETE CASCADE,
    geom     geometry(MultiPolygon, 2154) NOT NULL,
    -- 'successeur' est posé par 06_insee_mvt.sql
    source   text NOT NULL CHECK (source IN ('geofla', 'union_prefixe', 'absorbee', 'successeur')),
    partagee boolean NOT NULL DEFAULT false
);

-- 1. jointure directe sur le code INSEE
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       'geofla'
FROM   atom a
JOIN   geofla_commune g ON g.insee_com = a.insee_geofla
GROUP  BY a.atom_id;

-- 2. rattrapages listés dans geom_correspondance.csv
--    'union_prefixe' : Lyon et Marseille, dont les arrondissements portent
--    des codes préfixés (69381-69389, 13201-13216)
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       'union_prefixe'
FROM   atom a
JOIN   diag_geom_correspondance d ON d.insee = a.insee_geofla
JOIN   geofla_commune g ON g.insee_com LIKE d.cible || '%'
WHERE  d.methode = 'union_prefixe'
  AND  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
GROUP  BY a.atom_id;

--    'absorbee' : la commune a fusionné après 2011, on prend l'absorbante
INSERT INTO atom_geom (atom_id, geom, source)
SELECT a.atom_id,
       ST_Multi(ST_UnaryUnion(ST_Collect(g.geom))),
       'absorbee'
FROM   atom a
JOIN   diag_geom_correspondance d ON d.insee = a.insee_geofla
JOIN   geofla_commune g ON g.insee_com = d.cible
WHERE  d.methode = 'absorbee'
  AND  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
GROUP  BY a.atom_id;

-- 3. marquage des polygones servant à plusieurs atomes
UPDATE atom_geom ag SET partagee = true
FROM  (SELECT insee_geofla FROM atom
       WHERE insee_geofla IS NOT NULL
       GROUP BY insee_geofla HAVING count(*) > 1) d
JOIN  atom a ON a.insee_geofla = d.insee_geofla
WHERE ag.atom_id = a.atom_id;

CREATE INDEX atom_geom_geom_idx ON atom_geom USING gist (geom);
ANALYZE atom_geom;

-- ---------------------------------------------------------------------------
-- snapshot_geom(date, niveau) : la carte, enfin. Une ligne par unité vivante,
-- avec sa géométrie dissoute. `n_sans_geom` dit combien d'atomes manquent à
-- l'appel — une unité avec n_sans_geom > 0 est incomplète, pas fausse.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION snapshot_geom(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (
    unit_id     text,
    niveau      text,
    dep         char(2),
    nom         text,
    n_atomes    bigint,
    n_sans_geom bigint,
    n_partagees bigint,
    geom        geometry(MultiPolygon, 2154)
)
LANGUAGE sql STABLE AS $$
    SELECT u.unit_id,
           u.niveau,
           u.dep,
           coalesce(uv.nom, u.nom),
           count(*),
           count(*) FILTER (WHERE ag.atom_id IS NULL),
           count(*) FILTER (WHERE ag.partagee),
           ST_Multi(ST_UnaryUnion(ST_Collect(ag.geom)))
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
    WHERE  m.niveau = p_niveau
      AND  m.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION snapshot_geom(date, text) IS
    'Carte dissoute à une date. Ex : SELECT unit_id, nom, geom FROM snapshot_geom(''1885-06-01'');';

-- ---------------------------------------------------------------------------
-- check_geom() : ce qui manque.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_geom()
RETURNS TABLE (probleme text, n bigint, exemples text[])
LANGUAGE sql STABLE AS $$
    SELECT 'atome sans geometrie', count(*),
           (array_agg(a.atom_id ORDER BY a.atom_id))[1:5]
    FROM   atom a
    WHERE  NOT EXISTS (SELECT 1 FROM atom_geom g WHERE g.atom_id = a.atom_id)
    UNION ALL
    SELECT 'polygone partage entre plusieurs atomes', count(*),
           (array_agg(atom_id ORDER BY atom_id))[1:5]
    FROM   atom_geom WHERE partagee
    UNION ALL
    SELECT 'geometrie invalide', count(*),
           (array_agg(atom_id ORDER BY atom_id))[1:5]
    FROM   atom_geom WHERE NOT ST_IsValid(geom)
    UNION ALL
    SELECT 'source ' || source, count(*), (array_agg(atom_id))[1:3]
    FROM   atom_geom GROUP BY source;
$$;

-- ---------------------------------------------------------------------------
-- check_geom_overlap(date, niveau) : unités qui se recouvrent à une date.
-- Conséquence directe des polygones partagés ; à connaître avant de publier
-- une carte. La surface commune est donnée en km².
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_geom_overlap(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (unit_a text, unit_b text, surface_km2 numeric)
LANGUAGE sql STABLE AS $$
    WITH s AS (SELECT unit_id, geom FROM snapshot_geom(p_date, p_niveau)
               WHERE geom IS NOT NULL)
    SELECT a.unit_id, b.unit_id,
           round((ST_Area(ST_Intersection(a.geom, b.geom)) / 1e6)::numeric, 3)
    FROM   s a JOIN s b ON a.unit_id < b.unit_id AND ST_Overlaps(a.geom, b.geom)
    WHERE  ST_Area(ST_Intersection(a.geom, b.geom)) > 1000   -- > 1000 m²
    ORDER  BY 3 DESC;
$$;

\echo ''
\echo '=== Géométries chargées ==='
SELECT * FROM check_geom();

-- ---------------------------------------------------------------------------
-- Contrôle des préfixes : un préfixe trop long ne casse rien, il ampute en
-- silence. C'est arrivé — `1320` au lieu de `132` pour Marseille ne prenait que
-- les arrondissements 1 à 9 et perdait 133,66 km² sans qu'aucun contrôle ne
-- bronche, l'atome ayant bien une géométrie. Seule la comparaison à une source
-- extérieure l'a révélé. D'où ce tableau, à lire à chaque chargement.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== Préfixes union_prefixe : ce que chacun capte ==='
\echo '    Vérifier que le compte correspond au nombre d''arrondissements'
\echo '    attendu — Paris 20, Marseille 16, Lyon 9. Un compte inférieur'
\echo '    signale un préfixe trop long, donc une commune amputée.'
SELECT d.insee,
       d.cible,
       count(g.insee_com)                              AS captees,
       round((sum(ST_Area(g.geom)) / 1e6)::numeric, 2) AS km2,
       (SELECT count(*) FROM geofla_commune g2
         WHERE g2.insee_com LIKE left(d.cible, 3) || '%')
                                                       AS captees_si_3_car,
       min(g.insee_com) || ' … ' || max(g.insee_com)   AS plage
FROM   diag_geom_correspondance d
LEFT   JOIN geofla_commune g ON g.insee_com LIKE d.cible || '%'
WHERE  d.methode = 'union_prefixe'
GROUP  BY d.insee, d.cible
ORDER  BY d.insee;

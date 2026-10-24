-- ============================================================================
-- histgis — 118_paris_bois_1925_1929.sql : les bois de Boulogne et de
--                                          Vincennes hors de Paris jusqu'aux
--                                          décrets de 1925 et 1929
--
--   psql -d histgis -f sql/118_paris_bois_1925_1929.sql                 -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/118_paris_bois_1925_1929.sql
--   psql -d histgis -1 -v defaire=1   -f sql/118_paris_bois_1925_1929.sql
--
-- LE DÉFAUT
-- =========
-- De 1863 à 1929, la carte dessine Paris sur les 80 quartiers d'IRIS, qui
-- sont ceux d'AUJOURD'HUI : bois compris. Mesuré au 1900-06-01 sur
-- `carte_partition_atome` : PQ45, PQ46 (Bel-Air, Picpus) portent 10,06 km² du
-- bois de Vincennes, PQ61, PQ62, PQ63 (Auteuil, Muette, Porte-Dauphine)
-- 8,80 km² du bois de Boulogne. La 2/12e circonscription de 1900 fait
-- 13,23 km², la 1/16e 11,88.
--
-- Or la loi de 1859 arrête Paris au pied du glacis de l'enceinte. Les deux
-- bois sont propriété de la Ville (1852 et 1860), pas son territoire : ils
-- restent aux communes riveraines jusqu'aux décrets d'annexion —
--
--     bois de Boulogne, part de Boulogne    décret du 3 avril 1925 (JO du 5)
--     bois de Boulogne, part de Neuilly     décret du 18 avril 1929 (JO du 19)
--     bois de Vincennes, sept communes      décrets du 18 avril 1929, un par
--                                           commune (JO du 19)
--
-- Sources : notices « Bois de Boulogne » et « Bois de Vincennes » de
-- Wikipédia, recoupées pour 1925 par les notices de voies des Archives
-- nationales (« territoire de Boulogne-Billancourt annexé à Paris par décret
-- du 3 avril 1925 »). Les JO de 1925 et 1929 ne sont pas dans `sources/JORF/` : les
-- deux dates sont à confronter au texte.
--
-- ANR ne le voit pas non plus : il retire le bois aux communes dès 1860 et
-- le donne au Paris agrandi (atome 26207, sans polygone). `102` le leur rend
-- sur [1860,1863) ; ce fichier prolonge jusqu'au décret.
--
-- CE QUE CE FICHIER FAIT
-- ======================
--   bois       = ∪ des cinq IRIS « Bois de Boulogne 1-3 », « Bois de
--                Vincennes 1-2 » (`iris_paris`)
--   part(A)    = polygone ANR de A au 1859-06-01 ∩ bois, morceaux ≥ 1 ha
--
-- Le 1859-06-01 et non une date antérieure : ANR y porte déjà la
-- redistribution de 1860 — la part de Passy et d'Auteuil hors de l'enceinte
-- passe à Boulogne, celle de Bercy à Charenton (l'écart d'un an d'ANR,
-- `JOURNAL` du 2 octobre). Ce qu'ANR laisse alors aux annexées dans l'IRIS
-- du bois (~0,74 km² : Passy, Auteuil, Bercy) est intra-muros — la zone des
-- fortifications que l'IRIS range avec le bois — et RESTE à Paris.
--
--   commune A, [1863, décret(A))  : polygone ANR ∪ part(A)
--   quartier Q, [1863, 1925-04-03) : Q − ∪ toutes les parts
--   quartier Q, [1925-04-03, 1929-04-18) : Q − ∪ parts de 1929
--
-- Les quartiers `PQnn` n'ont pas de fenêtre ANR : ils tombent sur leur repli
-- (`atom_geom`, le quartier d'IRIS). Ils reçoivent ici des fenêtres datées,
-- source `iris-bois_118`. Ce sont des fractions : `84` ne leur applique pas la
-- règle du dernier polygone ANR (`gc`), et après 1929 ils retombent sur le
-- quartier entier. Les arrondissements-cantons 76219 et 76223 ne sont pas
-- touchés : ils ne gagnent déjà aucune face contre les quartiers, et le sol
-- du bois, réclamé par une commune datée, ne leur reviendra pas.
--
-- CE QUI N'EST PAS FAIT
-- =====================
-- La zone non aedificandi, annexée commune par commune de 1925 à 1930, reste
-- à Paris dès 1863 : la trame IRIS ne la sépare pas. Seuls les deux bois ont
-- un IRIS à eux.
--
-- ORDRE ET RÉVERSIBILITÉ
-- ======================
-- Après `102`, dont il recoupe les fenêtres [1863,…). `p118_trace` garde les
-- fenêtres d'origine et les fenêtres posées. Rejouer `102` demande de défaire
-- `118` d'abord (`-v defaire=1`), puis de le rejouer : `102` réinsérerait
-- sinon des fenêtres qui chevauchent celles-ci, et la contrainte d'exclusion
-- le refuserait.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p118_trace (
    quoi     text      NOT NULL CHECK (quoi IN ('origine', 'pose')),
    atom_id  text      NOT NULL,
    periode  daterange NOT NULL,
    geom     geometry(MultiPolygon, 2154),
    poly_id  text,
    pseudo_t boolean,
    source   text,
    pose_le  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, atom_id, periode)
);

\if :{?defaire}

DELETE FROM atom_geom_anr g
 USING p118_trace t
 WHERE t.quoi = 'pose' AND t.atom_id = g.atom_id AND t.periode = g.periode;
INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT atom_id, periode, geom, poly_id, pseudo_t, source
FROM   p118_trace WHERE quoi = 'origine';
TRUNCATE p118_trace;
\echo '=== 118 défait ==='

\else

DO $$
BEGIN
    IF to_regclass('histgis.iris_paris') IS NULL
       OR (SELECT count(*) FROM histgis.iris_paris WHERE nom_iris LIKE 'Bois de %') <> 5 THEN
        RAISE EXCEPTION 'iris_paris doit porter les cinq IRIS des bois (circo/paris_quartiers.py)';
    END IF;
    IF to_regclass('histgis.lambeaux_1860_trace') IS NULL
       OR NOT EXISTS (SELECT 1 FROM histgis.lambeaux_1860_trace) THEN
        RAISE EXCEPTION 'Jouer 102 d''abord : 118 recoupe ses fenêtres [1863,…).';
    END IF;
END $$;

-- L'état de départ : celui d'avant `118`.
DROP TABLE IF EXISTS t118_anr, t118_decret, t118_bois, t118_part, t118_coupe, t118_quartier;
CREATE TEMP TABLE t118_anr AS
SELECT g.atom_id, g.periode, g.geom, g.poly_id, g.pseudo_t, g.source
FROM   atom_geom_anr g
WHERE  NOT EXISTS (SELECT 1 FROM p118_trace t
                   WHERE t.quoi = 'pose' AND t.atom_id = g.atom_id AND t.periode = g.periode)
UNION ALL
SELECT atom_id, periode, geom, poly_id, pseudo_t, source
FROM   p118_trace WHERE quoi = 'origine';
CREATE INDEX ON t118_anr USING gist (geom);
CREATE INDEX ON t118_anr (atom_id);

CREATE TEMP TABLE t118_decret (insee text PRIMARY KEY, decret date, texte text);
INSERT INTO t118_decret VALUES
    ('92012', '1925-04-03', 'bois de Boulogne, décret du 3 avril 1925'),
    ('92051', '1929-04-18', 'bois de Boulogne, décret du 18 avril 1929'),
    ('94018', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94033', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94042', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94052', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94067', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94069', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929'),
    ('94080', '1929-04-18', 'bois de Vincennes, décret du 18 avril 1929');

CREATE TEMP TABLE t118_bois AS
SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom
FROM   iris_paris WHERE nom_iris LIKE 'Bois de %';

CREATE TEMP TABLE t118_part AS
WITH brut AS (
    SELECT a.atom_id, a.insee_geofla::text AS insee, d.decret,
           ST_CollectionExtract(ST_MakeValid(ST_Intersection(g.geom, b.geom)), 3) AS g
    FROM   atom a
    JOIN   t118_decret d ON d.insee = a.insee_geofla::text
    JOIN   t118_anr g ON g.atom_id = a.atom_id AND g.periode @> DATE '1859-06-01'
    CROSS  JOIN t118_bois b
    WHERE  NOT a.fraction
)
SELECT b.atom_id, b.insee, b.decret,
       (SELECT ST_Multi(ST_Union(x.geom)) FROM ST_Dump(b.g) x
         WHERE ST_Area(x.geom) >= 10000) AS geom
FROM   brut b;
DELETE FROM t118_part WHERE geom IS NULL OR ST_IsEmpty(geom);

DO $$
DECLARE r record;
BEGIN
    -- Deux communes ne se disputent pas le même sol.
    FOR r IN SELECT p.atom_id a, q.atom_id b,
                    ST_Area(ST_Intersection(p.geom, q.geom)) m2
             FROM t118_part p JOIN t118_part q ON p.atom_id < q.atom_id
             WHERE ST_Area(ST_Intersection(p.geom, q.geom)) > 10000
    LOOP
        RAISE EXCEPTION 'parts de % et % se recouvrent (% m²)', r.a, r.b, round(r.m2);
    END LOOP;
    -- Aucune autre commune survivante n'a de sol dans les bois en 1859.
    FOR r IN SELECT a.atom_id, a.insee_geofla,
                    ST_Area(ST_Intersection(g.geom, b.geom)) m2
             FROM t118_anr g JOIN atom a USING (atom_id) CROSS JOIN t118_bois b
             WHERE g.periode @> DATE '1859-06-01'
               AND NOT a.fraction
               AND a.insee_geofla::text NOT IN (SELECT insee FROM t118_decret)
               AND EXISTS (SELECT 1 FROM t118_anr s WHERE s.atom_id = a.atom_id
                                                     AND s.periode @> DATE '1900-06-01')
               AND ST_Intersects(g.geom, b.geom)
               AND ST_Area(ST_Intersection(g.geom, b.geom)) > 10000
    LOOP
        RAISE EXCEPTION 'commune survivante hors liste dans les bois : % (%), % m²',
                        r.atom_id, r.insee_geofla, round(r.m2);
    END LOOP;
END $$;

-- Les fenêtres des communes, coupées en 1863 et au décret.
CREATE TEMP TABLE t118_coupe AS
WITH r AS (
    SELECT g.*, p.geom AS g_part, p.decret
    FROM   t118_anr g JOIN t118_part p USING (atom_id)
    WHERE  g.periode && daterange('1863-01-01', p.decret, '[)')
)
SELECT atom_id, periode * daterange(NULL, '1863-01-01', '[)') AS periode,
       geom, poly_id, pseudo_t, source
FROM r WHERE lower(periode) < DATE '1863-01-01'
UNION ALL
SELECT atom_id, periode * daterange('1863-01-01', decret, '[)'),
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(geom, g_part)), 3)),
       poly_id, pseudo_t, source || '+bois_118'
FROM r
UNION ALL
SELECT atom_id, periode * daterange(decret, NULL, '[)'),
       geom, poly_id, pseudo_t, source
FROM r WHERE upper(periode) IS NULL OR upper(periode) > decret;

-- Les quartiers de Paris, privés des parts tant qu'elles ne sont pas annexées.
CREATE TEMP TABLE t118_quartier AS
WITH q AS (
    SELECT a.atom_id, ag.geom
    FROM   atom a JOIN atom_geom ag USING (atom_id)
    WHERE  a.atom_id ~ '^PQ[0-9]{2}$'
      AND  EXISTS (SELECT 1 FROM t118_part p
                    WHERE ST_Intersects(p.geom, ag.geom)
                      AND ST_Area(ST_Intersection(p.geom, ag.geom)) > 10000)
), t AS (
    SELECT DATE '1863-01-01' AS debut, DATE '1925-04-03' AS fin
    UNION ALL SELECT DATE '1925-04-03', DATE '1929-04-18'
), d AS (
    SELECT q.atom_id, daterange(t.debut, t.fin, '[)') AS periode, q.geom,
           ST_CollectionExtract(ST_MakeValid(ST_Difference(q.geom,
               (SELECT ST_UnaryUnion(ST_Collect(p.geom)) FROM t118_part p
                 WHERE p.decret > t.debut))), 3) AS g
    FROM q CROSS JOIN t
)
SELECT atom_id, periode, ST_Multi(g) AS geom, atom_id AS poly_id,
       false AS pseudo_t, 'iris-bois_118' AS source
FROM   d
WHERE  ST_Area(geom) - ST_Area(g) > 10000;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM t118_anr g JOIN t118_quartier q USING (atom_id)
                WHERE g.periode && q.periode) THEN
        RAISE EXCEPTION 'un quartier a déjà une fenêtre ANR sur 1863-1929 : à instruire';
    END IF;
END $$;

\echo ''
\echo '=== 1. Les parts rendues aux communes ==='
SELECT p.atom_id, p.insee, coalesce(n.nom, '?') AS nom, p.decret,
       round((ST_Area(p.geom) / 1e4)::numeric, 1) AS ha,
       ST_NumGeometries(p.geom) AS morceaux
FROM   t118_part p LEFT JOIN noms_geofla n ON n.insee = p.insee
ORDER  BY p.decret, ST_Area(p.geom) DESC;
SELECT round((sum(ST_Area(geom)) / 1e6)::numeric, 2) AS km2_rendus,
       round((ST_Area((SELECT geom FROM t118_bois)) / 1e6)::numeric, 2) AS km2_iris_bois
FROM   t118_part;
-- Attendu : Boulogne ~555 ha, Neuilly ~280 ; Vincennes, Saint-Maurice,
-- Fontenay ~200 chacune, Nogent ~140, Saint-Mandé ~110, Charenton ~85 ;
-- Joinville absente. ~18,1 km² sur 18,86 : le reste est intra-muros.

\echo ''
\echo '=== 2. Les fenêtres des communes ==='
SELECT atom_id, periode, source, round((ST_Area(geom) / 1e4)::numeric, 1) AS ha
FROM   t118_coupe ORDER BY atom_id, lower(periode);

\echo ''
\echo '=== 3. Les quartiers de Paris ==='
SELECT q.atom_id, q.periode, round((ST_Area(ag.geom) / 1e4)::numeric, 1) AS ha_iris,
       round((ST_Area(q.geom) / 1e4)::numeric, 1) AS ha_pose
FROM   t118_quartier q JOIN atom_geom ag USING (atom_id)
ORDER  BY q.atom_id, lower(q.periode);

\if :{?appliquer}

DELETE FROM atom_geom_anr g
 USING p118_trace t
 WHERE t.quoi = 'pose' AND t.atom_id = g.atom_id AND t.periode = g.periode;
INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT atom_id, periode, geom, poly_id, pseudo_t, source
FROM   p118_trace WHERE quoi = 'origine';
TRUNCATE p118_trace;

INSERT INTO p118_trace (quoi, atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT DISTINCT 'origine', g.atom_id, g.periode, g.geom, g.poly_id, g.pseudo_t, g.source
FROM   atom_geom_anr g
JOIN   t118_part p USING (atom_id)
WHERE  g.periode && daterange('1863-01-01', p.decret, '[)');

DELETE FROM atom_geom_anr g
 USING p118_trace t
 WHERE t.quoi = 'origine' AND t.atom_id = g.atom_id AND t.periode = g.periode;

INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT atom_id, periode, geom::geometry(MultiPolygon, 2154), poly_id, pseudo_t, source
FROM   t118_coupe
UNION ALL
SELECT atom_id, periode, geom::geometry(MultiPolygon, 2154), poly_id, pseudo_t, source
FROM   t118_quartier;

INSERT INTO p118_trace (quoi, atom_id, periode)
SELECT 'pose', atom_id, periode FROM t118_coupe
UNION ALL
SELECT 'pose', atom_id, periode FROM t118_quartier;

ANALYZE atom_geom_anr;

\echo ''
\echo '=== 4. Posé ==='
SELECT quoi, count(*) FROM p118_trace GROUP BY quoi;

\echo ''
\echo '=== 5. Recette : la carte de la Seine avant, entre et après les décrets ==='
CREATE TEMP TABLE t118_recette AS
SELECT d, c.atom_id, c.geom
FROM   unnest(ARRAY[DATE '1900-06-01', DATE '1927-06-01', DATE '1930-06-01']) d
CROSS  JOIN LATERAL carte_partition_atome(d, '75') c
WHERE  c.dedans;
SELECT d,
       round((sum(ST_Area(geom)) FILTER (WHERE atom_id LIKE 'PQ%') / 1e6)::numeric, 2)      AS km2_paris,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 2)                                         AS km2_seine,
       round((sum(ST_Area(ST_Intersection(geom, (SELECT geom FROM t118_bois))))
              FILTER (WHERE atom_id NOT LIKE 'PQ%') / 1e6)::numeric, 2)                       AS km2_bois_hors_paris
FROM   t118_recette GROUP BY d ORDER BY d;
-- `PQ%` et non `^PQnn$` : les fractions de quartier (PQ42#V-NE…) vivent à
-- certaines dates et pas à d'autres, et les oublier fait varier Paris de
-- plusieurs km² sans rapport avec les bois.
-- Attendu : Paris ~87,3 / ~92,9 / ~105,4 km² ; la Seine inchangée (479,64) ;
-- bois hors de Paris ~18,1 / ~12,6 / 0.

SELECT r.atom_id,
       round((max(ST_Area(r.geom)) FILTER (WHERE r.d = '1900-06-01') / 1e4)::numeric, 1) AS ha_1900,
       round((max(ST_Area(r.geom)) FILTER (WHERE r.d = '1927-06-01') / 1e4)::numeric, 1) AS ha_1927,
       round((max(ST_Area(r.geom)) FILTER (WHERE r.d = '1930-06-01') / 1e4)::numeric, 1) AS ha_1930
FROM   t118_recette r
WHERE  r.atom_id IN (SELECT atom_id FROM t118_part UNION SELECT atom_id FROM t118_quartier)
GROUP  BY r.atom_id ORDER BY r.atom_id;

\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte'

\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

\endif

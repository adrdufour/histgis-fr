-- ============================================================================
-- histgis — 102_seine_lambeaux_1860_1862.sql : ce que Paris prend en 1860 aux
--                                               communes qui SURVIVENT
--
--   psql -d histgis -f sql/102_seine_lambeaux_1860_1862.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/102_seine_lambeaux_1860_1862.sql
--
-- LE TROU
-- =======
-- `101` a prolongé les onze annexées jusqu'à la fin de la division 1857-1863.
-- Reste, mesuré sur l'export du 3 octobre 2026 à 17 h 09, un trou de 1860 à
-- 1862 qui n'est pas une annexée :
--
--     ~8,1 km²  le bois de Boulogne      Boulogne jusqu'en 1859, Paris ensuite
--     ~1,6 km²  les Ternes, Porte Maillot  Neuilly jusqu'en 1859, Paris ensuite
--
-- La loi de 1859 ne supprime pas seulement onze communes : elle prend aussi
-- un lambeau à treize voisines. ANR le retire de leur polygone en 1860 et le
-- donne au Paris agrandi (atome 26207), qui ne se dessine pas : Paris reste
-- les 48 quartiers de Vasserot jusqu'à la division de 1863.
--
-- CE QUE CE FICHIER FAIT
-- ======================
-- Même règle que `101` : de 1860 à 1862, le lambeau reste à la commune qui le
-- portait en 1859, donc dans SA circonscription de 1857.
--
--   lambeau(A) = polygone ANR de A au 1859-06-01
--                − ∪ polygones ANR de tous les atomes VIVANTS sur [1860,1863)
--                  (A compris, et les annexées prolongées par `101`)
--
-- Seuls comptent les atomes rattachés à une unité de la Seine sur
-- [1860,1863) — la règle ne doit rien combler hors du département — et les
-- morceaux d'au moins 1 ha. Chaque fenêtre ANR de A qui chevauche
-- [1860,1863) est COUPÉE : la part dans [1860,1863) reçoit le lambeau, le
-- reste garde le polygone d'ANR intact.
--
-- CE QUI EST UNE HYPOTHÈSE
-- ========================
-- La planche 1857-1863 nomme les annexées ; elle ne dit rien des lambeaux.
-- Les laisser voter avec leur ancienne commune jusqu'en 1863 est l'analogie
-- avec les annexées, pas une lecture. La source est marquée
-- `anr+lambeau_102` pour qu'on la retrouve.
--
-- Réversible et rejouable : `lambeaux_1860_trace` garde les fenêtres d'origine
-- et les fenêtres posées. Place dans la chaîne : après `101`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.annexees_1859_trace') IS NULL
       OR NOT EXISTS (SELECT 1 FROM histgis.annexees_1859_trace) THEN
        RAISE EXCEPTION E'Jouer 101 d''abord : les annexées doivent être prolongées\n'
            '  pour que leur sol ne soit pas pris pour un lambeau.';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS lambeaux_1860_trace (
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

-- Le calcul part de l'état d'ANR : les fenêtres posées sont remplacées, pour
-- ce calcul, par leurs fenêtres d'origine.
DROP TABLE IF EXISTS t102_anr, t102_viv, t102_lamb, t102_coupe;
CREATE TEMP TABLE t102_anr AS
SELECT g.atom_id, g.periode, g.geom, g.poly_id, g.pseudo_t, g.source
FROM   atom_geom_anr g
WHERE  NOT EXISTS (SELECT 1 FROM lambeaux_1860_trace t
                   WHERE t.quoi = 'pose' AND t.atom_id = g.atom_id AND t.periode = g.periode)
UNION ALL
SELECT atom_id, periode, geom, poly_id, pseudo_t, source
FROM   lambeaux_1860_trace WHERE quoi = 'origine';
CREATE INDEX ON t102_anr USING gist (geom);
CREATE INDEX ON t102_anr (atom_id);

-- Les atomes vivants dans la Seine sur [1860,1863).
CREATE TEMP TABLE t102_viv AS
SELECT DISTINCT m.atom_id
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
WHERE  u.dep = '75'
  AND  m.periode && daterange('1860-01-01', '1863-01-01', '[)');

CREATE TEMP TABLE t102_lamb AS
WITH pre AS (
    SELECT a.atom_id, a.geom
    FROM   t102_anr a JOIN t102_viv v USING (atom_id)
    WHERE  a.periode @> DATE '1859-06-01'
), brut AS (
    SELECT p.atom_id,
           ST_CollectionExtract(ST_MakeValid(ST_Difference(p.geom, coalesce(
               (SELECT ST_Union(o.geom) FROM t102_anr o JOIN t102_viv v USING (atom_id)
                WHERE o.periode && daterange('1860-01-01', '1863-01-01', '[)')
                  AND ST_Intersects(o.geom, p.geom)),
               ST_SetSRID('POLYGON EMPTY'::geometry, 2154)))), 3) AS g
    FROM   pre p
)
SELECT b.atom_id,
       (SELECT ST_Multi(ST_Union(d.geom)) FROM ST_Dump(b.g) d
         WHERE ST_Area(d.geom) >= 10000) AS geom
FROM   brut b;
DELETE FROM t102_lamb WHERE geom IS NULL OR ST_IsEmpty(geom);

-- Les fenêtres coupées : avant 1860, [1860,1863) avec lambeau, après 1863.
CREATE TEMP TABLE t102_coupe AS
WITH r AS (
    SELECT a.*, l.geom AS g_lamb
    FROM   t102_anr a JOIN t102_lamb l USING (atom_id)
    WHERE  a.periode && daterange('1860-01-01', '1863-01-01', '[)')
)
SELECT atom_id, periode * daterange(NULL, '1860-01-01', '[)') AS periode,
       geom, poly_id, pseudo_t, source
FROM r WHERE lower(periode) < DATE '1860-01-01'
UNION ALL
SELECT atom_id, periode * daterange('1860-01-01', '1863-01-01', '[)'),
       ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(geom, g_lamb)), 3)),
       poly_id, pseudo_t, 'anr+lambeau_102'
FROM r
UNION ALL
SELECT atom_id, periode * daterange('1863-01-01', NULL, '[)'),
       geom, poly_id, pseudo_t, source
FROM r WHERE upper(periode) IS NULL OR upper(periode) > DATE '1863-01-01';

\echo ''
\echo '=== 1. Les lambeaux ==='
SELECT l.atom_id, a.insee_geofla, coalesce(n.nom, '?') AS nom,
       round((ST_Area(l.geom) / 1e4)::numeric, 1) AS ha,
       ST_NumGeometries(l.geom) AS morceaux,
       ST_AsText(ST_Transform(ST_PointOnSurface(l.geom), 4326), 4) AS point
FROM   t102_lamb l
JOIN   atom a ON a.atom_id = l.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
ORDER  BY ST_Area(l.geom) DESC;
-- Attendu : Boulogne-Billancourt ~800 ha (le bois), Neuilly-sur-Seine
-- ~150 ha (les Ternes), et au plus quelques petits lambeaux d'autres
-- communes limitrophes. Rien hors de la Seine.

\echo ''
\echo '=== 2. Les fenêtres ANR coupées ==='
SELECT atom_id, periode, source, round((ST_Area(geom) / 1e4)::numeric, 1) AS ha
FROM   t102_coupe ORDER BY atom_id, lower(periode);

\echo ''
\echo '=== 3. Recouvrement des fenêtres à lambeau avec les vivants, au 1861-06-01 ==='
SELECT c.atom_id,
       round((coalesce(sum(ST_Area(ST_Intersection(c.geom, o.geom))), 0) / 1e4)::numeric, 3) AS ha_recouvert
FROM   t102_coupe c
JOIN   t102_anr o ON o.atom_id <> c.atom_id AND o.periode @> DATE '1861-06-01'
                 AND o.atom_id IN (SELECT atom_id FROM t102_viv)
                 AND ST_Intersects(c.geom, o.geom)
WHERE  c.periode @> DATE '1861-06-01'
GROUP  BY c.atom_id;
-- Attendu : ≈ 0 partout.

\if :{?appliquer}

-- Défaire le passage précédent.
DELETE FROM atom_geom_anr g
 USING lambeaux_1860_trace t
 WHERE t.quoi = 'pose' AND t.atom_id = g.atom_id AND t.periode = g.periode;
INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT atom_id, periode, geom, poly_id, pseudo_t, source
FROM   lambeaux_1860_trace WHERE quoi = 'origine';
TRUNCATE lambeaux_1860_trace;

-- Garder les fenêtres d'origine, les retirer, poser les coupées.
INSERT INTO lambeaux_1860_trace (quoi, atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT DISTINCT 'origine', g.atom_id, g.periode, g.geom, g.poly_id, g.pseudo_t, g.source
FROM   atom_geom_anr g
JOIN   t102_lamb l USING (atom_id)
WHERE  g.periode && daterange('1860-01-01', '1863-01-01', '[)');

DELETE FROM atom_geom_anr g
 USING lambeaux_1860_trace t
 WHERE t.quoi = 'origine' AND t.atom_id = g.atom_id AND t.periode = g.periode;

INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
SELECT atom_id, periode, geom::geometry(MultiPolygon, 2154), poly_id, pseudo_t, source
FROM   t102_coupe;
INSERT INTO lambeaux_1860_trace (quoi, atom_id, periode)
SELECT 'pose', atom_id, periode FROM t102_coupe;

ANALYZE atom_geom_anr;

\echo ''
\echo '=== 4. Posé ==='
SELECT quoi, count(*) FROM lambeaux_1860_trace GROUP BY quoi;

\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte'

\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

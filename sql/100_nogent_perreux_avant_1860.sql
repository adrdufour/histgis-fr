-- ============================================================================
-- histgis — 100_nogent_perreux_avant_1860.sql : le sol du Perreux rendu à Nogent
--
--   psql -d histgis -f sql/100_nogent_perreux_avant_1860.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/100_nogent_perreux_avant_1860.sql
--
-- LE TROU
-- =======
-- Trouvé le 6 septembre 2026 (JOURNAL, « Les 3,81 km² manquants ») et resté
-- ouvert depuis : de 1815 à 1859, la Seine a un trou à l'est, là où naîtra
-- Le Perreux. Dans ANR :
--
--     Nogent-sur-Marne  1860_0_…    [1790,1860)  4,19 km²
--                       1887_0_…    [1860,1887)  6,76 km²   (Le Perreux compris)
--     Le Perreux        COMMUNE_…   [1887,2020)  3,96 km²
--
-- Le Perreux est un écart de Nogent jusqu'à sa création le 23 mai 1887. ANR le
-- sait après 1860 et l'oublie avant : interrogé à 1848, le point rend
-- PERSONNE. Mesuré le 3 octobre 2026 sur l'export web du 24 septembre (grille
-- de 0,0005°) : ~3,9 km² sans propriétaire à TOUTES les dates 1815-1859, rien
-- à partir de 1860.
--
-- CE QUE CE FICHIER FAIT
-- ======================
-- Il agrandit le polygone ANR de Nogent sur [1790,1860) du sol que Nogent
-- possède en [1860,1887) et que PERSONNE ne revendique sur [1790,1860) :
--
--     comblement = Nogent[1860,1887) − Nogent[1790,1860)
--                  − ∪ polygones ANR de tout autre atome, de tout département,
--                      dont la fenêtre chevauche [1790,1860)
--
-- La soustraction porte sur la FENÊTRE et non sur une date : un sol qu'un
-- voisin revendique ne serait-ce qu'un an n'est pas pris. Ne sont gardés que
-- les morceaux d'au moins 1 ha qui touchent Nogent ; les éclats sont listés,
-- pas posés.
--
-- Aucune frontière n'est inventée : chaque arête du comblement est soit une
-- arête de Nogent 1860, soit une arête d'un voisin. Aucun rattachement n'est
-- touché — Nogent est déjà dans S1815@sud, S1820@8, S1831@13, S1852@9,
-- S1857@10 par `91` ; le sol suit l'atome.
--
-- CE QU'IL NE FAIT PAS
-- ====================
-- * Il ne touche pas Le Perreux, dont la vie en base avant 1887 (repli GEOFLA à
--   partir de 1870, superposé à Nogent : `sorties/anr/carte_couture_repli_1870.csv`)
--   est une autre question.
-- * Il ne règle pas le bois de Boulogne (1,86 km² sans propriétaire avant
--   1860) : ce n'est pas un trou d'ANR mais l'écart entre le Paris d'ANR et
--   celui de Vasserot.
-- * Le signalement à l'équipe ANR reste à faire (RESTE_A_FAIRE § 5).
--
-- Réversible : `nogent_perreux_trace` garde le polygone ANR d'origine ; le
-- fichier commence par le restaurer, il est donc rejouable. Pour défaire :
--   UPDATE histgis.atom_geom_anr g SET geom = t.geom_avant, source = t.source_avant
--     FROM histgis.nogent_perreux_trace t
--    WHERE t.atom_id = g.atom_id AND t.periode = g.periode;
--   TRUNCATE histgis.nogent_perreux_trace;
--
-- Place dans la chaîne : après `82` (et `89`), avant `84`/`99` et l'export.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION E'atom_geom_anr absente.\n  psql -d histgis -1 -f sql/82_anr_geom.sql';
    END IF;
END $$;

-- La trace existe dès le passage à blanc (vide) : c'est elle qui permet de
-- recalculer depuis l'ANR d'origine même après une application.
CREATE TABLE IF NOT EXISTS nogent_perreux_trace (
    atom_id      text        NOT NULL,
    periode      daterange   NOT NULL,
    geom_avant   geometry(MultiPolygon, 2154) NOT NULL,
    source_avant text        NOT NULL,
    ha_comble    numeric,
    pose_le      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (atom_id, periode)
);

-- ---------------------------------------------------------------------------
-- § 1. Nogent, avant et après 1860
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t100_nogent, t100_av, t100_ap, t100_autres, t100_trou, t100_neuf;

CREATE TEMP TABLE t100_nogent AS
SELECT a.atom_id FROM atom a WHERE a.cassini = '25098' AND NOT a.fraction;

CREATE TEMP TABLE t100_av AS
SELECT g.atom_id, g.periode,
       coalesce(t.geom_avant, g.geom)   AS geom,       -- l'ANR d'origine
       coalesce(t.source_avant, g.source) AS source
FROM   atom_geom_anr g
JOIN   t100_nogent n USING (atom_id)
LEFT   JOIN nogent_perreux_trace t ON t.atom_id = g.atom_id AND t.periode = g.periode
WHERE  g.periode @> DATE '1848-06-01';

CREATE TEMP TABLE t100_ap AS
SELECT g.atom_id, g.periode, g.geom
FROM   atom_geom_anr g
JOIN   t100_av av ON av.atom_id = g.atom_id
WHERE  lower(g.periode) = upper(av.periode);

DO $$
DECLARE n int; p daterange;
BEGIN
    SELECT count(*) INTO n FROM t100_nogent;
    IF n <> 1 THEN
        RAISE EXCEPTION '% atome(s) non-fraction de Cassini 25098 (Nogent-sur-Marne) ; 1 attendu.', n;
    END IF;
    SELECT count(*), (array_agg(periode))[1] INTO n, p FROM t100_av;
    IF n <> 1 OR p <> daterange('1790-01-01', '1860-01-01', '[)') THEN
        RAISE EXCEPTION 'Nogent à 1848 : % polygone(s), fenêtre % ; attendu 1, [1790-01-01,1860-01-01).', n, p;
    END IF;
    SELECT count(*), (array_agg(periode))[1] INTO n, p FROM t100_ap;
    IF n <> 1 OR p <> daterange('1860-01-01', '1887-01-01', '[)') THEN
        RAISE EXCEPTION 'Nogent après 1860 : % polygone(s), fenêtre % ; attendu 1, [1860-01-01,1887-01-01).', n, p;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 2. Le comblement : le sol de Nogent 1860 que personne ne tient avant
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t100_autres AS
SELECT ST_Union(g.geom) AS geom, count(*) AS n, string_agg(DISTINCT g.atom_id, ', ') AS qui
FROM   atom_geom_anr g, t100_av av, t100_ap ap
WHERE  g.atom_id <> av.atom_id
  AND  g.periode && av.periode
  AND  ST_Intersects(g.geom, ap.geom);

CREATE TEMP TABLE t100_trou AS
WITH d AS (
    SELECT (ST_Dump(ST_CollectionExtract(ST_MakeValid(
               ST_Difference(ST_Difference(ap.geom, av.geom),
                             coalesce(o.geom, ST_SetSRID('POLYGON EMPTY'::geometry, 2154)))), 3))).geom AS g,
           av.geom AS g_nogent
    FROM   t100_ap ap, t100_av av, t100_autres o
)
SELECT g, ST_Area(g) AS m2,
       ST_DWithin(g, g_nogent, 1)                      AS touche_nogent,
       ST_Area(g) >= 10000 AND ST_DWithin(g, g_nogent, 1) AS garde
FROM   d;

CREATE TEMP TABLE t100_neuf AS
SELECT av.atom_id, av.periode,
       ST_Multi(ST_CollectionExtract(ST_MakeValid(
           ST_Union(av.geom, (SELECT ST_Union(g) FROM t100_trou WHERE garde))), 3))::geometry(MultiPolygon, 2154) AS geom
FROM   t100_av av
WHERE  EXISTS (SELECT 1 FROM t100_trou WHERE garde);

\echo ''
\echo '=== 1. Les voisins soustraits (polygones ANR qui chevauchent [1790,1860) et touchent Nogent 1860) ==='
SELECT n AS polygones, qui FROM t100_autres;

\echo ''
\echo '=== 2. Les morceaux du comblement ==='
SELECT round((m2 / 1e4)::numeric, 2) AS ha, touche_nogent, garde,
       ST_AsText(ST_Transform(ST_PointOnSurface(g), 4326), 5) AS point
FROM   t100_trou ORDER BY m2 DESC LIMIT 20;
-- Attendu : UN grand morceau, ~390 ha, garde = t ; le reste en éclats < 1 ha.

\echo ''
\echo '=== 3. Nogent sur [1790,1860), avant et après ==='
SELECT round((ST_Area(av.geom) / 1e4)::numeric, 1)                           AS ha_anr,
       round(((SELECT sum(m2) FROM t100_trou WHERE garde) / 1e4)::numeric, 1) AS ha_comble,
       round((ST_Area(nf.geom) / 1e4)::numeric, 1)                           AS ha_apres,
       round((ST_Area(ap.geom) / 1e4)::numeric, 1)                           AS ha_nogent_1860,
       ST_NumGeometries(nf.geom)                                             AS parties
FROM   t100_av av, t100_ap ap, t100_neuf nf;
-- Attendu : ~419 + ~393 = ~812 ha, en UNE partie. Le neuf dépasse Nogent 1860
-- (676 ha) : avant 1860 ANR donne aussi à Nogent ~136 ha du bois de
-- Vincennes, rendus à Paris ensuite. Ce n'est pas l'objet de ce fichier.

\echo ''
\echo '=== 4. Recouvrement du neuf avec tout autre polygone ANR, à quatre dates ==='
SELECT d::date AS date, count(g.atom_id) AS voisins_touches,
       round((coalesce(sum(ST_Area(ST_Intersection(nf.geom, g.geom))), 0) / 1e4)::numeric, 3) AS ha_recouvert
FROM   unnest(ARRAY['1815-06-01','1830-06-01','1848-06-01','1859-06-01']::date[]) d
CROSS  JOIN t100_neuf nf
LEFT   JOIN atom_geom_anr g ON g.atom_id <> nf.atom_id AND g.periode @> d
                           AND ST_Intersects(g.geom, nf.geom)
GROUP  BY d ORDER BY d;
-- Attendu : ha_recouvert ≈ 0 (les contacts de bord comptent dans voisins_touches).

\echo ''
\echo '=== 5. Un atome vivant à 1848 sans ANR, dessiné par repli sur ce sol ? ==='
SELECT m.atom_id, m.unit_id,
       round((ST_Area(ST_Intersection(ag.geom, tr.g)) / 1e4)::numeric, 2) AS ha
FROM   membership m
JOIN   atom_geom ag ON ag.atom_id = m.atom_id
JOIN   t100_trou tr ON tr.garde AND ST_Intersects(ag.geom, tr.g)
WHERE  m.periode @> DATE '1848-06-01'
  AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                   WHERE g.atom_id = m.atom_id AND g.periode @> DATE '1848-06-01')
  AND  ST_Area(ST_Intersection(ag.geom, tr.g)) > 10000;
-- Attendu : aucune ligne. Une ligne voudrait dire que la carte dessinait déjà
-- quelqu'un là, et le comblement créerait un doublon.

\if :{?appliquer}

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM t100_neuf) THEN
        RAISE EXCEPTION 'Aucun morceau gardé : rien à poser. Voir la recette 2.';
    END IF;
END $$;

-- Restaurer avant de poser : le fichier est rejouable.
UPDATE atom_geom_anr g SET geom = t.geom_avant, source = t.source_avant
FROM   nogent_perreux_trace t
WHERE  t.atom_id = g.atom_id AND t.periode = g.periode;
TRUNCATE nogent_perreux_trace;

INSERT INTO nogent_perreux_trace (atom_id, periode, geom_avant, source_avant, ha_comble)
SELECT g.atom_id, g.periode, g.geom, g.source,
       round(((SELECT sum(m2) FROM t100_trou WHERE garde) / 1e4)::numeric, 2)
FROM   atom_geom_anr g
JOIN   t100_neuf n ON n.atom_id = g.atom_id AND n.periode = g.periode;

UPDATE atom_geom_anr g SET geom = n.geom, source = 'anr+comble_100'
FROM   t100_neuf n
WHERE  n.atom_id = g.atom_id AND n.periode = g.periode;

ANALYZE atom_geom_anr;

\echo ''
\echo '=== 6. Posé : le point du Perreux, à qui est-il ? ==='
SELECT d::date AS date, coalesce(string_agg(g.atom_id || ' (' || g.source || ')', ', '), 'PERSONNE') AS proprietaire
FROM   unnest(ARRAY['1815-06-01','1848-06-01','1859-06-01','1865-06-01']::date[]) d
LEFT   JOIN atom_geom_anr g
       ON g.periode @> d
      AND ST_Intersects(g.geom, ST_Transform(ST_SetSRID(ST_MakePoint(2.4934, 48.8436), 4326), 2154))
GROUP  BY d ORDER BY d;
-- Attendu : Nogent (anr+comble_100) de 1815 à 1859, Nogent (anr) en 1865.

\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte   (puis vérifier 1817, 1840, 1855 sur la carte)'

\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

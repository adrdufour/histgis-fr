-- ============================================================================
-- histgis — 101_seine_annexees_1859_1862.sql : l'anneau de 1859-1862
--
--   psql -d histgis -f sql/101_seine_annexees_1859_1862.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/101_seine_annexees_1859_1862.sql
--   puis REJOUER 91 (il borne les rattachements par la vie ANR de l'atome) :
--   psql -d histgis -1 -v appliquer=1 -f sql/91_seine_1815_1870.sql
--
-- LE PROBLÈME
-- ===========
-- Les onze annexées meurent dans ANR au 1er janvier 1859. La loi du 16 juin
-- 1859 prend effet le 1er janvier 1860, et surtout la DIVISION ÉLECTORALE de
-- 1857 court jusqu'en 1863 : Paris y reste les 48 quartiers de Vasserot, et la
-- planche 1857-1863 rattache les annexées aux circos 1, 2 (et 5) de Paris et
-- aux 9e et 10e de banlieue. Résultat mesuré sur l'export du 3 octobre 2026 :
--
--   1859        les annexées n'ont plus de sol ; le comblement de `84` donne
--               le trou à Clichy (26,1 km² au lieu de 4,8) et à Boulogne (28,6
--               au lieu de 6,1) ;
--   1860-1862   un anneau d'une quarantaine de km² entre le mur de Vasserot
--               et la banlieue, sans propriétaire.
--
-- CE QUE CE FICHIER FAIT
-- ======================
-- Il prolonge le sol de chaque annexée jusqu'au 1er janvier 1863 — fin de la
-- division 1857-1863 — par de NOUVELLES fenêtres dans `atom_geom_anr`, sans
-- toucher aux fenêtres d'ANR :
--
--   sol(annexée, F) = dernier polygone ANR de l'annexée
--                     − ∪ polygones ANR des atomes VIVANTS (membership) sur F
--
-- La soustraction rend aux voisins ce qu'ANR leur donne dès 1859-1860 : les
-- lambeaux d'annexées restés hors des fortifications (Clichy, Saint-Ouen,
-- Saint-Denis, Aubervilliers, Pantin, Bagnolet, Montreuil, Saint-Mandé,
-- Charenton, Ivry, Gentilly, Montrouge, Vanves, Issy, Boulogne…). Le Paris
-- agrandi d'ANR (atome 26207) n'est soustrait que s'il est vivant — il ne
-- l'est pas : Paris se dessine par les quartiers de Vasserot jusqu'en 1863.
-- Les fenêtres F se coupent à chaque date où un voisin change de polygone, et
-- seuls les morceaux d'au moins 1 ha sont gardés.
--
-- `91` fait le reste sans modification : il borne chaque rattachement par
-- `max(upper(periode))` de l'atome dans `atom_geom_anr`, qui passe de 1859 à
-- 1863. Rejouer `91` étend donc d'elles-mêmes les rattachements 1857-1863.
--
-- CE QUE C'EST, ET CE QUE CE N'EST PAS
-- ====================================
-- De 1860 à 1862 ces atomes ne sont plus des COMMUNES : ce sont des morceaux
-- de Paris qui votent encore dans la circonscription de 1857. L'atome porte un
-- territoire, pas un statut. Belleville reste nommée et non attribuée
-- (« ligne purement arbitraire » selon l'atlas). Les bois de Boulogne et de
-- Vincennes ne sont pas des annexées : s'ils restent sans propriétaire, le
-- comblement de `84` les donne au voisin de plus long bord, et c'est déclaré.
--
-- Réversible : `annexees_1859_trace`. Rejouable : retire ses fenêtres avant
-- de recalculer. Place dans la chaîne : après `89`, AVANT `91`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION E'atom_geom_anr absente.\n  psql -d histgis -1 -f sql/82_anr_geom.sql';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS annexees_1859_trace (
    atom_id text      NOT NULL,
    periode daterange NOT NULL,
    ha      numeric,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (atom_id, periode)
);

DROP TABLE IF EXISTS t101_ann, t101_base, t101_vois, t101_fen, t101_neuf;

CREATE TEMP TABLE t101_ann (atom_id text PRIMARY KEY, nom text);
INSERT INTO t101_ann VALUES
    ('1960', 'Auteuil'), ('2924', 'Batignolles-Monceau'), ('3564', 'Belleville'),
    ('3719', 'Bercy'), ('8509', 'Charonne'), ('16141', 'Grenelle'),
    ('8165', 'La Chapelle'), ('40600', 'La Villette'), ('23671', 'Montmartre'),
    ('26284', 'Passy'), ('39042', 'Vaugirard');

-- Le dernier polygone ANR de chaque annexée — hors les fenêtres de ce fichier.
CREATE TEMP TABLE t101_base AS
SELECT DISTINCT ON (g.atom_id) g.atom_id, a.nom, g.periode, g.geom, g.poly_id
FROM   atom_geom_anr g
JOIN   t101_ann a USING (atom_id)
WHERE  NOT EXISTS (SELECT 1 FROM annexees_1859_trace t
                   WHERE t.atom_id = g.atom_id AND t.periode = g.periode)
ORDER  BY g.atom_id, upper(g.periode) DESC;

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM t101_base;
    IF n <> 11 THEN
        RAISE EXCEPTION '% annexée(s) pourvue(s) dans atom_geom_anr au lieu de 11. Rejouer 89.', n;
    END IF;
    SELECT count(*) INTO n FROM t101_base WHERE upper(periode) <> DATE '1859-01-01';
    IF n > 0 THEN
        RAISE EXCEPTION '% annexée(s) dont le dernier polygone ne finit pas au 1859-01-01.', n;
    END IF;
END $$;

-- Les voisins : polygones ANR d'atomes VIVANTS sur [1859,1863), qui touchent
-- une annexée. La fenêtre est rognée à [1859,1863).
CREATE TEMP TABLE t101_vois AS
SELECT g.atom_id,
       g.periode * daterange('1859-01-01', '1863-01-01', '[)') AS periode,
       g.geom
FROM   atom_geom_anr g
WHERE  g.periode && daterange('1859-01-01', '1863-01-01', '[)')
  AND  g.atom_id NOT IN (SELECT atom_id FROM t101_ann)
  AND  EXISTS (SELECT 1 FROM membership m
               WHERE m.atom_id = g.atom_id
                 AND m.periode && (g.periode * daterange('1859-01-01', '1863-01-01', '[)')))
  AND  EXISTS (SELECT 1 FROM t101_base b WHERE ST_Intersects(b.geom, g.geom));

-- Les fenêtres : coupées à chaque changement de polygone d'un voisin.
CREATE TEMP TABLE t101_fen AS
WITH b AS (
    SELECT DATE '1859-01-01' AS d UNION SELECT DATE '1863-01-01'
    UNION SELECT lower(periode) FROM t101_vois
    UNION SELECT upper(periode) FROM t101_vois
), o AS (
    SELECT d, lead(d) OVER (ORDER BY d) AS f
    FROM   (SELECT DISTINCT d FROM b
            WHERE d >= DATE '1859-01-01' AND d <= DATE '1863-01-01') x
)
SELECT daterange(d, f, '[)') AS fen FROM o WHERE f IS NOT NULL;

CREATE TEMP TABLE t101_neuf AS
WITH brut AS (
    SELECT b.atom_id, b.nom, f.fen AS periode, b.poly_id, ST_Area(b.geom) AS m2_base,
           ST_CollectionExtract(ST_MakeValid(ST_Difference(b.geom, coalesce(
               (SELECT ST_Union(v.geom) FROM t101_vois v
                WHERE v.periode && f.fen AND ST_Intersects(v.geom, b.geom)),
               ST_SetSRID('POLYGON EMPTY'::geometry, 2154)))), 3) AS g
    FROM   t101_base b CROSS JOIN t101_fen f
)
SELECT br.atom_id, br.nom, br.periode, br.poly_id, br.m2_base,
       (SELECT ST_Multi(ST_Union(d.geom)) FROM ST_Dump(br.g) d
         WHERE ST_Area(d.geom) >= 10000)::geometry(MultiPolygon, 2154) AS geom
FROM   brut br;

\echo ''
\echo '=== 1. Les fenêtres ==='
SELECT fen FROM t101_fen ORDER BY lower(fen);
-- Attendu : quelques fenêtres entre 1859 et 1863, coupées en 1860 au moins.

\echo ''
\echo '=== 2. Le sol prolongé de chaque annexée ==='
SELECT n.nom, lower(n.periode) AS du, upper(n.periode) AS au,
       round((n.m2_base / 1e4)::numeric, 1)                       AS ha_anr_1858,
       round((coalesce(ST_Area(n.geom), 0) / 1e4)::numeric, 1)    AS ha_prolonge,
       round((100 * coalesce(ST_Area(n.geom), 0) / n.m2_base)::numeric, 0) AS pct
FROM   t101_neuf n ORDER BY n.nom, lower(n.periode);
-- Attendu : de 60 à 100 % selon la part de la commune restée hors des
-- fortifications. Un 0 % voudrait dire qu'un voisin vivant (le Paris d'ANR ?)
-- couvre toute l'annexée : voir la recette 3.

\echo ''
\echo '=== 3. Les voisins soustraits, et le Paris d ANR ==='
SELECT v.atom_id, a.insee_geofla, v.periode,
       round((sum(ST_Area(ST_Intersection(v.geom, b.geom))) / 1e4)::numeric, 1) AS ha_pris
FROM   t101_vois v
JOIN   atom a ON a.atom_id = v.atom_id
JOIN   t101_base b ON ST_Intersects(v.geom, b.geom)
GROUP  BY v.atom_id, a.insee_geofla, v.periode
HAVING sum(ST_Area(ST_Intersection(v.geom, b.geom))) > 10000
ORDER  BY ha_pris DESC;
-- Attendu : les communes limitrophes, quelques dizaines d'ha chacune. PAS
-- l'atome 26207 (Paris), qui n'est pas vivant.
SELECT count(*) AS rattachements_de_26207_sur_1859_1863
FROM   membership WHERE atom_id = '26207'
  AND  periode && daterange('1859-01-01', '1863-01-01', '[)');
-- Attendu : 0.

\echo ''
\echo '=== 4. Recouvrement avec les voisins vivants, à trois dates ==='
SELECT d::date AS date,
       round((coalesce(sum(ST_Area(ST_Intersection(n.geom, v.geom))), 0) / 1e4)::numeric, 3) AS ha_recouvert
FROM   unnest(ARRAY['1859-06-01', '1860-06-01', '1862-06-01']::date[]) d
JOIN   t101_neuf n ON n.periode @> d AND n.geom IS NOT NULL
LEFT   JOIN t101_vois v ON v.periode @> d AND ST_Intersects(n.geom, v.geom)
GROUP  BY d ORDER BY d;
-- Attendu : ≈ 0.

\if :{?appliquer}

DELETE FROM atom_geom_anr g
 WHERE EXISTS (SELECT 1 FROM annexees_1859_trace t
                WHERE t.atom_id = g.atom_id AND t.periode = g.periode);
TRUNCATE annexees_1859_trace;

WITH ins AS (
    INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t, source)
    SELECT atom_id, periode, geom, poly_id, false, 'anr+prolonge_101'
    FROM   t101_neuf WHERE geom IS NOT NULL
    RETURNING atom_id, periode, geom
)
INSERT INTO annexees_1859_trace (atom_id, periode, ha)
SELECT atom_id, periode, round((ST_Area(geom) / 1e4)::numeric, 2) FROM ins;

ANALYZE atom_geom_anr;

\echo ''
\echo '=== 5. Posé ==='
SELECT count(*) AS fenetres, count(DISTINCT atom_id) AS annexees,
       round(sum(ha) FILTER (WHERE periode @> DATE '1861-06-01'), 1) AS ha_a_1861
FROM   annexees_1859_trace;
-- Attendu : 11 annexées.

\echo ''
\echo 'Ensuite : psql -d histgis -1 -v appliquer=1 -f sql/91_seine_1815_1870.sql'
\echo '          python3 cartes/export_web.py 75 --partition --role histgis_carte'

\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

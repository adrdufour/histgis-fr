-- ============================================================================
-- histgis — 32_marseille_geom.sql : donner aux cantons de Marseille
--                                   leur vraie géométrie (1870-1940)
--
--   ogr2ogr -f PostgreSQL PG:dbname=histgis gaudillere/marseille_cantons.gpkg \
--           -nln histgis.gaud_lignes      -nlt LINESTRING   lignes
--   ogr2ogr -f PostgreSQL PG:dbname=histgis gaudillere/marseille_cantons.gpkg \
--           -nln histgis.gaud_etiquettes  -nlt POINT        etiquettes
--   psql -d histgis -1 -f 32_marseille_geom.sql
--
-- Le problème
-- -----------
-- Les douze atomes-fractions `21387#1313` … `21387#1324` portent TOUS le même
-- polygone : la ville entière, 235,22 km². Le territoire est donc compté
-- autant de fois qu'il y a de cantons — 1 176 km² en trop en 1870, 2 587 en
-- 1940. Marseille est le premier poste du double comptage de `12`.
--
-- Pourquoi il n'y a pas besoin d'un atome par période
-- ---------------------------------------------------
-- Les cantons marseillais changent d'emprise deux fois : lois du 13 juillet
-- 1886 et du 19 juin 1901, que la base date au 1er janvier de leur année.
-- `atom_geom` n'a pas de dimension temporelle : on pourrait croire qu'il faut
-- un atome par canton ET par configuration.
--
-- C'est inutile, parce que l'architecture découple déjà géométrie et
-- attribution. Les divisions de 1886 et 1901 étant CUMULATIVES — elles
-- ajoutent des lignes sans en effacer —, leur superposition est la division la
-- plus fine, celle de 1901 : douze cellules. Chaque cellule a une géométrie
-- fixe pour toute la série, et un rattachement qui change en 1886 et en 1901.
-- C'est exactement ce que `membership` sait porter.
--
-- Les douze cellules sont donc les douze atomes existants. Ce qui change :
--   - leur géométrie, qui cesse d'être la ville entière ;
--   - leurs rattachements de 1870-1886 et 1886-1901, qui doivent être
--     RECALCULÉS. La cellule qui est le 1er canton en 1901 relevait d'un autre
--     canton en 1870, et la base dit aujourd'hui le contraire.
--
-- Ce dernier point réécrit des rattachements venus de TRF-GIS. C'est assumé :
-- ils sont un artefact de l'incapacité de la source à représenter des
-- fractions géométriquement, pas une information sur le terrain. Tout est
-- tracé dans `marseille_trace` et réversible.
--
-- Si la cumulativité ne tient pas — une ligne de 1901 qui ignore une ligne de
-- 1870 —, le découpage produit simplement plus de douze cellules et le § 3
-- l'arrête. La méthode reste juste, il faut alors créer les atomes manquants.
--
-- Prérequis : base chargée 1870-1940, couches `gaud_lignes` et
--             `gaud_etiquettes` importées (EPSG:2154).
-- ÉCRIT. À lancer avec `psql -1`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set commune   '21387'
\set d1870     '1870-01-01'
\set d1886     '1886-01-01'
\set d1901     '1901-01-01'
\set d1941     '1941-01-01'

\echo ''
\echo '============================================================'
\echo ' MARSEILLE — géométries cantonales 1870-1940'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Préflight : les couches livrées sont-elles exploitables ?
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 0. Préflight ==='

DO $$
DECLARE n int; s int;
BEGIN
  IF to_regclass('histgis.gaud_lignes') IS NULL
     OR to_regclass('histgis.gaud_etiquettes') IS NULL THEN
    RAISE EXCEPTION 'Couches absentes. Importer le GeoPackage avec ogr2ogr (voir en-tête).';
  END IF;

  SELECT count(*) INTO n FROM gaud_lignes;
  IF n = 0 THEN RAISE EXCEPTION 'gaud_lignes est vide.'; END IF;

  SELECT count(*) INTO n FROM gaud_etiquettes;
  IF n <> 12 THEN
    RAISE EXCEPTION 'gaud_etiquettes : % points, 12 attendus (un par cellule de 1901).', n;
  END IF;

  SELECT DISTINCT ST_SRID(geom) INTO s FROM gaud_lignes;
  IF s <> 2154 THEN RAISE EXCEPTION 'gaud_lignes en SRID %, 2154 attendu.', s; END IF;

  SELECT DISTINCT ST_SRID(geom) INTO s FROM gaud_etiquettes;
  IF s <> 2154 THEN RAISE EXCEPTION 'gaud_etiquettes en SRID %, 2154 attendu.', s; END IF;

  -- les trois colonnes d'étiquetage doivent être remplies partout
  SELECT count(*) INTO n FROM gaud_etiquettes
   WHERE u1870 IS NULL OR u1886 IS NULL OR u1901 IS NULL;
  IF n > 0 THEN
    RAISE EXCEPTION '% étiquettes incomplètes : chaque cellule relève d''un canton dans CHACUNE des trois configurations.', n;
  END IF;
END $$;

\echo '    couches présentes, 12 étiquettes complètes, EPSG:2154.'

-- ---------------------------------------------------------------------------
-- 1. Découper la commune par les lignes
-- ---------------------------------------------------------------------------
-- On ne dessine pas les cantons, on découpe la commune. Le contour extérieur
-- reste celui de GEOFLA, exact ; seules les lignes internes portent
-- l'imprécision de l'atlas. Et l'union des cellules vaut la commune par
-- construction : ni écharde, ni trou, rien à nettoyer.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Découpage ==='

DROP TABLE IF EXISTS mars_cellule;
CREATE TABLE mars_cellule AS
WITH ville AS (
    SELECT geom FROM atom_geom WHERE atom_id = :'commune'
), blades AS (
    SELECT ST_Boundary(geom) AS g FROM ville
    UNION ALL
    SELECT ST_Collect(geom) FROM gaud_lignes
), morceaux AS (
    SELECT (ST_Dump(ST_Polygonize(ST_Node(ST_Collect(g))))).geom AS geom
    FROM   blades
)
SELECT row_number() OVER (ORDER BY ST_Area(m.geom) DESC) AS cellule_id,
       ST_Multi(ST_CollectionExtract(
           ST_Intersection(m.geom, v.geom), 3)) AS geom
FROM   morceaux m CROSS JOIN ville v
-- les lignes débordent volontairement du contour : on ne garde que l'intérieur
WHERE  ST_Contains(v.geom, ST_PointOnSurface(m.geom));

CREATE INDEX mars_cellule_gix ON mars_cellule USING gist (geom);

SELECT count(*) AS cellules,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 2) AS km2_total,
       round((min(ST_Area(geom)) / 1e6)::numeric, 3) AS km2_min,
       round((max(ST_Area(geom)) / 1e6)::numeric, 2) AS km2_max
FROM   mars_cellule;

-- ---------------------------------------------------------------------------
-- 2. Attribuer chaque cellule à ses trois cantons
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Étiquetage ==='

DROP TABLE IF EXISTS mars_rat;
CREATE TABLE mars_rat AS
SELECT c.cellule_id, c.geom,
       e.u1870, e.u1886, e.u1901,
       :'commune' || '#' || e.u1901 AS atom_id
FROM   mars_cellule c
JOIN   gaud_etiquettes e ON ST_Contains(c.geom, e.geom);

SELECT count(*) AS cellules_etiquetees,
       count(DISTINCT u1870) AS cantons_1870,
       count(DISTINCT u1886) AS cantons_1886,
       count(DISTINCT u1901) AS cantons_1901
FROM   mars_rat;

-- ---------------------------------------------------------------------------
-- 3. Les assertions qui arrêtent la transaction
-- ---------------------------------------------------------------------------
-- Chacune énonce une propriété que le dessin doit avoir, pas un motif qu'il
-- pourrait avoir. Si l'une casse, rien n'est écrit.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Assertions ==='

DO $$
DECLARE n int; a1 double precision; a2 double precision;
BEGIN
  -- 3a. une cellule, une étiquette, et pas de cellule orpheline
  SELECT count(*) INTO n FROM mars_cellule c
   WHERE NOT EXISTS (SELECT 1 FROM mars_rat r WHERE r.cellule_id = c.cellule_id);
  IF n > 0 THEN
    RAISE EXCEPTION '% cellule(s) sans étiquette : le découpage produit des morceaux non prévus, ou un point d''étiquette tombe hors de sa cellule.', n;
  END IF;

  SELECT count(*) INTO n FROM (
      SELECT cellule_id FROM mars_rat GROUP BY 1 HAVING count(*) > 1) t;
  IF n > 0 THEN
    RAISE EXCEPTION '% cellule(s) portent plusieurs étiquettes.', n;
  END IF;

  -- 3b. le compte de cantons par configuration, que l'atlas ET la base donnent
  SELECT count(DISTINCT u1870) INTO n FROM mars_rat;
  IF n <> 6  THEN RAISE EXCEPTION '1870 : % cantons distincts, 6 attendus.', n;  END IF;
  SELECT count(DISTINCT u1886) INTO n FROM mars_rat;
  IF n <> 8  THEN RAISE EXCEPTION '1886 : % cantons distincts, 8 attendus.', n;  END IF;
  SELECT count(DISTINCT u1901) INTO n FROM mars_rat;
  IF n <> 12 THEN RAISE EXCEPTION '1901 : % cantons distincts, 12 attendus.', n; END IF;

  -- 3c. cumulativité : une cellule de 1901 ne peut pas chevaucher deux cantons
  --     de 1886, sinon la division de 1901 n'est pas un raffinement et douze
  --     cellules ne suffisent pas.
  SELECT count(*) INTO n FROM (
      SELECT u1901 FROM mars_rat GROUP BY u1901
      HAVING count(DISTINCT u1886) > 1 OR count(DISTINCT u1870) > 1) t;
  IF n > 0 THEN
    RAISE EXCEPTION '% canton(s) de 1901 relèvent de plusieurs cantons antérieurs : les divisions ne sont pas cumulatives, il faut découper plus fin.', n;
  END IF;

  -- 3d. les unit_id étiquetés existent-ils bien dans la base ?
  SELECT count(*) INTO n FROM (
      SELECT u1870 AS u FROM mars_rat UNION
      SELECT u1886 FROM mars_rat UNION
      SELECT u1901 FROM mars_rat) t
   WHERE NOT EXISTS (SELECT 1 FROM unit u
                      WHERE u.unit_id = t.u AND u.niveau = 'canton');
  IF n > 0 THEN
    RAISE EXCEPTION '% unit_id étiqueté(s) inconnu(s) de la table unit.', n;
  END IF;

  -- 3e. les douze atomes visés existent
  SELECT count(*) INTO n FROM mars_rat r
   WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = r.atom_id);
  IF n > 0 THEN
    RAISE EXCEPTION '% atome(s) cible(s) absent(s) de la table atom.', n;
  END IF;

  -- 3f. l'union des cellules vaut la commune, au mètre carré près
  SELECT sum(ST_Area(geom)) INTO a1 FROM mars_cellule;
  SELECT ST_Area(geom)      INTO a2 FROM atom_geom WHERE atom_id = '21387';
  IF abs(a1 - a2) > 1.0 THEN
    RAISE EXCEPTION 'Union des cellules % m², commune % m² : écart de % m².',
                    round(a1::numeric), round(a2::numeric), round(abs(a1-a2)::numeric);
  END IF;
END $$;

\echo '    six assertions franchies.'

-- ---------------------------------------------------------------------------
-- 4. La trace, avant d'écrire
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Trace ==='

DROP TABLE IF EXISTS marseille_trace;
CREATE TABLE marseille_trace (
    quoi    text,
    cle     text,
    avant   text,
    apres   text,
    pose_le timestamptz DEFAULT now()
);

-- l'ancienne géométrie partagée, et les anciens rattachements
INSERT INTO marseille_trace (quoi, cle, avant, apres)
SELECT 'atom_geom', ag.atom_id,
       ag.source || ' ' || round((ST_Area(ag.geom)/1e6)::numeric, 2) || ' km2',
       'gaudillere ' || round((ST_Area(r.geom)/1e6)::numeric, 2) || ' km2'
FROM   atom_geom ag JOIN mars_rat r ON r.atom_id = ag.atom_id;

INSERT INTO marseille_trace (quoi, cle, avant, apres)
SELECT 'membership', m.membership_id::text,
       m.atom_id || ' -> ' || m.unit_id || ' [' || m.valid_from || ',' || m.valid_to || ')',
       'supprime'
FROM   membership m
WHERE  m.niveau = 'canton' AND m.atom_id LIKE :'commune' || '#%';

-- ---------------------------------------------------------------------------
-- 5. Écrire
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Application ==='

-- 5a. les géométries : la ville entière cède la place à la cellule
UPDATE atom_geom ag
SET    geom     = r.geom,
       source   = 'gaudillere',
       partagee = false
FROM   mars_rat r
WHERE  ag.atom_id = r.atom_id;

-- 5b. les rattachements : on efface les anciens, artefacts du polygone unique
DELETE FROM membership
WHERE  niveau = 'canton' AND atom_id LIKE :'commune' || '#%';

-- 5c. et on repose les trois configurations depuis les étiquettes
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, u1870, 'canton', :'d1870'::date, :'d1886'::date FROM mars_rat
    UNION ALL
    SELECT atom_id, u1886, 'canton', :'d1886'::date, :'d1901'::date FROM mars_rat
    UNION ALL
    SELECT atom_id, u1901, 'canton', :'d1901'::date, :'d1941'::date FROM mars_rat
    RETURNING membership_id
)
INSERT INTO marseille_trace (quoi, cle, apres)
SELECT 'membership', membership_id::text, 'pose' FROM ins;

ANALYZE atom_geom; ANALYZE membership;

SELECT quoi, apres, count(*) FROM marseille_trace GROUP BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 6. Recette — le double comptage a-t-il disparu ? ==='
\echo '    Avant : 1 176 km² en trop en 1870, 1 647 en 1900, 2 587 en 1940.'
\echo '    Attendu maintenant : 0,00 aux trois dates.'

SELECT d::date AS date,
       count(DISTINCT m.atom_id) AS fractions,
       count(DISTINCT m.unit_id) AS cantons,
       round((sum(DISTINCT ST_Area(ag.geom)) / 1e6)::numeric, 2) AS km2_somme,
       round((ST_Area((SELECT geom FROM atom_geom WHERE atom_id = '21387'))
              / 1e6)::numeric, 2) AS km2_ville
FROM   (VALUES ('1870-06-01'), ('1900-06-01'), ('1940-06-01')) AS t(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla = '13055'
JOIN   atom_geom ag ON ag.atom_id = a.atom_id
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '=== 7. Recette — les cantons dissous se recomposent-ils toujours ? ==='
\echo '    Chaque canton doit rester d''un seul tenant : un canton en deux'
\echo '    morceaux disjoints signale une étiquette posée dans la mauvaise'
\echo '    cellule.'
SELECT d::date AS date, m.unit_id,
       coalesce(uv.nom, u.nom) AS nom,
       count(*) AS cellules,
       ST_NumGeometries(ST_Multi(ST_UnaryUnion(ST_Collect(ag.geom)))) AS morceaux,
       round((ST_Area(ST_Union(ag.geom)) / 1e6)::numeric, 2) AS km2
FROM   (VALUES ('1870-06-01'), ('1900-06-01'), ('1940-06-01')) AS t(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla = '13055'
JOIN   atom_geom ag ON ag.atom_id = a.atom_id
JOIN   unit u ON u.unit_id = m.unit_id
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> d::date
GROUP  BY 1, 2, 3 ORDER BY 1, 2;

\echo ''
\echo '=== À lancer ensuite ==='
\echo '    12_conflit_successeur.sql — le double comptage national doit'
\echo '        baisser de ~1 176 km² à 1870 et ~2 587 km² à 1940.'
\echo '    controle_gay.sh — le seul juge externe : ces cantons tombent-ils'
\echo '        où Gay les met ? Si l''IoU se dégrade, le dessin est en cause,'
\echo '        pas le contrôle.'
\echo ''
\echo 'Tables : mars_cellule, mars_rat, marseille_trace.'
\echo 'Rollback : marseille_trace porte l''état antérieur de chaque objet.'

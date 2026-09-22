-- ============================================================================
-- histgis — 89_seine_annexees_1860.sql : les onze communes que Paris a mangées
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour le \copy
--   psql -d histgis -f sql/89_seine_annexees_1860.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/89_seine_annexees_1860.sql
--
-- POURQUOI CE FICHIER EXISTE
-- ==========================
-- Avant 1860 le département de la Seine compte onze communes de plus que la
-- base n'en connaît : Auteuil, Batignolles-Monceau, Belleville, Bercy,
-- Charonne, Grenelle, La Chapelle, La Villette, Montmartre, Passy et
-- Vaugirard. La loi du 16 juin 1859 les supprime au profit de Paris.
--
-- Elles forment une couronne continue entre le Paris de Vasserot et la
-- banlieue. **Sans elles, aucune date d'avant 1860 ne peut être complète** :
-- il resterait un anneau vide de quarante kilomètres carrés autour du centre.
--
-- CE QU'IL POSE, ET RIEN DE PLUS
-- ===============================
-- Onze atomes et leur géométrie ANR. **Aucun rattachement** : ce fichier ne
-- dit pas à quelle circonscription elles appartenaient, seulement qu'elles
-- existaient et où. L'attribution est le travail de `90` et de ses suites.
--
-- L'IDENTIFIANT N'EST PAS INVENTÉ
-- ================================
-- `82` a établi que **`id_com` d'ANR EST l'identifiant Cassini**, la clé que
-- `atom.cassini` porte depuis le premier chargement. Les onze atomes prennent
-- donc leur `atom_id` de leur Cassini, comme toute commune ordinaire de la
-- base. Aucun des onze n'existe déjà — TRF-GIS commence en 1870 et elles sont
-- mortes en 1860 — et la recette 2 le vérifie plutôt que de le supposer.
--
-- `insee_geofla` reste NULL : elles n'ont pas de code INSEE, n'ayant jamais
-- existé sous ce système. `com_act = 3`, la valeur que TRF-GIS réserve aux
-- communes anciennes d'avant 1943.
--
-- CE QUE LA SOURCE DONNE, MESURÉ HORS BASE
-- =========================================
-- Douze fenêtres pour onze communes, sans une variante et sans un
-- recouvrement (`circo/seine_annexees_1860.csv`) :
--
--     Auteuil, Belleville, Bercy, Charonne, La Chapelle, La Villette,
--     Montmartre, Passy .................... [1790, 1859)
--     Batignolles-Monceau, Grenelle ........ [1830, 1859)   créées en 1830
--     Vaugirard ............................ [1790, 1830) puis [1830, 1859)
--
-- Batignolles-Monceau naît de Clichy et Grenelle de Vaugirard, toutes deux en
-- 1830 — ce qui explique la double fenêtre de Vaugirard, et pourquoi la Seine
-- compte 79 communes en 1815 et 81 en 1830. *ANR est cohérent avec lui-même
-- sur ce point, et personne ne le lui avait demandé.*
--
-- L'ÉCART D'UN AN, DÉCLARÉ
-- =========================
-- ANR ferme les onze en **1859**. La loi est du 16 juin 1859 et prend effet le
-- **1er janvier 1860**. Une année les sépare, pendant laquelle ANR donne déjà
-- à Paris sa forme agrandie (`1860_0A/0B/0C`, fenêtre [1859, 1860)).
--
-- Ce fichier suit ANR, parce que la géométrie est ce qu'il pose : une vie qui
-- courrait jusqu'en 1860 aurait une année sans polygone, et
-- `carte_partition_atome` ne dessinerait rien. **Toute division posée plus
-- tard sur 1852-1859 devra donc se fermer au 1er janvier 1859**, et le dire.
--
-- Réversible : `seine_annexees_trace`, section 5.
-- Prérequis : la table de transit `anr_commune` chargée (voir `sql/JOUER_82.md`).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION E'Table histgis.anr_commune absente.\n'
            '  Recharger la couche geometries_only_processed du GeoPackage ANR\n'
            '  avec ogr2ogr — la commande exacte est dans sql/JOUER_82.md.';
    END IF;
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION E'atom_geom_anr absente.\n'
            '  psql -d histgis -1 -f sql/82_anr_geom.sql';
    END IF;
END $$;

DROP TABLE IF EXISTS sa_src;
CREATE TEMP TABLE sa_src (
    cassini  integer PRIMARY KEY,
    nom      text,
    debut    int,
    fin      int,
    fenetres text
);
\copy sa_src FROM 'circo/seine_annexees_1860.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- 1. Ce que la source donne, confronté à la table de transit
--
-- La colonne `fenetres` du CSV est une LECTURE, faite hors base sur le
-- GeoPackage. `anr_commune` est la même donnée passée par ogr2ogr. Les deux
-- doivent dire la même chose ; si elles divergent, c'est la lecture qui a
-- tort et il faut la refaire, pas la contourner.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sa_poly;
CREATE TEMP TABLE sa_poly AS
WITH brut AS (
    SELECT an.id_com::text                              AS id_com,
           an.poly_id,
           (nullif(an.startdt::text, ''))::numeric::int AS an_debut,
           (nullif(an.enddt::text,   ''))::numeric::int AS an_fin,
           coalesce(an.pseudo_t::boolean, false)        AS pseudo_t,
           ST_Multi(an.geom)                            AS geom
    FROM   anr_commune an
    JOIN   sa_src s ON s.cassini::text = an.id_com::text
    WHERE  an.geom IS NOT NULL
), bornes AS (
    SELECT * FROM brut
    WHERE  an_debut IS NOT NULL AND an_fin IS NOT NULL AND an_fin > an_debut
), arbitre AS (
    SELECT b.* FROM bornes b
    LEFT   JOIN anr_variante v ON v.poly_id = b.poly_id
    WHERE  v.poly_id IS NULL OR v.verdict = 'retenu'
)
SELECT DISTINCT ON (poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin) *
  FROM arbitre
 ORDER BY poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin;
-- Les trois règles sont celles de `82` — R1 fenêtre semi-ouverte non vide,
-- R3 variantes arbitrées, R2 doublons exacts. Recopiées et non appelées :
-- `82` les écrit dans un `INSERT`, pas dans une fonction. *Une règle recopiée
-- est une dette ; elle est déclarée ici plutôt que dissimulée.*

\echo ''
\echo '=== 1. Les onze communes, et ce qu ANR en dit ==='
SELECT s.nom, s.cassini,
       count(p.poly_id)                       AS fenetres_en_base,
       min(p.an_debut)                        AS debut,
       max(p.an_fin)                          AS fin,
       round((sum(ST_Area(p.geom)) / 1e6)::numeric, 2) AS km2_cumules,
       bool_or(p.pseudo_t)                    AS pseudo
  FROM sa_src s LEFT JOIN sa_poly p ON p.id_com = s.cassini::text
 GROUP BY s.nom, s.cassini ORDER BY s.nom;
-- Attendu : 1 fenêtre chacune sauf Vaugirard qui en a 2 ; aucun pseudo.

\echo ''
\echo '=== 2. Garde-fou : aucun de ces atomes n existe deja ==='
SELECT s.nom, s.cassini, a.atom_id, a.insee_geofla
  FROM sa_src s JOIN atom a ON a.atom_id = s.cassini::text OR a.cassini = s.cassini::text
 ORDER BY 1;
-- Attendu : aucune ligne. Une ligne voudrait dire que la base connaît déjà la
-- commune sous un autre nom, et ce fichier la dédoublerait.

\echo ''
\echo '=== 3. Garde-fou : la lecture hors base et la table de transit ==='
SELECT s.nom, s.debut AS lu_debut, min(p.an_debut) AS base_debut,
       s.fin AS lu_fin, max(p.an_fin) AS base_fin
  FROM sa_src s LEFT JOIN sa_poly p ON p.id_com = s.cassini::text
 GROUP BY s.nom, s.debut, s.fin
HAVING s.debut IS DISTINCT FROM min(p.an_debut)
    OR s.fin   IS DISTINCT FROM max(p.an_fin)
 ORDER BY 1;
-- Attendu : aucune ligne.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS seine_annexees_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- Retirer sa trace AVANT de juger de ce qui reste — la leçon de `55`. L'ordre
-- compte : la géométrie référence l'atome, elle part la première.
DELETE FROM atom_geom_anr g
 WHERE EXISTS (SELECT 1 FROM seine_annexees_trace t
                WHERE t.quoi = 'geom' AND t.cle = g.atom_id || '|' || g.periode::text);
DELETE FROM atom a
 WHERE EXISTS (SELECT 1 FROM seine_annexees_trace t
                WHERE t.quoi = 'atom' AND t.cle = a.atom_id);
TRUNCATE seine_annexees_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n
      FROM sa_src s JOIN atom a
        ON a.atom_id = s.cassini::text OR a.cassini = s.cassini::text;
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) existent deja pour ces communes. Ce '
            'fichier CREE, il ne remplace pas. Voir la recette 2.', n;
    END IF;

    SELECT count(*) INTO n FROM sa_src s
     WHERE NOT EXISTS (SELECT 1 FROM sa_poly p WHERE p.id_com = s.cassini::text);
    IF n > 0 THEN
        RAISE EXCEPTION '% commune(s) sans aucun polygone dans anr_commune. '
            'Un atome sans geometrie ne se dessine nulle part. Voir la '
            'recette 1.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT s.cassini::text, s.cassini::text, false, 3, NULL FROM sa_src s
    RETURNING atom_id
)
INSERT INTO seine_annexees_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

WITH ins AS (
    INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t)
    SELECT p.id_com,
           daterange(make_date(p.an_debut, 1, 1), make_date(p.an_fin, 1, 1), '[)'),
           p.geom, p.poly_id, p.pseudo_t
      FROM sa_poly p
    RETURNING atom_id, periode
)
INSERT INTO seine_annexees_trace (quoi, cle)
SELECT 'geom', atom_id || '|' || periode::text FROM ins;

ANALYZE atom;
ANALYZE atom_geom_anr;

\echo ''
\echo '=== 4. Pose ==='
SELECT quoi, count(*) FROM seine_annexees_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 11 atomes, 12 geometries.

\echo ''
\echo '=== 5. Recette : la couronne se referme-t-elle ? ==='
-- Le test qui décide. À 1848 la Seine doit être pavée par 81 communes —
-- 69 de la banlieue actuelle, les 11 d'ici, et Paris. Ici on ne mesure que
-- les 80 non parisiennes : leur union doit valoir 441,56 km², chiffre mesuré
-- hors base sur le GeoPackage, et leur recouvrement mutuel doit être nul.
-- Le lot des 80 ne se déduit pas d'un préfixe de code INSEE : `92|93|94`
-- ramasserait les communes venues de Seine-et-Oise en 1968, qui n'ont jamais
-- été dans la Seine. Il se lit dans la planche cantonale de 1954, comme dans
-- `88` — les atomes que la Seine rattache à l'un de ses cantons — augmentée
-- des onze d'ici.
WITH lot AS (
    SELECT cassini::text AS atom_id FROM sa_src
    UNION
    SELECT DISTINCT m.atom_id
      FROM membership m
      JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton' AND u.dep = '75'
     WHERE m.niveau = 'canton' AND m.periode @> DATE '1954-06-01'
), a1848 AS (
    SELECT g.atom_id, g.geom
      FROM atom_geom_anr g
      JOIN lot l ON l.atom_id = g.atom_id
     WHERE g.periode @> DATE '1848-06-01'
)
SELECT count(*)                                             AS communes,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 2)   AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                            AS recouvrement_km2
  FROM a1848;
-- Attendu : 80 communes, 441,56 km2, recouvrement 0,001 km2.
-- Un ecart sur le nombre voudrait dire qu'une commune de Seine-et-Oise s'est
-- glissee dans le filtre `92|93|94` ; sur l'union, que la variante retenue
-- n'est pas celle mesuree hors base.

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

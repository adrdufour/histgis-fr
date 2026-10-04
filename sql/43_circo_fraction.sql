-- ============================================================================
-- 43_circo_fraction.sql — rendre leur circonscription aux atomes-fractions
--
--   psql -d histgis -f sql/43_circo_fraction.sql
--
-- Le défaut, trouvé le 20 août 2026 par Biarritz
-- ----------------------------------------------
-- Adrien, sur la carte : « je vois des communes disparaître entre 1987 et
-- 2000 ». De 1987 à 1999 la couche cantonale n'existe pas — c'est le trou
-- 1941-1998 — et seule la couche des circonscriptions alimente l'affichage.
-- Une commune sans circonscription y est donc invisible.
--
-- Mesuré sur les Basses-Pyrénées : **quatre polygones** ne sont couverts par
-- aucun atome rattaché — Biarritz, Anglet, Lacq et Nay. Pau, pourtant coupée
-- elle aussi, s'affiche normalement.
--
-- La différence tient à l'ORIGINE des atomes-fractions. `24_canton_moderne.sql`
-- en compte 998 : **266 héritées de TRF-GIS** pour 1870-1940, que le même code
-- de canton fait retrouver, et **732 créées par lui**. Pau repose sur des
-- fractions héritées, Biarritz sur des fractions créées.
--
-- Or `24` a été reconstruit le 17 août : il a supprimé ses 732 atomes, et la
-- suppression a **cascadé sur `membership`**, emportant les rattachements de
-- circonscription que `27` et `28` avaient posés dessus. `24` a bien recréé les
-- atomes ; rien n'a recréé les circonscriptions.
--
-- Mesure qui tranche : sur la période 1986-2010, 36 353 rattachements de
-- circonscription, dont **261 seulement sur des fractions** — les héritées. Les
-- 732 autres en ont zéro.
--
-- Ce n'est donc pas un défaut du chargeur : c'est une dépendance de chaîne non
-- écrite, la même qui a fait échouer `24` le 17 août. Elle est désormais dans
-- `sql/README.md`.
--
-- Pourquoi ce fichier plutôt qu'un rejeu de 27 et 28
-- --------------------------------------------------
-- `27` et `28` sont rejouables : ils retirent leur passage par leur trace. Mais
-- ils retirent aussi **leurs unités**, et depuis leur premier passage `15`,
-- `41` et `42` ont posé des rattachements qui les référencent. La clé étrangère
-- `membership_unit_fk` refuserait, exactement comme pour `24`.
--
-- Il faudrait donc défaire trois fichiers, rejouer les deux couches, puis les
-- refaire. Beaucoup de mouvement pour reposer ce qui manque. Ce fichier ne crée
-- **aucune unité, aucun atome, aucune géométrie** : il repose uniquement les
-- rattachements absents, par la même résolution que `27` et `28`.
--
-- La règle
-- --------
--   « Une ligne source dont l'atome résolu n'a AUCUNE circonscription sur la
--     période de sa couche reçoit celle que la source lui donne. »
--
-- Aucune interprétation : c'est la requête de `27` et `28`, restreinte à ce qui
-- manque. Si un atome a déjà une circonscription sur la période, on ne touche à
-- rien — ce fichier ne corrige pas une attribution, il comble une absence.
--
-- Trois garde-fous
-- ----------------
--   1. Les tables source `circo86_src` et `circo_src`, laissées en base par
--      `28` et `27`, doivent exister. Sans elles on ne sait rien.
--   2. L'unité visée doit exister. On ne crée aucune circonscription : si elle
--      manque, c'est que la couche n'a pas été chargée, et il faut la charger.
--   3. Rien n'est posé sur un atome qui a déjà une circonscription sur la
--      période, ni sur une période déjà occupée.
--
-- Réversible : `circo_fraction_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set d86_debut '1986-11-24'
-- Bascule alignée sur `27`, `28` et `40_outremer` : 10 juin 2012. Voir
-- l'en-tête de `28_circo_1986.sql`. Corrigé le 20 août 2026.
\set d86_fin   '2012-06-10'
\set d09_debut '2012-06-10'
\set d09_fin   '2013-01-01'
-- Même date de référence que `27` et `28` pour lire la structure cantonale :
-- c'est elle qui a servi à découper les atomes-fractions.
\set date_canton '2012-06-01'

DO $$
BEGIN
    IF to_regclass('histgis.circo86_src') IS NULL
    OR to_regclass('histgis.circo_src')   IS NULL THEN
        RAISE EXCEPTION 'circo86_src ou circo_src absente : jouer 28 et 27 avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS circo_fraction_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    couche        text NOT NULL,      -- '1986' ou '2009'
    insee         char(5),
    canton_source text,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_fraction_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE circo_fraction_trace;

-- ---------------------------------------------------------------------------
-- 1. Résolution, identique à celle de 27 et 28
--
-- `DISTINCT ON (canton, insee, circo)` avec préférence à l'atome dont le canton
-- CONCORDE avec celui de la ligne source : c'est ce qui envoie chaque fraction
-- vers la bonne ligne. Pour Biarritz, la ligne du canton 6408 choisit
-- `4174#6408` et celle du canton 6444 choisit `4174#6444`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cf_rat;
CREATE TEMP TABLE cf_rat AS
SELECT '1986' AS couche, s.canton, s.insee, s.circo || '@1986' AS unit_id,
       a.atom_id, :'d86_debut'::date AS d0, :'d86_fin'::date AS d1
  FROM (SELECT DISTINCT ON (s.canton, s.insee, s.circo)
               s.canton, s.insee, s.circo, a.atom_id
          FROM circo86_src s
          JOIN atom a       ON a.insee_geofla = s.insee
          JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                           AND m.periode @> :'date_canton'::date
         WHERE s.niveau = 'commune'
         ORDER BY s.canton, s.insee, s.circo,
                  (m.unit_id = s.canton) DESC, a.atom_id) s
  JOIN atom a ON a.atom_id = s.atom_id
UNION ALL
SELECT '2009', s.canton, s.insee, s.circo || '@2009',
       a.atom_id, :'d09_debut'::date, :'d09_fin'::date
  FROM (SELECT DISTINCT ON (s.canton, s.insee, s.circo)
               s.canton, s.insee, s.circo, a.atom_id
          FROM circo_src s
          JOIN atom a       ON a.insee_geofla = s.insee
          JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                           AND m.periode @> :'date_canton'::date
         WHERE s.niveau = 'commune'
         ORDER BY s.canton, s.insee, s.circo,
                  (m.unit_id = s.canton) DESC, a.atom_id) s
  JOIN atom a ON a.atom_id = s.atom_id;

-- ---------------------------------------------------------------------------
-- 2. Ce qui manque : l'atome n'a AUCUNE circonscription sur la période
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cf_manque;
CREATE TEMP TABLE cf_manque AS
SELECT DISTINCT r.couche, r.atom_id, r.unit_id, r.insee, r.canton, r.d0, r.d1
  FROM cf_rat r
 WHERE NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = r.atom_id AND m.niveau = 'circo'
                      AND m.periode && daterange(r.d0, r.d1, '[)'))
   -- garde-fou 2 : l'unité doit exister, on n'en crée aucune
   AND EXISTS (SELECT 1 FROM unit u
                WHERE u.unit_id = r.unit_id AND u.niveau = 'circo');

-- Un atome ne peut relever que d'une circonscription par couche. Si la source
-- en donne deux, on ne tranche pas : on écarte et on le dit.
DROP TABLE IF EXISTS cf_ambigu;
CREATE TEMP TABLE cf_ambigu AS
SELECT couche, atom_id, count(DISTINCT unit_id) AS n,
       string_agg(DISTINCT unit_id, ' / ') AS unites
  FROM cf_manque GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1;

DELETE FROM cf_manque m USING cf_ambigu a
 WHERE a.couche = m.couche AND a.atom_id = m.atom_id;

\echo ''
\echo '=== 1. Ce qui manque, par couche ==='
SELECT couche, count(*) AS rattachements,
       count(DISTINCT atom_id) AS atomes,
       count(DISTINCT insee)   AS communes
  FROM cf_manque GROUP BY 1 ORDER BY 1;
-- Mesuré le 20 août 2026 avant correctif : 261 rattachements de circo sur
-- fractions pour 998 fractions existantes. Le manque doit être de l'ordre des
-- 732 fractions créées par `24`, par couche.

\echo ''
\echo '--- écartés faute de circonscription unique (rien n''est posé) ---'
SELECT * FROM cf_ambigu ORDER BY couche, atom_id LIMIT 20;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', d0, d1 FROM cf_manque
    RETURNING membership_id, atom_id, unit_id, valid_from
)
INSERT INTO circo_fraction_trace (membership_id, atom_id, unit_id, couche,
                                  insee, canton_source)
SELECT i.membership_id, i.atom_id, i.unit_id, m.couche, m.insee, m.canton
  FROM ins i
  JOIN cf_manque m ON m.atom_id = i.atom_id AND m.unit_id = i.unit_id
                  AND m.d0 = i.valid_from;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Posé ==='
SELECT couche, count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       count(DISTINCT insee) AS communes
  FROM circo_fraction_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Les quatre communes du 64 qui ont révélé le défaut ==='
SELECT a.insee_geofla, coalesce(n.nom, '?') AS commune, a.atom_id,
       m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 43' END AS origine
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'circo'
                   AND m.valid_to > DATE '1986-01-01'
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
  LEFT JOIN circo_fraction_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla IN ('64122', '64024', '64300', '64417')
 ORDER BY a.insee_geofla, a.atom_id, m.valid_from;
-- Attendu : Biarritz 64-06, Anglet 64-05, Lacq 64-03, Nay 64-02, sur leurs
-- deux fractions chacune, pour les deux couches.

\echo ''
\echo '=== 4. Aucun atome dans deux circonscriptions à la même date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0.

\echo ''
\echo '=== 5. Chevauchements (doit valoir 0) ==='
SELECT count(*) AS chevauchements
  FROM membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '=== 6. Polygones sans circonscription au 1er juin 1990 ==='
\echo '    LA recette de ce fichier : c''est ce que la carte montre entre 1987'
\echo '    et 1999, où la couche cantonale n''existe pas. On teste le POLYGONE,'
\echo '    pas l''atome — un polygone porté par plusieurs atomes est couvert dès'
\echo '    que l''un d''eux est rattaché.'
SELECT count(*) AS polygones_sans_circo,
       round(sum(km2)) AS km2
  FROM (SELECT md5(ST_AsEWKB(ag.geom)) AS cle,
               max(ST_Area(ag.geom) / 1e6) AS km2
          FROM atom_geom ag
         GROUP BY 1
        HAVING NOT bool_or(EXISTS (
                   SELECT 1 FROM membership m
                    WHERE m.atom_id = ag.atom_id AND m.niveau = 'circo'
                      AND m.periode @> DATE '1990-06-01'))) x;
-- Attendu : très bas. Les communes légitimement absentes de la couche de 1986
-- (Tende et La Brigue avant 1947 sont hors période ; les communes nées après
-- 1986) doivent seules y figurer.

-- ---------------------------------------------------------------------------
-- 5. Pour défaire
--
--   DELETE FROM membership m USING circo_fraction_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE circo_fraction_trace;
-- ---------------------------------------------------------------------------

-- ============================================================================
-- histgis — 33_diff_cantonal.sql : les mouvements cantonaux 1940→1999,
--                                  calculés et non dictés
--
--   psql -d histgis -v dep=01 -f 33_diff_cantonal.sql
--
-- Le retournement
-- ---------------
-- Le registre `cantons/mouvements_cantonaux.csv` a été conçu pour saisir à la
-- main, département par département, les mouvements cantonaux du trou
-- 1941-1998. L'Ain a montré que c'était inutile : la base porte déjà le
-- rattachement de chaque commune en 1940 (TRF-GIS) et en 1999 (COG), les
-- `unit_id` sont partagés entre les deux couches, et le code Insee fait le
-- pont. **Le différentiel se calcule.**
--
-- Ce qui manque n'est donc pas la liste des mouvements, c'est leur DATE. Le
-- registre devient une table de datation : ce script produit les faits, les
-- cartes de Gaudillère fournissent les bornes.
--
-- Ce que le calcul voit et que la dictée ne voyait pas
-- ---------------------------------------------------
-- 1. Les **transferts** entre deux cantons anciens — une commune qui change de
--    canton sans qu'aucun canton ne naisse ni ne disparaisse. Invisible à la
--    dictée, invisible à la remontée depuis 1999. Cinq cas dans l'Ain.
-- 2. Les **chefs-lieux partagés** : une commune répartie entre plusieurs
--    cantons apparaît sur plusieurs lignes. Bourg-en-Bresse est ainsi éclatée
--    entre trois cantons en 1999, ce que la dictée comptait pour un.
-- 3. La distinction entre **fusion communale** et mouvement cantonal, que le
--    simple comptage des effectifs confondait.
--
-- Ce que le calcul ne voit pas
-- ---------------------------
-- La date, et l'ordre des mouvements. Un canton démembré puis remembré rend le
-- même différentiel qu'un canton immobile. C'est une borne, pas une histoire.
--
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set d40 '1940-06-01'
\set d99 '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' MOUVEMENTS CANTONAUX 1940 → 1999'
\echo '============================================================'

DROP TABLE IF EXISTS dc_c40;
CREATE TEMP TABLE dc_c40 AS
SELECT DISTINCT a.insee_geofla AS insee, m.unit_id AS u
FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
WHERE  m.niveau = 'canton' AND m.periode @> :'d40'::date
  AND  left(a.insee_geofla, 2) = :'dep';

DROP TABLE IF EXISTS dc_c99;
CREATE TEMP TABLE dc_c99 AS
SELECT DISTINCT a.insee_geofla AS insee, m.unit_id AS u
FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
WHERE  m.niveau = 'canton' AND m.periode @> :'d99'::date
  AND  left(a.insee_geofla, 2) = :'dep';

DROP TABLE IF EXISTS dc_diff;
CREATE TEMP TABLE dc_diff AS
SELECT insee,
       coalesce(c40.u, '(absente 1940)') AS c40,
       coalesce(c99.u, '(disparue)')     AS c99
FROM   dc_c40 c40 FULL JOIN dc_c99 c99 USING (insee);

-- Les cantons nés après 1940 : ceux qui n'existaient pas à la date de départ.
DROP TABLE IF EXISTS dc_neuf;
CREATE TEMP TABLE dc_neuf AS
SELECT DISTINCT u FROM dc_c99
WHERE  u NOT IN (SELECT u FROM dc_c40);

-- ---------------------------------------------------------------------------
-- 1. Le décor
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Effectifs ==='
SELECT (SELECT count(DISTINCT u) FROM dc_c40)     AS cantons_1940,
       (SELECT count(DISTINCT u) FROM dc_c99)     AS cantons_1999,
       (SELECT count(*)          FROM dc_neuf)    AS cantons_neufs,
       (SELECT count(DISTINCT insee) FROM dc_c40) AS communes_1940,
       (SELECT count(DISTINCT insee) FROM dc_c99) AS communes_1999;

-- ---------------------------------------------------------------------------
-- 2. Les mouvements, classés
-- ---------------------------------------------------------------------------
-- Trois natures, qui n'appellent pas le même travail :
--   demembrement — vers un canton neuf : la dictée les connaît
--   transfert    — entre deux cantons anciens : elle ne les voit PAS
--   fusion       — la commune disparaît : ce n'est pas un mouvement cantonal
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Les mouvements par nature ==='
DROP TABLE IF EXISTS dc_mvt;
CREATE TEMP TABLE dc_mvt AS
SELECT d.c40, u40.nom AS nom_1940,
       d.c99, u99.nom AS nom_1999,
       CASE WHEN d.c99 = '(disparue)'      THEN 'fusion'
            WHEN d.c40 = '(absente 1940)'  THEN 'creation_commune'
            -- La commune reste dans son canton de 1940 ET relève d'un autre :
            -- elle n'est pas PARTIE, elle est PARTAGÉE. Sans ce test, une
            -- commune éclatée entre n cantons est comptée n-1 fois comme
            -- départ, et la recette du § 6 tombe en négatif.
            WHEN EXISTS (SELECT 1 FROM dc_c99 x
                         WHERE x.insee = d.insee AND x.u = d.c40)
                                           THEN 'partage'
            WHEN d.c99 IN (SELECT u FROM dc_neuf) THEN 'demembrement'
            ELSE 'transfert' END AS nature,
       count(*) AS communes,
       string_agg(d.insee, ' ' ORDER BY d.insee) AS liste
FROM   dc_diff d
LEFT   JOIN unit u40 ON u40.unit_id = d.c40
LEFT   JOIN unit u99 ON u99.unit_id = d.c99
WHERE  d.c40 IS DISTINCT FROM d.c99
GROUP  BY 1, 2, 3, 4, 5;

SELECT nature, count(*) AS lignes, sum(communes) AS communes
FROM   dc_mvt GROUP BY 1 ORDER BY 1;

\echo ''
\echo '--- démembrements : vers un canton créé après 1940 ---'
SELECT c40, nom_1940, c99, nom_1999, communes, left(liste, 60) AS communes_liste
FROM   dc_mvt WHERE nature = 'demembrement' ORDER BY c99, c40;

\echo ''
\echo '--- partages : la commune reste dans son canton ET rejoint un autre ---'
\echo '    Un chef-lieu divisé, pas un mouvement. Compté à part pour que la'
\echo '    recette du § 6 ne le prenne pas pour un départ.'
SELECT c40, nom_1940, c99, nom_1999, communes, liste
FROM   dc_mvt WHERE nature = 'partage' ORDER BY c40, c99;

\echo ''
\echo '=== 3. LES TRANSFERTS — ce que la dictée ne peut pas voir ==='
\echo '    Une commune passée d''un canton ancien à un autre, sans création'
\echo '    ni disparition. Ni la lecture des cartes ni la remontée depuis'
\echo '    1999 ne les révèlent. Chacun doit être daté à part.'
SELECT c40, nom_1940, c99, nom_1999, communes, liste
FROM   dc_mvt WHERE nature = 'transfert' ORDER BY c40, c99;

\echo ''
\echo '=== 4. Communes partagées entre plusieurs cantons en 1999 ==='
\echo '    Un chef-lieu éclaté compte pour autant de lignes qu''il a de'
\echo '    cantons. C''est le cas Marseille-Lyon, à repérer avant de'
\echo '    conclure qu''il manque des événements.'
SELECT c.insee, u.nom AS commune_dans,
       count(*) OVER (PARTITION BY c.insee) AS n_cantons
FROM   dc_c99 c
LEFT   JOIN unit u ON u.unit_id = c.u
WHERE  c.insee IN (SELECT insee FROM dc_c99 GROUP BY insee HAVING count(*) > 1)
ORDER  BY c.insee, u.nom;

\echo ''
\echo '=== 5. Fusions communales — à écarter des mouvements cantonaux ==='
SELECT c40, nom_1940, communes, left(liste, 70) AS communes_liste
FROM   dc_mvt WHERE nature = 'fusion' ORDER BY communes DESC, c40;

-- ---------------------------------------------------------------------------
-- 6. La recette d'équilibre
-- ---------------------------------------------------------------------------
-- Pour chaque canton de 1940 : effectif de départ moins ce qui est parti,
-- plus ce qui est arrivé, doit valoir l'effectif de 1999. Un écart signale
-- un mouvement mal classé ou une commune comptée deux fois.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 6. Recette — les effectifs s''équilibrent-ils ? ==='
-- Ne PAS sommer les lignes de `dc_mvt` : une commune partagée entre plusieurs
-- cantons dès 1940 y produit une ligne par couple, et se compte donc autant de
-- fois qu'elle a de cantons d'origine. Montluçon (03185) relève de deux
-- cantons en 1940 et de cinq en 1999 : elle « arrive » deux fois dans chaque
-- canton neuf.
--
-- On repart des états eux-mêmes, avec la seule définition qui tienne quel que
-- soit le nombre de cantons par commune :
--   partie   = elle était dans ce canton en 1940 et n'y est plus en 1999
--   arrivée  = elle y est en 1999 et n'y était pas en 1940
-- Les communes partagées se traitent alors sans cas particulier, et le
-- classement `partage` de la § 2 n'a plus à intervenir ici.
WITH depart AS (
    SELECT c.u, count(DISTINCT c.insee) AS n
    FROM   dc_c40 c
    WHERE  NOT EXISTS (SELECT 1 FROM dc_c99 x
                       WHERE x.insee = c.insee AND x.u = c.u)
    GROUP  BY c.u
), arrivee AS (
    SELECT c.u, count(DISTINCT c.insee) AS n
    FROM   dc_c99 c
    WHERE  NOT EXISTS (SELECT 1 FROM dc_c40 x
                       WHERE x.insee = c.insee AND x.u = c.u)
    GROUP  BY c.u
), eff AS (
    SELECT u, count(*) AS n40 FROM dc_c40 GROUP BY 1
), eff9 AS (
    SELECT u, count(*) AS n99 FROM dc_c99 GROUP BY 1
)
SELECT coalesce(eff.u, eff9.u) AS canton, un.nom,
       coalesce(eff.n40, 0)      AS n_1940,
       coalesce(depart.n, 0)     AS partis,
       coalesce(arrivee.n, 0)    AS arrives,
       coalesce(eff9.n99, 0)     AS n_1999,
       coalesce(eff.n40,0) - coalesce(depart.n,0)
         + coalesce(arrivee.n,0) - coalesce(eff9.n99,0) AS ecart
FROM   eff FULL JOIN eff9 USING (u)
LEFT   JOIN depart  ON depart.u  = coalesce(eff.u, eff9.u)
LEFT   JOIN arrivee ON arrivee.u = coalesce(eff.u, eff9.u)
LEFT   JOIN unit un ON un.unit_id = coalesce(eff.u, eff9.u)
WHERE  coalesce(eff.n40,0) - coalesce(depart.n,0)
       + coalesce(arrivee.n,0) - coalesce(eff9.n99,0) <> 0
ORDER  BY abs(coalesce(eff.n40,0) - coalesce(depart.n,0)
              + coalesce(arrivee.n,0) - coalesce(eff9.n99,0)) DESC;

\echo ''
\echo '    Aucune ligne = tous les effectifs s''équilibrent.'
\echo ''
\echo '=== Ce qu''il reste à faire pour ce département ==='
\echo '    Les mouvements sont établis. Seules manquent les DATES, que les'
\echo '    cartes de Gaudillère bornent : un mouvement visible sur la carte'
\echo '    de N et absent de la précédente est survenu dans l''intervalle.'

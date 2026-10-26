-- ============================================================================
-- histgis — 30_stabilite_cantonale.sql : la composition cantonale de 1940
--                                        vaut-elle encore en 1986 ?
--
--   psql -d histgis -v dep=13 -f 30_stabilite_cantonale.sql
--
-- L'enjeu
-- -------
-- Le trou cantonal 1941-1998 bloque le découpage législatif de 1958, qui se
-- définit par cantons. Mais Gaudillère, pour les Bouches-du-Rhône, ne signale
-- **qu'une seule modification cantonale de 1815 à 1986** : la création du
-- canton de Port-Saint-Louis en 1945.
--
-- Si c'est vrai, la composition de 1940 — que TRF-GIS nous donne — vaut aussi
-- pour 1986, et le trou se comble pour ce département.
--
-- Le test, sans rien supposer
-- ---------------------------
-- Une circonscription de 1986 est une union de cantons entiers : c'est vérifié
-- (aucun couple canton-commune partagé dans le fichier du ministère, § 4 ter
-- de note_circonscriptions.md). Donc **si les cantons n'ont pas bougé entre
-- 1940 et 1986, toutes les communes d'un canton de 1940 doivent relever de la
-- même circonscription en 1986.**
--
-- Une exception par canton signalé comme divisé par l'atlas est attendue — en
-- Bouches-du-Rhône : Istres et Salon-de-Provence. Toute autre exception
-- infirme la stabilité.
--
-- Ce que le test ne prouve pas
-- ---------------------------
-- Il est nécessaire, pas suffisant. Deux cantons de 1940 fusionnés puis
-- refondus à l'identique dans la même circonscription passeraient au travers.
-- Il écarte les remaniements, pas les réorganisations neutres. C'est une
-- présomption forte, à déclarer comme telle.
--
-- Prérequis : base chargée, 28_circo_1986.sql (table circo86_src).
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set date_1940 '1940-06-01'

\echo ''
\echo '============================================================'
\echo ' STABILITÉ CANTONALE 1940 → 1986'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. La composition cantonale de 1940, vue par commune
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stab_1940;
CREATE TABLE stab_1940 AS
SELECT DISTINCT a.insee_geofla AS insee, m.unit_id AS canton_1940,
       coalesce(uv.nom, u.nom) AS nom_canton
FROM   membership m
JOIN   atom a ON a.atom_id = m.atom_id
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id
                           AND uv.periode @> :'date_1940'::date
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1940'::date
  AND  a.insee_geofla IS NOT NULL
  AND  left(a.insee_geofla, 2) = :'dep';

CREATE INDEX stab_1940_idx ON stab_1940 (insee);

\echo ''
\echo '=== 1. Le département en 1940 ==='
SELECT count(DISTINCT canton_1940) AS cantons_1940,
       count(DISTINCT insee)       AS communes_1940
FROM   stab_1940;

-- ---------------------------------------------------------------------------
-- 2. Croisement avec les circonscriptions de 1986
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS stab_test;
CREATE TABLE stab_test AS
SELECT s.canton_1940, max(s.nom_canton) AS nom_canton,
       count(DISTINCT s.insee)          AS communes,
       count(DISTINCT c.circo)          AS n_circos_1986,
       string_agg(DISTINCT c.circo, ' / ' ORDER BY c.circo) AS circos_1986,
       count(DISTINCT s.insee) FILTER (WHERE c.circo IS NULL) AS sans_circo
FROM   stab_1940 s
LEFT   JOIN circo86_src c ON c.insee = s.insee
GROUP  BY s.canton_1940;

\echo ''
\echo '=== 2. LE TEST — un canton de 1940, combien de circonscriptions ? ==='
\echo '    Si les cantons n''ont pas bougé, chaque canton de 1940 doit tomber'
\echo '    dans UNE seule circonscription de 1986.'
SELECT n_circos_1986, count(*) AS cantons, sum(communes) AS communes
FROM   stab_test GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Les cantons éclatés entre plusieurs circonscriptions ==='
\echo '    Attendu en Bouches-du-Rhône : Istres et Salon-de-Provence, que'
\echo '    l''atlas signale comme divisés. Marseille aussi, ses'
\echo '    circonscriptions se définissant sur les arrondissements.'
\echo '    Toute AUTRE ligne infirme la stabilité.'
SELECT canton_1940, nom_canton, communes, n_circos_1986, circos_1986
FROM   stab_test WHERE n_circos_1986 > 1
ORDER  BY n_circos_1986 DESC, communes DESC;

\echo ''
\echo '=== 4. Cantons dont des communes n''ont aucune circonscription 1986 ==='
\echo '    Communes disparues entre 1940 et 1986, ou absentes du fichier.'
SELECT canton_1940, nom_canton, communes, sans_circo
FROM   stab_test WHERE sans_circo > 0
ORDER  BY sans_circo DESC LIMIT 15;

-- ---------------------------------------------------------------------------
-- 3. Le sens inverse : une circonscription de 1986 est-elle une union de
--    cantons de 1940 ?
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Vue par circonscription de 1986 ==='
SELECT c.circo,
       count(DISTINCT s.canton_1940) AS cantons_1940,
       count(DISTINCT c.insee)       AS communes,
       string_agg(DISTINCT coalesce(s.nom_canton, '(hors 1940)'), ', '
                  ORDER BY coalesce(s.nom_canton, '(hors 1940)')) AS cantons
FROM   circo86_src c
LEFT   JOIN stab_1940 s ON s.insee = c.insee
WHERE  left(c.circo, 2) = :'dep'
GROUP  BY c.circo ORDER BY c.circo;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    § 2 : la quasi-totalité des cantons à 1 circonscription → la'
\echo '        composition de 1940 vaut pour 1986, et le trou se comble pour'
\echo '        ce département.'
\echo '    § 3 ne contenant que les cantons annoncés par l''atlas → confirmé.'
\echo '    Une exception non annoncée → un remaniement cantonal a eu lieu et'
\echo '        l''hypothèse tombe pour ce canton.'
\echo ''
\echo 'Rappel : test NÉCESSAIRE, pas suffisant. Deux cantons fusionnés puis'
\echo 'refondus dans la même circonscription passeraient au travers.'
\echo ''
\echo 'Tables : stab_1940, stab_test.'

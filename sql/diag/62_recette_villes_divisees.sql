-- ============================================================================
-- histgis — 62_recette_villes_divisees.sql : le premier contrôle indépendant
--                                            de la couche 1870-1940
--
--   psql -d histgis -f sql/diag/62_recette_villes_divisees.sql
--
-- LECTURE SEULE.
--
-- POURQUOI CE FICHIER COMPTE PLUS QUE SON VOLUME
-- ==============================================
-- La couche circonscriptions 1870-1940 n'a **aucun contrôle indépendant**. Elle
-- vient entièrement de TRF-GIS, et toutes nos recettes mesurent une COHÉRENCE :
-- la couverture boucle, les unions valent le tout, aucun atome n'est dans deux
-- unités. Aucune ne peut dire si la couche est EXACTE, faute d'un dehors.
--
-- L'affaire de l'Ain a montré ce que cela coûte. Trente cantons sur quarante-
-- trois étaient dans la mauvaise circonscription, et la base était cohérente
-- avec elle-même de bout en bout : zéro chevauchement, zéro atome orphelin,
-- fragmentation normale. **Ce qui l'a révélé est un œil humain sur une carte.**
--
-- L'ANNEXE VI § 6 FOURNIT UN DEHORS
-- =================================
-- « 98 villes dont le territoire a été réparti entre plusieurs
-- circonscriptions », avec une matrice par découpage. Les totaux transcrits
-- dans `circo/annexe_vi.md` :
--
--     découpage   1875   1889   1927
--     villes        19     22     41
--
-- C'est un nombre établi par un tiers, sur la période même qui n'a aucun
-- contrôle. Et il ne demande **aucun appariement** : ni nom de circonscription
-- à faire correspondre à un code, ni composition à confronter ligne à ligne.
-- C'est ce qui en fait le point de départ, avant le § 1 (circonscriptions
-- scindées) qui nomme ses cas et qu'il faudra apparier.
--
-- CE QUE CE CONTRÔLE PEUT DIRE, ET CE QU'IL NE PEUT PAS
-- =====================================================
-- Un ÉCART prouve qu'une des deux sources se trompe, sans dire laquelle.
--
-- Une CONCORDANCE ne prouve pas l'exactitude de la couche : deux erreurs
-- compensées donnent le même total. C'est un contrôle NÉCESSAIRE, pas
-- suffisant — la même réserve que `30_stabilite_cantonale.sql` porte sur
-- lui-même.
--
-- Trois causes d'écart n'engagent NI l'atlas NI la couche, et doivent être
-- écartées avant toute conclusion :
--
--   1. **Le périmètre des exclusions.** Le § 5 exclut explicitement Paris, la
--      petite couronne, Lyon et Marseille. Le § 6 ne le redit pas, et rien ne
--      dit qu'il les exclut aussi. Les deux comptes sont donc produits, avec et
--      sans, et l'on regarde lequel tombe juste — SANS choisir d'avance celui
--      qui arrange.
--   2. **L'année de référence.** Gaudillère date les découpages de 1875, 1889
--      et 1927 ; nos segments s'ouvrent en 1876, 1889 et 1928. Ce sont les
--      mêmes découpages — la loi précède les élections — mais une ville divisée
--      en cours de segment fausserait la comparaison. On échantillonne donc au
--      milieu du segment, pas à son ouverture.
--   3. **La maille.** Une ville divisée est chez nous un atome-fraction
--      `cassini#circo`. Si la géométrisation en a manqué, la ville sort d'un
--      seul tenant et le compte baisse — défaut de NOTRE chaîne, pas de la
--      couche d'attribution.
--
-- Prérequis : base chargée, couche circo 1870-1940.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' RECETTE — VILLES DIVISÉES, ANNEXE VI § 6'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Les attendus, transcrits de l'atlas
--
-- La table entière est écrite, pas seulement les trois valeurs testées : les
-- autres colonnes situent la courbe, et une courbe se lit mieux qu'un point.
-- La division des villes double entre 1889 et 1927, puis double encore en 1986.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r62_attendu;
CREATE TABLE r62_attendu (decoupage_atlas smallint, segment smallint,
                          villes smallint, testable boolean);
INSERT INTO r62_attendu VALUES
  (1815, NULL,  1, false), (1820, NULL,  4, false), (1831, NULL, 12, false),
  (1852, NULL,  9, false), (1857, NULL, 10, false), (1862, NULL, 12, false),
  (1867, NULL, 14, false),
  (1875, 1876, 19, true),  (1889, 1889, 22, true),  (1927, 1928, 41, true),
  (1958, NULL, 43, false), (1986, NULL, 81, false);

\echo ''
\echo '-- 1. la matrice de l''annexe VI § 6'
SELECT decoupage_atlas, segment, villes,
       CASE WHEN testable THEN 'testé ici' ELSE '—' END AS statut
FROM   r62_attendu ORDER BY decoupage_atlas;

-- ---------------------------------------------------------------------------
-- 2. Ce que la couche produit
--
-- Une ville divisée = un `cassini` dont les atomes relèvent de PLUSIEURS
-- circonscriptions à la même date. On groupe par cassini et non par atome :
-- c'est précisément parce que les fractions sont des atomes distincts qu'il
-- faut remonter d'un cran pour retrouver la ville.
--
-- La date d'échantillonnage est au MILIEU du segment (cf. en-tête, cause 2).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r62_ville;
CREATE TABLE r62_ville AS
WITH sonde(segment, d) AS (VALUES
    (1876::smallint, '1878-12-01'::date),
    (1889::smallint, '1893-12-01'::date),
    (1928::smallint, '1930-12-01'::date))
SELECT s.segment,
       a.cassini,
       max(a.insee_geofla)                       AS insee,
       count(DISTINCT m.unit_id)                 AS n_circo,
       string_agg(DISTINCT u.nom, ' | ' ORDER BY u.nom) AS circos,
       max(u.dep)                                AS dep
FROM   sonde s
JOIN   membership m ON m.niveau = 'circo'
                   AND daterange(m.valid_from, m.valid_to, '[)') @> s.d
JOIN   atom a  ON a.atom_id = m.atom_id
JOIN   unit u  ON u.unit_id = m.unit_id AND u.niveau = 'circo'
GROUP  BY s.segment, a.cassini
HAVING count(DISTINCT m.unit_id) > 1;

CREATE INDEX r62_ville_seg_idx ON r62_ville (segment);

-- Les exclusions déclarées au § 5. Paris et la petite couronne se repèrent par
-- le département ; Lyon et Marseille par leur code INSEE.
DROP TABLE IF EXISTS r62_exclu;
CREATE TABLE r62_exclu AS
SELECT segment, cassini FROM r62_ville
WHERE  dep IN ('75', '92', '93', '94')
   OR  insee IN ('69123', '13055')
   OR  cassini LIKE '69123%' OR cassini LIKE '13055%';

-- ---------------------------------------------------------------------------
-- 3. LA CONFRONTATION
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. atlas contre couche, avec et sans les exclusions du § 5'
SELECT a.decoupage_atlas          AS atlas,
       a.segment,
       a.villes                   AS attendu,
       (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment)
                                  AS trouve_tout,
       (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment
          AND NOT EXISTS (SELECT 1 FROM r62_exclu e
                           WHERE e.segment = v.segment AND e.cassini = v.cassini))
                                  AS trouve_hors_exclusions,
       (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment) - a.villes
                                  AS ecart_tout,
       (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment
          AND NOT EXISTS (SELECT 1 FROM r62_exclu e
                           WHERE e.segment = v.segment AND e.cassini = v.cassini))
       - a.villes                 AS ecart_hors
FROM   r62_attendu a
WHERE  a.testable
ORDER  BY a.decoupage_atlas;

\echo ''
\echo '   Lire les DEUX colonnes d''écart. Le § 6 ne dit pas s''il exclut'
\echo '   Paris, Lyon et Marseille comme le fait le § 5 ; c''est la mesure'
\echo '   qui doit le dire, et non le choix de celle qui arrange.'

-- ---------------------------------------------------------------------------
-- 4. Les villes trouvées — nommées, pour que l'écart soit interprétable
--
-- Un compteur d'écart sans les cas n'est pas exploitable : on ne sait pas si
-- l'on a trop de villes ou pas les bonnes.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. les villes divisées, par découpage'
SELECT segment, dep, coalesce(insee, cassini) AS commune, n_circo,
       left(circos, 62) AS circonscriptions
FROM   r62_ville
ORDER  BY segment, dep, commune;

\echo ''
\echo '-- 4 bis. celles qui tombent sous les exclusions du § 5'
SELECT v.segment, v.dep, coalesce(v.insee, v.cassini) AS commune, v.n_circo
FROM   r62_ville v
JOIN   r62_exclu e ON e.segment = v.segment AND e.cassini = v.cassini
ORDER  BY v.segment, v.dep;

-- ---------------------------------------------------------------------------
-- 5. La courbe, qui se lit mieux qu'un point
--
-- L'atlas fait doubler la division des villes entre 1889 et 1927. Si notre
-- couche ne montre pas cette accélération, l'écart n'est pas une question de
-- comptage mais de structure — et il faut chercher ailleurs qu'aux marges.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. la forme de la courbe, atlas contre couche'
SELECT a.decoupage_atlas AS atlas, a.villes AS attendu,
       (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment) AS trouve,
       round(100.0 * (SELECT count(*) FROM r62_ville v WHERE v.segment = a.segment)
             / nullif(a.villes, 0), 0)                                AS pct
FROM   r62_attendu a WHERE a.testable ORDER BY a.decoupage_atlas;

\echo ''
\echo '============================================================'
\echo ' Une concordance ne prouve pas l''exactitude : deux erreurs'
\echo ' compensées donnent le même total. Un écart, lui, prouve'
\echo ' qu''une des deux sources se trompe — sans dire laquelle.'
\echo '============================================================'

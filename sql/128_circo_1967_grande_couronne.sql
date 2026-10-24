-- ============================================================================
-- histgis — 128_circo_1967_grande_couronne.sql : les circonscriptions de la
--           loi du 12 juillet 1966 dans les Yvelines, l'Essonne et le
--           Val-d'Oise
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/128_circo_1967_grande_couronne.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/128_circo_1967_grande_couronne.sql
--   psql -d histgis -1 -v defaire=1 -f sql/128_circo_1967_grande_couronne.sql
--
-- LE TROU
-- =======
-- Le pendant de `125` pour l'autre moitié de la Seine-et-Oise : de 1968 au
-- 24 novembre 1986, les 269 communes des Yvelines, 197 de l'Essonne et 185 du
-- Val-d'Oise n'avaient aucune circonscription.
--
-- LA SOURCE
-- =========
-- Gaudillère, cartes « 1967-1986 » (photos 108, 128 et 133 de
-- `photos/1940_1995/`, lues le 24 octobre 2026). Contrairement à celles de la
-- petite couronne, elles sont dessinées AU CANTON (les cantons de 1967), avec
-- les cantons divisés en notes :
--   Yvelines — « trois cantons étaient divisés : 1) Versailles-Nord-Ouest :
--     Le Chesnay 4e ; Rocquencourt, Saint-Cyr et la partie Nord-Ouest de
--     Versailles 5e. 2) Versailles-Nord : Viroflay 6e ; la partie Nord de
--     Versailles 5e. 3) Versailles-Ouest : Les Clayes 4e ; Bois-d'Arcy et
--     Fontenay 5e ; Montigny, Guyancourt et la partie Ouest de Versailles 6e ;
--     Plaisir, Thiverval et Trappes 8e. » « Les communes de Château-Fort et
--     Toussus-le-Noble, rattachées aux Yvelines (6e) par décret du 21 novembre
--     1969, appartenaient auparavant à l'Essonne (4e). »
--   Essonne — « 1) Corbeil-Nord : Bondoufle, Courcouronnes, Écharcon, Évry,
--     Lisses et Ris-Orangis 2e ; le reste 1re. 2) Corbeil-Sud : Corbeil,
--     Morsang, Saint-Pierre et Saintry 1re ; le reste 2e. »
-- Le groupe Corbeil, Étiolles, Morsang, Saint-Germain, Saint-Pierre, Saintry,
-- Soisy, Tigery est celui que la note de 1958 donnait déjà à la 13e de
-- Seine-et-Oise : les deux lectures se recoupent.
--
-- LA RÈGLE
-- ========
-- Le canton de la commune au 31 décembre 1967 (posé par `127`) donne la
-- circonscription ; les communes nommées par les notes passent avant. Les
-- noms de canton de la base ne sont pas toujours ceux de l'atlas : « Dourdan-
-- Nord » et « Dourdan-Sud » côté Yvelines sont le canton de Saint-Arnoult de
-- la carte, « Sarcelles-Centre » et « Écouen-Lochères » ses Sarcelles et
-- Écouen. Trois communes n'ont pas de canton à cette date et sont nommées :
-- Corbeil-Essonnes (1re), Argenteuil (3e), Sarcelles (5e).
--
-- VERSAILLES n'a aucun canton de 1964 à 1994 (la ville découpée en quatre
-- cantons en 1964 n'est pas tracée). Elle est posée par ses trois fractions
-- d'avant 1964 : Nord en 5e, Ouest et Sud en 6e. APPROXIMATION : la partie
-- Nord-Ouest de 1964 (5e) n'a pas d'atome à elle, et la limite Nord / Ouest
-- de 1941 n'est pas celle de 1967.
--
-- Bornes et choix des atomes : ceux de `125` — [1968-01-01, 1986-11-24),
-- atomes qui ont un canton à la date, sinon ceux de la circonscription de
-- 1986, sinon l'atome entier.
--
-- Réversible : `circo_1967gc_trace`. Rejouable. Passe après `127` et `125`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set du '1968-01-01'
\set au '1986-11-24'
\set ref '1967-12-31'
\set bascule_69 '1969-11-21'

CREATE TABLE IF NOT EXISTS circo_1967gc_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_1967gc_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_1967gc_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_1967gc_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_1967gc_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- Canton de la carte (nom de la base au 31 décembre 1967) -> circonscription.
-- `dep` est celui de la commune aujourd'hui (préfixe INSEE).
DROP TABLE IF EXISTS t128_canton;
CREATE TEMP TABLE t128_canton (dep text, canton text, circo int);
INSERT INTO t128_canton VALUES
('78','Maisons-Laffitte',1), ('78','Houilles',1),
('78','Saint-Germain-en-Laye',2), ('78','Chatou',2),
('78','Conflans-Sainte-Honorine',3), ('78','Poissy',3), ('78','Meulan',3),
('78','Marly-le-Roi',4), ('78','La Celle-Saint-Cloud',4),
('78','Versailles-Sud',6),
('78','Bonnières-sur-Seine',7), ('78','Limay',7), ('78','Mantes-Gassicourt',7),
('78','Houdan',7),
('78','Montfort-l''Amaury',8), ('78','Rambouillet',8), ('78','Chevreuse',8),
('78','Dourdan-Nord',8), ('78','Dourdan-Sud',8),
('91','Montgeron',1), ('91','Brunoy',1),
('91','Arpajon',2), ('91','Étampes',2), ('91','La Ferté-Alais',2),
('91','Méréville',2), ('91','Milly',2),
('91','Massy',3), ('91','Athis-Mons',3), ('91','Longjumeau',3),
('91','Savigny-sur-Orge',3), ('91','Juvisy-sur-Orge',3),
('91','Palaiseau',4), ('91','Limours',4), ('91','Dourdan-Nord',4),
('91','Dourdan-Sud',4),
('95','Magny-en-Vexin',1), ('95','Marines',1), ('95','Pontoise',1),
('95','L''Isle-Adam',1),
('95','Cormeilles-en-Parisis',2), ('95','Taverny',2),
('95','Argenteuil-Sud',3),
('95','Saint-Leu-la-Forêt',4), ('95','Montmorency',4),
('95','Enghien-les-Bains',4), ('95','Soisy-sous-Montmorency',4),
('95','Luzarches',5), ('95','Sarcelles-Centre',5), ('95','Écouen-Lochères',5),
('95','Gonesse',5),
-- communes d'un département rangées en 1967 dans un canton de l'autre
('78','Magny-en-Vexin',-951),   -- Arthieul, Blamécourt : Magny, 1re du 95
('78','Méréville',-912);        -- Congerville : Méréville, 2e du 91

-- Communes nommées par les notes (et les trois sans canton au 31/12/1967).
-- `unite` explicite ; `du`/`au` pour Château-Fort et Toussus-le-Noble.
DROP TABLE IF EXISTS t128_nomme;
CREATE TEMP TABLE t128_nomme (insee text, nom text, unite text, du date, au date);
INSERT INTO t128_nomme VALUES
('78158','Le Chesnay','78-04', :'du', :'au'),
('78524','Rocquencourt','78-05', :'du', :'au'),
('78545','Saint-Cyr-l''École','78-05', :'du', :'au'),
('78686','Viroflay','78-06', :'du', :'au'),
('78165','Les Clayes-sous-Bois','78-04', :'du', :'au'),
('78073','Bois-d''Arcy','78-05', :'du', :'au'),
('78242','Fontenay-le-Fleury','78-05', :'du', :'au'),
('78423','Montigny-le-Bretonneux','78-06', :'du', :'au'),
('78297','Guyancourt','78-06', :'du', :'au'),
('78490','Plaisir','78-08', :'du', :'au'),
('78615','Thiverval-Grignon','78-08', :'du', :'au'),
('78621','Trappes','78-08', :'du', :'au'),
('78143','Châteaufort','91-04', :'du', :'bascule_69'),
('78143','Châteaufort','78-06', :'bascule_69', :'au'),
('78620','Toussus-le-Noble','91-04', :'du', :'bascule_69'),
('78620','Toussus-le-Noble','78-06', :'bascule_69', :'au'),
('91086','Bondoufle','91-02', :'du', :'au'),
('91182','Courcouronnes','91-02', :'du', :'au'),
('91204','Écharcon','91-02', :'du', :'au'),
('91228','Évry','91-02', :'du', :'au'),
('91340','Lisses','91-02', :'du', :'au'),
('91521','Ris-Orangis','91-02', :'du', :'au'),
('91225','Étiolles','91-01', :'du', :'au'),
('91553','Saint-Germain-lès-Corbeil','91-01', :'du', :'au'),
('91600','Soisy-sur-Seine','91-01', :'du', :'au'),
('91617','Tigery','91-01', :'du', :'au'),
('91174','Corbeil-Essonnes','91-01', :'du', :'au'),
('91435','Morsang-sur-Seine','91-01', :'du', :'au'),
('91573','Saint-Pierre-du-Perray','91-01', :'du', :'au'),
('91577','Saintry-sur-Seine','91-01', :'du', :'au'),
('91037','Auvernaux','91-02', :'du', :'au'),
('91045','Ballancourt-sur-Essonne','91-02', :'du', :'au'),
('91135','Champcueil','91-02', :'du', :'au'),
('91159','Chevannes','91-02', :'du', :'au'),
('91179','Le Coudray-Montceaux','91-02', :'du', :'au'),
('91244','Fontenay-le-Vicomte','91-02', :'du', :'au'),
('91386','Mennecy','91-02', :'du', :'au'),
('91441','Nainville-les-Roches','91-02', :'du', :'au'),
('91468','Ormoy','91-02', :'du', :'au'),
('91649','Vert-le-Petit','91-02', :'du', :'au'),
('91659','Villabé','91-02', :'du', :'au'),
('95018','Argenteuil','95-03', :'du', :'au'),
('95585','Sarcelles','95-05', :'du', :'au');

-- Versailles : par atome
DROP TABLE IF EXISTS t128_versailles;
CREATE TEMP TABLE t128_versailles (atom_id text, unite text);
INSERT INTO t128_versailles VALUES
('39569#7838','78-05'), ('39569#7839','78-06'), ('39569#7840','78-06');

-- La composition : commune -> unité, sur sa fenêtre
DROP TABLE IF EXISTS t128_lu;
CREATE TEMP TABLE t128_lu AS
WITH canton_ref AS (
    SELECT DISTINCT a.insee_geofla AS insee, left(a.insee_geofla, 2) AS dep,
           coalesce(v.nom, u.nom) AS canton
      FROM membership m
      JOIN atom a USING (atom_id)
      JOIN unit u ON u.unit_id = m.unit_id
      LEFT JOIN unit_version v ON v.unit_id = u.unit_id AND v.periode @> :'ref'::date
     WHERE m.niveau = 'canton' AND m.periode @> :'ref'::date
       AND left(a.insee_geofla, 2) IN ('78','91','95')
)
SELECT r.insee, r.canton,
       CASE WHEN c.circo = -951 THEN '95-01'
            WHEN c.circo = -912 THEN '91-02'
            ELSE r.dep || '-' || lpad(c.circo::text, 2, '0') END AS unite,
       :'du'::date AS du, :'au'::date AS au, 'canton'::text AS par
  FROM canton_ref r
  JOIN t128_canton c ON c.dep = r.dep AND c.canton = r.canton
 WHERE r.insee NOT IN (SELECT insee FROM t128_nomme)
   AND r.insee <> '78646'
UNION ALL
SELECT insee, NULL, unite, du, au, 'nommee' FROM t128_nomme;

\echo ''
\echo '=== 1. Cantons au 31/12/1967 sans correspondance (attendu : aucun, hors Versailles) ==='
SELECT left(a.insee_geofla, 2) AS dep, coalesce(v.nom, u.nom) AS canton,
       count(DISTINCT a.insee_geofla) AS communes
  FROM membership m JOIN atom a USING (atom_id) JOIN unit u ON u.unit_id = m.unit_id
  LEFT JOIN unit_version v ON v.unit_id = u.unit_id AND v.periode @> :'ref'::date
 WHERE m.niveau = 'canton' AND m.periode @> :'ref'::date
   AND left(a.insee_geofla, 2) IN ('78','91','95')
   AND NOT EXISTS (SELECT 1 FROM t128_canton c
                    WHERE c.dep = left(a.insee_geofla, 2) AND c.canton = coalesce(v.nom, u.nom))
 GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 2. Communes : dans deux unités à la fois, ou dans aucune (attendu : Versailles et les mortes seules) ==='
SELECT l.insee, count(*) AS lignes FROM t128_lu l
 GROUP BY 1 HAVING count(*) > 1 AND l.insee NOT IN ('78143','78620');
SELECT DISTINCT a.insee_geofla AS sans_unite
  FROM atom a
 WHERE left(a.insee_geofla, 2) IN ('78','91','95')
   AND a.insee_geofla NOT IN (SELECT insee FROM t128_lu)
 ORDER BY 1;

\echo ''
\echo '=== 2 bis. Notes contre cantons : la commune nommée est-elle bien dans le canton annoncé ? ==='
SELECT n.insee, n.nom, coalesce(v.nom, u.nom) AS canton_base
  FROM t128_nomme n
  JOIN atom a ON a.insee_geofla = n.insee
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> :'ref'::date
  JOIN unit u ON u.unit_id = m.unit_id
  LEFT JOIN unit_version v ON v.unit_id = u.unit_id AND v.periode @> :'ref'::date
 ORDER BY 3, 1;

-- Les intervalles, par (commune, ligne) : bornes cantonales dans la fenêtre
DROP TABLE IF EXISTS t128_borne;
CREATE TEMP TABLE t128_borne AS
SELECT DISTINCT l.insee, l.unite, l.du AS fdu, l.au AS fau, b AS d
  FROM t128_lu l
  JOIN LATERAL (
        SELECT l.du AS b UNION SELECT l.au
        UNION
        SELECT x FROM membership m JOIN atom a USING (atom_id),
               LATERAL (VALUES (m.valid_from), (m.valid_to)) v(x)
         WHERE a.insee_geofla = l.insee AND m.niveau = 'canton'
           AND x > l.du AND x < l.au) z ON true;

DROP TABLE IF EXISTS t128_inter;
CREATE TEMP TABLE t128_inter AS
SELECT insee, unite, d AS du, lead(d) OVER (PARTITION BY insee, unite, fdu ORDER BY d) AS au
  FROM t128_borne;
DELETE FROM t128_inter WHERE au IS NULL;

DROP TABLE IF EXISTS t128_brut;
CREATE TEMP TABLE t128_brut AS
WITH actifs AS (
    SELECT i.insee, i.unite, i.du, i.au, a.atom_id, 'canton'::text AS voie
      FROM t128_inter i JOIN atom a ON a.insee_geofla = i.insee
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id
                    AND m.niveau = 'canton' AND m.periode @> i.du)
), repli86 AS (
    SELECT i.insee, i.unite, i.du, i.au, a.atom_id, 'circo_1986'::text AS voie
      FROM t128_inter i JOIN atom a ON a.insee_geofla = i.insee
     WHERE NOT EXISTS (SELECT 1 FROM actifs x WHERE x.insee = i.insee AND x.du = i.du)
       AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id
                    AND m.niveau = 'circo' AND m.periode @> :'au'::date)
), entier AS (
    SELECT i.insee, i.unite, i.du, i.au, a.atom_id, 'entier'::text AS voie
      FROM t128_inter i JOIN atom a ON a.insee_geofla = i.insee AND NOT a.fraction
     WHERE NOT EXISTS (SELECT 1 FROM actifs x WHERE x.insee = i.insee AND x.du = i.du)
       AND NOT EXISTS (SELECT 1 FROM repli86 x WHERE x.insee = i.insee AND x.du = i.du)
)
SELECT * FROM actifs UNION ALL SELECT * FROM repli86 UNION ALL SELECT * FROM entier
UNION ALL
SELECT '78646', unite, :'du'::date, :'au'::date, atom_id, 'versailles' FROM t128_versailles;

-- Une commune morte avant 1968 n'a aucun atome actif : son « entier » ne doit
-- pas être dessiné. On ne garde l'entier que si l'atome a vécu dans la fenêtre
-- (un rattachement quelconque après 1968).
DELETE FROM t128_brut b
 WHERE b.voie = 'entier'
   AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = b.atom_id
                    AND m.valid_to > :'du'::date);

DROP TABLE IF EXISTS t128_pose;
CREATE TEMP TABLE t128_pose AS
WITH o AS (
    SELECT b.*, b.unite || '@1967' AS unit_id,
           CASE WHEN b.du = lag(b.au) OVER (PARTITION BY b.atom_id, b.unite ORDER BY b.du)
                THEN 0 ELSE 1 END AS neuf
      FROM t128_brut b
), g AS (
    SELECT o.*, sum(neuf) OVER (PARTITION BY atom_id, unite ORDER BY du) AS ilot FROM o
)
SELECT atom_id, insee, left(unite, 2) AS dep, unit_id, min(du) AS valid_from,
       max(au) AS valid_to, string_agg(DISTINCT voie, '+') AS voie
  FROM g GROUP BY atom_id, insee, unite, unit_id, ilot;

\echo ''
\echo '=== 3. Ce qui sera posé ==='
SELECT dep, count(DISTINCT unit_id) AS circos, count(DISTINCT insee) AS communes,
       count(DISTINCT atom_id) AS atomes, count(*) AS rattachements
  FROM t128_pose GROUP BY 1 ORDER BY 1;
SELECT voie, count(DISTINCT insee) AS communes FROM t128_pose GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 4. Garde-fou : un atome dans deux unités à la fois (attendu : zéro) ==='
SELECT a.atom_id, a.unit_id, b.unit_id
  FROM t128_pose a JOIN t128_pose b
    ON a.atom_id = b.atom_id AND a.unit_id < b.unit_id
   AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);

\echo ''
\echo '=== 5. Garde-fou : périodes déjà prises au niveau circo (attendu : zéro) ==='
DROP TABLE IF EXISTS t128_pris;
CREATE TEMP TABLE t128_pris AS
SELECT p.atom_id, p.insee, m.unit_id, m.valid_from, m.valid_to
  FROM t128_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
SELECT * FROM t128_pris ORDER BY 1 LIMIT 30;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t128_pris;
    IF n > 0 THEN RAISE EXCEPTION '% rattachement(s) existent déjà. Recette 5.', n; END IF;
    SELECT count(*) INTO n FROM t128_pose a JOIN t128_pose b
        ON a.atom_id = b.atom_id AND a.unit_id < b.unit_id
       AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);
    IF n > 0 THEN RAISE EXCEPTION '% atome(s) dans deux unités. Recette 4.', n; END IF;
    SELECT count(*) INTO n FROM (SELECT DISTINCT unit_id FROM t128_pose) d JOIN unit u USING (unit_id);
    IF n > 0 THEN RAISE EXCEPTION '% unité(s) déjà en base hors trace.', n; END IF;
END $$;

DROP TABLE IF EXISTS t128_nom;
CREATE TEMP TABLE t128_nom (dep text, nom text);
INSERT INTO t128_nom VALUES ('78','Yvelines'), ('91','Essonne'), ('95','Val-d''Oise');

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT DISTINCT p.unit_id, 'circo', p.dep, split_part(p.unit_id, '@', 1),
           'uninominal', 1967,
           n.nom || ' ' || ltrim(substr(p.unit_id, 4, 2), '0')
             || CASE WHEN substr(p.unit_id, 4, 2) = '01' THEN 're' ELSE 'e' END
             || ' circonscription (1967-1986)', false
      FROM t128_pose p JOIN t128_nom n USING (dep)
    RETURNING unit_id
)
INSERT INTO circo_1967gc_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT p.unit_id,
       n.nom || ' ' || ltrim(substr(p.unit_id, 4, 2), '0')
         || CASE WHEN substr(p.unit_id, 4, 2) = '01' THEN 're' ELSE 'e' END
         || ' circonscription', :'du'::date, :'au'::date
  FROM t128_pose p JOIN t128_nom n USING (dep);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM t128_pose
    RETURNING membership_id
)
INSERT INTO circo_1967gc_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 6. Posé ==='
SELECT quoi, count(*) FROM circo_1967gc_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 7. Communes des 78, 91, 95 à canton et sans circonscription, au 1er juillet (attendu : 0) ==='
SELECT y AS annee, left(a.insee_geofla, 2) AS dep,
       count(DISTINCT a.insee_geofla) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership k JOIN atom b USING (atom_id)
            WHERE b.insee_geofla = a.insee_geofla AND k.niveau = 'circo'
              AND k.periode @> make_date(y, 7, 1))) AS sans_circo
  FROM atom a JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
   , generate_series(1968, 1986) y
 WHERE left(a.insee_geofla, 2) IN ('78','91','95') AND m.periode @> make_date(y, 7, 1)
 GROUP BY 1, 2 HAVING count(DISTINCT a.insee_geofla) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership k JOIN atom b USING (atom_id)
            WHERE b.insee_geofla = a.insee_geofla AND k.niveau = 'circo'
              AND k.periode @> make_date(y, 7, 1))) > 0
 ORDER BY 1, 2;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

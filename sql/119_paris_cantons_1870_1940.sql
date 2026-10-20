-- ============================================================================
-- histgis — 119_paris_cantons_1870_1940.sql : les cantons de Paris portés par
--                                              ses QUARTIERS, 1876-1940
--
--   psql -d histgis -f sql/119_paris_cantons_1870_1940.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/119_paris_cantons_1870_1940.sql
--   psql -d histgis -1 -v defaire=1   -f sql/119_paris_cantons_1870_1940.sql
--
-- À blanc, tout se joue dans une transaction annulée à la fin : les recettes
-- montrent l'état d'après, la base n'est pas touchée.
--
-- LE DÉFAUT
-- =========
-- Les vingt cantons de Paris de 1870 à 1940 (7515 à 7534, un par
-- arrondissement) sont portés par les atomes-arrondissements 762xx, de
-- [1870-01-01, 1941-01-01). Les circonscriptions le sont par les quartiers
-- `PQ…` sur [1876, 1885) et [1889, 1941) — au scrutin de liste (1870-1876,
-- 1885-1889) ce sont les arrondissements qui portent la circo départementale.
--
-- Quand les deux trames vivent, le treillis de `84` (`partition_un_dep`, appelé
-- par `carte_partition_atome` de `99`), qui ne connaît pas les niveaux, voit
-- deux propriétaires sur chaque face de Paris : l'arrondissement (repli
-- `atom_geom`, ~16 km² pour le 12e) et le quartier qui la contient (repli ou
-- fenêtre `iris-bois_118`, quelques km²). Tous deux sont des replis — ou le
-- quartier seul est daté — et l'arbitrage (d) départage par l'AIRE : le plus
-- petit gagne. Le quartier prend toutes les faces, l'arrondissement n'en garde
-- aucune et sort du résultat sans un mot.
--
-- Mesuré à blanc le 18 octobre 2026, au 1900-06-01 : `carte_partition_atome`
-- rend 83 quartiers (65 en `departage`) et AUCUN des 20 arrondissements ;
-- `carte_partition(…, 'canton', '75')` rend les 21 cantons de banlieue et pas
-- un canton parisien. L'en-tête de `103` disait « 1876-1940 n'est pas touché :
-- les quartiers y sont entiers, et le partage n'y a rien coupé » — c'est vrai
-- des quartiers, pas des arrondissements, qui y perdaient tout.
--
-- LA RÈGLE : CELLE DE `103`, UNE SEULE TRAME À LA FOIS
-- ====================================================
-- Sur chaque période où les quartiers d'un arrondissement sont rattachés à une
-- circonscription, ce sont EUX qui portent son canton : chaque quartier
-- (`PQnn` et fractions `PQnn#…`, même code INSEE) reçoit le canton de son
-- arrondissement, sur ses propres périodes de circo bornées à la période du
-- canton. Le rattachement cantonal de l'arrondissement est réduit à ce qui
-- reste — [1870, 1876) et [1885, 1889), où il porte aussi la circo et où les
-- quartiers ne vivent pas. Rien n'est perdu : le canton d'un arrondissement
-- est l'union de ses quartiers.
--
-- Un arrondissement dont le canton n'est pas EXACTEMENT [1870, 1941), ou dont
-- un quartier vit en circo hors de cette période sans être couvert, n'est pas
-- traité (recette 1).
--
-- Le bois de Boulogne et celui de Vincennes suivent `118` sans rien demander :
-- de 1876 à 1925-1929, les quartiers PQ45, 46, 61, 62, 63 sont déjà amputés
-- des parts non annexées. Aux deux fenêtres de scrutin de liste, les
-- arrondissements 76219 et 76223 retombent sur leur repli bois compris ; les
-- communes riveraines, datées, gardent le bois au § (d) de `84`.
--
-- ORDRE ET RÉVERSIBILITÉ
-- ======================
-- Après `103`, qui lit le canton des arrondissements au 1940-06-01 pour savoir
-- quel canton donner aux quartiers après 1941 : joué après `119`, `103` n'y
-- trouverait plus rien, déclarerait les vingt arrondissements « NON TRAITÉ » et
-- rendrait 1941-1998 aux arrondissements. Rejouer `103` seul demande donc de
-- défaire `119` d'abord (`-v defaire=1`), puis de le rejouer.
--
-- `p119_trace` : rattachements posés (quartiers et morceaux d'arrondissement
-- restants). `p119_modif` : rattachements d'arrondissement retirés, avec leurs
-- bornes d'origine. Le fichier défait toujours son passage précédent avant de
-- poser : il est rejouable.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?appliquer}
\elif :{?defaire}
\else
BEGIN;
\endif

CREATE TABLE IF NOT EXISTS p119_trace (
    membership_id bigint PRIMARY KEY,
    pose_le timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS p119_modif (
    membership_id bigint PRIMARY KEY,
    atom_id    text NOT NULL,
    unit_id    text NOT NULL,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    pose_le    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent
-- ---------------------------------------------------------------------------
DELETE FROM membership m USING p119_trace t WHERE t.membership_id = m.membership_id;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p119_modif;
TRUNCATE p119_trace, p119_modif;

\if :{?defaire}
\echo ''
\echo '=== 119 défait : les arrondissements portent de nouveau le canton de 1870 à 1940 ==='
SELECT count(*) AS arrondissements_canton_1870_1941
FROM   membership m JOIN atom a USING (atom_id)
WHERE  m.niveau = 'canton' AND a.insee_geofla ~ '^751(0[1-9]|1[0-9]|20)$'
  AND  a.atom_id NOT LIKE 'P%' AND NOT a.fraction
  AND  m.valid_from = DATE '1870-01-01' AND m.valid_to = DATE '1941-01-01';
-- Attendu : 20.
\else

-- ---------------------------------------------------------------------------
-- 1. Les arrondissements et leur canton de 1870-1940
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t119_arr, t119_pq, t119_couv, t119_carte;

CREATE TEMP TABLE t119_arr AS
SELECT a.atom_id, a.insee_geofla AS insee,
       m.membership_id, m.unit_id, m.valid_from, m.valid_to, m.periode,
       (m.valid_from = DATE '1870-01-01' AND m.valid_to = DATE '1941-01-01') AS bornes_ok
FROM   atom a
JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> DATE '1900-06-01'
WHERE  a.insee_geofla ~ '^751(0[1-9]|1[0-9]|20)$'
  AND  a.atom_id NOT LIKE 'P%' AND NOT a.fraction;

-- Les périodes de circo de chaque quartier, bornées à celle du canton de son
-- arrondissement, fusionnées quand elles se touchent.
CREATE TEMP TABLE t119_pq AS
SELECT g.atom_id, g.insee, g.unit_id, lower(p) AS du, upper(p) AS au
FROM  (SELECT q.atom_id, r.insee, r.unit_id,
              range_agg(m.periode * r.periode) AS mr
       FROM   atom q
       JOIN   t119_arr r ON r.insee = q.insee_geofla AND r.bornes_ok
       JOIN   membership m ON m.atom_id = q.atom_id AND m.niveau = 'circo'
                          AND m.periode && r.periode
       WHERE  q.atom_id LIKE 'PQ%'
       GROUP  BY q.atom_id, r.insee, r.unit_id) g
CROSS  JOIN LATERAL unnest(g.mr) p;

-- Par arrondissement : l'union des périodes de ses quartiers, et ce qu'il
-- garde — la période du canton moins cette union.
CREATE TEMP TABLE t119_couv AS
SELECT r.atom_id, r.insee, r.unit_id, r.membership_id, r.valid_from, r.valid_to,
       coalesce((SELECT range_agg(daterange(p.du, p.au)) FROM t119_pq p
                  WHERE p.insee = r.insee), '{}'::datemultirange) AS par_quartiers
FROM   t119_arr r WHERE r.bornes_ok;
ALTER TABLE t119_couv ADD COLUMN reste datemultirange;
UPDATE t119_couv SET reste = datemultirange(daterange(valid_from, valid_to)) - par_quartiers;

\echo ''
\echo '=== 1. Les arrondissements : canton, périodes par les quartiers, reste ==='
SELECT r.insee, r.atom_id, r.unit_id, r.valid_from, r.valid_to,
       c.par_quartiers, c.reste,
       (SELECT count(DISTINCT p.atom_id) FROM t119_pq p WHERE p.insee = r.insee) AS quartiers,
       CASE WHEN NOT r.bornes_ok THEN 'NON TRAITÉ (bornes)'
            WHEN c.par_quartiers = '{}' THEN 'NON TRAITÉ (aucun quartier)'
            ELSE 'traité' END AS verdict
FROM   t119_arr r LEFT JOIN t119_couv c USING (atom_id)
ORDER  BY r.insee;
-- Attendu : 20 lignes « traité », par_quartiers {[1876-01-01,1885-01-01),
-- [1889-01-01,1941-01-01)}, reste {[1870-01-01,1876-01-01),[1885-01-01,1889-01-01)}.

\echo ''
\echo '=== 1 bis. Une date où un arrondissement aurait des quartiers vivants en circo, mais pas tous ses sols ? ==='
-- Pour chaque arrondissement et chaque borne de période, l'aire des quartiers
-- vivants (repli `atom_geom`, bois compris) contre celle de l'arrondissement.
-- L'UNION et non la somme : les fractions `PQnn#…` partagent le polygone de
-- leur quartier.
WITH bornes AS (
    SELECT DISTINCT p.insee, p.du AS d FROM t119_pq p
)
SELECT b.insee, b.d,
       round((ST_Area(ga.geom) / 1e6)::numeric, 3) AS km2_arr,
       round((ST_Area(ST_Union(gq.geom)) / 1e6)::numeric, 3) AS km2_quartiers
FROM   bornes b
JOIN   t119_couv c ON c.insee = b.insee
JOIN   atom_geom ga ON ga.atom_id = c.atom_id
JOIN   t119_pq p ON p.insee = b.insee AND b.d >= p.du AND b.d < p.au
JOIN   atom_geom gq ON gq.atom_id = p.atom_id
GROUP  BY b.insee, b.d, ga.geom
HAVING abs(ST_Area(ga.geom) - ST_Area(ST_Union(gq.geom))) > 1e4
ORDER  BY 1, 2;
-- Attendu : aucune ligne (écart > 1 ha).

-- ---------------------------------------------------------------------------
-- 2. Poser
-- ---------------------------------------------------------------------------
INSERT INTO p119_modif (membership_id, atom_id, unit_id, valid_from, valid_to)
SELECT membership_id, atom_id, unit_id, valid_from, valid_to
FROM   t119_couv WHERE par_quartiers <> '{}';

DELETE FROM membership m USING p119_modif t WHERE t.membership_id = m.membership_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atom_id, p.unit_id, 'canton', p.du, p.au
    FROM   t119_pq p
    JOIN   t119_couv c ON c.insee = p.insee
    JOIN   p119_modif t ON t.membership_id = c.membership_id
    UNION ALL
    SELECT c.atom_id, c.unit_id, 'canton', lower(r), upper(r)
    FROM   t119_couv c JOIN p119_modif t USING (membership_id)
    CROSS  JOIN LATERAL unnest(c.reste) r
    RETURNING membership_id
)
INSERT INTO p119_trace (membership_id) SELECT membership_id FROM ins;

\echo ''
\echo '=== 2. Posé ==='
SELECT (SELECT count(*) FROM p119_modif)                                   AS arrondissements_retires,
       (SELECT count(*) FROM p119_trace t JOIN membership m USING (membership_id)
         WHERE m.atom_id LIKE 'PQ%')                                       AS cantons_de_quartier,
       (SELECT count(*) FROM p119_trace t JOIN membership m USING (membership_id)
         WHERE m.atom_id NOT LIKE 'PQ%')                                   AS restes_d_arrondissement;

-- ---------------------------------------------------------------------------
-- 3. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. À ces dates, une seule trame vivante à Paris ? ==='
SELECT d::date AS date,
       count(DISTINCT m.atom_id) FILTER (WHERE m.atom_id LIKE 'PQ%')     AS quartiers_vivants,
       count(DISTINCT m.atom_id) FILTER (WHERE m.atom_id NOT LIKE 'P%')  AS arrondissements_vivants
FROM   unnest(ARRAY['1872-06-01','1880-06-01','1887-06-01','1900-06-01',
                    '1927-06-01','1935-06-01']::date[]) d
JOIN   membership m ON m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla ~ '^751'
GROUP  BY d ORDER BY d;
-- Attendu : arrondissements 20 et quartiers 0 en 1872 et 1887 ; l'inverse
-- aux autres dates.

\echo ''
\echo '=== 4. La carte des cantons de la Seine : 20 cantons parisiens, 479,64 km², sans recouvrement ==='
CREATE TEMP TABLE t119_carte AS
SELECT d::date AS date, c.unit_id, c.geom
FROM   unnest(ARRAY['1872-06-01','1880-06-01','1887-06-01','1900-06-01',
                    '1927-06-01','1935-06-01']::date[]) d
CROSS  JOIN LATERAL carte_partition(d::date, 'canton', '75') c;

SELECT date,
       count(*) FILTER (WHERE unit_id BETWEEN '7515' AND '7534')          AS cantons_paris,
       count(*) FILTER (WHERE NOT unit_id BETWEEN '7515' AND '7534')      AS cantons_banlieue,
       round((sum(ST_Area(geom)) FILTER (WHERE unit_id BETWEEN '7515' AND '7534') / 1e6)::numeric, 2) AS km2_paris,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 2)                      AS km2_seine,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 4) AS km2_recouvrement
FROM   t119_carte GROUP BY date ORDER BY date;
-- Attendu : 20 cantons parisiens à chaque date, km2_seine = 479,64,
-- km2_recouvrement = 0.

\endif

\if :{?appliquer}
ANALYZE membership;
\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte'
\elif :{?defaire}
ANALYZE membership;
\else
ROLLBACK;
\echo ''
\echo '=== Tourné à blanc (transaction annulée) — relancer avec -1 -v appliquer=1 ==='
\endif

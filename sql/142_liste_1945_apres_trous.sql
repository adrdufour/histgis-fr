-- ============================================================================
-- histgis — 142_liste_1945_apres_trous.sql : la liste départementale de
--           1945-1958 sur les cantons que `137` a prolongés après `122`
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/142_liste_1945_apres_trous.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/142_liste_1945_apres_trous.sql
--   psql -d histgis -1 -v defaire=1 -f sql/142_liste_1945_apres_trous.sql
--
-- Relevé le 1er novembre 2026, en corrigeant Aurent (`138`, cas `jumeau`) :
-- en 1957, 198 atomes dessinés par ANR avaient un canton et pas de
-- circonscription — Seine-et-Marne 47, Moselle 26, Territoire de Belfort 24,
-- Orne 21, Haute-Savoie 16, Sarthe 15, Rhône 14, Savoie 13,
-- Seine-Inférieure 9, Isère 8, Saône-et-Loire 4, Corse-du-Sud 1 (préfixe du
-- code GEOFLA). Tous ont la liste `L<dep>01@1945` de 1945 au 1er janvier
-- 1955, puis rien jusqu'en 1958.
--
-- LA CAUSE : l'ordre `122` → `137`, et une règle en une seule passe.
--   * `122` (21 octobre) pose la liste sur la DURÉE DU CANTON de l'atome
--     dans la fenêtre. Ces atomes avaient alors un trou cantonal ouvert au
--     1er janvier 1955 (fin de la lecture de 1954) : la liste s'arrêtait là.
--   * `137` (26 octobre) comble le trou cantonal — membership posée dès
--     1955, jusqu'en 1967, 1982, 1985 ou 1998 —, puis son § 8 cherche la
--     circonscription du trou [1955, 1958) chez les AUTRES atomes du canton
--     (`circo_meme_canton`). Or, dans ces 19 cantons, aucun autre atome
--     n'en avait sur [1955, 1958) au moment du calcul : ceux qui avaient le
--     même trou ne s'aident pas entre eux, et ceux qui n'avaient rien du
--     tout ne reçoivent la liste que dans la même passe. Rien n'est posé.
--   Ce n'est ni le report `93`/`97`, ni un jalon, ni un atome fantôme. Les
--   communes cédées depuis (quatre du canton de Meyzieu et dix de celui de
--   Saint-Symphorien-d'Ozon, de l'Isère au Rhône en 1967-1968, préfixe 69)
--   étaient en 1957 dans un canton de l'Isère : elles reçoivent la liste de
--   l'Isère.
--
-- LA RÈGLE, celle de `122`, rejouée sur les cantons d'aujourd'hui : sous la
-- Quatrième République le département est UNE circonscription (la Seine à
-- part, qui n'a pas d'unité `L75…`). Un atome qui a un canton du département
-- D (Corse ramenée à 20) sur une période de [1945-01-01, 1958-01-01) sans
-- aucune circonscription reçoit `L<D>01@1945` sur cette période, bornée à la
-- vie de l'unité. Aucune lecture n'est à faire : la liste est unique.
--   Prise sur toute la fenêtre et sur tous les atomes, la règle trouve au
--   1er novembre 2026 222 périodes sur 222 atomes : les 198 de 1957, et 24
--   autres du même mécanisme — six communes de la Somme (cantons 8008 et
--   8010, Amiens) et Furiani (2B120) de 1945 à 1954 ; les fractions de Lille (5934,
--   5939, 5941), de Lyon (neuf cantons), d'Orléans, de Strasbourg et de
--   Tours, sans liste de 1945 à 1958 alors que leurs voisines l'ont.
--
-- Réversible : `p142_trace`. Rejouable (la trace est retirée avant le
-- calcul). Après `141`. Ne pose que dans des trous : `122` et `137` rejoués
-- ensuite le verraient comme déjà posé ; les rejouer demande de défaire
-- celui-ci d'abord.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p142_trace (
    quoi text NOT NULL,              -- 'membership'
    cle  text NOT NULL,
    atom_id text, unit_id text, niveau text,
    ancien_from date, ancien_to date,
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
 WHERE EXISTS (SELECT 1 FROM p142_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM p142_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t142_udep;
CREATE TEMP TABLE t142_udep AS
SELECT unit_id, CASE WHEN dep::text IN ('2A', '2B') THEN '20' ELSE dep::text END AS dep
  FROM unit;
CREATE INDEX ON t142_udep (unit_id);

-- les listes de 1945, et leur vie
DROP TABLE IF EXISTS t142_liste;
CREATE TEMP TABLE t142_liste AS
SELECT u.unit_id, d.dep, daterange(min(v.valid_from), max(v.valid_to)) AS vie
  FROM unit u
  JOIN t142_udep d USING (unit_id)
  JOIN unit_version v USING (unit_id)
 WHERE u.niveau = 'circo' AND u.unit_id ~ '^L.*@1945$'
 GROUP BY 1, 2;

-- 1. Les trous : canton dans la fenêtre, aucune circonscription
DROP TABLE IF EXISTS t142_trou;
CREATE TEMP TABLE t142_trou AS
WITH circ AS (
    SELECT atom_id, range_agg(periode) AS mr
      FROM membership WHERE niveau = 'circo' GROUP BY 1
), can AS (
    SELECT m.atom_id, m.unit_id AS canton, m.periode * daterange('1945-01-01', '1958-01-01') AS p
      FROM membership m
     WHERE m.niveau = 'canton' AND m.periode && daterange('1945-01-01', '1958-01-01')
)
SELECT c.atom_id, c.canton,
       unnest(datemultirange(c.p) - coalesce(ci.mr, '{}'::datemultirange)) AS p
  FROM can c LEFT JOIN circ ci USING (atom_id);
DELETE FROM t142_trou WHERE isempty(p);

DROP TABLE IF EXISTS t142_pose;
CREATE TEMP TABLE t142_pose AS
SELECT g.atom_id, g.canton, l.unit_id AS circo, g.p * l.vie AS p
  FROM t142_trou g
  JOIN t142_udep dc ON dc.unit_id = g.canton
  JOIN t142_liste l ON l.dep = dc.dep AND l.unit_id = 'L' || dc.dep || '01@1945';
DELETE FROM t142_pose WHERE isempty(p);

\echo ''
\echo '=== 1. Trous trouvés, par département du canton (attendu : 222 sur 222 atomes) ==='
SELECT d.dep, count(*) AS periodes, count(DISTINCT g.atom_id) AS atomes,
       count(*) FILTER (WHERE a.fraction) AS fractions,
       count(*) FILTER (WHERE g.p @> DATE '1957-06-01') AS en_1957,
       min(lower(g.p)) AS du, max(upper(g.p)) AS au,
       string_agg(DISTINCT g.canton, ' ' ORDER BY g.canton) AS cantons
  FROM t142_trou g JOIN t142_udep d ON d.unit_id = g.canton JOIN atom a USING (atom_id)
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 1 bis. Trous sans liste de 1945 (attendu : zéro) ==='
SELECT g.*, d.dep FROM t142_trou g JOIN t142_udep d ON d.unit_id = g.canton
 WHERE NOT EXISTS (SELECT 1 FROM t142_pose x WHERE x.atom_id = g.atom_id AND x.p && g.p);

\echo ''
\echo '=== 1 ter. Communes dont le code GEOFLA n''est pas du département du canton ==='
SELECT a.insee_geofla, x.atom_id, x.canton, x.circo, x.p
  FROM t142_pose x JOIN atom a USING (atom_id) JOIN t142_udep d ON d.unit_id = x.canton
 WHERE CASE WHEN left(a.insee_geofla, 2) IN ('2A', '2B') THEN '20' ELSE left(a.insee_geofla, 2) END <> d.dep
 ORDER BY 1;

\echo ''
\echo '=== 2. Posés, par circonscription ==='
SELECT circo, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(lower(p)) AS du, max(upper(p)) AS au
  FROM t142_pose GROUP BY 1 ORDER BY 1;

\if :{?appliquer}
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(x.atom_id) INTO n, ex FROM t142_pose x
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = x.atom_id AND m.niveau = 'circo'
                      AND m.periode && x.p)
        OR EXISTS (SELECT 1 FROM t142_pose y WHERE y.atom_id = x.atom_id AND y.p && x.p
                      AND (y.circo, lower(y.p)) <> (x.circo, lower(x.p)));
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % période(s) déjà occupée(s) (p. ex. %).', n, ex; END IF;
    IF (SELECT count(*) FROM t142_pose) = 0 THEN
        RAISE NOTICE 'Rien à poser : la liste de 1945 couvre déjà tous les cantons.';
    END IF;
END $$;

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, circo, 'circo', lower(p), upper(p) FROM t142_pose
  RETURNING membership_id, atom_id, unit_id, valid_from, valid_to)
INSERT INTO p142_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'membership', membership_id::text, atom_id, unit_id, 'circo', valid_from, valid_to FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p142_trace GROUP BY 1 ORDER BY 1;
\endif

\echo ''
\echo '=== 3. En 1957, atomes dessinés par ANR à canton sans circonscription (attendu après pose : zéro) ==='
SELECT left(a.insee_geofla, 2) AS dep, count(*)
  FROM atom a
 WHERE EXISTS (SELECT 1 FROM atom_geom_anr g WHERE g.atom_id = a.atom_id AND g.periode @> DATE '1957-06-01')
   AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id AND m.niveau = 'canton'
                  AND m.periode @> DATE '1957-06-01')
   AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id AND m.niveau = 'circo'
                      AND m.periode @> DATE '1957-06-01')
 GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '=== 4. Cravanche (90, atome 10945), 1945-1958 ==='
SELECT niveau, unit_id, valid_from, valid_to FROM membership
 WHERE atom_id = '10945' AND valid_to > '1945-01-01' AND valid_from < '1958-01-01'
 ORDER BY niveau, valid_from;
\endif

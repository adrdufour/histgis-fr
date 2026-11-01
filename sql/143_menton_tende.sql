-- ============================================================================
-- histgis — 143_menton_tende.sql : une commune dessinée sans l'une de ses deux
--           couches — la ville dont la mère et les fractions se partagent
--           canton et circonscription (Menton), et la commune neuve qui n'a
--           aucun rattachement avant la couche moderne (Tende, La Brigue)
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/143_menton_tende.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/143_menton_tende.sql
--   psql -d histgis -1 -v defaire=1 -f sql/143_menton_tende.sql
--
-- Relevé le 1er novembre 2026, à la demande d'Adrien : « Menton n'a pas de
-- circonscription et Tende pas de canton ; ils ne sont ni l'un ni l'autre
-- dans la liste ». Planche des Alpes-Maritimes, 1987-1997.
--
-- 1. MENTON : LA MÈRE TIENT UNE COUCHE, SES FRACTIONS L'AUTRE
-- ==========================================================
-- De 1986-11-24 à 1998-03-15, la commune entière (`22015`) porte le canton
-- de Menton (`95`, report 1969-1998), et ses deux fractions (`22015#0613`,
-- `22015#0652`) la circonscription 06-04@1986 (`28`, qui lit les communes
-- de 1999, où Menton est déjà coupée — décret du 21 février 1997, effet en
-- mars 1998, voir `112`). Les deux couches ne tiennent pas le même atome.
-- La page sait déplier une mère sur ses fractions (`deplieMeres()`), mais
-- seulement quand les fractions COUVRENT la mère : avant 1998 elles n'ont
-- que leur polygone de repli, 4 % de la commune. Le dépliage est refusé, la
-- commune entière se dessine avec son canton et sans circonscription, et
-- les fractions sont masquées dans la couche cantonale.
--
-- LA RÈGLE : sur la fenêtre où la mère tient la couche L1 et AUCUNE de ses
-- fractions ne la tient, les rattachements L2 des fractions reviennent à la
-- mère, à condition que les fractions soient toutes dans la même unité L2 à
-- chaque instant. C'est vrai par construction : toutes les parties de la
-- ville sont dans une seule circonscription, donc la ville aussi. Deux cas :
--   * `transfert` : la mère n'a pas L2 sur le morceau, elle le reçoit ;
--   * `doublon` : la mère a déjà L2, et la même unité ; rien à lui donner.
-- Dans les deux cas les fractions perdent L2 sur le morceau : une commune,
-- un atome par date et par couche.
-- Des fractions dans DEUX circonscriptions, quand la ville entière est dans
-- un canton : la circonscription est celle des autres communes de ce canton,
-- si elle est unique (règle de `137` § 8). Monéteau (89) : la ville est au
-- canton d'Auxerre-Nord jusqu'en 1992 ; `28`, qui lit la commune de 1999,
-- met sa fraction du canton de Seignelay dans la 2e circonscription. Les
-- autres communes d'Auxerre-Nord sont dans la 1re : Monéteau aussi.
-- Une mère qui a L2 dans une AUTRE unité que ses fractions ne reçoit rien :
-- le conflit est listé au § 1 quater.
--
-- La règle écarte d'elle-même le schéma de 1870-1940 (cantons sur les
-- fractions, circonscription sur la mère, 120 villes) : là les fractions
-- tiennent L1, et la page les déplie, puisqu'elles sont découpées.
--
-- Mesuré au 1er novembre 2026 : 6 villes —
--   Menton (06), 1986-1998 ; Aubagne (13), 1986-2004 ; Istres et
--   Martigues (13), 1986-1992 ; Monéteau (89), 1986-1992 ; Rochefort (17),
--   1815-1852 (la ville est coupée en deux cantons en 1852 ; `106` a posé
--   les circonscriptions de 1815-1852 sur les deux fractions de 1870).
-- Reste en conflit : Orléans, 1968-1973 (la mère au canton d'Orléans-Nord-
-- Ouest pendant que ses fractions sont à Orléans-Est et Orléans-Ouest :
-- un doublon dans la couche cantonale, pas un trou).
--
-- 2. TENDE ET LA BRIGUE : FRANÇAISES DEPUIS 1947, SANS RATTACHEMENT AVANT 1986
-- ===========================================================================
-- Les deux communes n'ont d'atome que moderne (`M06162`, `M06163`, posés
-- par `21` sur la trame GEOFLA) : la trame de 1870 ne les a pas, ANR non
-- plus. `24` leur donne le canton de Tende à partir de 1998-03-15, `28` la
-- 06-04@1986 à partir de 1986-11-24 ; rien avant. JOURNAL du 28 août : « le
-- canton existe et il est vide » au jalon de 1954 — exact pour le jalon,
-- faux pour la carte, qui les dessine à partir de 1986 sans canton.
-- Ce qui est posé, et d'où :
--   * 1947-09-17 : rattachement à la France (traité de Paris du 10 février
--     1947 ; `insee_mvt`, mod 20, même date pour les deux) ;
--   * canton de Breil-sur-Roya (`0604`) jusqu'au 11 septembre 1951 : le
--     canton de Tende est créé « par division de Breil » (Gaudillère,
--     annexe VII, p. 789, `cantons/chronologie_cantonale.csv`) ;
--   * canton de Tende (`0631`) du 11 septembre 1951 au 15 mars 1998, où
--     `24` prend le relais. Date du décret selon la table analytique du JO
--     de 1951 (« Erection en canton (chef-lieu Tende). — D. 11 sept. 1951,
--     p. 9502 ») ; Gaudillère écrit le 10. Un jour d'écart, sans effet sur
--     une planche annuelle ; le JO l'emporte ;
--   * liste départementale `L0601@1945` jusqu'au 1er janvier 1958 ;
--   * 4e circonscription de 1958 (`06-04@1958`) jusqu'au 24 novembre 1986 :
--     l'atlas range le canton de Tende dans la 4e (`circo/composition_1958_1986.csv`,
--     « sans unité en base » parce que le canton n'avait pas d'atome), où
--     sont aussi les trois communes de Breil.
-- LE MÊME DÉFAUT AILLEURS : PONT-DE-BUIS-LÈS-QUIMERCH (29). Cherché sur tous
-- les mouvements INSEE depuis 1943 (§ 3) : une commune d'après mouvement
-- qu'aucun atome ne porte un an après l'effet, et qu'un atome porte plus
-- tard. Hors arrondissements de Marseille et de Lyon (portés avant 1999 par
-- les fractions de la ville : voulu), il n'en sort qu'une autre. Quimerch
-- (`28470`) et Logonna-Quimerch (`19825`) s'arrêtent au 1er janvier 1965,
-- à leur fusion dans Pont-de-Buis (1er février 1965, mod 31) ; l'atome
-- `S29302` (posé par `21`) ne commence qu'en 1986 (circonscription) et
-- 1992 (canton). Vingt ans sans territoire, puis six ans sans canton.
-- Posé : canton du Faou (`2914`) du 1er janvier 1965 au 22 mars 1992,
-- 6e circonscription de 1958 (`29-06@1958`) jusqu'au 24 novembre 1986 —
-- ceux des deux communes absorbées jusqu'en 1965, et ceux de Pont-de-Buis
-- en 1986-1992 (la 6e de 1986, le canton du Faou) : même unité aux deux
-- bouts, règle de `120`. La borne du 1er janvier 1965 est celle où les
-- deux atomes absorbés s'arrêtent : pas de mois sans rien.
--
-- CE QUE CE FICHIER NE FAIT PAS. Les trous cantonaux des villes coupées
-- entre 1968 et 1998 (Brest, Aubervilliers… environ 230 communes où une
-- fraction a sa circonscription et aucun atome de la ville son canton) ne
-- sont pas du même ordre : la mère perd son canton à la division, les
-- fractions ne le reçoivent qu'au relais de `24` ou de `95`, et le tracé
-- entre les deux reste à faire (`coupes_ville.csv`, `p137_reste`). Ni les
-- lacunes de 1958-1986 que l'atlas n'a pas lues (Jura, Haute-Saône, les
-- cantons divisés de `circo/composition_1958_etat.csv`).
--
-- Réversible : `p143_trace`. Rejouable (la trace est retirée avant le
-- calcul). Après `142`.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p143_trace (
    quoi text NOT NULL,              -- 'membership', 'retire'
    cle  text NOT NULL,
    atom_id text, unit_id text, niveau text,
    ancien_from date, ancien_to date,
    regle text,
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
 WHERE EXISTS (SELECT 1 FROM p143_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT cle::bigint, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p143_trace WHERE quoi = 'retire';
DELETE FROM p143_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- ---------------------------------------------------------------------------
-- 1. Mère et fractions
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t143_mere;
CREATE TEMP TABLE t143_mere AS
SELECT a.atom_id AS mere
  FROM atom a
 WHERE NOT a.fraction
   AND EXISTS (SELECT 1 FROM atom f WHERE f.fraction AND f.cassini = a.atom_id);

DROP TABLE IF EXISTS t143_agg;
CREATE TEMP TABLE t143_agg AS
SELECT x.mere, n.niveau,
       coalesce((SELECT range_agg(m.periode) FROM membership m
                  WHERE m.atom_id = x.mere AND m.niveau = n.niveau), '{}') AS m_mr,
       coalesce((SELECT range_agg(m.periode) FROM membership m JOIN atom f USING (atom_id)
                  WHERE f.fraction AND f.cassini = x.mere AND m.niveau = n.niveau), '{}') AS f_mr
  FROM t143_mere x CROSS JOIN (VALUES ('canton'), ('circo')) n(niveau);

-- la fenêtre : la mère tient L1, aucune fraction ne le tient
DROP TABLE IF EXISTS t143_piece;
CREATE TEMP TABLE t143_piece AS
WITH fen AS (
    SELECT a1.mere, a2.niveau AS l2, a1.m_mr - a1.f_mr AS w
      FROM t143_agg a1 JOIN t143_agg a2 ON a2.mere = a1.mere AND a2.niveau <> a1.niveau
)
SELECT fe.mere, fe.l2, m.membership_id, m.atom_id, m.unit_id,
       unnest(datemultirange(m.periode) * fe.w) AS p
  FROM fen fe
  JOIN atom f ON f.fraction AND f.cassini = fe.mere
  JOIN membership m ON m.atom_id = f.atom_id AND m.niveau = fe.l2;
DELETE FROM t143_piece WHERE isempty(p);

-- conflits : deux fractions dans deux unités, ou la mère dans une autre unité
DROP TABLE IF EXISTS t143_conflit;
CREATE TEMP TABLE t143_conflit AS
SELECT x.mere, x.l2, x.p * y.p AS p, x.unit_id AS u1, y.unit_id AS u2, 'fractions' AS quoi
  FROM t143_piece x JOIN t143_piece y
    ON y.mere = x.mere AND y.l2 = x.l2 AND y.unit_id > x.unit_id AND y.p && x.p
UNION ALL
SELECT x.mere, x.l2, x.p * m.periode, x.unit_id, m.unit_id, 'mere'
  FROM t143_piece x JOIN membership m
    ON m.atom_id = x.mere AND m.niveau = x.l2 AND m.periode && x.p AND m.unit_id <> x.unit_id;

-- Arbitrage (règle de `137` § 8) : deux fractions dans deux circonscriptions
-- alors que la ville entière est dans UN canton — la circonscription est celle
-- des autres communes de ce canton, si elle est unique. La mère la reçoit ;
-- les fractions perdent les leurs. Monéteau, 1986-1992.
DROP TABLE IF EXISTS t143_arb;
CREATE TEMP TABLE t143_arb AS
WITH c AS (
    SELECT mere, l2, unnest(range_agg(p)) AS p FROM t143_conflit
     WHERE quoi = 'fractions' AND l2 = 'circo' GROUP BY 1, 2
), w AS (
    SELECT c.mere, c.l2, mc.unit_id AS canton, c.p * mc.periode AS p
      FROM c JOIN membership mc ON mc.atom_id = c.mere AND mc.niveau = 'canton' AND mc.periode && c.p
)
SELECT w.mere, w.l2, w.canton, w.p, min(x.unit_id) AS unit_id, count(DISTINCT x.unit_id) AS n
  FROM w
  JOIN membership oc ON oc.unit_id = w.canton AND oc.niveau = 'canton' AND oc.periode && w.p
  JOIN atom b ON b.atom_id = oc.atom_id AND b.cassini <> w.mere
  JOIN membership x ON x.atom_id = oc.atom_id AND x.niveau = 'circo' AND x.periode && (w.p * oc.periode)
 WHERE NOT EXISTS (SELECT 1 FROM membership mm WHERE mm.atom_id = w.mere AND mm.niveau = 'circo'
                      AND mm.periode && w.p)
 GROUP BY 1, 2, 3, 4;
DELETE FROM t143_arb WHERE n <> 1 OR isempty(p)
   OR unit_id NOT IN (SELECT x.unit_id FROM t143_piece x WHERE x.mere = t143_arb.mere AND x.p && t143_arb.p);

DROP TABLE IF EXISTS t143_ok;
CREATE TEMP TABLE t143_ok AS
SELECT x.*, unnest(datemultirange(x.p)
                   - (coalesce((SELECT range_agg(c.p) FROM t143_conflit c WHERE c.mere = x.mere AND c.l2 = x.l2), '{}')
                      - coalesce((SELECT range_agg(r.p) FROM t143_arb r WHERE r.mere = x.mere AND r.l2 = x.l2), '{}'))) AS q
  FROM t143_piece x;
DELETE FROM t143_ok WHERE isempty(q);

-- ce que la mère n'a pas encore : transfert ; ce qu'elle a déjà : doublon
DROP TABLE IF EXISTS t143_pose_mere;
CREATE TEMP TABLE t143_pose_mere AS
WITH u0 AS (
    SELECT o.mere, o.l2, o.unit_id,
           datemultirange(o.q) - coalesce((SELECT range_agg(r.p) FROM t143_arb r
                                            WHERE r.mere = o.mere AND r.l2 = o.l2), '{}') AS mr
      FROM t143_ok o
    UNION ALL
    SELECT mere, l2, unit_id, datemultirange(p) FROM t143_arb
), u AS (
    SELECT mere, l2, unit_id, range_agg(r) AS mr
      FROM u0 CROSS JOIN LATERAL unnest(u0.mr) AS r GROUP BY 1, 2, 3
)
SELECT u.mere AS atom_id, u.l2 AS niveau, u.unit_id,
       unnest(u.mr - coalesce((SELECT range_agg(m.periode) FROM membership m
                                WHERE m.atom_id = u.mere AND m.niveau = u.l2), '{}')) AS p
  FROM u;
DELETE FROM t143_pose_mere WHERE isempty(p);

-- les rattachements des fractions, amputés des morceaux rendus à la mère
DROP TABLE IF EXISTS t143_retire;
CREATE TEMP TABLE t143_retire AS
SELECT m.membership_id, m.atom_id, m.unit_id, m.niveau, m.valid_from, m.valid_to,
       datemultirange(m.periode) - r.mr AS reste
  FROM membership m
  JOIN (SELECT membership_id, range_agg(q) AS mr FROM t143_ok GROUP BY 1) r USING (membership_id);

DROP TABLE IF EXISTS t143_reste;
CREATE TEMP TABLE t143_reste AS
SELECT atom_id, unit_id, niveau, unnest(reste) AS p FROM t143_retire;
DELETE FROM t143_reste WHERE isempty(p);

\echo ''
\echo '=== 1. Villes dont la mère tient une couche et les fractions l''autre (attendu : 5 villes) ==='
SELECT o.mere, a.insee_geofla, o.l2 AS couche_rendue,
       string_agg(DISTINCT o.unit_id, ' ') AS unites,
       min(lower(o.q)) AS du, max(upper(o.q)) AS au,
       string_agg(DISTINCT o.atom_id, ' ') AS fractions,
       (SELECT count(*) FROM t143_pose_mere p WHERE p.atom_id = o.mere AND p.niveau = o.l2) AS transferts
  FROM t143_ok o JOIN atom a ON a.atom_id = o.mere
 GROUP BY o.mere, a.insee_geofla, o.l2 ORDER BY 5;

\echo ''
\echo '=== 1 bis. Posé sur la mère (transfert) ==='
SELECT * FROM t143_pose_mere ORDER BY atom_id, p;

\echo ''
\echo '=== 1 ter. Conflits tranchés par le canton de la mère (attendu : Monéteau, 89263, 89-01@1986) ==='
SELECT r.mere, a.insee_geofla, r.canton, r.unit_id, r.p FROM t143_arb r JOIN atom a ON a.atom_id = r.mere;

\echo ''
\echo '=== 1 quater. Conflits non posés (attendu : Orléans, 45234, 1968-1973 : la mère est'
\echo '           à Orléans-Nord-Ouest quand ses fractions sont à Orléans-Est et Orléans-Ouest) ==='
SELECT c.mere, a.insee_geofla, c.l2, c.quoi, c.u1, c.u2, min(lower(c.p)) AS du, max(upper(c.p)) AS au
  FROM t143_conflit c JOIN atom a ON a.atom_id = c.mere
 WHERE NOT (c.l2 = 'canton' AND c.quoi = 'fractions')
   AND NOT EXISTS (SELECT 1 FROM t143_arb r WHERE r.mere = c.mere AND r.l2 = c.l2 AND r.p @> c.p)
 GROUP BY 1, 2, 3, 4, 5, 6 ORDER BY 1;
\echo '    … et le schéma de 1870-1940 (fractions dans des cantons différents, circonscription sur la mère) :'
SELECT count(DISTINCT mere) AS villes, min(lower(p)) AS du, max(upper(p)) AS au
  FROM t143_conflit WHERE l2 = 'canton' AND quoi = 'fractions';

-- ---------------------------------------------------------------------------
-- 2. Tende et La Brigue, 1947-1998
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t143_tende;
CREATE TEMP TABLE t143_tende (atom_id text, niveau text, unit_id text, valid_from date, valid_to date);
INSERT INTO t143_tende
SELECT a, n, u, f::date, t::date
  FROM (VALUES ('M06162'), ('M06163')) x(a)
 CROSS JOIN (VALUES
    ('canton', '0604',       '1947-09-17', '1951-09-11'),
    ('canton', '0631',       '1951-09-11', '1998-03-15'),
    ('circo',  'L0601@1945', '1947-09-17', '1958-01-01'),
    ('circo',  '06-04@1958', '1958-01-01', '1986-11-24')) y(n, u, f, t);
INSERT INTO t143_tende VALUES
    ('S29302', 'canton', '2914',       '1965-01-01', '1992-03-22'),
    ('S29302', 'circo',  '29-06@1958', '1965-01-01', '1986-11-24');

\echo ''
\echo '=== 2. Tende, La Brigue, Pont-de-Buis : ce qui sera posé ==='
SELECT * FROM t143_tende ORDER BY atom_id, niveau, valid_from;

\echo ''
\echo '=== 2 bis. Contrôles : Breil-sur-Roya en 1950 et dans la 4e en 1960 ; vie des unités ==='
SELECT 'canton 0604 au 1950-06-01' AS quoi, count(*) AS atomes FROM membership
 WHERE unit_id = '0604' AND periode @> DATE '1950-06-01'
UNION ALL
SELECT 'Breil (0604) dans 06-04@1958 au 1960-06-01', count(*) FROM membership c
  JOIN membership x ON x.atom_id = c.atom_id AND x.niveau = 'circo' AND x.unit_id = '06-04@1958'
                   AND x.periode @> DATE '1960-06-01'
 WHERE c.unit_id = '0604' AND c.periode @> DATE '1960-06-01'
UNION ALL
SELECT 'L0601@1945 au 1950-06-01', count(*) FROM membership
 WHERE unit_id = 'L0601@1945' AND periode @> DATE '1950-06-01'
UNION ALL
SELECT 'Quimerch, Logonna-Quimerch : 2914 et 29-06@1958 jusqu''au 1965-01-01', count(*) FROM membership
 WHERE atom_id IN ('28470', '19825') AND unit_id IN ('2914', '29-06@1958') AND valid_to = '1965-01-01'
UNION ALL
SELECT 'canton 2914 au 1975-06-01', count(*) FROM membership
 WHERE unit_id = '2914' AND periode @> DATE '1975-06-01';

\if :{?appliquer}
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(t.atom_id) INTO n, ex FROM t143_tende t
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = t.atom_id AND m.niveau = t.niveau
                      AND m.periode && daterange(t.valid_from, t.valid_to));
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : Tende/La Brigue déjà rattachées sur % période(s) (p. ex. %).', n, ex; END IF;
    SELECT count(*), min(p.atom_id) INTO n, ex FROM t143_pose_mere p
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
                      AND m.periode && p.p);
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % période(s) de mère déjà occupée(s) (p. ex. %).', n, ex; END IF;
END $$;

INSERT INTO p143_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to, regle)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to, 'fraction_vers_mere'
  FROM t143_retire;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t143_retire);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, lower(p), upper(p) FROM t143_reste
  RETURNING membership_id)
INSERT INTO p143_trace (quoi, cle, regle) SELECT 'membership', membership_id::text, 'fraction_reste' FROM ins;

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, lower(p), upper(p) FROM t143_pose_mere
  RETURNING membership_id)
INSERT INTO p143_trace (quoi, cle, regle) SELECT 'membership', membership_id::text, 'mere_transfert' FROM ins;

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM t143_tende
  RETURNING membership_id)
INSERT INTO p143_trace (quoi, cle, regle) SELECT 'membership', membership_id::text, 'tende_1947' FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, regle, count(*) FROM p143_trace GROUP BY 1, 2 ORDER BY 1, 2;
\endif

-- ---------------------------------------------------------------------------
-- 3. Contrôles
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Communes nées après 1943 sans rattachement à leur création (attendu après pose : arrondissements'
\echo '        de Marseille et de Lyon, et Pont-de-Buis 1949-1965, porté par Quimerch et Saint-Ségal) ==='
WITH prem AS (
    SELECT a.atom_id, a.insee_geofla, min(m.valid_from) AS d0
      FROM atom a JOIN membership m USING (atom_id) WHERE NOT a.fraction GROUP BY 1, 2
), cre AS (
    SELECT com_ap, min(date_eff) AS d FROM insee_mvt WHERE mod IN ('20', '21', '30') GROUP BY 1
)
SELECT p.atom_id, p.insee_geofla, cre.d AS creation, p.d0 AS premier_rattachement
  FROM prem p JOIN cre ON cre.com_ap = p.insee_geofla
 WHERE cre.d > '1943-01-01' AND p.d0 > cre.d + 400
   AND NOT EXISTS (SELECT 1 FROM atom b JOIN membership m USING (atom_id)
                    WHERE b.insee_geofla = p.insee_geofla AND b.atom_id <> p.atom_id
                      AND m.periode @> (cre.d + 30))
 ORDER BY 3, 1;

\echo ''
\echo '=== 3 bis. Menton, Tende, La Brigue au 1990-06-01 ==='
SELECT a.atom_id, m.niveau, m.unit_id, m.valid_from, m.valid_to
  FROM atom a JOIN membership m USING (atom_id)
 WHERE a.atom_id IN ('22015', '22015#0613', '22015#0652', 'M06162', 'M06163')
   AND m.periode @> DATE '1990-06-01'
 ORDER BY 1, 2;
\endif

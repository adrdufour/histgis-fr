-- ============================================================================
-- histgis — 141_circo_hors_departement.sql : les communes passées dans un
--           autre département ne gardent plus la circonscription de l'ancien
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/141_circo_hors_departement.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/141_circo_hors_departement.sql
--   psql -d histgis -1 -v defaire=1 -f sql/141_circo_hors_departement.sql
--
-- Relevé le 1er novembre 2026, à la demande d'Adrien : « RILLIEUX-LA-PAPE n'a
-- pas de canton en 1973 ». Sur la planche de l'Ain, Rillieux était dessinée
-- par sa circonscription (01-03@1958) sans canton de l'Ain : la base la met au
-- canton de Rillieux (6939, Rhône) dès la cession de 1967 (`121`), mais dans
-- la 3e circonscription de l'Ain jusqu'en 1986. Sur la planche du Rhône, elle
-- avait un canton et aucune circonscription.
--
-- LA CAUSE : `137` § 8, règles `circo_canton_1958` et `circo_atlas_partiel`.
-- Pour un atome à canton sans circonscription, elles prenaient le canton du
-- 1er décembre 1958 sans regarder son département. Une commune passée dans
-- un autre département après 1958 recevait donc la circonscription de
-- l'ancien — ce que `113` refusait depuis le 20 octobre 2026 (Genay,
-- Montanay, Ytres : « la vie cantonale bornée aux cantons du département »).
-- `137` est corrigé ; ce fichier corrige la base sans le rejouer (le
-- rejouer seul défairait ce que `138`-`140` ont posé par-dessus).
--
-- 1. RETIRÉ. Toute circonscription posée par `137` (`p137_trace`) sur une
--    période où le canton de l'atome est d'un autre département ; seule la
--    partie croisée est retirée. 39 lignes, 12 atomes au 1er novembre 2026 :
--      Ain → Rhône (loi n° 67-1205) : Rillieux-la-Pape, Crépieux-la-Pape,
--        Sathonay-Camp, Sathonay-Village (1967-12-31), Genay et Montanay
--        (1969-04-20, décret du 12 avril 1969, canton de Neuville) ;
--      Isère → Rhône (même loi) : cinq atomes des cantons de Meyzieu (6937)
--        et de Saint-Symphorien-d'Ozon (6938), qui avaient la 5e de l'Isère ;
--      Somme → Pas-de-Calais : Ytres (canton de Bertincourt, 1970-12-02).
--    Non touché : deux lignes de 8 jours en 1969 (78143, 78620 : canton 9103
--    de l'Essonne, circonscription 78-06@1967), qui ne viennent pas de `137`.
--
-- 2. POSÉ. Dans les trous ainsi ouverts — et dans ceux qu'avaient déjà les
--    autres atomes de ces cantons —, la règle `circo_atlas_partiel` de `137`
--    corrigée : la circonscription où l'atlas range le canton du trou
--    (`circo/composition_1958_1986.csv`), dans les départements que `113`
--    n'a pas posés, le canton étant entier dans une seule circonscription.
--    Le canton du 1er décembre 1958 compte s'il est du même département.
--    Attendu : la 7e du Rhône pour Rillieux et les Sathonay de 1973 à 1986
--    (69-07@1973), pour Genay et Montanay de 1969 à 1986 (69-07@1958 puis
--    @1973) ; la 13e (Meyzieu) et la 11e (Saint-Symphorien-d'Ozon) de 1973 à
--    1986 pour les communes cédées par l'Isère — unités 69-11@1973 et
--    69-13@1973 créées ici ; la 2e du Pas-de-Calais pour Ytres.
--    Restent sans circonscription, faute de source : Rillieux, Crépieux, les
--    Sathonay, Meyzieu et Saint-Symphorien de 1968 à 1973 — leurs cantons
--    naissent après l'atlas de 1958, qui ne les range nulle part.
--
-- Réversible : `p141_trace` (identifiants d'origine rendus). Rejouable.
-- Après `137` et `138`. Rejouer `137` demande de défaire celui-ci d'abord.
-- Depuis la RACINE du dépôt (`\copy` relatif).
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p141_trace (
    quoi text NOT NULL,              -- 'membership', 'retire', 'unit', 'version'
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
 WHERE EXISTS (SELECT 1 FROM p141_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT cle::bigint, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p141_trace WHERE quoi = 'retire';
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM p141_trace t WHERE t.quoi = 'version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM p141_trace t WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM p141_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t141_udep;
CREATE TEMP TABLE t141_udep AS
SELECT unit_id, CASE WHEN dep::text IN ('2A', '2B') THEN '20' ELSE dep::text END AS dep
  FROM unit;
CREATE INDEX ON t141_udep (unit_id);

-- 1. Les circonscriptions de `137` croisées avec un canton d'un autre département
DROP TABLE IF EXISTS t141_retire;
CREATE TEMP TABLE t141_retire AS
SELECT x.membership_id, x.atom_id, x.unit_id, x.niveau, x.valid_from, x.valid_to,
       range_agg(x.periode * c.periode) AS croise
  FROM membership x
  JOIN p137_trace t ON t.quoi = 'membership' AND t.cle = x.membership_id::text
  JOIN membership c ON c.atom_id = x.atom_id AND c.niveau = 'canton' AND c.periode && x.periode
  JOIN t141_udep dx ON dx.unit_id = x.unit_id
  JOIN t141_udep dc ON dc.unit_id = c.unit_id
 WHERE x.niveau = 'circo' AND dx.dep <> dc.dep
 GROUP BY 1, 2, 3, 4, 5, 6;

-- ce qui reste de chacune, hors de la partie croisée
DROP TABLE IF EXISTS t141_reste;
CREATE TEMP TABLE t141_reste AS
SELECT atom_id, unit_id, p
  FROM (SELECT atom_id, unit_id,
               unnest(datemultirange(daterange(valid_from, valid_to, '[)')) - croise) AS p
          FROM t141_retire) s
 WHERE NOT isempty(p);

-- 2. Les trous à combler : les atomes de ces cantons, de 1958 à 1986
DROP TABLE IF EXISTS t141_comp;
CREATE TEMP TABLE t141_comp (
    dep text, departement text, depuis int, jusqu int, reference date,
    circonscription text, canton_atlas text, canton_id text, canton_base text, note text);
\copy t141_comp FROM 'circo/composition_1958_1986.csv' WITH (FORMAT csv, HEADER true)
DROP TABLE IF EXISTS t141_etat;
CREATE TEMP TABLE t141_etat (
    dep text, departement text, depuis int, jusqu int, circos int,
    cantons_base int, posable text, raison text, atlas_sans_unite text);
\copy t141_etat FROM 'circo/composition_1958_etat.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS t141_div;
CREATE TEMP TABLE t141_div AS
SELECT DISTINCT CASE WHEN c.dep IN ('2A', '2B') THEN '20' ELSE c.dep END AS dep, c.depuis, c.canton_id,
       daterange(make_date(c.depuis, 1, 1),
                 CASE WHEN c.jusqu = 1986 THEN DATE '1986-11-24' ELSE make_date(c.jusqu, 1, 1) END) AS fen,
       c.dep || '-' || lpad(c.circonscription, 2, '0') || '@' || c.depuis AS circo,
       c.departement || ' ' || c.circonscription
           || CASE WHEN c.circonscription = '1' THEN 're' ELSE 'e' END || ' circonscription' AS nom
  FROM t141_comp c
  JOIN t141_etat e ON e.dep = c.dep AND e.depuis = c.depuis AND e.posable = 'non'
 WHERE c.canton_id <> ''
   AND NOT EXISTS (SELECT 1 FROM t141_comp x
                    WHERE x.dep = c.dep AND x.depuis = c.depuis AND x.canton_id = c.canton_id
                      AND x.circonscription <> c.circonscription);

-- les cantons touchés : ceux où l'on retire, au moment où l'on retire
DROP TABLE IF EXISTS t141_cantons;
CREATE TEMP TABLE t141_cantons AS
SELECT DISTINCT c.unit_id AS canton
  FROM t141_retire r
  JOIN membership c ON c.atom_id = r.atom_id AND c.niveau = 'canton'
                   AND c.periode && r.croise::datemultirange
  JOIN t141_udep dc ON dc.unit_id = c.unit_id
  JOIN t141_udep dx ON dx.unit_id = r.unit_id AND dx.dep <> dc.dep;

DROP TABLE IF EXISTS t141_trou;
CREATE TEMP TABLE t141_trou AS
WITH can AS (
    SELECT m.atom_id, m.unit_id AS canton, m.periode * daterange('1958-01-01', '1986-11-24') AS p
      FROM membership m
     WHERE m.niveau = 'canton' AND m.unit_id IN (SELECT canton FROM t141_cantons)
       AND m.periode && daterange('1958-01-01', '1986-11-24')
), circ AS (                        -- les circonscriptions qui resteront
    SELECT atom_id, range_agg(periode) AS mr
      FROM membership
     WHERE niveau = 'circo' AND atom_id IN (SELECT atom_id FROM can)
       AND membership_id NOT IN (SELECT membership_id FROM t141_retire)
     GROUP BY 1
    UNION ALL
    SELECT atom_id, range_agg(p) FROM t141_reste GROUP BY 1
), circ1 AS (SELECT atom_id, range_agg(r) AS mr FROM circ, unnest(mr) r GROUP BY 1)
SELECT c.atom_id, c.canton, unnest(datemultirange(c.p) - coalesce(ci.mr, '{}'::datemultirange)) AS p
  FROM can c LEFT JOIN circ1 ci USING (atom_id);
DELETE FROM t141_trou WHERE isempty(p);

DROP TABLE IF EXISTS t141_pose;
CREATE TEMP TABLE t141_pose AS
SELECT DISTINCT ON (g.atom_id, g.p, d.fen) g.atom_id, g.canton, g.p * d.fen AS p, d.circo, d.dep, d.depuis, d.nom, d.fen
  FROM t141_trou g
  JOIN t141_udep ug ON ug.unit_id = g.canton
  LEFT JOIN membership r0 ON r0.atom_id = g.atom_id AND r0.niveau = 'canton'
                         AND r0.periode @> DATE '1958-12-01'
                         AND EXISTS (SELECT 1 FROM t141_udep ur WHERE ur.unit_id = r0.unit_id AND ur.dep = ug.dep)
  JOIN t141_div d ON d.canton_id = coalesce(r0.unit_id, g.canton) AND d.fen && g.p AND d.dep = ug.dep
 ORDER BY g.atom_id, g.p, d.fen;
DELETE FROM t141_pose WHERE isempty(p);

\echo ''
\echo '=== 1. Retirés (attendu : 39 lignes, 12 atomes) ==='
SELECT a.insee_geofla, r.atom_id, r.unit_id, r.valid_from, r.valid_to, r.croise
  FROM t141_retire r JOIN atom a USING (atom_id) ORDER BY 1, 4;
SELECT count(*) AS lignes, count(DISTINCT atom_id) AS atomes FROM t141_retire;

\echo ''
\echo '=== 1 bis. Gardé de chacune, hors partie croisée ==='
SELECT * FROM t141_reste ORDER BY 1, 3;

\echo ''
\echo '=== 2. Posés, par canton et circonscription ==='
SELECT canton, circo, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(lower(p)) AS du, max(upper(p)) AS au,
       NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = circo) AS unite_neuve
  FROM t141_pose GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 2 bis. Trous laissés (pas de canton atlasé dans le département) ==='
SELECT g.canton, count(*) AS periodes, count(DISTINCT g.atom_id) AS atomes, min(lower(g.p)), max(upper(g.p))
  FROM t141_trou g
 WHERE NOT EXISTS (SELECT 1 FROM t141_pose x WHERE x.atom_id = g.atom_id AND x.p && g.p)
 GROUP BY 1 ORDER BY 1;

\if :{?appliquer}
DO $$
BEGIN
    -- après un rebuild, `137` corrigé ne pose plus rien de croisé : sans objet
    IF (SELECT count(*) FROM t141_retire) = 0 THEN
        RAISE NOTICE 'Rien à retirer : `137` est passé corrigé, ce fichier est sans objet.';
    END IF;
END $$;

INSERT INTO p141_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to
  FROM t141_retire;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t141_retire);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, 'circo', lower(p), upper(p) FROM t141_reste
  RETURNING membership_id)
INSERT INTO p141_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

-- les unités que l'atlas nomme et que la base n'a pas (comme `137`)
DROP TABLE IF EXISTS t141_unit_neuve;
CREATE TEMP TABLE t141_unit_neuve AS
SELECT DISTINCT circo AS unit_id, dep, depuis, nom, fen
  FROM t141_pose WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = circo);
INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
SELECT unit_id, 'circo', dep, split_part(unit_id, '@', 1), 'uninominal', depuis, nom, false
  FROM t141_unit_neuve;
INSERT INTO p141_trace (quoi, cle) SELECT 'unit', unit_id FROM t141_unit_neuve;
WITH ins AS (
  INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
  SELECT unit_id, nom, lower(fen), upper(fen) FROM t141_unit_neuve
  RETURNING unit_version_id)
INSERT INTO p141_trace (quoi, cle) SELECT 'version', unit_version_id::text FROM ins;

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, circo, 'circo', lower(p), upper(p) FROM t141_pose
  RETURNING membership_id)
INSERT INTO p141_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p141_trace GROUP BY 1 ORDER BY 1;
\endif

\echo ''
\echo '=== 3. Plus aucune circonscription d''un autre département que le canton (hors 78143, 78620) ==='
SELECT a.insee_geofla, c.unit_id AS canton, x.unit_id AS circo,
       lower(c.periode * x.periode) AS du, upper(c.periode * x.periode) AS au
  FROM membership x
  JOIN membership c ON c.atom_id = x.atom_id AND c.niveau = 'canton' AND c.periode && x.periode
  JOIN t141_udep dx ON dx.unit_id = x.unit_id
  JOIN t141_udep dc ON dc.unit_id = c.unit_id
  JOIN atom a ON a.atom_id = x.atom_id
 WHERE x.niveau = 'circo' AND dx.dep <> dc.dep
 ORDER BY 1, 4;

\echo ''
\echo '=== 4. Rillieux-la-Pape (29181), 1958-1990 ==='
SELECT niveau, unit_id, valid_from, valid_to FROM membership
 WHERE atom_id = '29181' AND valid_to > '1958-01-01' AND valid_from < '1990-01-01'
 ORDER BY niveau, valid_from;
\endif

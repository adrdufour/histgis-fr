-- ============================================================================
-- histgis — 123_circo_villes_partagees.sql : les villes partagées entre
--                                            plusieurs circonscriptions
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/123_circo_villes_partagees.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/123_circo_villes_partagees.sql
--   psql -d histgis -1 -v defaire=1 -f sql/123_circo_villes_partagees.sql
--
-- CE QUE CE FICHIER EST
-- =====================
-- `circo/partition_ville.csv` (Adrien, 21 octobre 2026, en cours) dit, pour
-- une ville coupée entre plusieurs cantons, dans quelle circonscription était
-- chacun de ses cantons, et quand. Une ligne par (canton, période) ;
-- `depuis`-`jusqu` sont des années incluses, `jusqu` vide = jusqu'au découpage
-- suivant (1986 → 2012).
--
-- Ce fichier lit chaque ligne, la confronte à la base et COMBLE ce qui manque.
-- Il ne remplace rien : une ligne que la base contredit est montrée
-- (recette 2, `desaccord`), pas corrigée.
--
-- LE CAS QU'IL TRAITE VRAIMENT : 1876-1940
-- =======================================
-- Sous la Troisième République, la base portait la circonscription d'une ville
-- partagée sur l'atome-MÈRE entier, dans une unité fusionnée — « Moulins
-- (1-2) », U0381@1876 — tandis que les fractions portaient les cantons. La
-- carte ne pouvait donc pas dire quelle moitié de Moulins votait dans la 1re.
-- Pour chaque ligne de cette période :
--   * la fraction `<mère>#<canton>` reçoit la circonscription `<ville>-<n>` du
--     segment en vigueur, là où la mère est dans une unité fusionnée ;
--   * la mère perd ce morceau de son appartenance fusionnée. Elle n'a alors
--     plus rien à la date, comme après 1958 où les fractions portent tout ;
--     `99` § a0 ne lui rend son sol que si elle est vivante, et elle ne l'est
--     plus : les fractions sont dessinées avec leur circonscription.
--   * TOUT OU RIEN par mère et par appartenance fusionnée : si une fraction
--     vivante de la ville n'est pas dans le CSV pour ce morceau, rien n'est
--     posé ni retiré pour la ville (recette 4) — sans quoi cette fraction
--     deviendrait blanche.
-- Les années du CSV qui tombent sur un scrutin de liste (1885-1889,
-- 1919-1928) ne posent rien : la mère y est dans `L<dep>01@1870`, unité
-- ordinaire, et ce fichier ne touche qu'aux unités fusionnées.
--
-- DEUX UNITÉS CRÉÉES, faute d'exister : Nice-2 de 1910 (U0604@1910) et Nice-1
-- de 1928 (U0603@1928). La base ne connaissait ces circonscriptions qu'à
-- travers « Nice (1-2) » et « Nice (1-2-3) » ; elles ne portent ici que leurs
-- fractions de Nice, leurs communes rurales éventuelles ne sont pas lues.
--
-- AILLEURS
-- ========
-- 1958-1986 : les fractions de 1958 sont posées par `113` (alias Nice-1 →
-- Nice-Est dans `circo/composition_1958.py`, 21 octobre 2026). Ce fichier ne
-- comble que les fractions nées après 1958 sous un canton neuf (Nice 5e et
-- 6e, 1973) : il passe APRÈS `113`. 1986, 1820, 1863 : la base avait déjà
-- tout, le fichier le vérifie.
--
-- Réversible : `circo_ville_trace` (pose, reste, retire, unit). Le fichier
-- retire sa trace avant de reposer, et se rejoue sans risque.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS circo_ville_trace (
    quoi text NOT NULL,        -- pose | reste | retire | unit
    cle  text NOT NULL,        -- membership_id, ou unit_id
    atom_id text, unit_id text, valid_from date, valid_to date,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DROP TABLE IF EXISTS t123_csv;
CREATE TEMP TABLE t123_csv (
    n serial,                  -- rang dans le CSV, en-tête non compté
    dep text, insee text, ville text, canton_id text, canton text,
    circonscription int, depuis int, jusqu int, etat text, note text);
\copy t123_csv (dep, insee, ville, canton_id, canton, circonscription, depuis, jusqu, etat, note) FROM 'circo/partition_ville.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS t123_unit_neuve;
CREATE TEMP TABLE t123_unit_neuve AS
SELECT * FROM (VALUES
    ('U0604@1910', '06', '0604', 'Nice-2', 1910, date '1910-01-01', date '1919-01-01'),
    ('U0603@1928', '06', '0603', 'Nice-1', 1928, date '1928-01-01', date '1941-01-01')
) v(unit_id, dep, code, nom, segment, du, au);

-- ---------------------------------------------------------------------------
-- Retirer la trace (défaire, ou avant de reposer)
-- ---------------------------------------------------------------------------
\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_ville_trace t
                WHERE t.quoi IN ('pose', 'reste') AND t.cle = m.membership_id::text);
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, 'circo', valid_from, valid_to
  FROM circo_ville_trace WHERE quoi = 'retire';
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_ville_trace t WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_ville_trace t WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_ville_trace;
\endif

-- ---------------------------------------------------------------------------
-- Résolution : la fraction, la fenêtre, l'unité attendue
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t123_ligne;
CREATE TEMP TABLE t123_ligne AS
SELECT c.*, f.atom_id AS fraction, f.cassini AS mere,
       daterange(make_date(c.depuis, 1, 1),
                 CASE WHEN c.jusqu IS NOT NULL THEN make_date(c.jusqu + 1, 1, 1) END) AS fenetre
  FROM t123_csv c
  LEFT JOIN atom f ON f.insee_geofla = c.insee AND f.fraction
                  AND f.atom_id = f.cassini || '#' || c.canton_id;

DROP TABLE IF EXISTS t123_version;
CREATE TEMP TABLE t123_version AS
SELECT u.unit_id, u.dep::text AS dep, u.code, u.segment_depuis, v.nom, v.periode
  FROM unit u JOIN unit_version v USING (unit_id)
 WHERE u.niveau = 'circo'
UNION ALL
-- Les unités de 1986 et de 2009 n'ont presque pas de version : leur durée est
-- celle de leurs appartenances.
SELECT u.unit_id, u.dep::text, u.code, u.segment_depuis, u.nom,
       daterange(min(m.valid_from), max(m.valid_to))
  FROM unit u JOIN membership m USING (unit_id)
 WHERE u.niveau = 'circo'
   AND NOT EXISTS (SELECT 1 FROM unit_version v WHERE v.unit_id = u.unit_id)
 GROUP BY u.unit_id, u.dep, u.code, u.segment_depuis, u.nom
UNION ALL
SELECT n.unit_id, n.dep, n.code, n.segment, n.nom, daterange(n.du, n.au)
  FROM t123_unit_neuve n
 WHERE NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = n.unit_id);

-- Une unité fusionnée : « Moulins (1-2) », « Nice (1-2-3) ».
DROP TABLE IF EXISTS t123_fusion;
CREATE TEMP TABLE t123_fusion AS
SELECT unit_id FROM unit WHERE niveau = 'circo' AND nom ~ ' \(\d+(-\d+)+\)$';

-- Le morceau attendu : fenêtre ∩ version de l'unité ∩ vie cantonale de la fraction.
--   1871-1940 : l'unité porte le nom `<ville>-<n>` ;
--   sinon     : le code `<dep>-<nn>`, du segment de la ligne à partir de 1958.
DROP TABLE IF EXISTS t123_attendu;
CREATE TEMP TABLE t123_attendu AS
WITH vie AS (
    SELECT atom_id, range_agg(periode) AS mr
      FROM membership WHERE niveau = 'canton' GROUP BY atom_id
)
SELECT l.n, l.fraction, l.mere, v.unit_id, l.depuis,
       datemultirange(l.fenetre * v.periode) * coalesce(vie.mr, '{}') AS mr,
       datemultirange(l.fenetre * v.periode) - coalesce(vie.mr, '{}') AS hors_canton
  FROM t123_ligne l
  JOIN t123_version v
    ON v.dep = l.dep AND v.periode && l.fenetre
   AND CASE WHEN l.depuis BETWEEN 1871 AND 1940
            THEN v.nom = l.ville || '-' || l.circonscription
            ELSE v.code = l.dep || '-' || lpad(l.circonscription::text, 2, '0')
                 AND (l.depuis < 1958 OR v.segment_depuis = l.depuis) END
  LEFT JOIN vie ON vie.atom_id = l.fraction
 WHERE l.fraction IS NOT NULL;

-- Ce que la base dit déjà, pour la fraction et pour sa mère.
DROP TABLE IF EXISTS t123_bilan;
CREATE TEMP TABLE t123_bilan AS
WITH fc AS (
    SELECT atom_id, unit_id, range_agg(periode) AS mr
      FROM membership WHERE niveau = 'circo' GROUP BY atom_id, unit_id
), ftout AS (
    SELECT atom_id, range_agg(periode) AS mr
      FROM membership WHERE niveau = 'circo' GROUP BY atom_id
), mere_ordinaire AS (            -- la mère dans une unité non fusionnée
    SELECT m.atom_id, range_agg(m.periode) AS mr
      FROM membership m
     WHERE m.niveau = 'circo'
       AND m.unit_id NOT IN (SELECT unit_id FROM t123_fusion)
     GROUP BY m.atom_id
)
SELECT a.n, a.fraction, a.mere, a.unit_id, a.depuis, a.hors_canton,
       a.mr * coalesce(meme.mr, '{}')                              AS deja,
       a.mr * (coalesce(tout.mr, '{}') - coalesce(meme.mr, '{}'))   AS desaccord,
       (a.mr - coalesce(tout.mr, '{}')) * coalesce(mo.mr, '{}')     AS mere_entiere,
       (a.mr - coalesce(tout.mr, '{}')) - coalesce(mo.mr, '{}')     AS a_poser
  FROM t123_attendu a
  LEFT JOIN fc meme ON meme.atom_id = a.fraction AND meme.unit_id = a.unit_id
  LEFT JOIN ftout tout ON tout.atom_id = a.fraction
  LEFT JOIN mere_ordinaire mo ON mo.atom_id = a.mere;

-- Tout ou rien, par appartenance fusionnée de la mère.
DROP TABLE IF EXISTS t123_coupe;
CREATE TEMP TABLE t123_coupe AS
WITH poses AS (
    SELECT mere, range_agg(r) AS mr
      FROM t123_bilan b, unnest(b.a_poser) r GROUP BY mere
)
SELECT m.membership_id, m.atom_id AS mere, m.unit_id, m.valid_from, m.valid_to,
       datemultirange(m.periode) * p.mr AS coupe
  FROM membership m
  JOIN poses p ON p.mere = m.atom_id
 WHERE m.niveau = 'circo' AND m.unit_id IN (SELECT unit_id FROM t123_fusion)
   AND NOT isempty(datemultirange(m.periode) * p.mr);

-- Une fraction vivante dans le morceau coupé, et qui n'y aurait rien.
DROP TABLE IF EXISTS t123_trou;
CREATE TEMP TABLE t123_trou AS
WITH vie AS (
    SELECT atom_id, range_agg(periode) AS mr
      FROM membership WHERE niveau = 'canton' GROUP BY atom_id
), couvert AS (
    SELECT f.atom_id, range_agg(r) AS mr
      FROM (SELECT b.fraction AS atom_id, r FROM t123_bilan b, unnest(b.a_poser) r
            UNION ALL
            SELECT m.atom_id, m.periode FROM membership m WHERE m.niveau = 'circo') f(atom_id, r)
     GROUP BY f.atom_id
)
SELECT c.membership_id, c.mere, c.unit_id, f.atom_id AS fraction,
       (vie.mr * c.coupe) - coalesce(cv.mr, '{}') AS sans_rien
  FROM t123_coupe c
  JOIN atom f ON f.cassini = c.mere AND f.fraction
  JOIN vie ON vie.atom_id = f.atom_id
  LEFT JOIN couvert cv ON cv.atom_id = f.atom_id
 WHERE NOT isempty((vie.mr * c.coupe) - coalesce(cv.mr, '{}'));

-- Les poses retenues : hors des villes incomplètes. Une pose sans mère
-- fusionnée (fraction née après 1958) passe telle quelle.
DROP TABLE IF EXISTS t123_pose;
CREATE TEMP TABLE t123_pose AS
SELECT b.n, b.fraction AS atom_id, b.unit_id, lower(r) AS valid_from, upper(r) AS valid_to
  FROM t123_bilan b, unnest(b.a_poser) r
 WHERE NOT EXISTS (SELECT 1 FROM t123_trou t
                    WHERE t.mere = b.mere
                      AND EXISTS (SELECT 1 FROM t123_coupe c
                                   WHERE c.membership_id = t.membership_id
                                     AND c.coupe && datemultirange(r)));
DELETE FROM t123_coupe c WHERE c.membership_id IN (SELECT membership_id FROM t123_trou);

-- ---------------------------------------------------------------------------
-- Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 1. Lignes du CSV sans fraction en base (attendu : rien) ==='
SELECT n, dep, ville, canton_id, canton, depuis, jusqu FROM t123_ligne WHERE fraction IS NULL;

\echo ''
\echo '=== 1 bis. Lignes sans unité attendue (attendu : rien) ==='
SELECT l.n, l.ville, l.canton, l.circonscription, l.depuis, l.jusqu
  FROM t123_ligne l
 WHERE l.fraction IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM t123_attendu a WHERE a.n = l.n);

\echo ''
\echo '=== 2. État ligne par ligne ==='
SELECT l.n, l.ville, l.canton_id, l.canton, l.circonscription AS circo,
       l.depuis, l.jusqu,
       CASE WHEN bool_or(NOT isempty(b.desaccord)) THEN 'desaccord'
            WHEN bool_or(NOT isempty(b.a_poser))
                 AND bool_or(p.atom_id IS NOT NULL) THEN '123'
            WHEN bool_or(NOT isempty(b.a_poser)) THEN 'ville incomplète'
            WHEN bool_or(NOT isempty(b.deja)) THEN 'deja'
            WHEN bool_or(NOT isempty(b.mere_entiere)) THEN 'commune entière'
            ELSE 'rien' END AS etat,
       string_agg(DISTINCT b.unit_id, ' ') AS unites,
       range_agg(r_dej) FILTER (WHERE r_dej IS NOT NULL)::text AS deja,
       (SELECT string_agg(DISTINCT m.unit_id || ' ' || m.valid_from || '/' || m.valid_to, ' ; ')
          FROM membership m, t123_bilan b2, unnest(b2.desaccord) d
         WHERE b2.n = l.n AND m.atom_id = l.fraction AND m.niveau = 'circo'
           AND m.periode && d) AS base_dit,
       range_agg(r_hors) FILTER (WHERE r_hors IS NOT NULL)::text AS hors_canton
  FROM t123_ligne l
  LEFT JOIN t123_bilan b ON b.n = l.n
  LEFT JOIN LATERAL unnest(b.deja) r_dej ON true
  LEFT JOIN LATERAL unnest(b.hors_canton) r_hors ON true
  LEFT JOIN LATERAL (SELECT atom_id FROM t123_pose p WHERE p.n = l.n LIMIT 1) p ON true
 GROUP BY l.n, l.ville, l.canton_id, l.canton, l.circonscription, l.depuis, l.jusqu, l.fraction
 ORDER BY l.n;

\echo ''
\echo '=== 3. Ce qui sera posé, et ce que la mère perd ==='
SELECT atom_id, unit_id, valid_from, valid_to FROM t123_pose ORDER BY atom_id, valid_from;
SELECT mere, unit_id, valid_from, valid_to, coupe::text AS retire FROM t123_coupe ORDER BY mere, valid_from;

\echo ''
\echo '=== 4. Villes incomplètes : fraction vivante sans ligne (rien posé pour ce morceau) ==='
SELECT mere, unit_id, fraction, sans_rien::text FROM t123_trou ORDER BY mere, fraction;

-- ---------------------------------------------------------------------------
-- Pose
-- ---------------------------------------------------------------------------
\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t123_pose;
    IF n = 0 THEN RAISE EXCEPTION 'Rien à poser.'; END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
    SELECT n.unit_id, 'circo', n.dep, n.code, 'uninominal', n.segment, n.nom, false
      FROM t123_unit_neuve n
     WHERE n.unit_id IN (SELECT unit_id FROM t123_pose)
       AND NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = n.unit_id)
    RETURNING unit_id
)
INSERT INTO circo_ville_trace (quoi, cle, unit_id) SELECT 'unit', unit_id, unit_id FROM ins;
INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT n.unit_id, n.nom, n.du, n.au FROM t123_unit_neuve n
 WHERE n.unit_id IN (SELECT cle FROM circo_ville_trace WHERE quoi = 'unit');

-- La mère d'abord : ses morceaux fusionnés libèrent la place.
DO $$
DECLARE c record; r daterange; id bigint;
BEGIN
    FOR c IN SELECT * FROM t123_coupe LOOP
        DELETE FROM membership WHERE membership_id = c.membership_id;
        INSERT INTO circo_ville_trace (quoi, cle, atom_id, unit_id, valid_from, valid_to)
        VALUES ('retire', c.membership_id::text, c.mere, c.unit_id, c.valid_from, c.valid_to);
        FOR r IN SELECT unnest(datemultirange(daterange(c.valid_from, c.valid_to)) - c.coupe) LOOP
            INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
            VALUES (c.mere, c.unit_id, 'circo', lower(r), upper(r))
            RETURNING membership_id INTO id;
            INSERT INTO circo_ville_trace (quoi, cle, atom_id, unit_id, valid_from, valid_to)
            VALUES ('reste', id::text, c.mere, c.unit_id, lower(r), upper(r));
        END LOOP;
    END LOOP;
END $$;

DO $$
DECLARE p record; id bigint;
BEGIN
    FOR p IN SELECT * FROM t123_pose LOOP
        INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
        VALUES (p.atom_id, p.unit_id, 'circo', p.valid_from, p.valid_to)
        RETURNING membership_id INTO id;
        INSERT INTO circo_ville_trace (quoi, cle, atom_id, unit_id, valid_from, valid_to)
        VALUES ('pose', id::text, p.atom_id, p.unit_id, p.valid_from, p.valid_to);
    END LOOP;
END $$;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM circo_ville_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 6. Unités fusionnées restées sans appartenance ==='
SELECT f.unit_id, u.nom FROM t123_fusion f JOIN unit u USING (unit_id)
 WHERE NOT EXISTS (SELECT 1 FROM membership m WHERE m.unit_id = f.unit_id)
 ORDER BY 1;
\else
\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

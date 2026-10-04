-- ============================================================================
-- histgis — 103_paris_cantons_1941_1998.sql : les cantons de Paris portés par
--                                              ses QUARTIERS, 1941-2012
--
--   psql -d histgis -f sql/103_paris_cantons_1941_1998.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/103_paris_cantons_1941_1998.sql
--
-- À blanc, tout se joue dans une transaction annulée à la fin : les recettes
-- montrent l'état d'après, la base n'est pas touchée.
--
-- DEUX TRAMES SUR LE MÊME SOL
-- ===========================
-- Paris a deux jeux d'atomes : les 20 arrondissements (762xx), qui portent les
-- cantons, et les quartiers (PQ…), qui portent les circonscriptions. Quand les
-- deux sont vivants à la même date, `carte_partition_atome` — qui ne connaît
-- pas les niveaux — partage le sol entre eux face par face. Mesuré sur
-- l'export du 3 octobre 2026 à 18 h 30 : le 17e arrondissement tombe à
-- 1,36 km² dès 1958, le 15e à 2,48 et le 18e à 1,91 dès 1986, et la carte
-- montre deux dessins de Paris qui ne coïncident pas. C'était déjà le cas de
-- 1999 à 2011 (cantons de 1999 par arrondissement, circos de 1986 par
-- quartier), et la première version de ce fichier, qui donnait les cantons de
-- 1941-1998 aux arrondissements, l'avait étendu à 1941-1998.
--
-- LA RÈGLE : UNE SEULE TRAME À LA FOIS
-- ====================================
-- De 1941 jusqu'à la fin des circonscriptions par quartier (2012), le canton
-- est porté par les QUARTIERS : chaque quartier reçoit le canton de son
-- arrondissement (même code INSEE), sur les périodes où il est rattaché à une
-- circonscription — et de 1941 à 1945, où il n'y a pas de circonscription,
-- les quartiers de 1945 le reçoivent depuis le 1er janvier 1941. Les
-- rattachements cantonaux des arrondissements sur cette fenêtre (ceux de 1999)
-- sont reportés à la fin de la fenêtre. Rien n'est perdu : le canton d'un
-- arrondissement est l'union de ses quartiers.
--
-- Le canton lui-même est l'accord des deux bouts : l'unité de 1940 et celle de
-- 1999 sont la même (7515 « Paris-01 » / « Paris 1er canton »…). Un
-- arrondissement dont les deux bouts diffèrent n'est pas traité (recette 1).
--
-- 1876-1940 n'est pas touché : les quartiers y sont entiers, et le partage
-- n'y a rien coupé.
--
-- Réversible et rejouable : `paris_cantons_trace` (rattachements posés, y
-- compris ceux de la première version) et `paris_cantons_modif` (rattachements
-- d'arrondissement raccourcis ou retirés, avec leurs bornes d'origine).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?appliquer}
\else
BEGIN;
\endif

CREATE TABLE IF NOT EXISTS paris_cantons_trace (
    membership_id bigint PRIMARY KEY,
    pose_le timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS paris_cantons_modif (
    membership_id bigint PRIMARY KEY,
    atom_id    text NOT NULL,
    unit_id    text NOT NULL,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    retire     boolean NOT NULL,
    pose_le    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 0. Défaire le passage précédent (première ou seconde version)
-- ---------------------------------------------------------------------------
DELETE FROM membership m USING paris_cantons_trace t WHERE t.membership_id = m.membership_id;
UPDATE membership m SET valid_from = t.valid_from, valid_to = t.valid_to
  FROM paris_cantons_modif t
 WHERE t.membership_id = m.membership_id AND NOT t.retire;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM paris_cantons_modif WHERE retire;
TRUNCATE paris_cantons_trace, paris_cantons_modif;

-- ---------------------------------------------------------------------------
-- 1. Les arrondissements, leur canton aux deux bouts
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t103_arr, t103_pq, t103_per, t103_fin;

CREATE TEMP TABLE t103_arr AS
SELECT a.atom_id, a.insee_geofla AS insee,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = a.atom_id
          AND m.niveau = 'canton' AND m.periode @> DATE '1940-06-01')       AS u_1940,
       (SELECT m.unit_id FROM membership m WHERE m.atom_id = a.atom_id
          AND m.niveau = 'canton' AND m.valid_from >= DATE '1941-01-01'
        ORDER BY m.valid_from LIMIT 1)                                       AS u_apres
FROM   atom a
WHERE  a.insee_geofla ~ '^751(0[1-9]|1[0-9]|20)$'
  AND  a.atom_id NOT LIKE 'P%' AND NOT a.fraction;

\echo ''
\echo '=== 1. Les arrondissements : canton en 1940 et après 1941 ==='
SELECT insee, atom_id, u_1940, u_apres,
       CASE WHEN u_1940 = u_apres THEN 'accord' ELSE 'NON TRAITÉ' END AS verdict
FROM   t103_arr ORDER BY insee;
-- Attendu : 20 lignes « accord ».

-- ---------------------------------------------------------------------------
-- 2. Les quartiers et leurs périodes de canton
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t103_pq AS
SELECT q.atom_id, r.insee, r.u_1940 AS unit_id
FROM   atom q
JOIN   t103_arr r ON r.insee = q.insee_geofla AND r.u_1940 = r.u_apres
WHERE  q.atom_id LIKE 'PQ%';

CREATE TEMP TABLE t103_per AS
-- les périodes de circonscription, à partir de 1941
SELECT p.atom_id, p.insee, p.unit_id,
       greatest(m.valid_from, DATE '1941-01-01') AS du, m.valid_to AS au
FROM   t103_pq p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
WHERE  m.valid_to > DATE '1941-01-01'
UNION ALL
-- 1941-1945 : les quartiers de 1945, depuis le 1er janvier 1941
SELECT p.atom_id, p.insee, p.unit_id, DATE '1941-01-01', min(m.valid_from)
FROM   t103_pq p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
WHERE  m.valid_from >= DATE '1941-01-01'
GROUP  BY p.atom_id, p.insee, p.unit_id
HAVING min(m.valid_from) < DATE '1946-06-01' AND min(m.valid_from) > DATE '1941-01-01';

-- La fin de la fenêtre, arrondissement par arrondissement.
CREATE TEMP TABLE t103_fin AS
SELECT insee, max(au) AS fin FROM t103_per GROUP BY insee;

\echo ''
\echo '=== 2. Couverture par les quartiers, arrondissement par arrondissement ==='
WITH j AS (
    SELECT d::date AS d FROM generate_series(DATE '1941-06-01', DATE '2011-06-01', interval '1 year') d
)
SELECT f.insee, min(p.du) AS du, f.fin AS au, count(DISTINCT p.atom_id) AS quartiers,
       (SELECT string_agg(extract(year FROM j.d)::text, ' ')
          FROM j WHERE j.d < f.fin
           AND NOT EXISTS (SELECT 1 FROM t103_per x WHERE x.insee = f.insee
                            AND j.d >= x.du AND j.d < x.au)) AS annees_sans_quartier
FROM   t103_fin f JOIN t103_per p USING (insee)
GROUP  BY f.insee, f.fin ORDER BY f.insee;
-- Attendu : 20 lignes, de 1941 à 2012, `annees_sans_quartier` vide. Une année
-- listée serait une année où l'arrondissement n'aurait plus de canton du tout.

-- ---------------------------------------------------------------------------
-- 3. Poser
-- ---------------------------------------------------------------------------
-- Les rattachements cantonaux des arrondissements dans la fenêtre : raccourcis
-- s'ils la dépassent, retirés s'ils y tiennent.
INSERT INTO paris_cantons_modif (membership_id, atom_id, unit_id, valid_from, valid_to, retire)
SELECT m.membership_id, m.atom_id, m.unit_id, m.valid_from, m.valid_to, m.valid_to <= f.fin
FROM   membership m
JOIN   t103_arr r ON r.atom_id = m.atom_id AND r.u_1940 = r.u_apres
JOIN   t103_fin f ON f.insee = r.insee
WHERE  m.niveau = 'canton'
  AND  m.valid_from >= DATE '1941-01-01' AND m.valid_from < f.fin;

DELETE FROM membership m USING paris_cantons_modif t
 WHERE t.membership_id = m.membership_id AND t.retire;
UPDATE membership m SET valid_from = f.fin
  FROM paris_cantons_modif t
  JOIN t103_arr r ON r.atom_id = t.atom_id
  JOIN t103_fin f ON f.insee = r.insee
 WHERE t.membership_id = m.membership_id AND NOT t.retire;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au FROM t103_per WHERE du < au
    RETURNING membership_id
)
INSERT INTO paris_cantons_trace (membership_id) SELECT membership_id FROM ins;

\echo ''
\echo '=== 3. Posé ==='
SELECT (SELECT count(*) FROM paris_cantons_trace)                       AS cantons_de_quartier,
       (SELECT count(*) FROM paris_cantons_modif WHERE retire)          AS arrondissements_retires,
       (SELECT count(*) FROM paris_cantons_modif WHERE NOT retire)      AS arrondissements_raccourcis;

\echo ''
\echo '=== 4. Recette : à ces dates, une seule trame vivante à Paris ? ==='
SELECT d::date AS date,
       count(DISTINCT m.atom_id) FILTER (WHERE m.atom_id LIKE 'PQ%')     AS quartiers_vivants,
       count(DISTINCT m.atom_id) FILTER (WHERE m.atom_id NOT LIKE 'P%')  AS arrondissements_vivants
FROM   unnest(ARRAY['1942-06-01','1950-06-01','1960-06-01','1990-06-01',
                    '2005-06-01','2013-06-01']::date[]) d
JOIN   membership m ON m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id AND a.insee_geofla ~ '^751'
GROUP  BY d ORDER BY d;
-- Attendu : arrondissements_vivants = 0 de 1942 à 2005, quartiers = 0 en 2013.

\if :{?appliquer}
ANALYZE membership;
\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte'
\else
ROLLBACK;
\echo ''
\echo '=== Tourné à blanc (transaction annulée) — relancer avec -1 -v appliquer=1 ==='
\endif

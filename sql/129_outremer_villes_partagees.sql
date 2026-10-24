-- ============================================================================
-- histgis — 129_outremer_villes_partagees.sql : les villes d'outre-mer
--           partagées entre plusieurs cantons ou circonscriptions
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/129_outremer_villes_partagees.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/129_outremer_villes_partagees.sql
--   psql -d histgis -1 -v defaire=1 -f sql/129_outremer_villes_partagees.sql
--
-- LE TROU
-- =======
-- `40` ne rattache une commune qu'à un canton ou une circonscription unique.
-- Les 27 communes multicantonales des quatre DOM (Saint-Denis, Fort-de-France,
-- Cayenne, Pointe-à-Pitre, Les Abymes…) n'avaient donc AUCUN canton, de 1946 à
-- 2013, et sortaient blanches ; de même Fort-de-France pour la circonscription
-- de 1986 (2e et 3e) et Saint-Denis de La Réunion pour celle de 2012 (1re et
-- 6e). Un atome par commune : la coupe intracommunale est inexprimable dans
-- `om_*` (RESTE_A_FAIRE § 0 bis b).
--
-- CE QUE CE FICHIER POSE
-- ======================
-- La convention de la métropole pour une ville non découpée — « Moulins
-- (1-2) », « Nice (1-2-3) » : une unité qui réunit les cantons (ou les
-- circonscriptions) que la ville partage, nommée pour le dire, sur la même
-- fenêtre que les autres rattachements du niveau. La ville est dessinée, sa
-- couleur ne prétend pas à un canton unique, et l'export la compte déjà parmi
-- les `n_partagees` (`om_atom.multi`).
--
-- Le nom ne donne pas le NOMBRE de cantons : c'est celui de 2015 (Saint-Denis
-- en a neuf), que la fenêtre fait remonter à 1946 ; le nombre de 1946 n'est
-- pas connu ici.
--
-- Réversible : `om_partage_trace`. Rejouable. Après `40` et `126`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS om_partage_trace (
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
DELETE FROM om_membership m
 WHERE EXISTS (SELECT 1 FROM om_partage_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.om_membership_id::text);
DELETE FROM om_unit_version v
 WHERE EXISTS (SELECT 1 FROM om_partage_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM om_unit u
 WHERE EXISTS (SELECT 1 FROM om_partage_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM om_partage_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- Les noms, écrits comme le reste du dépôt (la trame est en capitales)
DROP TABLE IF EXISTS t129_nom;
CREATE TEMP TABLE t129_nom (insee text, nom text);
INSERT INTO t129_nom VALUES
('97101','Les Abymes'), ('97105','Basse-Terre'), ('97107','Capesterre-Belle-Eau'),
('97113','Le Gosier'), ('97116','Morne-à-l''Eau'), ('97117','Le Moule'),
('97118','Petit-Bourg'), ('97120','Pointe-à-Pitre'), ('97128','Sainte-Anne'),
('97129','Sainte-Rose'),
('97209','Fort-de-France'), ('97210','Le François'), ('97213','Le Lamentin'),
('97222','Le Robert'), ('97228','Sainte-Marie'), ('97229','Schœlcher'),
('97302','Cayenne'),
('97407','Le Port'), ('97409','Saint-André'), ('97410','Saint-Benoît'),
('97411','Saint-Denis'), ('97412','Saint-Joseph'), ('97413','Saint-Leu'),
('97414','Saint-Louis'), ('97415','Saint-Paul'), ('97416','Saint-Pierre'),
('97422','Le Tampon');

-- 1. Cantons : les communes `multi` des quatre DOM sans aucun canton, sur la
--    fenêtre des cantons de `40`
DROP TABLE IF EXISTS t129_pose;
CREATE TEMP TABLE t129_pose AS
SELECT a.atom_id, a.dep, 'canton'::text AS niveau,
       a.dep || '-V' || a.atom_id AS unit_id, 'V' || a.atom_id AS code,
       NULL::text AS regime, NULL::int AS seg,
       n.nom || ' (ville à plusieurs cantons, non découpée)' AS nom,
       (SELECT min(valid_from) FROM om_membership WHERE niveau = 'canton') AS du,
       (SELECT max(valid_to)   FROM om_membership WHERE niveau = 'canton') AS au
  FROM om_atom a JOIN t129_nom n ON n.insee = a.atom_id
 WHERE a.multi AND a.dep IN ('971','972','973','974')
   AND NOT EXISTS (SELECT 1 FROM om_membership m
                    WHERE m.atom_id = a.atom_id AND m.niveau = 'canton');

-- 2. Circonscriptions : un segment de `40` (1986 ou 2012) sans rattachement,
--    alors que le fichier du ministère donne plusieurs circonscriptions
INSERT INTO t129_pose
SELECT a.atom_id, a.dep, 'circo', a.dep || '-V' || a.atom_id || '@' || s.segment,
       a.dep || '-V' || a.atom_id, 'uninominal',
       CASE s.segment WHEN '1986' THEN 1986 ELSE 2009 END,
       n.nom || ' (partagée entre les circonscriptions '
         || string_agg(DISTINCT s.circo, ', ' ORDER BY s.circo) || ')',
       CASE s.segment WHEN '1986' THEN '1986-11-24'::date ELSE '2012-06-10'::date END,
       CASE s.segment WHEN '1986' THEN '2012-06-10'::date ELSE '2013-01-01'::date END
  FROM om_atom a
  JOIN t129_nom n ON n.insee = a.atom_id
  JOIN om_circo_src s ON s.insee = a.atom_id
 WHERE a.dep IN ('971','972','973','974')
   AND NOT EXISTS (SELECT 1 FROM om_membership m
                    WHERE m.atom_id = a.atom_id AND m.niveau = 'circo'
                      AND m.valid_from = CASE s.segment WHEN '1986' THEN '1986-11-24'::date
                                                         ELSE '2012-06-10'::date END)
 GROUP BY a.atom_id, a.dep, s.segment, n.nom
HAVING count(DISTINCT s.circo) > 1;

\echo ''
\echo '=== 1. Ce qui sera posé ==='
SELECT niveau, dep, count(*) AS communes, string_agg(nom, ' ; ' ORDER BY atom_id) AS unites
  FROM t129_pose GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 2. Garde-fou : périodes déjà prises (attendu : zéro) ==='
DROP TABLE IF EXISTS t129_pris;
CREATE TEMP TABLE t129_pris AS
SELECT p.atom_id, m.unit_id FROM t129_pose p
  JOIN om_membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                      AND m.periode && daterange(p.du, p.au, '[)');
SELECT * FROM t129_pris;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t129_pris;
    IF n > 0 THEN RAISE EXCEPTION '% rattachement(s) existent déjà. Recette 2.', n; END IF;
END $$;

WITH iu AS (
    INSERT INTO om_unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
    SELECT unit_id, niveau, dep, code, regime, seg, nom FROM t129_pose
    RETURNING unit_id
), iv AS (
    INSERT INTO om_unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t129_pose
    RETURNING unit_id
)
INSERT INTO om_partage_trace (quoi, cle) SELECT 'unit', unit_id FROM iu;

WITH ins AS (
    INSERT INTO om_membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, du, au FROM t129_pose
    RETURNING om_membership_id
)
INSERT INTO om_partage_trace (quoi, cle)
SELECT 'membership', om_membership_id::text FROM ins;

ANALYZE om_unit; ANALYZE om_membership;

\echo ''
\echo '=== 3. Communes des quatre DOM sans canton ou sans circonscription (attendu : 0) ==='
SELECT a.dep, d,
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM om_membership m WHERE m.atom_id = a.atom_id
                        AND m.niveau = 'canton' AND m.periode @> d)) AS sans_canton,
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM om_membership m WHERE m.atom_id = a.atom_id
                        AND m.niveau = 'circo' AND m.periode @> d)) AS sans_circo
  FROM om_atom a, unnest(ARRAY['1950-06-01','1975-06-01','1990-06-01','2012-07-01']::date[]) d
 WHERE a.dep IN ('971','972','973','974')
 GROUP BY 1, 2 ORDER BY 1, 2;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

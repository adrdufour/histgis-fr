-- ============================================================================
-- histgis — 132_noms_cantons_yvelines.sql : les codes de canton 7801 à 7839,
--           Seine-et-Oise jusqu'en 1968, Yvelines ensuite — et leur nom
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/132_noms_cantons_yvelines.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/132_noms_cantons_yvelines.sql
--   psql -d histgis -1 -v defaire=1 -f sql/132_noms_cantons_yvelines.sql
--
-- LE DÉFAUT
-- =========
-- Le COG a réutilisé les codes de la Seine-et-Oise pour les Yvelines : `7808`
-- est Dourdan-Nord jusqu'en 1968 et Houdan ensuite, `7801` Argenteuil puis
-- Aubergenville. La base porte les deux vies sous la même unité, et ne
-- nomme que les deux bouts : versions jusqu'en 1941 (Seine-et-Oise), puis à
-- partir de 1999 (Yvelines). Entre les deux, le nom retombe sur `unit.nom`,
-- celui de la Seine-et-Oise : la carte des Yvelines de 1968 à 1998 nomme
-- « Dourdan-Nord » le canton de Houdan, « Argenteuil » celui d'Aubergenville,
-- « Magny-en-Vexin » celui de Saint-Germain-en-Laye-Nord. Vu le 25 octobre
-- 2026 dans l'export de 1980.
--
-- LA CORRECTION — des versions, aucune appartenance touchée :
--   * [fin de la dernière version, 1968-01-01) : le nom de Seine-et-Oise
--     (`unit.nom`), là où aucune version ne couvre déjà ;
--   * [1968-01-01, 1999-01-01) : le nom des Yvelines de 1999.
-- Mesuré avant d'écrire : aucune de ces unités ne porte de rattachement de
-- Seine-et-Oise après le 1er janvier 1968, ni des Yvelines avant.
-- RÉSERVE : le nom de 1999 vaut pour toute la période ; un canton renommé
-- entre 1968 et 1999 (Mantes-Gassicourt / Mantes-la-Jolie…) garde le nom de
-- 1999. C'est le nom que la base prête déjà à ces unités en 1999-2013.
--
-- Réversible : `p132_trace`. Rejouable.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p132_trace (
    cle text PRIMARY KEY, pose_le timestamptz NOT NULL DEFAULT now()
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM p132_trace t WHERE t.cle = v.unit_version_id::text);
DELETE FROM p132_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t132_unite;
CREATE TEMP TABLE t132_unite AS
SELECT u.unit_id, u.nom AS nom_seo, v.nom AS nom_yv,
       (SELECT max(w.valid_to) FROM unit_version w
         WHERE w.unit_id = u.unit_id AND w.valid_to <= '1968-01-01') AS fin_versions,
       (SELECT max(m.valid_to) FROM membership m
         WHERE m.unit_id = u.unit_id AND m.valid_from < '1968-01-01') AS fin_seo,
       (SELECT min(m.valid_from) FROM membership m
         WHERE m.unit_id = u.unit_id AND m.valid_from >= '1968-01-01') AS debut_yv
  FROM unit u
  JOIN unit_version v ON v.unit_id = u.unit_id AND v.valid_from = '1999-01-01'
 WHERE u.niveau = 'canton' AND u.dep = '78' AND u.unit_id ~ '^78[0-9]{2}$';

\echo ''
\echo '=== 1. Garde-fou : une unité qui servirait aux deux de part et d''autre de 1968 (attendu : zéro) ==='
SELECT * FROM t132_unite WHERE fin_seo > '1968-01-01' OR debut_yv < '1968-01-01';

DROP TABLE IF EXISTS t132_pose;
CREATE TEMP TABLE t132_pose AS
SELECT unit_id, nom_seo AS nom, fin_versions AS du, '1968-01-01'::date AS au
  FROM t132_unite
 WHERE fin_versions IS NOT NULL AND fin_versions < '1968-01-01'
UNION ALL
SELECT unit_id, nom_yv, '1968-01-01', '1999-01-01' FROM t132_unite;

-- les trous laissés par une version déjà présente (Écouen-Lochères, 1964-1968)
DELETE FROM t132_pose p
 WHERE EXISTS (SELECT 1 FROM unit_version v WHERE v.unit_id = p.unit_id
                  AND v.periode && daterange(p.du, p.au, '[)')
                  AND NOT EXISTS (SELECT 1 FROM p132_trace t WHERE t.cle = v.unit_version_id::text));
INSERT INTO t132_pose
SELECT u.unit_id, u.nom_seo, u.fin_versions, v.valid_from
  FROM t132_unite u JOIN unit_version v ON v.unit_id = u.unit_id
 WHERE v.valid_from > u.fin_versions AND v.valid_to <= '1968-01-01';

\echo ''
\echo '=== 2. Ce qui sera posé ==='
SELECT unit_id, nom, du, au FROM t132_pose ORDER BY 1, 3;

\if :{?appliquer}
WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, du, au FROM t132_pose
    RETURNING unit_version_id
)
INSERT INTO p132_trace (cle) SELECT unit_version_id::text FROM ins;

\echo ''
\echo '=== 3. Posé ==='
SELECT count(*) AS versions FROM p132_trace;
\else
\echo ''
\echo '=== À blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

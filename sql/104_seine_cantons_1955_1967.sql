-- ============================================================================
-- histgis — 104_seine_cantons_1955_1967.sql : les cantons de banlieue de la
--                                              Seine prolongés jusqu'en 1968
--
--   psql -d histgis -f sql/104_seine_cantons_1955_1967.sql              -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/104_seine_cantons_1955_1967.sql
--
-- LE TROU
-- =======
-- Les 80 communes de banlieue ont leur canton par le jalon de 1954 (`87`, sur
-- [1954, 1955)) et par le report arrière 1941-1953, puis plus rien jusqu'aux
-- cantons des Hauts-de-Seine, de la Seine-Saint-Denis et du Val-de-Marne.
-- `97` (deux bouts 1941-1967) laisse la Seine de côté : les cantons d'après
-- sont ceux de départements neufs, l'accord des deux bouts est impossible.
--
-- Tant que Paris n'avait pas de canton non plus, la page passait d'elle-même
-- en coloration par circonscription et le trou ne se voyait pas. `103` a donné
-- leurs cantons aux arrondissements : la couche cantonale existe désormais
-- de 1955 à 1967, avec Paris seul, et la banlieue y paraît sans canton.
--
-- CE QUE CE FICHIER FAIT — ET C'EST UNE HYPOTHÈSE
-- ===============================================
-- Il prolonge le canton de 1954 de chaque commune jusqu'au 1er janvier 1968
-- — début du jalon cantonal des Hauts-de-Seine, de la Seine-Saint-Denis et du
-- Val-de-Marne (`59`) — ou jusqu'à son rattachement cantonal suivant s'il
-- commence avant.
--
-- Première version (3 octobre 2026) : « jusqu'au rattachement suivant, s'il
-- commence entre 1955 et 1969 ». 25 communes sur 80 restaient sans canton —
-- Puteaux, Boulogne, Saint-Denis… — parce que leur rattachement suivant
-- n'arrive qu'en 1994-1998, ou jamais : les communes multicantonales de 1968
-- passent en fractions, et l'atome-commune n'a plus de canton à lui. C'est l'hypothèse que `88` fait déjà pour les
-- circonscriptions — « la composition n'est lue qu'à 1954 et projetée » — et
-- que `RESTE_A_FAIRE.md` § 4 bis inscrit comme « Confirmer la stabilité
-- cantonale 1945-1968 ». Elle tombe si un canton de banlieue a été remanié
-- entre 1955 et 1967 : la recette 2 donne de quoi le vérifier.
--
-- Réversible et rejouable : `seine_cantons_1955_trace`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS seine_cantons_1955_trace (
    membership_id bigint PRIMARY KEY,
    pose_le timestamptz NOT NULL DEFAULT now()
);

DROP TABLE IF EXISTS t104_m, t104_pose;

-- Le canton de 1954 de chaque commune de banlieue (unité de la Seine), hors
-- Paris, hors ce que ce fichier a posé.
CREATE TEMP TABLE t104_m AS
SELECT m.membership_id, m.atom_id, m.unit_id, u.nom AS canton, m.valid_to
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
JOIN   atom a ON a.atom_id = m.atom_id
WHERE  m.niveau = 'canton' AND u.dep = '75'
  AND  m.periode @> DATE '1954-06-01'
  AND  coalesce(a.insee_geofla, '') !~ '^751'
  AND  NOT EXISTS (SELECT 1 FROM seine_cantons_1955_trace t
                   WHERE t.membership_id = m.membership_id);

CREATE TEMP TABLE t104_pose AS
SELECT b.atom_id, b.unit_id, b.canton, b.valid_to AS du,
       (SELECT min(m2.valid_from) FROM membership m2
         WHERE m2.atom_id = b.atom_id AND m2.niveau = 'canton'
           AND m2.valid_from >= b.valid_to
           AND NOT EXISTS (SELECT 1 FROM seine_cantons_1955_trace t
                           WHERE t.membership_id = m2.membership_id)) AS suivant
FROM   t104_m b;
ALTER TABLE t104_pose ADD COLUMN au date;
UPDATE t104_pose SET au = least(coalesce(suivant, DATE '1968-01-01'), DATE '1968-01-01');

\echo ''
\echo '=== 1. Ce qui sera posé ==='
SELECT count(*) FILTER (WHERE au > du)                         AS prolonges,
       count(*) FILTER (WHERE suivant IS NULL)                    AS sans_canton_ensuite,
       count(*) FILTER (WHERE suivant > DATE '1968-01-01')        AS reprise_apres_1968,
       min(du) AS depuis, min(au) AS jusqu_au_plus_tot, max(au) AS jusqu_au_plus_tard
FROM   t104_pose;
-- Attendu : 80 prolongés, depuis 1955-01-01, jusqu'au 1968-01-01.

\echo ''
\echo '=== 2. Pour juger l hypothèse : canton de 1954 → canton suivant ==='
SELECT p.canton AS canton_1954, u2.dep, u2.nom AS canton_suivant, count(*) AS communes
FROM   t104_pose p
JOIN   membership m2 ON m2.atom_id = p.atom_id AND m2.niveau = 'canton' AND m2.valid_from = p.suivant
JOIN   unit u2 ON u2.unit_id = m2.unit_id AND u2.niveau = m2.niveau
GROUP  BY 1, 2, 3 ORDER BY 1, 3;
-- Les cantons de 1967 découpent ceux de 1954 : cette table montre comment.
-- Elle ne prouve pas la stabilité 1955-1967, elle permet de la discuter.

\echo ''
\echo '=== 3. Garde-fou : la période est-elle libre ? ==='
SELECT p.atom_id, m.unit_id, m.periode
FROM   t104_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.du, p.au, '[)')
WHERE  p.au > p.du
  AND  NOT EXISTS (SELECT 1 FROM seine_cantons_1955_trace t
                   WHERE t.membership_id = m.membership_id);
-- Attendu : aucune ligne (ce que ce fichier a déjà posé n'y compte pas).

\if :{?appliquer}

DELETE FROM membership m USING seine_cantons_1955_trace t
 WHERE t.membership_id = m.membership_id;
TRUNCATE seine_cantons_1955_trace;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', du, au
    FROM   t104_pose
    WHERE  au > du
    RETURNING membership_id
)
INSERT INTO seine_cantons_1955_trace (membership_id) SELECT membership_id FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 4. Posé ==='
SELECT count(*) AS rattachements_poses FROM seine_cantons_1955_trace;

\echo ''
\echo 'Ensuite : python3 cartes/export_web.py 75 --partition --role histgis_carte'
\echo '          (et 92 93 94 si leurs cartes doivent montrer la Seine d avant 1968)'

\else
\echo ''
\echo '=== Tourné à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

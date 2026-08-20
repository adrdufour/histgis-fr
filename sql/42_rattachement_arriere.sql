-- ============================================================================
-- 42_rattachement_arriere.sql — rattacher le passé d'un atome qui existe déjà
--
--   psql -d histgis -f sql/42_rattachement_arriere.sql
--
-- Le défaut, trouvé le 17 août 2026 par Chisa
-- -------------------------------------------
-- Adrien : « la commune de Chisa est absente de la Corse 1870-1940 ».
--
-- Elle n'est pas absente de la base : elle y est **depuis 1986**, portée par
-- l'atome `M2B366` que `21_atomes_modernes.sql` a créé. Ce qui manque, ce n'est
-- pas le polygone, c'est le rattachement d'avant sa naissance.
--
-- Chisa a été créée le 12 avril 1947 par détachement de **Ventiseri**
-- (`insee_mvt`, mod 20). Avant cette date, son territoire était corse, français,
-- et relevait du canton de Ventiseri. Il doit donc porter la chronologie de
-- Ventiseri jusqu'en 1947.
--
-- Butry-sur-Oise est le cas jumeau : créée le 1er août 1948 par détachement
-- d'Auvers-sur-Oise, portée par `M95120`.
--
-- Pourquoi `15` ne peut pas les traiter
-- -------------------------------------
-- `15_creation_arriere.sql` fait exactement ce travail, mais seulement pour les
-- communes dont **aucun atome ne porte le polygone** : il en crée un, puis lui
-- recopie la chronologie de la mère. Son test de sélection demande « ce
-- territoire est-il porté par un atome ? ».
--
-- Chisa et Butry y répondent OUI depuis `21`. Et elles y répondent oui
-- **précisément parce que `15` avait échoué sur elles** : leur mouvement de
-- création nomme `20366` et `78692`, codes d'avant le recodage de la Corse
-- (1976) et le démembrement de la Seine-et-Oise (1968), que `15` comparait au
-- code GEOFLA moderne. N'ayant pas d'atome `N`, elles ont reçu un atome `M` de
-- `21`, qui les a crues neuves. Les deux fichiers se sont partagé le territoire
-- sans se voir.
--
-- `15` résout désormais les codes (garde-fou 6), mais cela ne suffit plus : le
-- test de la section 1 les écarte avant le raccord. Lui faire poser des
-- rattachements sur des atomes qu'il n'a pas créés romprait son contrat — « je
-- crée mes atomes, je les retire ». D'où ce fichier, additif et tracé.
--
-- La règle
-- --------
--   « Un atome dont le polygone est celui d'une commune à la création
--     DOCUMENTÉE, et qui n'a aucun rattachement avant cette création, reçoit la
--     chronologie de sa mère pour toute la période antérieure. »
--
-- C'est mot pour mot le pari de `11` et de `15`, appliqué à un atome existant
-- au lieu d'un atome créé. La filiation est **donnée par la source**, comme en
-- `41` : `insee_mvt` nomme `com_av` et `date_eff`.
--
-- Ce qui est DÉLIBÉRÉMENT laissé de côté
-- --------------------------------------
-- **Tende et La Brigue.** Elles figurent dans la même liste — créées le
-- 1947-09-17, aucun rattachement en 1870 — et elles doivent y rester. Leur
-- mouvement INSEE a un `com_av` **VIDE** : le territoire vient d'Italie, il n'y
-- a pas de commune mère, et la source le dit. Le garde-fou 1 les écarte sans
-- qu'on ait à les nommer. 271,1 km² qui ne sont pas un défaut de la base mais
-- un fait de l'histoire.
--
-- **Stuckange.** Sa mère est Kuntzig, qui est elle-même sans rattachement en
-- 1870. Le garde-fou 4 la laisse : une mère qui n'a rien ne transmet rien.
--
-- **Chamrousse.** Elle relève de `15`, pas d'ici — son polygone n'est porté que
-- par les débris d'un passage précédent de `15`, dont le nettoyage a été
-- corrigé le même jour. Rejouer `15` puis `24` la rétablit.
--
-- Cinq garde-fous
-- ---------------
--   1. `com_av` non vide : pas de filiation, pas de recopie. C'est Tende.
--   2. Les codes sont résolus à travers les recodages `mod 41`, aux deux bouts.
--      Sans cela, ni la fille ni la mère ne se retrouvent.
--   3. On ne pose rien sur une période déjà occupée.
--   4. On ne pose que ce que la mère porte réellement.
--   5. Rien après la date de création : le territoire cesse d'être à la mère le
--      jour où la fille naît. La borne est la date exacte, pas l'année.
--
-- Réversible : `rattachement_arriere_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- Prérequis : `15` joué (il construit `creation_recodage`), `21`, `24`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.creation_recodage') IS NULL THEN
        RAISE EXCEPTION '15_creation_arriere.sql doit être joué avant : il '
                        'construit creation_recodage, la résolution des codes.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rattachement_arriere_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    insee         char(5) NOT NULL,   -- la commune née après la série
    insee_mere    char(5) NOT NULL,
    creee_le      date NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM rattachement_arriere_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE rattachement_arriere_trace;

-- ---------------------------------------------------------------------------
-- 1. Les cas : création documentée, atome existant, aucun rattachement au
--    début de la série
--
-- Le test porte sur le RATTACHEMENT à une date, pas sur l'existence d'un
-- atome. C'est la correction de fond : un atome sans rattachement couvre
-- géométriquement et ne couvre rien dans le temps.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ra_cas;
CREATE TEMP TABLE ra_cas AS
WITH debut AS (
    SELECT min(valid_from) AS d0 FROM membership
),
-- garde-fou 2 : les deux bouts résolus à travers les recodages
mvt AS (
    SELECT coalesce(rp.moderne, i.com_ap) AS insee,
           coalesce(rv.moderne, i.com_av) AS insee_mere,
           i.com_av                       AS insee_mere_source,
           i.date_eff                     AS creee_le,
           i.libelle_av                   AS nom_mere
      FROM insee_mvt i
      LEFT JOIN creation_recodage rp ON rp.ancien = i.com_ap
      LEFT JOIN creation_recodage rv ON rv.ancien = i.com_av
     WHERE i.mod IN ('20', '21')
       -- garde-fou 1 : une création ex nihilo n'a pas de mère. Tende et La
       -- Brigue, venues d'Italie en 1947, sont écartées ici et doivent l'être.
       AND i.com_av IS NOT NULL
       AND btrim(i.com_av) <> ''
       AND i.com_av IS DISTINCT FROM i.com_ap
),
-- la création la plus ancienne : celle qui détache le territoire
premier AS (
    SELECT DISTINCT ON (insee) insee, insee_mere, insee_mere_source,
           creee_le, nom_mere
      FROM mvt ORDER BY insee, creee_le
)
SELECT p.*, a.atom_id, d.d0 AS depuis
  FROM premier p
  CROSS JOIN debut d
  -- l'atome qui porte le polygone de la fille, quelle que soit sa provenance
  JOIN geofla_commune g ON g.insee_com = p.insee
  JOIN atom_geom ag ON ag.geom && g.geom
                   AND ST_Contains(ag.geom, ST_PointOnSurface(g.geom))
  JOIN atom a ON a.atom_id = ag.atom_id
 WHERE p.creee_le > d.d0
   -- aucun rattachement de canton au début de la série : c'est le trou
   AND NOT EXISTS (
       SELECT 1 FROM membership m
        WHERE m.atom_id = a.atom_id
          AND m.niveau  = 'canton'
          AND m.periode @> d.d0);

\echo ''
\echo '=== 1. Les cas retenus ==='
SELECT c.insee, coalesce(n.nom, '?') AS commune, c.atom_id,
       c.insee_mere, c.insee_mere_source AS mere_dans_l_acte, c.nom_mere,
       c.creee_le
  FROM ra_cas c
  LEFT JOIN noms_geofla n ON n.insee = c.insee
 ORDER BY c.creee_le, c.insee;
-- Attendu le 17 août 2026 : Chisa 2B366 et Butry-sur-Oise 95120.
-- Tende et La Brigue NE doivent PAS y figurer — com_av vide, garde-fou 1.

-- ---------------------------------------------------------------------------
-- 2. Ce que la mère portait avant la création
--
-- L'intersection avec `[début, création)` fait tout le travail du garde-fou 5 :
-- on ne prend jamais plus que ce que la mère avait, ni plus que la fenêtre.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ra_periode;
CREATE TEMP TABLE ra_periode AS
SELECT c.atom_id,
       mm.unit_id,
       mm.niveau,
       lower(mm.periode * daterange(c.depuis, c.creee_le, '[)')) AS valid_from,
       upper(mm.periode * daterange(c.depuis, c.creee_le, '[)')) AS valid_to,
       c.insee, c.insee_mere, c.creee_le
  FROM ra_cas c
  -- l'atome de la MÈRE : par le code GEOFLA, résolu
  JOIN atom am ON am.insee_geofla = c.insee_mere AND NOT am.fraction
  JOIN membership mm ON mm.atom_id = am.atom_id
                    AND mm.periode && daterange(c.depuis, c.creee_le, '[)')
 WHERE NOT isempty(mm.periode * daterange(c.depuis, c.creee_le, '[)'));

-- Garde-fou 3 : ne rien poser sur une période déjà occupée.
DELETE FROM ra_periode p
 WHERE EXISTS (
    SELECT 1 FROM membership m
     WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
       AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

-- Plusieurs atomes-mères possibles : une seule ligne par (atome, niveau,
-- période), sans quoi la contrainte EXCLUDE ferait échouer la transaction.
DELETE FROM ra_periode a
 USING ra_periode b
 WHERE a.atom_id = b.atom_id AND a.niveau = b.niveau
   AND a.valid_from = b.valid_from
   AND a.unit_id > b.unit_id;

\echo ''
\echo '=== 2. Ce qui va être posé ==='
SELECT niveau, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM ra_periode GROUP BY niveau ORDER BY niveau;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to
      FROM ra_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO rattachement_arriere_trace (membership_id, atom_id, unit_id, niveau,
                                        valid_from, valid_to, insee, insee_mere,
                                        creee_le)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.insee, p.insee_mere, p.creee_le
  FROM ins i
  JOIN ra_periode p ON p.atom_id = i.atom_id
                   AND p.niveau  = i.niveau
                   AND p.valid_from = i.valid_from
                   AND p.unit_id = i.unit_id;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Posé, par commune ==='
SELECT t.insee, coalesce(n.nom, '?') AS commune, t.atom_id, t.insee_mere,
       t.creee_le, count(*) AS lignes,
       string_agg(DISTINCT t.niveau, ', ') AS niveaux,
       min(t.valid_from) AS depuis, max(t.valid_to) AS jusqu_a
  FROM rattachement_arriere_trace t
  LEFT JOIN noms_geofla n ON n.insee = t.insee
 GROUP BY 1, 2, 3, 4, 5 ORDER BY t.creee_le, t.insee;

\echo ''
\echo '=== 4. Chisa, le cas qui a révélé le défaut ==='
SELECT m.niveau, m.unit_id, u.nom, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 42' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN rattachement_arriere_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '2B366'
 ORDER BY m.niveau, m.valid_from;
-- Attendu : le canton de Ventiseri — Prunelli-di-Fiumorbo — depuis 1870, et
-- l'alternance liste/uninominal pour la circonscription.

\echo ''
\echo '=== 5. Aucun atome dans deux unités du même niveau à la même date ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode
          FROM membership GROUP BY 1, 2, 3
        HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY niveau;
-- Attendu : aucune ligne.

\echo ''
\echo '=== 6. Aucun polygone réclamé deux fois — recette GÉOMÉTRIQUE ==='
\echo '    Ce fichier ne crée AUCUN atome ni AUCUNE géométrie : il ne peut pas'
\echo '    doubler une surface. La recette est là parce que la leçon de 41 est'
\echo '    récente et que l''affirmation doit être vérifiée, pas crue.'
SELECT count(*) AS polygones_reclames_deux_fois
  FROM rattachement_arriere_trace t
  JOIN atom_geom gt ON gt.atom_id = t.atom_id
  JOIN atom_geom gj ON gj.atom_id <> t.atom_id
                   AND md5(ST_AsEWKB(gj.geom)) = md5(ST_AsEWKB(gt.geom))
  JOIN membership m ON m.atom_id = gj.atom_id
                   AND m.niveau  = t.niveau
                   AND m.periode && daterange(t.valid_from, t.valid_to, '[)');

\echo ''
\echo '=== 7. Ce qui reste NON COUVERT au début de la série ==='
\echo '    Tende et La Brigue doivent y rester : italiennes jusqu''en 1947,'
\echo '    sans commune mère dans la source. Ce n''est pas un défaut.'
SELECT g.code_dept AS dep, g.insee_com, g.nom_comm,
       round((ST_Area(g.geom) / 1e6)::numeric, 1) AS km2
  FROM geofla_commune g
 WHERE NOT EXISTS (
       SELECT 1 FROM atom_geom ag
         JOIN membership m ON m.atom_id = ag.atom_id
                          AND m.niveau  = 'canton'
                          AND m.periode @> (SELECT min(valid_from) FROM membership)
        WHERE ag.geom && g.geom
          AND ST_Contains(ag.geom, ST_PointOnSurface(g.geom)))
 ORDER BY km2 DESC LIMIT 15;

-- ---------------------------------------------------------------------------
-- 5. Pour défaire
--
--   DELETE FROM membership m USING rattachement_arriere_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE rattachement_arriere_trace;
-- ---------------------------------------------------------------------------

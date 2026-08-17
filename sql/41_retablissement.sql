-- ============================================================================
-- 41_retablissement.sql — les communes rétablies après 1999
--
--   psql -d histgis -f sql/41_retablissement.sql
--
-- Le défaut, trouvé le 17 août 2026 par Ouézy
-- -------------------------------------------
-- Ouézy (14482), dans le Calvados, est absente de la base entre 1999 et 2006.
-- Ce n'est pas une erreur : **elle n'existait pas**. `insee_mvt` le dit sans
-- ambiguïté :
--
--   1972-01-01  mod 33  14482 Ouézy -> 14149 Cesny-aux-Vignes-Ouézy
--   2006-01-01  mod 21  14149 Cesny-aux-Vignes-Ouézy -> 14482 Ouézy
--
-- Fusionnée-associée en 1972 sous la loi Marcellin, rétablie en 2006. Le COG de
-- 1999 ne connaît que 14149, et la base le suit fidèlement.
--
-- **Mais son polygone, lui, existe.** GEOFLA 2011 porte 14482 séparément,
-- puisque le rétablissement est antérieur au millésime. Entre 1999 et 2006, ce
-- polygone n'a donc aucun rattachement : un trou de couverture de la taille de
-- la commune, dans la couche moderne.
--
-- C'est le MIROIR exact du défaut d'Arrien-en-Bethmale, corrigé par
-- `40_scission_circo.sql`. Là, une commune née après le début de la série
-- laissait un trou en amont ; ici, une commune disparue puis rétablie laisse un
-- trou en aval. `11_scission.sql` prolonge vers l'arrière ; rien ne prolongeait
-- vers l'avant.
--
-- L'ampleur, mesurée avant d'écrire
-- ---------------------------------
--   66 communes de GEOFLA 2011 sont absentes du COG 1999
--   21 d'entre elles sont des RÉTABLISSEMENTS datés (mod 21), de 2000 à 2008
--
-- Bercenay-le-Hayer et Trancault (2000), Ousse, Sendets, Ruffiac, Plottes,
-- Draillant (2001), Mauvezin-sur-Gupie (2003), Brabant et Brocourt-en-Argonne
-- (2004), Trémilly (2005), Ouézy et Cuislès (2006), Bosselshausen (2007),
-- Liéoux, Saint-Symphorien, Verquigneul, Rosoy (2008) — la queue des fusions
-- Marcellin de 1971-72, défaites une à une.
--
-- Les 45 autres ne sont pas des rétablissements et ne sont pas traitées ici :
-- elles relèvent d'autres mécanismes, à examiner séparément.
--
-- La règle, et pourquoi elle est plus sûre que celle de 40
-- -------------------------------------------------------
--   « Entre le début de la couche moderne et sa date de rétablissement, la
--     commune reçoit les rattachements de la commune qui l'absorbait. »
--
-- Ici **la filiation est donnée par la source**, elle n'est pas déduite.
-- `insee_mvt` nomme explicitement la commune absorbante (`com_av`) et la date
-- (`date_eff`). Là où `40` devait passer par les voisins de canton et se
-- contenter d'une unanimité, `41` lit un fait.
--
-- Ce qu'on suppose quand même : que le territoire de la commune associée
-- suivait le rattachement de la commune absorbante. C'est vrai par
-- construction — une commune associée n'a pas de rattachement propre, elle est
-- une fraction de l'absorbante — donc l'hypothèse est ici plus faible que
-- partout ailleurs dans la chaîne.
--
-- Quatre garde-fous
-- -----------------
--   1. Seuls les mouvements `mod = '21'` (rétablissement) postérieurs à 1999.
--   2. `com_av <> com_ap` : `insee_mvt` écrit aussi une ligne où la commune
--      rétablie figure des deux côtés, et la prendre ferait hériter la commune
--      d'elle-même.
--   3. On ne pose rien sur une période déjà occupée. La contrainte EXCLUDE le
--      refuserait, mais autant ne pas lui faire annuler la transaction.
--   4. On ne pose que si l'absorbante a effectivement un rattachement sur la
--      période. Sans quoi il n'y a rien à hériter, et on se tait.
--
-- Réversible : tout est tracé dans `retablissement_trace`, section 6.
-- Rejouable : le script retire ses propres lignes avant de recommencer.
-- Prérequis : la couche moderne chargée (`20`, `21`, `24`) et `insee_mvt` (06).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE EXCEPTION 'insee_mvt absente : jouer 06_insee_mvt.sql avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS retablissement_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    insee         char(5) NOT NULL,   -- la commune rétablie
    insee_mere    char(5) NOT NULL,   -- celle qui l'absorbait
    retablie_le   date NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM retablissement_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE retablissement_trace;

-- ---------------------------------------------------------------------------
-- 1. Les rétablissements, et leur commune absorbante
--
-- Une commune peut avoir été rétablie en plusieurs temps ; on retient le
-- PREMIER rétablissement postérieur au début de la couche moderne, celui qui
-- ferme la fenêtre à combler.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ret_cas;
CREATE TEMP TABLE ret_cas AS
WITH debut AS (
    -- le début de la couche moderne, lu et non supposé
    SELECT min(m.valid_from) AS d0
      FROM membership m
      JOIN atom a USING (atom_id)
     WHERE m.valid_from >= DATE '1990-01-01'
),
brut AS (
    SELECT v.com_ap                       AS insee,
           v.com_av                       AS insee_mere,
           v.date_eff                     AS retablie_le,
           row_number() OVER (PARTITION BY v.com_ap ORDER BY v.date_eff) AS rang
      FROM insee_mvt v, debut
     WHERE v.mod = '21'                          -- rétablissement
       AND v.com_av <> v.com_ap                  -- garde-fou 2
       AND v.date_eff > debut.d0
)
SELECT b.insee, b.insee_mere, b.retablie_le, d.d0 AS depuis
  FROM brut b, debut d
 WHERE b.rang = 1;

\echo ''
\echo '=== 1. Les cas retenus ==='
SELECT c.insee, coalesce(n.nom, '?') AS commune,
       c.insee_mere, coalesce(nm.nom, '?') AS mere,
       c.depuis, c.retablie_le
  FROM ret_cas c
  LEFT JOIN noms_geofla n  ON n.insee  = c.insee
  LEFT JOIN noms_geofla nm ON nm.insee = c.insee_mere
 ORDER BY c.retablie_le, c.insee;

-- ---------------------------------------------------------------------------
-- 2. Ce que l'absorbante portait sur la fenêtre, découpé à la fenêtre
--
-- `*` intersecte deux `daterange` : le rattachement de la mère et la fenêtre
-- [début de la couche moderne, rétablissement). On ne prend donc jamais plus
-- que ce que la mère avait, ni plus que la fenêtre.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ret_periode;
CREATE TEMP TABLE ret_periode AS
SELECT af.atom_id                                   AS atom_id,
       mm.unit_id,
       mm.niveau,
       lower(mm.periode * daterange(c.depuis, c.retablie_le, '[)')) AS valid_from,
       upper(mm.periode * daterange(c.depuis, c.retablie_le, '[)')) AS valid_to,
       c.insee, c.insee_mere, c.retablie_le
  FROM ret_cas c
  -- l'atome de la commune RÉTABLIE, celui qui porte le polygone orphelin
  JOIN atom af ON af.insee_geofla = c.insee AND NOT af.fraction
  -- l'atome de la commune ABSORBANTE, et ses rattachements sur la fenêtre
  JOIN atom am ON am.insee_geofla = c.insee_mere AND NOT am.fraction
  JOIN membership mm ON mm.atom_id = am.atom_id
                    AND mm.periode && daterange(c.depuis, c.retablie_le, '[)')
 WHERE NOT isempty(mm.periode * daterange(c.depuis, c.retablie_le, '[)'));

-- Garde-fou 3 : ne rien poser sur une période déjà occupée.
DELETE FROM ret_periode p
 WHERE EXISTS (
    SELECT 1 FROM membership m
     WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
       AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

-- Un atome rétabli peut correspondre à plusieurs atomes-mères (communes
-- absorbées puis refondues) : on ne garde qu'une ligne par (atome, niveau,
-- période), sans quoi la contrainte EXCLUDE ferait échouer la transaction.
DELETE FROM ret_periode a
 USING ret_periode b
 WHERE a.atom_id = b.atom_id AND a.niveau = b.niveau
   AND a.valid_from = b.valid_from
   AND a.unit_id > b.unit_id;

\echo ''
\echo '=== 2. Ce qui va être posé ==='
SELECT niveau, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM ret_periode GROUP BY niveau ORDER BY niveau;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to
      FROM ret_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO retablissement_trace (membership_id, atom_id, unit_id, niveau,
                                  valid_from, valid_to, insee, insee_mere,
                                  retablie_le)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.insee, p.insee_mere, p.retablie_le
  FROM ins i
  JOIN ret_periode p ON p.atom_id = i.atom_id
                    AND p.niveau  = i.niveau
                    AND p.valid_from = i.valid_from
                    AND p.unit_id = i.unit_id;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Posé, par commune ==='
SELECT t.insee, coalesce(n.nom, '?') AS commune, t.insee_mere,
       t.retablie_le, count(*) AS lignes,
       string_agg(DISTINCT t.niveau, ', ') AS niveaux
  FROM retablissement_trace t
  LEFT JOIN noms_geofla n ON n.insee = t.insee
 GROUP BY 1, 2, 3, 4 ORDER BY t.retablie_le, t.insee;

\echo ''
\echo '=== 4. Ouézy, le cas qui a révélé le défaut ==='
SELECT m.niveau, m.unit_id, u.nom, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 41' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN retablissement_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '14482' AND m.valid_from >= DATE '1990-01-01'
 ORDER BY m.niveau, m.valid_from;
-- Attendu : une chaîne continue de 1999 à 2013, sans trou entre 1999 et 2006.

\echo ''
\echo '=== 5. Aucun atome dans deux unités du même niveau à la même date ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode
          FROM membership GROUP BY 1, 2, 3
        HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY niveau;
-- Attendu : aucune ligne, ou seulement les villes coupées déjà connues.

-- ---------------------------------------------------------------------------
-- 5. Ce que ce fichier NE traite PAS
--
-- Les 45 autres communes de GEOFLA 2011 absentes du COG 1999 ne sont pas des
-- rétablissements. Elles peuvent être des créations postérieures, des
-- changements de code, ou des écarts de millésime entre GEOFLA et le COG. Les
-- traiter par la même règle serait leur appliquer une filiation que la source
-- ne donne pas.
--
-- Pour les lister :
--
--   SELECT n.insee, n.nom FROM noms_geofla n
--    WHERE NOT EXISTS (SELECT 1 FROM commune_moderne c
--                       WHERE c.code = n.insee AND c.valid_from <= '1999-06-01'
--                         AND c.valid_to > '1999-06-01')
--      AND NOT EXISTS (SELECT 1 FROM retablissement_trace t
--                       WHERE t.insee = n.insee);
--
-- ---------------------------------------------------------------------------
-- 6. Pour défaire
--
--   DELETE FROM membership m USING retablissement_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE retablissement_trace;
-- ---------------------------------------------------------------------------

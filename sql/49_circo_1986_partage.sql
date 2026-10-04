-- ============================================================================
-- 49_circo_1986_partage.sql — lever les indéterminations du découpage de 1986
--
--   python3 circo/resoudre_1986_partage.py
--   psql -d histgis -v partage=circo/circo_1986_partage.csv \
--        -f sql/49_circo_1986_partage.sql          # depuis la RACINE
--
-- Le trou
-- -------
-- `28_circo_1986.sql` charge le tableau de correspondance du ministère de
-- l'Intérieur, dont la colonne « 1986 » vaut parfois « 16 et 17 » : le canton
-- de 2012, qui sert de clé, chevauchait deux circonscriptions de 1986.
-- `extrait_circo.py` a écarté ces cas plutôt que de trancher — **125 communes,
-- 13 cantons**, dans `circo_1986_indetermine.csv`.
--
-- Sur la carte, ces communes n'apparaissaient pas du tout, ce qui donnait à voir
-- une lacune de la base là où il y avait une incertitude documentée. C'est le
-- signalement du 20 août 2026 : « certains cantons ne sont pas présents dans le
-- Nord, ce qui enlève également les communes ».
--
-- La source, et pourquoi elle a le droit de trancher
-- --------------------------------------------------
-- Le **§ 5 de l'atlas Gaudillère** énumère les cantons divisés de 1986 et dit,
-- pour chacun, quelles communes vont dans quelle circonscription. Elle est
-- INDÉPENDANTE du ministère : elle ne recopie pas la donnée qu'elle lève.
--
-- Et elle se contrôle. Pour chacun des 13 cantons, le ministère annonçait une
-- PAIRE de circonscriptions possibles sans dire laquelle ; l'atlas nomme les
-- communes. Les deux sources se recoupent donc sur la paire, et divergent
-- seulement sur la répartition — que seule l'une des deux donne.
--
--   circonscriptions posées hors de la paire annoncée : **0 sur 118**
--
-- Ce n'est pas une vérification de forme : un écart aurait signalé une règle
-- mal transcrite, un canton mal identifié, ou une confusion entre les
-- découpages cantonaux de 1986 et de 2012.
--
-- Trois degrés de certitude, portés par la colonne `voie`
-- -------------------------------------------------------
--   `nommee`   42 — la commune est nommée dans le texte ;
--   `reste`    72 — elle tombe sous « le reste du canton » ;
--   `reserve`   4 — idem, mais l'identification du canton de 1986 avec celui de
--                   2012 repose sur une correspondance de noms entre deux
--                   découpages cantonaux. Douai-Nord-Est, créé en 1991
--                   (décret n° 91-216), rattaché au « canton douai ouest » du
--                   texte. À relire sur l'original.
--
-- Ce qui reste, et pourquoi
-- -------------------------
-- **10 communes.** Les arrondissements de Lyon et Roubaix, que l'atlas exclut
-- explicitement de son § 5 ; Drancy, Dugny et Le Bourget, dont le canton
-- chevauche TROIS circonscriptions ; Cappelle-la-Grande et Saint-Pol-sur-Mer,
-- dans un canton de Dunkerque que le texte ne traite pas. Elles restent
-- indéterminées, et c'est exact.
--
-- Deux désaccords, signalés et non résolus
-- ----------------------------------------
-- L'atlas déclare divisés les cantons de **Douai-Ouest** et de **Condé-sur-
-- Escaut**, que le ministère donne d'un seul tenant. Aucune des deux sources
-- n'a autorité sur l'autre ici. Consigné dans `circo/annexe_vi.md`.
--
-- Réversible : `circo_partage_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- Prérequis : `24` (atomes-fractions) et `28` (unités de 1986) joués.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?partage}
\else
  \set partage 'circo/circo_1986_partage.csv'
  \echo 'partage non fourni : circo/circo_1986_partage.csv par défaut'
\endif

-- Mêmes bornes que `28`. Le 10 juin 2012 est le premier tour du renouvellement
-- général à partir duquel l'ordonnance n° 2009-935 s'applique.
\set debut '1986-11-24'
\set fin   '2012-06-10'
\set date_canton '2012-06-01'

DO $$
BEGIN
    IF to_regclass('histgis.circo1986_trace') IS NULL THEN
        RAISE EXCEPTION '28_circo_1986.sql doit être joué avant : ce fichier '
                        'complète sa couche, il ne la remplace pas.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS circo_partage_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    canton_2012   text NOT NULL,
    insee         char(5) NOT NULL,
    voie          text NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_partage_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE circo_partage_trace;

-- ---------------------------------------------------------------------------
-- 1. La source
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS partage_src;
CREATE TABLE partage_src (
    canton text, insee char(5), nom text, circo text, voie text
);
\set cmd '\\copy partage_src FROM ' :'partage' ' WITH (FORMAT csv, HEADER true)'
:cmd

\echo ''
\echo '=== 1. Source lue ==='
SELECT count(*) AS lignes, count(DISTINCT insee) AS communes,
       count(DISTINCT canton) AS cantons,
       count(*) FILTER (WHERE voie = 'nommee')  AS nommees,
       count(*) FILTER (WHERE voie = 'reste')   AS reste,
       count(*) FILTER (WHERE voie = 'reserve') AS reserve
  FROM partage_src;

-- ---------------------------------------------------------------------------
-- 2. Poser la ligne sur le BON atome
--
-- Une commune coupée entre cantons a plusieurs atomes, un par canton
-- (`cassini#canton`). La source donne le canton : on choisit l'atome dont le
-- rattachement cantonal concorde, et l'atome plein à défaut. C'est la même
-- règle que `27` et `28`, et le LEFT JOIN est délibéré — une ligne qui ne
-- concorde avec aucun canton doit atterrir quand même, pas disparaître.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cp_cible;
CREATE TEMP TABLE cp_cible AS
SELECT DISTINCT ON (s.canton, s.insee)
       s.canton, s.insee, s.circo, s.voie,
       a.atom_id,
       coalesce(m.unit_id = s.canton, false) AS canton_concorde
  FROM partage_src s
  JOIN atom a ON a.insee_geofla = s.insee
  LEFT JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                        AND m.periode @> :'date_canton'::date
 ORDER BY s.canton, s.insee,
          (m.unit_id = s.canton) DESC NULLS LAST, a.atom_id;

\echo ''
\echo '=== 2. Lignes source sans atome ==='
SELECT s.canton, s.insee, s.nom
  FROM partage_src s
 WHERE NOT EXISTS (SELECT 1 FROM cp_cible c
                    WHERE c.canton = s.canton AND c.insee = s.insee);
-- Attendu : aucune.

\echo ''
\echo '=== 3. Unités de 1986 manquantes ==='
SELECT DISTINCT c.circo || '@1986' AS unite_attendue
  FROM cp_cible c
 WHERE NOT EXISTS (SELECT 1 FROM unit u
                    WHERE u.unit_id = c.circo || '@1986' AND u.niveau = 'circo');
-- Attendu : aucune. `28` les a toutes créées — l'atlas ne nomme aucune
-- circonscription que le ministère ignore.

-- ---------------------------------------------------------------------------
-- 3. Garde-fou : ne rien poser sur une période déjà occupée
--
-- Certaines de ces communes ont DÉJÀ un rattachement pour 1986 — quand le
-- ministère avait tranché pour une partie d'entre elles. On ne les contredit
-- pas : la source qui a posé reste maîtresse de sa période.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cp_pose;
CREATE TEMP TABLE cp_pose AS
SELECT c.*
  FROM cp_cible c
 WHERE EXISTS (SELECT 1 FROM unit u
                WHERE u.unit_id = c.circo || '@1986' AND u.niveau = 'circo')
   AND NOT EXISTS (
       SELECT 1 FROM membership m
        WHERE m.atom_id = c.atom_id AND m.niveau = 'circo'
          AND m.periode && daterange(:'debut', :'fin', '[)'));

\echo ''
\echo '=== 4. Ce qui va etre pose ==='
SELECT count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       count(*) FILTER (WHERE canton_concorde) AS sur_le_bon_canton
  FROM cp_pose;

\echo ''
\echo '=== 5. Ecarte parce que la periode etait deja occupee ==='
SELECT c.canton, c.insee, c.circo, c.voie
  FROM cp_cible c
 WHERE NOT EXISTS (SELECT 1 FROM cp_pose p
                    WHERE p.canton = c.canton AND p.insee = c.insee)
 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 4. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, circo || '@1986', 'circo', :'debut'::date, :'fin'::date
      FROM cp_pose
    RETURNING membership_id, atom_id, unit_id
)
INSERT INTO circo_partage_trace (membership_id, atom_id, unit_id,
                                 canton_2012, insee, voie)
SELECT i.membership_id, i.atom_id, i.unit_id, p.canton, p.insee, p.voie
  FROM ins i
  JOIN cp_pose p ON p.atom_id = i.atom_id
                AND p.circo || '@1986' = i.unit_id;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 5. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 6. Pose, par departement et par voie ==='
SELECT left(t.insee, 2) AS dep, t.voie, count(*) AS communes
  FROM circo_partage_trace t GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 7. Anzin, Douai et Valenciennes ==='
SELECT t.insee, coalesce(n.nom, '?') AS commune, t.canton_2012, t.unit_id, t.voie
  FROM circo_partage_trace t
  LEFT JOIN noms_geofla n ON n.insee = t.insee
 WHERE t.insee IN ('59014', '59178', '59606', '59544', '59346', '59507')
 ORDER BY t.insee, t.canton_2012;
-- Anzin (59014) doit etre en 59-20, Saint-Saulve (59544) en 59-21 : c'est la
-- phrase de l'atlas, et c'est le cas qui a montre que la liste du § 5 n'etait
-- pas celle que nous en avions transcrite.

\echo ''
\echo '=== 8. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode
          FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0.

\echo ''
\echo '=== 9. Ce qui reste indetermine ==='
\echo '    10 communes : arrondissements de Lyon et Roubaix (exclus du § 5),'
\echo '    Drancy/Dugny/Le Bourget (canton a TROIS circonscriptions),'
\echo '    Cappelle-la-Grande et Saint-Pol-sur-Mer (canton non traite).'
\echo ''
\echo '=== 10. Pour tout defaire ==='
\echo '    DELETE FROM membership m USING circo_partage_trace t'
\echo '     WHERE t.membership_id = m.membership_id;'
\echo '    TRUNCATE circo_partage_trace;'

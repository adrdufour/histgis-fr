-- ============================================================================
-- 52_paris_circo_1986.sql — Paris entre enfin dans la couche de 1986
--
--   python3 circo/paris_quartiers.py     # reconstruit paris_quartier
--   python3 circo/paris_circo.py         # reconstruit paris_circo
--   psql -d histgis -f sql/52_paris_circo_1986.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/52_paris_circo_1986.sql
--
-- Le trou
-- -------
-- `28_circo_1986.sql` le déclare en toutes lettres dans ses recettes : « Paris
-- absent du découpage de 1986 (21 circonscriptions) ». La raison n'est pas un
-- oubli mais une impossibilité : le tableau du ministère ne descend pas sous la
-- commune, et à Paris les circonscriptions **coupent les arrondissements**.
-- Aucune trame communale ne peut les porter.
--
-- Ce qui lève le blocage
-- ----------------------
-- Deux pièces, construites en amont et longtemps restées sans emploi :
--
--   `circo/note_paris.md` + `paris_decoupage.csv` — la composition PAR QUARTIER
--   de dix-neuf divisions électorales de 1815 à 1986, transcrite de l'atlas
--   Gaudillère. Douze divisions postérieures à 1860 citent exactement 80
--   quartiers, sans un oubli ni un inventé.
--
--   `circo/paris_quartiers.py` — la géométrie des 80 quartiers, reconstruite
--   par union d'IRIS (CONTOURS-IRIS, Licence Ouverte 2.0). 105,43 km² contre
--   104,90 pour GEOFLA : l'écart est celui des bois.
--
-- **Ces deux tables vivaient hors de la chaîne** et `rebuild.sh` les emportait
-- à chaque reconstruction — la leçon de `19_noms_geofla.sql`, répétée. Elles
-- sont désormais appelées par `rejouer_apres_rebuild.sh`.
--
-- Les 80 quartiers deviennent des atomes
-- --------------------------------------
-- Un atome est « la plus petite unité au rattachement stable ». À Paris, c'est
-- le quartier, pas l'arrondissement. On crée donc 80 atomes `PQ01`…`PQ80`,
-- marqués `fraction`, portant chacun SA géométrie — et non celle de sa mère,
-- contrairement aux fractions de Marseille et de Lyon. Le recouvrement de
-- 12 822 km² ne s'aggrave donc pas d'un mètre carré ici.
--
-- Ce que ce fichier ne fait PAS, et pourquoi
-- ------------------------------------------
-- Il ne touche pas aux vingt atomes d'arrondissement, ni à leurs rattachements
-- de 1870-1940. Les poser au quartier serait plus juste — TRF-GIS attribue
-- aujourd'hui la circonscription à l'arrondissement entier, ce qui est faux dès
-- qu'elle le coupe — mais ce serait REMPLACER de la donnée existante, et cela
-- demande son propre contrôle. Ici on ne fait que combler.
--
-- Conséquence à connaître : entre 1986 et 2012, Paris est porté à la fois par
-- les atomes d'arrondissement (niveau canton) et par les atomes de quartier
-- (niveau circo). **105 km² comptés deux fois**, le temps que l'étape suivante
-- déplace les rattachements anciens. C'est déclaré, pas dissimulé.
--
-- Les huit quartiers coupés
-- -------------------------
-- Pour 1986, la transcription cite 88 lignes pour 80 quartiers : **huit
-- quartiers relèvent de deux circonscriptions**. Un atome ne peut pas
-- appartenir à deux unités du même niveau à la même date — la contrainte
-- `membership_non_chevauchant` le refuse, et elle a raison.
--
-- On suit donc le précédent de `27_circo_2012.sql` : poser ce qui est entier,
-- **nommer** ce qui est coupé. La recette 4 les liste. L'atlas donne les rues
-- de partage ; les découper est le chantier suivant, et il demande une trame
-- infra-quartier que nous n'avons pas.
--
-- Réversible : `paris_circo_trace`, section 6.
-- Prérequis : `28` joué ; `paris_quartier` et `paris_circo` reconstruites.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Mêmes bornes que `28`, pour que Paris et la province basculent ensemble.
\set debut '1986-11-24'
\set fin   '2012-06-10'

DO $$
BEGIN
    IF to_regclass('histgis.paris_quartier') IS NULL
       OR to_regclass('histgis.paris_circo') IS NULL THEN
        RAISE EXCEPTION E'paris_quartier ou paris_circo absente.\n'
            'Les reconstruire :\n'
            '  python3 circo/paris_quartiers.py\n'
            '  python3 circo/paris_circo.py\n'
            'Ces tables vivent dans le schéma histgis : rebuild.sh les efface.';
    END IF;
    IF to_regclass('histgis.circo1986_trace') IS NULL THEN
        RAISE EXCEPTION '28_circo_1986.sql doit être joué avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Ce que la source donne pour 1986, et ce qui est posable
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pc_ligne;
CREATE TEMP TABLE pc_ligne AS
SELECT unnest(q_list) AS quartier,
       '75-' || lpad(circo, 2, '0') || '@1986' AS unit_id,
       circo
  FROM paris_circo
 WHERE periode = '1986';

DROP TABLE IF EXISTS pc_coupe;
CREATE TEMP TABLE pc_coupe AS
SELECT quartier FROM pc_ligne GROUP BY quartier HAVING count(*) > 1;

DROP TABLE IF EXISTS pc_pose;
CREATE TEMP TABLE pc_pose AS
SELECT l.quartier, l.unit_id, l.circo
  FROM pc_ligne l
 WHERE l.quartier NOT IN (SELECT quartier FROM pc_coupe);

\echo ''
\echo '=== 1. La source pour 1986 ==='
SELECT (SELECT count(*) FROM paris_circo WHERE periode = '1986') AS circos,
       (SELECT count(*) FROM pc_ligne)                           AS lignes,
       (SELECT count(DISTINCT quartier) FROM pc_ligne)           AS quartiers,
       (SELECT count(*) FROM pc_coupe)                           AS coupes,
       (SELECT count(*) FROM pc_pose)                            AS posables;
-- Attendu : 21 circonscriptions, 88 lignes, 80 quartiers, 8 coupés, 72 posables.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS paris_circo_trace (
    quoi    text NOT NULL,
    cle     text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- Retrait d'un passage précédent, dans l'ordre des dépendances.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM paris_circo_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM paris_circo_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM atom a
 WHERE EXISTS (SELECT 1 FROM paris_circo_trace t
                WHERE t.quoi = 'atom' AND t.cle = a.atom_id);
TRUNCATE paris_circo_trace;

-- ---------------------------------------------------------------------------
-- 2. Les 80 atomes de quartier
--
-- `cassini` est NOT NULL et sert de clé de regroupement dans tout le projet.
-- Aucun code Cassini n'existe pour un quartier parisien : on y met
-- l'identifiant du quartier, préfixé, pour que rien ne le confonde avec un
-- vrai numéro Cassini.
-- ---------------------------------------------------------------------------
INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('paris_quartier', '52_paris_circo_1986.sql',
     'union d''IRIS (CONTOURS-IRIS, Licence Ouverte 2.0), via paris_quartiers.py')
ON CONFLICT (source) DO NOTHING;

WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, insee_geofla)
    SELECT 'PQ' || lpad(q.quartier::text, 2, '0'),
           'PQ' || lpad(q.quartier::text, 2, '0'),
           true,
           q.arrondissement
      FROM paris_quartier q
    RETURNING atom_id
)
INSERT INTO paris_circo_trace (quoi, cle)
SELECT 'atom', atom_id FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT 'PQ' || lpad(q.quartier::text, 2, '0'), q.geom, 'paris_quartier', false
  FROM paris_quartier q;

-- ---------------------------------------------------------------------------
-- 3. Les 21 circonscriptions
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom)
    SELECT DISTINCT l.unit_id, 'circo', '75',
           '75-' || lpad(l.circo, 2, '0'),
           'uninominal', 1986,
           'Paris ' || l.circo || 'e circonscription'
      FROM pc_ligne l
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO paris_circo_trace (quoi, cle)
SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT l.unit_id, 'Paris ' || l.circo || 'e circonscription',
       :'debut'::date, :'fin'::date
  FROM pc_ligne l
 WHERE EXISTS (SELECT 1 FROM paris_circo_trace t
                WHERE t.quoi = 'unit' AND t.cle = l.unit_id);

-- ---------------------------------------------------------------------------
-- 4. Les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT 'PQ' || lpad(p.quartier::text, 2, '0'), p.unit_id, 'circo',
           :'debut'::date, :'fin'::date
      FROM pc_pose p
    RETURNING membership_id
)
INSERT INTO paris_circo_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE atom; ANALYZE atom_geom; ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 5. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Ce qui a ete pose ==='
SELECT quoi, count(*) FROM paris_circo_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 80 atomes, 21 unites, 72 rattachements.

\echo ''
\echo '=== 3. Couverture de Paris a 1990 ==='
SELECT count(DISTINCT m.atom_id) AS quartiers_rattaches,
       count(DISTINCT m.unit_id) AS circonscriptions,
       round((ST_Area(ST_Union(g.geom)) / 1e6)::numeric, 2) AS km2
  FROM membership m
  JOIN atom_geom g ON g.atom_id = m.atom_id
 WHERE m.niveau = 'circo' AND m.periode @> DATE '1990-06-01'
   AND m.unit_id LIKE '75-%@1986';
-- Attendu : 72 quartiers, 21 circonscriptions, et une surface INFERIEURE aux
-- 105,43 km2 de Paris — les huit quartiers coupes manquent, et c'est exact.

\echo ''
\echo '=== 4. Les quartiers coupes, non poses ==='
SELECT c.quartier, q.nom, string_agg(l.circo, ' / ' ORDER BY l.circo) AS entre
  FROM pc_coupe c
  JOIN pc_ligne l ON l.quartier = c.quartier
  LEFT JOIN paris_quartier q ON q.quartier = c.quartier
 GROUP BY c.quartier, q.nom ORDER BY c.quartier;
-- L'atlas nomme les rues de partage : ces huit-la sont posables le jour ou
-- une trame infra-quartier existera. Les laisser vides est exact ; leur
-- attribuer une circonscription au juge ne le serait pas.

\echo ''
\echo '=== 5. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0.

\echo ''
\echo '=== 6. Pour tout defaire ==='
\echo '    DELETE membership, puis unit, puis atom, via paris_circo_trace.'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

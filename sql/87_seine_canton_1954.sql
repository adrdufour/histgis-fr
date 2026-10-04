-- ============================================================================
-- histgis — 87_seine_canton_1954.sql : quatre communes de la Seine rendues au
-- jalon cantonal de 1954
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour le \copy
--   psql -d histgis -f sql/87_seine_canton_1954.sql              -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/87_seine_canton_1954.sql
--
-- CE QUE CE FICHIER RÉPARE
-- ========================
-- La planche cantonale de 1954 porte 22 cantons pour la Seine et 76 des
-- 80 communes de banlieue. Quatre manquent : **Choisy-le-Roi, Noisy-le-Sec,
-- Sceaux, Villejuif**. Ce n'est pas un trou de la source — les quatre sont sur
-- le fascicule, avec leur code d'arrondissement et de canton. C'est
-- l'extraction qui les a laissées tomber, sur des noms qu'elle n'a pas su
-- apparier : `Choisy-ic-Roi`, `Nolsy-ie-Sec`, `SCEAUX` (en capitales, seule
-- ligne du département dans ce style), `Vitejuit`.
--
-- Trois des quatre sont les CHEFS-LIEUX des cantons qui portent leur nom. La
-- quatrième, Choisy-le-Roi, se lit `3 08`, c'est-à-dire canton d'Ivry-sur-Seine.
--
-- POURQUOI CE N'EST PAS UN JUGEMENT
-- ==================================
-- La page 758 du fascicule porte DEUX écritures du même fait : la nomenclature
-- des 42 cantons du département en tête de page, et le tableau de population
-- commune par commune. Pour Noisy-le-Sec, Sceaux et Villejuif les deux
-- écritures donnent le même code. Pour Choisy-le-Roi seul le tableau le donne,
-- et la nomenclature confirme seulement que `08` est le canton d'Ivry.
--
-- Le détail des lectures est dans `cog1954/correctif_seine_1954.csv`, avec la
-- ligne OCR brute de chacune. *Un correctif dont on ne peut pas relire la
-- pièce n'est pas un correctif, c'est une opinion.*
--
-- CE QUE ÇA DÉBLOQUE
-- ==================
-- Les circonscriptions de la Seine de 1945 à 1958 se définissent PAR CANTON
-- (loi du 5 octobre 1946). Sans ces quatre-là, `88` poserait une division
-- trouée à 76 communes sur 80 — mesuré par `circo/banc_seine.py`.
--
-- BORNES
-- ======
-- Celles de `68` mot pour mot : [1954-01-01, 1955-01-01). Ce fichier ajoute des
-- rattachements au jalon existant, il n'en étend pas la portée.
--
-- Réversible : `seine_canton_trace`, section 4.
-- Prérequis : `68_cog1954_membership.sql` joué.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM unit
                    WHERE niveau = 'canton' AND dep = '75'
                      AND nom = 'Sceaux') THEN
        RAISE EXCEPTION E'Le jalon cantonal de 1954 n''est pas en base.\n'
            '  psql -d histgis -1 -f sql/68_cog1954_membership.sql';
    END IF;
END $$;

-- La trace se crée AVANT les recettes, et non dans la branche qui pose.
-- PostgreSQL résout les noms de tables au moment de l'analyse : un
-- `to_regclass(...) IS NULL OR NOT EXISTS (SELECT … FROM la_trace)` ne protège
-- rien du tout, il échoue à la planification. *Une garde qui suppose une
-- évaluation paresseuse d'un nom de relation n'est pas une garde.*
-- Une table de trace vide n'est pas une donnée : la créer à blanc ne pose rien.
CREATE TABLE IF NOT EXISTS seine_canton_trace (
    cle text PRIMARY KEY,
    pose_le timestamptz NOT NULL DEFAULT now()
);

DROP TABLE IF EXISTS sc_src;
CREATE TEMP TABLE sc_src (
    insee               char(5),
    commune             text,
    arr                 smallint,
    canton              smallint,
    canton_nom          text,
    page                int,
    lecture_tableau     text,
    lecture_nomenclature text,
    ligne_brute         text
);
\copy sc_src FROM 'cog1954/correctif_seine_1954.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- 1. Résolution : l'atome par le code INSEE, le canton par son nom en base
--
-- Le nom du canton n'est pas apparié de loin : les quatre noms cités sont
-- ceux que `68` a posés, à la lettre. Une ligne qui ne résout pas sort en
-- recette 2 et le garde-fou arrête tout.
--
-- `NOT a.fraction` — CORRIGÉ LE 6 SEPTEMBRE 2026, PREMIER JEU
-- ============================================================
-- Le premier écrit joignait sur le seul `insee_geofla`. Il a rendu SIX lignes
-- pour quatre communes : Villejuif possède trois atomes, `40231` et deux
-- fractions `40231#9427` et `40231#9448`, héritées d'un partage cantonal de
-- 1870-1940. *Un code INSEE ne désigne pas un atome, il désigne une commune.*
--
-- La convention à suivre n'est pas une invention : `68` pose UN atome par
-- commune, et ne fabrique une fraction `atome#canton` que si la commune est
-- multicantonale À 1954 — aucune ne l'est dans la Seine. Les deux fractions de
-- Villejuif ne sont d'ailleurs dessinées à aucune date : l'export du 75 ne
-- contient aucun atome à `#`, pas même en 1870.
--
-- Les fractions écartées sont listées en recette 1 bis, pour que le choix se
-- lise au lieu de se subir.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_pose;
CREATE TEMP TABLE sc_pose AS
SELECT s.insee, s.commune, s.canton_nom, s.lecture_tableau,
       s.lecture_nomenclature, s.page,
       a.atom_id, u.unit_id
  FROM sc_src s
  LEFT JOIN atom a ON a.insee_geofla = s.insee AND NOT a.fraction
  LEFT JOIN unit u ON u.niveau = 'canton' AND u.dep = '75'
                  AND u.nom = s.canton_nom;

\echo ''
\echo '=== 1. Ce que le correctif propose ==='
SELECT commune, canton_nom, lecture_tableau AS tableau,
       coalesce(lecture_nomenclature, '') AS nomenclature,
       page, atom_id, unit_id
  FROM sc_pose ORDER BY commune;

\echo ''
\echo '=== 1 bis. Les fractions ecartees, et a qui elles appartiennent ==='
SELECT s.commune, a.atom_id, a.cassini, a.com_act
  FROM sc_src s JOIN atom a ON a.insee_geofla = s.insee AND a.fraction
 ORDER BY 1, 2;
-- Attendu au 6 septembre 2026 : les deux fractions de Villejuif, et rien
-- d'autre. Une fraction NEUVE qui apparaitrait ici serait a comprendre avant
-- de rejouer : elle voudrait dire qu'une commune de la Seine est devenue
-- multicantonale quelque part dans la base.

\echo ''
\echo '=== 2. Garde-fou : tout resout-il, et une seule fois ? ==='
SELECT count(*)                                   AS lignes,
       count(*) FILTER (WHERE atom_id IS NULL)    AS atomes_introuvables,
       count(*) FILTER (WHERE unit_id IS NULL)    AS cantons_introuvables,
       count(*) - count(DISTINCT insee)           AS insee_en_double
  FROM sc_pose;
-- Attendu : 4, 0, 0, 0.  Le dernier chiffre est celui qui manquait au premier
-- jeu : il valait 2, et le fichier a pose six rattachements pour quatre
-- communes sans que rien ne proteste.

\echo ''
\echo '=== 3. Garde-fou : ces atomes sont-ils bien SANS canton en 1954 ? ==='
-- Si une ligne sort, le correctif remplacerait un rattachement au lieu d'en
-- combler l'absence, et il faut comprendre lequel avant d'aller plus loin.
SELECT p.commune, u.nom AS canton_deja_pose, m.valid_from, m.valid_to
  FROM sc_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(DATE '1954-01-01',
                                              DATE '1955-01-01', '[)')
  JOIN unit u ON u.unit_id = m.unit_id
 WHERE NOT EXISTS (SELECT 1 FROM seine_canton_trace t
                    WHERE t.cle = m.membership_id::text)
 ORDER BY 1;
-- Attendu : aucune ligne.
--
-- Le `NOT EXISTS` est le pendant, du côté DIAGNOSTIC, du retrait de trace que
-- fait la pose. Sans lui, ce fichier relancé à blanc après un passage voit ses
-- PROPRES rattachements et annonce quatre conflits — ce qui est arrivé le
-- 6 septembre 2026 et n'a alarmé personne uniquement parce que la cause était
-- connue. *Un diagnostic qui compte l'ouvrage du fichier parmi les obstacles
-- du fichier ne prévient de rien, il crie au loup.*

\if :{?appliquer}

-- Retirer son propre passage AVANT de juger de ce qui reste — la leçon de `55`.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM seine_canton_trace t
                WHERE t.cle = m.membership_id::text);
TRUNCATE seine_canton_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM sc_pose
     WHERE atom_id IS NULL OR unit_id IS NULL;
    IF n > 0 THEN
        RAISE EXCEPTION '% ligne(s) du correctif ne resolvent pas. Voir la '
            'recette 2.', n;
    END IF;

    SELECT count(*) - count(DISTINCT insee) INTO n FROM sc_pose;
    IF n > 0 THEN
        RAISE EXCEPTION '% commune(s) du correctif resolvent vers plusieurs '
            'atomes. Un code INSEE ne designe pas un atome. Voir les recettes '
            '1 bis et 2.', n;
    END IF;

    SELECT count(*) INTO n
      FROM sc_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(DATE '1954-01-01',
                                                  DATE '1955-01-01', '[)');
    IF n > 0 THEN
        RAISE EXCEPTION 'Ces atomes ont deja un canton en 1954 : % '
            'rattachement(s). Ce fichier COMBLE, il ne remplace pas. Voir la '
            'recette 3.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', DATE '1954-01-01', DATE '1955-01-01'
      FROM sc_pose
    RETURNING membership_id
)
INSERT INTO seine_canton_trace (cle)
SELECT membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 4. Pose ==='
SELECT count(*) AS rattachements_poses FROM seine_canton_trace;

\echo ''
\echo '=== 5. Recette : la Seine est-elle entiere au canton en 1954 ? ==='
-- 80 communes de banlieue, 22 cantons, aucune absente. C'est la recette que
-- `circo/banc_seine.py` mesure hors base ; elle doit rendre le meme chiffre.
SELECT count(DISTINCT a.atom_id) AS communes_avec_canton,
       count(DISTINCT m.unit_id) AS cantons
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> DATE '1954-06-01'
  JOIN unit u ON u.unit_id = m.unit_id AND u.dep = '75'
 WHERE a.insee_geofla ~ '^(92|93|94)';
-- Attendu : 80 et 22.

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

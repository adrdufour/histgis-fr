-- ============================================================================
-- histgis — 88_seine_circo_1945_1967.sql : la banlieue de la Seine entre dans
-- la couche circonscriptions
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour le \copy
--   python3 circo/banc_seine.py                                 -- le banc
--   psql -d histgis -f sql/88_seine_circo_1945_1967.sql         -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/88_seine_circo_1945_1967.sql
--
-- LE TROU, ET SA CAUSE
-- ====================
-- De 1870 à 1940 le département de la Seine est entier sur la carte : cent
-- atomes, Paris et ses quatre-vingts communes de banlieue. À partir de 1945 il
-- se réduit à Paris. La cause n'est pas la géométrie — les quatre-vingts
-- communes sont en base, dessinées, vivantes — c'est qu'elles n'ont plus AUCUN
-- rattachement circo. La seule source qui porte le 75 hors 1870-1940 est
-- `paris_decoupage.xlsx`, et elle est intra-muros par quartier.
--
-- CE QUE CE FICHIER POSE
-- ======================
--   1945-1958   3 circonscriptions   4e, 5e, 6e de la Seine
--   1958-1968  24 circonscriptions   32e à 55e de la Seine
--
-- Paris garde les siennes, posées par `55` : 1re à 3e en 1945-1958, 1re à 31e
-- en 1958-1986. Ce fichier ne touche à aucune.
--
-- LES DEUX TEXTES, ET CE QU'ILS ONT DE COMMUN
-- ============================================
-- Les deux découpages se définissent PAR CANTON — c'est exactement ce qui
-- bloquait nationalement le découpage de 1958 (`histgis-trou-cantonal`). Mais
-- le trou n'en est plus un depuis `66`-`69` : le jalon de 1954 donne les
-- 22 cantons de la Seine et leur composition communale.
--
--   * **1945-1958** — loi n° 46-2151 du 5 octobre 1946 (JORF du 8 octobre
--     1946), découpage déjà en vigueur aux constituantes du 21 octobre 1945 et
--     du 2 juin 1946. Trois circonscriptions de banlieue, 22 cantons en tout,
--     scrutin de LISTE à la proportionnelle.
--   * **1958-1968** — ordonnance n° 58-945 du 13 octobre 1958, tableau n° 1.
--     Vingt-quatre circonscriptions de banlieue, uninominal à deux tours ;
--     dix-sept sont énoncées en communes, sept en cantons.
--
-- LE CONTRÔLE QUI DÉCIDE, ET IL EST INDÉPENDANT
-- ==============================================
-- Les 22 cantons cités par la loi de 1946 sont, nom pour nom, les 22 cantons
-- que le fascicule du recensement de 1954 nomme pour la Seine. Ni un de plus,
-- ni un de moins. **Deux sources qui n'ont jamais été mises en contact** — un
-- texte électoral d'un côté, un dénombrement de l'autre, douze ans d'écart.
-- Et les 7 cantons de 1958 sont un sous-ensemble strict des 22.
--
-- Mesuré hors base par `circo/banc_seine.py` :
--
--     cantons cités par 1946 : 22 ; par 1958 : 7 ; en base à 1954 : 22
--       1946 == base 1954 ...... OUI
--       1958 inclus dans 1946 .. OUI
--     1945-1958    3 circos  80/80 communes  absentes 0  doubles 0
--     1958-1968   24 circos  80/80 communes  absentes 0  doubles 0
--
-- L'HYPOTHÈSE QUI PORTE TOUT, ET ELLE SE DIT
-- ===========================================
-- La composition communale des cantons n'est connue qu'à 1954. Ce fichier la
-- projette sur 1945-1958 et sur 1958-1968. **C'est une hypothèse de stabilité
-- cantonale, pas une lecture.** Ce qui la soutient : les 22 cantons de 1946 et
-- ceux de 1954 coïncident, et les 7 cantons de 1958 en font partie — la
-- NOMENCLATURE est donc stable de 1946 à 1958. Ce qui ne la soutient pas :
-- rien ne dit qu'une commune n'a pas changé de canton dans l'intervalle, et
-- l'annexe VII de Gaudillère compte trente créations cantonales entre 1954
-- et 1968 pour la France entière.
--
-- Les dix-sept circonscriptions de 1958 énoncées en communes ne dépendent PAS
-- de cette hypothèse : elles nomment leurs communes. Sur les 80 communes,
-- 57 sont posées par leur nom propre et 23 par un canton.
--
-- LES BORNES
-- ==========
--   [1945-01-01, 1958-01-01)   comme les circonscriptions parisiennes de `55`
--   [1958-01-01, 1968-01-01)   la Seine meurt le 1er janvier 1968
--
-- La seconde borne n'est pas celle de Paris. Les unités parisiennes de `55`
-- courent jusqu'au 24 novembre 1986 ; celles-ci s'arrêtent à la dissolution du
-- département par la loi du 10 juillet 1964, effective au 1er janvier 1968.
-- **Les législatives de mars 1967 se sont tenues dans ces circonscriptions-là**
-- — c'est pourquoi la borne est 1968 et non 1967.
--
-- CE QUI RESTE OUVERT APRÈS CE FICHIER
-- =====================================
--   * **1941-1945** — l'Occupation, rien de transcrit, ni pour Paris ni pour
--     la banlieue.
--   * **1968-1985** — la banlieue passe aux 92, 93 et 94, qui n'ont aucune
--     couche circo. Ce fichier ne la suit pas.
--   * **1815-1869** — les 80 communes n'ont ni rattachement ni géométrie sur
--     la carte. Autre chantier, autre source.
--
-- Réversible : `seine_circo_trace`, section 6.
-- Prérequis : `68_cog1954_membership.sql` et `87_seine_canton_1954.sql` joués.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
DECLARE n_atomes bigint; n_communes bigint;
BEGIN
    SELECT count(DISTINCT a.atom_id), count(DISTINCT a.insee_geofla)
      INTO n_atomes, n_communes
      FROM atom a
      JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                       AND m.periode @> DATE '1954-06-01'
      JOIN unit u ON u.unit_id = m.unit_id AND u.dep = '75'
     WHERE a.insee_geofla ~ '^(92|93|94)';
    IF n_communes < 80 THEN
        RAISE EXCEPTION E'Le jalon cantonal de 1954 ne couvre que % des '
            '80 communes de la Seine.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/87_seine_canton_1954.sql',
            n_communes;
    END IF;
    -- Le second garde-fou est celui qui manquait au premier jeu : la planche
    -- doit tenir UN atome par commune. Si elle en tient deux, `87` a ete joue
    -- dans sa version d'avant le 6 septembre et il faut le rejouer — il retire
    -- sa propre trace, donc le rejeu est propre.
    IF n_atomes <> n_communes THEN
        RAISE EXCEPTION E'La planche cantonale de 1954 tient % atomes pour % '
            'communes. Un code INSEE ne designe pas un atome.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/87_seine_canton_1954.sql',
            n_atomes, n_communes;
    END IF;
END $$;

-- La trace se crée AVANT les recettes : PostgreSQL résout les noms de tables
-- à l'analyse, donc une garde `to_regclass(...) IS NULL OR …` échoue à la
-- planification au lieu de court-circuiter. Une trace vide ne pose rien.
CREATE TABLE IF NOT EXISTS seine_circo_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DROP TABLE IF EXISTS se_src;
CREATE TEMP TABLE se_src (
    division text, circo int, libelle text, type text, jeton text,
    insee text, source text
);
\copy se_src FROM 'circo/seine_circo.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- 1. Les deux divisions et leurs bornes
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS se_periode;
CREATE TEMP TABLE se_periode (
    division text PRIMARY KEY, du date, au date, regime text, prefixe text
);
INSERT INTO se_periode VALUES
    ('1945-1958', DATE '1945-01-01', DATE '1958-01-01', 'liste',      'V1945_1958#'),
    ('1958-1968', DATE '1958-01-01', DATE '1968-01-01', 'uninominal', 'S1958_1968#');
-- Le préfixe de 1945 est celui de `55` : même division, mêmes bornes, les
-- circonscriptions 4 à 6 continuent la série 1 à 3 de Paris. Celui de 1958 est
-- neuf — `S` pour Seine — parce que les bornes DIFFÈRENT de celles de Paris.
-- *Deux unités qui ne vivent pas le même temps ne partagent pas une série.*

-- ---------------------------------------------------------------------------
-- 2. Le nom du canton dans le texte, et son nom en base
--
-- Deux écarts seulement, tous deux dus au texte de 1946 qui donne le nom long
-- du chef-lieu. Ils sont écrits ici, un par un, plutôt que rattrapés par une
-- ressemblance : *un appariement flou qui réussit ne se distingue pas d'un
-- appariement flou qui se trompe.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS se_alias;
CREATE TEMP TABLE se_alias (jeton text PRIMARY KEY, nom_base text);
INSERT INTO se_alias VALUES
    ('Charenton-le-Pont',   'Charenton'),
    ('Montreuil-sous-Bois', 'Montreuil');

-- ---------------------------------------------------------------------------
-- 3. Le référentiel : la planche cantonale de la Seine au 1er juin 1954
--
-- CORRIGÉ LE 6 SEPTEMBRE 2026, PREMIER JEU
-- =========================================
-- Le premier écrit résolvait les jetons « commune » sur le seul
-- `insee_geofla`. Il rendait **105 atomes pour 57 communes** en 1958 et 82 en
-- 1945 : les deux divisions ne couvraient pas le même territoire, et la
-- recette de couverture — qui déduisait elle aussi son lot de `insee_geofla` —
-- annonçait 82/82 sans rien voir.
--
-- *Un code INSEE ne désigne pas un atome, il désigne une commune.* Villejuif
-- en possède trois : `40231` et deux fractions héritées d'un partage cantonal
-- de 1870-1940, que l'export ne dessine à aucune date.
--
-- D'où un référentiel UNIQUE pour les deux divisions et pour la recette : les
-- atomes que la Seine rattache à l'un de ses cantons au 1er juin 1954. Il vaut
-- pour trois raisons :
--
--   * il vient de `68` et de `87`, donc du recensement de 1954 — jamais de la
--     transcription qu'il sert à éprouver ;
--   * `68` pose UN atome par commune, et ne fabrique une fraction que si la
--     commune est multicantonale à 1954, ce qu'aucune n'est ici ;
--   * il est le même pour les jetons « canton » et pour les jetons
--     « commune », donc les deux divisions couvrent le même sol par
--     construction.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS se_lot;
CREATE TEMP TABLE se_lot AS
SELECT DISTINCT a.atom_id, a.insee_geofla AS insee, m.unit_id AS canton_id
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.periode @> DATE '1954-06-01'
  JOIN unit u ON u.unit_id = m.unit_id AND u.dep = '75'
 WHERE a.insee_geofla ~ '^(92|93|94)';
CREATE INDEX se_lot_insee_idx ON se_lot (insee);

DROP TABLE IF EXISTS se_ligne;
CREATE TEMP TABLE se_ligne AS
-- 3a. les jetons « commune » : le code INSEE désigne la commune, le
--     référentiel désigne son atome
SELECT s.division, s.circo, s.type, s.jeton, l.atom_id
  FROM se_src s
  JOIN se_lot l ON l.insee = s.insee
 WHERE s.type = 'commune'
UNION ALL
-- 3b. les jetons « canton » : la composition communale au 1er juin 1954
SELECT s.division, s.circo, s.type, s.jeton, l.atom_id
  FROM se_src s
  JOIN unit u ON u.niveau = 'canton' AND u.dep = '75'
             AND u.nom = coalesce((SELECT nom_base FROM se_alias al
                                    WHERE al.jeton = s.jeton), s.jeton)
  JOIN se_lot l ON l.canton_id = u.unit_id
 WHERE s.type = 'canton';

DROP TABLE IF EXISTS se_pose;
CREATE TEMP TABLE se_pose AS
SELECT DISTINCT l.division, l.circo, l.atom_id,
       p.du, p.au, p.regime,
       p.prefixe || l.circo AS unit_id,
       extract(year FROM p.du)::int AS segment
  FROM se_ligne l JOIN se_periode p ON p.division = l.division;

\echo ''
\echo '=== 1. Ce que la source donne ==='
SELECT division, count(DISTINCT circo) AS circos,
       count(DISTINCT atom_id) AS communes,
       count(*) FILTER (WHERE type = 'canton') AS jetons_canton,
       count(*) FILTER (WHERE type = 'commune') AS jetons_commune
  FROM se_ligne GROUP BY division ORDER BY division;
-- Attendu : 1945-1958  3 circos  80 communes
--           1958-1968 24 circos  80 communes

\echo ''
\echo '=== 2. Garde-fou : tout jeton resout-il ? ==='
SELECT s.division, s.circo, s.type, s.jeton
  FROM se_src s
 WHERE NOT EXISTS (SELECT 1 FROM se_ligne l
                    WHERE l.division = s.division AND l.circo = s.circo
                      AND l.jeton = s.jeton)
 ORDER BY 1, 2, 4;
-- Attendu : aucune ligne.

\echo ''
\echo '=== 3. Recette de couverture : chaque division partitionne-t-elle ? ==='
-- Une commune absente est un trou sur la carte ; une commune double est une
-- superposition. Les deux se comptent, aucune ne se tolère.
-- Le lot attendu ne se déduit PAS de la transcription — il viendrait alors de
-- ce qu'on cherche à éprouver. C'est `se_lot`, la planche cantonale de 1954.
WITH vu AS (SELECT division, atom_id, count(DISTINCT circo) AS n
              FROM se_ligne WHERE atom_id IN (SELECT atom_id FROM se_lot)
             GROUP BY 1, 2)
SELECT p.division,
       (SELECT count(*) FROM se_lot)             AS attendues,
       count(*) FILTER (WHERE v.n >= 1)          AS couvertes,
       count(*) FILTER (WHERE v.n > 1)           AS doubles,
       (SELECT count(DISTINCT l.atom_id) FROM se_ligne l
         WHERE l.division = p.division
           AND l.atom_id NOT IN (SELECT atom_id FROM se_lot)) AS hors_lot
  FROM se_periode p LEFT JOIN vu v ON v.division = p.division
 GROUP BY p.division ORDER BY p.division;
-- Attendu : 80, 80, 0, 0 sur les deux lignes.
-- `hors_lot` est la colonne qui manquait : elle compte les atomes que la
-- transcription atteint SANS que la planche de 1954 les connaisse. Au premier
-- jeu elle aurait valu 48, et le defaut se serait vu tout de suite.

\echo ''
\echo '=== 4. Garde-fou : ces periodes sont-elles VIDES pour la banlieue ? ==='
-- Si une ligne sort, ce fichier remplacerait de la donnee existante au lieu de
-- combler, et il faut s'arreter pour comprendre laquelle.
SELECT p.division, count(*) AS rattachements_deja_presents
  FROM se_periode p
  JOIN membership m ON m.niveau = 'circo'
                   AND m.periode && daterange(p.du, p.au, '[)')
  JOIN atom a ON a.atom_id = m.atom_id
 WHERE a.atom_id IN (SELECT atom_id FROM se_ligne)
   AND NOT EXISTS (SELECT 1 FROM seine_circo_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle = m.membership_id::text)
 GROUP BY p.division ORDER BY p.division;
-- Attendu : aucune ligne.
--
-- Le `NOT EXISTS` est le pendant, du côté DIAGNOSTIC, du retrait de trace que
-- fait la pose : relancé à blanc après un passage, ce fichier verrait sinon
-- ses propres 160 rattachements et se dénoncerait lui-même.

\if :{?appliquer}

-- Retirer son propre passage AVANT de juger de ce qui reste — la leçon de `55`.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM seine_circo_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM seine_circo_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE seine_circo_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n
      FROM se_src s
     WHERE NOT EXISTS (SELECT 1 FROM se_ligne l
                        WHERE l.division = s.division AND l.circo = s.circo
                          AND l.jeton = s.jeton);
    IF n > 0 THEN
        RAISE EXCEPTION '% jeton(s) de la transcription ne resolvent pas. '
            'Voir la recette 2.', n;
    END IF;

    SELECT count(DISTINCT atom_id) INTO n
      FROM se_ligne WHERE atom_id NOT IN (SELECT atom_id FROM se_lot);
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) atteints par la transcription sont '
            'inconnus de la planche cantonale de 1954. Voir la recette 3, '
            'colonne hors_lot.', n;
    END IF;

    SELECT count(*) INTO n FROM (
        SELECT division FROM se_ligne GROUP BY division
         HAVING count(DISTINCT atom_id) <> 80) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'Une division ne couvre pas les 80 communes de la '
            'Seine. Voir la recette 3.';
    END IF;

    SELECT count(*) INTO n FROM (
        SELECT division, atom_id FROM se_ligne GROUP BY 1, 2
         HAVING count(DISTINCT circo) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION '% commune(s) dans deux circonscriptions a la meme '
            'date. Voir la recette 3.', n;
    END IF;

    SELECT count(*) INTO n
      FROM se_periode p
      JOIN membership m ON m.niveau = 'circo'
                       AND m.periode && daterange(p.du, p.au, '[)')
     WHERE m.atom_id IN (SELECT atom_id FROM se_ligne);
    IF n > 0 THEN
        RAISE EXCEPTION 'Ces periodes ne sont pas vides pour la banlieue : % '
            'rattachement(s) deja presents. Ce fichier COMBLE, il ne remplace '
            'pas. Voir la recette 4.', n;
    END IF;
END $$;

-- `provisoire = true` : la composition cantonale est projetée depuis 1954, pas
-- lue à la date. Le marqueur porte cette réserve, et il n'y a pas de raison de
-- le retirer tant qu'un second jalon cantonal ne l'aura pas confirmée.
WITH u AS (
    SELECT DISTINCT unit_id, circo, segment, division, regime FROM se_pose
), ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT u.unit_id, 'circo', '75', '75-' || u.circo,
           u.regime, u.segment,
           'Seine ' || u.circo || 'e circonscription (' || u.division || ')',
           true
      FROM u
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO seine_circo_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT p.unit_id, 'Seine ' || p.circo || 'e circonscription',
       p.du, p.au
  FROM se_pose p
 WHERE EXISTS (SELECT 1 FROM seine_circo_trace t
                WHERE t.quoi = 'unit' AND t.cle = p.unit_id);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT atom_id, unit_id, 'circo', du, au FROM se_pose
    RETURNING membership_id
)
INSERT INTO seine_circo_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM seine_circo_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 6. La Seine, de 1870 a 1967 : le departement est-il entier ? ==='
-- Cent atomes de 1870 a 1940 : vingt arrondissements et quatre-vingts
-- communes. A partir de 1945 Paris passe au quartier, donc 80 + 80 = 160.
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (
           WHERE a.insee_geofla ~ '^(92|93|94)') AS banlieue,
       count(DISTINCT m.atom_id) FILTER (
           WHERE a.insee_geofla !~ '^(92|93|94)') AS paris,
       count(DISTINCT m.unit_id) AS circos
  FROM (VALUES ('1875-06-01'::date), ('1900-06-01'), ('1935-06-01'),
               ('1943-06-01'), ('1950-06-01'), ('1956-06-01'),
               ('1960-06-01'), ('1967-06-01'), ('1970-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo'
                  AND u.dep = '75'
  LEFT JOIN atom a ON a.atom_id = m.atom_id
 WHERE u.unit_id IS NOT NULL
 GROUP BY d ORDER BY d;
-- Attendu : banlieue = 80 a 1875, 1900, 1935, 1950, 1956, 1960 et 1967.
-- 1943 ne rend AUCUNE ligne — l'Occupation, rien de transcrit. 1970 rend une
-- ligne a banlieue = 0 : la Seine n'existe plus, Paris garde ses quartiers.
-- Une banlieue entre 1 et 79 serait le defaut a chercher.

\echo ''
\echo '=== 7. Aucun atome dans deux circos a la meme date, France entiere ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

-- ============================================================================
-- 55_paris_circo_serie.sql — combler les deux trous parisiens qui restent
--
--   python3 circo/paris_quartiers.py     # trame des 80
--   python3 circo/paris_circo.py         # table paris_circo
--   psql -d histgis -f sql/55_paris_circo_serie.sql          -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/55_paris_circo_serie.sql
--
-- Les deux trous, et pourquoi ce sont bien des trous
-- --------------------------------------------------
-- **1863-1870.** `54` fait remonter Paris à 1815 sur la trame de Vasserot, mais
-- s'arrête en 1863 ; TRF-GIS ne commence qu'en 1870. Sept ans entre les deux,
-- que la transcription couvre par les divisions `1863-1869` et `1869-1870` —
-- neuf circonscriptions chacune, sur la trame des 80.
--
-- **1941-1986.** La couche circo est vide dans TOUTE la France entre 1941 et le
-- découpage de 1986 : le découpage de 1958 se définit par cantons, et la
-- nomenclature cantonale de ces années manque (`histgis-trou-cantonal`).
-- **Mais à Paris il se définit par QUARTIERS.** C'est ce que `note_paris.md`
-- annonce : « le premier morceau de 1958 posable, sans rien attendre ».
--
-- Ce fichier ne remplace rien
-- ---------------------------
-- Les divisions de 1876 à 1940 ne sont PAS traitées ici. TRF-GIS y pose déjà
-- des circonscriptions, au niveau de l'arrondissement entier — ce qui est faux
-- dès qu'une circonscription le coupe, et la transcription permettrait de les
-- affiner au quartier. Mais ce serait REMPLACER de la donnée existante, et cela
-- demande son propre contrôle. Ici on ne fait que combler.
--
-- Le garde-fou 3 le vérifie plutôt que de le promettre : aucune période posée
-- ne doit rencontrer un rattachement parisien déjà en base.
--
-- Ce qui reste ouvert après ce fichier
-- ------------------------------------
--   * **1848-1852** — aucune division transcrite. Quatre ans, et rien pour les
--     combler.
--   * **1941-1945** — l'Occupation. La transcription saute de 1928-1940 à
--     1945-1958.
--   * les quartiers coupés entre deux circonscriptions, ici comme en `52` :
--     nommés, pas attribués.
--
-- Réversible : `paris_serie_trace`, section 5.
-- Prérequis : `52_paris_circo_1986.sql` joué — il crée les atomes `PQ01`…`PQ80`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.paris_circo') IS NULL THEN
        RAISE EXCEPTION E'paris_circo absente.\n'
            '  python3 circo/paris_quartiers.py && python3 circo/paris_circo.py';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = 'PQ01') THEN
        RAISE EXCEPTION E'Les atomes de quartier PQ01…PQ80 n''existent pas.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/52_paris_circo_1986.sql';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les quatre divisions, et leurs bornes
--
-- Chaque division court jusqu'au début de la suivante. `1958-1986` se ferme au
-- 24 novembre 1986, date de la loi — exactement là où `52` ouvre, pour que
-- Paris n'ait pas un jour de vide entre les deux.
-- ---------------------------------------------------------------------------
-- Le régime est celui de la LOI ÉLECTORALE, pas une déduction du nombre de
-- circonscriptions. Corrigé le 21 août 2026 : les quatre divisions portaient
-- `uninominal`, et 1945-1958 sortait donc à tort sur la carte. **Les
-- législatives de 1945, 1946, 1951 et 1956 se sont tenues à la représentation
-- proportionnelle** — trois secteurs pour la Seine, ce que la transcription
-- confirme d'elle-même en ne donnant que trois circonscriptions.
--
-- Le compte aurait dû me mettre en garde : trois circonscriptions pour Paris
-- ne peut pas être un scrutin uninominal.
DROP TABLE IF EXISTS ps_periode;
CREATE TEMP TABLE ps_periode (
    periode text PRIMARY KEY, du date, au date, regime text
);
INSERT INTO ps_periode VALUES
    ('1863-1869', DATE '1863-01-01', DATE '1869-01-01', 'uninominal'),
    ('1869-1870', DATE '1869-01-01', DATE '1870-01-01', 'uninominal'),
    -- 1870-1940 : voir `56`. 1941-1945 : rien de transcrit.
    ('1945-1958', DATE '1945-01-01', DATE '1958-01-01', 'liste'),
    ('1958-1986', DATE '1958-01-01', DATE '1986-11-24', 'uninominal');

DROP TABLE IF EXISTS ps_ligne;
CREATE TEMP TABLE ps_ligne AS
SELECT p.periode, p.du, p.au, p.regime, c.circo,
       unnest(c.q_list)                                  AS quartier,
       'PQ' || lpad(unnest(c.q_list)::text, 2, '0')      AS atom_id,
       'V' || replace(p.periode, '-', '_') || '#' || c.circo AS unit_id,
       extract(year FROM p.du)::int                      AS segment,
       c.source
  FROM paris_circo c
  JOIN ps_periode p ON p.periode = c.periode;

-- Garde-fou 1 : un quartier cité par deux circonscriptions ne peut pas devenir
-- un atome unique. On pose ce qui est entier, on nomme ce qui est coupé.
DROP TABLE IF EXISTS ps_coupe;
CREATE TEMP TABLE ps_coupe AS
SELECT periode, quartier FROM ps_ligne
 GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1;

DROP TABLE IF EXISTS ps_pose;
CREATE TEMP TABLE ps_pose AS
SELECT l.* FROM ps_ligne l
 WHERE NOT EXISTS (SELECT 1 FROM ps_coupe c
                    WHERE c.periode = l.periode AND c.quartier = l.quartier);

\echo ''
\echo '=== 1. Ce que la source donne ==='
SELECT l.periode, min(l.du) AS du, max(l.au) AS au,
       count(DISTINCT l.unit_id) AS circos,
       count(DISTINCT l.quartier) AS quartiers,
       count(DISTINCT c.quartier) AS coupes,
       min(l.source) AS source
  FROM ps_ligne l
  LEFT JOIN ps_coupe c ON c.periode = l.periode
 GROUP BY l.periode ORDER BY min(l.du);

\echo ''
\echo '=== 2. Garde-fou : ces periodes sont-elles bien VIDES pour Paris ? ==='
-- Si une ligne sort, ce fichier remplacerait de la donnee existante au lieu de
-- combler — et il faut s'arreter pour comprendre laquelle.
SELECT p.periode, count(*) AS rattachements_deja_presents
  FROM ps_periode p
  JOIN membership m ON m.niveau = 'circo'
                   AND m.periode && daterange(p.du, p.au, '[)')
  JOIN atom a ON a.atom_id = m.atom_id
 WHERE a.insee_geofla LIKE '751%'
 GROUP BY p.periode ORDER BY p.periode;
-- Attendu : aucune ligne.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS paris_serie_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- RETIRER SON PROPRE PASSAGE AVANT DE VÉRIFIER, et non l'inverse.
--
-- Le garde-fou se trouvait au-dessus de ce retrait : au second passage il
-- voyait les rattachements que le fichier avait lui-même posés, les prenait
-- pour de la donnée à ne pas écraser, et refusait de tourner. Un fichier
-- rejouable doit d'abord effacer sa trace, ensuite juger de ce qui reste.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM paris_serie_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM paris_serie_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE paris_serie_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n
      FROM ps_periode p
      JOIN membership m ON m.niveau = 'circo'
                       AND m.periode && daterange(p.du, p.au, '[)')
      JOIN atom a ON a.atom_id = m.atom_id
     WHERE a.insee_geofla LIKE '751%';
    IF n > 0 THEN
        RAISE EXCEPTION 'Ces periodes ne sont pas vides pour Paris : % '
            'rattachement(s) deja presents. Ce fichier COMBLE, il ne remplace '
            'pas. Voir la recette 2.', n;
    END IF;
END $$;

-- `provisoire = true` : marqueur de prudence, par cohérence avec `54`.
-- Le régime, lui, vient désormais de `ps_periode` et non d'une constante :
-- 1863-1870 et 1958-1986 sont uninominaux, **1945-1958 est un scrutin de
-- liste** — représentation proportionnelle, trois secteurs pour la Seine.
WITH u AS (
    SELECT DISTINCT unit_id, circo, segment, periode, regime FROM ps_ligne
), ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT u.unit_id, 'circo', '75', '75-' || u.circo,
           u.regime, u.segment,
           'Paris ' || u.circo || 'e circonscription (' || u.periode || ')',
           true
      FROM u
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO paris_serie_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT l.unit_id, 'Paris ' || l.circo || 'e circonscription',
       l.du, l.au
  FROM ps_ligne l
 WHERE EXISTS (SELECT 1 FROM paris_serie_trace t
                WHERE t.quoi = 'unit' AND t.cle = l.unit_id);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT DISTINCT atom_id, unit_id, 'circo', du, au FROM ps_pose
    RETURNING membership_id
)
INSERT INTO paris_serie_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Pose ==='
SELECT quoi, count(*) FROM paris_serie_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 4. Paris, de 1815 a 2012 : la chaine est-elle continue ? ==='
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) AS quartiers,
       count(DISTINCT m.unit_id) AS circos
  FROM (VALUES ('1816-06-01'::date), ('1850-06-01'), ('1860-06-01'),
               ('1865-06-01'), ('1875-06-01'), ('1900-06-01'),
               ('1935-06-01'), ('1943-06-01'), ('1950-06-01'),
               ('1970-06-01'), ('1990-06-01'), ('2005-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN atom a ON a.atom_id = m.atom_id AND a.insee_geofla LIKE '751%'
 WHERE a.atom_id IS NOT NULL OR m.atom_id IS NULL
 GROUP BY d ORDER BY d;
-- Doivent rester VIDES : 1850 (trou 1848-1852) et 1943 (Occupation).
-- Tout le reste doit porter des circonscriptions.

\echo ''
\echo '=== 5. Quartiers coupes, non poses ==='
SELECT c.periode, c.quartier, q.nom
  FROM ps_coupe c LEFT JOIN paris_quartier q ON q.quartier = c.quartier
 ORDER BY 1, 2;

\echo ''
\echo '=== 6. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

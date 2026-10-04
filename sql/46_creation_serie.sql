-- ============================================================================
-- 46_creation_serie.sql — les communes nées PENDANT la série que `11` ne peut
--                          pas prolonger, rattachées par la filiation HAC
--
--   python3 hac/hac_filiation.py
--   psql -d histgis -f sql/46_creation_serie.sql      # depuis la RACINE
--
-- Le trou, et pourquoi il résiste à tout le reste
-- -----------------------------------------------
-- Après `11` et `15`, il reste **205 km² non couverts en 1870**, sur 39
-- communes (`10_couverture.sql`). Elles ont toutes un atome ; ce qui leur
-- manque est un rattachement à cette date. Deux familles, mesurées :
--
-- **A. Alsace-Moselle — une trentaine.** Philippsbourg, Amnéville, Mittlach,
-- Halstroff, Veckring, Ritzing, Mexy, Piennes… Leur atome commence au
-- **1ᵉʳ janvier 1919** : TRF-GIS ne couvre pas la Moselle annexée, et ces
-- communes sont nées SOUS administration allemande — Philippsbourg en 1874,
-- Amnéville en 1894, Mittlach en 1908. `11` refuse de remonter avant 1919, et
-- il a raison : son garde-fou 4 interdit de franchir l'interruption de 1871,
-- parce que les codes de canton sont réutilisés de part et d'autre.
--
-- Mais leur territoire était **français en 1870-1871**, et il appartenait à
-- leur mère : Baerenthal, Gandrange, Metzeral. Il y a donc une année à combler,
-- celle d'avant l'annexion, et une seule.
--
-- **B. Les autres — Plan-de-Cuques, et quelques communes de la Seine.**
-- Plan-de-Cuques commence en 1937 dans le canton 1324, qui n'existe pas en
-- 1870 : `11` n'a donc rien pu prolonger, faute de canton d'accueil vivant.
-- Son territoire relevait d'Allauch.
--
-- Pourquoi HAC répond ICI à la bonne question
-- -------------------------------------------
-- Un essai du 20 août 2026 avait remplacé le pari de `11` par la filiation
-- HAC, et **le contrôle Gay l'a rejeté** : 11 paris perdus contre 4. La cause
-- est que HAC ne nomme qu'une mère quand il y en a plusieurs, et surtout que la
-- question de `11` porte sur le CANTON D'ATTRIBUTION à la création, que la
-- filiation ne donne pas. Voir l'en-tête de `11_scission.sql`.
--
-- **Ici la situation est inverse.** Ces communes n'ont aucun rattachement à
-- prolonger : il n'existe pas de réponse concurrente, meilleure ou pire. La
-- seule question possible est « à qui ce territoire appartenait-il ? », et
-- c'est exactement ce que HAC énonce. Une source ne vaut pas par son prestige
-- mais par l'adéquation de sa réponse à la question posée.
--
-- Contrôlé sur pièce : Wikipédia, pour Plan-de-Cuques, écrit « la commune fut
-- fondée en 1937, date à laquelle elle s'est dissociée de la commune
-- d'Allauch », et son blason porte le millésime 1937 avec les armes d'Allauch.
-- Voie publique, vérifiable, CC BY-SA, indépendante de HAC.
--
-- La règle
-- --------
--   « Une commune née pendant la série, dont l'atome n'a aucun rattachement au
--     début de celle-ci, reçoit la chronologie de la mère que HAC nomme, du
--     début de la série jusqu'à sa création — ou jusqu'à son premier
--     rattachement propre si celui-ci vient plus tôt. »
--
-- Cinq garde-fous
-- ---------------
--   1. La filiation vient de HAC, résolue de façon UNIQUE (`voie = 'unique'`).
--      Une mère homonyme ou introuvable écarte le cas.
--   2. La mère est retrouvée par son `cassini`, jamais par son nom : c'est la
--      clé que `hac_filiation.py` a déjà résolue, et la seule sûre.
--   3. Les atomes-mères doivent être UNANIMES sur la période. Sinon on
--      s'abstient — on ne tranche pas entre deux cantons.
--   4. Rien n'est posé sur une période déjà occupée.
--   5. Le polygone doit être ORPHELIN à cette date : si un autre atome le
--      porte déjà et se trouve rattaché, il n'y a pas de trou, et le combler
--      compterait le territoire deux fois. C'est la leçon du garde-fou 6 de
--      `41_retablissement.sql`.
--
-- Réversible : `creation_serie_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- Prérequis : `11` et `15` joués, `hac/hac_filiation.csv` engendré.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?hac}
\else
  \set hac 'hac/hac_filiation.csv'
\endif

-- ---------------------------------------------------------------------------
-- 0. La filiation, et la trace
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS hac_filiation;
CREATE TABLE hac_filiation (
    cassini_fille text, nom_fille text, dep text, annee int,
    nom_mere_hac text, cassini_mere text, voie text
);
\set cmd '\\copy hac_filiation FROM ' :'hac' ' WITH (FORMAT csv, HEADER true)'
:cmd
CREATE INDEX hac_filiation_idx ON hac_filiation (cassini_fille);

CREATE TABLE IF NOT EXISTS creation_serie_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    cassini_fille text NOT NULL,
    cassini_mere  text NOT NULL,
    nom_mere_hac  text,
    creee_en      int,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM creation_serie_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE creation_serie_trace;

-- ---------------------------------------------------------------------------
-- 1. Les cas : un atome, aucun rattachement au début de la série, une mère
-- ---------------------------------------------------------------------------
-- `d0` au niveau CANTON, et non tous niveaux confondus — corrigé le
-- 6 septembre 2026, en même temps que `42`, qui portait le même défaut et
-- l'a fait voir en s'arrêtant.
--
-- Ce fichier sélectionne « un atome sans aucun rattachement au début de la
-- série », et compare l'année de création HAC à ce début. Depuis `54`, qui
-- fait commencer Paris en 1815, `min(valid_from)` sur tout `membership` vaut
-- **1815-01-01** : `f.annee > 1815` est vrai pour presque tout, et le
-- garde-fou 5 — « le territoire n'est rattaché par aucun atome à cette
-- date » — devient vide de sens, seuls les 48 quartiers de Vasserot ayant un
-- rattachement à cette date.
--
-- La série que ce fichier raisonne est la série CANTONALE, que rien ne
-- peuple avant 1870 : `54`, `55`, `56`, `57`, `90` et `91` ne posent que du
-- `circo`. L'assertion ci-dessous arrête le fichier si cela cesse d'être
-- vrai, plutôt que de le laisser se dégrader sans le dire.
--
-- *Contrairement à `42`, ce fichier n'a pas d'alarme sur l'effectif : il
-- aurait POSÉ. C'est l'arrêt de `42`, trois marches plus haut, qui a fait
-- regarder ici.*
DO $$
DECLARE d date;
BEGIN
    SELECT min(valid_from) INTO d FROM membership WHERE niveau = 'canton';
    IF d IS NULL THEN
        RAISE EXCEPTION 'Aucun rattachement cantonal : la base n''est pas chargée.';
    END IF;
    IF d <> DATE '1870-01-01' THEN
        RAISE EXCEPTION E'La serie cantonale commence en %, et non 1870-01-01.\n'
            '  Ce fichier compare l''annee de creation HAC au debut de la serie\n'
            '  et teste qu''aucun atome ne portait le territoire a cette date.\n'
            '  Si le canton remonte plus haut, les deux tests changent de sens.', d;
    END IF;
END $$;

DROP TABLE IF EXISTS cs_cas;
CREATE TEMP TABLE cs_cas AS
WITH debut AS (SELECT min(valid_from) AS d0 FROM membership
                WHERE niveau = 'canton')
SELECT a.atom_id, a.cassini, a.insee_geofla, d.d0 AS depuis,
       f.cassini_mere, f.nom_mere_hac, f.annee AS creee_en,
       -- la fenêtre s'arrête à la création, ou au premier rattachement propre
       -- si celui-ci vient plus tôt : on ne recouvre jamais ce qui existe.
       least(make_date(f.annee, 1, 1),
             coalesce((SELECT min(m.valid_from) FROM membership m
                        WHERE m.atom_id = a.atom_id AND m.niveau = 'canton'),
                      make_date(f.annee, 1, 1))) AS jusqu_a
  FROM atom a
  CROSS JOIN debut d
  JOIN hac_filiation f ON f.cassini_fille = a.cassini AND f.voie = 'unique'
 WHERE NOT a.fraction
   AND a.insee_geofla IS NOT NULL
   AND f.annee > extract(year FROM d.d0)::int
   -- garde-fou 5 : le TERRITOIRE ne doit être rattaché par AUCUN atome au
   -- début de la série. On interroge le polygone, pas l'atome.
   AND NOT EXISTS (
       SELECT 1 FROM atom_geom ag
         JOIN membership m ON m.atom_id = ag.atom_id AND m.niveau = 'canton'
                          AND m.periode @> d.d0
        JOIN atom_geom ai ON ai.atom_id = a.atom_id
       WHERE ag.geom && ai.geom
         AND ST_Contains(ag.geom, ST_PointOnSurface(ai.geom)));

DELETE FROM cs_cas WHERE jusqu_a <= depuis;

\echo ''
\echo '=== 1. Les cas retenus ==='
SELECT c.insee_geofla, c.cassini, c.nom_mere_hac, c.cassini_mere,
       c.creee_en, c.depuis, c.jusqu_a
  FROM cs_cas c ORDER BY c.insee_geofla;
-- Attendu : une trentaine de communes d'Alsace-Moselle, dont la fenêtre se
-- ferme en 1871 (leur atome commence en 1919, donc `jusqu_a` vaut 1919 pour
-- les créations postérieures — l'intersection avec la mère fera le reste),
-- plus Plan-de-Cuques et quelques communes de la Seine.

-- ---------------------------------------------------------------------------
-- 2. Ce que la mère portait, découpé à la fenêtre
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cs_periode;
CREATE TEMP TABLE cs_periode AS
WITH brut AS (
    SELECT c.atom_id, mm.unit_id, mm.niveau,
           lower(mm.periode * daterange(c.depuis, c.jusqu_a, '[)')) AS valid_from,
           upper(mm.periode * daterange(c.depuis, c.jusqu_a, '[)')) AS valid_to,
           c.cassini AS cassini_fille, c.cassini_mere, c.nom_mere_hac, c.creee_en
      FROM cs_cas c
      JOIN atom am ON am.cassini = c.cassini_mere AND NOT am.fraction
      JOIN membership mm ON mm.atom_id = am.atom_id
                        AND mm.periode && daterange(c.depuis, c.jusqu_a, '[)')
     WHERE NOT isempty(mm.periode * daterange(c.depuis, c.jusqu_a, '[)'))
)
-- garde-fou 3 : unanimité des mères
SELECT atom_id, min(unit_id) AS unit_id, niveau, valid_from, valid_to,
       cassini_fille, cassini_mere, nom_mere_hac, creee_en
  FROM brut
 GROUP BY atom_id, niveau, valid_from, valid_to,
          cassini_fille, cassini_mere, nom_mere_hac, creee_en
HAVING count(DISTINCT unit_id) = 1;

-- garde-fou 4 : rien sur une période déjà occupée
DELETE FROM cs_periode p
 WHERE EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
                  AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

\echo ''
\echo '=== 2. Ce qui va être posé ==='
SELECT niveau, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM cs_periode GROUP BY niveau ORDER BY niveau;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM cs_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO creation_serie_trace (membership_id, atom_id, unit_id, niveau,
                                  valid_from, valid_to, cassini_fille,
                                  cassini_mere, nom_mere_hac, creee_en)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.cassini_fille, p.cassini_mere,
       p.nom_mere_hac, p.creee_en
  FROM ins i
  JOIN cs_periode p ON p.atom_id = i.atom_id AND p.niveau = i.niveau
                   AND p.valid_from = i.valid_from;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Posé, par commune ==='
SELECT a.insee_geofla, t.nom_mere_hac, t.creee_en,
       string_agg(DISTINCT t.niveau, ', ') AS niveaux,
       count(*) AS lignes, min(t.valid_from) AS depuis, max(t.valid_to) AS jusqu_a
  FROM creation_serie_trace t
  JOIN atom a ON a.atom_id = t.atom_id
 GROUP BY 1, 2, 3 ORDER BY 1;

\echo ''
\echo '=== 4. Plan-de-Cuques, contrôlé sur pièce ==='
\echo '    Wikipédia : « fondée en 1937, date à laquelle elle s''est dissociée'
\echo '    de la commune d''Allauch ». Elle doit donc relever du canton'
\echo '    d''Allauch de 1870 à 1937.'
SELECT m.niveau, m.unit_id, coalesce(u.nom, '?') AS unite,
       m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 46' END AS origine
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN creation_serie_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '13075' AND m.valid_from < DATE '1941-01-01'
 ORDER BY m.niveau, m.valid_from;

\echo ''
\echo '=== 5. Aucun atome dans deux unités du même niveau à la même date ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode FROM membership
         GROUP BY 1, 2, 3 HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY niveau;

\echo ''
\echo '=== 6. Aucun chevauchement ==='
SELECT count(*) AS chevauchements
  FROM membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

-- ---------------------------------------------------------------------------
-- 5. Ce qui reste, et pour défaire
--
-- La mesure qui fait foi est extérieure :  cd sql && ./controle_gay.sh
--
-- Attendu : le territoire non couvert en 1870 BAISSE depuis 205 km², et le
-- nombre d'atomes mal placés ne monte pas. S'il monte, HAC nomme une mère dont
-- le territoire ne vient pas — comme lors de l'essai sur `11` — et il faut
-- défaire plutôt qu'expliquer :
--
--   DELETE FROM membership m USING creation_serie_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE creation_serie_trace;
-- ---------------------------------------------------------------------------

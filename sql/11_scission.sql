-- ============================================================================
-- histgis — 11_scission.sql : combler les trous de couverture
--
-- Le problème, établi par 09 et 10
-- --------------------------------
-- Il manque 5 926 km² à notre couverture en 1870, 743 en 1940, et l'écart est
-- à sens unique : nous ne revendiquons jamais un territoire de trop. Ce sont
-- des communes de la trame 2011 qu'aucun atome ne réclame — celles nées d'une
-- scission postérieure à la date.
--
-- Ce qui rend le correctif bon marché
-- -----------------------------------
-- L'essentiel de ces communes est né ENTRE 1870 ET 1940. TRF-GIS les suit :
-- elles ont déjà un atome, dont le `membership` commence à leur année de
-- création. Le Grau-du-Roi 1879, La Londe-les-Maures 1901,
-- Port-Saint-Louis-du-Rhône 1904, Le Lavandou 1913, Saint-Martin-de-Crau 1925.
-- Rien à aller chercher dehors : il suffit de prolonger leur rattachement vers
-- l'arrière.
--
-- Ce que cela suppose d'admettre
-- ------------------------------
-- Que le territoire d'une commune soit rattaché à un canton avant que la
-- commune existe. C'est cohérent avec le modèle : l'atome est défini comme la
-- plus petite unité au rattachement STABLE, pas comme une commune. Le
-- territoire du futur Grau-du-Roi appartenait bien à un canton en 1870 — celui
-- d'Aigues-Mortes, dont il a été détaché.
--
-- L'hypothèse de fond : une commune nouvelle reste dans le canton de sa mère.
-- Vraie presque toujours, fausse parfois. Elle n'est pas invérifiable —
-- `controle_gay.sh` la note, avant et après.
--
-- Quatre garde-fous
-- -----------------
--   1. Seul le PREMIER rattachement est prolongé. Les trous en milieu de
--      chronologie ne sont pas comblés : les 1 690 atomes absents de 1871 à
--      1919 sont l'Alsace-Moselle, et ce trou-là doit rester.
--   2. Le prolongement suit la chronologie du canton d'accueil, pas le
--      calendrier. Une commune alsacienne créée sous administration allemande
--      et apparue en 1919 ne sera prolongée que sur les périodes où son canton
--      a lui-même des membres — donc pas entre 1871 et 1919.
--   3. Les recodages sont écartés. Si un autre atome portant le même code
--      INSEE était actif juste avant, le territoire était déjà couvert :
--      prolonger le doublerait au lieu de le combler.
--   4. Le prolongement ne franchit pas une interruption du canton d'accueil.
--
-- Le quatrième mérite un mot, il a été ajouté après coup. Les garde-fous 1 et
-- 2 ne suffisaient pas : ils laissaient passer les cantons d'Alsace-Moselle,
-- dont le canton d'accueil A des membres en 1870 comme en 1921 — mais pas les
-- mêmes cantons. TRF-GIS réutilise les codes `depct` de part et d'autre de la
-- rupture de 1871 : le 5705 de 1870 (numérotation de la Meurthe) et le 5705 de
-- 1921 (Moselle reconstituée) sont deux cantons différents sous une même
-- clé. Prolonger jusqu'en 1870 rattachait donc la commune à un canton qui
-- n'était pas le sien.
--
-- Correction : on ne garde que la plage d'existence CONTINUE du canton
-- d'accueil aboutissant à la date d'apparition. Pour une commune mosellane
-- apparue en 1921, cela donne 1919-1920 et rien avant — ce qui est exact.
-- Le prix est un peu de territoire alsacien-mosellan qui redevient non
-- couvert avant 1871, et c'est honnête : nous ne savons pas à quel canton il
-- appartenait.
--
-- Ce qui a été essayé, mesuré, et ABANDONNÉ — 20 août 2026
-- ---------------------------------------------------------
-- Le pari ci-dessus prolonge l'unité que la commune elle-même rejoint à sa
-- création. HAC — *Des villages de Cassini aux communes d'aujourd'hui* — nomme
-- sa MÈRE, pour 444 créations de la fenêtre sur 447 (`extraction/hac/hac_filiation.py`).
-- Il était tentant de bâtir sur ce fait plutôt que sur un pari : recopier la
-- chronologie de la mère, année par année, et ne garder le pari qu'en repli.
--
-- **C'était plus mauvais.** Mesuré par `controle_gay.sh`, avant et après :
--
--                        paris perdus   taux      atomes mal placés (1870)
--   pari (état actuel)      4 / 414     99,0 %              151
--   filiation HAC          11 / 425     97,4 %              155
--
-- Les sept cas où les deux voies divergeaient sont passés dans le canton de la
-- mère nommée, et **Gay les compte tous les sept comme mal placés** :
-- Pornichet, Charantonnay, Aboën, Bagnoles-de-l'Orne, Saint-Edmond,
-- Le Pont-de-Claix, Beauchamp.
--
-- La cause est claire, et elle était écrite comme réserve dans
-- `45_controle_hac.sql` : **HAC ne nomme qu'une mère quand il y en a
-- plusieurs.** Pornichet est créée en 1900 à partir d'Escoublac ET de
-- Saint-Nazaire ; HAC ne cite qu'Escoublac. Le canton d'attribution à la
-- création reflète où le territoire se trouvait administrativement ; la mère
-- citée reflète l'origine paroissiale. Ce ne sont pas les mêmes faits.
--
-- Ce qu'il faut en retenir. Une source qui nomme un fait n'est pas
-- automatiquement meilleure qu'un pari mesuré : encore faut-il qu'elle nomme
-- LE fait dont on a besoin. Ici la filiation est vraie et ne répond pas à la
-- question posée, qui porte sur le canton.
--
-- HAC garde ses deux emplois utiles : **contrôler** ce pari
-- (`45_controle_hac.sql`, qui ne modifie rien) et nommer la mère des ~37
-- communes nées pendant la série et absentes de TRF-GIS, que ni `11` ni `15`
-- ne peuvent traiter. Voir `RESTE_A_FAIRE.md`.
--
-- Réversible : toutes les lignes ajoutées sont tracées dans `scission_trace`,
-- et la section 5 donne la commande pour les retirer.
--
-- Prérequis : base chargée (load.sh, 05 → 06 → 07). 08-10 non nécessaires.
-- Rejouable : le script retire ses propres lignes avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.membership') IS NULL THEN
        RAISE EXCEPTION 'membership absente : lancer load.sh avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Table de trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scission_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    debut_reel    date NOT NULL,   -- date d'apparition réelle de l'atome
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM scission_trace t WHERE t.membership_id = m.membership_id);
TRUNCATE scission_trace;

-- ---------------------------------------------------------------------------
-- 1. Les candidats
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS scission_candidat;
CREATE TABLE scission_candidat AS
WITH bornes AS (
    SELECT min(valid_from) AS d0, max(valid_to) AS d1 FROM membership
),
-- première apparition de chaque atome, par niveau
debut AS (
    SELECT m.atom_id, m.niveau, min(m.valid_from) AS debut
    FROM   membership m
    GROUP  BY 1, 2
    HAVING min(m.valid_from) > (SELECT d0 FROM bornes)
),
-- l'unité rejointe à cette première apparition
cible AS (
    SELECT d.atom_id, d.niveau, d.debut, m.unit_id
    FROM   debut d
    JOIN   membership m ON m.atom_id = d.atom_id
                       AND m.niveau  = d.niveau
                       AND m.valid_from = d.debut
)
SELECT c.atom_id, c.niveau, c.debut, c.unit_id,
       a.insee_geofla,
       a.fraction,
       -- garde-fou 3 : un autre atome portait-il déjà ce code juste avant ?
       EXISTS (
           SELECT 1
           FROM   atom ay
           JOIN   membership my ON my.atom_id = ay.atom_id AND my.niveau = c.niveau
           WHERE  ay.atom_id <> c.atom_id
             AND  ay.insee_geofla IS NOT NULL
             AND  ay.insee_geofla = a.insee_geofla
             AND  my.periode @> (c.debut - 1)
       ) AS recodage
FROM   cible c
JOIN   atom a ON a.atom_id = c.atom_id;

CREATE INDEX scission_candidat_idx ON scission_candidat (atom_id, niveau);

\echo ''
\echo '============================================================'
\echo ' SCISSIONS — prolongement des rattachements vers l''arrière'
\echo '============================================================'

\echo ''
\echo '=== 1. Atomes apparus en cours de série ==='
SELECT niveau,
       count(*)                                   AS candidats,
       count(*) FILTER (WHERE recodage)           AS ecartes_recodage,
       count(*) FILTER (WHERE fraction)           AS dont_fractions,
       count(*) FILTER (WHERE insee_geofla IS NULL) AS sans_code_insee,
       min(debut)                                 AS plus_tot,
       max(debut)                                 AS plus_tard
FROM   scission_candidat GROUP BY niveau ORDER BY niveau;

\echo ''
\echo '--- répartition des apparitions par décennie (niveau canton) ---'
SELECT (extract(decade FROM debut) * 10)::int AS decennie,
       count(*) FILTER (WHERE NOT recodage) AS retenus,
       count(*) FILTER (WHERE recodage)     AS ecartes
FROM   scission_candidat WHERE niveau = 'canton'
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 2. Les périodes à combler
--
-- Année par année, on ne retient que celles où le canton d'accueil a
-- lui-même au moins un membre — c'est le garde-fou 2. Les années retenues sont
-- ensuite recollées en intervalles continus (îlots), pour ne pas gonfler
-- `membership` d'une ligne par an.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS scission_ilot;
CREATE TABLE scission_ilot AS
WITH bornes AS (
    SELECT min(valid_from) AS d0, max(valid_to) AS d1 FROM membership
),
annees AS (
    SELECT generate_series(extract(year FROM d0)::int,
                           extract(year FROM d1)::int - 1) AS y
    FROM   bornes
),
vivant AS (
    SELECT c.atom_id, c.niveau, c.unit_id, c.debut, a.y
    FROM   scission_candidat c
    CROSS  JOIN annees a
    WHERE  NOT c.recodage
      -- un atome sans code INSEE n'a pas de polygone : le prolonger
      -- n'apporterait rien et alourdirait `membership` pour rien
      AND  c.insee_geofla IS NOT NULL
      -- l'année entière doit tenir AVANT la date d'apparition. Le test porte
      -- sur la fin de l'année et non sur son début : si une apparition
      -- tombait en cours d'année, un test sur le 1er janvier laisserait
      -- l'intervalle déborder sur `debut` et la contrainte EXCLUDE
      -- refuserait l'insertion.
      AND  make_date(a.y + 1, 1, 1) <= c.debut
      AND  EXISTS (
               SELECT 1 FROM membership mu
               WHERE  mu.unit_id = c.unit_id
                 AND  mu.niveau  = c.niveau
                 AND  mu.periode @> make_date(a.y, 6, 1)
           )
),
-- gaps and islands : y - rang est constant sur une suite d'années consécutives
iles AS (
    SELECT atom_id, niveau, unit_id, debut, y,
           y - row_number() OVER (PARTITION BY atom_id, niveau, unit_id ORDER BY y) AS ilot
    FROM   vivant
),
groupes AS (
    SELECT atom_id, niveau, unit_id, debut,
           min(y) AS y_min, max(y) AS y_max, count(*) AS n_annees
    FROM   iles
    GROUP  BY atom_id, niveau, unit_id, debut, ilot
)
-- garde-fou 4 : seul l'îlot qui TOUCHE la date d'apparition est retenu. Les
-- îlots antérieurs sont séparés de `debut` par une interruption du canton
-- d'accueil — franchir cette interruption, c'est supposer que le canton est
-- resté le même de part et d'autre, ce que la rupture de 1871 dément.
SELECT atom_id, niveau, unit_id, debut,
       make_date(y_min, 1, 1)     AS valid_from,
       make_date(y_max + 1, 1, 1) AS valid_to,
       n_annees,
       (y_max = extract(year FROM debut)::int - 1) AS retenu
FROM   groupes;

DROP TABLE IF EXISTS scission_periode;
CREATE TABLE scission_periode AS
SELECT atom_id, niveau, unit_id, debut, valid_from, valid_to, n_annees
FROM   scission_ilot WHERE retenu;

\echo ''
\echo '=== 2. Périodes reconstituées ==='
SELECT niveau,
       count(DISTINCT atom_id) AS atomes,
       count(*)                AS intervalles,
       sum(n_annees)           AS annees_comblees,
       round(avg(n_annees), 1) AS annees_par_atome
FROM   scission_periode GROUP BY niveau ORDER BY niveau;

\echo ''
\echo '--- îlots écartés par le garde-fou 4 ---'
\echo '    Périodes où le canton d''accueil existait, mais séparées de la date'
\echo '    d''apparition par une interruption. Presque toujours la rupture de'
\echo '    1871 en Alsace-Moselle : le canton portant ce code avant 1871 n''est'
\echo '    pas celui qui porte le même code après 1919.'
SELECT niveau,
       count(*) FILTER (WHERE retenu)     AS ilots_retenus,
       count(*) FILTER (WHERE NOT retenu) AS ilots_ecartes,
       sum(n_annees) FILTER (WHERE NOT retenu) AS annees_ecartees
FROM   scission_ilot GROUP BY niveau ORDER BY niveau;

\echo ''
\echo '--- les 15 plus longs îlots écartés ---'
SELECT atom_id, niveau, unit_id, valid_from, valid_to, debut, n_annees
FROM   scission_ilot WHERE NOT retenu
ORDER  BY n_annees DESC LIMIT 15;

-- ---------------------------------------------------------------------------
-- 3. Insertion
--
-- La contrainte EXCLUDE ne peut pas se plaindre : toutes les périodes posées
-- sont antérieures à `debut`, où l'atome n'avait par définition aucun
-- rattachement. Si elle se plaint quand même, c'est que le raisonnement est
-- faux quelque part — et c'est très bien qu'elle le dise.
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to
    FROM   scission_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO scission_trace (membership_id, atom_id, unit_id, niveau,
                            valid_from, valid_to, debut_reel)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.debut
FROM   ins i
JOIN   scission_periode p ON p.atom_id = i.atom_id
                         AND p.niveau  = i.niveau
                         AND p.valid_from = i.valid_from;

ANALYZE membership;

\echo ''
\echo '=== 3. Ce qui a été posé ==='
SELECT niveau, count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   scission_trace GROUP BY niveau ORDER BY niveau;

-- ---------------------------------------------------------------------------
-- 4. Effet sur la couverture
--
-- Indicateur, pas mesure : la somme des surfaces majore le gain réel, deux
-- atomes pouvant partager un polygone. La mesure qui fait foi est celle de
-- `controle_gay.sh`, contre une source extérieure.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Surface rendue à la couverture (majorant) ==='
SELECT d::date AS date,
       count(DISTINCT t.atom_id)                          AS atomes_ajoutes,
       round((sum(ST_Area(g.geom)) / 1e6)::numeric, 0)    AS km2
FROM   (VALUES ('1870-06-01'), ('1900-06-01'), ('1940-06-01')) AS v(d)
JOIN   scission_trace t
       ON t.niveau = 'canton'
      AND daterange(t.valid_from, t.valid_to, '[)') @> v.d::date
JOIN   atom_geom g ON g.atom_id = t.atom_id
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- les 20 plus grandes surfaces rendues, à 1870 ---'
SELECT t.atom_id, a.insee_geofla, t.unit_id, t.debut_reel,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
FROM   scission_trace t
JOIN   atom a      ON a.atom_id = t.atom_id
JOIN   atom_geom g ON g.atom_id = t.atom_id
WHERE  t.niveau = 'canton'
  AND  daterange(t.valid_from, t.valid_to, '[)') @> '1870-06-01'::date
ORDER  BY ST_Area(g.geom) DESC LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. Recette et réversibilité
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recette ==='
\echo '--- chevauchements introduits (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- effectifs après correctif ---'
\echo '    n_unites et n_departements doivent être inchangés : on n''ajoute'
\echo '    aucune unité. n_atomes augmente, c''est tout l''objet du script.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1885-06-01'), ('1914-06-01'), ('1940-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'canton'
ORDER  BY 1;

\echo ''
\echo 'Pour tout défaire :'
\echo '  DELETE FROM histgis.membership m USING histgis.scission_trace t'
\echo '   WHERE m.membership_id = t.membership_id;'
\echo '  TRUNCATE histgis.scission_trace;'
\echo ''
\echo 'Pour mesurer le gain contre Gay : cd sql && ./controle_gay.sh'

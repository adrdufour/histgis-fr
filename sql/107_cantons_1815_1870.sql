-- ============================================================================
-- histgis — 107_cantons_1815_1870.sql : les CANTONS de 1815 à 1870,
--                                       France entière, en une passe
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -P pager=off -f sql/107_cantons_1815_1870.sql          -- à blanc
--   psql -d histgis -P pager=off -1 -v appliquer=1 \
--        -f sql/107_cantons_1815_1870.sql > build/p107.log
--   psql -d histgis -1 -v retirer=1 -f sql/107_cantons_1815_1870.sql      -- tout retirer
--
-- Prérequis : ceux de `106` — `82` (atom_geom_anr, anr_commune), `15`
-- (creation_trace), `64` (c15_composition), `39` (la Meurthe rendue au 54),
-- `05` (atom_geom, repli géométrique). Indépendant des circos : peut passer
-- avant ou après `106`.
--
-- POURQUOI CE FICHIER
-- ===================
-- `106` a posé les CIRCONSCRIPTIONS 1815-1870 dans 86 départements, mais pas
-- les cantons : son option `-v cantons=1` remontait le canton de 1870 tel
-- quel jusqu'en 1815, et l'atlas montre que c'est faux à quelques endroits.
-- Résultat : de 1815 à 1869, la carte avait des circos et AUCUN canton (sauf
-- l'Yonne, `105`). Ce fichier comble ce trou (remarque d'Adrien, 6 octobre
-- 2026).
--
-- CE QU'IL AFFIRME
-- ================
-- L'hypothèse est celle de `106` : un atome était, avant 1870, dans son
-- canton de 1870. Elle est vraie partout où ni l'atlas ni ANR ne disent le
-- contraire ; elle a été MESURÉE dans l'Yonne seulement (`diag_yonne_1815`).
-- Chaque atome est posé de max(début, naissance) au 1er janvier 1870 :
--   * début = la première division de `c15_composition` où figure son canton
--     (1815 presque partout ; 1860 pour la Savoie, la Haute-Savoie et le comté
--     de Nice ; 1820 pour Montbéliard et Audincourt, doubistes en 1816) ; à
--     défaut, la première division du département ; à défaut (l'Aveyron, non
--     photographié), 1815 ;
--   * naissance = celle de `106` (premier polygone ANR, commune-mère pour les
--     fractions, mères de `creation_trace` pour les atomes N). Un atome sans
--     naissance connue n'est pas posé.
--
-- LES EXCEPTIONS DE L'ATLAS — les tables t107_suit et t107_avant ci-dessous
-- ==========================================================================
-- Les cartes de Gaudillère datent un changement à la carte près (1815, 1820,
-- 1831, 1848, 1852, 1857, 1863, 1869) : la date posée est celle de la
-- PREMIÈRE carte qui montre le nouvel état, comme pour les circos.
--
--   « suit » — canton de 1870 qui n'existe pas encore : avant la date, ses
--   atomes vont au canton dont il est issu.
--     22  Étables                < 1831  le canton voisin le plus proche  DOUTE
--     26  Saint-Paul-Trois-Ch.   < 1852  Pierrelatte
--     30  Bessèges               < 1863  Saint-Ambroix
--     69  Amplepuis              < 1870  Thizy
--     70  Marnay                 < 1870  Gy ou Pesmes, au plus proche     DOUTE
--     71  Le Creusot             < 1870  Montcenis   (canton de 1874 : 1870-1874
--                                                     reste faux dans la base)
--     83  Le Luc                 < 1831  Besse
--     83  Solliès-Pont           < 1831  Cuers
--     83  La Seyne-sur-Mer       < 1870  Ollioules
--   Trouville-sur-Mer (14) et Montceau-les-Mines (71), que l'atlas ne dessine
--   pas non plus, n'existent pas dans la trame de 1870 : leurs communes y sont
--   déjà dans Pont-l'Évêque et Mont-Saint-Vincent. Rien à faire (recette 2 du
--   premier passage, 6 octobre 2026).
--   Quand l'atlas donne deux mères, ou n'en donne pas, chaque atome va au
--   candidat le plus proche (distance, puis longueur de frontière commune) :
--   la carte de 1870 n'a pas de quoi mieux faire.
--
--   « avant » — cantons de 1870 issus d'une scission : avant la date, leurs
--   atomes forment une unité NOUVELLE, provisoire, sans numéro INSEE.
--     03  C03-Montluçon            < 1863  Montluçon-Est + -Ouest + Commentry
--     30  C30-Alès                 < 1863  Alès-Est + Alès-Ouest
--     42  C42-Saint-Étienne-Est    < 1863  Saint-Étienne-Nord-Est + -Sud-Est
--     42  C42-Saint-Étienne-Ouest  < 1863  Saint-Étienne-Nord-Ouest + -Sud-Ouest
--     68  C68-Mulhouse             < 1863  Mulhouse-Nord + Mulhouse-Sud
--   Saint-Étienne : SEE = NE + SE, SEO = NO + SO est l'approximation de
--   `regles_1815_21_63.py`, pas une lecture.
--
-- LES COMMUNES QUI ONT CHANGÉ DE CANTON, LUES COMMUNE PAR COMMUNE
-- ================================================================
-- `cantons/changements_communes_1815_1870.csv` (chargé aussi par `106`) :
-- une ligne par commune, son canton avant la DATE EXACTE de l'acte, son
-- canton de 1870 après ; `cree` = oui quand l'acte crée ce canton (tous ses
-- atomes doivent alors avoir une ligne : garde-fou 3 ter). Plus fin que « suit » : la mère est dite commune par
-- commune, et la date est celle de l'acte, pas celle d'une carte.
--     01  Villars  < 18.7.1868  L. 18.7.1868 (annexe VII p.787) :
--         Villars, Bouligneux, Lapeyrouse, Monthieux  <- Saint-Trivier-sur-M.
--         Marlieux, St-Germain-sur-Renon, St-Paul-de-Varax  <- Chalamont
--         Birieux  <- Meximieux ;  La Chapelle-du-Châtelard  <- Châtillon-
--         sur-Chalaronne (« Chatillon » de l'annexe : pas Châtillon-de-
--         Michaille, sans contact avec la Dombes).
--   L'atlas ne dessine Villars sur aucune carte 1815-1870 : la création de
--   1868 tombe entre ses cartes de 1863 et 1869 (remarque d'Adrien, 10
--   octobre 2026).
--
-- CE QUI N'EST PAS TRAITÉ, VOLONTAIREMENT
-- =======================================
--   * Les « fusions » de `regles_*` qui ne sont que des pastilles non
--     détaillées (Valence, Morlaix, Rochefort, Roubaix, Strasbourg, Lyon,
--     Lille, Marseille, Le Mans) : la carte ne dessine pas la limite, cela ne
--     veut pas dire qu'il n'y avait qu'un canton. Posés comme en 1870.
--   * Vitré-Nord/-Sud (avant 1857) = Vitré-Est/-Ouest : partage différent
--     probable, non lu. Posés comme en 1870.
--   * Ghisoni (20), que l'atlas ne nomme pas : absence de nom sur une petite
--     carte, pas preuve d'inexistence. Posé comme en 1870. (Villars (01),
--     longtemps rangé ici, est créé en 1868 : voir le CSV ci-dessus.)
--   * Caen-Nord/-Sud (1815) = Caen-Est/-Ouest : idem.
--   * L'arrondissement de Grasse (varois jusqu'en 1860, au 06 dans la base) :
--     ses cantons commencent en 1863 comme ses circos. Trou connu.
--   * Les communes qui ont changé de canton SANS que l'atlas le montre : non
--     mesuré hors de l'Yonne.
--   * 75 (la Seine : arrondissements de Paris avant 1860, annexion — à faire à
--     part), 89 (posé par `105`), 57 (pas de trame de 1870).
--
-- LES NOMS
-- ========
-- Chaque canton reçoit une `unit_version` de son premier rattachement au
-- 1er janvier 1870, au nom qu'il porte en 1870 — ou, avant la date de la
-- table t107_nom, au nom que lui donne l'atlas (chef-lieu transféré :
-- Saint-Martin-de-Valgalgues pour La Grand-Combe avant 1863, etc.). Une
-- version n'est posée que si l'unité n'en a aucune qui chevauche (recette 6).
--
-- CE QUI EXISTE DÉJÀ N'EST PAS REMPLACÉ
-- =====================================
-- Si un atome a déjà un rattachement cantonal avant 1870 (l'Yonne, une
-- pose locale), la période posée par ce fichier s'ARRÊTE au début du premier
-- rattachement existant, ou n'est pas posée s'il couvre déjà son début.
-- Recette 4 : ce qui est rogné, par département.
--
-- Réversible : `canton_1815_trace`. Le fichier retire sa trace avant de
-- reposer, et se rejoue sans risque. `-v retirer=1` retire et s'arrête.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set d70 '1870-01-01'

CREATE TABLE IF NOT EXISTS canton_1815_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE canton_1815_trace;
\echo 'Trace de 107 retirée.'
\quit
\endif

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL
       OR to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql (et charger anr_commune).';
    END IF;
    IF to_regclass('histgis.creation_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : creation_trace absente (sql/15_creation_arriere.sql).';
    END IF;
    IF to_regclass('histgis.c15_composition') IS NULL THEN
        RAISE EXCEPTION E'PRÉREQUIS : c15_composition absente.\n'
            '  psql -d histgis -f sql/64_composition_1815_stage.sql';
    END IF;
    IF to_regclass('histgis.atom_geom') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : atom_geom absente (sql/05_geom.sql).';
    END IF;
END $$;

-- La réparation des noms de `106` (deux U+FFFD pour une lettre accentuée).
CREATE OR REPLACE FUNCTION pg_temp.repare(nom text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT replace(regexp_replace(nom, '(^|[- ])' || chr(65533) || chr(65533),
                                  '\1É', 'g'),
                   chr(65533) || chr(65533), 'é')
$f$;

-- ---------------------------------------------------------------------------
-- 0. Les règles
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t107_exclu;
CREATE TEMP TABLE t107_exclu (dep text PRIMARY KEY, raison text);
INSERT INTO t107_exclu VALUES
    ('75', 'la Seine : à faire à part (Paris avant 1860, annexion)'),
    ('89', 'l''Yonne : cantons posés par 105'),
    ('57', 'la Moselle : pas de trame de 1870');

DROP TABLE IF EXISTS t107_suit;
CREATE TEMP TABLE t107_suit (
    dep text, canton text, jusqu int, meres text[], doute boolean, note text);
INSERT INTO t107_suit VALUES
    ('22', 'Étables', 1831, NULL, true,
     'n''apparaît qu''à la carte 1831-1848 ; mère non dite : canton voisin le plus proche'),
    ('26', 'Saint-Paul-Trois-Châteaux', 1852, ARRAY['Pierrelatte'], false,
     'dessiné à partir de 1852 ; avant, compris dans Pierrelatte'),
    ('30', 'Bessèges', 1863, ARRAY['Saint-Ambroix'], false,
     'n''apparaît qu''en 1863 ; suit Saint-Ambroix'),
    ('69', 'Amplepuis', 1870, ARRAY['Thizy'], false,
     'non dessiné ; issu de Thizy'),
    ('70', 'Marnay', 1870, ARRAY['Gy', 'Pesmes'], true,
     'non dessiné ; suit Gy et Pesmes : chaque atome au plus proche'),
    ('71', 'Le Creusot', 1870, ARRAY['Montcenis'], false,
     'canton de 1874 ; issu de Montcenis'),
    ('83', 'Le Luc', 1831, ARRAY['Besse'], false,
     'dessiné à partir de 1831 ; avant, suit Besse'),
    ('83', 'Solliès-Pont', 1831, ARRAY['Cuers'], false,
     'dessiné à partir de 1831 ; avant, suit Cuers'),
    ('83', 'La Seyne-sur-Mer', 1870, ARRAY['Ollioules'], false,
     'canton postérieur ; suit Ollioules');

DROP TABLE IF EXISTS t107_avant;
CREATE TEMP TABLE t107_avant (
    dep text, unit_id text, nom text, jusqu int, cantons text[], note text);
INSERT INTO t107_avant VALUES
    ('03', 'C03-Montluçon', 'Montluçon', 1863,
     ARRAY['Montluçon-Est', 'Montluçon-Ouest', 'Commentry'],
     '« Montluçon » avant 1863 ; Commentry dessiné à partir de 1863'),
    ('30', 'C30-Alès', 'Alès', 1863,
     ARRAY['Alès-Est', 'Alès-Ouest'],
     'un seul canton d''Alès jusqu''à la carte de 1863'),
    ('42', 'C42-Saint-Étienne-Est', 'Saint-Étienne-Est', 1863,
     ARRAY['Saint-Étienne-Nord-Est', 'Saint-Étienne-Sud-Est'],
     'deux cantons jusqu''à la carte de 1857 ; SEE = NE + SE, approximation'),
    ('42', 'C42-Saint-Étienne-Ouest', 'Saint-Étienne-Ouest', 1863,
     ARRAY['Saint-Étienne-Nord-Ouest', 'Saint-Étienne-Sud-Ouest'],
     'deux cantons jusqu''à la carte de 1857 ; SEO = NO + SO, approximation'),
    ('68', 'C68-Mulhouse', 'Mulhouse', 1863,
     ARRAY['Mulhouse-Nord', 'Mulhouse-Sud'],
     '« Mulhouse » avant 1863');

-- Les noms de l'atlas, quand le chef-lieu a changé (même territoire).
-- « (1815) » dans `regles_*` = la seule carte de 1815, d'où 1820.
DROP TABLE IF EXISTS t107_nom;
CREATE TEMP TABLE t107_nom (dep text, canton text, ancien text, jusqu int);
INSERT INTO t107_nom VALUES
    ('18', 'Saint-Martin-d''Auxigny',  'Menetou-Salon',              1820),
    ('24', 'Sigoulès',                 'Cunèges',                    1820),
    ('24', 'Saint-Astier',             'Grignols',                   1831),
    ('27', 'Amfreville-la-Campagne',   'Tourville',                  1831),
    ('27', 'Fleury-sur-Andelle',       'Grainville',                 1848),
    ('29', 'Plouigneau',               'Le Ponthou',                 1831),
    ('30', 'La Grand-Combe',           'Saint-Martin-de-Valgalgues', 1863),
    ('39', 'Beaufort',                 'Cousance',                   1820),
    ('39', 'Saint-Laurent',            'Les Petites-Chiettes',       1869),
    ('42', 'Saint-Galmier',            'Chazelles-sur-Lyon',         1820),
    ('46', 'Latronquière',             'Gorses',                     1820),
    ('52', 'Châteauvillain',           'Ville-sur-Aujon',            1820),
    ('56', 'La Gacilly',               'Carentoir',                  1852),
    ('59', 'Cysoing',                  'Templeuve',                  1820),
    ('61', 'Messei',                   'Saint-Gervais-de-Messei',    1820),
    ('62', 'Calais-Nord-Ouest',        'Calais',                     1852),
    ('69', 'Lamure-sur-Azergues',      'Saint-Nizier-d''Azergues',   1852),
    ('83', 'Rians',                    'Ginasservis',                1831);

-- Les communes qui ont changé de canton, à la date de l'acte (en-tête).
DROP TABLE IF EXISTS t107_ancien;
CREATE TEMP TABLE t107_ancien (
    dep text, insee text, cassini text, commune text, canton_avant text,
    canton_apres text, cree text, date_acte date, acte text, source text);
\copy t107_ancien FROM 'cantons/changements_communes_1815_1870.csv' WITH (FORMAT csv, HEADER true)
DELETE FROM t107_ancien WHERE dep IN (SELECT dep FROM t107_exclu);

-- ---------------------------------------------------------------------------
-- 1. Les atomes de 1870, leur canton, leur naissance, leur début
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t107_atome;
CREATE TEMP TABLE t107_atome AS
WITH a70 AS (
    SELECT m.atom_id, a.cassini, a.fraction, u.dep::text AS dep,
           m.unit_id AS canton_id, pg_temp.repare(u.nom) AS canton
      FROM membership m
      JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
      JOIN atom a ON a.atom_id = m.atom_id
     WHERE m.niveau = 'canton' AND m.periode @> :'d70'::date
       AND u.dep::text NOT IN (SELECT dep FROM t107_exclu)
), ne_anr AS (
    SELECT atom_id, min(lower(periode)) AS ne_le
      FROM atom_geom_anr WHERE atom_id IN (SELECT atom_id FROM a70)
     GROUP BY atom_id
), ne_mere AS (
    SELECT an.id_com::text AS cassini,
           make_date(min((nullif(an.startdt::text, ''))::numeric::int), 1, 1) AS ne_le
      FROM anr_commune an
     WHERE an.id_com::text IN (SELECT cassini FROM a70)
     GROUP BY 1
), ne_n AS (
    SELECT t.atom_id,
           min(coalesce(na.ne_le,
                        (SELECT make_date(min((nullif(an.startdt::text, ''))
                                              ::numeric::int), 1, 1)
                           FROM anr_commune an
                          WHERE an.id_com::text = am.cassini))) AS ne_le
      FROM creation_trace t
     CROSS JOIN LATERAL unnest(string_to_array(t.meres, ';')) AS m(id)
      JOIN atom am ON am.atom_id = m.id
      LEFT JOIN ne_anr na ON na.atom_id = m.id
     WHERE t.atom_id IN (SELECT atom_id FROM a70)
     GROUP BY t.atom_id
), c15 AS (
    -- La Meurthe : 99 dans c15_composition, 54 dans `unit` (`39`).
    SELECT CASE WHEN dep = '99' THEN '54' ELSE dep END AS dep,
           canton, make_date(depuis::int, 1, 1) AS du
      FROM c15_composition
), debut_canton AS (
    SELECT dep, canton, min(du) AS du FROM c15 GROUP BY 1, 2
), debut_dep AS (
    SELECT dep, min(du) AS du FROM c15 GROUP BY 1
)
SELECT a70.*,
       CASE WHEN a70.atom_id LIKE 'N%' THEN nn.ne_le
            WHEN a70.fraction          THEN nm.ne_le
            ELSE coalesce(na.ne_le, nm.ne_le) END AS ne_le,
       coalesce(dc.du, dd.du, DATE '1815-01-01')  AS debut,
       CASE WHEN dc.du IS NOT NULL THEN 'canton dans c15'
            WHEN dd.du IS NOT NULL THEN 'département dans c15'
            ELSE '1815 par défaut' END            AS debut_lu
  FROM a70
  LEFT JOIN ne_anr  na ON na.atom_id = a70.atom_id
  LEFT JOIN ne_mere nm ON nm.cassini = a70.cassini
  LEFT JOIN ne_n    nn ON nn.atom_id = a70.atom_id
  LEFT JOIN debut_canton dc ON dc.dep = a70.dep AND dc.canton = a70.canton
  LEFT JOIN debut_dep    dd ON dd.dep = a70.dep;
CREATE INDEX ON t107_atome (atom_id);
CREATE INDEX ON t107_atome (dep, canton);
ANALYZE t107_atome;

\echo ''
\echo '=== 1. Les atomes de 1870, par département ==='
SELECT dep, count(*) AS atomes, count(DISTINCT canton_id) AS cantons,
       count(*) FILTER (WHERE ne_le IS NULL)                       AS sans_naissance,
       count(*) FILTER (WHERE ne_le >= :'d70'::date)              AS nes_en_1870_ou_apres,
       min(debut) AS debut_min, max(debut) AS debut_max,
       string_agg(DISTINCT debut_lu, ', ')                         AS debut_lu
  FROM t107_atome GROUP BY dep ORDER BY dep;
-- debut_max > debut_min : des cantons commencent plus tard (Savoie, Nice,
-- Grasse 1863, Montbéliard 1820). « 1815 par défaut » : l'Aveyron, et tout
-- département que c15 ne connaît pas — à regarder.

\echo ''
\echo '=== 1 bis. Cantons de 1870 que c15 ne nomme pas, dans un département qu''il connaît ==='
SELECT dep, canton, count(*) AS atomes, min(debut) AS debut
  FROM t107_atome WHERE debut_lu = 'département dans c15'
 GROUP BY 1, 2 ORDER BY 1, 2;
-- Attendu : aucune ligne, ou des cas expliqués (fractions sans circo).

-- ---------------------------------------------------------------------------
-- 2. Les règles retrouvent-elles leurs cantons ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t107_nom_absent;
CREATE TEMP TABLE t107_nom_absent AS
SELECT 'suit' AS table_, s.dep, s.canton AS nom
  FROM t107_suit s
 WHERE NOT EXISTS (SELECT 1 FROM t107_atome a WHERE a.dep = s.dep AND a.canton = s.canton)
UNION ALL
SELECT 'suit (mère)', s.dep, m
  FROM t107_suit s CROSS JOIN LATERAL unnest(s.meres) m
 WHERE NOT EXISTS (SELECT 1 FROM t107_atome a WHERE a.dep = s.dep AND a.canton = m)
UNION ALL
SELECT 'avant', v.dep, c
  FROM t107_avant v CROSS JOIN LATERAL unnest(v.cantons) c
 WHERE NOT EXISTS (SELECT 1 FROM t107_atome a WHERE a.dep = v.dep AND a.canton = c)
UNION ALL
SELECT 'deux règles', s.dep, s.canton
  FROM t107_suit s JOIN t107_avant v ON v.dep = s.dep AND s.canton = ANY (v.cantons)
UNION ALL
SELECT 'mère sous règle', s.dep, m
  FROM t107_suit s CROSS JOIN LATERAL unnest(s.meres) m
 WHERE EXISTS (SELECT 1 FROM t107_suit s2 WHERE s2.dep = s.dep AND s2.canton = m)
    OR EXISTS (SELECT 1 FROM t107_avant v WHERE v.dep = s.dep AND m = ANY (v.cantons))
UNION ALL
-- le CSV des communes : commune absente, ou pas dans son canton de 1870
SELECT 'ancien (commune)', x.dep, x.commune || ' (' || x.cassini || ' -> '
       || x.canton_apres || ')'
  FROM t107_ancien x
 WHERE NOT EXISTS (SELECT 1 FROM t107_atome a
                    WHERE a.dep = x.dep AND a.cassini = x.cassini
                      AND a.canton = x.canton_apres)
UNION ALL
SELECT 'ancien (canton avant)', x.dep, x.canton_avant
  FROM t107_ancien x
 WHERE NOT EXISTS (SELECT 1 FROM t107_atome a
                    WHERE a.dep = x.dep AND a.canton = x.canton_avant)
UNION ALL
SELECT 'ancien et suit', x.dep, x.canton_apres
  FROM t107_ancien x
 WHERE EXISTS (SELECT 1 FROM t107_suit s
                WHERE s.dep = x.dep AND s.canton IN (x.canton_apres, x.canton_avant))
    OR EXISTS (SELECT 1 FROM t107_avant v
                WHERE v.dep = x.dep
                  AND (x.canton_apres = ANY (v.cantons)
                       OR x.canton_avant = ANY (v.cantons)));

\echo ''
\echo '=== 2. Garde-fou : noms des règles introuvables ou règles qui se croisent ==='
SELECT * FROM t107_nom_absent ORDER BY 2, 1, 3;
-- Attendu : aucune ligne. Le plus souvent une graphie : comparer à `unit.nom`.

-- ---------------------------------------------------------------------------
-- 3. Les règles, atome par atome
-- ---------------------------------------------------------------------------
-- La géométrie de 1870 des atomes des départements où l'on doit choisir.
DROP TABLE IF EXISTS t107_geom;
CREATE TEMP TABLE t107_geom AS
SELECT a.atom_id, a.dep, a.canton,
       coalesce((SELECT g.geom FROM atom_geom_anr g
                  WHERE g.atom_id = a.atom_id AND g.periode @> :'d70'::date
                  LIMIT 1),
                (SELECT ag.geom FROM atom_geom ag WHERE ag.atom_id = a.atom_id)) AS geom
  FROM t107_atome a
 WHERE a.dep IN (SELECT dep FROM t107_suit
                  WHERE meres IS NULL OR cardinality(meres) > 1);
CREATE INDEX ON t107_geom USING gist (geom);

DROP TABLE IF EXISTS t107_regle_atome;
CREATE TEMP TABLE t107_regle_atome (
    atom_id text PRIMARY KEY, cible text NOT NULL, jusqu date NOT NULL,
    regle text NOT NULL, detail text);

-- « suit », une seule mère.
INSERT INTO t107_regle_atome
SELECT a.atom_id, m.canton_id, make_date(s.jusqu, 1, 1),
       'suit', s.canton || ' -> ' || s.meres[1]
  FROM t107_atome a
  JOIN t107_suit s ON s.dep = a.dep AND s.canton = a.canton
  JOIN LATERAL (SELECT DISTINCT b.canton_id FROM t107_atome b
                 WHERE b.dep = s.dep AND b.canton = s.meres[1]) m ON true
 WHERE cardinality(s.meres) = 1;

-- « suit », plusieurs mères ou aucune : le candidat le plus proche.
INSERT INTO t107_regle_atome
SELECT DISTINCT ON (e.atom_id)
       e.atom_id, c.canton_id, make_date(s.jusqu, 1, 1), 'suit (au plus proche)',
       s.canton || ' -> ' || c.canton || ' (' || round(c.d) || ' m, frontière '
       || round(c.f) || ' m)'
  FROM t107_geom e
  JOIN t107_suit s ON s.dep = e.dep AND s.canton = e.canton
                  AND (s.meres IS NULL OR cardinality(s.meres) > 1)
  JOIN LATERAL (
        SELECT b.canton_id, b.canton,
               min(ST_Distance(e.geom, gb.geom)) AS d,
               sum(CASE WHEN ST_Intersects(e.geom, gb.geom)
                        THEN ST_Length(ST_Intersection(ST_Boundary(e.geom),
                                                       ST_Boundary(gb.geom)))
                        ELSE 0 END) AS f
          FROM t107_geom gb
          JOIN t107_atome b ON b.atom_id = gb.atom_id
         WHERE gb.dep = e.dep AND gb.canton <> e.canton
           AND (s.meres IS NULL OR gb.canton = ANY (s.meres))
           AND NOT EXISTS (SELECT 1 FROM t107_suit s2
                            WHERE s2.dep = gb.dep AND s2.canton = gb.canton)
           AND ST_DWithin(e.geom, gb.geom, 30000)
         GROUP BY 1, 2) c ON true
 WHERE e.geom IS NOT NULL
 ORDER BY e.atom_id, c.d, c.f DESC;

-- « avant ».
INSERT INTO t107_regle_atome
SELECT a.atom_id, v.unit_id, make_date(v.jusqu, 1, 1), 'avant', v.nom
  FROM t107_atome a
  JOIN t107_avant v ON v.dep = a.dep AND a.canton = ANY (v.cantons);

-- « ancien canton » : le CSV, commune par commune, à la date de l'acte.
-- Tous les atomes de la commune (fractions comprises) suivent sa ligne.
INSERT INTO t107_regle_atome
SELECT a.atom_id, m.canton_id, x.date_acte, 'ancien canton',
       x.commune || ' : ' || x.canton_avant || ' -> ' || x.canton_apres
       || ' (' || x.acte || ')'
  FROM t107_atome a
  JOIN t107_ancien x ON x.dep = a.dep AND x.cassini = a.cassini
                    AND x.canton_apres = a.canton
  JOIN LATERAL (SELECT DISTINCT b.canton_id FROM t107_atome b
                 WHERE b.dep = x.dep AND b.canton = x.canton_avant) m ON true
 WHERE NOT EXISTS (SELECT 1 FROM t107_regle_atome r WHERE r.atom_id = a.atom_id);

\echo ''
\echo '=== 3. Les règles, appliquées ==='
SELECT a.dep, a.canton, r.regle, r.jusqu,
       string_agg(DISTINCT r.detail, ' ; ') AS vers, count(*) AS atomes
  FROM t107_regle_atome r JOIN t107_atome a USING (atom_id)
 GROUP BY 1, 2, 3, 4 ORDER BY 1, 2;

\echo ''
\echo '=== 3 bis. Atomes d''un canton « suit » restés sans mère (pas de géométrie) ==='
SELECT a.dep, a.canton, a.atom_id
  FROM t107_atome a JOIN t107_suit s ON s.dep = a.dep AND s.canton = a.canton
 WHERE NOT EXISTS (SELECT 1 FROM t107_regle_atome r WHERE r.atom_id = a.atom_id);
-- Attendu : aucune ligne. Sinon l'atome resterait dans son canton de 1870
-- dès 1815 — le refus est dans la pose.

\echo ''
\echo '=== 3 ter. Le CSV des communes : chaque ligne et sa règle ==='
SELECT x.dep, x.commune, x.canton_avant, x.canton_apres, x.date_acte,
       count(r.atom_id) AS atomes, string_agg(DISTINCT r.regle, ', ') AS regle
  FROM t107_ancien x
  LEFT JOIN t107_atome a ON a.dep = x.dep AND a.cassini = x.cassini
                        AND a.canton = x.canton_apres
  LEFT JOIN t107_regle_atome r ON r.atom_id = a.atom_id
 GROUP BY 1, 2, 3, 4, 5 ORDER BY 1, 4, 3, 2;
-- Attendu : atomes >= 1 et regle = « ancien canton » sur chaque ligne.
-- Villars (01) : 9 communes, aucun atome de Villars hors du CSV (ci-dessous).
DROP TABLE IF EXISTS t107_ancien_orphelin;
CREATE TEMP TABLE t107_ancien_orphelin AS
SELECT a.dep, a.canton, a.atom_id, a.cassini
  FROM t107_atome a
 WHERE EXISTS (SELECT 1 FROM t107_ancien x
                WHERE x.dep = a.dep AND x.canton_apres = a.canton
                  AND x.cree = 'oui')
   AND NOT EXISTS (SELECT 1 FROM t107_regle_atome r WHERE r.atom_id = a.atom_id);
SELECT * FROM t107_ancien_orphelin ORDER BY 1, 2, 3;
-- Attendu : aucune ligne. Un atome d'un canton CRÉÉ (cree = oui) sans ligne
-- dans le CSV serait posé dans ce canton dès 1815.

-- ---------------------------------------------------------------------------
-- 4. Les périodes, et ce qui existe déjà
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t107_pose;
CREATE TEMP TABLE t107_pose (
    id serial PRIMARY KEY, dep text, atom_id text, unit_id text,
    valid_from date, valid_to date, quoi text, rogne boolean DEFAULT false);

INSERT INTO t107_pose (dep, atom_id, unit_id, valid_from, valid_to, quoi)
SELECT a.dep, a.atom_id, r.cible, greatest(a.debut, a.ne_le),
       least(r.jusqu, :'d70'::date), r.regle
  FROM t107_atome a JOIN t107_regle_atome r USING (atom_id)
 WHERE a.ne_le IS NOT NULL
UNION ALL
SELECT a.dep, a.atom_id, a.canton_id,
       greatest(a.debut, a.ne_le, coalesce(r.jusqu, a.debut)),
       :'d70'::date, 'canton de 1870'
  FROM t107_atome a LEFT JOIN t107_regle_atome r USING (atom_id)
 WHERE a.ne_le IS NOT NULL;
DELETE FROM t107_pose WHERE valid_from >= valid_to;

-- Rogner sur les rattachements cantonaux qui existent déjà (hors trace).
WITH x AS (
    SELECT p.id, min(lower(m.periode)) AS premier
      FROM t107_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
     WHERE NOT EXISTS (SELECT 1 FROM canton_1815_trace t
                        WHERE t.quoi = 'membership'
                          AND t.cle = m.membership_id::text)
     GROUP BY p.id
)
UPDATE t107_pose p SET valid_to = least(p.valid_to, x.premier), rogne = true
  FROM x WHERE x.id = p.id;

\echo ''
\echo '=== 4. Rogné sur l''existant, par département ==='
SELECT dep, count(*) FILTER (WHERE valid_from <  valid_to) AS raccourcis,
            count(*) FILTER (WHERE valid_from >= valid_to) AS supprimes
  FROM t107_pose WHERE rogne GROUP BY dep ORDER BY dep;
-- Attendu : peu de lignes. Un département entier en « supprimés » a déjà ses
-- cantons d'avant 1870 par un autre fichier : l'ajouter à t107_exclu.
DELETE FROM t107_pose WHERE valid_from >= valid_to;

\echo ''
\echo '=== 5. Ce qui sera posé ==='
SELECT quoi, count(DISTINCT dep) AS deps, count(DISTINCT unit_id) AS unites,
       count(*) AS rattachements, min(valid_from) AS du, max(valid_to) AS au
  FROM t107_pose GROUP BY quoi ORDER BY quoi;

-- Les versions de nom : du premier rattachement à 1870, coupées par t107_nom.
DROP TABLE IF EXISTS t107_version;
CREATE TEMP TABLE t107_version AS
WITH vie AS (
    SELECT unit_id, min(valid_from) AS du, max(valid_to) AS au
      FROM t107_pose GROUP BY unit_id
), nom70 AS (
    SELECT v.unit_id, coalesce(uv.nom, u.nom) AS nom, u.dep::text AS dep,
           pg_temp.repare(u.nom) AS canton
      FROM vie v JOIN unit u ON u.unit_id = v.unit_id
      LEFT JOIN unit_version uv ON uv.unit_id = v.unit_id
                               AND uv.periode @> :'d70'::date
     -- au rejeu, les unités nouvelles existent déjà : elles ont leur branche
     WHERE v.unit_id NOT IN (SELECT unit_id FROM t107_avant)
)
-- les unités de 1870 : nom de l'atlas avant la date, nom de 1870 après
SELECT v.unit_id, n.ancien AS nom, v.du AS valid_from,
       least(make_date(n.jusqu, 1, 1), v.au) AS valid_to
  FROM vie v JOIN nom70 c ON c.unit_id = v.unit_id
  JOIN t107_nom n ON n.dep = c.dep AND n.canton = c.canton
UNION ALL
SELECT v.unit_id, c.nom,
       greatest(v.du, coalesce((SELECT make_date(n.jusqu, 1, 1) FROM t107_nom n
                                 WHERE n.dep = c.dep AND n.canton = c.canton),
                               v.du)),
       v.au
  FROM vie v JOIN nom70 c ON c.unit_id = v.unit_id
UNION ALL
-- les unités nouvelles
SELECT a.unit_id, a.nom, v.du, v.au
  FROM vie v JOIN t107_avant a ON a.unit_id = v.unit_id;
DELETE FROM t107_version WHERE valid_from >= valid_to;

-- Ne pas poser une version qui chevauche une version existante (hors trace).
ALTER TABLE t107_version ADD COLUMN chevauche boolean;
UPDATE t107_version t SET chevauche = EXISTS (
    SELECT 1 FROM unit_version uv
     WHERE uv.unit_id = t.unit_id
       AND uv.periode && daterange(t.valid_from, t.valid_to, '[)')
       AND NOT EXISTS (SELECT 1 FROM canton_1815_trace x
                        WHERE x.quoi = 'unit_version'
                          AND x.cle = uv.unit_version_id::text));

\echo ''
\echo '=== 6. Les noms d''avant 1870 ==='
SELECT count(*) FILTER (WHERE NOT chevauche) AS versions_posees,
       count(*) FILTER (WHERE chevauche)     AS versions_ecartees
  FROM t107_version;
SELECT t.unit_id, t.nom, t.valid_from, t.valid_to, t.chevauche
  FROM t107_version t
 WHERE t.chevauche OR t.unit_id LIKE 'C%'
    OR EXISTS (SELECT 1 FROM t107_nom n WHERE n.ancien = t.nom)
 ORDER BY 1, 3;
-- « chevauche » : l'unité a déjà un nom daté sur cette période ; il est
-- gardé, et la carte s'en servira.

\if :{?appliquer}

-- Retirer la trace avant de juger — la leçon de `55`.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM canton_1815_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE canton_1815_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t107_nom_absent;
    IF n > 0 THEN
        RAISE EXCEPTION '% nom(s) de règle introuvable(s) ou règles croisées. '
            'Voir la recette 2.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t107_atome a JOIN t107_suit s ON s.dep = a.dep AND s.canton = a.canton
     WHERE NOT EXISTS (SELECT 1 FROM t107_regle_atome r WHERE r.atom_id = a.atom_id);
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) d''un canton « suit » sans mère. Recette 3 bis.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t107_ancien x
     WHERE NOT EXISTS (SELECT 1 FROM t107_atome a
                         JOIN t107_regle_atome r USING (atom_id)
                        WHERE a.dep = x.dep AND a.cassini = x.cassini
                          AND r.regle = 'ancien canton');
    IF n > 0 THEN
        RAISE EXCEPTION '% ligne(s) du CSV des communes sans règle posée. '
            'Recettes 2 et 3 ter.', n;
    END IF;

    SELECT count(*) INTO n FROM t107_ancien_orphelin;
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) d''un canton créé par le CSV sans ligne '
            'dans le CSV. Recette 3 ter.', n;
    END IF;

    SELECT count(*) INTO n FROM t107_atome WHERE ne_le IS NULL;
    IF n > 0.02 * (SELECT count(*) FROM t107_atome) THEN
        RAISE EXCEPTION '% atome(s) sans naissance, plus de 2 %%. Recette 1.', n;
    ELSIF n > 0 THEN
        RAISE NOTICE '% atome(s) sans naissance connue : non posés (recette 1).', n;
    END IF;

    SELECT count(*) INTO n
      FROM (SELECT DISTINCT unit_id FROM t107_avant) d
      JOIN unit u ON u.unit_id = d.unit_id;
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) nouvelle(s) existent déjà hors trace.', n;
    END IF;

    SELECT count(*) INTO n
      FROM t107_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION '% chevauchement(s) après rognage — ne devrait pas arriver.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT DISTINCT a.unit_id, 'canton', a.dep, a.unit_id,
           NULL::text, NULL::smallint, a.nom, true
      FROM t107_avant a
     WHERE EXISTS (SELECT 1 FROM t107_pose p WHERE p.unit_id = a.unit_id)
    RETURNING unit_id
)
INSERT INTO canton_1815_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, valid_from, valid_to FROM t107_version
     WHERE NOT chevauche
    RETURNING unit_version_id
)
INSERT INTO canton_1815_trace (quoi, cle)
SELECT 'unit_version', unit_version_id::text FROM ins;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM t107_pose
    RETURNING membership_id
)
INSERT INTO canton_1815_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 7. Pose ==='
SELECT quoi, count(*) FROM canton_1815_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 8. Cantons et circos, date par date : départements où ils ne couvrent pas les mêmes atomes ==='
WITH d(d) AS (VALUES ('1817-06-01'::date), ('1825-06-01'), ('1840-06-01'),
                     ('1850-06-01'), ('1855-06-01'), ('1860-06-01'),
                     ('1866-06-01'), ('1869-06-01')),
c AS (
    SELECT d.d, u.dep::text AS dep, m.niveau, count(DISTINCT m.atom_id) AS n
      FROM d JOIN membership m ON m.periode @> d.d
      JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
     GROUP BY 1, 2, 3
)
SELECT d, dep,
       coalesce(max(n) FILTER (WHERE niveau = 'canton'), 0) AS atomes_canton,
       coalesce(max(n) FILTER (WHERE niveau = 'circo'), 0)  AS atomes_circo
  FROM c GROUP BY 1, 2
HAVING coalesce(max(n) FILTER (WHERE niveau = 'canton'), 0)
    <> coalesce(max(n) FILTER (WHERE niveau = 'circo'), 0)
 ORDER BY 2, 1;
-- Attendu : l'Aveyron (cantons sans circos), la Seine (circos sans cantons),
-- les départements rognés en recette 4, Grasse avant 1863 (ni l'un ni
-- l'autre) — et rien d'autre. Un écart ailleurs = un atome que 106 a posé et
-- pas 107, ou l'inverse : le chercher.

\echo ''
\echo '=== 9. Aucun atome dans deux cantons à la même date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'canton'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0 (la contrainte EXCLUDE l'interdit déjà).

\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

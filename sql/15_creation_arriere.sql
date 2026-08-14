-- ============================================================================
-- histgis — 15_creation_arriere.sql : les communes nées après la série
--
-- Le problème, ce qu'il reste du § 6.2
-- ------------------------------------
-- `11_scission.sql` a comblé les trous de couverture dus aux communes nées
-- ENTRE 1870 et 1940 : TRF-GIS les suit, leur atome existe, il suffisait de
-- prolonger son rattachement vers l'arrière. Restent 811 km² en 1870 et 610 en
-- 1940 — des communes de la trame 2011 nées APRÈS la série. TRF-GIS ne les a
-- jamais vues, elles n'ont aucun atome, et rien à prolonger.
--
-- Ce qu'on sait d'elles
-- ---------------------
-- Le fichier des mouvements de communes de l'INSEE remonte à 1943 et documente
-- leur création : modalités 20 (création) et 21 (rétablissement), où `com_av`
-- nomme la commune dont le territoire a été détaché — la mère. C'est ce que
-- `10_couverture.sql` § 2 exploite déjà pour les compter.
--
-- Le pari, et il est le même qu'en 11
-- -----------------------------------
-- *Le territoire d'une commune née après 1940 appartenait au canton de sa mère.*
-- Ce n'est pas une extrapolation sur l'inconnu : la mère existe dans la base,
-- son rattachement est documenté année par année, et on ne fait que l'étendre
-- à un territoire qui était le sien. Le Grau-du-Roi de 1879 relevait du canton
-- d'Aigues-Mortes ; une commune détachée d'Arles en 1950 relevait, en 1870, du
-- canton d'Arles.
--
-- Le choix de conception
-- ----------------------
-- Deux voies étaient possibles. Élargir la géométrie de l'atome mère en y
-- unionnant le polygone de la fille — simple, mais cela mêle géométrie et
-- attribution, et défait le découplage qui fait tenir tout le reste. Ou créer
-- un ATOME-FRACTION portant le polygone de la fille, et lui recopier
-- l'appartenance de la mère. C'est la seconde, retenue ici : la géométrie reste
-- à sa place, l'ajout est isolable, et il se retire d'un DELETE.
--
-- L'atome créé n'est pas une commune historique et ne prétend pas l'être :
-- `cassini` reçoit une valeur synthétique préfixée 'N', `fraction = true`, et
-- `atom_geom.source = 'creation_arriere'`. Rien ne doit pouvoir le confondre
-- avec un atome issu de TRF-GIS.
--
-- Les garde-fous
-- --------------
--   1. La mère est identifiée d'abord par la GÉOMÉTRIE — `ST_Equals` sur le
--      polygone de `com_av` —, avec repli sur `insee_geofla`. C'est la leçon
--      de `14`, mais amendée : l'empreinte binaire `md5(ST_AsEWKB(geom))`
--      constate qu'un polygone est PARTAGÉ, elle ne teste pas que deux
--      polygones sont LE MÊME. `ST_UnaryUnion`, qui construit `atom_geom`,
--      peut renormaliser une représentation sans changer la géométrie.
--   2. Si plusieurs atomes portent ce polygone et qu'ils NE SONT PAS dans le
--      même canton une année donnée, cette année n'est pas comblée. On ne
--      choisit pas au hasard entre deux mères : on déclare inconnu.
--   3. Rien n'est posé pour une année postérieure à la création. Le territoire
--      cesse d'appartenir à la mère le jour où la fille naît.
--   4. Les années où la mère n'a elle-même aucun rattachement restent vides.
--      Le trou d'Alsace-Moselle 1871-1919 est ainsi préservé sans traitement
--      particulier — et c'est pour cela qu'aucun équivalent du garde-fou 4 de
--      `11` n'est nécessaire ici : on ne franchit aucune interruption, on
--      recopie une chronologie existante.
--   5. Une fille dont le territoire est DÉJÀ COUVERT est écartée — test par
--      point intérieur contenu dans un polygone d'atome, celui de
--      `10_couverture.sql`. L'égalité de polygone ne suffit pas : un
--      arrondissement de Marseille n'égale pas l'union qui le porte, et serait
--      compté deux fois.
--
-- Les deux niveaux sont traités : canton et circonscription. Combler l'un sans
-- l'autre laisserait la couverture des circonscriptions en l'état.
--
-- Réversible : `creation_trace` liste les atomes posés, et la suppression
-- cascade sur `atom_geom` et `membership`.
--
-- Prérequis : base chargée (load.sh, 05 → 06 → 07 → 11), `insee_mvt` peuplée
-- par `06`, et `ctrl_non_couvert` par `controle_gay.sh` (pour la recette
-- seulement — le script sait s'en passer).
-- Rejouable : il retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE EXCEPTION 'insee_mvt absente : lancer 06_insee_mvt.sql avant.';
    END IF;
    IF to_regclass('histgis.geofla_commune') IS NULL THEN
        RAISE EXCEPTION 'geofla_commune absente : charger GEOFLA avant.';
    END IF;
END $$;

-- 'creation_arriere' rejoint les sources reconnues, comme 07 l'a fait pour hac
ALTER TABLE atom_geom DROP CONSTRAINT IF EXISTS atom_geom_source_check;
ALTER TABLE atom_geom ADD CONSTRAINT atom_geom_source_check CHECK (
    source IN ('geofla', 'union_prefixe', 'absorbee', 'successeur',
               'hac', 'hac_partage', 'creation_arriere')
);

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
--
-- La suppression des atomes cascade sur atom_geom et membership : ces atomes
-- n'appartiennent qu'à ce script, rien d'autre ne les référence.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS creation_trace (
    atom_id     text PRIMARY KEY,
    insee_fille char(5) NOT NULL,
    nom_fille   text,
    insee_mere  char(5) NOT NULL,
    meres       text NOT NULL,      -- atom_id des mères, séparés par ';'
    n_meres     smallint NOT NULL,
    date_eff    date NOT NULL,
    modalite    text NOT NULL,
    km2         numeric,
    pose_le     timestamptz NOT NULL DEFAULT now()
);

DELETE FROM atom a USING creation_trace t WHERE a.atom_id = t.atom_id;
TRUNCATE creation_trace;

-- ---------------------------------------------------------------------------
-- 1. Les filles : communes de la trame que nul atome ne porte
--
-- Le test est géométrique et non par code : une commune est « sans atome » si
-- aucun atom_geom ne porte exactement son polygone. Cela inclut d'emblée les
-- cas où le code a changé sans que la géométrie bouge.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS creation_fille;
CREATE TABLE creation_fille AS
WITH sans_atome AS (
    SELECT g.insee_com, g.nom_comm, g.code_dept AS dep, g.geom,
           round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
    FROM   geofla_commune g
    -- Test de COUVERTURE, pas d'identité : un point intérieur de la commune
    -- tombe-t-il dans un polygone d'atome ? C'est celui de 10_couverture.sql,
    -- et c'est le seul correct.
    --
    -- La première version comparait des empreintes de polygones entiers. Elle
    -- déclarait « sans atome » les 16 arrondissements de Marseille et 2 de
    -- Lyon, dont le territoire est pourtant porté par un atome
    -- `union_prefixe` — dont le polygone est leur UNION, qu'aucun composant
    -- n'égale. Ils n'ont pas été comblés parce que leur mère 13055 n'existe
    -- pas dans GEOFLA : par chance, pas par conception. Avec une mère
    -- trouvable, Marseille aurait été compté deux fois.
    WHERE  NOT EXISTS (
               SELECT 1 FROM atom_geom ag
               WHERE  ag.geom && g.geom
                 AND  ST_Contains(ag.geom, ST_PointOnSurface(g.geom))
           )
)
SELECT s.insee_com AS insee_fille, s.nom_comm AS nom_fille, s.dep, s.km2, s.geom,
       m.mod       AS modalite,
       m.date_eff,
       m.com_av    AS insee_mere,
       m.libelle_av AS nom_mere
FROM   sans_atome s
JOIN   LATERAL (
           SELECT i.mod, i.date_eff, i.com_av, i.libelle_av
           FROM   insee_mvt i
           WHERE  i.com_ap = s.insee_com
             AND  i.mod IN ('20', '21')
             AND  i.com_av IS DISTINCT FROM i.com_ap
             AND  i.com_av IS NOT NULL
           -- la création la plus ANCIENNE : c'est celle qui détache le
           -- territoire de la mère historique
           ORDER  BY i.date_eff
           LIMIT  1
       ) m ON true;

CREATE INDEX creation_fille_idx ON creation_fille (insee_fille);

\echo ''
\echo '============================================================'
\echo ' COMMUNES NÉES APRÈS LA SÉRIE — rattachement au canton de la mère'
\echo '============================================================'

\echo ''
\echo '=== 1. Les filles documentées par l''INSEE ==='
SELECT count(*)                                   AS filles,
       round(sum(km2), 0)                         AS km2,
       min(date_eff)                              AS plus_ancienne,
       max(date_eff)                              AS plus_recente,
       count(*) FILTER (WHERE modalite = '20')    AS creations,
       count(*) FILTER (WHERE modalite = '21')    AS retablissements
FROM   creation_fille;

\echo ''
\echo '--- les 20 plus grandes ---'
SELECT insee_fille, nom_fille, dep, km2, modalite, date_eff, nom_mere
FROM   creation_fille ORDER BY km2 DESC LIMIT 20;

\echo ''
\echo '--- créées AVANT la fin de la série (à examiner, pas à combler) ---'
\echo '    Une commune née pendant la série devrait avoir un atome TRF-GIS.'
\echo '    Si elle n''en a pas, c''est un autre défaut que celui-ci.'
SELECT insee_fille, nom_fille, dep, km2, date_eff
FROM   creation_fille
WHERE  date_eff < (SELECT max(valid_to) FROM membership)
ORDER  BY km2 DESC;

-- ---------------------------------------------------------------------------
-- 2. Les mères, identifiées par la géométrie
--
-- Garde-fou 1 : on ne suit pas le code `com_av` jusqu'à un atome, on cherche
-- les atomes dont le POLYGONE est celui de `com_av`. Un atome `successeur`
-- porte le polygone de la commune qui l'a absorbé : si c'est celle-là qui a
-- essaimé, il est bien candidat, et le code ne l'aurait pas dit.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS creation_mere;
CREATE TABLE creation_mere AS
WITH mere_geom AS (
    SELECT f.insee_fille, ST_Multi(g.geom) AS geom
    FROM   creation_fille f
    JOIN   geofla_commune g ON g.insee_com = f.insee_mere
),
cand AS (
    -- voie 1 : égalité GÉOMÉTRIQUE. `ST_Equals` et non l'égalité d'empreinte
    -- binaire : `atom_geom.geom` est construit par ST_UnaryUnion, qui peut
    -- renormaliser une représentation sans changer la géométrie. La première
    -- version, qui comparait des md5, perdait ainsi Val-de-Reuil et
    -- Marcheprime — dont les mères Incarville et Biganos sont pourtant des
    -- communes ordinaires. Le `&&` amène l'index gist.
    SELECT m.insee_fille, ag.atom_id, 'geometrie'::text AS voie
    FROM   mere_geom m
    JOIN   atom_geom ag ON ag.geom && m.geom AND ST_Equals(ag.geom, m.geom)
    UNION ALL
    -- voie 2 : repli par le code. Un atome dont `insee_geofla` est le code de
    -- la mère est candidat même si sa géométrie diffère — cas d'une mère
    -- disparue avant 2011, dont l'atome porte le polygone de l'absorbante.
    -- Sans effet sur la géométrie posée : on ne recopie que l'appartenance.
    SELECT f.insee_fille, a.atom_id, 'code'
    FROM   creation_fille f
    JOIN   atom a ON a.insee_geofla = f.insee_mere
)
SELECT c.insee_fille,
       c.atom_id AS mere_atom_id,
       a.cassini,
       string_agg(DISTINCT c.voie, '+' ORDER BY c.voie) AS voie
FROM   cand c
JOIN   atom a       ON a.atom_id = c.atom_id
JOIN   atom_geom ag ON ag.atom_id = c.atom_id   -- une mère sans polygone ne dit rien
GROUP  BY c.insee_fille, c.atom_id, a.cassini;

CREATE INDEX creation_mere_idx ON creation_mere (insee_fille);

\echo ''
\echo '=== 2. Mères retrouvées ==='
-- `count(*)` dans un LATERAL renvoie TOUJOURS une ligne : n vaut 0, jamais
-- NULL. Le premier jet testait `n IS NULL` et rangeait donc les filles sans
-- mère — Tende et La Brigue — dans la branche « plusieurs ». Sans conséquence
-- sur ce qui est posé, mais un rapport qui ment est un rapport à corriger.
SELECT CASE WHEN coalesce(n, 0) = 0 THEN '0 - aucune mere dans la base'
            WHEN n = 1              THEN '1 - mere unique'
            ELSE                         'n - plusieurs atomes sur le polygone mere'
       END                          AS situation,
       count(*)                     AS filles,
       round(sum(f.km2), 0)         AS km2
FROM   creation_fille f
LEFT   JOIN LATERAL (
           SELECT count(*) AS n FROM creation_mere m
           WHERE  m.insee_fille = f.insee_fille
       ) x ON true
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- par quelle voie la mère a-t-elle été retrouvée ? ---'
\echo '    `geometrie` = ST_Equals sur le polygone. `code` = repli sur'
\echo '    insee_geofla. La voie `code` seule signale une mère dont le polygone'
\echo '    diffère : mère disparue avant 2011, dont l''atome porte celui de'
\echo '    l''absorbante. Sans effet — on ne recopie que l''appartenance.'
SELECT voie, count(*) AS meres, count(DISTINCT insee_fille) AS filles
FROM   creation_mere GROUP BY voie ORDER BY 2 DESC;

\echo ''
\echo '--- filles sans mère identifiable (non comblées, déclarées inconnues) ---'
SELECT f.insee_fille, f.nom_fille, f.dep, f.km2, f.insee_mere, f.nom_mere
FROM   creation_fille f
WHERE  NOT EXISTS (SELECT 1 FROM creation_mere m WHERE m.insee_fille = f.insee_fille)
ORDER  BY f.km2 DESC;

-- ---------------------------------------------------------------------------
-- 3. Année par année : où la mère était-elle rattachée ?
--
-- Garde-fou 2 : une année n'est retenue que si TOUTES les mères candidates
-- s'accordent sur la même unité. Garde-fou 3 : l'année entière doit précéder
-- la création. Garde-fou 4 : une année où aucune mère n'a de rattachement ne
-- produit pas de ligne, donc reste un trou.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS creation_annee;
CREATE TABLE creation_annee AS
WITH bornes AS (
    SELECT min(valid_from) AS d0, max(valid_to) AS d1 FROM membership
),
annees AS (
    SELECT generate_series(extract(year FROM d0)::int,
                           extract(year FROM d1)::int - 1) AS y
    FROM   bornes
),
niveaux AS (SELECT unnest(ARRAY['canton', 'circo']) AS niveau),
accord AS (
    SELECT f.insee_fille, n.niveau, a.y,
           count(DISTINCT m.unit_id) AS n_unites,
           min(m.unit_id)            AS unit_id
    FROM   creation_fille f
    CROSS  JOIN annees a
    CROSS  JOIN niveaux n
    JOIN   creation_mere cm ON cm.insee_fille = f.insee_fille
    JOIN   membership m ON m.atom_id = cm.mere_atom_id
                       AND m.niveau  = n.niveau
                       AND m.periode @> make_date(a.y, 6, 1)
    -- l'année entière doit tenir avant la création ; le test porte sur la fin
    -- de l'année, comme en 11, pour ne pas déborder sur `date_eff`
    WHERE  make_date(a.y + 1, 1, 1) <= f.date_eff
    GROUP  BY f.insee_fille, n.niveau, a.y
)
SELECT insee_fille, niveau, y, unit_id
FROM   accord WHERE n_unites = 1;

\echo ''
\echo '=== 3. Années comblées, et années écartées faute d''accord ==='
WITH bornes AS (
    SELECT min(valid_from) AS d0, max(valid_to) AS d1 FROM membership
),
annees AS (
    SELECT generate_series(extract(year FROM d0)::int,
                           extract(year FROM d1)::int - 1) AS y
    FROM bornes
),
niveaux AS (SELECT unnest(ARRAY['canton', 'circo']) AS niveau),
tout AS (
    SELECT f.insee_fille, n.niveau, a.y, count(DISTINCT m.unit_id) AS n_unites
    FROM   creation_fille f
    CROSS  JOIN annees a CROSS JOIN niveaux n
    JOIN   creation_mere cm ON cm.insee_fille = f.insee_fille
    JOIN   membership m ON m.atom_id = cm.mere_atom_id
                       AND m.niveau  = n.niveau
                       AND m.periode @> make_date(a.y, 6, 1)
    WHERE  make_date(a.y + 1, 1, 1) <= f.date_eff
    GROUP  BY 1, 2, 3
)
SELECT niveau,
       count(*) FILTER (WHERE n_unites = 1) AS annees_retenues,
       count(*) FILTER (WHERE n_unites > 1) AS annees_ecartees_desaccord,
       count(DISTINCT insee_fille)          AS filles
FROM   tout GROUP BY niveau ORDER BY niveau;

-- ---------------------------------------------------------------------------
-- 4. Recollage en intervalles, puis pose
--
-- Même motif « gaps and islands » qu'en 11 : y - rang est constant sur une
-- suite d'années consécutives dans la même unité.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS creation_periode;
CREATE TABLE creation_periode AS
WITH iles AS (
    SELECT insee_fille, niveau, unit_id, y,
           y - row_number() OVER (PARTITION BY insee_fille, niveau, unit_id
                                  ORDER BY y) AS ilot
    FROM   creation_annee
)
SELECT insee_fille, niveau, unit_id,
       make_date(min(y), 1, 1)     AS valid_from,
       make_date(max(y) + 1, 1, 1) AS valid_to,
       count(*)                    AS n_annees
FROM   iles
GROUP  BY insee_fille, niveau, unit_id, ilot;

-- 4a. les atomes
INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
SELECT 'N' || f.insee_fille,       -- 'N' comme « née après la série »
       'N' || f.insee_fille,       -- cassini synthétique : ce n'est PAS une
                                   -- commune historique, et rien ne doit le
                                   -- laisser croire
       true,
       NULL,
       f.insee_fille
FROM   creation_fille f
WHERE  EXISTS (SELECT 1 FROM creation_periode p WHERE p.insee_fille = f.insee_fille);

-- 4b. les géométries
INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT 'N' || f.insee_fille, ST_Multi(f.geom), 'creation_arriere', false
FROM   creation_fille f
WHERE  EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = 'N' || f.insee_fille);

-- 4c. les rattachements
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT 'N' || p.insee_fille, p.unit_id, p.niveau, p.valid_from, p.valid_to
FROM   creation_periode p
WHERE  EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = 'N' || p.insee_fille);

-- 4d. la trace
INSERT INTO creation_trace (atom_id, insee_fille, nom_fille, insee_mere,
                            meres, n_meres, date_eff, modalite, km2)
SELECT 'N' || f.insee_fille, f.insee_fille, f.nom_fille, f.insee_mere,
       (SELECT string_agg(m.mere_atom_id, ';' ORDER BY m.mere_atom_id)
          FROM creation_mere m WHERE m.insee_fille = f.insee_fille),
       (SELECT count(*) FROM creation_mere m WHERE m.insee_fille = f.insee_fille),
       f.date_eff, f.modalite, f.km2
FROM   creation_fille f
WHERE  EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = 'N' || f.insee_fille);

ANALYZE atom;
ANALYZE atom_geom;
ANALYZE membership;

\echo ''
\echo '=== 4. Ce qui a été posé ==='
SELECT count(*) AS atomes_crees, round(sum(km2), 0) AS km2_rendus,
       count(*) FILTER (WHERE n_meres > 1) AS dont_meres_multiples
FROM   creation_trace;

\echo ''
\echo '--- intervalles posés, par niveau ---'
SELECT niveau, count(*) AS lignes, count(DISTINCT insee_fille) AS filles,
       sum(n_annees) AS annees, min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   creation_periode GROUP BY niveau ORDER BY niveau;

\echo ''
\echo '--- les 20 plus grandes surfaces rendues ---'
SELECT t.atom_id, t.nom_fille, t.insee_mere, t.n_meres, t.date_eff, t.km2
FROM   creation_trace t ORDER BY t.km2 DESC LIMIT 20;

\echo ''
\echo '--- filles écartées faute d''accord entre mères (déclarées inconnues) ---'
SELECT f.insee_fille, f.nom_fille, f.dep, f.km2,
       (SELECT count(*) FROM creation_mere m WHERE m.insee_fille = f.insee_fille) AS n_meres
FROM   creation_fille f
WHERE  NOT EXISTS (SELECT 1 FROM creation_trace t WHERE t.insee_fille = f.insee_fille)
ORDER  BY f.km2 DESC;

-- ---------------------------------------------------------------------------
-- 5. Recette
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Recette ==='
\echo '--- chevauchements de membership (doit valoir 0) ---'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '--- territoire déjà couvert par un autre atome (doit valoir 0) ---'
\echo '    LA recette du script. La première version comparait des empreintes'
\echo '    et ne pouvait donc PAS attraper le cas qu''elle visait : le polygone'
\echo '    d''un arrondissement de Marseille n''égale pas celui de l''union qui'
\echo '    le contient, mais son territoire est bien déjà compté. Le test qui'
\echo '    vaut est l''inclusion, pas l''égalité.'
SELECT count(*) AS territoires_deja_couverts
FROM   atom_geom n
JOIN   atom_geom o ON o.atom_id <> n.atom_id
                  AND o.geom && n.geom
                  AND ST_Contains(o.geom, ST_PointOnSurface(n.geom))
WHERE  n.source = 'creation_arriere';

\echo ''
\echo '--- polygones strictement identiques (doit valoir 0) ---'
SELECT count(*) AS empreintes_partagees
FROM   (SELECT md5(ST_AsEWKB(geom)) AS cle FROM atom_geom
        WHERE  source = 'creation_arriere') n
JOIN   (SELECT md5(ST_AsEWKB(geom)) AS cle FROM atom_geom
        WHERE  source <> 'creation_arriere') o ON o.cle = n.cle;

\echo ''
\echo '--- effectifs après correctif ---'
\echo '    n_unites et n_departements doivent être INCHANGÉS : aucune unité'
\echo '    n''est créée. n_atomes augmente, c''est tout l''objet du script.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1885-06-01'), ('1914-06-01'), ('1940-06-01')) AS t(d),
       LATERAL count_units(d::date) c
ORDER  BY 1, c.niveau;

\echo ''
\echo '--- géométries ---'
SELECT * FROM check_geom();

\echo ''
\echo 'Pour tout défaire (la suppression cascade sur atom_geom et membership) :'
\echo '  DELETE FROM histgis.atom a USING histgis.creation_trace t'
\echo '   WHERE a.atom_id = t.atom_id;'
\echo '  TRUNCATE histgis.creation_trace;'
\echo ''
\echo 'La mesure qui fait foi reste extérieure : cd sql && ./controle_gay.sh'
\echo 'Attendu : territoire non couvert en forte baisse (811 km² en 1870,'
\echo '610 en 1940), IoU stable ou en hausse, nombre de cantons inchangé.'

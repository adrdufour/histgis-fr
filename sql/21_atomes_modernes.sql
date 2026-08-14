-- ============================================================================
-- histgis — 21_atomes_modernes.sql : les atomes qui manquent à 1943-2012
--
-- Suite de `20`, qui a reconstitué la chronologie communale sans rien écrire.
-- Ce fichier écrit : il crée les atomes manquants et fixe la correspondance
-- code INSEE → atome, datée. Il ne pose AUCUN `membership` — il n'y a encore
-- ni canton ni circonscription moderne à quoi rattacher quoi que ce soit.
--
-- Trois populations, trois traitements
-- -----------------------------------
--
-- 1. LES ARRONDISSEMENTS DE MARSEILLE ET DE LYON. 25 codes que GEOFLA connaît
--    et que la base ignore : `05_geom.sql` les réunit en un seul atome par
--    ville, via `union_prefixe`. Le dispositif tient pour 1870-1940, où
--    l'arrondissement municipal n'est pas une circonscription pertinente. Il ne
--    tient plus après 1946 et 1963, où les arrondissements sont créés, codés,
--    et suivis par les découpages législatifs urbains.
--
--    Ce qu'on NE fait pas, et pourquoi. L'idée d'éclater rétroactivement, avec
--    « le canton d'époque recevant l'union », est infaisable : TRF-GIS ne dit
--    jamais quel arrondissement relève de quel canton en 1870, et faire
--    appartenir l'atome du 3e arrondissement aux dix cantons lyonnais viole
--    `membership_non_chevauchant`. La contrainte qui fait la fiabilité de la
--    base est celle qui refuse cette écriture, et c'est heureux : l'alternative
--    serait d'attribuer au jugé.
--
--    Les atomes-fractions restent donc l'attribution de 1870-1940 — un
--    `20464#6911` dit « la part de Lyon dans le canton 6911 », soit exactement
--    ce que la source donne. Les atomes d'arrondissement prennent le relais à
--    partir de 1943. Les deux familles portent des géométries qui se
--    recouvrent, mais leurs `membership` ne se croisent jamais dans le temps :
--    `snapshot_geom()` à une date donnée n'en voit qu'une. La section 5 le
--    vérifie.
--
--    Conséquence assumée : les 430 km² de double comptage lyonnais de 1870
--    restent. Aucune source ne permet de les lever ; seule ANR-COMMUNES le
--    pourra.
--
-- 2. TENDE ET LA BRIGUE. Italiennes jusqu'au traité de Paris de 1947, donc
--    absentes à juste titre de 1870-1940. Françaises ensuite : elles ont
--    besoin d'un atome, et GEOFLA leur donne un polygone.
--
-- 3. LES COMMUNES NÉES PUIS DISPARUES ENTRE 1943 ET 2011. Aucun polygone dans
--    la trame 2011. On les crée SANS géométrie plutôt que de leur donner celle
--    de la commune qui les a absorbées — trop grande, et c'est la fragilité
--    signalée au § 5 bis de note_1943_2012.md. Elles feront tomber le compte
--    « atome sans geometrie » de 0 à n, et c'est voulu : le trou doit se voir.
--
-- Périmètre : MÉTROPOLE. GEOFLA 2011 est métropolitain, la base 1870-1940
-- aussi. Les communes d'outre-mer sont écartées, comptées, et le choix est
-- révocable — il tient dans une clause.
--
-- Prérequis : `20_commune_moderne.sql` (table cm_commune), GEOFLA chargée.
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set fin_ancienne '1941-01-01'
\set debut_moderne '1943-02-19'

DO $$
BEGIN
    IF to_regclass('histgis.cm_commune') IS NULL THEN
        RAISE EXCEPTION 'cm_commune absente : lancer 20_commune_moderne.sql avant.';
    END IF;
END $$;

ALTER TABLE atom_geom DROP CONSTRAINT IF EXISTS atom_geom_source_check;
ALTER TABLE atom_geom ADD CONSTRAINT atom_geom_source_check CHECK (
    source IN ('geofla', 'union_prefixe', 'absorbee', 'successeur',
               'hac', 'hac_partage', 'creation_arriere', 'arrondissement')
);

-- ---------------------------------------------------------------------------
-- 0. Trace et retrait d'un passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS atome_moderne_trace (
    atom_id  text PRIMARY KEY,
    code     char(5) NOT NULL,
    famille  text NOT NULL,      -- arrondissement | rattachee_1947 | ephemere
    avec_geom boolean NOT NULL,
    km2      numeric,
    pose_le  timestamptz NOT NULL DEFAULT now()
);

DELETE FROM atom a USING atome_moderne_trace t WHERE a.atom_id = t.atom_id;
TRUNCATE atome_moderne_trace;

\echo ''
\echo '============================================================'
\echo ' ATOMES MODERNES — ce qui manque à la période 1943-2012'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Inventaire : quels codes n'ont pas d'atome ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS am_manquant;
CREATE TABLE am_manquant AS
SELECT DISTINCT c.code,
       left(c.code, 2) IN ('97', '98')                          AS outre_mer,
       EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = c.code) AS dans_geofla,
       -- un arrondissement est un code capté par un préfixe `union_prefixe`
       EXISTS (SELECT 1 FROM diag_geom_correspondance d
                WHERE d.methode = 'union_prefixe' AND c.code LIKE d.cible || '%') AS arrondissement,
       min(c.valid_from) OVER (PARTITION BY c.code)              AS ne_le,
       max(c.valid_to)   OVER (PARTITION BY c.code)              AS mort_le
FROM   cm_commune c
-- Un code n'est « sans atome » que si AUCUNE des deux voies n'aboutit.
--
-- Le premier jet ne testait que la voie directe et créait donc 906 atomes de
-- trop — un par code résolu par succession. Conséquences en chaîne : ces
-- atomes n'avaient pas de géométrie, la correspondance pointait vers eux au
-- lieu de l'atome réel, et la voie `succession` devenait inatteignable
-- (0 intervalle au lieu de 901). Deux d'entre eux, Chisa 2B366 et
-- Butry-sur-Oise 95120 — des recodages de 1976 et 1968 —, recevaient même une
-- géométrie, donc un territoire compté deux fois.
WHERE  NOT EXISTS (SELECT 1 FROM atom a WHERE a.insee_geofla = c.code)
  AND  NOT EXISTS (SELECT 1 FROM commune_successeur s
                   JOIN   atom a2 ON a2.insee_geofla = s.insee_2011
                   WHERE  s.insee_ancien = c.code)
  -- Troisième garde-fou, et c'est un test GÉOMÉTRIQUE.
  --
  -- Les deux précédents interrogent des codes. Or Pont-de-Buis-lès-Quimerch
  -- (29302) est une DESTINATION de fusion, pas une origine : `commune_
  -- successeur` ne la connaît pas comme `insee_ancien`, et aucun atome ne
  -- porte son code. Pourtant deux atomes `successeur` — les communes de 1870
  -- fusionnées en 1949 — portent déjà exactement son polygone. Lui créer un
  -- atome, c'est un troisième porteur du même territoire.
  --
  -- Le test qui vaut n'est donc pas « ce code a-t-il un atome ? » mais
  -- « ce POLYGONE est-il déjà porté ? ».
  AND  NOT EXISTS (SELECT 1
                   FROM   geofla_commune g
                   JOIN   atom_geom ag ON ag.geom && g.geom
                                      AND ST_Equals(ag.geom, ST_Multi(g.geom))
                   WHERE  g.insee_com = c.code);

-- ---------------------------------------------------------------------------
-- 1 bis. Les recodages internes à la population manquante
--
-- Chisa apparaît deux fois : `20366` de 1947 à 1976, `2B366` ensuite. Butry-
-- sur-Oise de même, `78692` puis `95120`. Ce sont des recodages — un seul
-- territoire, deux codes — et leur créer deux atomes serait les dédoubler.
-- Le premier code n'a d'ailleurs aucun polygone dans la trame 2011, ce qui
-- explique les deux « atomes sans géométrie » du passage précédent.
--
-- On replie donc chaque chaîne de recodage sur son code terminal, seul à
-- porter un polygone, et on garde les codes intermédiaires comme alias.
-- ---------------------------------------------------------------------------
ALTER TABLE am_manquant ADD COLUMN code_atome char(5);

WITH RECURSIVE arc AS (
    SELECT DISTINCT m.com_av, m.com_ap
    FROM   cm_mvt m
    WHERE  m.effet = 'recodage'
      AND  EXISTS (SELECT 1 FROM am_manquant x WHERE x.code = m.com_av)
      AND  EXISTS (SELECT 1 FROM am_manquant y WHERE y.code = m.com_ap)
),
chaine (depart, courant, n) AS (
    SELECT code, code, 0 FROM am_manquant
    UNION
    SELECT c.depart, a.com_ap, c.n + 1
    FROM   chaine c JOIN arc a ON a.com_av = c.courant
    WHERE  c.n < 5
)
UPDATE am_manquant m
   SET code_atome = t.terminal
  FROM (SELECT DISTINCT ON (depart) depart, courant AS terminal
        FROM   chaine
        ORDER  BY depart, n DESC) t
 WHERE m.code = t.depart;

\echo ''
\echo '--- recodages repliés (un territoire, un atome) ---'
SELECT code AS code_intermediaire, code_atome AS code_retenu
FROM   am_manquant WHERE code <> code_atome ORDER BY code;

-- ---------------------------------------------------------------------------
-- 1 ter. Les codes dont le successeur vit en même temps qu'eux
--
-- Un code sans atome propre se raccorde par succession à l'atome de la commune
-- qui l'a absorbé. C'est juste quand les deux se SUCCÈDENT — un recodage : le
-- 75001 d'Alfortville s'éteint en 1968 quand naît le 94002. Ce l'est beaucoup
-- moins quand ils COEXISTENT — une fusion : la commune absorbée vit de 1943 à
-- 1972, l'absorbante de 1943 à aujourd'hui, et les deux codes pointeraient sur
-- un seul atome pendant vingt-neuf ans.
--
-- Conséquence, si on laissait faire : cet atome devrait appartenir à deux
-- cantons à la fois dès que les `membership` seront posés. La contrainte
-- `membership_non_chevauchant` le refuserait — ou, pire, un rattachement
-- serait perdu en silence.
--
-- Ces codes-là ont donc besoin de LEUR atome, portant le polygone du
-- successeur : partagé, marqué comme tel, et c'est la limite de trame connue
-- du § 6.1 — la même que celle des 1 487 atomes `successeur` de `06`.
-- ---------------------------------------------------------------------------
-- On détecte le CONFLIT, pas le cas de figure qui le produit.
--
-- Un premier jet ne visait que le conflit d'un code avec SON successeur : il
-- en réglait 4 sur 13. Deux communes absorbées par une même troisième tombent
-- pourtant sur le même atome sans qu'aucune ne soit successeur de l'autre, et
-- deux codes peuvent aussi entrer en conflit alors que leur successeur commun
-- n'est pas vivant à cette date. Énumérer les motifs, c'est en oublier ; on
-- compare donc les rattachements résolus, deux à deux, sur les périodes qui se
-- chevauchent.
DROP TABLE IF EXISTS am_partage;
CREATE TABLE am_partage AS
WITH direct AS (
    SELECT DISTINCT ON (c.code) c.code, a.atom_id
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   atom a ON a.insee_geofla = c.code
    ORDER  BY c.code, a.fraction, a.atom_id
),
succ AS (
    SELECT DISTINCT ON (c.code) c.code, a.atom_id, s.insee_2011 AS code_geom
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   commune_successeur s ON s.insee_ancien = c.code
    JOIN   atom a ON a.insee_geofla = s.insee_2011
    WHERE  NOT EXISTS (SELECT 1 FROM direct d WHERE d.code = c.code)
    ORDER  BY c.code, a.fraction, a.atom_id
),
-- la voie `polygone` emprunte elle aussi un atome, et souffre donc du même
-- défaut : Pont-de-Buis (29302, née en 1949) et la commune 29138, vivante
-- jusqu'en 1965, se partageaient l'atome 19825 pendant seize ans.
poly AS (
    SELECT DISTINCT ON (c.code) c.code, ag.atom_id, c.code AS code_geom
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   geofla_commune g ON g.insee_com = c.code
    JOIN   atom_geom ag ON ag.geom && g.geom AND ST_Equals(ag.geom, ST_Multi(g.geom))
    JOIN   atom a2 ON a2.atom_id = ag.atom_id
    WHERE  NOT EXISTS (SELECT 1 FROM direct d WHERE d.code = c.code)
      AND  NOT EXISTS (SELECT 1 FROM succ  s WHERE s.code = c.code)
    ORDER  BY c.code, a2.fraction, ag.atom_id
),
-- toutes les voies qui EMPRUNTENT un atome, par opposition à `direct` qui le
-- possède. Ce sont elles, et elles seules, qui peuvent avoir à en recevoir un.
emprunt AS (
    SELECT code, atom_id, code_geom FROM succ
    UNION ALL
    SELECT code, atom_id, code_geom FROM poly
),
resolu AS (
    SELECT code, atom_id FROM direct
    UNION ALL
    SELECT code, atom_id FROM emprunt
)
-- celui qui possède l'atome par son propre code le garde ; l'emprunteur en
-- reçoit un, portant le même polygone — partagé, et déclaré comme tel.
SELECT DISTINCT e.code, e.code_geom
FROM   emprunt e
JOIN   cm_commune x ON x.code = e.code
JOIN   resolu r     ON r.atom_id = e.atom_id AND r.code <> e.code
JOIN   cm_commune y ON y.code = r.code
                   AND daterange(x.valid_from, x.valid_to, '[)')
                    && daterange(y.valid_from, y.valid_to, '[)');

\echo ''
\echo '--- codes en conflit sur un atome emprunté (atome propre requis) ---'
SELECT p.code, p.code_geom AS polygone_de,
       (SELECT min(valid_from) FROM cm_commune c WHERE c.code = p.code) AS ne_le,
       (SELECT max(valid_to)   FROM cm_commune c WHERE c.code = p.code) AS mort_le
FROM   am_partage p ORDER BY p.code;

\echo ''
\echo '--- rappel : combien de codes se raccordent, et par quelle voie ? ---'
\echo '    Un code résolu par SUCCESSION n''a pas besoin d''atome : c''est le'
\echo '    même territoire sous un autre code. Lui en créer un serait le'
\echo '    dupliquer — l''erreur du premier jet, 906 atomes de trop.'
SELECT CASE WHEN EXISTS (SELECT 1 FROM atom a WHERE a.insee_geofla = c.code)
              THEN 'directe'
            WHEN EXISTS (SELECT 1 FROM commune_successeur s
                         JOIN atom a2 ON a2.insee_geofla = s.insee_2011
                         WHERE s.insee_ancien = c.code)
              THEN 'succession'
            ELSE 'aucune - atome a creer' END AS voie,
       count(*) AS codes
FROM   (SELECT DISTINCT code FROM cm_commune) c
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '=== 1. Codes sans atome ==='
SELECT CASE WHEN outre_mer      THEN 'outre-mer (hors perimetre)'
            WHEN arrondissement THEN 'arrondissement Marseille/Lyon'
            WHEN dans_geofla    THEN 'metropole, presente en 2011'
            ELSE                     'metropole, disparue avant 2011'
       END        AS famille,
       count(*)   AS codes
FROM   am_manquant GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '--- métropole, présente en 2011 (attendu : Tende et La Brigue) ---'
SELECT m.code, g.nom_comm, m.ne_le, m.mort_le,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
FROM   am_manquant m JOIN geofla_commune g ON g.insee_com = m.code
WHERE  NOT m.outre_mer AND NOT m.arrondissement
ORDER  BY 5 DESC;

\echo ''
\echo '--- métropole, disparue avant 2011 (sans polygone possible) ---'
SELECT m.code, m.ne_le, m.mort_le,
       (SELECT v.libelle_ap FROM cm_mvt v WHERE v.com_ap = m.code ORDER BY v.date_eff LIMIT 1) AS nom
FROM   am_manquant m
WHERE  NOT m.outre_mer AND NOT m.arrondissement AND NOT m.dans_geofla
ORDER  BY m.code;

-- ---------------------------------------------------------------------------
-- 2. Les arrondissements
--
-- Découverts par le préfixe, jamais codés en dur : si `geom_correspondance.csv`
-- change, ce script suit. Chaque arrondissement reçoit SON polygone GEOFLA.
-- ---------------------------------------------------------------------------
-- L'atome et sa trace sont posés dans la MÊME instruction, via RETURNING —
-- l'idiome de `11_scission.sql`. Sans cela, une erreur survenant entre les
-- deux laisse des atomes committés et non tracés, que le retrait en tête de
-- fichier ne retrouve plus. C'est arrivé : `NULL` non casté dans un
-- SELECT DISTINCT, 25 arrondissements orphelins.
--
-- `NULL::smallint` : dans un SELECT DISTINCT, Postgres résout le type d'un
-- NULL nu en `text` et refuse l'insertion dans `com_act`.
WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT 'A' || m.code, 'A' || m.code, false, NULL::smallint, m.code
    FROM   am_manquant m
    WHERE  m.arrondissement AND m.dans_geofla AND NOT m.outre_mer
    RETURNING atom_id, insee_geofla
)
INSERT INTO atome_moderne_trace (atom_id, code, famille, avec_geom)
SELECT atom_id, insee_geofla, 'arrondissement', false FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT 'A' || m.code, ST_Multi(g.geom), 'arrondissement', false
FROM   am_manquant m
JOIN   geofla_commune g ON g.insee_com = m.code
WHERE  m.arrondissement AND m.dans_geofla AND NOT m.outre_mer;

-- ---------------------------------------------------------------------------
-- 3. Les rattachées de 1947 et les éphémères
-- ---------------------------------------------------------------------------
-- un atome par TERRITOIRE, donc par code terminal de chaîne de recodage
WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT DISTINCT 'M' || m.code_atome, 'M' || m.code_atome,
           false, NULL::smallint, m.code_atome
    FROM   am_manquant m
    WHERE  NOT m.outre_mer AND NOT m.arrondissement
    RETURNING atom_id, insee_geofla
)
INSERT INTO atome_moderne_trace (atom_id, code, famille, avec_geom)
SELECT atom_id, insee_geofla, 'territoire_neuf', false FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT DISTINCT 'M' || m.code_atome, ST_Multi(g.geom), 'geofla', false
FROM   am_manquant m
JOIN   geofla_commune g ON g.insee_com = m.code_atome
WHERE  NOT m.outre_mer AND NOT m.arrondissement;
-- un terminal sans polygone resterait sans géométrie : le trou serait déclaré,
-- pas comblé par un polygone trop grand (cf. en-tête, § 3)

-- les codes qui coexistent avec leur successeur : un atome chacun, portant le
-- polygone du successeur. `partagee = true` dit qu'il n'est pas exclusif.
WITH ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT 'S' || p.code, 'S' || p.code, false, NULL::smallint, p.code
    FROM   am_partage p
    RETURNING atom_id, insee_geofla
)
INSERT INTO atome_moderne_trace (atom_id, code, famille, avec_geom)
SELECT atom_id, insee_geofla, 'territoire_partage', false FROM ins;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT 'S' || p.code, ST_Multi(g.geom), 'successeur', true
FROM   am_partage p
JOIN   geofla_commune g ON g.insee_com = p.code_geom;

-- Les atomes qui portaient déjà ce polygone deviennent partagés eux aussi.
-- Le test est géométrique et non par code : le porteur peut avoir été trouvé
-- par la voie `polygone`, auquel cas aucun code ne le désigne.
UPDATE atom_geom ag SET partagee = true
FROM   atom_geom n
JOIN   atome_moderne_trace t ON t.atom_id = n.atom_id
                            AND t.famille = 'territoire_partage'
WHERE  ag.atom_id <> n.atom_id
  AND  ag.geom && n.geom AND ST_Equals(ag.geom, n.geom)
  AND  NOT ag.partagee;

-- la trace apprend a posteriori si l'atome a reçu un polygone, et lequel
UPDATE atome_moderne_trace t
   SET avec_geom = true,
       km2 = round((ST_Area(ag.geom) / 1e6)::numeric, 2)
  FROM atom_geom ag
 WHERE ag.atom_id = t.atom_id;

ANALYZE atom; ANALYZE atom_geom;

\echo ''
\echo '=== 2. Atomes créés ==='
SELECT famille, count(*) AS atomes,
       count(*) FILTER (WHERE avec_geom) AS avec_geometrie,
       round(sum(km2), 2)                AS km2
FROM   atome_moderne_trace GROUP BY famille ORDER BY 2 DESC;

-- ---------------------------------------------------------------------------
-- 4. La correspondance code → atome, datée
--
-- Pour 181 codes, plusieurs atomes portent le même code — la correspondance
-- plusieurs-vers-un du § 6.1. Comme ces atomes partagent AUSSI le même
-- polygone (ils le tiennent de la même jointure GEOFLA), le choix n'a aucune
-- conséquence géométrique : il est seulement nominal. On préfère donc l'atome
-- entier à une fraction, puis le plus petit identifiant, et on le signale.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS commune_moderne;
CREATE TABLE commune_moderne AS
WITH choix AS (
    SELECT DISTINCT ON (c.code)
           c.code, a.atom_id, a.fraction,
           count(*) OVER (PARTITION BY c.code) AS n_atomes
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   atom a ON a.insee_geofla = c.code
    ORDER  BY c.code, a.fraction, a.atom_id
),
succ AS (
    SELECT DISTINCT ON (c.code) c.code, a.atom_id, 1 AS n_atomes
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   commune_successeur s ON s.insee_ancien = c.code
    JOIN   atom a ON a.insee_geofla = s.insee_2011
    WHERE  NOT EXISTS (SELECT 1 FROM atom a2 WHERE a2.insee_geofla = c.code)
    ORDER  BY c.code, a.fraction, a.atom_id
),
-- les codes intermédiaires d'une chaîne de recodage : même territoire, donc
-- même atome que le code terminal
alias AS (
    SELECT m.code, a.atom_id
    FROM   am_manquant m
    JOIN   atom a ON a.insee_geofla = m.code_atome
    WHERE  m.code <> m.code_atome
),
-- un polygone déjà porté par un atome préexistant : la voie que le premier
-- jet ignorait, et qui a fait naître le doublon de Pont-de-Buis
par_polygone AS (
    SELECT DISTINCT ON (c.code) c.code, ag.atom_id
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   geofla_commune g ON g.insee_com = c.code
    JOIN   atom_geom ag ON ag.geom && g.geom AND ST_Equals(ag.geom, ST_Multi(g.geom))
    JOIN   atom a2 ON a2.atom_id = ag.atom_id
    WHERE  NOT EXISTS (SELECT 1 FROM atom a3 WHERE a3.insee_geofla = c.code)
    ORDER  BY c.code, a2.fraction, ag.atom_id
)
SELECT cm.code, cm.valid_from, cm.valid_to,
       coalesce(ch.atom_id, al.atom_id, s.atom_id, pp.atom_id)  AS atom_id,
       CASE WHEN ch.atom_id IS NOT NULL THEN 'direct'
            WHEN al.atom_id IS NOT NULL THEN 'recodage'
            WHEN s.atom_id  IS NOT NULL THEN 'succession'
            WHEN pp.atom_id IS NOT NULL THEN 'polygone'
            ELSE                             'aucun' END        AS voie,
       coalesce(ch.n_atomes, 1) > 1                             AS choix_ambigu,
       left(cm.code, 2) IN ('97', '98')                         AS outre_mer
FROM   cm_commune cm
LEFT   JOIN choix ch        ON ch.code = cm.code
LEFT   JOIN alias al        ON al.code = cm.code
LEFT   JOIN succ  s         ON s.code  = cm.code
LEFT   JOIN par_polygone pp ON pp.code = cm.code;

ALTER TABLE commune_moderne ADD PRIMARY KEY (code, valid_from);
CREATE INDEX commune_moderne_atome_idx ON commune_moderne (atom_id);
CREATE INDEX commune_moderne_periode_idx ON commune_moderne
    USING gist (daterange(valid_from, valid_to, '[)'));

\echo ''
\echo '=== 3. Correspondance code → atome ==='
SELECT voie,
       count(*)                                  AS intervalles,
       count(DISTINCT code)                      AS codes,
       count(*) FILTER (WHERE choix_ambigu)      AS dont_choix_ambigu,
       count(*) FILTER (WHERE outre_mer)         AS dont_outre_mer
FROM   commune_moderne GROUP BY voie ORDER BY 2 DESC;

\echo ''
\echo '--- un atome porte-t-il plusieurs codes à la même date ? (doit valoir 0) ---'
\echo '    Deux codes vivants simultanément et rattachés au même atome, ce'
\echo '    serait le même territoire compté deux fois. Un atome peut en'
\echo '    revanche porter plusieurs codes SUCCESSIFS — c''est même tout'
\echo '    l''objet du continuum, et des recodages.'
SELECT count(*) AS codes_simultanes_sur_un_atome
FROM   commune_moderne a
JOIN   commune_moderne b ON b.atom_id = a.atom_id
                        AND b.code <> a.code
                        AND daterange(a.valid_from, a.valid_to, '[)')
                         && daterange(b.valid_from, b.valid_to, '[)')
WHERE  a.atom_id IS NOT NULL AND a.code < b.code;

\echo ''
\echo '--- codes encore sans atome (doit être l''outre-mer, et rien d''autre) ---'
SELECT left(code, 3) AS prefixe, count(DISTINCT code) AS codes
FROM   commune_moderne WHERE voie = 'aucun'
GROUP  BY 1 ORDER BY 2 DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- 5. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Recettes ==='
\echo '--- le relais est-il propre ? ---'
\echo '    Les atomes `union_prefixe` ne doivent avoir AUCUN membership après'
\echo '    le 1er janvier 1941, et les atomes d''arrondissement aucun avant'
\echo '    1943. C''est ce qui garantit que les deux familles, dont les'
\echo '    géométries se recouvrent, ne coexistent jamais à une même date.'
SELECT (SELECT count(*) FROM membership m JOIN atom_geom ag USING (atom_id)
         WHERE ag.source = 'union_prefixe' AND m.valid_to > :'fin_ancienne'::date)
                                                        AS union_prefixe_apres_1941,
       (SELECT count(*) FROM membership m JOIN atom_geom ag USING (atom_id)
         WHERE ag.source = 'arrondissement' AND m.valid_from < :'debut_moderne'::date)
                                                        AS arrondissement_avant_1943;

\echo ''
\echo '--- territoire déjà porté par un atome préexistant (doit valoir 0) ---'
\echo '    La recette porte sur TOUS les atomes créés par ce script, pas sur la'
\echo '    seule famille `arrondissement`. Le premier jet la restreignait aux'
\echo '    arrondissements et n''a donc pas vu Chisa et Butry-sur-Oise, deux'
\echo '    recodages qui recevaient une géométrie déjà portée ailleurs.'
\echo '    Le test est l''INCLUSION d''un point intérieur, pas l''égalité :'
\echo '    un polygone peut être contenu dans un autre sans lui être égal.'
-- Le partage se juge dans le TEMPS, pas sur le libellé de la source.
--
-- Le jet précédent excluait `union_prefixe` par son nom, et laissait donc
-- passer l'atome 28580 — un `hac` qui porte lui aussi tout Lyon — flaggant les
-- neuf arrondissements. Ce qui compte n'est pas d'où vient la géométrie du
-- porteur, mais s'il est encore rattaché à quelque chose après 1943 : si son
-- `membership` s'arrête en 1941, les deux atomes ne coexistent jamais à une
-- même date et le recouvrement est sans effet sur `snapshot_geom()`.
SELECT count(*) FILTER (WHERE actif_apres_1943)      AS conflit_reel,
       count(*) FILTER (WHERE NOT actif_apres_1943)  AS recouvrement_sans_effet
FROM (
    SELECT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = o.atom_id
                      AND m.valid_to > :'debut_moderne'::date) AS actif_apres_1943
    FROM   atome_moderne_trace t
    JOIN   atom_geom n ON n.atom_id = t.atom_id
    JOIN   atom_geom o ON o.atom_id <> n.atom_id
                      AND NOT EXISTS (SELECT 1 FROM atome_moderne_trace t2
                                       WHERE t2.atom_id = o.atom_id)
                      AND o.geom && n.geom
                      AND ST_Contains(o.geom, ST_PointOnSurface(n.geom))
) x;

\echo ''
\echo '    `conflit_reel` doit valoir 0 : un territoire porté deux fois à une'
\echo '    même date serait compté deux fois. `recouvrement_sans_effet`'
\echo '    dénombre les inclusions dans un atome de la période ancienne —'
\echo '    attendu : les 9 arrondissements de Lyon dans l''atome 28580, plus'
\echo '    les 16 de Marseille dans le leur.'

\echo ''
\echo '--- couverture de la trame par les atomes (métropole) ---'
\echo '    Chaque commune GEOFLA doit être portée par au moins un atome.'
\echo '    Marseille et Lyon comptent désormais deux fois : l''union pour la'
\echo '    période ancienne, les arrondissements pour la moderne. Attendu.'
\echo '    Le test porte sur le TERRITOIRE, pas sur le code : Pont-de-Buis n''a'
\echo '    aucun atome à son code, et son territoire est pourtant porté par les'
\echo '    deux communes de 1870 qui ont fusionné pour la former.'
SELECT count(*) AS communes_geofla,
       count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM atom_geom ag
           WHERE  ag.geom && g.geom
             AND  ST_Contains(ag.geom, ST_PointOnSurface(g.geom)))) AS territoire_porte,
       count(*) FILTER (WHERE EXISTS (
           SELECT 1 FROM atom a WHERE a.insee_geofla = g.insee_com)) AS dont_par_le_code
FROM   geofla_commune g;

\echo ''
\echo '--- état des géométries ---'
\echo '    `atome sans geometrie` passe de 0 à n : ce sont les communes nées'
\echo '    puis disparues entre 1943 et 2011, dont la trame 2011 ne sait rien.'
\echo '    Le trou est déclaré, pas comblé par un polygone trop grand.'
SELECT * FROM check_geom();

\echo ''
\echo '--- effectifs 1870-1940 : rigoureusement inchangés ---'
\echo '    Aucun membership n''a été posé : la base ancienne ne doit pas bouger'
\echo '    d''une unité ni d''un atome.'
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1885-06-01'), ('1940-06-01')) AS t(d),
       LATERAL count_units(d::date) c
WHERE  c.niveau = 'canton' ORDER BY 1;

\echo ''
\echo 'Pour tout défaire :'
\echo '  DELETE FROM histgis.atom a USING histgis.atome_moderne_trace t'
\echo '   WHERE a.atom_id = t.atom_id;'
\echo '  TRUNCATE histgis.atome_moderne_trace; DROP TABLE histgis.commune_moderne;'
\echo ''
\echo 'Tables : am_manquant, atome_moderne_trace, commune_moderne.'
\echo 'Aucun membership posé — il n''y a pas encore d''unité moderne.'

-- ============================================================================
-- histgis — 73_recette_1967.sql : les décrets de 1967 jugés par le COG de 1968
--
--   psql -d histgis -1 -f sql/73_recette_1967.sql
--
-- POURQUOI CETTE RECETTE EST DIFFÉRENTE DES AUTRES
-- ================================================
-- Le contrôle habituel du dépôt confronte une extraction au COG de 1999 — une
-- source qui n'a pas vu le texte des décrets. Il est bon, mais il regarde
-- trente ans plus tard : un désaccord peut venir de nous comme du monde.
--
-- Ici, les deux sources sont séparées par CINQ MOIS.
--
--   * les six décrets du 20 juillet 1967 créent les cantons de l'Essonne, des
--     Hauts-de-Seine, de la Seine-Saint-Denis, du Val-de-Marne, du Val-d'Oise
--     et des Yvelines, avec effet à la naissance de ces départements le
--     1er janvier 1968 ;
--   * le jalon de 1968, posé par `59`, vient du recensement de mars 1968.
--
-- Elles ne partagent rien : un texte de décret OCRisé du JO du 22 juillet
-- 1967 d'un côté, les fascicules du recensement OCRisés séparément de l'autre.
-- Entre les deux, il ne s'est presque rien passé. Un désaccord ne peut donc
-- PAS être imputé au monde : il accuse l'une des deux lectures.
--
-- C'est le contrôle le plus serré dont le trou 1943-1999 dispose.
--
-- CE QUE CE FICHIER FAIT
-- ======================
-- Il ne pose aucun `membership`. Il produit deux tables de recette :
--
--   r67_canton    un verdict par canton créé en 1967
--   r67_transfert la simulation, SANS ÉCRITURE, de la pose des cinq
--                 transferts isolés de commune (cf. § 3)
--
-- L'APPARIEMENT DES CANTONS, ET POURQUOI PAS PAR LE NOM
-- =====================================================
-- Les décrets nomment les cantons, le COG les numérote. On n'apparie donc pas
-- par le nom mais **par la composition** : le canton de 1968 retenu est celui
-- qui partage le plus de communes avec la liste du décret, dans le même
-- département. C'est indépendant du nom — et le nom est justement ce que
-- l'OCR abîme, quand il n'est pas la nomenclature elle-même qui le déplace
-- (la série havraise décalée d'un rang après 1991).
--
-- Seuil : trois communes entières. En deçà, deux cantons voisins partagent
-- facilement une commune et le recouvrement ne distingue plus rien. Seuil
-- repris de `controle_composition.py`, posé avant de mesurer et non ajusté.
--
-- Prérequis : `72_registre_actes.sql`, et le jalon de 1968 posé par
--             `58` + `59`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon '1968-06-01'
\set mini  3

\echo ''
\echo '============================================================'
\echo ' RECETTE — les décrets de 1967 contre le recensement de 1968'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql d''abord.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton'
                      AND periode @> DATE '1968-06-01') THEN
        RAISE EXCEPTION
          'PRÉREQUIS : le jalon de 1968 n''est pas en base (sql/58 puis sql/59).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Ce que les décrets de 1967 disent
--
-- On ne garde que les lignes qui portent un atome : une commune sans atome
-- n'est comparable à rien. Elles restent comptées au § 4.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r67_dit;
CREATE TABLE r67_dit AS
SELECT c.decret, c.date_acte, c.dep, c.canton, c.atome
FROM   acte_composition c
WHERE  c.date_acte >= DATE '1967-01-01'
  AND  c.date_acte <  DATE '1968-01-01'
  AND  c.atome IS NOT NULL
GROUP  BY 1,2,3,4,5;      -- une commune peut être citée deux fois par un décret

CREATE INDEX r67_dit_idx ON r67_dit (dep, canton);

\echo ''
\echo '-- 1. ce que les décrets de 1967 donnent à juger'
SELECT count(*)                        AS lignes,
       count(DISTINCT (dep, canton))   AS cantons,
       count(DISTINCT decret)          AS decrets,
       count(DISTINCT dep)             AS departements
FROM   r67_dit;

-- ---------------------------------------------------------------------------
-- 2. Ce que la base dit au 1er juin 1968
--
-- On interroge le MODÈLE, pas le fichier de préparation : c'est la base telle
-- qu'elle répondra à `snapshot(1968-06-01)` qui est jugée.
--
-- L'atome d'une commune multicantonale de 1968 porte le suffixe `#canton`
-- (mécanisme de `24` § 4). On le retire pour comparer, sans quoi aucune
-- fraction ne se retrouverait.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r67_base;
CREATE TABLE r67_base AS
SELECT split_part(m.atom_id, '#', 1) AS atome,
       m.unit_id                     AS canton_1968,
       u.dep                         AS dep_1968
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'jalon'::date
GROUP  BY 1,2,3;

CREATE INDEX r67_base_idx ON r67_base (atome);

-- ---------------------------------------------------------------------------
-- 3. Le verdict, canton par canton
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r67_canton;
CREATE TABLE r67_canton AS
WITH taille AS (
    SELECT decret, dep, canton, count(*) AS communes
    FROM   r67_dit GROUP BY 1,2,3
),
votes AS (
    SELECT d.decret, d.dep, d.canton, b.canton_1968, count(*) AS n
    FROM   r67_dit d
    JOIN   r67_base b ON b.atome = d.atome AND b.dep_1968 = d.dep
    GROUP  BY 1,2,3,4
),
meilleur AS (
    SELECT DISTINCT ON (decret, dep, canton)
           decret, dep, canton, canton_1968, n
    FROM   votes ORDER BY decret, dep, canton, n DESC, canton_1968
)
SELECT t.decret, t.dep, t.canton, t.communes,
       m.canton_1968,
       coalesce(m.n, 0)                                        AS retrouvees,
       CASE WHEN t.communes > 0
            THEN round(100.0 * coalesce(m.n, 0) / t.communes, 0)
       END                                                     AS taux,
       CASE
         WHEN t.communes < :mini                       THEN 'trop court'
         WHEN m.canton_1968 IS NULL                    THEN 'aucune commune retrouvée en 1968'
         WHEN m.n::numeric / t.communes >= 0.8         THEN 'accord'
         WHEN m.n::numeric / t.communes >= 0.5         THEN 'accord partiel'
         ELSE                                               'désaccord'
       END                                                     AS verdict
FROM   taille t
LEFT   JOIN meilleur m USING (decret, dep, canton);

\echo ''
\echo '-- 3. verdict'
SELECT verdict, count(*) AS cantons
FROM   r67_canton
GROUP  BY verdict
ORDER  BY CASE verdict WHEN 'accord' THEN 1 WHEN 'accord partiel' THEN 2
                       WHEN 'désaccord' THEN 3 WHEN 'trop court' THEN 4
                       ELSE 5 END;

\echo ''
\echo '   par département'
SELECT dep,
       count(*) FILTER (WHERE verdict = 'accord')         AS accord,
       count(*) FILTER (WHERE verdict = 'accord partiel') AS partiel,
       count(*) FILTER (WHERE verdict = 'désaccord')      AS desaccord,
       count(*) FILTER (WHERE verdict = 'trop court')     AS trop_court
FROM   r67_canton GROUP BY dep ORDER BY dep;

\echo ''
\echo '   sur les cantons jugeables, la part des communes confirmées'
SELECT sum(retrouvees) AS confirmees, sum(communes) AS total,
       round(100.0 * sum(retrouvees) / nullif(sum(communes), 0), 1) AS pct
FROM   r67_canton
WHERE  verdict IN ('accord', 'accord partiel', 'désaccord');

\echo ''
\echo '   LE CHIFFRE À LIRE : un désaccord ici ne peut pas venir du monde.'
\echo '   Cinq mois séparent le décret du recensement. S''il y en a, ils'
\echo '   accusent l''une des deux lectures, et il faut aller voir laquelle.'
SELECT decret, dep, canton, communes, retrouvees, canton_1968, taux
FROM   r67_canton WHERE verdict = 'désaccord' ORDER BY dep, canton;

-- ---------------------------------------------------------------------------
-- 4. Ce qui n'a pas pu être jugé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. hors jugement'
\echo '   lignes de 1967 sans atome (fractions de ville, noms non appariés) :'
SELECT count(*) AS lignes
FROM   acte_composition
WHERE  date_acte >= DATE '1967-01-01' AND date_acte < DATE '1968-01-01'
  AND  atome IS NULL;

\echo '   atomes cités par le décret et absents du jalon de 1968 :'
\echo '   (le rappel de l''extraction du COG 1968 est de 91,4 % — l''essentiel'
\echo '    de cet écart est là, et c''est une lacune de 1968, pas de 1967)'
SELECT count(DISTINCT d.atome) AS atomes
FROM   r67_dit d
WHERE  NOT EXISTS (SELECT 1 FROM r67_base b WHERE b.atome = d.atome);

-- ---------------------------------------------------------------------------
-- 5. LES CINQ TRANSFERTS — simulation, sans écriture
--
-- On sait tout d'eux sauf une chose : la date à laquelle ils prennent effet.
-- Le décret de 1997 est explicite (« prendra effet pour le prochain
-- renouvellement des conseils généraux ») ; les autres ne disent rien, et les
-- conseils généraux se renouvelaient par MOITIÉ — « le prochain
-- renouvellement » d'un canton dépend de sa série, que nous n'avons pas.
--
-- Poser un `membership` demande une borne basse. Choisir la date de signature
-- serait une convention déguisée en fait, et le décalage possible est d'un
-- renouvellement — trois ans. On simule donc, et on ne écrit pas.
--
-- Ce que la simulation montre : la place est libre, l'atome existe, le canton
-- de destination est une unité connue. Il ne manque que la convention.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r67_transfert;
CREATE TABLE r67_transfert AS
SELECT t.date_acte, t.dep, t.commune, t.insee, t.atome,
       t.canton_source, t.canton_dest,
       -- le canton de 1999 où la base place effectivement cette commune
       (SELECT m.unit_id FROM membership m
         WHERE m.atom_id = t.atome AND m.niveau = 'canton'
           AND m.periode @> DATE '1999-06-01' LIMIT 1)          AS canton_1999_en_base,
       -- La place est-elle libre entre l'acte et 1999 ?
       -- NULL, et non `true`, quand l'atome est inconnu : sans atome la
       -- question n'a pas de sens, et un `true` s'y lirait comme un feu vert.
       CASE WHEN t.atome IS NULL THEN NULL
            ELSE NOT EXISTS (SELECT 1 FROM membership m
                              WHERE m.atom_id = t.atome AND m.niveau = 'canton'
                                AND m.periode && daterange(t.date_acte,
                                                           DATE '1999-01-01', '[)'))
       END                                                      AS place_libre
FROM   acte_transfert t;

\echo ''
\echo '-- 5. les cinq transferts : simulation'
SELECT date_acte, dep, commune, atome, canton_source, canton_dest,
       canton_1999_en_base, place_libre
FROM   r67_transfert ORDER BY date_acte, dep;

\echo ''
\echo '   Si `place_libre` vaut partout `t` et `atome` n''est jamais NULL, il ne'
\echo '   manque que la convention de date d''effet pour poser ces cinq lignes.'
\echo '   Voir cantons/note_entree_en_base.md § 4.'

ANALYZE r67_canton;

\echo ''
\echo '============================================================'
\echo ' Recette terminée. Aucun membership n''a été touché.'
\echo '============================================================'

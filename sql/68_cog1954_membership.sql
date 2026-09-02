-- ============================================================================
-- histgis — 68_cog1954_membership.sql : le jalon de 1954 entre dans le modèle
--
--   psql -d histgis -1 -f sql/68_cog1954_membership.sql
--
-- SECOND jalon cantonal dans le trou 1943-1999, quatorze ans avant celui de
-- 1968. À lancer en une seule transaction : il écrit dans `atom` et
-- `membership`.
--
-- POURQUOI DEUX POINTS VALENT BIEN PLUS QUE DEUX FOIS UN POINT
-- ============================================================
-- Avec le seul jalon de 1968, la composition cantonale entre 1943 et 1999 était
-- connue en un instant et supposée partout ailleurs. Avec 1954 et 1968, elle
-- devient CONFRONTABLE : le § 6 de `66` mesure **94,2 % d'accord sur 25 370
-- communes** entre deux lectures qui ne partagent ni le fascicule, ni la chaîne
-- OCR, ni la méthode d'appariement.
--
-- Ce chiffre ne dit pas que les deux lectures sont justes — deux OCR peuvent se
-- tromper de la même façon sur une même typographie. Il dit qu'elles sont
-- INDÉPENDAMMENT cohérentes, ce qui est le seul contrôle dont nous disposions
-- sur cette période. *La cohérence n'est pas l'exactitude.*
--
-- LES BORNES, ET CE QU'ELLES SUPPOSENT
-- =====================================
--   [1954-01-01, 1955-01-01)
--
-- Mêmes bornes que `67`, pour que l'année 1954 forme un jalon unique et non
-- deux morceaux disjoints. Mais **le recensement observe le 10 MAI, pas le
-- 1er janvier** : la borne est plus large que la source de quatre mois en
-- amont. Le § 7 mesure ce que cet élargissement coûte — le nombre d'atomes
-- posés dont la commune n'existait pas encore au 1er janvier 1954. Un écart
-- nul rendrait la question théorique ; un écart non nul devra être resserré.
--
-- Comme pour 1968, la borne s'arrête au 31 décembre. Étendre jusqu'en 1968
-- supposerait une stabilité que l'annexe VII de Gaudillère dément — elle compte
-- TRENTE créations cantonales entre 1954 et 1968.
--
-- CE QUI DISTINGUE 1954 DE 1968 DANS LA QUALITÉ
-- ==============================================
-- 1968 imprime le code INSEE : la clé est lue, et le nom sert de contrôle.
-- 1954 ne porte que le NOM, et le code a été reconstruit en deux passes :
--
--   `ferme`         26 202   correspondance EXACTE et unique sur le nom
--   `ferme_canton`   3 361   ressemblance CONFIRMÉE par le canton, signal
--                            indépendant du nom
--
-- Les deux sont posées, avec leur origine inscrite dans `c54_qualite`. La
-- seconde n'est pas moins sûre en principe — un appariement flou confirmé par
-- une information étrangère à la ressemblance vaut mieux qu'un exact non
-- confirmé — mais elle repose sur un signal de plus, donc sur une hypothèse de
-- plus. On les distingue pour pouvoir les distinguer plus tard.
--
-- NE SONT PAS POSÉES : `canton_contredit` (115), `canton_indetermine` (55),
-- `exact_collision` (40), `aucun` (1 627). Elles n'ont pas de code INSEE et
-- n'entrent donc même pas dans `c54_lien`.
--
-- LA COLLISION QUE PERSONNE N'A ENCORE CHERCHÉE
-- ==============================================
-- `apparie_noms.py` juge l'unicité en seconde passe, mais SEULEMENT parmi ses
-- propres appariements exacts. `confirme_par_canton.py` pose ensuite 3 361
-- codes sans vérifier qu'aucun d'eux ne vise une commune déjà prise par un
-- `ferme`. **Ce contrôle n'a jamais été fait**, et le § 2 bis le fait ici : il
-- compte les communes visées par plus d'une ligne. C'est le même angle mort que
-- `codes_orphelins.py` avait en 1968 — un garde-fou qui regarde en arrière mais
-- pas de côté.
--
-- Prérequis : `66_cog1954_stage.sql` (c54_lien), puis `67` pour les trois
-- cantons délégués.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut '1954-01-01'
\set jalon_fin   '1955-01-01'
\set date_1954   '1954-05-10'

\echo ''
\echo '============================================================'
\echo ' COG 1954 — pose du jalon cantonal'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.c54_lien') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/66_cog1954_stage.sql d''abord.';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS c54_trace (
    quoi text NOT NULL,          -- 'membership' | 'atom'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
--
-- Les membership d'abord, ils référencent les atomes. Et jamais la trace des
-- autres fichiers : `67` défait la sienne, `68` la sienne.
-- ---------------------------------------------------------------------------
DELETE FROM membership m
 USING c54_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

DELETE FROM atom a
 USING c54_trace t
 WHERE t.quoi = 'atom' AND t.cle = a.atom_id;

TRUNCATE c54_trace;

\echo ''
\echo '-- 1. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 2. Les cantons délégués à `67`
--
-- Même déclaration explicite que `c68_delegue`, et pour la même raison : le
-- § 4 écarte déjà ce qui est physiquement posé, mais cela ferait dépendre le
-- résultat de l'ordre d'exécution. Si `67` n'a pas tourné, `68` poserait ces
-- treize communes lui-même, sans le contrôle 13/13 face aux décrets — et `67`
-- échouerait ensuite sur la contrainte d'exclusion.
--
-- *Un ordre se perd, un garde-fou reste.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_delegue;
CREATE TABLE c54_delegue (canton_id text PRIMARY KEY, pose_par text, motif text);
INSERT INTO c54_delegue VALUES
  ('1930', '67_cantons_1949_1951.sql', 'Brive-Sud, D. 13.9.1951'),
  ('4630', '67_cantons_1949_1951.sql', 'Sousceyrac, D. 5.9.1949'),
  ('0631', '67_cantons_1949_1951.sql', 'Tende, D. 10.9.1951 — Tende et La '
   'Brigue sont françaises depuis 1947 et n''ont pas d''atome');

\echo ''
\echo '-- 2 ter. cantons délégués à 67 — non posés ici'
SELECT d.canton_id, d.motif,
       (SELECT count(*) FROM c54_lien l WHERE l.canton_id = d.canton_id) AS lignes
FROM   c54_delegue d ORDER BY d.canton_id;

-- ---------------------------------------------------------------------------
-- 2 bis. CE QUE `67` A RÉVÉLÉ SANS LE CHERCHER
--
-- `67` a posé ses onze rattachements mais créé ZÉRO unité : `INSERT 0 0`. Les
-- trois `unit_id` existaient déjà, apportés par `24_canton_moderne.sql` depuis
-- le COG de 1999.
--
-- **La prémisse écrite dans l'en-tête de `66` était donc fausse** : ces cantons
-- ne sont invisibles qu'à TRF-GIS, qui s'arrête en 1940 ; la nomenclature
-- moderne les connaît. Le § 4a de `66` le disait déjà en ne les listant pas
-- parmi les cantons inconnus — je ne l'avais pas lu ainsi.
--
-- Ce qui en découle n'est pas anodin. Réutiliser `1930` pour le Brive-Sud de
-- 1951 AFFIRME que c'est la même unité que le `1930` de 1999, lequel s'appelle
-- « Brive-la-Gaillarde-Sud-Est ». Le nom a changé ; le territoire aussi,
-- peut-être. Le contrôle ci-dessous confronte les deux compositions.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 2 bis. les cantons de 67 : composition de 1954 vs composition moderne'
SELECT d.canton_id,
       (SELECT u.nom FROM unit u WHERE u.unit_id = d.canton_id)  AS nom_moderne,
       (SELECT count(*) FROM membership m
         WHERE m.unit_id = d.canton_id AND m.niveau = 'canton'
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> :'jalon_debut'::date)                          AS atomes_1954,
       (SELECT count(DISTINCT m.atom_id) FROM membership m
         WHERE m.unit_id = d.canton_id AND m.niveau = 'canton'
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> '1999-01-01'::date)                            AS atomes_1999,
       (SELECT count(*) FROM membership a
         JOIN membership b ON b.atom_id = a.atom_id
                          AND b.unit_id = d.canton_id AND b.niveau = 'canton'
                          AND daterange(b.valid_from, b.valid_to, '[)')
                              @> '1999-01-01'::date
         WHERE a.unit_id = d.canton_id AND a.niveau = 'canton'
           AND daterange(a.valid_from, a.valid_to, '[)')
               @> :'jalon_debut'::date)                          AS communs
FROM   c54_delegue d ORDER BY d.canton_id;

\echo ''
\echo '   `communs` = 0 avec `atomes_1954` et `atomes_1999` non nuls voudrait'
\echo '   dire que le même numéro désigne DEUX territoires disjoints à 45 ans'
\echo '   d''écart — l''identité serait alors une invention du chargement, pas'
\echo '   un fait. Un recouvrement large la rend au contraire plausible.'

-- ---------------------------------------------------------------------------
-- 3. Ce qui est posable, et avec quelle qualité
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_pose;
CREATE TABLE c54_pose AS
WITH retenu AS (
    SELECT l.*
    FROM   c54_lien l
    WHERE  l.commune_vivante
      AND  l.atome IS NOT NULL
      AND  l.canton_connu
      AND  NOT EXISTS (SELECT 1 FROM c54_delegue d
                        WHERE d.canton_id = l.canton_id)
),
-- `count(DISTINCT …) OVER (…)` n'existe pas en PostgreSQL — la fenêtre ne sait
-- pas dédupliquer. On agrège d'abord, on rejoint ensuite : c'est plus verbeux
-- et strictement équivalent.
n_par_commune AS (
    SELECT insee, count(DISTINCT canton_id) AS n_cantons
    FROM   retenu GROUP BY insee
),
posable AS (
    SELECT r.*, n.n_cantons
    FROM   retenu r JOIN n_par_commune n ON n.insee = r.insee
)
SELECT p.insee,
       p.nom_lu,
       p.dep,
       p.canton_id,
       p.atome                                     AS atome_commune,
       p.n_cantons,
       p.n_atomes,
       p.appariement,
       CASE WHEN p.n_cantons > 1
            THEN p.atome || '#' || p.canton_id
            ELSE p.atome
       END                                         AS atome_final,
       p.n_cantons > 1                             AS est_fraction,
       -- LA QUALITÉ, par ordre de gravité décroissante
       CASE
         WHEN p.n_atomes > 1                  THEN 'atome_ambigu'
         WHEN p.appariement = 'ferme_canton'  THEN 'nom_flou_confirme'
         ELSE 'ferme'
       END                                         AS qualite
FROM   posable p;

CREATE INDEX c54_pose_atome_idx ON c54_pose (atome_final);

\echo ''
\echo '-- 3. ce qui va être posé, par qualité'
SELECT qualite,
       count(*)                                  AS lignes,
       count(DISTINCT insee)                     AS communes,
       count(*) FILTER (WHERE est_fraction)      AS dont_fractions
FROM   c54_pose GROUP BY qualite ORDER BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 3 bis. LES COMMUNES VISÉES PAR PLUSIEURS LIGNES — le contrôle manquant
--
-- Deux causes, qu'il faut séparer :
--
--   * MULTICANTONALES. Une commune partagée entre deux cantons est lue deux
--     fois, à deux cantons différents. C'est un FAIT du territoire, traité par
--     l'atome-fraction comme dans `24` § 4 et `59` § 3.
--
--   * COLLISION D'APPARIEMENT. Deux lignes distinctes ont reçu le même code
--     INSEE — l'une par `apparie_noms`, l'autre par `confirme_par_canton`, qui
--     n'a jamais vérifié que sa cible était libre. Ici l'une des deux est
--     nécessairement fausse.
--
-- Le canton les départage : cantons différents = probablement multicantonale,
-- canton identique = probablement collision. Ce n'est pas une preuve, c'est un
-- tri — et il faut le lire avant de croire au chiffre des fractions.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_multi_ligne;
CREATE TABLE c54_multi_ligne AS
SELECT insee,
       count(*)                                             AS n_lignes,
       count(DISTINCT canton_id)                            AS n_cantons,
       string_agg(DISTINCT canton_id, ',' ORDER BY canton_id) AS cantons,
       string_agg(DISTINCT nom_lu, ' | ')                   AS noms_lus,
       string_agg(DISTINCT appariement, ',')                AS appariements
FROM   c54_pose GROUP BY insee HAVING count(*) > 1;

\echo ''
\echo '-- 3 bis. communes visées par plus d''une ligne'
SELECT count(*) FILTER (WHERE n_cantons > 1)  AS multicantonales_probables,
       count(*) FILTER (WHERE n_cantons = 1)  AS collisions_probables,
       sum(n_lignes)                          AS lignes_concernees
FROM   c54_multi_ligne;

\echo ''
\echo '   les collisions probables — MÊME code, MÊME canton, deux noms lus :'
SELECT insee, noms_lus, cantons, appariements
FROM   c54_multi_ligne WHERE n_cantons = 1
ORDER  BY insee LIMIT 15;

\echo ''
\echo '   les multicantonales probables, dix exemples :'
SELECT insee, noms_lus, cantons FROM c54_multi_ligne WHERE n_cantons > 1
ORDER  BY n_lignes DESC, insee LIMIT 10;

-- Une commune lue deux fois AU MÊME CANTON n'apporte rien de plus la seconde
-- fois : ou c'est un doublon de lecture, ou c'est une collision — dans les deux
-- cas un seul rattachement est justifié, et le second serait faux.
-- On en garde UNE, choisie par `ctid` : l'identité physique de la ligne est la
-- seule chose qui départage deux doublons exacts. C'est la leçon de `59` § 2
-- bis, où `min(insee)` ne suffisait pas.
DELETE FROM c54_pose p
 WHERE p.ctid <> (SELECT min(q.ctid) FROM c54_pose q
                   WHERE q.insee = p.insee AND q.canton_id = p.canton_id);

-- ---------------------------------------------------------------------------
-- 3 ter. LES ATOMES PARTAGÉS PAR PLUSIEURS COMMUNES DE 1954
--
-- `cm_atome` fait passer une commune disparue par son successeur : deux
-- communes distinctes en 1954, fusionnées depuis, se résolvent au MÊME atome.
-- Si leurs cantons diffèrent, `membership_non_chevauchant` refuse le second.
--
-- Ce n'est pas un défaut de lecture mais la conséquence du choix de `20` : la
-- période moderne est portée par un continuum d'atomes 1870-2012, et l'atome
-- est la maille du TERRITOIRE, pas de la personne juridique. En 1954 le cas est
-- mécaniquement plus fréquent qu'en 1968 — quatorze ans de fusions en plus.
--
-- On écarte, et on compte. Poser l'un des deux au hasard donnerait un canton
-- faux à un territoire, sans trace.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_atome_partage;
CREATE TABLE c54_atome_partage AS
SELECT atome_final,
       count(*)                        AS n_lignes,
       count(DISTINCT insee)           AS n_communes,
       count(DISTINCT canton_id)       AS n_cantons,
       string_agg(DISTINCT insee, ',' ORDER BY insee)         AS communes,
       string_agg(DISTINCT canton_id, ',' ORDER BY canton_id) AS cantons
FROM   c54_pose GROUP BY atome_final HAVING count(*) > 1;

\echo ''
\echo '-- 3 ter. atomes visés par plusieurs lignes'
SELECT count(*)                                  AS atomes_partages,
       sum(n_lignes)                             AS lignes,
       sum(n_communes)                           AS communes,
       count(*) FILTER (WHERE n_cantons = 1)     AS dont_meme_canton
FROM   c54_atome_partage;

\echo ''
\echo '   dix exemples :'
SELECT atome_final, communes, cantons FROM c54_atome_partage
ORDER BY n_lignes DESC, atome_final LIMIT 10;

-- Cantons divergents : on écarte tout, aucune des deux lectures ne prime.
DELETE FROM c54_pose p
 USING c54_atome_partage x
 WHERE p.atome_final = x.atome_final AND x.n_cantons > 1;

-- Même canton : une seule ligne suffit à porter l'information.
DELETE FROM c54_pose p
 USING c54_atome_partage x
 WHERE p.atome_final = x.atome_final
   AND x.n_cantons = 1
   AND p.ctid <> (SELECT min(q.ctid) FROM c54_pose q
                   WHERE q.atome_final = x.atome_final);

DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atome_final) INTO n, ex
      FROM (SELECT atome_final FROM c54_pose
             GROUP BY atome_final HAVING count(*) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'GARDE-FOU : % atomes finaux encore en double (ex. %).', n, ex;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Les atomes-fraction
--
-- Créés seulement s'ils n'existent pas : `24` et `59` ont pu poser le même
-- identifiant, et l'atome est alors réutilisé.
-- ---------------------------------------------------------------------------
WITH nouveau AS (
    SELECT DISTINCT p.atome_final, a.cassini, a.com_act, a.insee_geofla
    FROM   c54_pose p
    JOIN   atom a ON a.atom_id = p.atome_commune
    WHERE  p.est_fraction
      AND  NOT EXISTS (SELECT 1 FROM atom x WHERE x.atom_id = p.atome_final)
),
ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT atome_final, cassini, true, com_act, insee_geofla FROM nouveau
    RETURNING atom_id
)
INSERT INTO c54_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

\echo ''
\echo '-- 4. atomes-fraction créés'
SELECT count(*) AS crees FROM c54_trace WHERE quoi = 'atom';

-- ---------------------------------------------------------------------------
-- 5. Les rattachements
--
-- Ce que `67` a déjà posé est laissé en place : `68` ne défait que SA trace.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_deja_pris;
CREATE TABLE c54_deja_pris AS
SELECT p.insee, p.canton_id, p.atome_final, m.unit_id AS pose_par_ailleurs
FROM   c54_pose p
JOIN   membership m ON m.atom_id = p.atome_final AND m.niveau = 'canton'
                   AND daterange(m.valid_from, m.valid_to, '[)')
                       @> :'jalon_debut'::date;

\echo ''
\echo '-- 5 bis. atomes déjà rattachés par un autre fichier — laissés en place'
SELECT pose_par_ailleurs AS canton, count(*) AS lignes, min(insee) AS un_exemple
FROM   c54_deja_pris GROUP BY 1 ORDER BY lignes DESC LIMIT 10;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atome_final, p.canton_id, 'canton',
           :'jalon_debut'::date, :'jalon_fin'::date
    FROM   c54_pose p
    WHERE  NOT EXISTS (SELECT 1 FROM c54_deja_pris d
                        WHERE d.atome_final = p.atome_final)
    RETURNING membership_id, atom_id
)
INSERT INTO c54_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 5. rattachements posés'
SELECT count(*) AS membership FROM c54_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 6. La qualité, attachée à chaque rattachement
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_qualite;
CREATE TABLE c54_qualite AS
SELECT m.membership_id, p.insee, p.canton_id, p.qualite, p.appariement,
       p.n_atomes, p.est_fraction
FROM   membership m
JOIN   c54_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
JOIN   c54_pose  p ON p.atome_final = m.atom_id;

CREATE INDEX c54_qualite_m_idx ON c54_qualite (membership_id);
CREATE INDEX c54_qualite_q_idx ON c54_qualite (qualite);

\echo ''
\echo '-- 6. ce qui N''A PAS été posé, et pourquoi'
SELECT CASE
         WHEN NOT commune_vivante THEN 'commune inconnue de cm_commune en 1954'
         WHEN atome IS NULL       THEN 'commune vivante mais sans atome'
         WHEN NOT canton_connu    THEN 'canton absent de la nomenclature'
       END                                   AS motif,
       count(*)                              AS lignes,
       count(DISTINCT insee)                 AS communes
FROM   c54_lien
WHERE  NOT (commune_vivante AND atome IS NOT NULL AND canton_connu)
GROUP  BY motif ORDER BY lignes DESC;

\echo ''
\echo '   et les lignes du CSV sans code INSEE, qui n''entrent même pas ici :'
SELECT appariement, count(*) FROM c54_src WHERE insee = ''
GROUP BY appariement ORDER BY count(*) DESC;

-- ---------------------------------------------------------------------------
-- 7. Recette, lue depuis le MODÈLE
--
-- Ce qui est vérifié ici ne doit rien à `c54_pose` : une recette qui relit sa
-- propre source ne vérifie que la copie.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 7. recette'
SELECT
  (SELECT count(DISTINCT m.atom_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'jalon_debut'::date)
                                                       AS atomes_rattaches_1954,
  (SELECT count(DISTINCT m.unit_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'jalon_debut'::date)
                                                       AS cantons_peuples_1954,
  (SELECT count(*) FROM membership m
    WHERE m.niveau = 'canton' AND m.valid_from = :'jalon_debut'::date
      AND m.valid_to = :'jalon_fin'::date)             AS lignes_du_jalon;

\echo ''
\echo '   le jalon n''a-t-il rien débordé ?'
SELECT count(*) AS hors_bornes
FROM   membership m
JOIN   c54_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
WHERE  m.valid_from <> :'jalon_debut'::date OR m.valid_to <> :'jalon_fin'::date;

\echo ''
\echo '   snapshot(1953-12-31) doit rester VIDE — rien en amont du jalon'
SELECT count(DISTINCT m.atom_id) AS atomes_au_31_12_1953
FROM   membership m WHERE m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> '1953-12-31'::date;

\echo ''
\echo '   snapshot(1955-01-01) doit rester VIDE — rien en aval'
SELECT count(DISTINCT m.atom_id) AS atomes_au_01_01_1955
FROM   membership m WHERE m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> '1955-01-01'::date;

\echo ''
\echo '   LE PRIX DE LA BORNE ÉLARGIE : le recensement observe le 10 MAI, la'
\echo '   borne part du 1er JANVIER. Combien de communes posées n''existaient'
\echo '   pas encore au 1er janvier 1954 ?'
SELECT count(*) AS communes_nees_entre_janvier_et_mai
FROM   c54_pose p
WHERE  NOT EXISTS (SELECT 1 FROM cm_commune c
                    WHERE c.code = p.insee
                      AND daterange(c.valid_from, c.valid_to, '[)')
                          @> :'jalon_debut'::date);

\echo ''
\echo '   part de rattachements par qualité :'
SELECT qualite, count(*) AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   c54_qualite GROUP BY qualite ORDER BY n DESC;

\echo ''
\echo '   les deux jalons côte à côte — 1954 et 1968 dans le même trou :'
SELECT '1954' AS jalon,
       count(DISTINCT m.atom_id) AS atomes, count(DISTINCT m.unit_id) AS cantons
FROM   membership m WHERE m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> '1954-06-01'::date
UNION ALL
SELECT '1968',
       count(DISTINCT m.atom_id), count(DISTINCT m.unit_id)
FROM   membership m WHERE m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> '1968-06-01'::date;

\echo ''
\echo '============================================================'
\echo ' Jalon posé sur [1954-01-01, 1955-01-01) et sur cette année SEULE.'
\echo ' Le trou 1943-1999 a maintenant DEUX points au lieu d''un — mais'
\echo ' cinquante-quatre années restent sans aucune source.'
\echo '============================================================'

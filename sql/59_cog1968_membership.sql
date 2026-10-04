-- ============================================================================
-- histgis — 59_cog1968_membership.sql : le jalon de 1968 entre dans le modèle
--
--   psql -d histgis -1 -f sql/59_cog1968_membership.sql
--
-- Premier fichier à poser des rattachements cantonaux DANS le trou 1943-1999.
-- À lancer en une seule transaction : il écrit dans `atom` et `membership`.
--
-- LES BORNES, ET POURQUOI ELLES SONT SI COURTES
-- =============================================
--   [1968-01-01, 1969-01-01)
--
-- Un recensement dit un ÉTAT à une DATE ; il ne dit pas une durée. Étendre ce
-- rattachement jusqu'au COG de 1999 ferait répondre `snapshot` sur trente ans
-- d'un coup — et supposerait une stabilité cantonale que rien n'établit. Le
-- registre cantonal consolidé compte 48 démembrements postérieurs à 1986 ; la
-- composition BOUGE dans l'intervalle.
--
-- L'accord de 88,3 % entre 1968 et 1999 (§ 6 de `58`) ne suffit pas : il tombe
-- à 54 % dans le Val-de-Marne, 57 % dans les Bouches-du-Rhône, 58 % dans les
-- Hauts-de-Seine. Une borne large y poserait des rattachements faux qu'AUCUNE
-- recette interne ne saurait distinguer des vrais — c'est exactement ce que
-- l'affaire de l'Ain a coûté (§ 51), et la raison pour laquelle `24` préfère
-- ne rien renvoyer plutôt qu'un canton faux.
--
-- L'extension, département par département et sur pièces, sera un fichier 60.
--
-- MARQUER PLUTÔT QU'EXCLURE — et les deux cas où c'est impossible
-- ===============================================================
-- Décision du 22 août 2026 : tout ce qui PEUT être posé l'est, avec sa qualité
-- inscrite dans `c68_qualite`. C'est la règle du dépôt — on signale, on ne
-- supprime pas — appliquée au chargement lui-même.
--
-- Deux classes échappent à cette règle pour une raison structurelle, non par
-- prudence :
--
--   * CANTON INCONNU (512 lignes, 361 codes). Un `membership` exige un
--     `unit_id` existant. Les poser demanderait de créer 361 unités cantonales
--     dont la moyenne de citation est 1,4 — c'est-à-dire, en écrasante
--     majorité, des codes mal lus. Marquer reviendrait à inventer des cantons.
--     EXCEPTION NOTABLE : `5740` en Moselle, cité 16 fois autour d'Alsting.
--     Un canton cité seize fois n'est pas une coquille ; il est signalé au § 5
--     pour être tranché sur pièces, pas créé ici.
--
--   * SANS ATOME ou COMMUNE NON VIVANTE (~520 lignes). Il n'y a rien à quoi
--     rattacher.
--
-- Ces deux classes restent entières dans `c68_lien`, et le § 5 les compte.
--
-- LES FRACTIONS CANTONALES
-- ========================
-- `membership_non_chevauchant` interdit à un atome d'appartenir à deux cantons
-- au même instant. Les 275 communes multicantonales (559 lignes) reçoivent
-- donc un atome par canton, `<atome>#<canton>`, marqué `fraction`. C'est le
-- mécanisme de `24` § 4, avec sa limite connue : le territoire sera compté
-- autant de fois qu'il y a de fractions, en attendant ANR-COMMUNES.
--
-- REJOUABLE
-- =========
-- Tout ce qui est écrit est tracé dans `c68_trace`, et la section 1 défait le
-- passage précédent AVANT de juger quoi que ce soit. La leçon de `55` : un
-- fichier qui vérifie que la place est libre avant d'avoir retiré sa propre
-- trace refuse de tourner deux fois.
--
-- Prérequis : sql/58_cog1968_stage.sql (c68_lien).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut '1968-01-01'
\set jalon_fin   '1969-01-01'

\echo ''
\echo '============================================================'
\echo ' COG 1968 — pose du jalon cantonal'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.c68_lien') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/58_cog1968_stage.sql d''abord.';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS c68_trace (
    quoi text NOT NULL,          -- 'membership' | 'atom'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
--
-- L'ordre compte : les membership d'abord (ils référencent les atomes), les
-- atomes ensuite. Et cette section s'exécute même si rien n'a été posé.
-- ---------------------------------------------------------------------------
DELETE FROM membership m
 USING c68_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

DELETE FROM atom a
 USING c68_trace t
 WHERE t.quoi = 'atom' AND t.cle = a.atom_id;

TRUNCATE c68_trace;

\echo ''
\echo '-- 1. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 2. Ce qui est posable, et avec quelle qualité
--
-- La qualité n'est PAS une opinion : chaque valeur correspond à un fait
-- vérifiable, mesuré par `58`.
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- LES CANTONS DÉLÉGUÉS À UN AUTRE FICHIER
--
-- Certains cantons ne viennent pas du recensement seul : ils ont demandé une
-- source publiée et un contrôle commune par commune. `5740` (Forbach-II,
-- D. 8.8.1967 - D. 24.12.1984) est posé par `60_canton_forbach2.sql`, qui
-- confronte ses seize communes à la composition publiée et REFUSE d'écrire si
-- une seule manque.
--
-- POURQUOI UNE LISTE EXPLICITE PLUTÔT QU'UN ORDRE D'EXÉCUTION.
--
-- Le § 3 bis écarte déjà ce qui est physiquement posé. Mais cela ne suffit pas :
-- si `60` n'a pas encore tourné — première installation, ou base reconstruite —
-- `59` pose ces seize communes LUI-MÊME, sans le contrôle des 16/16, et `60`
-- échouera ensuite sur la contrainte. Le résultat dépendrait alors de l'ordre
-- dans lequel on a joué les fichiers, ce qui est précisément ce qu'une chaîne
-- rejouable ne doit pas tolérer.
--
-- La liste ci-dessous est donc la déclaration : *ce canton n'est pas à moi*.
-- Elle vaut quel que soit l'état de la base.
DROP TABLE IF EXISTS c68_delegue;
CREATE TABLE c68_delegue (canton_id text PRIMARY KEY, pose_par text, motif text);
INSERT INTO c68_delegue VALUES
  ('5740', '60_canton_forbach2.sql',
   'Forbach-II : absent de TRF-GIS (1940) et du COG (1999), '
   'composition vérifiée sur source publiée');

\echo ''
\echo '-- 2 ter. cantons délégués à un autre fichier — non posés ici'
SELECT d.canton_id, d.pose_par,
       (SELECT count(*) FROM c68_lien l WHERE l.canton_id = d.canton_id) AS lignes
FROM   c68_delegue d;

\echo ''
\echo '   Si ces lignes ne sont pas en base après la chaîne complète,'
\echo '   c''est que le fichier délégué n''a pas été joué.'

DROP TABLE IF EXISTS c68_pose;
CREATE TABLE c68_pose AS
WITH posable AS (
    SELECT l.*,
           count(*) OVER (PARTITION BY l.insee) AS n_cantons
    FROM   c68_lien l
    WHERE  l.commune_vivante
      AND  l.atome IS NOT NULL
      AND  l.canton_connu
      AND  NOT EXISTS (SELECT 1 FROM c68_delegue d
                        WHERE d.canton_id = l.canton_id)
)
SELECT p.insee,
       p.nom,
       p.dep,
       p.canton_id,
       p.atome                                     AS atome_commune,
       p.n_cantons,
       p.n_atomes,
       p.accord,
       p.canton_autre,
       -- l'atome effectivement rattaché : la commune entière, ou sa fraction
       CASE WHEN p.n_cantons > 1
            THEN p.atome || '#' || p.canton_id
            ELSE p.atome
       END                                         AS atome_final,
       p.n_cantons > 1                             AS est_fraction,
       -- LA QUALITÉ, par ordre de gravité décroissante
       CASE
         WHEN p.n_atomes > 1            THEN 'atome_ambigu'
         WHEN p.accord = 'canton_conteste' THEN 'canton_conteste'
         WHEN p.accord IN ('psm6', 'psm4') THEN 'lecture_unique'
         ELSE 'ferme'
       END                                         AS qualite
FROM   posable p;

CREATE INDEX c68_pose_atome_idx ON c68_pose (atome_final);

\echo ''
\echo '-- 2. ce qui va être posé, par qualité'
SELECT qualite,
       count(*)                                  AS lignes,
       count(DISTINCT insee)                     AS communes,
       count(*) FILTER (WHERE est_fraction)      AS dont_fractions
FROM   c68_pose
GROUP  BY qualite
ORDER  BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 2 bis. LES ATOMES PARTAGÉS PAR PLUSIEURS COMMUNES DE 1968
--
-- `cm_atome` fait passer une commune disparue par son successeur. Deux
-- communes distinctes en 1968, fusionnées depuis, se résolvent donc au MÊME
-- atome — et si leurs cantons diffèrent, `membership_non_chevauchant` refuse
-- le second rattachement.
--
-- Ce n'est ni une erreur de lecture ni un défaut du modèle : c'est la
-- conséquence exacte du choix, posé par `20`, de faire porter la période
-- moderne par un continuum d'atomes 1870-2012. L'atome est la maille du
-- territoire, pas de la personne juridique.
--
-- ON ÉCARTE, ET ON COMPTE. Marquer ne peut pas s'appliquer ici : la contrainte
-- est structurelle, pas prudentielle. Poser l'un des deux au hasard donnerait
-- un canton faux à un territoire, sans trace ; les poser tous deux est
-- interdit par la base elle-même.
--
-- Le remède propre — un atome par commune de 1968 — suppose de découper le
-- territoire de l'atome moderne entre ses composantes de 1968, ce qui demande
-- une géométrie que nous n'avons pas. Même limite, même attente
-- qu'ANR-COMMUNES.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c68_atome_partage;
CREATE TABLE c68_atome_partage AS
SELECT atome_final,
       count(*)                        AS n_lignes,
       count(DISTINCT insee)           AS n_communes,
       count(DISTINCT canton_id)       AS n_cantons,
       string_agg(DISTINCT insee, ',' ORDER BY insee)      AS communes,
       string_agg(DISTINCT canton_id, ',' ORDER BY canton_id) AS cantons
FROM   c68_pose
GROUP  BY atome_final
HAVING count(*) > 1;

\echo ''
\echo '-- 2 bis. atomes visés par plusieurs lignes — écartés, cf. en-tête § 2 bis'
SELECT count(*)               AS atomes_partages,
       sum(n_lignes)          AS lignes_ecartees,
       sum(n_communes)        AS communes_concernees,
       count(*) FILTER (WHERE n_cantons = 1) AS dont_meme_canton
FROM   c68_atome_partage;

\echo ''
\echo '   dix exemples :'
SELECT atome_final, communes, cantons FROM c68_atome_partage
ORDER BY n_lignes DESC, atome_final LIMIT 10;

-- Ceux dont TOUTES les lignes désignent le même canton ne posent aucun
-- problème de fond : une seule ligne suffit à porter l'information, et
-- l'écarter perdrait un rattachement juste. On en garde une.
DELETE FROM c68_pose p
 USING c68_atome_partage x
 WHERE p.atome_final = x.atome_final
   AND x.n_cantons > 1;

-- Ceux dont TOUTES les lignes désignent le même canton ne posent aucun
-- problème de fond : une seule ligne suffit à porter l'information, et
-- l'écarter perdrait un rattachement juste. On en garde une.
--
-- LE TRI PAR `insee` NE SUFFIT PAS. Deux lignes peuvent porter le MÊME code et
-- le même canton — cas produit par `codes_orphelins.py` quand deux lectures
-- orphelines sont corrigées vers la même commune. `min(insee)` ne les
-- départage alors pas, et la contrainte d'exclusion refuse l'insertion sur un
-- message qui ne dit pas laquelle des 30 000 lignes est en cause.
--
-- On déduplique donc sur le COUPLE (atome, canton), par `ctid` — l'identité
-- physique de la ligne, seule chose qui distingue deux doublons exacts.
DELETE FROM c68_pose p
 USING c68_atome_partage x
 WHERE p.atome_final = x.atome_final
   AND x.n_cantons = 1
   AND p.ctid <> (SELECT min(q.ctid) FROM c68_pose q
                   WHERE q.atome_final = x.atome_final);

-- garde-fou : après ce ménage, plus aucun doublon ne doit subsister, sans quoi
-- l'insertion en bloc échouerait sur un message qui ne dirait pas laquelle des
-- 30 000 lignes est en cause.
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atome_final) INTO n, ex
      FROM (SELECT atome_final FROM c68_pose
             GROUP BY atome_final HAVING count(*) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'GARDE-FOU : % atomes finaux encore en double (ex. %).', n, ex;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Les atomes-fraction
--
-- Créés seulement s'ils n'existent pas déjà : `24` a pu en poser pour
-- 1999-2012 sous le même identifiant, et l'atome est alors réutilisé.
-- ---------------------------------------------------------------------------
WITH nouveau AS (
    SELECT DISTINCT p.atome_final, a.cassini, a.com_act, a.insee_geofla
    FROM   c68_pose p
    JOIN   atom a ON a.atom_id = p.atome_commune
    WHERE  p.est_fraction
      AND  NOT EXISTS (SELECT 1 FROM atom x WHERE x.atom_id = p.atome_final)
),
ins AS (
    INSERT INTO atom (atom_id, cassini, fraction, com_act, insee_geofla)
    SELECT atome_final, cassini, true, com_act, insee_geofla FROM nouveau
    RETURNING atom_id
)
INSERT INTO c68_trace (quoi, cle) SELECT 'atom', atom_id FROM ins;

\echo ''
\echo '-- 3. atomes-fraction créés'
SELECT count(*) AS crees FROM c68_trace WHERE quoi = 'atom';

-- ---------------------------------------------------------------------------
-- 4. Les rattachements
-- ---------------------------------------------------------------------------
-- LES ATOMES DÉJÀ RATTACHÉS PAR UN AUTRE FICHIER SONT LAISSÉS EN PLACE.
--
-- `59` défait SA trace (§ 1), jamais celle des autres. Or `60_canton_forbach2`
-- pose seize rattachements sur le canton 5740 et les trace dans `c60_trace`.
--
-- Le piège est circulaire : en CRÉANT l'unité 5740, `60` la rend connue de
-- `unit` — donc `58` cesse de la ranger parmi les cantons inconnus, donc `59`
-- veut poser ces seize communes à son tour, et `membership_non_chevauchant`
-- refuse. **Un fichier qui enrichit la nomenclature change ce que le fichier
-- précédent croit devoir faire**, et l'erreur ne survient qu'au second rejeu de
-- la chaîne, quand tout paraît stable.
--
-- On écarte donc ce qui est déjà posé, et on le compte. Plus sûr qu'un ordre
-- d'exécution imposé : un ordre se perd, un garde-fou reste.
DROP TABLE IF EXISTS c68_deja_pris;
CREATE TABLE c68_deja_pris AS
SELECT p.insee, p.canton_id, p.atome_final, m.unit_id AS pose_par_ailleurs
FROM   c68_pose p
JOIN   membership m ON m.atom_id = p.atome_final AND m.niveau = 'canton'
                   AND daterange(m.valid_from, m.valid_to, '[)')
                       @> :'jalon_debut'::date;

\echo ''
\echo '-- 3 bis. atomes déjà rattachés par un autre fichier — laissés en place'
SELECT pose_par_ailleurs AS canton, count(*) AS lignes, min(insee) AS un_exemple
FROM   c68_deja_pris GROUP BY 1 ORDER BY lignes DESC LIMIT 10;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atome_final, p.canton_id, 'canton',
           :'jalon_debut'::date, :'jalon_fin'::date
    FROM   c68_pose p
    WHERE  NOT EXISTS (SELECT 1 FROM c68_deja_pris d
                        WHERE d.atome_final = p.atome_final)
    RETURNING membership_id, atom_id
)
INSERT INTO c68_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 4. rattachements posés'
SELECT count(*) AS membership FROM c68_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 5. La qualité, attachée à chaque rattachement
--
-- Le modèle n'a pas de colonne de qualité sur `membership`, et lui en ajouter
-- une pour un seul jalon serait payer très cher. Une table à côté suffit, et
-- se lit par jointure.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c68_qualite;
CREATE TABLE c68_qualite AS
SELECT m.membership_id,
       p.insee,
       p.canton_id,
       p.qualite,
       p.accord,
       p.canton_autre,          -- la lecture cantonale écartée, si contestée
       p.n_atomes
FROM   membership m
JOIN   c68_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
JOIN   c68_pose  p ON p.atome_final = m.atom_id;

CREATE INDEX c68_qualite_m_idx ON c68_qualite (membership_id);
CREATE INDEX c68_qualite_q_idx ON c68_qualite (qualite);

\echo ''
\echo '-- 5. ce qui N''A PAS été posé, et pourquoi'
SELECT CASE
         WHEN NOT commune_vivante THEN 'commune inconnue de cm_commune en 1968'
         WHEN atome IS NULL       THEN 'commune vivante mais sans atome'
         WHEN NOT canton_connu    THEN 'canton absent de la nomenclature'
       END                                   AS motif,
       count(*)                              AS lignes,
       count(DISTINCT insee)                 AS communes
FROM   c68_lien
WHERE  NOT (commune_vivante AND atome IS NOT NULL AND canton_connu)
GROUP  BY motif
ORDER  BY lignes DESC;

\echo ''
\echo '   plus les lignes écartées faute d''atome propre (§ 2 bis) :'
SELECT sum(n_lignes) FILTER (WHERE n_cantons > 1) AS cantons_divergents,
       sum(n_lignes - 1) FILTER (WHERE n_cantons = 1) AS doublons_meme_canton
FROM   c68_atome_partage;

\echo ''
\echo '   les cantons inconnus cités 5 fois ou plus — candidats CRÉATION,'
\echo '   à trancher sur pièces et non à créer ici :'
SELECT canton_id, count(*) AS lignes, min(dep) AS dep, min(nom) AS exemple
FROM   c68_lien WHERE NOT canton_connu
GROUP  BY canton_id HAVING count(*) >= 5
ORDER  BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 6. Recette
--
-- Ce qui est vérifié ici ne doit rien à `c68_pose` : on interroge le MODÈLE,
-- pas la table qui a servi à le remplir. Une recette qui relit sa propre
-- source ne vérifie que la copie.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. recette, lue depuis le modèle'
SELECT
  (SELECT count(DISTINCT m.atom_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'jalon_debut'::date)
                                                       AS atomes_rattaches_1968,
  (SELECT count(DISTINCT m.unit_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'jalon_debut'::date)
                                                       AS cantons_peuples_1968,
  (SELECT count(*) FROM membership m
    WHERE m.niveau = 'canton' AND m.valid_from = :'jalon_debut'::date
      AND m.valid_to = :'jalon_fin'::date)             AS lignes_du_jalon;

\echo ''
\echo '   le jalon n''a-t-il rien débordé ? (aucun rattachement hors 1968)'
SELECT count(*) AS hors_bornes
FROM   membership m
JOIN   c68_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
WHERE  m.valid_from <> :'jalon_debut'::date OR m.valid_to <> :'jalon_fin'::date;

\echo ''
\echo '   snapshot(1967-12-31) doit rester VIDE : le jalon ne déborde pas en amont'
SELECT count(DISTINCT m.atom_id) AS atomes_au_31_12_1967
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> '1967-12-31'::date;

\echo ''
\echo '   part de rattachements de qualité `ferme` :'
SELECT qualite, count(*) AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   c68_qualite GROUP BY qualite ORDER BY n DESC;

\echo ''
\echo '   les cantons délégués sont-ils en base ? (sinon, le fichier manque)'
SELECT d.canton_id, d.pose_par,
       (SELECT count(*) FROM membership m
         WHERE m.unit_id = d.canton_id AND m.niveau = 'canton'
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> :'jalon_debut'::date)                     AS en_base,
       (SELECT count(*) FROM c68_lien l
         WHERE l.canton_id = d.canton_id
           AND l.commune_vivante AND l.atome IS NOT NULL)   AS attendu
FROM   c68_delegue d;

\echo ''
\echo '   `en_base` à 0 signifie que le fichier délégué n''a pas été joué :'
\echo '   ces communes sont alors ABSENTES du jalon, et non mal rattachées.'

\echo ''
\echo '============================================================'
\echo ' Jalon posé sur [1968-01-01, 1969-01-01) et sur cette année SEULE.'
\echo ' Toute extension est une décision distincte, à prendre sur pièces,'
\echo ' département par département — ce sera 60.'
\echo '============================================================'

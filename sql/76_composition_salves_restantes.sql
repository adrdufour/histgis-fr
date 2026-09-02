-- ============================================================================
-- histgis — 76_composition_salves_restantes.sql : la longue traîne des actes
--
--   psql -d histgis -1 -f sql/76_composition_salves_restantes.sql
--   (après `75`, dont il reprend la convention)
--
-- CE QU'IL POSE
-- =============
-- Les compositions de toutes les salves que `75` n'a pas prises : 1961, 1970,
-- 1974-1976, 1984, 1985, 1988, 1991-1997. Environ 1 240 lignes sur 383 cantons.
-- Chaque année compte peu ; l'ensemble compte.
--
-- La liste des salves est définie EN CREUX — les années des actes posables,
-- moins celles de `75`, moins 1967 — et non écrite à la main. Un décret qui
-- entrerait demain au registre tomberait donc dans `76` sans qu'on y pense.
-- Le 28 août au matin, 207 y sont entrés d'un coup.
--
-- JUMEAU DE `75`, ET LA PARENTÉ S'ARRÊTE À UN ENDROIT PRÉCIS
-- ==========================================================
-- La mécanique est la même, section par section, et les numéros de section
-- SUIVENT CEUX DE `75` pour que les deux fichiers se lisent en regard. Il n'y
-- a pas de § 2 ici, et c'est tout le propos :
--
--     `scrutin_cantonal` et `acte_effet` ne sont PAS reconstruites.
--     La convention de date d'effet n'existe qu'à un seul endroit.
--
-- C'est la seule chose qu'il fallait absolument ne pas dupliquer. Deux
-- fichiers qui définiraient chacun leur convention finiraient par diverger, et
-- le jour où ils divergeraient **rien ne le dirait** : chacun rendrait des
-- chiffres cohérents, et la base porterait deux règles sous un seul nom.
--
-- La duplication de la mécanique, elle, est assumée. Elle a un coût — un
-- correctif porté à `75` doit être reporté ici — et le § 10 f le rend
-- vérifiable : il compte ce que les deux fichiers couvrent ensemble.
--
-- 1967 EST EXCLU, ET CE N'EST PAS UN OUBLI
-- ========================================
-- Les six décrets du 20 juillet 1967 prennent effet à la naissance des
-- départements d'Île-de-France, le 1er janvier 1968 — un fait juridique, pas
-- le scrutin suivant. La convention y serait fausse de deux mois et demi, et
-- ces cantons sont déjà en base par deux voies exactes : le recensement de
-- 1968 (`58` + `59`) pour cinq départements, `74` pour les Yvelines dont le
-- fascicule manque. `73` a mesuré leur accord : 45 accords, 0 désaccord.
--
-- *Une convention ne s'applique pas là où un fait est disponible.*
--
-- LA CONVENTION COÛTE BEAUCOUP PLUS CHER ICI QUE DANS `75` — MESURÉ
-- =================================================================
-- C'est le fait le plus important de ce fichier, et il n'était pas prévu.
--
-- L'incertitude de série ne pèse que sur les cantons MODIFIÉS : un canton créé
-- entre en vigueur au scrutin qui l'élit. Or la part des actes de création
-- pure s'effondre avec le temps :
--
--     1967            764 lignes — « creation de cantons » 100,0 %
--     1973 / 1982   2 988 lignes — « creation de cantons »  63,8 %
--     le reste        987 lignes — « creation de cantons »   9,1 %
--
-- Conséquence mesurée sur la vraie base : `75` pose 37,0 % de ses
-- rattachements avec un décalage possible de trois ans ; **`76` en pose
-- 93,7 %**.
--
-- Autrement dit : la couverture que ce fichier ajoute est RÉELLE mais
-- nettement plus MOLLE que celle de `75`. Les années 1985-1998 reposent
-- presque entièrement sur une convention, là où 1973 et 1982 reposaient pour
-- près des deux tiers sur des créations dont la date se déduit d'elle-même.
--
-- Cela ne condamne pas la pose — `p76_qualite` le porte ligne à ligne, et une
-- incertitude déclarée vaut mieux qu'un trou muet. Mais **toute lecture des
-- cantons entre 1985 et 1998 doit joindre `p76_qualite`**, faute de quoi elle
-- prendra une convention pour un fait.
--
-- CE QUE LA CONVENTION COÛTE — rappel, car il vaut ici aussi
-- ==========================================================
--     valid_from = premier tour du renouvellement des conseils généraux
--                  qui suit la signature
--
-- Les conseils généraux se renouvelaient par MOITIÉ : « le prochain
-- renouvellement » d'un canton dépend de sa série, que nous n'avons pas. Pour
-- un canton créé la question ne se pose guère ; pour un canton modifié, le
-- décalage possible est de trois ans. `p76_qualite` porte `serie_inconnue` et
-- `decalage_max_annees` ligne à ligne, comme `p75_qualite`.
--
-- La borne haute reste la date d'effet du premier acte postérieur du même
-- département, plafonnée à 1999-01-01 où `24` reprend la main.
--
-- CE QUI SE JOUE ICI ET PAS DANS `75`
-- ===================================
-- Les salves tardives — 1984, 1985, 1991, 1997 — sont proches de 1999. La
-- résolution des cantons contre la nomenclature de 1999 devrait donc y être
-- MEILLEURE que pour 1973, puisque moins d'actes s'intercalent. Le § 11 de
-- `75` mesurait 63,6 % de résolution sans acte intercalé contre 50,8 % au-delà
-- de trois : si ce fichier rend un taux nettement supérieur, l'explication
-- tient, et elle vaut rétrospectivement pour `75`.
--
-- REJOUABLE
-- =========
-- Tout ce qui est écrit est tracé dans `p76_trace`, et le § 3 défait le
-- passage précédent AVANT de juger quoi que ce soit.
--
-- Prérequis : `72_registre_actes.sql`, `24_canton_moderne.sql`,
--             `75_composition_1973_1982.sql` (pour la convention).
--             (`58` + `59` seulement pour le diagnostic du § 8.)
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ATTENTION : `\set` prend TOUTE la fin de la ligne, commentaire compris.
-- Un `-- …` après la valeur entre dans la variable et casse le premier cast.
-- Les commentaires vont donc au-dessus, jamais à côté.
--
-- fin_serie : la date où `24_canton_moderne.sql` reprend la main.
\set fin_serie   '1999-01-01'
\set jalon_1999  '1999-06-01'
\set jalon_1968  '1968-06-01'
-- mini  : communes entières minimales pour qu'un canton soit jugeable
-- seuil : part de la liste du décret retrouvée en 1999 pour conclure
\set mini        3
\set seuil       0.8

\echo ''
\echo '============================================================'
\echo ' LES SALVES RESTANTES — même convention, même mécanique'
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
                    WHERE niveau = 'canton' AND periode @> DATE '1999-06-01') THEN
        RAISE EXCEPTION
          'PRÉREQUIS : les cantons de 1999 ne sont pas en base (sql/24). '
          'Sans eux, aucun canton du décret ne peut être identifié.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. LA CONVENTION N'EST PAS REDÉFINIE ICI
--
-- `scrutin_cantonal` et `acte_effet` sont posées par `75`, et ce fichier les
-- REPREND telles quelles. C'est le seul point qui compte dans la parenté des
-- deux fichiers : la mécanique de pose est jumelle, mais **la convention de
-- date d'effet n'existe qu'à un seul endroit**. Une convention qui se
-- recopierait finirait par diverger, et le jour où elle divergerait rien ne le
-- dirait — les deux fichiers rendraient des chiffres cohérents et faux.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_effet') IS NULL
       OR to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION
          'PRÉREQUIS : `scrutin_cantonal` et `acte_effet` sont posées par '
          'sql/75_composition_1973_1982.sql. Le jouer d''abord.';
    END IF;
END $$;

\echo ''
\echo '-- 1. convention reprise de `75`'
SELECT (SELECT count(*) FROM scrutin_cantonal)                        AS scrutins,
       (SELECT count(*) FROM acte_effet WHERE statut = 'posable')     AS actes_posables,
       (SELECT count(*) FROM acte_effet WHERE statut <> 'posable')    AS actes_ecartes;

-- ---------------------------------------------------------------------------
-- 3. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p76_trace (
    quoi text NOT NULL,          -- 'membership'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p76_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p76_trace;

\echo ''
\echo '-- 3. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 4. Les salves traitées ici : TOUT LE RESTE
--
-- 1961, 1970, 1974-1976, 1984, 1985, 1988, 1991-1997 — environ 1 240 lignes
-- de composition sur 383 cantons. `75` a pris les deux grosses salves ; celle-ci
-- prend la longue traîne, où chaque année compte peu et où l'ensemble compte.
--
-- 1967 EST EXCLU, ET CE N'EST PAS UN OUBLI
-- ========================================
-- Les six décrets du 20 juillet 1967 créent les cantons de l'Essonne, des
-- Hauts-de-Seine, de la Seine-Saint-Denis, du Val-de-Marne, du Val-d'Oise et
-- des Yvelines, **avec effet à la naissance de ces départements le 1er janvier
-- 1968**. Leur date d'effet est un fait juridique, pas le scrutin suivant : la
-- convention de ce fichier y serait fausse, et de deux mois et demi.
--
-- Ils sont déjà en base par deux voies exactes :
--   * le recensement de 1968 (`58` + `59`) pour cinq de ces départements ;
--   * `74` pour les Yvelines, dont le fascicule manque, sur la date du décret.
--
-- Et `73` a mesuré l'accord des deux : 45 accords, 0 désaccord.
--
-- *Une convention ne s'applique pas là où un fait est disponible.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p76_salve;
CREATE TABLE p76_salve (annee smallint PRIMARY KEY);

-- Tout ce qui reste, défini EN CREUX plutôt qu'en dur : les années des actes
-- posables, moins celles que `75` a déjà posées, moins 1967.
--
-- Le creux n'est pas une élégance, c'est une garantie. Une liste écrite à la
-- main se serait désynchronisée le jour où un décret de plus entrerait au
-- registre — et il en est entré 207 le 28 août au matin. Ici, un acte nouveau
-- tombe automatiquement dans `76` s'il n'est pas dans `75`.
INSERT INTO p76_salve (annee)
SELECT DISTINCT extract(year FROM c.date_acte)::smallint
FROM   acte_effet e
JOIN   acte_cantonal a ON a.legifrance_id = e.legifrance_id
JOIN   acte_composition c ON c.url = a.url
WHERE  e.statut = 'posable'
  AND  extract(year FROM c.date_acte)::smallint NOT IN (1973, 1982, 1967);

-- `canton_norme` : la même graphie pour un même canton. Le banc a montré
-- « Saint-Quentin - Sud » et « Saint-Quentin-Sud » traités comme deux cantons
-- rivaux, puis refusés tous les deux pour collision — un canton perdu par une
-- espace. La normalisation ne fait QUE cela : elle uniformise les espaces
-- autour des traits d'union et la casse. Elle ne rapproche pas deux noms
-- voisins, et n'a donc rien de commun avec l'appariement par le nom que le
-- dépôt s'interdit : deux noms qui ne diffèrent que par une espace ne sont
-- pas deux noms.
DROP TABLE IF EXISTS p76_dit;
CREATE TABLE p76_dit AS
SELECT c.url,
       e.dep                              AS dep_acte,
       c.canton,
       lower(trim(regexp_replace(regexp_replace(c.canton, '\s*-\s*', '-', 'g'),
                                 '\s+', ' ', 'g')))  AS canton_norme,
       c.atome,
       e.date_effet                       AS valid_from,
       e.date_fin                         AS valid_to,
       e.objet,
       c.provenance
FROM   acte_composition c
JOIN   acte_cantonal   a ON a.url = c.url
JOIN   acte_effet      e ON e.legifrance_id = a.legifrance_id
WHERE  extract(year FROM c.date_acte)::smallint IN (SELECT annee FROM p76_salve)
  AND  e.statut = 'posable'
  AND  c.atome IS NOT NULL
GROUP  BY 1,2,3,4,5,6,7,8,9;   -- une commune peut être citée deux fois par un décret

CREATE INDEX p76_dit_idx ON p76_dit (dep_acte, canton);

\echo ''
\echo '-- 4. ce qui est donné à poser'
SELECT extract(year FROM valid_from) AS scrutin,
       count(*)                             AS lignes,
       count(DISTINCT (dep_acte, canton))   AS cantons,
       count(DISTINCT dep_acte)             AS departements,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   p76_dit GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   lignes des salves ÉCARTÉES avant tout jugement, et pourquoi'
SELECT CASE
         WHEN c.atome IS NULL THEN 'a - pas d''atome (fraction de ville, ou nom non apparié)'
         ELSE 'b - acte non posable : ' || e.statut
       END                                  AS motif,
       count(*)                             AS lignes
FROM   acte_composition c
JOIN   acte_cantonal   a ON a.url = c.url
JOIN   acte_effet      e ON e.legifrance_id = a.legifrance_id
WHERE  extract(year FROM c.date_acte)::smallint IN (SELECT annee FROM p76_salve)
  AND  (c.atome IS NULL OR e.statut <> 'posable')
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. Résolution : quel canton de 1999 porte chaque canton du décret ?
--
-- Le vote se fait sur les atomes, sans restriction de département, PUIS la
-- compatibilité de département est vérifiée. L'ordre compte : restreindre
-- d'abord écarterait la Corse de 1973 (`20` contre `2A`/`2B`) en silence,
-- et un filtre qui écarte en silence est le défaut le plus cher du dépôt.
-- ---------------------------------------------------------------------------
-- LE VOTE SE COMPTE SUR DES COMMUNES DISTINCTES, PAS SUR DES LIGNES. Une
-- commune citée par deux décrets de la même salve — ou lue à la fois par le
-- JO et par Légifrance — apparaît deux fois dans `p76_dit`. Comptée deux
-- fois, elle donnait au banc un taux de 333 % pour Aureilhan : un canton de
-- trois communes qui en « retrouvait » dix. Un taux supérieur à 100 % n'est
-- pas un bon score, c'est un défaut de dénombrement.
DROP TABLE IF EXISTS p76_uniq;
CREATE TABLE p76_uniq AS
SELECT DISTINCT dep_acte, canton_norme, atome, valid_from, valid_to
FROM   p76_dit;
CREATE INDEX p76_uniq_idx ON p76_uniq (dep_acte, canton_norme);

DROP TABLE IF EXISTS p76_lien;
CREATE TABLE p76_lien AS
WITH taille AS (
    SELECT dep_acte, canton_norme, valid_from, valid_to, count(*) AS communes
    FROM   p76_uniq GROUP BY 1,2,3,4
),
graphies AS (
    SELECT dep_acte, canton_norme,
           string_agg(DISTINCT canton, ' | ' ORDER BY canton) AS cantons_lus
    FROM   p76_dit GROUP BY 1,2
),
base99 AS (
    SELECT split_part(m.atom_id, '#', 1) AS atome, m.unit_id, u.dep
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
    WHERE  m.niveau = 'canton'
      AND  m.periode @> :'jalon_1999'::date
    GROUP  BY 1,2,3
),
-- LE VOTE SE COMPTE PAR PÉRIODE, PAS PAR CANTON. Un canton peut être cité par
-- les DEUX salves : il a alors deux lignes dans `taille`, une par période,
-- mais un vote agrégé sans la période additionnait les deux et rendait un taux
-- de 367 % pour Aureilhan — trois communes qui en « retrouvaient » onze. Même
-- symptôme que le comptage sur les lignes corrigé plus haut, autre cause :
-- ici, ce n'est pas la commune qui était comptée deux fois, c'est la DATE qui
-- avait disparu de la clé. Le § 5 ter refuse désormais tout taux > 100 %.
votes AS (
    SELECT d.dep_acte, d.canton_norme, d.valid_from, d.valid_to,
           b.unit_id, b.dep AS dep_1999, count(*) AS n
    FROM   p76_uniq d JOIN base99 b ON b.atome = d.atome
    GROUP  BY 1,2,3,4,5,6
),
meilleur AS (
    SELECT DISTINCT ON (dep_acte, canton_norme, valid_from, valid_to)
           dep_acte, canton_norme, valid_from, valid_to, unit_id, dep_1999, n
    FROM   votes
    ORDER  BY dep_acte, canton_norme, valid_from, valid_to, n DESC, unit_id
)
SELECT t.dep_acte, t.canton_norme, g.cantons_lus,
       t.valid_from, t.valid_to, t.communes,
       m.unit_id, m.dep_1999, coalesce(m.n, 0) AS partagees,
       CASE WHEN t.communes > 0
            THEN round(100.0 * coalesce(m.n, 0) / t.communes, 0) END AS taux,
       -- normalisation Corse : reprise telle quelle de `75`. Elle ne sert pas
       -- ici (aucun acte corse dans ces salves), et elle reste — une règle
       -- retirée parce qu'elle ne sert pas aujourd'hui est une règle qui
       -- manquera le jour où un décret corse entrera au registre.
       (CASE WHEN t.dep_acte  IN ('20','2A','2B') THEN 'CORSE' ELSE t.dep_acte  END)
     = (CASE WHEN m.dep_1999  IN ('20','2A','2B') THEN 'CORSE' ELSE m.dep_1999  END)
                                                                     AS dep_compatible,
       NULL::text AS verdict
FROM   taille t
LEFT   JOIN meilleur m USING (dep_acte, canton_norme, valid_from, valid_to)
LEFT   JOIN graphies g USING (dep_acte, canton_norme);

UPDATE p76_lien SET verdict = CASE
    WHEN communes < :mini                        THEN 'trop court'
    WHEN unit_id IS NULL                         THEN 'aucun canton de 1999 en commun'
    WHEN dep_compatible IS NOT TRUE              THEN 'département incompatible'
    WHEN partagees::numeric / communes >= :seuil THEN 'resolu'
    WHEN partagees::numeric / communes >= 0.5    THEN 'accord partiel'
    ELSE                                              'desaccord'
END;

-- Deux cantons du décret résolus vers la MÊME unité sur la MÊME période :
-- la résolution n'est plus injective, donc elle n'identifie plus rien. On
-- refuse les deux plutôt que d'en choisir un.
UPDATE p76_lien l SET verdict = 'collision'
 WHERE l.verdict = 'resolu'
   AND EXISTS (SELECT 1 FROM p76_lien k
                WHERE k.verdict = 'resolu'
                  AND k.unit_id = l.unit_id
                  AND k.valid_from = l.valid_from AND k.valid_to = l.valid_to
                  AND (k.dep_acte, k.canton_norme)
                      IS DISTINCT FROM (l.dep_acte, l.canton_norme));

CREATE INDEX p76_lien_idx ON p76_lien (dep_acte, canton_norme);

-- ---------------------------------------------------------------------------
-- 5 ter. LA BORNE DU TAUX — garde-fou, et non recette
--
-- `partagees` est un sous-ensemble de `communes` : le taux ne PEUT pas
-- dépasser 100 %. Il l'a fait deux fois, pour deux causes différentes — les
-- lignes comptées au lieu des communes, puis la période absente de la clé du
-- vote. Les deux fois, le résultat était cohérent et faux, et les deux fois le
-- dépassement était le seul signe visible.
--
-- Un dépassement fausse le seuil de 80 % DANS LE SENS PERMISSIF : il fait
-- passer des cantons que la règle aurait dû refuser. C'est la seule direction
-- où plus rien ne le signale ensuite. D'où un refus total, et non un tri.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5 ter. taux supérieurs à 100 % (doit valoir 0 — la part ne peut pas'
\echo '   dépasser son tout ; si elle le fait, c''est le dénombrement qui ment)'
SELECT count(*) AS taux_impossibles FROM p76_lien WHERE taux > 100;

DO $$
DECLARE n integer; ex text;
BEGIN
    SELECT count(*), min(cantons_lus) INTO n, ex FROM p76_lien WHERE taux > 100;
    IF n > 0 THEN
        RAISE EXCEPTION
          'REFUS : % canton(s) au taux supérieur à 100 %% (p. ex. %). '
          'Le dénombrement est faux, pas le score. Rien n''est posé.', n, ex;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 5 bis. LES COMMUNES DISPUTÉES — une contradiction dans la source
--
-- Une commune citée par DEUX cantons résolus sur la même période. Le modèle
-- l'interdit (`membership_non_chevauchant`), et il a raison : une commune
-- n'appartient qu'à un canton.
--
-- Trouvé au banc d'essai, sur les vraies compositions : 14163 est donnée à la
-- fois à Ouistreham-Riva-Bella et à Troarn par la salve de 1982. Ce peut être
-- une erreur d'OCR, une commune réellement partagée, ou deux décrets de la
-- même salve qui se succèdent sans que la lecture ait vu l'ordre.
--
-- ON ÉCARTE LA COMMUNE, PAS LES DEUX CANTONS. La contradiction porte sur
-- cette ligne-là ; les autres communes des deux cantons ne sont contestées
-- par personne. C'est le traitement que `59` réserve à ses 460
-- `atome_ambigu`, et le refus en bloc serait ici une punition collective.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p76_atome_dispute;
CREATE TABLE p76_atome_dispute AS
SELECT d.atome, d.valid_from, d.valid_to,
       min(d.dep_acte)                               AS dep_acte,
       count(DISTINCT (d.dep_acte, d.canton_norme))  AS n_cantons,
       string_agg(DISTINCT l.cantons_lus, ' | ' ORDER BY l.cantons_lus) AS cantons
FROM   p76_uniq d
JOIN   p76_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
WHERE  l.verdict = 'resolu'
GROUP  BY d.atome, d.valid_from, d.valid_to
HAVING count(DISTINCT l.unit_id) > 1;

\echo ''
\echo '-- 5 bis. communes réclamées par deux cantons sur la même période'
SELECT atome, dep_acte, n_cantons, cantons, valid_from
FROM   p76_atome_dispute ORDER BY dep_acte, atome;

\echo ''
\echo '   Elles ne sont pas posées, et les cantons qui les citent le sont'
\echo '   quand même : la contradiction porte sur la commune, pas sur eux.'

\echo ''
\echo '-- 5. résolution des cantons du décret vers la nomenclature'
SELECT verdict, count(*) AS cantons, sum(communes) AS communes
FROM   p76_lien GROUP BY verdict ORDER BY cantons DESC;

\echo ''
\echo '   le piège de la Corse (0 ligne attendue ici : aucun acte corse dans'
\echo '   ces salves — le recodage de 1976 concernait `75`, pas `76`)'
SELECT dep_acte, count(*) AS cantons,
       count(*) FILTER (WHERE verdict = 'resolu') AS resolus,
       min(dep_1999) AS dep_1999_min, max(dep_1999) AS dep_1999_max
FROM   p76_lien WHERE dep_acte IN ('20','2A','2B')
GROUP  BY dep_acte ORDER BY dep_acte;

-- ---------------------------------------------------------------------------
-- 6. Ce qui va être posé — et les deux garde-fous d'écriture
-- ---------------------------------------------------------------------------
-- UN RATTACHEMENT, PAS UNE LIGNE DE LECTURE. Le regroupement n'est pas
-- cosmétique : une même commune est souvent citée deux fois pour le même
-- canton — par deux décrets d'une même salve, ou par les deux extractions
-- (le JO OCRisé et Légifrance) qui se recouvrent sur 283 cantons. Sans lui,
-- l'insertion pose deux lignes identiques et `membership_non_chevauchant`
-- refuse la seconde, au milieu de l'écriture. Trouvé au banc d'essai sur
-- 02089, et c'est la deuxième fois que le dépôt paie ce défaut : `42` avait
-- déjà cru dédoublonner avec un `>` là où il fallait grouper.
DROP TABLE IF EXISTS p76_pose;
CREATE TABLE p76_pose AS
SELECT d.atome,
       l.unit_id,
       d.valid_from,
       d.valid_to,
       min(d.dep_acte)                                   AS dep_acte,
       string_agg(DISTINCT d.canton, ' | ')              AS canton,
       min(l.taux)                                       AS taux,
       min(l.communes)                                   AS communes,
       string_agg(DISTINCT d.provenance, '+')            AS provenance,
       count(DISTINCT d.url)                             AS n_actes,
       -- un seul acte de création suffit à lever l'incertitude de série
       bool_and(d.objet <> 'creation de cantons')        AS serie_inconnue
FROM   p76_dit d
JOIN   p76_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
WHERE  l.verdict = 'resolu'
  AND  NOT EXISTS (SELECT 1 FROM p76_atome_dispute x
                    WHERE x.atome = d.atome AND x.valid_from = d.valid_from)
  AND  NOT EXISTS (
         SELECT 1 FROM membership m
          WHERE m.atom_id = d.atome AND m.niveau = 'canton'
            AND m.periode && daterange(d.valid_from, d.valid_to, '[)'))
GROUP  BY d.atome, l.unit_id, d.valid_from, d.valid_to;

\echo ''
\echo '-- 6. à poser'
SELECT count(*)                AS rattachements,
       count(DISTINCT unit_id) AS cantons,
       count(DISTINCT atome)   AS atomes
FROM   p76_pose;

\echo ''
\echo '   atomes écartés parce que la place n''était pas libre'
\echo '   (attendu ici : ce que `75` a posé pour 1973 ou 1982 et qui court'
\echo '    encore, et la ligne unique de `38_decret_1982_ain.sql`. Un occupant'
\echo '    qui ne serait ni l''un ni l''autre est à regarder.)'
SELECT m.unit_id AS occupe_par, count(*) AS lignes, min(d.atome) AS un_exemple
FROM   p76_uniq d
JOIN   p76_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
JOIN   membership m ON m.atom_id = d.atome AND m.niveau = 'canton'
                   AND m.periode && daterange(d.valid_from, d.valid_to, '[)')
WHERE  l.verdict = 'resolu'
GROUP  BY 1 ORDER BY lignes DESC LIMIT 10;

-- GARDE-FOU 1 : après le retrait des communes disputées, plus aucun atome ne
-- doit être réclamé deux fois sur des périodes qui se recouvrent.
-- `membership_non_chevauchant` lèverait l'erreur au milieu de l'écriture ; on
-- préfère refuser AVANT, en bloc, et savoir pourquoi.
--
-- Le § 5 bis retire les conflits ATTENDUS (deux cantons du décret). Ce qui
-- resterait ici serait d'une autre nature — un atome porté par deux lignes de
-- périodes différentes mais sécantes, donc un défaut de la convention de
-- bornes elle-même. C'est pour cela que le refus est ici total et non ligne à
-- ligne : si la convention se contredit, rien de ce qu'elle produit ne vaut.
\echo ''
\echo '   atomes réclamés par deux cantons sur des périodes qui se recouvrent'
\echo '   (doit valoir 0 après le § 5 bis — sinon la CONVENTION se contredit) :'
SELECT count(*) AS conflits
FROM   p76_pose a JOIN p76_pose b
       ON a.atome = b.atome
      AND (a.unit_id, a.valid_from, a.valid_to)
        < (b.unit_id, b.valid_from, b.valid_to)
      AND daterange(a.valid_from, a.valid_to, '[)')
       && daterange(b.valid_from, b.valid_to, '[)');

DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
      FROM p76_pose a JOIN p76_pose b
           ON a.atome = b.atome
          AND (a.unit_id, a.valid_from, a.valid_to)
            < (b.unit_id, b.valid_from, b.valid_to)
          AND daterange(a.valid_from, a.valid_to, '[)')
           && daterange(b.valid_from, b.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION
          'REFUS : % conflit(s) d''atome entre deux cantons. Rien n''est posé.', n;
    END IF;
END $$;

-- GARDE-FOU 2 : l'ordre de grandeur des communes disputées. Une poignée est
-- un bruit de lecture ; plusieurs dizaines diraient que la salve n'est pas
-- lue comme un ensemble ordonné, et le retrait ligne à ligne masquerait le
-- défaut au lieu de le montrer. Seuil posé avant la mesure, à 50.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM p76_atome_dispute;
    IF n > 50 THEN
        RAISE EXCEPTION
          'REFUS : % communes réclamées par deux cantons. Ce n''est plus du '
          'bruit de lecture — la salve est à relire avant d''être posée.', n;
    END IF;
END $$;

-- GARDE-FOU 3 : l'ordre de grandeur. Leçon de `42`, où trois requêtes bien
-- formées et absurdes n'ont été démasquées que par le nombre de lignes
-- qu'elles rendaient. Ces salves portent environ 1 240 lignes de composition ;
-- au-delà de 3 000 rattachements, la sélection a dérivé.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM p76_pose;
    IF n > 3000 THEN
        RAISE EXCEPTION
          'REFUS : % rattachements à poser, très au-delà des ~1 240 lignes de '
          'composition de ces salves. La sélection a dérivé.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. La pose, et la qualité attachée à chaque rattachement
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atome, unit_id, 'canton', valid_from, valid_to
    FROM   p76_pose
    RETURNING membership_id
)
INSERT INTO p76_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

DROP TABLE IF EXISTS p76_qualite;
CREATE TABLE p76_qualite AS
-- Un canton CRÉÉ entre en vigueur au scrutin qui l'élit : la série ne se pose
-- pas. Un canton MODIFIÉ dépend de la série de son département, que nous
-- n'avons pas. L'objet de l'acte est le seul discriminant disponible, et il
-- ne tranche que dans un sens — d'où `serie_inconnue` calculé au § 6.
SELECT m.membership_id,
       p.dep_acte,
       p.canton                              AS canton_decret,
       p.unit_id,
       p.taux,
       p.communes,
       p.provenance,                          -- 'jo' (OCR), 'legifrance', ou les deux
       p.n_actes,
       'scrutin_suivant'::text                AS convention,
       p.serie_inconnue,
       CASE WHEN p.serie_inconnue THEN 3 ELSE 0 END
                                              AS decalage_max_annees,
       (SELECT min(e.borne_haute_source) FROM acte_effet e
         WHERE e.dep = p.dep_acte AND e.date_effet = p.valid_from)
                                              AS borne_haute_source
FROM   membership m
JOIN   p76_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
JOIN   p76_pose  p ON p.atome = m.atom_id AND p.unit_id = m.unit_id
                  AND p.valid_from = m.valid_from;

CREATE INDEX p76_qualite_m_idx ON p76_qualite (membership_id);
CREATE INDEX p76_qualite_s_idx ON p76_qualite (serie_inconnue);

ANALYZE membership;
ANALYZE p76_qualite;

\echo ''
\echo '-- 7. posé'
SELECT count(*) AS rattachements FROM p76_trace WHERE quoi = 'membership';

\echo ''
\echo '   LA LIGNE À LIRE AVANT TOUTE AUTRE : la part des rattachements dont'
\echo '   la date de début peut être fausse de trois ans, faute de connaître'
\echo '   la série de renouvellement du département.'
\echo '   ATTENDU ICI : environ 94 %, contre 37 % dans `75`. Ces salves sont'
\echo '   faites de MODIFICATIONS et non de créations (9,1 % de « creation de'
\echo '   cantons » contre 63,8 %), et un canton modifié ne dit pas sa date.'
\echo '   La couverture ajoutée est réelle, et molle. Elle se lit avec'
\echo '   p76_qualite, jamais sans.'
SELECT serie_inconnue, decalage_max_annees, count(*) AS rattachements,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   p76_qualite GROUP BY 1,2 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 8. DIAGNOSTIC — ce que le jalon de 1968 dit des cantons résolus
--
-- Ce n'est PAS une recette : 1968 n'a pas servi à résoudre, et un désaccord
-- ici n'accuse personne. Il se lit à l'envers — un canton du décret dont la
-- meilleure correspondance en 1968 n'est pas celle de 1999 est très
-- probablement un canton CRÉÉ ou REDÉCOUPÉ par l'acte, c'est-à-dire
-- exactement ce que l'acte dit faire.
--
-- L'information utile est l'inverse : les cantons dont 1968 et 1999 désignent
-- la MÊME unité sont ceux dont l'identité est établie par deux sources qui
-- n'ont rien en commun — un décret OCRisé du JO et un recensement OCRisé.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p76_diag_1968;
CREATE TABLE p76_diag_1968 AS
WITH base68 AS (
    SELECT split_part(m.atom_id, '#', 1) AS atome, m.unit_id
    FROM   membership m
    WHERE  m.niveau = 'canton' AND m.periode @> :'jalon_1968'::date
    GROUP  BY 1,2
),
votes AS (
    SELECT d.dep_acte, d.canton_norme, d.valid_from, d.valid_to,
           b.unit_id, count(*) AS n
    FROM   p76_uniq d JOIN base68 b ON b.atome = d.atome
    GROUP  BY 1,2,3,4,5
),
meilleur AS (
    SELECT DISTINCT ON (dep_acte, canton_norme, valid_from, valid_to)
           dep_acte, canton_norme, valid_from, valid_to, unit_id, n
    FROM   votes
    ORDER  BY dep_acte, canton_norme, valid_from, valid_to, n DESC, unit_id
)
SELECT l.dep_acte, l.cantons_lus, l.valid_from, l.communes,
       l.unit_id AS unit_1999,
       m.unit_id AS unit_1968, coalesce(m.n, 0) AS partagees_1968
FROM   p76_lien l
LEFT   JOIN meilleur m USING (dep_acte, canton_norme, valid_from, valid_to)
WHERE  l.verdict = 'resolu';

\echo ''
\echo '-- 8. diagnostic : 1968 désigne-t-il la même unité que 1999 ?'
SELECT CASE
         WHEN unit_1968 IS NULL          THEN 'c - aucune commune retrouvée en 1968 (fascicule manquant, ou rappel de l''OCR)'
         WHEN unit_1968 = unit_1999      THEN 'a - même unité : identité confirmée par deux sources sans lien'
         ELSE                                 'b - unité différente : signature attendue d''une création ou d''un redécoupage'
       END      AS lecture,
       count(*) AS cantons
FROM   p76_diag_1968 GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 9. Ce qui n'a PAS été posé, et pourquoi
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 9. refusés, par motif'
SELECT verdict, count(*) AS cantons, sum(communes) AS communes
FROM   p76_lien WHERE verdict <> 'resolu'
GROUP  BY verdict ORDER BY cantons DESC;

\echo ''
\echo '   les désaccords et les collisions, en clair — ce sont les seuls'
\echo '   refus qui accusent une LECTURE plutôt qu''une nomenclature disparue'
SELECT dep_acte, cantons_lus, valid_from, communes, unit_id, partagees, taux, verdict
FROM   p76_lien
WHERE  verdict IN ('desaccord', 'collision', 'département incompatible')
ORDER  BY verdict, dep_acte, cantons_lus;

\echo ''
\echo '   Ces cantons-là restent absents. Règle de `60` : mieux vaut un canton'
\echo '   absent qu''un canton faux, puisqu''aucune recette interne ne saurait'
\echo '   distinguer le second d''un vrai.'

-- ---------------------------------------------------------------------------
-- 10. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 10. recettes'

\echo ''
\echo '   a. aucun chevauchement introduit (la contrainte l''aurait refusé,'
\echo '      mais on le redit pour que la recette soit lisible sans elle) :'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id
      AND a.periode && b.periode
WHERE  a.niveau = 'canton';

\echo ''
\echo '   b. snapshot répond-il désormais à ces dates ?'
\echo '      (1968-06-01 : le jalon de 59 — inchangé)'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date)       AS rattachements,
       (SELECT count(DISTINCT m.unit_id) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date)       AS cantons
FROM   (VALUES ('1968-06-01'), ('1972-01-01'), ('1974-01-01'),
               ('1977-01-01'), ('1980-01-01'), ('1983-01-01'),
               ('1986-01-01'), ('1990-01-01'), ('1993-01-01'),
               ('1996-01-01'), ('1998-06-01')) v(d)
ORDER  BY 1;

\echo ''
\echo '      1968 est le jalon de `59`, inchangé. Les autres dates sont ce que'
\echo '      `75` et `76` apportent ENSEMBLE — ce fichier ne se lit pas seul.'

\echo ''
\echo '   c. couverture par département, au 1er janvier 1974 et 1983'
SELECT extract(year FROM p.valid_from) AS scrutin,
       count(DISTINCT p.dep_acte)      AS departements,
       count(DISTINCT p.unit_id)       AS cantons,
       count(*)                        AS rattachements
FROM   p76_pose p GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   d. aucune période vide ni inversée (doit valoir 0) :'
SELECT count(*) AS periodes_absurdes
FROM   p76_pose WHERE valid_from >= valid_to;

\echo ''
\echo '   e. aucun rattachement posé au-delà de la reprise de `24` (doit valoir 0) :'
SELECT count(*) AS deborde_1999
FROM   p76_qualite q JOIN membership m USING (membership_id)
WHERE  m.valid_to > :'fin_serie'::date;

\echo ''
\echo '   f. LA RECETTE QUI JUSTIFIE LA PAIRE : `75` et `76` couvrent-ils'
\echo '      ensemble tous les actes posables porteurs d''une composition ?'
\echo '      (le reste attendu : 1967, traité par `59` et `74` sur des dates'
\echo '       exactes, et les actes sans composition lue)'
SELECT count(DISTINCT a.legifrance_id)                                AS actes_posables_avec_composition,
       count(DISTINCT a.legifrance_id) FILTER (
         WHERE extract(year FROM c.date_acte) IN (1973, 1982))        AS pris_par_75,
       count(DISTINCT a.legifrance_id) FILTER (
         WHERE extract(year FROM c.date_acte)::smallint
               IN (SELECT annee FROM p76_salve))                      AS pris_par_76,
       count(DISTINCT a.legifrance_id) FILTER (
         WHERE extract(year FROM c.date_acte) = 1967)                 AS laisses_a_1967
FROM   acte_cantonal a
JOIN   acte_effet e   ON e.legifrance_id = a.legifrance_id AND e.statut = 'posable'
JOIN   acte_composition c ON c.url = a.url;

\echo ''
\echo '   g. cohérence de la table de qualité (doit valoir 0) :'
SELECT count(*) AS traces_sans_qualite
FROM   p76_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p76_qualite q
                    WHERE q.membership_id = t.cle::bigint);

-- ---------------------------------------------------------------------------
-- 11. CE QUI SÉPARE LA SALVE DE 1999 — pourquoi la résolution échoue
--
-- Ajouté le 28 août 2026 après lecture du JO, et c'est une leçon d'ensemble.
--
-- La collision « Laval - Nord-Ouest / Laval - Sud-Ouest » (53) n'était pas une
-- erreur de lecture. Le décret du 17 juillet 1973 crée quatre cantons à Laval,
-- chacun avec trois communes rurales et une portion de ville. **Le décret du
-- 24 décembre 1984 remplace Laval-Nord-Ouest, Laval-Sud-Ouest et Laval-Est par
-- quatre cantons définis uniquement par des portions de la ville** : les
-- communes rurales sont parties ailleurs. En 1999, elles se retrouvent
-- ensemble, et les deux cantons de 1973 votent donc pour la même unité.
--
-- Le refus est juste. Mais le motif inscrit — « la résolution n'est plus
-- injective » — décrit le symptôme et non la cause. La cause est qu'UN ACTE
-- EST PASSÉ ENTRE LES DEUX DATES, et le registre le sait déjà.
--
-- D'où ce diagnostic : la résolution contre 1999 doit se dégrader à mesure que
-- des actes s'intercalent. Si la statistique le montre, alors les refus ne
-- sont pas du bruit — ils ont une cause nommée et datée, et `76` saura où la
-- résolution contre 1999 n'est pas le bon juge.
--
-- Lecture seule ; ne change rien à ce qui a été posé.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p76_intercale;
CREATE TABLE p76_intercale AS
SELECT l.dep_acte, l.cantons_lus, l.valid_from, l.communes, l.taux, l.verdict,
       (SELECT count(*) FROM acte_cantonal a
         WHERE a.dep = l.dep_acte
           AND a.date_signature >  l.valid_from
           AND a.date_signature <  :'fin_serie'::date) AS actes_intercales
FROM   p76_lien l;

\echo ''
\echo '-- 11. la résolution contre 1999 se dégrade-t-elle quand un acte'
\echo '   s''intercale entre la salve et 1999 ?'
SELECT CASE WHEN actes_intercales = 0 THEN 'a - aucun acte intercalé'
            WHEN actes_intercales <= 2 THEN 'b - 1 ou 2 actes'
            ELSE                            'c - 3 actes ou plus'
       END                                                        AS intervalle,
       count(*)                                                   AS cantons,
       count(*) FILTER (WHERE verdict = 'resolu')                 AS resolus,
       round(100.0 * count(*) FILTER (WHERE verdict = 'resolu')
             / nullif(count(*), 0), 1)                            AS pct_resolus,
       count(*) FILTER (WHERE verdict = 'accord partiel')         AS partiels,
       count(*) FILTER (WHERE verdict IN ('desaccord','collision')) AS pires
FROM   p76_intercale GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   MÊME LECTURE QUE DANS `75`, ET C''EST ICI QU''ELLE SE VÉRIFIE.'
\echo '   Ces salves sont pour la plupart PLUS PROCHES de 1999 que celles de'
\echo '   1973 : si l''explication tient, la ligne « a » doit y être meilleure'
\echo '   que les 63,6 % mesurés par `75`. Le gradient a-t-il la même pente ?'
\echo '   S''il l''a, les refus des deux fichiers ont une seule et même cause,'
\echo '   et elle est datée.'

\echo ''
\echo '   les départements où le plus de cantons échouent avec le plus d''actes'
\echo '   intercalés. Ils ne seront pas rattrapés par une salve de plus : il'
\echo '   faudrait, pour eux, un jalon intermédiaire — un recensement, ou la'
\echo '   composition d''un acte que le registre ignore encore.'
SELECT dep_acte, count(*) AS cantons,
       count(*) FILTER (WHERE verdict <> 'resolu') AS refuses,
       max(actes_intercales)                       AS actes_intercales
FROM   p76_intercale
GROUP  BY dep_acte
HAVING count(*) FILTER (WHERE verdict <> 'resolu') > 0
ORDER  BY refuses DESC, actes_intercales DESC
LIMIT  12;

\echo ''
\echo '============================================================'
\echo ' Les salves restantes sont posées — même convention, et elle'
\echo ' est écrite dans p76_qualite ligne à ligne, comme dans p75.'
\echo ''
\echo ' Avec `75`, toutes les salves posables sont en base — sauf'
\echo ' 1967, qui n''en avait pas besoin. Suite : `77`, les cinq'
\echo ' transferts isolés de commune, que `73` § 5 simule déjà.'
\echo '============================================================'

-- ============================================================================
-- histgis — 75_composition_1973_1982.sql : les deux grosses salves entrent
--                                          dans le membership
--
--   psql -d histgis -1 -f sql/75_composition_1973_1982.sql
--
-- PREMIER FICHIER À POSER DES RATTACHEMENTS SUR UNE DATE CONVENTIONNELLE
-- =====================================================================
-- `59` a posé 1968 sur la date d'un recensement — un fait. `74` a posé les
-- Yvelines sur la date de naissance du département — un fait juridique. Ici,
-- la date d'effet n'est PAS dans la source, et c'est tout le problème du
-- fichier.
--
-- Les décrets de 1973 et de 1982 ne portent aucune clause d'effet. Leur
-- article final dit seulement « … est chargé de l'exécution du présent décret,
-- qui sera publié au Journal officiel de la République française ». Vérifié
-- sur les 233 segments de décret cantonal des JO : sept seulement portent une
-- clause explicite.
--
-- LA CONVENTION RETENUE, ET CE QU'ELLE COÛTE
-- ==========================================
--     valid_from = PREMIER TOUR DU RENOUVELLEMENT DES CONSEILS GÉNÉRAUX
--                  QUI SUIT LA SIGNATURE
--
-- Ce n'est pas un choix arbitraire. Chaque salve est signée quelques semaines
-- avant un renouvellement — juillet-août 1973 pour le scrutin du 23 septembre
-- 1973, janvier-février 1982 pour celui du 14 mars 1982 — et le seul décret de
-- tout le lot qui le dise en toutes lettres, celui de 1997, dit précisément
-- cela : « prendra effet pour le prochain renouvellement des conseils
-- généraux ». Le découpage doit être en vigueur au scrutin QUI ÉLIT, donc au
-- premier tour ; c'est pourquoi la borne est le premier tour et non le second.
--
-- MAIS LES CONSEILS GÉNÉRAUX SE RENOUVELAIENT PAR MOITIÉ. « Le prochain
-- renouvellement » d'un canton donné dépend de sa SÉRIE, que nous n'avons pas.
--
--   * pour un canton CRÉÉ, la question ne se pose guère : il entre en vigueur
--     au scrutin qui l'élit ;
--   * pour un canton MODIFIÉ, elle se pose entièrement, et le décalage
--     possible est d'un renouvellement — TROIS ANS.
--
-- Cette incertitude n'est pas cachée : elle est inscrite ligne à ligne dans
-- `p75_qualite` (`serie_inconnue`, `decalage_max_annees`), sur le modèle de
-- `c68_qualite`. **Une convention doit être lisible comme une convention.**
-- Ce fichier n'affirme pas une date ; il affirme une règle, et dit où la règle
-- peut se tromper.
--
-- LA BORNE HAUTE — ÉTROITE, COMME CELLE DE 1968
-- =============================================
--     valid_to = date d'effet du PREMIER ACTE POSTÉRIEUR touchant le même
--                département, sans dépasser 1999-01-01 où `24` reprend la main
--
-- Un acte vaut jusqu'au suivant, et le suivant prend effet à SON scrutin — pas
-- à sa signature. Fermer à la signature créerait un trou pendant lequel
-- l'ancienne composition était pourtant, elle, toujours en vigueur.
--
-- Cette borne suppose que la LISTE DES ACTES est complète sur l'intervalle. On
-- ne le sait pas, et `72` § 5 le dit sans détour : un silence est une absence
-- d'acte DANS NOTRE LISTE, pas une preuve de stabilité. La borne haute est
-- donc la partie fragile du fichier, et la seule mesure disponible — 94,2 %
-- d'accord 1954/1968 là où aucun acte n'est enregistré — n'est pas 100 %.
--
-- Deux garde-fous : tout acte postérieur ferme l'intervalle, MÊME muet (un
-- transfert de parcelles n'a aucun effet cantonal, mais fermer trop tôt ne
-- coûte que de la couverture, tandis que fermer trop tard pose des
-- rattachements faux) ; et le § 2 compte séparément ce que coûte ce choix.
--
-- L'IDENTITÉ DES CANTONS — PAR LA COMPOSITION, JAMAIS PAR LE NOM
-- ==============================================================
-- Reprise telle quelle de `74` : le canton retenu est celui de 1999 (posé par
-- `24`) qui partage au moins 80 % des communes de la liste du décret, sur au
-- moins trois communes entières. Un nom de canton n'est pas une identité, et
-- le dépôt a déjà payé pour l'avoir cru — la série havraise décalée d'un rang
-- après 1991.
--
-- On NE résout PAS contre le jalon de 1968, et c'est délibéré : un canton créé
-- en 1973 par scission a toutes ses communes dans le canton-mère en 1968, et
-- le vote désignerait la mère. Ce serait fabriquer une identité fausse. 1968
-- sert ici de DIAGNOSTIC (§ 8), pas de résolution.
--
-- LE PIÈGE DE LA CORSE
-- ====================
-- Les décrets de 1973 écrivent `20`, ceux de 1982 écrivent `2A` et `2B` : le
-- recodage de 1976 tombe entre les deux salves. Une comparaison de
-- département faite au caractère près écarterait la Corse de 1973 en silence —
-- exactement le défaut qui a coûté Chisa à `15`. Le § 5 normalise.
--
-- ON REFUSE PLUTÔT QUE DE DEVINER
-- ===============================
-- Trop court, accord partiel, désaccord, département incompatible, deux
-- cantons du décret résolus vers la même unité : rien n'est posé, tout est
-- listé au § 9 avec son motif. Règle de `60` — mieux vaut un canton absent
-- qu'un canton faux, puisqu'aucune recette interne ne saurait distinguer le
-- second d'un vrai.
--
-- CE QUI RESTE HORS DE CE FICHIER
-- ===============================
--   * le décret n° 82-82, « divers départements » : son titre ne nomme aucun
--     département et le JO en montre au moins deux. Tant qu'ils ne sont pas
--     établis un par un, ses compositions ne sont pas posées (`note_entree_en
--     _base.md` § 6). Elles restent dans `acte_composition`.
--   * les salves de 1967, 1970, 1974-1976, 1984, 1985, 1988 et 1991-1997 :
--     ce sera `76`, qui réutilise `scrutin_cantonal` et `acte_effet` posés ici.
--   * les cinq transferts isolés de commune : ce sera `77`, une fois la
--     présente convention éprouvée.
--
-- REJOUABLE
-- =========
-- Tout ce qui est écrit dans `membership` est tracé dans `p75_trace`, et le
-- § 3 défait le passage précédent AVANT de juger quoi que ce soit. Leçon de
-- `55` : un fichier qui vérifie que la place est libre avant d'avoir retiré sa
-- propre trace refuse de tourner deux fois.
--
-- Prérequis : `72_registre_actes.sql`, `24_canton_moderne.sql`.
--             (`58` + `59` seulement pour le diagnostic du § 8 ; leur absence
--              n'empêche pas la pose.)
--
-- Sources des dates de scrutin :
--   https://www.france-politique.fr/elections-cantonales.htm  (consulté le
--   28 août 2026 ; premier et second tour de 1961 à 2015)
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
\echo ' COMPOSITIONS DE 1973 ET 1982 — pose sur convention déclarée'
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
-- 1. Les renouvellements des conseils généraux
--
-- Table de référence, sourcée, indépendante du reste. Elle porte les deux
-- tours parce que la distinction compte : la borne retenue est le PREMIER,
-- celui qui élit sous le nouveau découpage.
--
-- 2001 y figure pour une seule raison : sans lui, les actes de 1998 et 1999
-- n'auraient « aucun scrutin suivant » et l'on ne saurait pas les distinguer
-- des actes qu'aucune donnée ne borne. Avec lui, ils sont proprement écartés
-- comme postérieurs à la fin de série (§ 2).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS scrutin_cantonal;
CREATE TABLE scrutin_cantonal (
    tour1 date PRIMARY KEY,
    tour2 date NOT NULL,
    CONSTRAINT scrutin_ordre CHECK (tour1 < tour2)
);

INSERT INTO scrutin_cantonal (tour1, tour2) VALUES
    ('1961-06-04', '1961-06-11'),
    ('1964-03-08', '1964-03-15'),
    ('1967-09-24', '1967-10-01'),
    ('1970-03-08', '1970-03-15'),
    ('1973-09-23', '1973-09-30'),
    ('1976-03-07', '1976-03-14'),
    ('1979-03-18', '1979-03-25'),
    ('1982-03-14', '1982-03-21'),
    ('1985-03-10', '1985-03-17'),
    ('1988-09-25', '1988-10-02'),
    ('1992-03-22', '1992-03-29'),
    ('1994-03-20', '1994-03-27'),
    ('1998-03-15', '1998-03-22'),
    ('2001-03-11', '2001-03-18');

COMMENT ON TABLE scrutin_cantonal IS
'Renouvellements des conseils généraux, 1961-2001. Source : france-politique.fr'
', consulté le 28 août 2026. Sert de date d''effet conventionnelle aux décrets'
' cantonaux dépourvus de clause d''effet (cf. sql/75).';

\echo ''
\echo '-- 1. scrutins de référence'
SELECT count(*) AS scrutins, min(tour1) AS du, max(tour1) AS au
FROM   scrutin_cantonal;

-- ---------------------------------------------------------------------------
-- 2. La date d'effet et la borne haute de CHAQUE acte
--
-- Calculées pour les 343 actes du registre, pas seulement pour les deux
-- salves : `76` reprendra cette table telle quelle, et une convention qui
-- change entre deux fichiers n'est plus une convention.
--
-- `date_fin` est la date d'effet du premier acte du MÊME DÉPARTEMENT dont
-- l'effet est STRICTEMENT postérieur. Le « strictement » n'est pas un détail :
-- une salve compte jusqu'à cinq décrets pour un même département, tous signés
-- entre deux scrutins, donc tous de même date d'effet. Sans lui, chaque décret
-- fermerait l'intervalle de son voisin et l'on poserait des périodes vides.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS acte_effet;
CREATE TABLE acte_effet AS
WITH base AS (
    SELECT a.legifrance_id,
           a.dep,
           a.objet,
           a.date_signature,
           (SELECT min(s.tour1) FROM scrutin_cantonal s
             WHERE s.tour1 >= a.date_signature)          AS date_effet
    FROM   acte_cantonal a
)
SELECT b.legifrance_id,
       b.dep,
       b.objet,
       b.date_signature,
       b.date_effet,
       (SELECT min(c.date_effet) FROM base c
         WHERE c.dep = b.dep AND c.dep <> '' AND c.dep IS NOT NULL
           AND c.date_effet > b.date_effet)              AS effet_acte_suivant,
       CASE
         WHEN b.date_effet IS NULL                       THEN 'aucun scrutin connu après la signature'
         WHEN b.date_effet >= :'fin_serie'::date         THEN 'effet postérieur à la fin de série'
         WHEN b.dep = '' OR b.dep IS NULL                THEN 'département non attribué'
         WHEN length(b.dep) > 2                          THEN 'outre-mer : hors nomenclature métropolitaine'
         ELSE                                                 'posable'
       END                                               AS statut
FROM   base b;

ALTER TABLE acte_effet ADD PRIMARY KEY (legifrance_id);

-- la borne haute proprement dite : l'acte suivant, à défaut la fin de série
ALTER TABLE acte_effet ADD COLUMN date_fin date;
UPDATE acte_effet
   SET date_fin = least(coalesce(effet_acte_suivant, :'fin_serie'::date),
                        :'fin_serie'::date);

ALTER TABLE acte_effet ADD COLUMN borne_haute_source text;
UPDATE acte_effet
   SET borne_haute_source = CASE
         WHEN effet_acte_suivant IS NULL                     THEN 'fin de série (aucun acte postérieur connu)'
         WHEN effet_acte_suivant >= :'fin_serie'::date       THEN 'fin de série (l''acte suivant est postérieur)'
         ELSE                                                     'acte postérieur du même département'
       END;

CREATE INDEX acte_effet_dep_idx ON acte_effet (dep, date_effet);

\echo ''
\echo '-- 2. date d''effet conventionnelle des 343 actes'
SELECT statut, count(*) AS actes
FROM   acte_effet GROUP BY statut ORDER BY actes DESC;

\echo ''
\echo '   d''où vient la borne haute (actes posables)'
SELECT borne_haute_source, count(*) AS actes,
       round(avg(date_fin - date_effet) / 365.25, 1) AS duree_moyenne_annees
FROM   acte_effet WHERE statut = 'posable'
GROUP  BY borne_haute_source ORDER BY actes DESC;

\echo ''
\echo '   CE QUE COÛTE LE CHOIX DE FERMER SUR TOUT ACTE, MÊME MUET'
\echo '   (un acte muet — transfert de parcelles, tracé de rues — ne change'
\echo '    l''appartenance d''aucune commune ; fermer dessus raccourcit un'
\echo '    intervalle sans nécessité. On l''assume et on le chiffre.)'
SELECT count(*) AS intervalles_fermes_par_un_acte_muet
FROM   acte_effet e
WHERE  e.statut = 'posable'
  AND  e.borne_haute_source = 'acte postérieur du même département'
  AND  EXISTS (
         SELECT 1 FROM acte_effet f
         JOIN   acte_cantonal a ON a.legifrance_id = f.legifrance_id
          WHERE f.dep = e.dep AND f.date_effet = e.effet_acte_suivant
            AND NOT EXISTS (SELECT 1 FROM acte_composition c WHERE c.url = a.url)
            AND NOT EXISTS (SELECT 1 FROM acte_transfert  t WHERE t.url = a.url));

\echo ''
\echo '   le décret n° 82-82 (« divers départements ») ne ferme aucun'
\echo '   intervalle, faute de département — limite déclarée, non corrigée :'
SELECT legifrance_id, date_signature, statut
FROM   acte_effet WHERE dep = '' OR dep IS NULL ORDER BY date_signature;

-- ---------------------------------------------------------------------------
-- 3. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p75_trace (
    quoi text NOT NULL,          -- 'membership'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p75_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p75_trace;

\echo ''
\echo '-- 3. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 4. Les salves traitées ici
--
-- Deux années, 2 986 lignes de composition. Le reste attend `76` : on
-- commence par les deux salves les plus grosses ET les mieux datées, pour que
-- la convention soit éprouvée là où elle a le plus de matière.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p75_salve;
CREATE TABLE p75_salve (annee smallint PRIMARY KEY);
INSERT INTO p75_salve VALUES (1973), (1982);

-- `canton_norme` : la même graphie pour un même canton. Le banc a montré
-- « Saint-Quentin - Sud » et « Saint-Quentin-Sud » traités comme deux cantons
-- rivaux, puis refusés tous les deux pour collision — un canton perdu par une
-- espace. La normalisation ne fait QUE cela : elle uniformise les espaces
-- autour des traits d'union et la casse. Elle ne rapproche pas deux noms
-- voisins, et n'a donc rien de commun avec l'appariement par le nom que le
-- dépôt s'interdit : deux noms qui ne diffèrent que par une espace ne sont
-- pas deux noms.
DROP TABLE IF EXISTS p75_dit;
CREATE TABLE p75_dit AS
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
WHERE  extract(year FROM c.date_acte)::smallint IN (SELECT annee FROM p75_salve)
  AND  e.statut = 'posable'
  AND  c.atome IS NOT NULL
GROUP  BY 1,2,3,4,5,6,7,8,9;   -- une commune peut être citée deux fois par un décret

CREATE INDEX p75_dit_idx ON p75_dit (dep_acte, canton);

\echo ''
\echo '-- 4. ce qui est donné à poser'
SELECT extract(year FROM valid_from) AS scrutin,
       count(*)                             AS lignes,
       count(DISTINCT (dep_acte, canton))   AS cantons,
       count(DISTINCT dep_acte)             AS departements,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   p75_dit GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   lignes des deux salves ÉCARTÉES avant tout jugement, et pourquoi'
SELECT CASE
         WHEN c.atome IS NULL THEN 'a - pas d''atome (fraction de ville, ou nom non apparié)'
         ELSE 'b - acte non posable : ' || e.statut
       END                                  AS motif,
       count(*)                             AS lignes
FROM   acte_composition c
JOIN   acte_cantonal   a ON a.url = c.url
JOIN   acte_effet      e ON e.legifrance_id = a.legifrance_id
WHERE  extract(year FROM c.date_acte)::smallint IN (SELECT annee FROM p75_salve)
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
-- JO et par Légifrance — apparaît deux fois dans `p75_dit`. Comptée deux
-- fois, elle donnait au banc un taux de 333 % pour Aureilhan : un canton de
-- trois communes qui en « retrouvait » dix. Un taux supérieur à 100 % n'est
-- pas un bon score, c'est un défaut de dénombrement.
DROP TABLE IF EXISTS p75_uniq;
CREATE TABLE p75_uniq AS
SELECT DISTINCT dep_acte, canton_norme, atome, valid_from, valid_to
FROM   p75_dit;
CREATE INDEX p75_uniq_idx ON p75_uniq (dep_acte, canton_norme);

DROP TABLE IF EXISTS p75_lien;
CREATE TABLE p75_lien AS
WITH taille AS (
    SELECT dep_acte, canton_norme, valid_from, valid_to, count(*) AS communes
    FROM   p75_uniq GROUP BY 1,2,3,4
),
graphies AS (
    SELECT dep_acte, canton_norme,
           string_agg(DISTINCT canton, ' | ' ORDER BY canton) AS cantons_lus
    FROM   p75_dit GROUP BY 1,2
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
    FROM   p75_uniq d JOIN base99 b ON b.atome = d.atome
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
       -- normalisation Corse : le recodage de 1976 tombe ENTRE les deux salves
       (CASE WHEN t.dep_acte  IN ('20','2A','2B') THEN 'CORSE' ELSE t.dep_acte  END)
     = (CASE WHEN m.dep_1999  IN ('20','2A','2B') THEN 'CORSE' ELSE m.dep_1999  END)
                                                                     AS dep_compatible,
       NULL::text AS verdict
FROM   taille t
LEFT   JOIN meilleur m USING (dep_acte, canton_norme, valid_from, valid_to)
LEFT   JOIN graphies g USING (dep_acte, canton_norme);

UPDATE p75_lien SET verdict = CASE
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
UPDATE p75_lien l SET verdict = 'collision'
 WHERE l.verdict = 'resolu'
   AND EXISTS (SELECT 1 FROM p75_lien k
                WHERE k.verdict = 'resolu'
                  AND k.unit_id = l.unit_id
                  AND k.valid_from = l.valid_from AND k.valid_to = l.valid_to
                  AND (k.dep_acte, k.canton_norme)
                      IS DISTINCT FROM (l.dep_acte, l.canton_norme));

CREATE INDEX p75_lien_idx ON p75_lien (dep_acte, canton_norme);

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
SELECT count(*) AS taux_impossibles FROM p75_lien WHERE taux > 100;

DO $$
DECLARE n integer; ex text;
BEGIN
    SELECT count(*), min(cantons_lus) INTO n, ex FROM p75_lien WHERE taux > 100;
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
DROP TABLE IF EXISTS p75_atome_dispute;
CREATE TABLE p75_atome_dispute AS
SELECT d.atome, d.valid_from, d.valid_to,
       min(d.dep_acte)                               AS dep_acte,
       count(DISTINCT (d.dep_acte, d.canton_norme))  AS n_cantons,
       string_agg(DISTINCT l.cantons_lus, ' | ' ORDER BY l.cantons_lus) AS cantons
FROM   p75_uniq d
JOIN   p75_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
WHERE  l.verdict = 'resolu'
GROUP  BY d.atome, d.valid_from, d.valid_to
HAVING count(DISTINCT l.unit_id) > 1;

\echo ''
\echo '-- 5 bis. communes réclamées par deux cantons sur la même période'
SELECT atome, dep_acte, n_cantons, cantons, valid_from
FROM   p75_atome_dispute ORDER BY dep_acte, atome;

\echo ''
\echo '   Elles ne sont pas posées, et les cantons qui les citent le sont'
\echo '   quand même : la contradiction porte sur la commune, pas sur eux.'

\echo ''
\echo '-- 5. résolution des cantons du décret vers la nomenclature'
SELECT verdict, count(*) AS cantons, sum(communes) AS communes
FROM   p75_lien GROUP BY verdict ORDER BY cantons DESC;

\echo ''
\echo '   le piège de la Corse : le décret écrit `20` en 1973, `2A`/`2B` en 1982'
SELECT dep_acte, count(*) AS cantons,
       count(*) FILTER (WHERE verdict = 'resolu') AS resolus,
       min(dep_1999) AS dep_1999_min, max(dep_1999) AS dep_1999_max
FROM   p75_lien WHERE dep_acte IN ('20','2A','2B')
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
DROP TABLE IF EXISTS p75_pose;
CREATE TABLE p75_pose AS
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
FROM   p75_dit d
JOIN   p75_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
WHERE  l.verdict = 'resolu'
  AND  NOT EXISTS (SELECT 1 FROM p75_atome_dispute x
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
FROM   p75_pose;

\echo ''
\echo '   atomes écartés parce que la place n''était pas libre'
\echo '   (attendu : la ligne unique de `38_decret_1982_ain.sql`, qui court du'
\echo '    26 janvier 1982 au 1er janvier 1999 et occupe donc la période que'
\echo '    la salve de 1982 veut écrire. Tout autre occupant est à regarder.)'
SELECT m.unit_id AS occupe_par, count(*) AS lignes, min(d.atome) AS un_exemple
FROM   p75_uniq d
JOIN   p75_lien l USING (dep_acte, canton_norme, valid_from, valid_to)
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
FROM   p75_pose a JOIN p75_pose b
       ON a.atome = b.atome
      AND (a.unit_id, a.valid_from, a.valid_to)
        < (b.unit_id, b.valid_from, b.valid_to)
      AND daterange(a.valid_from, a.valid_to, '[)')
       && daterange(b.valid_from, b.valid_to, '[)');

DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
      FROM p75_pose a JOIN p75_pose b
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
    SELECT count(*) INTO n FROM p75_atome_dispute;
    IF n > 50 THEN
        RAISE EXCEPTION
          'REFUS : % communes réclamées par deux cantons. Ce n''est plus du '
          'bruit de lecture — la salve est à relire avant d''être posée.', n;
    END IF;
END $$;

-- GARDE-FOU 3 : l'ordre de grandeur. Leçon de `42`, où trois requêtes bien
-- formées et absurdes n'ont été démasquées que par le nombre de lignes
-- qu'elles rendaient. Les deux salves portent 2 986 lignes de composition ;
-- au-delà de 6 000 rattachements, la sélection a dérivé.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM p75_pose;
    IF n > 6000 THEN
        RAISE EXCEPTION
          'REFUS : % rattachements à poser, très au-delà des 2 986 lignes de '
          'composition des deux salves. La sélection a dérivé.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. La pose, et la qualité attachée à chaque rattachement
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atome, unit_id, 'canton', valid_from, valid_to
    FROM   p75_pose
    RETURNING membership_id
)
INSERT INTO p75_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

DROP TABLE IF EXISTS p75_qualite;
CREATE TABLE p75_qualite AS
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
JOIN   p75_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
JOIN   p75_pose  p ON p.atome = m.atom_id AND p.unit_id = m.unit_id
                  AND p.valid_from = m.valid_from;

CREATE INDEX p75_qualite_m_idx ON p75_qualite (membership_id);
CREATE INDEX p75_qualite_s_idx ON p75_qualite (serie_inconnue);

ANALYZE membership;
ANALYZE p75_qualite;

\echo ''
\echo '-- 7. posé'
SELECT count(*) AS rattachements FROM p75_trace WHERE quoi = 'membership';

\echo ''
\echo '   LA LIGNE À LIRE AVANT TOUTE AUTRE : la part des rattachements dont'
\echo '   la date de début peut être fausse de trois ans, faute de connaître'
\echo '   la série de renouvellement du département.'
SELECT serie_inconnue, decalage_max_annees, count(*) AS rattachements,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   p75_qualite GROUP BY 1,2 ORDER BY 1;

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
DROP TABLE IF EXISTS p75_diag_1968;
CREATE TABLE p75_diag_1968 AS
WITH base68 AS (
    SELECT split_part(m.atom_id, '#', 1) AS atome, m.unit_id
    FROM   membership m
    WHERE  m.niveau = 'canton' AND m.periode @> :'jalon_1968'::date
    GROUP  BY 1,2
),
votes AS (
    SELECT d.dep_acte, d.canton_norme, d.valid_from, d.valid_to,
           b.unit_id, count(*) AS n
    FROM   p75_uniq d JOIN base68 b ON b.atome = d.atome
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
FROM   p75_lien l
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
FROM   p75_diag_1968 GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 9. Ce qui n'a PAS été posé, et pourquoi
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 9. refusés, par motif'
SELECT verdict, count(*) AS cantons, sum(communes) AS communes
FROM   p75_lien WHERE verdict <> 'resolu'
GROUP  BY verdict ORDER BY cantons DESC;

\echo ''
\echo '   les désaccords et les collisions, en clair — ce sont les seuls'
\echo '   refus qui accusent une LECTURE plutôt qu''une nomenclature disparue'
SELECT dep_acte, cantons_lus, valid_from, communes, unit_id, partagees, taux, verdict
FROM   p75_lien
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
               ('1980-01-01'), ('1983-01-01'), ('1990-01-01')) v(d)
ORDER  BY 1;

\echo ''
\echo '      1972 et 1990 doivent rester quasi vides : aucune salve ne les'
\echo '      couvre. 1974 et 1983 sont ce que ce fichier apporte.'

\echo ''
\echo '   c. couverture par département, au 1er janvier 1974 et 1983'
SELECT extract(year FROM p.valid_from) AS scrutin,
       count(DISTINCT p.dep_acte)      AS departements,
       count(DISTINCT p.unit_id)       AS cantons,
       count(*)                        AS rattachements
FROM   p75_pose p GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   d. aucune période vide ni inversée (doit valoir 0) :'
SELECT count(*) AS periodes_absurdes
FROM   p75_pose WHERE valid_from >= valid_to;

\echo ''
\echo '   e. aucun rattachement posé au-delà de la reprise de `24` (doit valoir 0) :'
SELECT count(*) AS deborde_1999
FROM   p75_qualite q JOIN membership m USING (membership_id)
WHERE  m.valid_to > :'fin_serie'::date;

\echo ''
\echo '   f. cohérence de la table de qualité (doit valoir 0) :'
SELECT count(*) AS traces_sans_qualite
FROM   p75_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p75_qualite q
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
DROP TABLE IF EXISTS p75_intercale;
CREATE TABLE p75_intercale AS
SELECT l.dep_acte, l.cantons_lus, l.valid_from, l.communes, l.taux, l.verdict,
       (SELECT count(*) FROM acte_cantonal a
         WHERE a.dep = l.dep_acte
           AND a.date_signature >  l.valid_from
           AND a.date_signature <  :'fin_serie'::date) AS actes_intercales
FROM   p75_lien l;

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
FROM   p75_intercale GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   Si `pct_resolus` baisse de a vers c, les refus ne sont pas du bruit :'
\echo '   ils ont une cause nommée et datée. C''est aussi la mesure de ce que'
\echo '   `76` fera gagner — chaque salve posée rapproche le point de'
\echo '   comparaison, et les cantons d''aujourd''hui refusés se résoudront'
\echo '   contre un jalon plus proche que 1999.'

\echo ''
\echo '   les départements où le plus de cantons échouent avec le plus d''actes'
\echo '   intercalés — à traiter en premier par `76`'
SELECT dep_acte, count(*) AS cantons,
       count(*) FILTER (WHERE verdict <> 'resolu') AS refuses,
       max(actes_intercales)                       AS actes_intercales
FROM   p75_intercale
GROUP  BY dep_acte
HAVING count(*) FILTER (WHERE verdict <> 'resolu') > 0
ORDER  BY refuses DESC, actes_intercales DESC
LIMIT  12;

\echo ''
\echo '============================================================'
\echo ' Les deux salves sont posées — sur une CONVENTION, et elle'
\echo ' est écrite dans p75_qualite ligne à ligne. Ce fichier'
\echo ' n''affirme pas une date : il affirme une règle, et dit où'
\echo ' la règle peut se tromper de trois ans.'
\echo ''
\echo ' Suite : `76` (les autres salves, même convention, mêmes'
\echo ' tables `scrutin_cantonal` et `acte_effet`), puis `77`'
\echo ' (les cinq transferts isolés).'
\echo '============================================================'

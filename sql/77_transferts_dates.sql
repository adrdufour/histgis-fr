-- ============================================================================
-- histgis — 77_transferts_dates.sql : les changements de canton datés au jour
--
--   psql -d histgis -1 -f sql/77_transferts_dates.sql
--   (à lancer depuis la RACINE du dépôt : le \copy est relatif au répertoire
--    de lancement)
--
-- CE QUE CE FICHIER POSE, ET POURQUOI IL EST DIFFÉRENT DES DEUX PRÉCÉDENTS
-- =======================================================================
-- `75` et `76` posent des COMPOSITIONS de cantons sur une convention de date.
-- Ici, ce sont des mouvements de commune, et **la date est un fait**.
--
-- Le fichier historique du COG 1999 — `Corhistoriq1999.txt`, modalité 43,
-- « changement de canton » — porte 66 mouvements avec, pour chacun, la date de
-- l'acte, celle de sa publication et **sa date d'effet**, plus le canton
-- d'arrivée codé. C'est `cantons/transferts_insee.py` qui l'en extrait.
--
-- Le dépôt connaissait ce fichier depuis le 9 août et en avait tiré la
-- conclusion juste — il ne contient que 66 changements, tous postérieurs à
-- 1995, donc aucune reconstitution de 1943-1995 n'est possible par là. Ce qui
-- avait échappé, c'est qu'il répondait à une AUTRE question :
--
--     une source trop pauvre pour combler un trou peut être exactement
--     assez riche pour dater ce qu'on a déjà.
--
-- `73` § 5 attendait depuis le 28 août « qu'il ne manque que la convention »
-- pour cinq transferts. Il n'en manquait pas : il manquait de regarder.
--
-- CE QUE LES DATES DISENT, ET QUI CONFIRME `75` AU LIEU DE LE DÉMENTIR
-- ===================================================================
--     Saint-Denis-des-Puits, Villebon (28)
--         décret du 10 avril 1995, JO du 15, EFFET LE 16 — le lendemain.
--     Saint-Alban-de-Roche (38) et soixante autres
--         décret du 26 février 1997, JO du 27, EFFET LE 1er AVRIL 1998.
--
-- Aucune des deux n'est le premier tour du renouvellement, qui est la
-- convention de `75` et `76`. On pourrait y lire un démenti ; c'est
-- l'inverse, et la raison tient à la nature des actes :
--
--   * un REDÉCOUPAGE crée ou modifie des cantons. La carte doit exister au
--     scrutin QUI ÉLIT, donc au premier tour — convention de `75`.
--   * un simple RATTACHEMENT de commune ne demande aucune élection. Il prend
--     effet quand l'acte le dit : le lendemain de sa publication en 1995, à
--     l'installation du nouveau conseil (1er avril 1998, après le second tour
--     du 22 mars) pour la salve de 1997 — dont le décret annonçait justement
--     l'effet « pour le prochain renouvellement des conseils généraux ».
--
-- **Deux règles différentes parce que les actes sont de nature différente**,
-- et non parce que l'une aurait été mal choisie. C'est le premier élément
-- extérieur qui vienne éclairer la convention de `75` depuis qu'elle est posée.
--
-- LES DEUX QUI RESTENT SANS FAIT
-- ==============================
-- Laprade (11) et Vasselin (38), janvier 1993, connus par Légifrance seul : le
-- fichier de l'INSEE ne répertorie les changements de canton que depuis 1994.
-- Ils sont posés **au lendemain de la publication au JO**, qui est ce que
-- l'INSEE enregistre pour les deux cas de 1995 — la meilleure estimation
-- disponible, et une convention, marquée comme telle dans `p77_qualite`.
-- L'incertitude est BORNÉE et inscrite : au pire, l'effet a été différé au
-- renouvellement du 20 mars 1994, soit quatorze mois.
--
-- DEUX SOURCES DOIVENT DIRE LA MÊME CHOSE
-- =======================================
-- Le canton d'arrivée est codé par l'INSEE (`dep || CT`). On ne le croit pas
-- sur parole : le § 3 vérifie que **le COG de 1999 place bien la commune dans
-- cette unité**, par `24`. Les deux viennent de l'INSEE mais pas du même
-- fichier ni du même travail, et surtout la seconde est déjà en base et sert
-- ailleurs. Un désaccord est refusé et listé.
--
-- Contrôle croisé gratuit : trois de ces mouvements sont aussi connus par le
-- texte des décrets (`acte_transfert`, via Légifrance). Le § 6 c compare les
-- deux lectures — canton d'arrivée nommé d'un côté, codé de l'autre.
--
-- CE QUI SERA ÉCARTÉ, ET CE QUE CELA VOUDRA DIRE
-- ==============================================
-- Beaucoup de ces communes sont déjà rattachées par `76` : la salve de 1997
-- qu'il a posée est la même que celle qui produit 61 de ces 66 mouvements. Un
-- transfert dont la place n'est pas libre n'est donc pas un échec — c'est le
-- signe que la composition du canton d'arrivée, elle, était déjà lue. Le § 4
-- les compte à part.
--
-- REJOUABLE
-- =========
-- Tout ce qui est écrit est tracé dans `p77_trace`, et le § 2 défait le
-- passage précédent AVANT de juger quoi que ce soit.
--
-- Prérequis : `72_registre_actes.sql`, `24_canton_moderne.sql`,
--             `75_composition_1973_1982.sql` (pour `scrutin_cantonal`),
--             et `cantons/transferts_insee.py` pour le CSV.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- fin_serie : la date où `24_canton_moderne.sql` reprend la main.
\set fin_serie  '1999-01-01'
\set jalon_1999 '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' TRANSFERTS DE COMMUNE — la date est un fait, pas une règle'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_transfert') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql d''abord.';
    END IF;
    IF to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION
          'PRÉREQUIS : `scrutin_cantonal` est posée par sql/75. Le jouer d''abord.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> DATE '1999-06-01') THEN
        RAISE EXCEPTION 'PRÉREQUIS : les cantons de 1999 ne sont pas en base (sql/24).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les mouvements datés par l'INSEE
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS transfert_insee;
CREATE TABLE transfert_insee (
    dep            text NOT NULL,
    insee          text NOT NULL,
    commune        text,
    canton_arrivee text NOT NULL,   -- unit_id, 'DDNN'
    date_acte      date,
    date_jo        date,
    date_effet     date NOT NULL,
    atome          text
);

\copy transfert_insee (dep, insee, commune, canton_arrivee, date_acte, date_jo, date_effet) FROM 'cantons/transferts_insee.csv' WITH (FORMAT csv, HEADER true)

-- même mécanique que `72` § 4 : `cm_atome` est une UNION ALL, on prend
-- l'atome par sous-requête pour ne pas dupliquer les lignes en silence
UPDATE transfert_insee t
   SET atome = (SELECT min(x.atom_id) FROM cm_atome x WHERE x.code = t.insee);

\echo ''
\echo '-- 1. changements de canton datés par le COG 1999 (modalité 43)'
SELECT count(*)                                AS mouvements,
       count(DISTINCT insee)                   AS communes,
       count(DISTINCT canton_arrivee)          AS cantons_arrivee,
       count(DISTINCT dep)                     AS departements,
       count(*) FILTER (WHERE atome IS NULL)   AS sans_atome
FROM   transfert_insee;

\echo ''
\echo '   par date d''effet — trois dates, et aucune n''est un premier tour'
SELECT date_effet, count(*) AS communes,
       string_agg(DISTINCT dep, ' ' ORDER BY dep) AS departements
FROM   transfert_insee GROUP BY date_effet ORDER BY date_effet;

-- ---------------------------------------------------------------------------
-- 2. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p77_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p77_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p77_trace;

\echo ''
\echo '-- 2. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 3. Les candidats : ce que l'INSEE date, plus ce que Légifrance seul connaît
--
-- `origine` dit d'où vient la DATE, et c'est la seule chose qui distingue les
-- deux lots :
--   'insee'      la date d'effet est écrite dans le fichier historique — un fait
--   'convention' le lendemain de la publication au JO, faute de mieux
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p77_candidat;
CREATE TABLE p77_candidat AS
SELECT t.insee,
       t.commune,
       t.dep,
       t.atome,
       t.canton_arrivee                        AS unit_id,
       t.date_effet                            AS valid_from,
       'insee'::text                           AS origine,
       NULL::date                              AS incertitude_jusqu_au,
       NULL::text                              AS canton_dest_nomme
FROM   transfert_insee t

UNION ALL

-- Les mouvements que Légifrance donne et que l'INSEE ignore : antérieurs à
-- 1994, hors de portée de son fichier historique. Le canton d'arrivée y est
-- NOMMÉ et non codé — on le résout par le COG de 1999, ce qui revient à dire
-- que la base doit y placer la commune. C'est faible, et c'est déclaré.
SELECT a.insee,
       a.commune,
       a.dep,
       a.atome,
       (SELECT m.unit_id FROM membership m
         WHERE m.atom_id = a.atome AND m.niveau = 'canton'
           AND m.periode @> :'jalon_1999'::date LIMIT 1)   AS unit_id,
       -- Lendemain de la publication : c'est ce que l'INSEE enregistre pour
       -- les deux mouvements de 1995, seul patron disponible.
       --
       -- `date_publication` est VIDE pour ces deux actes de 1993 — le
       -- moissonnage de Légifrance ne l'a pas rendue. On retombe alors sur le
       -- lendemain de la SIGNATURE, qui la précède de un à trois jours. Sans
       -- ce repli, `valid_from` restait NULL et la ligne partait en écriture
       -- avec une date vide ; le banc ne l'a pas vu, ses deux atomes n'étant
       -- pas résolus.
       coalesce((SELECT min(c.date_publication) FROM acte_cantonal c
                  WHERE c.url = a.url),
                a.date_acte) + 1                           AS valid_from,
       'convention'::text                                  AS origine,
       -- borne de l'incertitude : au pire l'effet a été différé au
       -- renouvellement suivant, comme pour la salve de 1997
       (SELECT min(s.tour1) FROM scrutin_cantonal s
         WHERE s.tour1 > a.date_acte)                      AS incertitude_jusqu_au,
       a.canton_dest                                       AS canton_dest_nomme
FROM   acte_transfert a
WHERE  NOT EXISTS (SELECT 1 FROM transfert_insee t WHERE t.insee = a.insee);

-- ---------------------------------------------------------------------------
-- 3 bis. UN MOUVEMENT PAR COMMUNE ET PAR CANTON D'ARRIVÉE
--
-- Trouvé par le garde-fou du § 5, qui a refusé de poser : deux communes
-- figurent DEUX FOIS dans le fichier de l'INSEE — Maxéville et
-- Villers-lès-Nancy, le 1er avril 1998 puis le 13 novembre 1998, **vers le
-- même canton les deux fois**.
--
-- Ce n'est donc pas un double déplacement mais une seconde écriture du même
-- fait : le décret de 1997 les avait déplacées, un acte de novembre 1998 le
-- redit — probablement un rectificatif, la troisième commune du lot (Laxou)
-- n'ayant, elle, qu'une seule ligne.
--
-- On garde la PREMIÈRE date d'effet : la commune est dans ce canton à partir
-- de là, et l'écriture postérieure ne l'en sort pas. `n_actes` conserve la
-- trace du doublon plutôt que de l'effacer.
--
-- Le cas d'un vrai double déplacement — deux cantons d'arrivée différents —
-- n'existe pas dans ces données, mais le § 5 le traite quand même : les
-- périodes s'enchaînent, chacune s'arrêtant au mouvement suivant. Une règle
-- écrite pour un cas absent aujourd'hui est une règle qui ne manquera pas
-- demain.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p77_mouvement;
CREATE TABLE p77_mouvement AS
SELECT insee, dep, atome, unit_id,
       min(valid_from)                        AS valid_from,
       min(commune)                           AS commune,
       min(origine)                           AS origine,
       min(incertitude_jusqu_au)              AS incertitude_jusqu_au,
       min(canton_dest_nomme)                 AS canton_dest_nomme,
       count(*)                               AS n_actes
FROM   p77_candidat
GROUP  BY insee, dep, atome, unit_id;

\echo ''
\echo '-- 3 bis. mouvements écrits deux fois par la source (même canton)'
SELECT insee, commune, dep, unit_id, valid_from, n_actes
FROM   p77_mouvement WHERE n_actes > 1 ORDER BY insee;

\echo ''
\echo '   communes déplacées vers PLUSIEURS cantons — une vraie chronologie,'
\echo '   dont les périodes devront s''enchaîner (0 attendu dans ces données) :'
SELECT count(*) AS communes
FROM   (SELECT atome FROM p77_mouvement WHERE atome IS NOT NULL
         GROUP BY atome HAVING count(DISTINCT unit_id) > 1) q;

\echo ''
\echo '-- 3. candidats, par origine de la DATE'
SELECT origine, count(*) AS mouvements,
       min(valid_from) AS du, max(valid_from) AS au,
       count(*) FILTER (WHERE unit_id IS NULL) AS sans_canton_arrivee,
       count(*) FILTER (WHERE atome IS NULL)   AS sans_atome
FROM   p77_candidat GROUP BY origine ORDER BY origine;

\echo ''
\echo '   les mouvements sous convention, en clair (il ne doit y en avoir que'
\echo '   deux : janvier 1993, hors de portée du fichier de l''INSEE)'
SELECT insee, commune, dep, unit_id, canton_dest_nomme,
       valid_from, incertitude_jusqu_au
FROM   p77_candidat WHERE origine = 'convention' ORDER BY insee;

-- ---------------------------------------------------------------------------
-- 4. Le verdict — et la seconde source qui doit confirmer la première
--
-- Le canton d'arrivée vient d'un fichier ; le COG de 1999 posé par `24` vient
-- d'un autre. Ils doivent désigner la même unité. Ce n'est pas une tautologie :
-- `24` a été construit sans jamais lire `Corhistoriq1999.txt`.
--
-- Un désaccord ne serait pas forcément une erreur — quatre ans séparent 1995
-- de 1999, la commune a pu rebouger — mais il rend le rattachement
-- indéfendable, et on ne pose pas ce qu'on ne peut pas défendre.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p77_lien;
CREATE TABLE p77_lien AS
SELECT c.*,
       (SELECT m.unit_id FROM membership m
         WHERE m.atom_id = c.atome AND m.niveau = 'canton'
           AND m.periode @> :'jalon_1999'::date LIMIT 1)   AS unit_1999,
       EXISTS (SELECT 1 FROM unit u
                WHERE u.unit_id = c.unit_id AND u.niveau = 'canton') AS unit_connue,
       EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = c.atome AND m.niveau = 'canton'
                  AND m.periode && daterange(c.valid_from,
                                             :'fin_serie'::date, '[)')) AS place_prise,
       NULL::text AS verdict
FROM   p77_mouvement c;

UPDATE p77_lien SET verdict = CASE
    WHEN atome IS NULL                       THEN 'commune sans atome'
    WHEN valid_from IS NULL                  THEN 'sans date d''effet ni de publication'
    WHEN unit_id IS NULL                     THEN 'canton d''arrivée inconnu'
    WHEN NOT unit_connue                     THEN 'unité absente de la nomenclature'
    WHEN unit_1999 IS DISTINCT FROM unit_id  THEN 'le COG 1999 dit un autre canton'
    WHEN valid_from >= :'fin_serie'::date    THEN 'effet postérieur à la fin de série'
    WHEN place_prise                         THEN 'place déjà occupée'
    ELSE                                          'posable'
END;

\echo ''
\echo '-- 4. verdict'
SELECT verdict, count(*) AS mouvements,
       count(*) FILTER (WHERE origine = 'insee')      AS dont_datés_par_l_insee,
       count(*) FILTER (WHERE origine = 'convention') AS dont_sous_convention
FROM   p77_lien GROUP BY verdict ORDER BY mouvements DESC;

\echo ''
\echo '   « place déjà occupée » N''EST PAS UN ÉCHEC : c''est le signe que la'
\echo '   composition du canton d''arrivée était déjà lue, le plus souvent par'
\echo '   `76` — la salve de 1997 qu''il pose est celle qui produit 61 de ces'
\echo '   66 mouvements. Qui occupe la place :'
SELECT m.unit_id AS occupe_par, count(*) AS mouvements,
       min(l.commune) AS un_exemple,
       min(m.valid_from) AS depuis
FROM   p77_lien l
JOIN   membership m ON m.atom_id = l.atome AND m.niveau = 'canton'
                   AND m.periode && daterange(l.valid_from, :'fin_serie'::date, '[)')
WHERE  l.verdict = 'place déjà occupée'
GROUP  BY 1 ORDER BY mouvements DESC LIMIT 12;

\echo ''
\echo '   les désaccords entre le fichier historique et le COG de 1999 —'
\echo '   à regarder un par un, ils accusent une lecture'
SELECT insee, commune, dep, unit_id AS dit_par_l_insee, unit_1999 AS dit_par_le_cog,
       valid_from
FROM   p77_lien WHERE verdict = 'le COG 1999 dit un autre canton' ORDER BY insee;

-- ---------------------------------------------------------------------------
-- 5. La pose
-- ---------------------------------------------------------------------------
-- Les périodes S'ENCHAÎNENT : un mouvement vaut jusqu'au suivant de la même
-- commune, et à défaut jusqu'à la reprise de `24`. C'est la seule façon de
-- poser une commune qui change deux fois de canton sans que la contrainte
-- `membership_non_chevauchant` s'y oppose — et sans inventer de bornes.
DROP TABLE IF EXISTS p77_pose;
CREATE TABLE p77_pose AS
SELECT atome, unit_id, valid_from,
       coalesce(lead(valid_from) OVER (PARTITION BY atome ORDER BY valid_from),
                :'fin_serie'::date)            AS valid_to,
       insee, commune, dep, origine, incertitude_jusqu_au, n_actes
FROM   p77_lien WHERE verdict = 'posable';

-- une période vide n'a pas de sens : elle naîtrait de deux mouvements le même
-- jour vers deux cantons différents, ce qui serait une contradiction
DELETE FROM p77_pose WHERE valid_from >= valid_to;

-- GARDE-FOU 1 : après enchaînement, deux mouvements d'une même commune ne
-- doivent plus se recouvrir. Le garde-fou ne porte plus sur la RÉPÉTITION —
-- une commune a le droit de bouger deux fois — mais sur le CHEVAUCHEMENT, qui
-- seul est impossible.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
      FROM p77_pose a JOIN p77_pose b
           ON a.atome = b.atome AND a.valid_from < b.valid_from
          AND daterange(a.valid_from, a.valid_to, '[)')
           && daterange(b.valid_from, b.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION
          'REFUS : % recouvrement(s) après enchaînement. Rien n''est posé.', n;
    END IF;
END $$;

-- GARDE-FOU 2 : l'ordre de grandeur. 66 mouvements datés plus 2 sous
-- convention ; au-delà de 100 rattachements, la sélection a dérivé.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM p77_pose;
    IF n > 100 THEN
        RAISE EXCEPTION
          'REFUS : % rattachements à poser, très au-delà des 68 mouvements '
          'connus. La sélection a dérivé.', n;
    END IF;
END $$;

\echo ''
\echo '-- 5. à poser'
SELECT count(*) AS rattachements, count(DISTINCT unit_id) AS cantons,
       min(valid_from) AS du, max(valid_from) AS au
FROM   p77_pose;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atome, unit_id, 'canton', valid_from, valid_to FROM p77_pose
    RETURNING membership_id
)
INSERT INTO p77_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

DROP TABLE IF EXISTS p77_qualite;
CREATE TABLE p77_qualite AS
SELECT m.membership_id,
       p.insee, p.commune, p.dep, p.unit_id,
       p.origine,                        -- 'insee' = la date est un fait
       (p.origine <> 'insee')            AS date_conventionnelle,
       p.incertitude_jusqu_au            -- borne haute de l'erreur possible
FROM   membership m
JOIN   p77_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
JOIN   p77_pose  p ON p.atome = m.atom_id AND p.unit_id = m.unit_id
                  AND p.valid_from = m.valid_from;

CREATE INDEX p77_qualite_m_idx ON p77_qualite (membership_id);

ANALYZE membership;
ANALYZE p77_qualite;

\echo ''
\echo '-- 5 bis. posé, par origine de la date'
SELECT origine, count(*) AS rattachements,
       count(*) FILTER (WHERE date_conventionnelle) AS dont_conventionnelles
FROM   p77_qualite GROUP BY origine ORDER BY origine;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. recettes'

\echo ''
\echo '   a. aucun chevauchement introduit (doit valoir 0) :'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode
WHERE  a.niveau = 'canton';

\echo ''
\echo '   b. aucun rattachement au-delà de la reprise de `24` (doit valoir 0) :'
SELECT count(*) AS deborde_1999
FROM   p77_qualite q JOIN membership m USING (membership_id)
WHERE  m.valid_to > :'fin_serie'::date;

\echo ''
\echo '   c. CONTRÔLE CROISÉ — trois de ces mouvements sont aussi connus par le'
\echo '      TEXTE des décrets (Légifrance), qui nomme le canton d''arrivée là'
\echo '      où l''INSEE le code. Les deux lectures se recoupent-elles ?'
-- Le nom se lit dans `unit_version` À LA DATE, par `unit_nom()`, et non dans
-- `unit.nom` — qui est documenté comme « dernier nom connu (dénormalisé,
-- confort) » et porte souvent celui de 1870-1940. Le premier passage sur la
-- vraie base a montré l'écart : pour `3804`, `unit.nom` dit « Bourgoin » quand
-- le décret et le COG disent « Bourgoin-Jallieu - Sud ». Le canton est le bon,
-- c'est le champ lu qui ne l'était pas.
SELECT a.commune,
       a.canton_dest                                  AS nommé_par_le_décret,
       t.canton_arrivee                               AS codé_par_l_insee,
       unit_nom(t.canton_arrivee, t.date_effet)       AS nom_à_la_date,
       u.nom                                          AS nom_dénormalisé,
       t.date_effet
FROM   acte_transfert a
JOIN   transfert_insee t ON t.insee = a.insee
LEFT   JOIN unit u ON u.unit_id = t.canton_arrivee AND u.niveau = 'canton'
ORDER  BY a.insee;

\echo ''
\echo '   d. snapshot aux dates que ce fichier touche'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements,
       (SELECT count(DISTINCT m.unit_id) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS cantons
FROM   (VALUES ('1993-06-01'), ('1995-06-01'), ('1998-06-01'), ('1998-12-01')) v(d)
ORDER  BY 1;

\echo ''
\echo '   e. cohérence de la table de qualité (doit valoir 0) :'
SELECT count(*) AS traces_sans_qualite
FROM   p77_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p77_qualite q
                    WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '============================================================'
\echo ' Les transferts sont posés. Pour la première fois dans ce'
\echo ' chantier, la date de début vient de la source elle-même —'
\echo ' sauf pour deux mouvements de 1993, marqués comme tels dans'
\echo ' p77_qualite, et dont l''erreur possible est bornée.'
\echo '============================================================'

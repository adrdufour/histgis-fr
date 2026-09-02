-- ============================================================================
-- histgis — 66_cog1954_stage.sql : le recensement de 1954 entre en base
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour le \copy
--   psql -d histgis -f sql/66_cog1954_stage.sql
--
-- Ce fichier N'ÉCRIT NI DANS `atom` NI DANS `membership`. C'est la méthode de
-- `20` et de `58` : mesurer la résolution, la noter, écrire ensuite.
--
-- L'ENJEU : UN SECOND JALON DANS LE TROU 1943-1999
-- =================================================
-- `59` a posé le jalon de 1968 — 32 659 rattachements au 1er janvier 1968.
-- Un seul point sur cinquante-six ans. **1954 en donne un second**, quatorze
-- ans plus tôt, et deux points valent bien plus que deux fois un point : entre
-- eux, la stabilité devient vérifiable au lieu d'être supposée.
--
-- CE QUE 1954 A DE DIFFÉRENT, ET QUI A COÛTÉ 7 576 COMMUNES
-- ==========================================================
-- **Le volume de 1954 n'imprime pas le code INSEE.** La jointure passe par le
-- nom, et c'est là que le dépouillement perdait un quart de ses lignes.
--
-- Deux passes l'ont réglé, sans un seul appel à l'OCR :
--
--   `apparie_noms.py`        26 202 codes, correspondance EXACTE et unique,
--                            après reconstruction des formes du nom
--                            (article postposé, « St » déployé, caractère
--                            parasite initial) ;
--   `confirme_par_canton.py`  3 361 de plus, appariements FLOUS confirmés par
--                            le canton — 97 % des jugeables.
--
-- Soit **29 563 lignes sur 31 400 — 94,1 %**.
--
-- La colonne `appariement` dit d'où vient chaque code, et c'est elle qui
-- distingue un fait d'une conjecture :
--
--     ferme               exact et unique
--     ferme_canton        flou, confirmé par un signal indépendant du nom
--     canton_contredit    le canton dément le nom — NON POSÉ
--     canton_indetermine  commune absente de 1940, ou canton illisible
--     exact_collision     deux lignes visent la même commune
--     aucun               rien trouvé
--
-- LES TROIS CANTONS QUE LA NOMENCLATURE NE PEUT PAS CONNAÎTRE
-- ============================================================
-- TRF-GIS s'arrête en 1940. Trois cantons créés entre 1940 et 1954 lui sont
-- donc invisibles — et l'annexe VII de Gaudillère les nomme :
--
--     1930   Brive-Sud     D. 13.9.1951    7 communes lues
--     4630   Sousceyrac    D. 5.9.1949     4 communes lues
--     0631   Tende         D. 10.9.1951    2 communes lues
--
-- **Les trois portent un numéro en FIN de série** — 1930 quand la Corrèze
-- s'arrête à 1929, 4630 quand le Lot s'arrête à 4629, 0631 quand les
-- Alpes-Maritimes s'arrêtent à 0630. C'est le motif exact de Forbach-II en
-- 1968 (5740 pour une série finissant à 5736), et il vaut confirmation
-- croisée : la source les date, la numérotation les situe.
--
-- Ils sont posés par `67_cantons_1949_1951.sql`, pas ici.
--
-- CORRECTION DU 28 AOÛT 2026 — « invisibles » était faux
-- -------------------------------------------------------
-- `67` a créé ZÉRO unité : `INSERT 0 0`. Les trois `unit_id` existaient déjà,
-- apportés par `24_canton_moderne.sql` depuis le COG de 1999. Ils ne sont
-- invisibles qu'à TRF-GIS ; la nomenclature MODERNE les connaît, et le § 4a
-- ci-dessous le disait déjà en ne les listant pas parmi les cantons inconnus.
-- Je ne l'avais pas lu ainsi.
--
-- La conséquence n'est pas nulle : réutiliser `1930` AFFIRME que le Brive-Sud
-- de 1951 est la même unité que le `1930` de 1999, qui s'appelle
-- « Brive-la-Gaillarde-Sud-Est ». `68` § 2 bis confronte les compositions.
--
-- Prérequis : `20_commune_moderne.sql`, `24_canton_moderne.sql`, et les deux
-- passes d'appariement Python. Lecture seule ; crée ses tables `c54_*`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Le recensement de 1954 a été effectué le 10 mai 1954.
\set date_1954 '1954-05-10'

\echo ''
\echo '============================================================'
\echo ' COG 1954 — dépôt et résolution'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Le dépôt brut
--
-- Les colonnes suivent l'ORDRE du CSV : `\copy … WITH (HEADER true)` saute
-- l'en-tête sans le lire, et se fie à l'ordre de la table. Une colonne ajoutée
-- en amont casse le chargement sur un message qui ne dit pas laquelle.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_src CASCADE;
-- `dep` est du TEXTE, pas `char(2)` : la **Seine-et-Oise** y porte le code
-- `78O` sur TROIS caractères. Le département a été éclaté en 1968 entre les
-- Yvelines, l'Essonne, les Hauts-de-Seine, la Seine-Saint-Denis, le
-- Val-de-Marne et le Val-d'Oise, et le dépôt le distingue ainsi du 78 actuel.
-- 576 lignes sont concernées — cf. § 4d.
CREATE TABLE c54_src (
    page            text,
    dep             text,
    dep_nom         text,
    arr             text,
    canton          text,      -- numéro dans le département, 1 ou 2 chiffres
    commune         text,      -- le nom LU, avec ses défauts d'OCR
    pop_1954        text,
    ligne_brute     text,
    entete_heritee  text,
    dep_avant       text,
    insee           text,      -- posé par apparie_noms / confirme_par_canton
    appariement     text,
    insee_propose   text       -- proposition non retenue, conservée
);

\copy c54_src FROM 'cog1954/communes_1954_redecoupe.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 1. dépôt'
SELECT count(*)                                    AS lignes,
       count(*) FILTER (WHERE insee <> '')         AS avec_code,
       count(DISTINCT nullif(insee, ''))           AS communes,
       count(DISTINCT dep)                         AS departements
FROM   c54_src;

\echo ''
\echo '-- 1 bis. par qualité d''appariement'
SELECT appariement, count(*),
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   c54_src GROUP BY appariement ORDER BY count(*) DESC;

-- ---------------------------------------------------------------------------
-- 2. Contrôles préalables
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    IF to_regclass('histgis.cm_commune') IS NULL
       OR to_regclass('histgis.cm_atome') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20_commune_moderne.sql.';
    END IF;

    -- La Seine-et-Oise est écartée du contrôle : son code `78O` ne peut par
    -- construction correspondre à aucun préfixe de code INSEE moderne.
    SELECT count(*) INTO n FROM c54_src
     WHERE insee <> '' AND dep <> '78O' AND left(insee, 2) <> dep;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % lignes dont le code contredit le département.', n;
    END IF;

    -- `flou_collision` et `homonyme` viennent de `seine_et_oise.py` : le
    -- premier marque un appariement flou dont la cible était déjà prise par un
    -- exact, le second un nom que plusieurs communes du vivier portent.
    SELECT count(*) INTO n FROM c54_src
     WHERE appariement NOT IN ('ferme', 'ferme_canton', 'canton_contredit',
                               'canton_indetermine', 'exact_collision',
                               'flou_collision', 'homonyme', 'aucun');
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % lignes au statut d''appariement inconnu (%).',
            n, (SELECT string_agg(DISTINCT appariement, ', ') FROM c54_src
                 WHERE appariement NOT IN ('ferme', 'ferme_canton',
                     'canton_contredit', 'canton_indetermine',
                     'exact_collision', 'flou_collision', 'homonyme',
                     'aucun'));
    END IF;

    RAISE NOTICE 'Contrôle préalable : les deux assertions passent.';
END $$;

-- ---------------------------------------------------------------------------
-- 3. Résolution
--
-- Deux jointures indépendantes, comme pour 1968 : la COMMUNE existait-elle au
-- 10 mai 1954 et quel atome la porte, le CANTON est-il une unité connue.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c54_lien;
CREATE TABLE c54_lien AS
SELECT s.dep,
       s.insee,
       s.commune                                          AS nom_lu,
       s.canton,
       -- La Seine-et-Oise est lue `78O` mais ses cantons sont `78xx` dans la
       -- base : `78O` || `26` donnerait `78O26`, qui n'existe pas.
       CASE WHEN s.dep = '78O' THEN '78' ELSE s.dep END
         || lpad(s.canton, 2, '0')                        AS canton_id,
       s.appariement,
       EXISTS (SELECT 1 FROM cm_commune c
                WHERE c.code = s.insee
                  AND daterange(c.valid_from, c.valid_to, '[)')
                      @> :'date_1954'::date)              AS commune_vivante,
       a.atome,
       a.n_atomes,
       EXISTS (SELECT 1 FROM unit u
                WHERE u.unit_id = CASE WHEN s.dep = '78O' THEN '78'
                                       ELSE s.dep END
                                  || lpad(s.canton, 2, '0')
                  AND u.niveau = 'canton')                AS canton_connu
FROM   c54_src s
-- `cm_atome` est une UNION ALL : un code peut y avoir plusieurs atomes. Un
-- LEFT JOIN nu dupliquerait les lignes en silence — la faute évitée dans `58`.
LEFT   JOIN LATERAL (
           SELECT min(x.atom_id) AS atome, count(DISTINCT x.atom_id) AS n_atomes
           FROM   cm_atome x WHERE x.code = s.insee
       ) a ON true
WHERE  s.insee <> '';

CREATE INDEX c54_lien_insee_idx  ON c54_lien (insee);
CREATE INDEX c54_lien_canton_idx ON c54_lien (canton_id);

\echo ''
\echo '-- 3. résolution, par classe'
SELECT commune_vivante,
       atome IS NOT NULL AS a_un_atome,
       canton_connu,
       count(*) AS lignes, count(DISTINCT insee) AS communes
FROM   c54_lien GROUP BY 1, 2, 3 ORDER BY lignes DESC;

\echo ''
\echo '   la classe pleinement résolue :'
SELECT count(*) AS lignes, count(DISTINCT insee) AS communes,
       count(DISTINCT atome) AS atomes, count(DISTINCT canton_id) AS cantons
FROM   c54_lien
WHERE  commune_vivante AND atome IS NOT NULL AND canton_connu AND n_atomes = 1;

\echo ''
\echo '-- 3 bis. croisé avec la qualité de l''appariement'
SELECT appariement, count(*) AS lignes,
       count(*) FILTER (WHERE commune_vivante AND atome IS NOT NULL
                          AND canton_connu)                       AS resolues,
       round(100.0 * count(*) FILTER (WHERE commune_vivante
                                        AND atome IS NOT NULL
                                        AND canton_connu) / count(*), 1) AS pct
FROM   c54_lien GROUP BY appariement ORDER BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 4. Les cantons inconnus — les trois créations, et le reste
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4a. cantons cités par 1954 et inconnus de la nomenclature'
SELECT canton_id, count(*) AS lignes,
       string_agg(nom_lu, ', ' ORDER BY insee) AS composition
FROM   c54_lien WHERE NOT canton_connu
GROUP  BY canton_id HAVING count(*) >= 2
ORDER  BY lignes DESC;

\echo ''
\echo '   Les trois premiers sont datés par l''annexe VII de Gaudillère :'
\echo '     1930 Brive-Sud (1951), 4630 Sousceyrac (1949), 0631 Tende (1951).'
\echo '   Ils portent un numéro en FIN de série — le motif de Forbach-II.'
\echo '   Les autres, cités une ou deux fois, sont des cantons mal lus.'

\echo ''
SELECT count(DISTINCT canton_id) AS cantons_inconnus, count(*) AS lignes
FROM   c54_lien WHERE NOT canton_connu;

\echo ''
\echo '-- 4b. communes que cm_commune ne connaît pas vivantes en 1954'
SELECT dep, count(*) AS lignes, min(insee) AS exemple, min(nom_lu) AS nom
FROM   c54_lien WHERE NOT commune_vivante
GROUP  BY dep ORDER BY lignes DESC LIMIT 12;

\echo ''
\echo '-- 4d. la Seine-et-Oise, un cas à part'
SELECT count(*)                             AS lignes,
       count(*) FILTER (WHERE insee <> '')  AS avec_un_code
FROM   c54_src WHERE dep = '78O';

\echo ''
\echo '   RÉGLÉ le 28 août 2026 par `69_pont_seine_et_oise.sql` et'
\echo '   `cog1954/seine_et_oise.py`. Ces 576 lignes étaient toutes classées'
\echo '   `aucun` — un tiers des sans-piste — parce qu''`apparie_noms.py`'
\echo '   cherche le nom DANS LE DÉPARTEMENT LU et que `78O` n''est dans aucun'
\echo '   référentiel. Le piège suivant était pire : les codes MODERNES'
\echo '   (91, 92, 93, 94, 95) n''existent pas en 1954, et les poser aurait'
\echo '   donné `commune_vivante = false` sur toute la série, sans erreur.'
\echo '   Le pont passe par l''ATOME, qui ne change pas quand l''INSEE'
\echo '   renumérote. `avec_un_code` doit valoir 556 sur 576.'

\echo ''
\echo '-- 4c. vérification que la jointure n''a pas dupliqué'
SELECT (SELECT count(*) FROM c54_src WHERE insee <> '') AS deposees,
       (SELECT count(*) FROM c54_lien)                  AS resolues,
       CASE WHEN (SELECT count(*) FROM c54_src WHERE insee <> '')
               = (SELECT count(*) FROM c54_lien)
            THEN 'identiques — pas de duplication'
            ELSE 'DIVERGENCE' END AS verdict;

-- ---------------------------------------------------------------------------
-- 5. L'apport, et le conflit éventuel
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. couverture actuelle de la date, et apport'
SELECT
  (SELECT count(DISTINCT m.atom_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'date_1954'::date)
                                                    AS atomes_deja_rattaches,
  (SELECT count(DISTINCT atome) FROM c54_lien
    WHERE atome IS NOT NULL AND canton_connu AND commune_vivante)
                                                    AS atomes_posables;

\echo ''
\echo '   `atomes_deja_rattaches` vaut 0 au PREMIER passage : le membership'
\echo '   cantonal s''arrête en 1941 et ne reprend qu''en 1968 depuis `59`.'
\echo '   Au rejeu il vaut ce que `68` a posé la fois précédente — `68` § 1'
\echo '   défait sa propre trace avant de réécrire, donc ce n''est pas un'
\echo '   conflit. Ce qu''il faut lire ici est `atomes_posables`.'

-- ---------------------------------------------------------------------------
-- 6. LA MESURE QUI JUSTIFIE TOUT — 1954 confronté à 1968
--
-- Deux jalons distants de quatorze ans, tous deux lus par nous. Leur accord
-- mesure la stabilité cantonale de l'intervalle — et c'est précisément ce que
-- le trou 1943-1999 empêchait de savoir.
--
-- Ce n'est PAS une recette : un désaccord peut venir d'un vrai changement
-- comme d'une erreur de lecture. Mais un accord ÉLEVÉ, département par
-- département, autoriserait à relier les deux jalons — ce qu'aucune source ne
-- permet aujourd'hui.
--
-- LA JOINTURE PASSE PAR L'ATOME, PAS PAR LE CODE — corrigé le 28 août 2026
-- ------------------------------------------------------------------------
-- La première version joignait sur `insee`. Elle marchait pour 88 départements
-- et **excluait silencieusement la Seine-et-Oise et la Seine** : 1968 les code
-- en moderne (`95008`), 1954 en numérotation d'époque (`78008`). Deux lignes
-- décrivant la même commune n'y étaient jamais rapprochées.
--
-- L'atome, lui, est le même aux deux dates — c'est sa raison d'être. On exige
-- `n_atomes = 1` des deux côtés : un code qui résout à plusieurs atomes rendrait
-- la comparaison ambiguë, et un dénominateur douteux vaut moins qu'un
-- dénominateur plus petit.
--
-- … ET LE CANTON NON PLUS N'A PAS LE MÊME NOM AUX DEUX DATES
-- -----------------------------------------------------------
-- Le correctif ci-dessus a rendu les deux départements disparus comparables, et
-- ils sont ressortis à **0,0 %** sur 406 communes. Ce n'est pas un désaccord :
-- c'est le MÊME défaut, un cran plus haut.
--
-- 1954 désigne un canton de Seine-et-Oise par `78` + son numéro ; 1968 le lit
-- dans le fascicule du département SUCCESSEUR et l'appelle `95nn`, `91nn`,
-- `78nn`… Les deux identifiants ne peuvent jamais coïncider, quelle que soit la
-- réalité du terrain. *J'ai corrigé la numérotation des communes sans voir que
-- celle des cantons posait exactement la même question.*
--
-- Un 0,0 % qui porte sur la totalité d'un département n'est jamais une mesure :
-- c'est une incompatibilité de définitions. Les deux départements sont donc
-- ÉCARTÉS de cette comparaison, et traités à part au § 6 ter — par la seule
-- voie que leurs identifiants autorisent, la comparaison des PARTITIONS.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. accord entre le canton de 1954 et celui de 1968 (INDICATIF)'
SELECT count(*)                                                  AS comparables,
       count(*) FILTER (WHERE l.canton_id = j.canton_id)         AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE l.canton_id = j.canton_id)
             / nullif(count(*), 0), 1)                           AS pct
FROM  (SELECT DISTINCT atome, canton_id, dep FROM c54_lien
        WHERE appariement IN ('ferme', 'ferme_canton')
          AND commune_vivante AND canton_connu AND n_atomes = 1
          AND dep NOT IN ('78O', '75')) l
JOIN  (SELECT DISTINCT atome, canton_id FROM c68_lien
        WHERE commune_vivante AND canton_connu AND n_atomes = 1) j
       ON j.atome = l.atome;

\echo ''
\echo '-- 6 bis. le même accord par département — les 20 plus faibles'
SELECT l.dep, count(*) AS communes,
       count(*) FILTER (WHERE l.canton_id = j.canton_id) AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE l.canton_id = j.canton_id)
             / nullif(count(*), 0), 1)                   AS pct
FROM  (SELECT DISTINCT atome, canton_id, dep FROM c54_lien
        WHERE appariement IN ('ferme', 'ferme_canton')
          AND commune_vivante AND canton_connu AND n_atomes = 1
          AND dep NOT IN ('78O', '75')) l
JOIN  (SELECT DISTINCT atome, canton_id FROM c68_lien
        WHERE commune_vivante AND canton_connu AND n_atomes = 1) j
       ON j.atome = l.atome
GROUP  BY l.dep ORDER BY pct LIMIT 20;

\echo ''
\echo '   La Seine-et-Oise (`78O`) et la Seine (`75`) sont ÉCARTÉES : leurs'
\echo '   cantons n''ont pas le même identifiant aux deux dates, et le 0,0 %'
\echo '   qu''elles affichaient ne mesurait rien. Voir le § 6 ter.'

-- ---------------------------------------------------------------------------
-- 6 ter. LES DEUX DÉPARTEMENTS DISPARUS — comparer des PARTITIONS
--
-- Leurs cantons n'ont pas d'identifiant commun aux deux dates, donc « même
-- canton ? » n'a pas de sens. Mais « ces deux communes sont-elles ENSEMBLE ? »
-- en a un, et il ne dépend d'aucune nomenclature : c'est une propriété du
-- découpage, pas de son étiquetage.
--
-- On compare donc, pour chaque PAIRE de communes lues aux deux dates :
--
--     ensemble_aux_deux_dates   la paire est dans un même canton en 1954 ET
--                               en 1968 — le découpage local n'a pas bougé
--     separees_en_1968          ensemble en 1954, séparées en 1968
--     reunies_en_1968           séparées en 1954, ensemble en 1968
--
-- Le taux qui compte est `ensemble_aux_deux_dates` rapporté aux paires
-- ensemble en 1954 : c'est la part du découpage de 1954 que 1968 conserve.
--
-- **Cette mesure n'est disponible NULLE PART ailleurs** : c'est la seule façon
-- de confronter deux lectures dont les étiquettes sont incomparables.
--
-- ELLE EST CALCULÉE POUR TOUS LES DÉPARTEMENTS, ET C'EST LE POINT
-- ----------------------------------------------------------------
-- Le premier jet ne la calculait que pour `78O` et `75`, et sortait 46,4 % et
-- 10,0 %. Ces deux nombres n'étaient **pas interprétables** : je les invitais à
-- se comparer aux 93 % du § 6, qui ne mesurent pas la même chose. Une part de
-- paires conservées et une part de communes au même canton ne vivent pas sur la
-- même échelle, et rien ne dit qu'un découpage inchangé donnerait 93 % ici.
--
-- *Une mesure sans échelle n'est pas une mesure.* On la calcule donc partout :
-- les 88 autres départements fournissent la référence, et la région parisienne
-- se lit dans une distribution au lieu d'être jugée contre un chiffre étranger.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6 ter. accord des PARTITIONS — la mesure qui ignore les étiquettes'
DROP TABLE IF EXISTS c54_partition;
CREATE TABLE c54_partition AS
WITH aux_deux AS (
    SELECT l.atome, l.dep, l.canton_id AS c54, j.canton_id AS c68
    FROM  (SELECT DISTINCT atome, canton_id, dep FROM c54_lien
            WHERE appariement IN ('ferme', 'ferme_canton')
              AND commune_vivante AND canton_connu AND n_atomes = 1) l
    JOIN  (SELECT DISTINCT atome, canton_id FROM c68_lien
            WHERE commune_vivante AND canton_connu AND n_atomes = 1) j
           ON j.atome = l.atome
)
SELECT x.dep,
       count(*) FILTER (WHERE x.c54 = y.c54)                    AS ensemble_1954,
       count(*) FILTER (WHERE x.c54 = y.c54 AND x.c68 = y.c68)  AS encore_ensemble,
       count(*) FILTER (WHERE x.c54 = y.c54 AND x.c68 <> y.c68) AS separees_en_1968,
       count(*) FILTER (WHERE x.c54 <> y.c54 AND x.c68 = y.c68) AS reunies_en_1968
FROM   aux_deux x JOIN aux_deux y ON y.dep = x.dep AND y.atome > x.atome
GROUP  BY x.dep;

\echo ''
\echo '   national, puis les 12 départements les plus bas :'
SELECT 'FRANCE'                                     AS dep,
       sum(ensemble_1954)                           AS ensemble_1954,
       sum(encore_ensemble)                         AS encore_ensemble,
       round(100.0 * sum(encore_ensemble)
             / nullif(sum(ensemble_1954), 0), 1)    AS pct_conserve
FROM   c54_partition
UNION ALL
SELECT dep, ensemble_1954, encore_ensemble,
       round(100.0 * encore_ensemble / nullif(ensemble_1954, 0), 1)
FROM  (SELECT * FROM c54_partition
        ORDER BY encore_ensemble::numeric / nullif(ensemble_1954, 0)
        LIMIT 12) x
ORDER  BY 4;

\echo ''
\echo '   `pct_conserve` = part des paires de communes réunies dans un même'
\echo '   canton en 1954 qui le sont encore en 1968. La ligne FRANCE donne'
\echo '   l''échelle ; sans elle, les chiffres de `78O` et `75` ne voulaient'
\echo '   rien dire. Un département très bas a été REDÉCOUPÉ, ce que la mesure'
\echo '   ordinaire du § 6 ne sait pas distinguer d''une nomenclature changée.'

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans atom ni membership.'
\echo ' Noter ces chiffres avant de jouer 67 puis 68.'
\echo '============================================================'

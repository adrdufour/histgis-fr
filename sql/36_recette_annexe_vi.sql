-- ============================================================================
-- histgis — 36_recette_annexe_vi.sql : la couche circonscriptions confrontée
--                                      à l'annexe VI de Gaudillère
--
--   psql -d histgis -f 36_recette_annexe_vi.sql
--
-- Pourquoi cette recette est différente des autres
-- ------------------------------------------------
-- Toutes les recettes du projet mesurent une COHÉRENCE : la couverture boucle,
-- les effectifs s'équilibrent, les unions valent le tout. Aucune ne peut dire
-- si la couche est EXACTE, parce qu'aucune ne dispose d'un dehors.
--
-- L'annexe VI en fournit un. Son § 5 énumère les cantons répartis entre
-- plusieurs circonscriptions — c'est-à-dire les endroits où une circonscription
-- n'est PAS une union de cantons entiers. Notre couche 1986, posée depuis le
-- tableau du ministère de l'Intérieur, doit présenter exactement ces
-- exceptions-là et aucune autre.
--
-- C'est une assertion falsifiable établie par un tiers, sur la couche qui
-- n'avait jusqu'ici pour tout contrôle externe que les 7 arrondissements de
-- Marseille.
--
-- Ce que l'annexe exclut, et qu'il faut donc exclure aussi
-- --------------------------------------------------------
-- « Les exclusions du paragraphe 3 valent aussi pour les cantons divisés :
-- Paris, petite couronne, Lyon, Marseille. » Ces quatre ensembles se
-- définissent sur les arrondissements ou les communes, pas sur les cantons.
--
-- ATTENTION : la liste ci-dessous est transcrite depuis des photographies de
-- l'ouvrage. À relire sur l'original avant de conclure quoi que ce soit d'un
-- désaccord — une erreur de transcription produirait un faux défaut.
--
-- Prérequis : 28_circo_1986.sql (table circo86_src).
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' RECETTE — CANTONS DIVISÉS, ANNEXE VI § 5, DÉCOUPAGE 1986'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Ce que l'annexe annonce
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS av_attendu;
CREATE TEMP TABLE av_attendu (dep char(2), canton text, mention text);
INSERT INTO av_attendu VALUES
    ('11', 'Mas-Cabardès',       '1985'),
    ('13', 'Istres',             '1986'),
    ('13', 'Salon-de-Provence',  '1986'),
    ('14', 'Lisieux-1',          '1986'),
    ('17', 'Saintes-Est',        '1986'),
    ('26', 'Loriol-sur-Drôme',   '1986'),
    ('31', 'Muret',              '1986'),
    ('62', 'Houdain',            '1958-1986');

\echo ''
\echo '=== 1. Ce que l''annexe VI annonce pour 1986 ==='
SELECT dep, canton, mention FROM av_attendu ORDER BY dep, canton;

-- ---------------------------------------------------------------------------
-- 2. Ce que notre couche 1986 présente
-- ---------------------------------------------------------------------------
-- Un canton est « divisé » si ses communes ne tombent pas toutes dans la même
-- circonscription. On travaille sur la composition cantonale de 1940, faute de
-- nomenclature cantonale de 1986 — c'est la limite du test, et elle joue
-- CONTRE nous : un canton remanié entre 1940 et 1986 apparaîtra divisé à tort.
-- Un accord malgré ce handicap n'en aurait que plus de valeur.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Ce que la couche presente ==='
\echo '    Reserve : la composition cantonale utilisee est celle de 1940. Un'
\echo '    canton remanie entre 1940 et 1986 sortira divise a tort. Ce biais'
\echo '    ne peut que produire des faux positifs, jamais des faux negatifs.'

DROP TABLE IF EXISTS av_constate;
CREATE TEMP TABLE av_constate AS
WITH compo AS (
    SELECT DISTINCT a.insee_geofla AS insee, m.unit_id AS canton,
           coalesce(uv.nom, u.nom) AS nom_canton,
           left(a.insee_geofla, 2) AS dep
    FROM   membership m
    JOIN   atom a ON a.atom_id = m.atom_id
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
    LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id
                               AND uv.periode @> '1940-06-01'::date
    WHERE  m.niveau = 'canton' AND m.periode @> '1940-06-01'::date
      AND  a.insee_geofla IS NOT NULL
)
SELECT c.dep, c.canton, max(c.nom_canton) AS nom_canton,
       count(DISTINCT c.insee)  AS communes,
       count(DISTINCT s.circo)  AS n_circos,
       string_agg(DISTINCT s.circo, ' / ' ORDER BY s.circo) AS circos
FROM   compo c
JOIN   circo86_src s ON s.insee = c.insee
GROUP  BY c.dep, c.canton
HAVING count(DISTINCT s.circo) > 1;

SELECT count(*) AS cantons_divises_constates FROM av_constate;

-- ---------------------------------------------------------------------------
-- 3. La confrontation
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- 3. LE RÉSULTAT QUI COMPTE : combien de cantons ont bougé
-- ---------------------------------------------------------------------------
-- Le § 2 sort un ordre de grandeur au-dessus de ce que l'annexe annonce. Ce
-- n'est pas un échec du test, c'est un renversement de ce qu'il mesure.
--
-- Si les cantons de 1940 valaient encore en 1986, la couche présenterait les
-- huit divisions de l'annexe et rien d'autre. Chaque canton divisé en plus est
-- un canton assez remanié entre 1940 et 1986 pour chevaucher une limite de
-- circonscription.
--
-- C'est donc une BORNE INFÉRIEURE du nombre de cantons modifiés pendant le
-- trou 1941-1998 — inférieure, parce qu'un canton peut avoir été remanié sans
-- pour autant traverser une limite de circonscription.
--
-- Première mesure de l'ampleur du trou. Jusqu'ici on savait qu'il existait,
-- pas ce qu'il contenait.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Combien de cantons de 1940 ont bouge avant 1986 ==='
\echo '    Borne INFERIEURE : un canton remanie sans traverser de limite de'
\echo '    circonscription reste invisible a ce test.'

SELECT (SELECT count(DISTINCT m.unit_id)
        FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
        WHERE  m.niveau = 'canton' AND m.periode @> '1940-06-01'::date
          AND  a.insee_geofla IS NOT NULL)              AS cantons_1940,
       (SELECT count(*) FROM av_constate)               AS divises_constates,
       (SELECT count(*) FROM av_attendu)                AS divises_annonces,
       (SELECT count(*) FROM av_constate)
         - (SELECT count(*) FROM av_attendu)            AS remanies_au_moins,
       round(100.0 * ((SELECT count(*) FROM av_constate)
                      - (SELECT count(*) FROM av_attendu))
             / nullif((SELECT count(DISTINCT m.unit_id)
                       FROM membership m JOIN atom a ON a.atom_id = m.atom_id
                       WHERE m.niveau = 'canton'
                         AND m.periode @> '1940-06-01'::date
                         AND a.insee_geofla IS NOT NULL), 0), 1) AS pct;

\echo ''
\echo '=== 4. Ou se concentre le remaniement ==='
\echo '    Un departement fortement urbanise a plus bouge. La distribution'
\echo '    dit par ou commencer le depouillement.'
SELECT dep, count(*) AS cantons_divises,
       left(string_agg(nom_canton, ', ' ORDER BY nom_canton), 70) AS exemples
FROM   av_constate
WHERE  dep NOT IN ('75', '92', '93', '94')
GROUP  BY dep ORDER BY 2 DESC, 1 LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. Les huit cantons de l'annexe, un par un
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Les huit divisions annoncees par l''annexe ==='
SELECT a.dep, a.canton, a.mention,
       CASE WHEN c.canton IS NULL THEN 'ABSENT de notre couche'
            ELSE 'present' END AS verdict,
       c.n_circos, c.communes, left(c.circos, 40) AS circos
FROM   av_attendu a
LEFT   JOIN av_constate c
       ON  c.dep = a.dep
       -- Le nom peut être tronqué d'un côté ou de l'autre : la base porte les
       -- noms courts d'époque — « Salon » pour Salon-de-Provence, « Bourg »
       -- pour Bourg-en-Bresse — quand l'annexe porte le nom long. On accepte
       -- donc le préfixe dans les DEUX sens.
       AND (unaccent(lower(c.nom_canton)) LIKE unaccent(lower(a.canton)) || '%'
         OR unaccent(lower(a.canton))     LIKE unaccent(lower(c.nom_canton)) || '%')
ORDER  BY a.dep, a.canton;

\echo ''
\echo '=== 6. Noms de cantons mal encodes ==='
\echo '    Repere dans le § 4 : « Orl??ans » a cote de « Orleans ». Un meme'
\echo '    canton sous deux graphies dont une cassee dedouble tout comptage'
\echo '    par nom et fait echouer tout appariement.'
SELECT u.unit_id, u.niveau, u.nom, uv.nom AS nom_version, uv.periode
FROM   unit u LEFT JOIN unit_version uv ON uv.unit_id = u.unit_id
WHERE  u.nom ~ '[^[:print:][:space:]éèêëàâäîïôöûüùçÉÈÊËÀÂÄÎÏÔÖÛÜÙÇœŒ''’ -]'
   OR  uv.nom ~ '[^[:print:][:space:]éèêëàâäîïôöûüùçÉÈÊËÀÂÄÎÏÔÖÛÜÙÇœŒ''’ -]'
ORDER  BY 1 LIMIT 40;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    Le § 3 porte le resultat : l''ecart entre ce que l''annexe annonce'
\echo '    et ce que la couche presente n''est pas du bruit, c''est la mesure'
\echo '    du remaniement cantonal 1940-1986. Borne inferieure.'
\echo ''
\echo '    Le § 5 teste ce qui reste testable : les huit cantons annonces'
\echo '    doivent tous etre presents. Un ABSENT serait un vrai defaut de la'
\echo '    couche circonscriptions — ou un canton renomme entre 1940 et 1986,'
\echo '    que l''appariement par nom rate.'
\echo ''
\echo '    Ce que ce script NE peut pas faire : valider la couche 1986. Il y'
\echo '    faudrait la nomenclature cantonale de 1986, qui est precisement ce'
\echo '    qui manque. Le controle externe de la couche circonscriptions reste'
\echo '    a construire — les paragraphes 1, 3, 4 et 6 de l''annexe VI s''y'
\echo '    pretent mieux, car ils ne dependent pas des cantons.'
\echo ''
\echo 'Rappel : la liste attendue est transcrite depuis des photographies.'
\echo 'Verifier sur l''original avant de conclure a un defaut.'

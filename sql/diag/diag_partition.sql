-- ============================================================================
-- histgis — diag_partition.sql : interroger la trame nettoyée SANS la recalculer
--
--     psql -d histgis -v date=1870-12-01 -f sql/diag/diag_partition.sql
--     psql -d histgis -f sql/diag/diag_partition.sql            # 1870-12-01 par défaut
--
-- POURQUOI CE FICHIER EXISTE
-- --------------------------
-- `carte_partition_atome(date)` boucle sur les 90 départements et met plusieurs
-- minutes. Chaque question posée séparément — nommer les replis, décomposer une
-- emprise, compter les atomes — la relançait en entier. Trois questions, trois
-- fois le calcul, et rien qui les relie.
--
-- Ici la partition est matérialisée UNE FOIS dans une table temporaire, puis
-- interrogée autant de fois qu'on veut. La table meurt avec la session : c'est
-- un diagnostic, pas une couche. *Ce qui coûte des minutes ne se demande pas
-- une question à la fois.*
--
-- LECTURE SEULE, comme tous les `diag_*.sql` du dépôt. Rien n'est écrit.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

\timing on
\echo ''
\echo '--- Calcul de la partition (une seule fois, plusieurs minutes) ----------'

DROP TABLE IF EXISTS d84;
CREATE TEMP TABLE d84 AS
SELECT DISTINCT ON (c.atom_id)
       c.atom_id, c.geom, c.source, c.motif,
       a.insee_geofla, a.fraction,
       (SELECT min(u.dep)
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.atom_id = c.atom_id AND m.periode @> :'date'::date) AS dep
FROM   carte_partition_atome(:'date'::date) c
JOIN   atom a ON a.atom_id = c.atom_id
ORDER  BY c.atom_id, c.source;

CREATE INDEX ON d84 USING gist (geom);
CREATE INDEX ON d84 (atom_id);
CREATE INDEX ON d84 (source);
ANALYZE d84;
\timing off

\echo ''
\echo '=== 1. Les replis GEOFLA résiduels, nommés un par un ===================='
\echo '    Ce qui reste de la trame de 2011 dans la carte nettoyée. Les six'
\echo '    doublons du § 8 de 82 — Sebrazac, Venaco, L''Aubépin, Fonteny,'
\echo '    Saint-Hubert, La Salvetat-Belmontet — devraient figurer ici.'
\echo ''

SELECT d.dep,
       d.atom_id,
       d.insee_geofla,
       coalesce(n.nom, g.nom_comm, '[' || d.insee_geofla || ']') AS nom,
       CASE WHEN d.fraction THEN 'fraction' ELSE '' END          AS quoi,
       round((ST_Area(d.geom) / 1e6)::numeric, 2)                AS km2
FROM   d84 d
LEFT   JOIN noms_geofla n ON n.insee = d.insee_geofla
LEFT   JOIN geofla_commune g ON g.insee_com = d.insee_geofla
WHERE  d.source = 'repli'
ORDER  BY d.dep, 4;

\echo ''
\echo '=== 2. Ce que ces replis ont en commun =================================='
\echo '    `jamais_anr` = ANR ne le pourvoit à AUCUNE date : aucune reprise'
\echo '    n''est possible, c''est une limite de la source. `pas_de_mere` = ANR'
\echo '    le pourvoit ailleurs mais aucun voisin ne se coupe à sa réapparition'
\echo '    — celui-là est à regarder, c''est peut-être la règle qui manque.'
\echo ''

SELECT CASE
         WHEN d.fraction THEN 'fraction (attendu)'
         WHEN NOT EXISTS (SELECT 1 FROM atom_geom_anr g WHERE g.atom_id = d.atom_id)
              THEN 'jamais pourvu par ANR'
         WHEN NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                          WHERE g.atom_id = d.atom_id
                            AND lower(g.periode) > :'date'::date)
              THEN 'pourvu avant seulement, pas de réapparition'
         ELSE 'réapparaît, mais pas de mère trouvée'
       END                                    AS cas,
       count(*)                               AS n,
       round((sum(ST_Area(d.geom)) / 1e6)::numeric, 1) AS km2
FROM   d84 d
WHERE  d.source = 'repli'
GROUP  BY 1
ORDER  BY 2 DESC;

\echo ''
\echo '=== 3. D''où vient la géométrie, et combien de sol chacune porte ========'

SELECT d.source,
       count(*)                                        AS atomes,
       round((sum(ST_Area(d.geom)) / 1e6)::numeric, 1) AS km2
FROM   d84 d
GROUP  BY d.source
ORDER  BY 2 DESC;

\echo ''
\echo '=== 4. Le motif d''arbitrage dominant, par atome ========================'
\echo '    ATTENTION À LA COLONNE km2 : c''est la surface TOTALE des atomes'
\echo '    concernés, PAS la surface arbitrée. Un atome de 20 km² dont une'
\echo '    lisière de 2 ha a été comblée pèse 20 dans la ligne `comblement`.'
\echo '    Cette colonne ne dit donc rien de ce que le comblement a ajouté —'
\echo '    la première version de ce fichier prétendait le contraire, et c''est'
\echo '    le § 7 qui répond à cette question-là.'
\echo ''

SELECT d.motif,
       count(*)                                        AS atomes,
       round((sum(ST_Area(d.geom)) / 1e6)::numeric, 1) AS km2_des_atomes
FROM   d84 d
GROUP  BY d.motif
ORDER  BY 2 DESC;

\echo ''
\echo '=== 5. L''écart de comptage : 38 129 ici, 38 331 au banc ================'
\echo '    Les trois lignes ne comptent pas la même chose. La différence entre'
\echo '    la première et la troisième est le seul écart à expliquer ; le banc,'
\echo '    lui, comptait les rattachements exportés, ce qui est encore autre'
\echo '    chose et ne se compare pas terme à terme.'
\echo ''
\echo '    LIBELLÉ DE LA DERNIÈRE LIGNE CORRIGÉ LE 5 SEPTEMBRE 2026. Il disait'
\echo '    « vivants SANS aucune géométrie — les vrais absents », ce qui est'
\echo '    faux : la requête compte les atomes ABSENTS DE `d84`, c''est-à-dire'
\echo '    du RÉSULTAT de la partition. `diag_sans_geometrie.sql` cherche les'
\echo '    vivants sans aucune géométrie — ni atom_geom, ni ANR à la date — et'
\echo '    en trouve ZÉRO. Les 318 ont tous de quoi être dessinés ; ce qui leur'
\echo '    manque est une FACE. C''est le § 8 qui les nomme, et c''est la même'
\echo '    confusion que son titre portait jusqu''à ce jour, une section plus'
\echo '    loin dans le même fichier.'
\echo ''

SELECT 'atomes vivants à la date' AS quoi, count(DISTINCT m.atom_id) AS n
FROM   membership m WHERE m.periode @> :'date'::date
UNION ALL
SELECT 'dont pourvus d''une géométrie (ANR, reprise ou repli)', count(*)
FROM   d84
UNION ALL
SELECT 'dont non-fraction', count(*) FROM d84 WHERE NOT fraction
UNION ALL
SELECT 'vivants ABSENTS DU RÉSULTAT de la partition (≠ sans géométrie)',
       count(DISTINCT m.atom_id)
FROM   membership m
WHERE  m.periode @> :'date'::date
  AND  NOT EXISTS (SELECT 1 FROM d84 d WHERE d.atom_id = m.atom_id);

\echo ''
\echo '=== 6. Emprise, comparée à la trame brute à la même date ================'
\echo '    L''emprise de 84 doit dépasser celle d''ANR d''à peu près ce que le'
\echo '    comblement a ajouté, et pas davantage.'
\echo ''

SELECT 'partition 84, hors fraction' AS quoi,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 0) AS km2
FROM   d84 WHERE NOT fraction
UNION ALL
SELECT 'somme des polygones ANR à la date',
       round((sum(ST_Area(ga.geom)) / 1e6)::numeric, 0)
FROM   atom_geom_anr ga WHERE ga.periode @> :'date'::date
UNION ALL
SELECT 'étalon GEOFLA 2014 cantons, Lambert-93 projeté', 548489;

\echo ''
\echo '=== 7. Ce que le nettoyage a réellement déplacé, atome par atome ========'
\echo '    La seule mesure qui réponde : la surface de chaque atome APRÈS la'
\echo '    partition, moins celle qu''il avait AVANT — c''est-à-dire sous'
\echo '    `coalesce(ANR à la date, atom_geom)`, exactement ce que la carte'
\echo '    dessinait. Les gains somment ce que le comblement et les reprises'
\echo '    ont ajouté, les pertes ce que la couture a retiré, et l''écart des'
\echo '    deux doit valoir l''écart d''emprise du § 6.'
\echo ''

WITH avant AS (
    SELECT d.atom_id, d.source, d.fraction,
           ST_Area(d.geom)                       AS ap,
           ST_Area(coalesce(ga.geom, ag.geom))   AS av
    FROM   d84 d
    LEFT   JOIN atom_geom_anr ga
           ON ga.atom_id = d.atom_id AND ga.periode @> :'date'::date
    LEFT   JOIN atom_geom ag ON ag.atom_id = d.atom_id
    WHERE  NOT d.fraction
)
SELECT CASE WHEN ap - av >  1000 THEN 'a gagné du sol'
            WHEN ap - av < -1000 THEN 'a perdu du sol'
            ELSE 'inchangé à 0,1 ha près' END        AS quoi,
       count(*)                                      AS atomes,
       round((sum(ap - av) / 1e6)::numeric, 1)       AS km2_net
FROM   avant
GROUP  BY 1
ORDER  BY 2 DESC;

\echo ''
\echo '=== 8. Les atomes vivants que la PARTITION ne rend pas =================='
\echo '    ATTENTION AU TITRE, CORRIGÉ LE 5 SEPTEMBRE 2026. Il disait « que'
\echo '    RIEN ne dessine », et ajoutait « ce ne sont pas des trous ouverts'
\echo '    par 84 — ils manquaient déjà ». **C''était faux, et mesuré tel** :'
\echo '    `diag_sans_geometrie.sql` cherche les atomes vivants sans aucune'
\echo '    géométrie — ni atom_geom, ni ANR à la date — et en trouve ZÉRO.'
\echo ''
\echo '    Ces atomes ont donc tous de quoi être dessinés. Ce qui leur manque,'
\echo '    c''est une FACE : ils sont absents du résultat de la fonction, pas'
\echo '    des tables qu''elle lit. L''arbitrage du § (d) donne chaque face à un'
\echo '    seul propriétaire, et un polygone entièrement recouvert par un autre'
\echo '    mieux classé — un repli sous un polygone ANR, typiquement une fille'
\echo '    reportée en arrière par `11` posée sur sa mère intacte — perd tout.'
\echo ''
\echo '    *Une population définie par « absente du résultat d''une fonction »'
\echo '    n''est pas celle définie par « absente des tables qu''elle lit ». Les'
\echo '    deux se disent avec la même phrase française.*'
\echo ''
\echo '    La question utile est donc « à qui leur sol a-t-il été donné ? », et'
\echo '    la requête est au § 6 de `diag_sans_geometrie.sql` : elle se colle'
\echo '    ICI, dans cette session, où `d84` est encore vivante.'
\echo '    Les vingt premiers, pour savoir de quoi il s''agit.'
\echo ''

SELECT m.atom_id, a.insee_geofla, a.fraction,
       coalesce(n.nom, '[' || a.insee_geofla || ']') AS nom,
       min(u.dep)                                    AS dep
FROM   membership m
JOIN   atom a ON a.atom_id = m.atom_id
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  m.periode @> :'date'::date
  AND  NOT EXISTS (SELECT 1 FROM d84 d WHERE d.atom_id = m.atom_id)
GROUP  BY m.atom_id, a.insee_geofla, a.fraction, 4
ORDER  BY 5, 4
LIMIT  20;

\echo ''
\echo '=== 9. La couture entre départements, nommée paire par paire ============'
\echo '    AJOUTÉ LE 5 SEPTEMBRE 2026, parce que la ligne a cessé de valoir'
\echo '    zéro. Passe nationale du 2 septembre : 0,000 km². Passe nationale du'
\echo '    5 septembre, mêmes atomes, mêmes reprises, même emprise au km² près :'
\echo '    **0,019 km²**. Une seule chose a changé entre les deux, l''anneau de'
\echo '    contexte du 3 septembre — et sa non-régression n''avait été vérifiée'
\echo '    que département par département, c''est-à-dire là où cette ligne est'
\echo '    SANS OBJET par construction.'
\echo ''
\echo '    *Une recette qu''on ne peut pas lire dans le cadre où l''on éprouve'
\echo '    un correctif ne le contrôle pas — elle attend la passe nationale.*'
\echo ''
\echo '    Ce qui se lit ici : deux atomes de départements différents qui se'
\echo '    recouvrent ont été arbitrés dans deux cadres, et la lisière n''est'
\echo '    pas tombée du même côté. 1,9 ha au total, donc des lisières et non'
\echo '    du territoire — mais c''est aussi ici que se verrait le corollaire'
\echo '    de la reprise non découpable : une FRATRIE À CHEVAL sur deux'
\echo '    départements recevant deux fois le même morceau. La colonne'
\echo '    `deux_reprises` sépare les deux lectures. Un couple qui la porte à'
\echo '    `t` et pèse plusieurs km² n''est pas une lisière : c''est le même sol'
\echo '    donné deux fois.'
\echo ''

SELECT a.dep                                              AS dep_a,
       coalesce(na.nom, '[' || a.insee_geofla || ']')     AS nom_a,
       b.dep                                              AS dep_b,
       coalesce(nb.nom, '[' || b.insee_geofla || ']')     AS nom_b,
       round((ST_Area(ST_Intersection(a.geom, b.geom)) / 1e6)::numeric, 4)
                                                          AS km2,
       a.source || ' / ' || b.source                      AS sources,
       (a.source = 'reprise' AND b.source = 'reprise')     AS deux_reprises
FROM   d84 a
JOIN   d84 b ON a.atom_id < b.atom_id
            AND a.geom && b.geom
            AND ST_Intersects(a.geom, b.geom)
LEFT   JOIN noms_geofla na ON na.insee = a.insee_geofla
LEFT   JOIN noms_geofla nb ON nb.insee = b.insee_geofla
WHERE  NOT a.fraction AND NOT b.fraction
  AND  a.dep IS DISTINCT FROM b.dep
ORDER  BY 5 DESC;

\echo ''
\echo '--- Fin. La table temporaire `d84` reste disponible dans CETTE session :'
\echo '    SELECT * FROM d84 WHERE dep = ''12'';'
\echo ''

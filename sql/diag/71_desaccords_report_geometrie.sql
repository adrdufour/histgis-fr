-- ============================================================================
-- histgis — 71_desaccords_report_geometrie.sql : la géométrie arbitre
--
--   psql -d histgis -f sql/diag/71_desaccords_report_geometrie.sql
--
-- LECTURE SEULE. Prérequis : `70_report_1940_1954.sql` (table `r70_paire`).
--
-- CE QUE `70` NE PEUT PAS DÉMÊLER
-- ================================
-- `70` mesure **323 désaccords sur 26 544 communes** entre le canton de 1940
-- reporté et celui lu en 1954. Ce chiffre mélange trois choses :
--
--   1. de VRAIS transferts de communes entre cantons, non datés par l'annexe
--      VII et invisibles au registre ;
--   2. des erreurs de LECTURE — le volume de 1954 imprime le canton sur un ou
--      deux chiffres, et l'OCR en abîme ;
--   3. des erreurs de report, si la composition de 1940 était fausse.
--
-- La liste brute suggère déjà que (2) pèse lourd :
--
--     02357   Vervins -> Oulchy-le-Château     canton lu 24, réel 34
--     02772   Vermand -> Vic-sur-Aisne         canton lu 35, réel 33
--     06074   Utelle  -> Nice-2
--
-- Vervins et Oulchy-le-Château sont aux deux extrémités de l'Aisne. Une commune
-- ne traverse pas un département pour changer de canton.
--
-- LE PRINCIPE, DÉJÀ ÉPROUVÉ
-- ==========================
-- *Quand codes et noms se contredisent, la géométrie arbitre.* C'est ce qui a
-- réfuté 227 des 311 « transferts » de la première extraction de 1954
-- (`cog1954/test_contiguite.py`) — Saint-Pierre-d'Oléron « passait » dans un
-- canton distant de 109 km. Aucun contrôle de cohérence ne pouvait les
-- démentir : les codes étaient valides, les noms plausibles, les cantons réels.
-- Seuls les polygones le pouvaient.
--
-- Un vrai transfert se fait vers un canton VOISIN. Une commune qui « passe »
-- dans un canton situé à quarante kilomètres n'a pas bougé : c'est le chiffre
-- qui a été mal lu.
--
-- CE QUE CE FICHIER NE DÉCIDE PAS
-- ================================
-- Il ne corrige rien et ne classe pas automatiquement. Il donne la distance, et
-- laisse le seuil au lecteur : la contiguïté stricte est trop dure (une commune
-- peut être séparée de son nouveau canton par un bras de rivière mal
-- numérisé), la distance nulle trop laxiste. Le § 4 propose une lecture, il ne
-- l'impose pas.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set date_1940 '1940-06-01'
\set date_1954 '1954-06-01'

\echo ''
\echo '============================================================'
\echo ' Les 323 désaccords du report : transfert ou mauvaise lecture ?'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.r70_paire') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/diag/70_report_1940_1954.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. La géométrie de chaque canton, aux deux dates
--
-- La géométrie ne vit PAS dans `atom` : `01_schema.sql` la renvoie
-- explicitement à `atom_geom (atom_id, geom, source, partagee)`, peuplée par
-- `05_geom.sql`. Géométrie et attribution sont découplées — c'est le choix
-- fondateur du modèle, et il se rappelle à qui écrit `a.geom`.
--
-- L'union des atomes rattachés au canton à la date. On EXCLUT la commune en
-- cause de l'union de son canton de 1954 : sans quoi la distance serait nulle
-- par construction, la commune faisant partie de ce qu'on mesure.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS d71_canton_1940;
CREATE TABLE d71_canton_1940 AS
SELECT m.unit_id, ST_Union(a.geom) AS geom
FROM   membership m JOIN atom_geom a ON a.atom_id = m.atom_id
WHERE  m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> :'date_1940'::date
  AND  m.unit_id IN (SELECT c40 FROM r70_paire WHERE c40 <> c54
                     UNION SELECT c54 FROM r70_paire WHERE c40 <> c54)
GROUP  BY m.unit_id;

CREATE INDEX d71_c40_geom ON d71_canton_1940 USING gist (geom);
CREATE INDEX d71_c40_id   ON d71_canton_1940 (unit_id);

\echo ''
\echo '-- 1. cantons dont la géométrie de 1940 est disponible'
SELECT count(*) AS cantons_geometres FROM d71_canton_1940;

-- ---------------------------------------------------------------------------
-- 2. La distance de la commune à chacun des deux cantons
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS d71_verdict;
CREATE TABLE d71_verdict AS
SELECT p.dep, p.insee, p.atome, p.c40, p.c54,
       (SELECT u.nom FROM unit u WHERE u.unit_id = p.c40)      AS nom_1940,
       (SELECT u.nom FROM unit u WHERE u.unit_id = p.c54)      AS nom_1954,
       -- distance au canton d'ARRIVÉE, la commune elle-même retirée
       round((ST_Distance(a.geom,
              (SELECT ST_Union(x.geom) FROM atom_geom x
                JOIN membership m ON m.atom_id = x.atom_id
               WHERE m.niveau = 'canton' AND m.unit_id = p.c54
                 AND daterange(m.valid_from, m.valid_to, '[)')
                     @> :'date_1940'::date
                 AND split_part(x.atom_id, '#', 1) <> p.atome))
             / 1000.0)::numeric, 1)                            AS km_vers_1954,
       round((ST_Distance(a.geom, g40.geom) / 1000.0)::numeric, 1)
                                                               AS km_vers_1940
FROM   r70_paire p
JOIN   atom_geom a ON a.atom_id = p.atome
LEFT   JOIN d71_canton_1940 g40 ON g40.unit_id = p.c40
WHERE  p.c40 <> p.c54;

\echo ''
\echo '-- 2. les désaccords mesurés'
SELECT count(*)                                            AS desaccords,
       count(*) FILTER (WHERE km_vers_1954 IS NULL)        AS sans_geometrie,
       count(*) FILTER (WHERE km_vers_1954 = 0)            AS canton_1954_voisin,
       count(*) FILTER (WHERE km_vers_1954 > 0
                          AND km_vers_1954 <= 5)           AS proche_5km,
       count(*) FILTER (WHERE km_vers_1954 > 5)            AS eloigne
FROM   d71_verdict;

-- ---------------------------------------------------------------------------
-- 3. Le détail, du plus invraisemblable au plus crédible
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. les 25 plus invraisemblables — le canton lu en 1954 est LOIN'
SELECT dep, insee, nom_1940, nom_1954, km_vers_1954
FROM   d71_verdict WHERE km_vers_1954 IS NOT NULL
ORDER  BY km_vers_1954 DESC LIMIT 25;

\echo ''
\echo '-- 3 bis. les transferts CRÉDIBLES — canton d''arrivée contigu'
SELECT dep, insee, nom_1940, nom_1954
FROM   d71_verdict WHERE km_vers_1954 = 0
ORDER  BY dep, insee LIMIT 25;

-- ---------------------------------------------------------------------------
-- 4. Ce que cela fait au taux du report
--
-- Si les désaccords à canton d'arrivée ÉLOIGNÉ sont des erreurs de lecture, ils
-- ne sont pas imputables au report. Le taux corrigé est une BORNE HAUTE de la
-- justesse du report, comme le taux brut en est une borne basse : la vérité est
-- entre les deux, et l'écart entre elles mesure notre ignorance.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. le report, entre deux bornes'
SELECT (SELECT count(*) FROM r70_paire)                         AS communes,
       (SELECT count(*) FROM r70_paire WHERE c40 = c54)         AS accord_brut,
       round(100.0 * (SELECT count(*) FROM r70_paire WHERE c40 = c54)
             / (SELECT count(*) FROM r70_paire), 2)             AS pct_borne_basse,
       round(100.0 * ((SELECT count(*) FROM r70_paire WHERE c40 = c54)
                      + (SELECT count(*) FROM d71_verdict WHERE km_vers_1954 > 5))
             / (SELECT count(*) FROM r70_paire), 2)             AS pct_borne_haute;

-- ---------------------------------------------------------------------------
-- 5. L'ÉCHANGE BIDIRECTIONNEL — une signature que la distance ne voit pas
--
-- Parmi les 89 désaccords vers un canton CONTIGU, donc géographiquement
-- crédibles, un motif saute aux yeux :
--
--     14025  Falaise-Sud -> Falaise-Nord      14244  Falaise-Nord -> Falaise-Sud
--     21142  Venarey -> Saint-Seine           21338  Saint-Seine -> Venarey
--
-- **Des communes qui se croisent entre deux mêmes cantons, dans les deux sens.**
-- Un redécoupage ne fait pas cela : il déplace la frontière, donc les communes
-- vont toutes dans le même sens. Un échange croisé est la signature d'une
-- CONFUSION entre deux cantons voisins — numéros proches, noms presque
-- identiques (Nord/Sud, Terranova/Terravecchia), et l'OCR ou le typographe
-- s'y perd.
--
-- La distance ne peut pas repérer ce cas : les deux cantons sont contigus, donc
-- chaque ligne prise isolément est plausible. **C'est la STRUCTURE de
-- l'ensemble qui la dément, pas la géométrie de chaque élément.**
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. les échanges croisés entre deux mêmes cantons'
WITH sens AS (
    SELECT least(c40, c54) AS a, greatest(c40, c54) AS b,
           count(*) FILTER (WHERE c40 < c54) AS a_vers_b,
           count(*) FILTER (WHERE c40 > c54) AS b_vers_a,
           count(*)                          AS total
    FROM   d71_verdict WHERE km_vers_1954 = 0
    GROUP  BY 1, 2
)
SELECT a, (SELECT nom FROM unit WHERE unit_id = a) AS nom_a,
       b, (SELECT nom FROM unit WHERE unit_id = b) AS nom_b,
       a_vers_b, b_vers_a, total
FROM   sens WHERE a_vers_b > 0 AND b_vers_a > 0
ORDER  BY total DESC;

\echo ''
\echo '-- 5 bis. ce que cela retire encore aux « transferts crédibles »'
WITH sens AS (
    SELECT least(c40, c54) AS a, greatest(c40, c54) AS b,
           count(*) FILTER (WHERE c40 < c54) AS ab,
           count(*) FILTER (WHERE c40 > c54) AS ba,
           count(*) AS total
    FROM   d71_verdict WHERE km_vers_1954 = 0
    GROUP  BY 1, 2
)
SELECT (SELECT count(*) FROM d71_verdict WHERE km_vers_1954 = 0) AS contigus,
       coalesce(sum(total) FILTER (WHERE ab > 0 AND ba > 0), 0)  AS en_echange_croise,
       (SELECT count(*) FROM d71_verdict WHERE km_vers_1954 = 0)
         - coalesce(sum(total) FILTER (WHERE ab > 0 AND ba > 0), 0)
                                                                 AS transferts_restants
FROM   sens;

\echo ''
\echo '   `transferts_restants` est la meilleure estimation actuelle du nombre'
\echo '   de VRAIS transferts de communes non datés sur 1940-1954. Rapporté aux'
\echo '   26 544 communes du banc, il dit à quel point le report est fiable'
\echo '   quand la liste des créations est complète.'

\echo ''
\echo '   La borne HAUTE suppose que tout désaccord vers un canton distant de'
\echo '   plus de 5 km est une erreur de lecture. C''est une hypothèse, pas un'
\echo '   fait : une commune peut réellement rejoindre un canton non contigu si'
\echo '   le canton lui-même a été remanié. Le seuil de 5 km est un choix, et'
\echo '   le § 3 permet de le déplacer.'

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo '============================================================'

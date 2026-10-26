-- ============================================================================
-- diag_deux_bouts_1969_1999.sql — l'intervalle noir, lu comme `93` a lu
-- 1941-1953 : par ses deux bouts
--
--   psql -d histgis -f sql/diag/diag_deux_bouts_1969_1999.sql | tee build/deux_bouts.txt
--
-- LECTURE SEULE. Écrit le 23 septembre 2026. C'est à `95` ce que `70` a été
-- à `93` : la mesure qui dit si le fichier qui pose vaut d'être écrit.
--
-- LE CONSTAT QUI L'A FAIT ÉCRIRE
-- ------------------------------
-- `diag_intervalle_noir.sql` a mesuré 357 788 atome-années noires, et son § 2
-- montre que le trou S'OUVRE en 1974 — pas en 1986. 21 891 atomes basculent
-- d'un coup après le scrutin du 23 septembre 1973. Le mur 1986-1989 n'est pas
-- le cœur ; le cœur est la salve de 1973, **qui est dépouillée**.
--
-- La cause est dans la règle de `81`, pas dans les sources : son report
-- s'arrête pour TOUT le département au premier acte, parce qu'il ignore qui
-- l'acte déplace. Or un décret de « création de cantons » ne touche que les
-- communes des cantons qu'il crée ou modifie — une vingtaine sur quatre cents.
-- Les autres restent où elles sont, et c'est justement ce que le report ne
-- sait pas dire.
--
-- DEUX VOIES POUR LES RENDRE, ET POURQUOI CE FICHIER MESURE LA SECONDE
-- --------------------------------------------------------------------
--   1. le CHAÎNAGE : franchir l'acte pour toute commune qu'il ne nomme pas.
--      Il repose sur la complétude de la lecture de chaque acte — et
--      `RESTE_A_FAIRE.md` § 1 compte 62 cantons annoncés au titre d'un décret
--      et jamais lus. Une commune d'un canton non lu passerait pour « non
--      nommée », et serait reportée à tort.
--   2. les DEUX BOUTS, comme `93` : pour chaque atome, le canton qui ferme le
--      trou à gauche (`81`, ou `75`/`76`/`77`) et celui qui l'ouvre à droite
--      (`79`, ou `75`/`76`/`77`). S'ils sont le même, on pose ; sinon, on
--      laisse vide. Le registre n'autorise rien, il EXPLIQUE les désaccords.
--
-- La seconde ne dépend d'aucune complétude de lecture. Ce qu'elle ne voit pas
-- est connu et borné : une commune partie puis revenue dans l'intervalle.
-- *Un accord entre deux relevés indépendants ne prouve pas l'immobilité ;
-- il la rend réfutable, ce que l'absence d'acte ne fait pas.*
--
-- CE QUE LE FICHIER DOIT DIRE AVANT QU'ON ÉCRIVE `95`
-- ---------------------------------------------------
--   § 3  le taux d'accord, et SON DÉNOMINATEUR ;
--   § 4  la pente : l'accord doit BAISSER quand le nombre d'actes dans le trou
--        monte, et presque pas là où l'atome n'est nommé par aucun. Sans cette
--        pente, l'accord ne mesure rien ;
--   § 5  les désaccords EN BLOC : un canton dont TOUS les atomes passent de X
--        à Y n'a pas déménagé, il a changé d'identifiant (la série havraise
--        décalée d'un rang en 1991). Ceux-là ne sont pas des mouvements ;
--   § 6  ce que `95` rendrait, en atome-années.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.p81_trace') IS NULL
       OR to_regclass('histgis.p79_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `79` et `81`.';
    END IF;
    IF to_regclass('histgis.acte_composition') IS NULL
       OR to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` et `75` (acte_composition, scrutin_cantonal).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. L'origine de chaque ligne cantonale, par les traces
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.b_origine;
CREATE TEMP TABLE b_origine (membership_id bigint PRIMARY KEY, fichier text);
INSERT INTO b_origine
SELECT DISTINCT ON (cle::bigint) cle::bigint, f
FROM (
          SELECT cle, '81' AS f, 1 AS rang FROM p81_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '79', 2 FROM p79_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '75', 3 FROM p75_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '76', 4 FROM p76_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '77', 5 FROM p77_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '74', 6 FROM y67_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '59', 7 FROM c68_trace WHERE quoi LIKE 'membership%'
-- `24` : la couche de 1999 elle-même, bout droit de 262 trous qui finissent
-- au 1999-01-01. Oubliée au premier passage (23 septembre 2026), où ces
-- lignes sortaient en « ? » et donc hors de `bouts_releves` — alors que le
-- COG 1999 est un relevé, pas un report.
UNION ALL SELECT cle, '24', 8 FROM canton_moderne_trace WHERE quoi = 'membership'
) t
WHERE cle ~ '^[0-9]+$'
ORDER BY cle::bigint, rang;

-- ---------------------------------------------------------------------------
-- 1. Les trous, atome par atome, entre deux lignes cantonales
-- ---------------------------------------------------------------------------
-- Un trou est l'intervalle entre la fin d'une ligne et le début de la
-- suivante, pour le même atome. On ne garde que ceux qui tombent ENTIÈREMENT
-- dans [1969-01-01, 1999-01-01] : ceux-là ont deux bouts dans la période que
-- `79` et `81` encadrent.
DROP TABLE IF EXISTS pg_temp.b_trou;
CREATE TEMP TABLE b_trou AS
WITH l AS (
    SELECT m.atom_id, m.membership_id, m.unit_id, m.valid_from, m.valid_to,
           lead(m.membership_id) OVER w AS id_d,
           lead(m.unit_id)       OVER w AS unit_d,
           lead(m.valid_from)    OVER w AS from_d
    FROM   membership m
    WHERE  m.niveau = 'canton'
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT l.atom_id,
       a.insee_geofla                         AS insee,
       a.fraction,
       trim(u.dep::text)                      AS dep,
       l.valid_to                             AS debut,
       l.from_d                               AS fin,
       round(((l.from_d - l.valid_to) / 365.25)::numeric, 2) AS annees,
       l.unit_id                              AS unit_g,
       l.unit_d,
       coalesce(og.fichier, '?')              AS source_g,
       coalesce(od.fichier, '?')              AS source_d
FROM   l
JOIN   atom a ON a.atom_id = l.atom_id
JOIN   unit u ON u.unit_id = l.unit_id AND u.niveau = 'canton'
LEFT   JOIN b_origine og ON og.membership_id = l.membership_id
LEFT   JOIN b_origine od ON od.membership_id = l.id_d
WHERE  l.from_d > l.valid_to
  AND  l.valid_to >= DATE '1969-01-01'
  AND  l.from_d   <= DATE '1999-01-01';
CREATE INDEX ON b_trou (atom_id);

-- Les actes qui prennent effet DANS le trou, pour le département de l'atome,
-- et ceux qui NOMMENT l'atome (par son code INSEE) dans le trou.
ALTER TABLE b_trou ADD COLUMN actes int, ADD COLUMN nomme boolean;
UPDATE b_trou t SET
    actes = (SELECT count(DISTINCT e.legifrance_id)
             FROM   acte_departement d
             JOIN   acte_effet e ON e.legifrance_id = d.legifrance_id
             WHERE  d.dep = t.dep
               AND  e.date_effet >= t.debut AND e.date_effet < t.fin
               AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                                 WHERE x.legifrance_id = e.legifrance_id)),
    nomme = EXISTS (
             SELECT 1 FROM acte_composition c
             WHERE  c.insee = t.insee
               AND  (SELECT min(s.tour1) FROM scrutin_cantonal s
                      WHERE s.tour1 >= c.date_acte) >= t.debut
               AND  (SELECT min(s.tour1) FROM scrutin_cantonal s
                      WHERE s.tour1 >= c.date_acte) <  t.fin);

ALTER TABLE b_trou ADD COLUMN accord boolean;
UPDATE b_trou SET accord = (unit_g = unit_d);

\echo ''
\echo '============================================================'
\echo ' 1969-1998 PAR LES DEUX BOUTS — mesure, rien n''est écrit'
\echo '============================================================'

\echo ''
\echo '-- 1. les trous à deux bouts, et ce qu''ils pèsent'
\echo '   (à comparer aux 357 788 atome-années de diag_intervalle_noir : la'
\echo '    différence est la part SANS bout droit — atomes morts dans le trou,'
\echo '    ou dont la ligne suivante commence après 1999)'
SELECT count(*)                          AS trous,
       count(DISTINCT atom_id)           AS atomes,
       round(sum(annees))                AS atome_annees,
       count(*) FILTER (WHERE fraction)  AS dont_fractions
FROM   b_trou;

\echo ''
\echo '-- 2. qui borne les trous : fichier de gauche × fichier de droite'
SELECT source_g, source_d, count(*) AS trous, round(sum(annees)) AS atome_annees
FROM   b_trou GROUP BY 1, 2 ORDER BY 3 DESC;

-- ---------------------------------------------------------------------------
-- 3. L'accord, avec son dénominateur
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. l''accord des deux bouts'
\echo '   Dénominateur : les trous à deux bouts, hors fractions (une fraction'
\echo '   porte son canton dans son identifiant : son accord ne mesure rien).'
SELECT count(*)                                         AS comparables,
       count(*) FILTER (WHERE accord)                   AS accord,
       round(100.0 * count(*) FILTER (WHERE accord) / nullif(count(*), 0), 2)
                                                        AS pct_accord,
       round(sum(annees) FILTER (WHERE accord))         AS atome_annees_en_accord
FROM   b_trou WHERE NOT fraction;

-- ---------------------------------------------------------------------------
-- 4. La pente — le test qui décide
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4 a. l''accord selon que l''atome est NOMMÉ par un acte dans le trou'
\echo '   Attendu : très haut quand il ne l''est pas, nettement plus bas quand'
\echo '   il l''est. Deux taux voisins voudraient dire que l''accord ne dépend'
\echo '   pas de ce que les décrets font — donc qu''il ne mesure pas les décrets.'
SELECT nomme, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 4 b. l''accord selon le nombre d''actes dans le trou (non nommés)'
SELECT least(actes, 5) AS actes_5_et_plus, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT nomme GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 4 c. l''accord selon la longueur du trou (non nommés)'
SELECT CASE WHEN annees <  5 THEN 'a. moins de 5 ans'
            WHEN annees < 10 THEN 'b. 5 à 10 ans'
            WHEN annees < 20 THEN 'c. 10 à 20 ans'
            ELSE                  'd. 20 ans et plus' END AS longueur,
       count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT nomme GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. Les désaccords — mouvements, ou identités qui ont glissé ?
-- ---------------------------------------------------------------------------
-- Un désaccord « en bloc » : le couple (X à gauche, Y à droite) couvre au
-- moins 80 % des atomes que X porte à gauche dans ce département, sur au moins
-- trois atomes. Un canton entier ne déménage pas ; il se renumérote, ou il est
-- scindé et `75` l'a résolu vers sa fille.
DROP TABLE IF EXISTS pg_temp.b_paire;
CREATE TEMP TABLE b_paire AS
SELECT unit_g, unit_d, count(*) AS n,
       (SELECT count(*) FROM b_trou t2
         WHERE t2.unit_g = t.unit_g AND NOT t2.fraction) AS n_gauche
FROM   b_trou t
WHERE  NOT fraction AND NOT accord
GROUP  BY 1, 2;

\echo ''
\echo '-- 5 a. les désaccords, classés'
SELECT CASE WHEN p.n >= 3 AND p.n >= 0.8 * p.n_gauche THEN 'en bloc — identité ?'
            WHEN t.nomme                              THEN 'nommé par un acte — mouvement expliqué'
            ELSE                                           'isolé, non nommé — à instruire' END
                                                   AS classe,
       count(*)                                    AS trous,
       round(sum(t.annees))                        AS atome_annees
FROM   b_trou t
JOIN   b_paire p ON p.unit_g = t.unit_g AND p.unit_d = t.unit_d
WHERE  NOT t.fraction AND NOT t.accord
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 5 b. les vingt plus gros blocs, nommés'
SELECT p.unit_g, ug.nom AS nom_gauche, p.unit_d, ud.nom AS nom_droite,
       p.n AS atomes, p.n_gauche
FROM   b_paire p
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = p.unit_g
                      ORDER BY v.valid_from DESC LIMIT 1) ug ON true
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = p.unit_d
                      ORDER BY v.valid_from DESC LIMIT 1) ud ON true
WHERE  p.n >= 3 AND p.n >= 0.8 * p.n_gauche
ORDER  BY p.n DESC LIMIT 20;

-- ---------------------------------------------------------------------------
-- 6. Ce que `95` rendrait
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. ce qu''un report par les deux bouts poserait, et ce qu''il laisserait'
SELECT CASE WHEN fraction           THEN 'fraction — convention à écrire'
            WHEN accord AND NOT nomme THEN 'accord, non nommé — posable'
            WHEN accord AND nomme     THEN 'accord mais nommé — aller-retour ? à lire'
            ELSE                           'désaccord — laissé vide' END AS verdict,
       count(*)                AS trous,
       count(DISTINCT atom_id) AS atomes,
       round(sum(annees))      AS atome_annees
FROM   b_trou GROUP BY 1 ORDER BY 4 DESC;

\echo ''
\echo '-- 6 bis. les départements, par atome-années posables'
SELECT dep,
       round(sum(annees) FILTER (WHERE accord AND NOT nomme AND NOT fraction)) AS posable,
       round(sum(annees) FILTER (WHERE NOT accord AND NOT fraction))           AS desaccord,
       round(100.0 * count(*) FILTER (WHERE accord AND NOT fraction)
             / nullif(count(*) FILTER (WHERE NOT fraction), 0), 1)            AS pct_accord
FROM   b_trou GROUP BY dep ORDER BY 2 DESC NULLS LAST;

\echo ''
\echo '-- fin — rien n''a été écrit. Tables temporaires seulement.'

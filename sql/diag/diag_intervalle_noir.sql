-- ============================================================================
-- diag_intervalle_noir.sql — l'intervalle noir entre `81` et `79`, département
-- par département, et ce qu'il faudrait pour le combler
--
--   psql -d histgis -f sql/diag/diag_intervalle_noir.sql | tee build/intervalle_noir.txt
--
-- LECTURE SEULE. Hors chaîne. Écrit le 23 septembre 2026, point 2 de la file
-- d'attente de RESTE_A_FAIRE.md, § 1 ter.
--
-- POURQUOI UN FICHIER ET NON LA RECETTE 11 g
-- ------------------------------------------
-- `81` § 11 g mesure l'intervalle par ses BORNES : la borne de `81` (premier
-- acte après le jalon de 1968) et le plancher de `79` (dernier acte avant
-- 1999), multipliés par des départements. C'est une estimation, et elle ne
-- voit pas ce que `75`, `76` et `77` ont posé DANS la fenêtre sous leur
-- convention de date. Ce fichier compte l'intervalle dans `membership` même :
-- atome par atome, année par année, qui n'a aucun canton.
--
-- *Une mesure dérivée des bornes décrit le trou que les bornes dessinent ;
-- seule la base dit celui qui reste.*
--
-- CE QU'IL CLASSE
-- ---------------
-- Une fenêtre noire tient aux actes qui tombent dedans : un report ne franchit
-- pas un acte dont il ignore l'effet. Pour chaque département, le § 3 trie ces
-- actes, et le § 4 en tire une VOIE :
--
--   chaînage     tous les actes de la fenêtre ont une composition lue
--                (`acte_composition`) — on peut dérouler la composition de 1968
--                acte après acte, sans source neuve ;
--   lecture      au moins un acte a son texte (Légifrance ou JO) mais n'a pas
--                été dépouillé — le travail est de lire, pas de chercher ;
--   source       au moins un acte n'a ni texte intégral ni composition — il
--                faut le JO en PDF (le mur 1986-1989 est de ce type).
--
-- Réserve connue et permanente : un décret nomme les cantons qu'il crée ou
-- modifie, jamais ceux qu'il vide. Le chaînage en hérite.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.p81_borne') IS NULL
       OR to_regclass('histgis.p81_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `81` n''a pas tourné (p81_borne, p81_qualite).';
    END IF;
    IF to_regclass('histgis.acte_effet') IS NULL
       OR to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` et `75` (acte_effet, acte_composition).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. La population de référence
-- ---------------------------------------------------------------------------
-- Les atomes du jalon de 1968, avec leur département : ce sont ceux dont `81`
-- a reporté la composition, donc ceux dont l'absence au-delà de la borne est
-- un trou et non une naissance ou une mort. Le département est celui de leur
-- unité de 1968 — pas de 1999, parce que la Seine-et-Oise et la Corse ont
-- changé de code dans l'intervalle, et que c'est `p81_borne` qu'on croise.
DROP TABLE IF EXISTS pg_temp.n_ref;
CREATE TEMP TABLE n_ref AS
SELECT DISTINCT ON (m.atom_id) m.atom_id, trim(u.dep::text) AS dep
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton'
  AND  m.periode @> DATE '1968-06-01'
ORDER  BY m.atom_id, u.dep;
CREATE INDEX ON n_ref (atom_id);

-- Les années noires, atome par atome : au 1er juin de chaque année de la
-- fenêtre, l'atome n'a aucun canton. On ne compte que les atomes VIVANTS cette
-- année-là, au sens d'un rattachement quelconque avant ET après — un atome
-- absorbé en 1972 n'est pas dans un trou en 1980, il est mort.
DROP TABLE IF EXISTS pg_temp.n_trou;
CREATE TEMP TABLE n_trou AS
SELECT r.dep, r.atom_id, y::int AS annee
FROM   n_ref r
CROSS  JOIN generate_series(1969, 1998) y
WHERE  NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = r.atom_id AND m.niveau = 'canton'
                      AND m.periode @> make_date(y::int, 6, 1))
  AND  EXISTS     (SELECT 1 FROM membership m
                    WHERE m.atom_id = r.atom_id AND m.niveau = 'canton'
                      AND lower(m.periode) > make_date(y::int, 6, 1));

\echo ''
\echo '============================================================'
\echo ' L''INTERVALLE NOIR ENTRE `81` ET `79`, MESURÉ DANS LA BASE'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Le total, et la comparaison avec l'estimation de `81` § 11 g
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 1. le total mesuré, contre l''estimation par les bornes'
\echo '   (11 g rendait 1 072 dép-années sur 72 départements ; ici l''unité est'
\echo '    l''atome-année, et un département-année noir vaut ~400 atome-années)'
SELECT count(DISTINCT dep)                            AS departements_touches,
       count(DISTINCT atom_id)                        AS atomes_touches,
       count(*)                                       AS atome_annees_noires,
       (SELECT count(*) FROM n_ref)                   AS atomes_du_jalon_1968,
       round(100.0 * count(*) / ((SELECT count(*) FROM n_ref) * 30), 1)
                                                      AS pct_de_1969_1998
FROM   n_trou;

-- ---------------------------------------------------------------------------
-- 2. Année par année — où est le cœur
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 2. année par année : atomes sans canton au 1er juin'
\echo '   (le mur 1986-1989 doit se voir ici, s''il est le cœur)'
SELECT annee,
       count(*)                  AS atomes_sans_canton,
       count(DISTINCT dep)       AS departements,
       repeat('#', (count(*) / 400)::int) AS histogramme
FROM   n_trou
GROUP  BY annee ORDER BY annee;

-- ---------------------------------------------------------------------------
-- 3. Les actes de chaque fenêtre, triés
-- ---------------------------------------------------------------------------
-- La fenêtre d'un département est [borne de `81`, plancher de `79`). Les actes
-- qui y prennent effet sont ceux qu'aucun des deux reports n'a su franchir.
DROP TABLE IF EXISTS pg_temp.n_acte;
CREATE TEMP TABLE n_acte AS
SELECT b.dep,
       a.legifrance_id,
       a.date_signature,
       e.date_effet,
       coalesce(nullif(a.decret, ''), '(non numéroté)')   AS decret,
       a.texte_integral = 'oui'                           AS texte_legifrance,
       EXISTS (SELECT 1 FROM acte_composition c
                WHERE c.date_acte = a.date_signature
                  AND c.dep = b.dep)                      AS depouille,
       left(a.objet, 70)                                  AS objet
FROM   p81_borne b
JOIN   acte_departement d ON d.dep = b.dep
JOIN   acte_cantonal a    ON a.legifrance_id = d.legifrance_id
JOIN   acte_effet e       ON e.legifrance_id = a.legifrance_id
WHERE  b.plancher_de_79 > b.borne
  AND  e.date_effet >= b.borne
  AND  e.date_effet <= b.plancher_de_79
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                    WHERE x.legifrance_id = a.legifrance_id);

\echo ''
\echo '-- 3. les actes des fenêtres noires, par nature'
\echo '   (bornes comprises : l''acte qui fixe la borne et celui qui fixe le'
\echo '    plancher font partie de ce qu''il faut connaître pour chaîner)'
SELECT CASE WHEN depouille        THEN 'dépouillé — composition lue'
            WHEN texte_legifrance THEN 'texte sur Légifrance, non dépouillé'
            ELSE                       'ni texte ni composition — JO requis' END
                                         AS nature,
       count(*)                          AS actes,
       count(DISTINCT dep)               AS departements,
       min(date_effet)                   AS du,
       max(date_effet)                   AS au
FROM   n_acte GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. Département par département, avec sa voie
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.n_dep;
CREATE TEMP TABLE n_dep AS
SELECT b.dep,
       b.borne,
       b.plancher_de_79                                           AS plancher,
       round(((b.plancher_de_79 - b.borne) / 365.25)::numeric, 1) AS ans,
       (SELECT count(*) FROM n_trou t WHERE t.dep = b.dep)        AS atome_annees,
       (SELECT count(*) FROM n_acte a WHERE a.dep = b.dep)        AS actes,
       (SELECT count(*) FROM n_acte a WHERE a.dep = b.dep
                                        AND a.depouille)          AS depouilles,
       (SELECT count(*) FROM n_acte a WHERE a.dep = b.dep
                                        AND NOT a.depouille
                                        AND a.texte_legifrance)   AS a_lire,
       (SELECT count(*) FROM n_acte a WHERE a.dep = b.dep
                                        AND NOT a.depouille
                                        AND NOT a.texte_legifrance) AS sans_texte
FROM   p81_borne b
WHERE  b.plancher_de_79 > b.borne
  AND  EXISTS (SELECT 1 FROM p81_qualite q WHERE q.dep = b.dep);

ALTER TABLE n_dep ADD COLUMN voie text;
UPDATE n_dep SET voie = CASE
    WHEN sans_texte > 0 THEN 'source'
    WHEN a_lire     > 0 THEN 'lecture'
    ELSE                     'chaînage' END;

\echo ''
\echo '-- 4 a. les voies : ce que coûte chacune, et ce qu''elle rapporte'
SELECT voie,
       count(*)                  AS departements,
       sum(atome_annees)         AS atome_annees_en_jeu,
       sum(actes)                AS actes,
       sum(a_lire)               AS actes_a_lire,
       sum(sans_texte)           AS actes_sans_texte
FROM   n_dep GROUP BY voie
ORDER  BY CASE voie WHEN 'chaînage' THEN 1 WHEN 'lecture' THEN 2 ELSE 3 END;

\echo ''
\echo '-- 4 b. les départements, du plus lourd au plus léger'
\echo '   (atome_annees : mesuré dans membership, § 0 ; ans : estimé par les'
\echo '    bornes, comme 11 g — les deux divergent là où 75-77 ont posé)'
SELECT dep, voie, borne, plancher, ans, atome_annees,
       actes, depouilles, a_lire, sans_texte
FROM   n_dep
ORDER  BY atome_annees DESC, dep;

-- ---------------------------------------------------------------------------
-- 5. Ce que les bornes annonçaient et que la base dément
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. écarts entre l''estimation et la mesure'
\echo '   a. départements à fenêtre non nulle et ZÉRO atome-année noire'
\echo '      (75, 76 ou 77 ont posé dans toute la fenêtre : rien à faire)'
SELECT dep, borne, plancher, ans FROM n_dep WHERE atome_annees = 0 ORDER BY dep;

\echo ''
\echo '   b. atome-années noires HORS de toute fenêtre de 11 g'
\echo '      (un trou que les bornes ne voient pas : à instruire à part)'
SELECT t.dep, count(*) AS atome_annees, min(t.annee) AS de, max(t.annee) AS a
FROM   n_trou t
WHERE  NOT EXISTS (SELECT 1 FROM n_dep d WHERE d.dep = t.dep)
GROUP  BY t.dep ORDER BY 2 DESC;

-- ---------------------------------------------------------------------------
-- 6. La voie « chaînage », acte par acte — le premier chantier
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. les fenêtres qui se chaînent sans source neuve, acte par acte'
SELECT a.dep, a.date_effet, a.date_signature, a.decret, a.objet
FROM   n_acte a
JOIN   n_dep d ON d.dep = a.dep AND d.voie = 'chaînage'
ORDER  BY d.atome_annees DESC, a.dep, a.date_effet;

\echo ''
\echo '-- 7. les actes à LIRE (texte disponible, non dépouillé)'
SELECT a.dep, a.date_effet, a.decret, a.legifrance_id, a.objet
FROM   n_acte a
WHERE  NOT a.depouille AND a.texte_legifrance
ORDER  BY a.date_effet, a.dep;

\echo ''
\echo '-- fin de diag_intervalle_noir.sql — rien n''a été modifié.'

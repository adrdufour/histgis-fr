-- ============================================================================
-- histgis — 70_report_1940_1954.sql : peut-on REPORTER une composition ?
--
--   psql -d histgis -f sql/diag/70_report_1940_1954.sql
--
-- LECTURE SEULE. N'écrit ni dans `atom` ni dans `membership`.
--
-- LA QUESTION, ET POURQUOI ELLE COMMANDE TOUT LE RESTE
-- =====================================================
-- Le trou 1943-1999 a deux jalons — 1954 et 1968 — bornés chacun à une année.
-- Les étendre suppose de REPORTER une composition d'une date à la suivante, ce
-- qui revient à affirmer : *rien d'autre n'est arrivé dans l'intervalle*.
--
-- Cette affirmation n'est aujourd'hui certifiable nulle part : sur les 2 024
-- mouvements du registre cantonal, **785 ne sont pas datés**, dont 274
-- transferts isolés de communes que l'annexe VII de Gaudillère ne couvre pas
-- par construction.
--
-- **1940 → 1954 est le seul intervalle où l'on ait les deux bouts ET une liste
-- d'actes réputée complète.** Gaudillère n'y date que TROIS créations —
-- Sousceyrac (1949), Tende (1951), Brive-Nord et Sud (1951) — établies par
-- trois voies indépendantes. C'est donc le banc d'essai du report : si le
-- report échoue ici, il échouera partout ailleurs, où les actes sont dix fois
-- plus nombreux et moins bien datés.
--
-- *On teste la méthode là où elle a le plus de chances de marcher. Un échec y
-- est décisif ; un succès n'y prouve que le cas facile.*
--
-- LE PIÈGE DE CIRCULARITÉ, ET COMMENT IL EST ÉVITÉ
-- =================================================
-- `confirme_par_canton.py` a posé 3 361 codes INSEE — la classe
-- `ferme_canton` — **en retenant précisément les lignes dont le canton de 1954
-- concordait avec celui de 1940**. Les inclure ici ferait mesurer au banc sa
-- propre entrée : l'accord y est vrai par construction, et il gonflerait le
-- résultat de onze points sans rien dire du monde.
--
-- **Le banc ne retient donc que la classe `ferme`** — 26 531 rattachements
-- appariés sur le seul nom, exact et unique, sans que le canton de 1940 soit
-- jamais consulté. C'est la seule part du jalon de 1954 qui soit indépendante
-- de 1940.
--
-- Les fractions cantonales sont écartées des deux côtés : leur identifiant
-- porte le canton (`atome#canton`), donc deux fractions d'une même commune ne
-- se rapprochent jamais. Elles sont comptées au § 2.
--
-- DEUX MESURES, PAS UNE
-- =====================
--   § 4  ACCORD PAR COMMUNE — la commune est-elle au même canton ?
--        Sensible à la nomenclature : un canton renommé ou renuméroté fait
--        chuter la mesure sans qu'aucun territoire n'ait bougé.
--   § 5  ACCORD DES PARTITIONS — deux communes réunies en 1940 le sont-elles
--        encore en 1954 ? N'utilise aucun identifiant, seulement la relation
--        « ensemble ou non ». C'est la mesure introduite par `66` § 6 ter, et
--        la seule comparable d'un département à l'autre.
--
-- Prérequis : `59`/`68` joués (jalons en base), `c54_qualite`, `c67_attendu`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set date_1940 '1940-06-01'
\set date_1954 '1954-06-01'

\echo ''
\echo '============================================================'
\echo ' Le report 1940 -> 1954 : la méthode tient-elle ?'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.c54_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/68_cog1954_membership.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les deux états, atome par atome
--
-- On compare sur l'atome NU : `split_part(atom_id, '#', 1)` retire le suffixe
-- de fraction. Un atome retenu doit avoir EXACTEMENT UN canton de chaque côté ;
-- sinon la comparaison n'a pas de sens.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r70_1940;
CREATE TABLE r70_1940 AS
SELECT split_part(m.atom_id, '#', 1)        AS atome,
       min(m.unit_id)                       AS canton,
       count(DISTINCT m.unit_id)            AS n_cantons,
       count(*) FILTER (WHERE m.atom_id LIKE '%#%') AS n_fractions
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> :'date_1940'::date
GROUP  BY 1;

DROP TABLE IF EXISTS r70_1954;
CREATE TABLE r70_1954 AS
SELECT split_part(m.atom_id, '#', 1)        AS atome,
       min(m.unit_id)                       AS canton,
       count(DISTINCT m.unit_id)            AS n_cantons,
       min(q.insee)                         AS insee,
       min(q.qualite)                       AS qualite,
       min(q.appariement)                   AS appariement
FROM   membership m
JOIN   c54_qualite q ON q.membership_id = m.membership_id
WHERE  m.niveau = 'canton'
  AND  daterange(m.valid_from, m.valid_to, '[)') @> :'date_1954'::date
GROUP  BY 1;

CREATE INDEX r70_1940_idx ON r70_1940 (atome);
CREATE INDEX r70_1954_idx ON r70_1954 (atome);

\echo ''
\echo '-- 1. les deux états'
SELECT (SELECT count(*) FROM r70_1940) AS atomes_1940,
       (SELECT count(*) FROM r70_1954) AS atomes_1954,
       (SELECT count(*) FROM r70_1954 a JOIN r70_1940 b USING (atome))
                                       AS communs;

-- ---------------------------------------------------------------------------
-- 2. Ce que le banc ÉCARTE, et pourquoi — avant de mesurer quoi que ce soit
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r70_paire;
CREATE TABLE r70_paire AS
SELECT b.atome,
       b.canton                             AS c40,
       a.canton                             AS c54,
       a.insee,
       left(b.canton, 2)                    AS dep
FROM   r70_1954 a
JOIN   r70_1940 b USING (atome)
WHERE  a.appariement = 'ferme'      -- la seule classe indépendante de 1940
  AND  a.n_cantons = 1
  AND  b.n_cantons = 1;

CREATE INDEX r70_paire_idx ON r70_paire (dep, atome);

\echo ''
\echo '-- 2. le tamis, étape par étape'
SELECT
  (SELECT count(*) FROM r70_1954 a JOIN r70_1940 b USING (atome))
                                                    AS atomes_communs,
  (SELECT count(*) FROM r70_1954 a JOIN r70_1940 b USING (atome)
    WHERE a.appariement <> 'ferme')                 AS ecartes_ferme_canton,
  (SELECT count(*) FROM r70_1954 a JOIN r70_1940 b USING (atome)
    WHERE a.appariement = 'ferme' AND (a.n_cantons > 1 OR b.n_cantons > 1))
                                                    AS ecartes_multicantonal,
  (SELECT count(*) FROM r70_paire)                  AS retenus;

\echo ''
\echo '   `ecartes_ferme_canton` est le point capital : ces lignes ont été'
\echo '   RETENUES par `confirme_par_canton.py` PARCE QUE leur canton de 1954'
\echo '   concordait avec celui de 1940. Les garder ferait mesurer au banc sa'
\echo '   propre entrée. Seule la classe `ferme`, appariée sur le nom seul,'
\echo '   est indépendante.'

-- ---------------------------------------------------------------------------
-- 3. Les trois créations connues — le report DOIT s'y tromper
--
-- Sousceyrac (D. 5.9.1949), Tende (D. 10.9.1951), Brive-Sud (D. 13.9.1951).
-- Un report brut ne les connaît pas ; il place leurs communes dans le canton
-- de 1940. Ces désaccords-là sont EXPLIQUÉS, et le § 4 les isole : le taux
-- corrigé est celui d'un report AUGMENTÉ de la liste d'actes, qui est la
-- méthode qu'on veut vraiment éprouver.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. les 13 communes des trois décrets de 1949-1951'
SELECT a.canton_id AS canton_1954, a.insee, a.nom,
       p.c40       AS canton_1940,
       CASE WHEN p.atome IS NULL THEN 'hors banc'
            WHEN p.c40 = p.c54   THEN 'le report tombe juste (?)'
            ELSE 'désaccord ATTENDU' END AS verdict
FROM   c67_attendu a
LEFT   JOIN r70_paire p ON p.insee = a.insee
ORDER  BY a.canton_id, a.insee;

-- ---------------------------------------------------------------------------
-- 4. ACCORD PAR COMMUNE
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. accord par commune — national'
SELECT count(*)                                          AS communes,
       count(*) FILTER (WHERE c40 = c54)                 AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE c40 = c54)
             / nullif(count(*), 0), 2)                   AS pct,
       count(*) FILTER (WHERE c40 <> c54
                          AND insee IN (SELECT insee FROM c67_attendu))
                                                         AS dont_explique_par_decret
FROM   r70_paire;

\echo ''
\echo '-- 4 bis. les 20 départements les plus bas'
SELECT dep, count(*) AS communes,
       count(*) FILTER (WHERE c40 = c54) AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE c40 = c54)
             / nullif(count(*), 0), 1)   AS pct
FROM   r70_paire GROUP BY dep
HAVING count(*) >= 20
ORDER  BY pct LIMIT 20;

\echo ''
\echo '-- 4 ter. les désaccords, vus de près (20 premiers)'
SELECT p.dep, p.insee, p.c40, p.c54,
       (SELECT u.nom FROM unit u WHERE u.unit_id = p.c40) AS nom_1940,
       (SELECT u.nom FROM unit u WHERE u.unit_id = p.c54) AS nom_1954
FROM   r70_paire p WHERE p.c40 <> p.c54
ORDER  BY p.dep, p.insee LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. ACCORD DES PARTITIONS — la mesure qui n'utilise aucun identifiant
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. accord des partitions — national, puis les 12 plus bas'
DROP TABLE IF EXISTS r70_partition;
CREATE TABLE r70_partition AS
SELECT x.dep,
       count(*) FILTER (WHERE x.c40 = y.c40)                   AS ensemble_1940,
       count(*) FILTER (WHERE x.c40 = y.c40 AND x.c54 = y.c54) AS encore_ensemble,
       count(*) FILTER (WHERE x.c40 <> y.c40 AND x.c54 = y.c54) AS reunies_en_1954
FROM   r70_paire x JOIN r70_paire y ON y.dep = x.dep AND y.atome > x.atome
GROUP  BY x.dep;

SELECT 'FRANCE'                                  AS dep,
       sum(ensemble_1940)                        AS ensemble_1940,
       sum(encore_ensemble)                      AS encore_ensemble,
       round(100.0 * sum(encore_ensemble)
             / nullif(sum(ensemble_1940), 0), 2) AS pct_conserve
FROM   r70_partition
UNION ALL
SELECT dep, ensemble_1940, encore_ensemble,
       round(100.0 * encore_ensemble / nullif(ensemble_1940, 0), 2)
FROM  (SELECT * FROM r70_partition WHERE ensemble_1940 >= 50
        ORDER BY encore_ensemble::numeric / nullif(ensemble_1940, 0)
        LIMIT 12) x
ORDER  BY 4;

-- ---------------------------------------------------------------------------
-- 6. LE TÉMOIN — la même mesure sur 1954 -> 1968
--
-- Un taux ne se lit pas seul. `66` § 6 ter donne **89,8 %** de paires
-- conservées entre 1954 et 1968, sur un intervalle de quatorze ans où
-- l'annexe VII compte trente créations. 1940 -> 1954 en compte trois sur
-- quatorze ans : si le report est une méthode viable, l'écart entre les deux
-- doit être franc. S'il ne l'est pas, ce sont les mouvements NON DATÉS qui
-- dominent — et le report est mort partout.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. le témoin : 1954 -> 1968 vaut 89,8 % (66 § 6 ter, 147 976 paires)'
\echo '   3 créations en 14 ans ici, 30 en 14 ans là. Si les deux taux se'
\echo '   ressemblent, ce ne sont pas les créations qui font le désaccord :'
\echo '   ce sont les transferts isolés, que le registre ne date pas.'

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo '============================================================'

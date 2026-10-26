-- ============================================================================
-- histgis — diag_registre_complement.sql : ce que les actes trouvés par
-- Wikipédia disent des trous 1941-1998, AVANT d'en poser un seul
--
--   psql -d histgis -f sql/diag/diag_registre_complement.sql
--   (depuis la RACINE du dépôt : le \copy est relatif au répertoire de lancement)
--
-- LECTURE SEULE. Tables temporaires uniquement ; rien n'est écrit en base.
--
-- POURQUOI UN DIAGNOSTIC ET PAS UN AJOUT À `72`
-- =============================================
-- `cantons/decrets_complement.csv` porte 34 actes que `decrets_cantonaux.csv`
-- n'a pas. Les verser dans `acte_cantonal` ne serait pas neutre :
--
--   * `75` donne à chaque acte une date d'effet par `scrutin_cantonal`, qui ne
--     commence qu'en 1961. Un acte de 1946 recevrait l'effet du 4 juin 1961 —
--     quinze ans de faux. Les renouvellements de 1945, 1949, 1951, 1955 et 1958
--     manquent à la table ;
--   * `78` / `79` bornent le report arrière par les actes du registre : un acte
--     de plus raccourcit des périodes déjà posées ;
--   * aucun de ces 34 textes n'a encore été LU. Le CSV dit `a_lire = oui`.
--
-- Ce fichier mesure donc d'abord ce qu'ils toucheraient. Il prépare la lecture
-- au JO ; il ne la remplace pas.
--
-- Prérequis : `93`, `95`, `97` joués (p93_verdict, p95_trou, p97_trou).
-- Source : cantons/decrets_complement.csv (cantons/wikipedia/batir_complement.py)
-- ============================================================================

\set ON_ERROR_STOP on

CREATE TEMP TABLE wp_acte (
    cle text PRIMARY KEY, date_signature date, date_publication_jo date,
    decret text, deps text, objet text, categorie text, jo text, page_jo text,
    legifrance_id text, url text, communes_insee text, resume text,
    source text, a_lire text
);
\copy wp_acte FROM 'cantons/decrets_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE wp_dep AS
SELECT cle, date_signature, categorie, unnest(string_to_array(deps, ' ')) AS dep
FROM   wp_acte;

CREATE TEMP TABLE wp_commune AS
SELECT cle, date_signature, categorie, unnest(string_to_array(communes_insee, ' ')) AS insee
FROM   wp_acte WHERE communes_insee <> '';

\echo ''
\echo '-- 1. les actes du complément'
SELECT categorie, count(*) AS actes,
       min(date_signature) AS du, max(date_signature) AS au,
       count(*) FILTER (WHERE coalesce(jo, '') = '') AS sans_numero_de_jo
FROM   wp_acte GROUP BY categorie ORDER BY actes DESC;

\echo ''
\echo '-- 2. aucun ne doit déjà être au registre (contrôle d''identité)'
SELECT w.cle, w.legifrance_id
FROM   wp_acte w JOIN acte_cantonal a ON a.legifrance_id = w.legifrance_id
WHERE  w.legifrance_id <> '';
\echo '   Attendu : zéro ligne.'

-- ---------------------------------------------------------------------------
-- 3. Les communes nommées : que dit la base aujourd'hui ?
--
-- `accord_1940_1954` sur une commune qu'un acte déplace entre 1941 et 1953
-- serait une contradiction : les deux bouts diraient le même canton alors que
-- la commune a changé. Le cas attendu est `desaccord` — c'est le trou que
-- l'acte vient expliquer et dater.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. communes nommées par un acte : leur verdict dans 93, leurs trous dans 95 / 97'
-- Le verdict de 93 ne vaut que pour un acte signé dans sa fenêtre [1941, 1954).
SELECT c.cle, c.date_signature, c.insee,
       CASE WHEN c.date_signature < DATE '1954-01-01'
            THEN string_agg(DISTINCT v.verdict, ', ') ELSE '(hors fenêtre 93)' END AS verdict_93,
       CASE WHEN c.date_signature < DATE '1954-01-01'
            THEN string_agg(DISTINCT v.canton_1940 || ' -> ' || coalesce(v.canton_1954, '?'), ', ')
       END                                                                    AS cantons_93,
       bool_or(a.atom_id IS NULL)                                             AS ville_sans_atome_entier,
       (SELECT count(*) FROM p97_trou t
         WHERE t.insee = c.insee
           AND c.date_signature >= t.valid_from - 400
           AND c.date_signature <  t.valid_to)                                AS trous_97_autour,
       (SELECT count(*) FROM p95_trou t
         WHERE t.insee = c.insee
           AND c.date_signature >= t.valid_from - 400
           AND c.date_signature <  t.valid_to)                                AS trous_95_autour
FROM   wp_commune c
LEFT   JOIN atom a        ON a.insee_geofla = c.insee AND NOT a.fraction
LEFT   JOIN p93_verdict v ON v.atom_id = a.atom_id
GROUP  BY c.cle, c.date_signature, c.insee
ORDER  BY c.date_signature, c.insee;

-- ---------------------------------------------------------------------------
-- 4. Ce que chaque acte pourrait expliquer, département par département
--
-- Grossier par construction : un acte est rapproché de TOUS les trous de son
-- département dont la fenêtre contient sa date. C'est un plafond, pas un
-- compte ; il dit où lire en premier.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. trous de 95 / 97 dont la fenêtre contient la date d''un acte du complément'
SELECT * FROM (
SELECT d.cle, d.dep, d.date_signature, d.categorie,
       (SELECT count(*) FROM p97_trou t
         WHERE t.dep = d.dep AND NOT t.fraction
           AND d.date_signature >= t.valid_from AND d.date_signature < t.valid_to) AS trous_97,
       (SELECT count(*) FROM p95_trou t
         WHERE t.dep = d.dep AND NOT t.fraction
           AND d.date_signature >= t.valid_from AND d.date_signature < t.valid_to) AS trous_95,
       (SELECT count(*) FROM p93_verdict v
         WHERE v.dep = d.dep AND v.verdict = 'desaccord'
           AND d.date_signature < DATE '1954-01-01')                            AS desaccords_93_du_dep
FROM   wp_dep d
WHERE  d.categorie IN ('composition', 'departement')
) s
ORDER  BY s.trous_97 + s.trous_95 DESC, s.date_signature;

-- ---------------------------------------------------------------------------
-- 5. Le contrôle qui compte : une période POSÉE qui enjambe un acte
--
-- Une commune nommée par un acte, et dont `membership` porte UNE seule période
-- couvrant la date de l'acte de part et d'autre (un an avant, un an après),
-- est affirmée immobile là où l'acte dit qu'elle a bougé. C'est la seule
-- erreur que ce diagnostic puisse prouver ; les autres sections ne font que
-- localiser des trous.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. périodes posées qui enjambent un acte nommant la commune'
SELECT c.cle, c.date_signature, c.insee, m.unit_id, m.valid_from, m.valid_to
FROM   wp_commune c
JOIN   atom a       ON a.insee_geofla = c.insee AND NOT a.fraction
JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
WHERE  c.categorie = 'composition'
  AND  m.valid_from <= c.date_signature - 365
  AND  m.valid_to   >  c.date_signature + 365
ORDER  BY c.date_signature, c.insee;
\echo '   Attendu : zéro ligne pour un transfert de commune entière (Saint-Sulpice,'
\echo '   Rainsars, Taponnat, Dompierre, Saint-Couat). Une ligne ici est une période'
\echo '   reportée à tort, à défaire avant toute pose. Pour une ville partagée (Lens,'
\echo '   Saumur, Abbeville, Liévin), l''atome entier peut légitimement rester au'
\echo '   même canton : c''est une fraction qui bouge.'

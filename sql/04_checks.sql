-- ============================================================================
-- histgis — 04_checks.sql : rapport de recette après chargement
-- Rien n'est modifié ici, tout est en lecture.
-- ============================================================================

SET search_path TO histgis, public;

\echo ''
\echo '=== 1. Effectifs par date (attendu : 87-90 dep, 2861-3028 cantons) ==='
SELECT d::date AS date, c.*
FROM   (VALUES ('1870-06-01'), ('1876-06-01'), ('1885-06-01'),
               ('1900-06-01'), ('1914-06-01'), ('1928-06-01'),
               ('1936-06-01'), ('1940-06-01')) AS t(d),
       LATERAL count_units(d::date) c
ORDER  BY 1, c.niveau;

\echo ''
\echo '=== 2. Régime électoral déduit, par période ==='
SELECT regime, min(annee) AS depuis, max(annee) AS jusqu_a, count(*) AS n_annees
FROM   regime_electoral GROUP BY regime ORDER BY 2;

\echo ''
\echo '=== 3. Anomalies structurelles ==='
SELECT * FROM check_orphans();

\echo ''
\echo '=== 4. Trous de chronologie (top 10 par durée, niveau canton) ==='
SELECT * FROM check_gaps('canton') LIMIT 10;
\echo '--- volumétrie des trous ---'
SELECT 'canton' AS niveau, count(*) FROM check_gaps('canton')
UNION ALL SELECT 'circo', count(*) FROM check_gaps('circo');

\echo ''
\echo '=== 5. Couverture croisée canton / circo (communes Cassini) ==='
SELECT d::date AS date, count(*) FILTER (WHERE present_canton AND NOT present_circo) AS sans_circo,
       count(*) FILTER (WHERE present_circo AND NOT present_canton) AS sans_canton
FROM   (VALUES ('1876-06-01'), ('1885-06-01'), ('1914-06-01'), ('1936-06-01')) AS t(d),
       LATERAL check_coverage(d::date)
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '=== 6. Cantons à cheval sur plusieurs circonscriptions (1914, top 10) ==='
\echo '    (1914 = scrutin uninominal ; sous scrutin de liste le résultat est vide par construction)'
SELECT * FROM check_nesting('1914-06-01') LIMIT 10;

\echo ''
\echo '=== 7. Cohérence unit_version : la dernière version doit porter unit.nom ==='
SELECT count(*) AS versions_finales_divergentes
FROM (
    SELECT DISTINCT ON (uv.unit_id) uv.unit_id, uv.nom AS nom_final, u.nom
    FROM   unit_version uv JOIN unit u USING (unit_id)
    ORDER  BY uv.unit_id, uv.valid_from DESC
) s
WHERE nom_final IS DISTINCT FROM nom AND nom IS NOT NULL;

\echo ''
\echo '=== 8. Contrôle anti-chevauchement (doit renvoyer 0 partout) ==='
SELECT 'membership' AS objet, count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode
UNION ALL
SELECT 'unit_version', count(*)
FROM   unit_version a JOIN unit_version b
       ON a.unit_id = b.unit_id
      AND a.unit_version_id < b.unit_version_id AND a.periode && b.periode;

\echo ''
\echo '=== 9. Exemple : le canton de Montluçon-Est en 1885 ==='
SELECT unit_id, nom, dep, n_atomes
FROM   snapshot('1885-06-01', 'canton')
WHERE  nom ILIKE 'Montlu%'
ORDER  BY nom;

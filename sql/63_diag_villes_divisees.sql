-- ============================================================================
-- histgis — 63_diag_villes_divisees.sql : pourquoi 62 rend zéro
--
--   psql -d histgis -f sql/63_diag_villes_divisees.sql
--
-- LECTURE SEULE.
--
-- `62_recette_villes_divisees.sql` a rendu ZÉRO ville divisée aux trois
-- découpages testés, là où l'annexe VI en annonce 19, 22 et 41.
--
-- Un tel résultat ne se commente pas : il se diagnostique. **Un contrôle qui
-- rend zéro ne rend pas un verdict, il rend un silence** — et un silence
-- complet, sur trois découpages indépendants, désigne bien plus sûrement la
-- requête que la couche.
--
-- Trois hypothèses, de la plus probable à la moins :
--
--   1. LA COLONNE `cassini` DE L'ATOME-FRACTION. `62` groupe par `a.cassini`
--      pour réunir les fractions d'une même ville. Si la colonne porte
--      `cassini#circo` au lieu du cassini nu, le regroupement SÉPARE ce qu'il
--      devait réunir, et aucune ville ne peut jamais apparaître divisée —
--      quelle que soit la couche.
--   2. LES DATES. J'ai sondé 1893-12-01 pour le segment 1889, alors qu'un
--      segment 1893 existe : j'échantillonnais le découpage suivant. Erreur
--      réelle, mais qui ne peut pas produire zéro — le découpage de 1893 a lui
--      aussi des villes divisées.
--   3. LA COUCHE. Les fractions de circonscription n'auraient jamais été
--      posées pour 1870-1940. Ce serait un fait majeur, et il faudrait le
--      vérifier avant de le croire.
--
-- La section 1 est le TÉMOIN : s'il n'y a aucun rattachement de circonscription
-- à ces dates, tout le reste est sans objet.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '-- 1. TÉMOIN : y a-t-il des rattachements circo à ces dates ?'
SELECT t.d::date                        AS date_sonde,
       count(*)                         AS memberships,
       count(DISTINCT m.unit_id)        AS circonscriptions,
       count(DISTINCT m.atom_id)        AS atomes
FROM   (VALUES ('1878-12-01'), ('1890-12-01'), ('1930-12-01')) t(d)
LEFT   JOIN membership m
       ON m.niveau = 'circo'
      AND daterange(m.valid_from, m.valid_to, '[)') @> t.d::date
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '-- 2. la colonne `cassini` des atomes-fraction — hypothèse 1'
SELECT atom_id, cassini, fraction,
       cassini = split_part(atom_id, '#', 1) AS cassini_est_nu
FROM   atom
WHERE  fraction AND atom_id LIKE '%#%'
LIMIT  10;

\echo ''
\echo '   combien de fractions ont un `cassini` NON nu ?'
SELECT count(*) FILTER (WHERE cassini <> split_part(atom_id, '#', 1)) AS cassini_pollue,
       count(*)                                                       AS fractions_total
FROM   atom WHERE fraction AND atom_id LIKE '%#%';

\echo ''
\echo '-- 3. des fractions de CIRCONSCRIPTION existent-elles ?'
\echo '   (une fraction de canton porte #<canton>, une de circo #<circo>)'
SELECT CASE WHEN EXISTS (SELECT 1 FROM unit u
                          WHERE u.unit_id = split_part(a.atom_id, '#', 2)
                            AND u.niveau = 'circo')      THEN 'circo'
            WHEN EXISTS (SELECT 1 FROM unit u
                          WHERE u.unit_id = split_part(a.atom_id, '#', 2)
                            AND u.niveau = 'canton')     THEN 'canton'
            ELSE 'inconnu' END                            AS suffixe_designe,
       count(*)                                           AS atomes
FROM   atom a WHERE a.fraction AND a.atom_id LIKE '%#%'
GROUP  BY 1 ORDER BY atomes DESC;

\echo ''
\echo '-- 4. une commune a-t-elle plusieurs circos à une date, ailleurs ?'
\echo '   (groupé sur le cassini NU, pour contourner l''hypothèse 1)'
SELECT count(*) AS communes_multi_circo
FROM  (SELECT split_part(a.atom_id, '#', 1) AS ville, m.valid_from
       FROM   membership m
       JOIN   atom a ON a.atom_id = m.atom_id
       WHERE  m.niveau = 'circo'
       GROUP  BY 1, 2
       HAVING count(DISTINCT m.unit_id) > 1) x;

\echo ''
\echo '   et par segment de découpage :'
SELECT u.segment_depuis                    AS segment,
       count(DISTINCT x.ville)             AS villes_divisees
FROM  (SELECT split_part(a.atom_id, '#', 1) AS ville,
              m.valid_from, m.unit_id
       FROM   membership m
       JOIN   atom a ON a.atom_id = m.atom_id
       WHERE  m.niveau = 'circo') x
JOIN   unit u ON u.unit_id = x.unit_id
WHERE  EXISTS (SELECT 1
               FROM  (SELECT split_part(a2.atom_id, '#', 1) AS v, m2.valid_from
                      FROM   membership m2
                      JOIN   atom a2 ON a2.atom_id = m2.atom_id
                      WHERE  m2.niveau = 'circo'
                      GROUP  BY 1, 2 HAVING count(DISTINCT m2.unit_id) > 1) y
               WHERE y.v = x.ville AND y.valid_from = x.valid_from)
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '-- 5. les segments réellement présents, pour corriger les dates de 62'
SELECT segment_depuis, count(*) AS circonscriptions,
       min(m.valid_from) AS ouverture, max(m.valid_to) AS fermeture
FROM   unit u
LEFT   JOIN membership m ON m.unit_id = u.unit_id AND m.niveau = 'circo'
WHERE  u.niveau = 'circo' AND u.segment_depuis BETWEEN 1870 AND 1940
GROUP  BY 1 ORDER BY 1;

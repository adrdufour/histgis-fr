-- ============================================================================
-- diag_corse_1976.sql — les trous corses de 1974-1981, avant d'écrire une règle
--
--   psql -d histgis -f sql/diag/diag_corse_1976.sql | tee build/corse_1976.txt
--
-- LECTURE SEULE. Écrit le 23 septembre 2026, après `95`.
--
-- `95` n'a posé aucun trou corse : 0 % d'accord, 2 304 atome-années. Les deux
-- bouts ne portent jamais le même identifiant, parce que les cantons corses
-- changent de code au 1er janvier 1976 (20NN → 2ANN / 2BNN). Mais le § 5 b du
-- diag des deux bouts montre deux familles mêlées :
--
--   * des RENUMÉROTATIONS : 2048 Santa-Maria-Siché → 2A48 Santa-Maria-Siché,
--     2060 Vezzani → 2B60 Vezzani. Même numéro, même nom ;
--   * des FUSIONS de 1973 : 2057 Valle-d'Alesani → 2B37 Orezza-Alesani,
--     2027 Muro → 2B05 Belgodère. Numéro différent ; et 2037 Piedicroce →
--     2B37 Orezza-Alesani, même numéro mais nom différent — le canton-mère
--     d'une fusion qui garde son numéro.
--
-- Une règle « même numéro » poserait la première famille. La question est de
-- savoir si elle se sépare proprement de la seconde, et si le test « nommé par
-- un acte » fonctionne en Corse : il compare des codes INSEE, et ceux de la
-- Corse ont changé en 1976 comme ceux de ses cantons. **Un décret de 1973
-- écrit `20xxx` ; l'atome porte `2Axxx`.** Si le test ne voit pas le décret de
-- 1973, une commune déplacée par lui passe pour « non nommée » — c'est le
-- piège que `75` a évité par normalisation, et qu'on pourrait avoir recréé.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '-- 1. les actes corses du registre, et ce qui en a été lu'
SELECT e.date_effet, a.date_signature,
       coalesce(nullif(a.decret, ''), '(non numéroté)') AS decret,
       string_agg(DISTINCT d.dep, ' ')                  AS deps,
       left(a.objet, 45)                                AS objet,
       (SELECT count(*) FROM acte_composition c
         WHERE c.date_acte = a.date_signature
           AND c.dep IN ('20', '2A', '2B'))             AS lignes_lues,
       (SELECT string_agg(DISTINCT left(c.insee, 2), ' ') FROM acte_composition c
         WHERE c.date_acte = a.date_signature
           AND c.dep IN ('20', '2A', '2B'))             AS prefixes_insee
FROM   acte_cantonal a
JOIN   acte_departement d ON d.legifrance_id = a.legifrance_id
JOIN   acte_effet e       ON e.legifrance_id = a.legifrance_id
WHERE  d.dep IN ('20', '2A', '2B')
  AND  e.date_effet < DATE '1999-01-01'
GROUP  BY 1, 2, 3, 5, a.date_signature
ORDER  BY 1;

-- Les trous corses, recalculés comme dans `95`.
DROP TABLE IF EXISTS pg_temp.k_trou;
CREATE TEMP TABLE k_trou AS
WITH l AS (
    SELECT m.atom_id, m.unit_id, m.valid_to,
           lead(m.unit_id)    OVER w AS unit_d,
           lead(m.valid_from) OVER w AS from_d
    FROM   membership m
    WHERE  m.niveau = 'canton'
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT l.atom_id, a.insee_geofla AS insee, l.valid_to AS debut, l.from_d AS fin,
       l.unit_id AS unit_g, l.unit_d
FROM   l JOIN atom a ON a.atom_id = l.atom_id
WHERE  l.from_d > l.valid_to
  AND  l.valid_to >= DATE '1969-01-01' AND l.from_d <= DATE '1999-01-01'
  AND  l.unit_id LIKE '20%'
  AND  NOT (a.fraction OR l.atom_id LIKE '%#%');

-- « Nommé », de deux façons : par le code de l'atome (le test de `95`), et
-- par ce code ramené à `20` — la forme qu'écrit un décret d'avant 1976.
ALTER TABLE k_trou ADD COLUMN nomme_95 boolean, ADD COLUMN nomme_20 boolean;
UPDATE k_trou t SET
  nomme_95 = EXISTS (SELECT 1 FROM acte_composition c
                      WHERE c.insee = t.insee
                        AND (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                            >= t.debut
                        AND (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                            <  t.fin),
  nomme_20 = EXISTS (SELECT 1 FROM acte_composition c
                      WHERE c.insee IN (t.insee, '20' || substr(t.insee, 3))
                        AND (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                            >= t.debut
                        AND (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                            <  t.fin);

\echo ''
\echo '-- 2. le test « nommé » voit-il le décret de 1973 ?'
\echo '   Si nomme_20 dépasse nomme_95, le test de `95` est aveugle en Corse'
\echo '   avant 1976 — et il l''est ailleurs pour tout code INSEE changé.'
SELECT count(*) AS trous,
       count(*) FILTER (WHERE nomme_95) AS nommes_selon_95,
       count(*) FILTER (WHERE nomme_20) AS nommes_code_20_compris
FROM   k_trou;

\echo ''
\echo '-- 3. les paires de cantons, avec leur famille'
SELECT t.unit_g, vg.nom AS nom_1968, t.unit_d, vd.nom AS nom_droite,
       CASE WHEN substr(t.unit_g, 3) = substr(t.unit_d, 3)
             AND lower(vg.nom) = lower(vd.nom)  THEN 'a. même numéro, même nom'
            WHEN substr(t.unit_g, 3) = substr(t.unit_d, 3)
                                                THEN 'b. même numéro, autre nom'
            ELSE                                     'c. autre numéro' END AS famille,
       count(*)                                  AS trous,
       count(*) FILTER (WHERE t.nomme_20)        AS nommes,
       min(t.debut) AS de, max(t.fin) AS a
FROM   k_trou t
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = t.unit_g
                      ORDER BY v.valid_from DESC LIMIT 1) vg ON true
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = t.unit_d
                      ORDER BY v.valid_from DESC LIMIT 1) vd ON true
GROUP  BY 1, 2, 3, 4, 5 ORDER BY 5, 6 DESC;

\echo ''
\echo '-- 4. le bilan par famille'
SELECT famille, count(*) AS trous,
       count(*) FILTER (WHERE nommes > 0) AS paires_touchees_par_un_acte,
       sum(trous) AS total_trous
FROM (
    SELECT CASE WHEN substr(t.unit_g, 3) = substr(t.unit_d, 3)
                 AND lower(vg.nom) = lower(vd.nom) THEN 'a. même numéro, même nom'
                WHEN substr(t.unit_g, 3) = substr(t.unit_d, 3)
                                                   THEN 'b. même numéro, autre nom'
                ELSE                                    'c. autre numéro' END AS famille,
           count(*) AS trous, count(*) FILTER (WHERE t.nomme_20) AS nommes
    FROM   k_trou t
    LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = t.unit_g
                          ORDER BY v.valid_from DESC LIMIT 1) vg ON true
    LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = t.unit_d
                          ORDER BY v.valid_from DESC LIMIT 1) vd ON true
    GROUP  BY t.unit_g, t.unit_d, 1
) x GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 5. hors de la Corse : le test de `95` est-il aveugle à un code changé ?'
\echo '   Atomes posés par `95` dont un code INSEE ANTÉRIEUR (commune_moderne)'
\echo '   est nommé dans le trou alors que le code actuel ne l''est pas.'
DO $$
DECLARE n bigint;
BEGIN
    IF to_regclass('histgis.commune_moderne') IS NULL
       OR to_regclass('histgis.p95_qualite') IS NULL THEN
        RAISE NOTICE 'commune_moderne ou p95_qualite absente : § 5 sauté.';
        RETURN;
    END IF;
    EXECUTE $q$
        SELECT count(*) FROM p95_qualite q
        JOIN   membership m ON m.membership_id = q.membership_id
        JOIN   atom a ON a.atom_id = q.atom_id
        WHERE  EXISTS (
               SELECT 1 FROM commune_moderne cm
               JOIN   acte_composition c ON c.insee = cm.code
               WHERE  cm.atom_id = q.atom_id
                 AND  cm.code <> a.insee_geofla
                 AND  (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                      >= m.valid_from
                 AND  (SELECT min(s.tour1) FROM scrutin_cantonal s WHERE s.tour1 >= c.date_acte)
                      <  m.valid_to)
    $q$ INTO n;
    RAISE NOTICE 'lignes de 95 nommées sous un ANCIEN code INSEE : %', n;
END $$;

\echo ''
\echo '-- fin — rien n''a été écrit.'

-- ============================================================================
-- 44_absorption_ancienne.sql — communes absorbées puis rétablies AVANT 1943
--
--   psql -d histgis -f sql/44_absorption_ancienne.sql
--
-- Le cas, et l'erreur qui a précédé
-- ---------------------------------
-- Adrien, sur la carte : « Cherré, dans la Sarthe, est absente de 1886 à 1888 ».
--
-- **Premier diagnostic, et il était faux.** La nomenclature TRF-GIS donne un
-- fichier par année ; la ligne de Cherré figure en 1885, manque en 1886 et 1887,
-- revient en 1888 à l'identique — même canton, même arrondissement, même
-- département. J'en ai conclu à une omission de la source, et écrit un fichier
-- pour refermer les trous courts bornés par la même unité. Son en-tête
-- affirmait : « aucune commune n'a jamais cessé d'exister deux ans pour renaître
-- à l'identique ».
--
-- C'était une affirmation sur le monde que rien ne fondait, et elle est fausse.
-- Adrien a produit la source : **La Ferté-Bernard absorbe Cherré et
-- Saint-Antoine-de-Rochefort en 1886 ; Cherré reprend son indépendance en
-- 1888.** (Cassini/EHESS, via l'article Wikipédia « Cherré (Sarthe) ».)
--
-- Et la nomenclature le disait déjà, dans une colonne que je n'avais pas lue :
--
--   1885  30448,72132,3,SAINT-ANTOINE-DE-ROCHEFORT,…,7210,LA FERTE-BERNARD
--                  ↑↑↑↑↑ ↑
--                  code INSEE de LA FERTÉ-BERNARD, et le drapeau `com_act` = 3
--
-- Saint-Antoine, absorbée le même jour et jamais rétablie, porte déjà le code
-- de l'absorbante. Les deux disparaissent en 1886 ; seule Cherré revient.
--
-- **La disparition n'était pas un trou dans la source : elle ÉTAIT l'événement.**
--
-- Ce que cela change, et pourquoi le fichier fautif méritait d'être jeté
-- ---------------------------------------------------------------------
-- Les valeurs qu'il aurait posées sont pourtant les bonnes : La Ferté-Bernard
-- relève du canton 7210 — dont elle est le chef-lieu — et de la même
-- circonscription que Cherré. Refermer le trou « parce que c'est la même unité
-- de part et d'autre » donne ici exactement le même résultat que recopier
-- l'absorbante.
--
-- **C'est précisément pour cela qu'il fallait le récrire.** Un résultat juste
-- tiré d'une règle fausse est le pire cas : rien ne le signale, et la règle
-- resservira ailleurs, où elle ne tombera pas juste. Une commune absorbée par
-- une voisine d'un AUTRE canton produirait le même trou, et l'ancien fichier
-- l'aurait refermé avec le mauvais canton — sans qu'aucune recette bronche.
--
-- La règle, et d'où vient la filiation
-- ------------------------------------
--   « Pendant son absorption, le territoire d'une commune reçoit le
--     rattachement de la commune qui l'absorbe. »
--
-- C'est mot pour mot la règle de `41_retablissement.sql`, voie `mere`, appliquée
-- à la série ancienne au lieu de la couche moderne. Ce qui change est la
-- SOURCE de la filiation : `insee_mvt` ne commence qu'en 1943 et ne dit rien de
-- 1886. Elle est donc portée ici par une table explicite, avec sa référence.
--
-- L'ampleur : une seule commune dans toute la série
-- -------------------------------------------------
-- Le signe d'une absorption suivie d'un rétablissement est un **trou intérieur**
-- dans la chronologie d'un atome. Mesuré sur les deux couches :
--
--   couche canton : 1 690 trous — 1 de 2 ans, 1 689 de 48 ans
--   couche circo  : 1 684 trous — 1 de 2 ans, 1 683 de 48 ans
--
-- Les trous de 48 ans sont l'Alsace-Moselle de 1871 à 1919, qui doivent rester
-- ouverts. Le seul autre est Cherré. **La table ci-dessous n'a donc qu'une
-- ligne**, et c'est un fait mesuré, pas une limite de l'écriture : toute autre
-- absorption ancienne suivie d'un rétablissement se signalerait de la même
-- façon, et la requête de la section 4 la retrouvera.
--
-- Trois garde-fous
-- ----------------
--   1. La filiation vient de la table, jamais d'une déduction. Pas de ligne,
--      pas de correctif.
--   2. Les atomes-mères doivent être UNANIMES sur la fenêtre. Deux atomes
--      portent le code 72132 — La Ferté-Bernard et Saint-Antoine absorbée — et
--      seul le premier a des rattachements après 1886 ; mais si deux mères
--      donnaient deux unités, on s'abstiendrait.
--   3. Rien n'est posé sur une période déjà occupée.
--
-- Réversible : `absorption_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- 0. La filiation, portée par la source et non déduite
--
-- Table permanente : elle documente autant qu'elle sert. Toute ligne ajoutée
-- doit citer une source publiquement vérifiable — c'est la contrainte du
-- projet, et elle vaut ici plus qu'ailleurs puisque rien dans la base ne
-- permet de contrôler la filiation.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS absorption_ancienne (
    insee       char(5) NOT NULL,     -- la commune absorbée puis rétablie
    insee_mere  char(5) NOT NULL,     -- celle qui l'absorbe
    absorbee_le date    NOT NULL,
    retablie_le date    NOT NULL,
    source      text    NOT NULL,
    PRIMARY KEY (insee, absorbee_le)
);

INSERT INTO absorption_ancienne (insee, insee_mere, absorbee_le, retablie_le, source)
VALUES ('72080', '72132', DATE '1886-01-01', DATE '1888-01-01',
        'Cassini/EHESS, via fr.wikipedia.org/wiki/Cherré_(Sarthe) — '
        'La Ferté-Bernard absorbe Cherré et Saint-Antoine-de-Rochefort en 1886 ; '
        'Cherré reprend son indépendance en 1888. Corroboré par la nomenclature '
        'TRF-GIS : Saint-Antoine y porte le code INSEE 72132 dès 1885.')
ON CONFLICT (insee, absorbee_le) DO NOTHING;

\echo ''
\echo '=== 0. La filiation retenue ==='
SELECT a.insee, coalesce(nf.nom, '?') AS commune,
       a.insee_mere, coalesce(nm.nom, '?') AS mere,
       a.absorbee_le, a.retablie_le
  FROM absorption_ancienne a
  LEFT JOIN noms_geofla nf ON nf.insee = a.insee
  LEFT JOIN noms_geofla nm ON nm.insee = a.insee_mere
 ORDER BY a.absorbee_le;

-- ---------------------------------------------------------------------------
-- 1. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS absorption_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    insee         char(5) NOT NULL,
    insee_mere    char(5) NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM absorption_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE absorption_trace;

-- ---------------------------------------------------------------------------
-- 2. Ce que l'absorbante portait pendant l'absorption
--
-- Garde-fou 2 : on ne retient une (fenêtre, niveau) que si TOUTES les mères
-- s'accordent. `count(DISTINCT unit_id) = 1` — la même clause que `40`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS abs_periode;
CREATE TEMP TABLE abs_periode AS
WITH brut AS (
    SELECT af.atom_id, mm.unit_id, mm.niveau,
           lower(mm.periode * daterange(c.absorbee_le, c.retablie_le, '[)')) AS valid_from,
           upper(mm.periode * daterange(c.absorbee_le, c.retablie_le, '[)')) AS valid_to,
           c.insee, c.insee_mere
      FROM absorption_ancienne c
      JOIN atom af ON af.insee_geofla = c.insee      AND NOT af.fraction
      JOIN atom am ON am.insee_geofla = c.insee_mere AND NOT am.fraction
      JOIN membership mm ON mm.atom_id = am.atom_id
                        AND mm.periode && daterange(c.absorbee_le, c.retablie_le, '[)')
     WHERE NOT isempty(mm.periode * daterange(c.absorbee_le, c.retablie_le, '[)'))
)
SELECT atom_id, min(unit_id) AS unit_id, niveau, valid_from, valid_to,
       insee, insee_mere
  FROM brut
 GROUP BY atom_id, niveau, valid_from, valid_to, insee, insee_mere
HAVING count(DISTINCT unit_id) = 1;

-- Garde-fou 3 : rien sur une période déjà occupée.
DELETE FROM abs_periode p
 WHERE EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
                  AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

\echo ''
\echo '=== 1. Ce qui va être posé ==='
SELECT p.niveau, p.unit_id, coalesce(u.nom, '?') AS unite,
       p.valid_from, p.valid_to, p.insee, p.insee_mere
  FROM abs_periode p
  LEFT JOIN unit u ON u.unit_id = p.unit_id AND u.niveau = p.niveau
 ORDER BY p.insee, p.niveau, p.valid_from;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM abs_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO absorption_trace (membership_id, atom_id, unit_id, niveau,
                              valid_from, valid_to, insee, insee_mere)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.insee, p.insee_mere
  FROM ins i
  JOIN abs_periode p ON p.atom_id = i.atom_id AND p.niveau = i.niveau
                    AND p.valid_from = i.valid_from;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Cherré, le cas qui a révélé le défaut ==='
SELECT m.niveau, m.unit_id, coalesce(u.nom, '?') AS unite,
       m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 44' END AS origine
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN absorption_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '72080' AND m.valid_from < DATE '1941-01-01'
 ORDER BY m.niveau, m.valid_from;
-- Attendu : canton de La Ferté-Bernard continu de 1870 à 1941, et la chaîne des
-- circonscriptions sans trou entre 1885 et 1889.
--
-- Note, et elle est importante : les unités posées ici sont les MÊMES que
-- celles qui bordent le trou, parce que La Ferté-Bernard est le chef-lieu du
-- canton de Cherré. **Cette coïncidence ne valide pas la règle** — elle rendait
-- au contraire l'erreur précédente indétectable. Voir l'en-tête.

\echo ''
\echo '=== 3. Saint-Antoine-de-Rochefort, absorbée sans retour ==='
\echo '    Contrôle par le témoin : elle ne doit RIEN recevoir. Son atome'
\echo '    s''arrête en 1886, et son territoire est porté depuis par celui de'
\echo '    La Ferté-Bernard, dont elle partage le code INSEE 72132.'
SELECT a.atom_id, a.insee_geofla, m.niveau, m.unit_id,
       m.valid_from, m.valid_to
  FROM atom a
  LEFT JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
 WHERE a.insee_geofla = '72132'
 ORDER BY a.atom_id, m.valid_from;

\echo ''
\echo '=== 4. Trous intérieurs restants — la table est-elle complète ? ==='
WITH suite AS (
    SELECT m.atom_id, m.niveau, m.unit_id, m.valid_to,
           lead(m.valid_from) OVER (PARTITION BY m.atom_id, m.niveau
                                    ORDER BY m.valid_from) AS suivant
      FROM membership m
)
SELECT extract(year FROM suivant)::int - extract(year FROM valid_to)::int AS annees,
       count(*) AS trous, count(DISTINCT atom_id) AS atomes
  FROM suite WHERE suivant IS NOT NULL AND suivant > valid_to
 GROUP BY 1 ORDER BY 1;
-- Attendu : plus aucun trou court, et 48 ans pour l'Alsace-Moselle.
--
-- **C'est la requête à relancer pour trouver d'autres absorptions anciennes.**
-- Tout trou intérieur de quelques années signale une commune absorbée puis
-- rétablie. Il ne faut PAS le refermer d'office : il faut chercher l'acte,
-- nommer l'absorbante, et ajouter une ligne à `absorption_ancienne`.

\echo ''
\echo '=== 5. Aucun chevauchement ==='
SELECT count(*) AS chevauchements
  FROM membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

-- ---------------------------------------------------------------------------
-- 5. Pour défaire
--
--   DELETE FROM membership m USING absorption_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE absorption_trace;
-- ---------------------------------------------------------------------------

-- ============================================================================
-- 44_lacune_nomenclature.sql — refermer une omission de la nomenclature source
--
--   psql -d histgis -f sql/44_lacune_nomenclature.sql
--
-- Le défaut, trouvé le 20 août 2026 par Cherré
-- --------------------------------------------
-- Adrien, sur la carte : « Cherré, dans la Sarthe, est absente de 1886 à 1888 ».
--
-- Elle l'est, et la source en est la cause. La nomenclature TRF-GIS donne un
-- fichier par année, et la ligne de Cherré figure en 1885, disparaît en 1886 et
-- 1887, puis revient en 1888 :
--
--   1885  9222,72080,1,CHERRE,Cherré,72,SARTHE,…,7210,10,LA FERTE-BERNARD,…
--   1886  (absente)
--   1887  (absente)
--   1888  9222,72080,1,CHERRE,Cherré,72,SARTHE,…,7210,10,LA FERTE-BERNARD,…
--
-- **Les deux lignes sont identiques** — même canton, même arrondissement, même
-- département. Rien n'a bougé. Ce n'est pas un événement administratif, c'est
-- une omission : la commune manque à deux millésimes, et le chargement, qui
-- suit fidèlement la source, produit deux périodes séparées par un trou.
--
-- Aucune commune n'a jamais cessé d'exister deux ans pour renaître à
-- l'identique. Une commune supprimée est absorbée par une autre, et le
-- territoire suit ; ici le territoire n'est réclamé par personne.
--
-- Le seuil, et pourquoi il n'est pas arbitraire
-- ---------------------------------------------
-- Mesuré sur les deux couches, tous atomes confondus, avant d'écrire :
--
--   couche canton : 1 690 trous intérieurs — 1 de 2 ans, 1 689 de 48 ans
--   couche circo  : 1 684 trous intérieurs — 1 de 2 ans, 1 683 de 48 ans
--
-- **La distribution est bimodale et rien ne se tient entre les deux.** Les
-- trous de 48 ans sont l'Alsace-Moselle, de 1871 à 1919 : ils doivent rester
-- ouverts, l'annexion est un fait. Le seul autre est Cherré.
--
-- Un seuil de 5 ans sépare donc les deux populations sans les frôler. Il n'est
-- pas choisi pour faire passer un cas : il est posé dans un intervalle où la
-- donnée est vide de 3 à 47 ans.
--
-- Ce garde-fou est doublé par la comparaison des unités : on ne referme un trou
-- que si **la même unité** se trouve avant et après. Sur l'Alsace-Moselle, ce
-- test seul ne suffirait pas — TRF-GIS réutilise les codes de canton de part et
-- d'autre de 1871 ([[trfgis-pieges-source]]), donc l'unité peut coïncider sans
-- que le territoire ait été français entre-temps. C'est la durée qui tranche.
--
-- La règle
-- --------
--   « Un trou intérieur de moins de cinq ans, borné de part et d'autre par la
--     MÊME unité, et que nul autre rattachement ne réclame, est une omission de
--     la nomenclature : on le referme. »
--
-- Quatre garde-fous
-- -----------------
--   1. Durée < 5 ans. Écarte l'Alsace-Moselle sans avoir à la nommer.
--   2. Même unité avant et après. Un vrai changement d'appartenance laisse deux
--      unités différentes, et n'est pas une omission.
--   3. L'atome ne doit avoir AUCUN autre rattachement au même niveau sur le
--      trou. S'il en a un, le trou n'en est pas un.
--   4. Alarme au-delà de 10 cas : la population mesurée est de 2. Un saut
--      signalerait que la sélection a dérivé, non que l'histoire a changé.
--
-- Le vrai correctif est en amont
-- ------------------------------
-- Ce fichier répare la base ; il ne répare pas la chaîne. `trfgis_extract.py`
-- pourrait reconduire une commune absente d'un millésime lorsqu'elle reparaît
-- inchangée au suivant. C'est noté dans `RESTE_A_FAIRE.md` — mais cela impose
-- un `rebuild.sh` complet, et ce fichier permet de ne pas l'attendre.
--
-- Réversible : `lacune_trace`, section 4.
-- Rejouable : retire son propre passage avant de recommencer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set seuil_annees 5

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lacune_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    annees        int  NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM lacune_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE lacune_trace;

-- ---------------------------------------------------------------------------
-- 1. Les trous intérieurs, et ce qui les borne
--
-- `lead()` sur les périodes triées d'un même (atome, niveau) : quand la fin
-- d'une période précède le début de la suivante, il y a trou.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS lac_trou;
CREATE TEMP TABLE lac_trou AS
WITH suite AS (
    SELECT m.atom_id, m.niveau, m.unit_id, m.valid_from, m.valid_to,
           lead(m.valid_from) OVER (PARTITION BY m.atom_id, m.niveau
                                    ORDER BY m.valid_from) AS suivant_debut,
           lead(m.unit_id)    OVER (PARTITION BY m.atom_id, m.niveau
                                    ORDER BY m.valid_from) AS suivant_unit
      FROM membership m
)
SELECT atom_id, niveau, unit_id,
       valid_to      AS trou_de,
       suivant_debut AS trou_a,
       extract(year FROM suivant_debut)::int
       - extract(year FROM valid_to)::int AS annees
  FROM suite
 WHERE suivant_debut IS NOT NULL
   AND suivant_debut > valid_to
   -- garde-fou 2 : la même unité de part et d'autre
   AND suivant_unit = unit_id;

\echo ''
\echo '=== 1. Trous intérieurs bornés par la même unité, par durée ==='
SELECT annees, count(*) AS trous, count(DISTINCT atom_id) AS atomes,
       string_agg(DISTINCT niveau, ', ') AS niveaux
  FROM lac_trou GROUP BY 1 ORDER BY 1;
-- Mesuré le 20 août 2026 : 2 ans -> 2 trous (Cherré, aux deux niveaux),
-- 48 ans -> 3 372 (l'Alsace-Moselle, qui doit rester ouverte).

-- ---------------------------------------------------------------------------
-- 2. Ceux qu'on referme
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS lac_pose;
CREATE TEMP TABLE lac_pose AS
SELECT t.*
  FROM lac_trou t
 WHERE t.annees < :seuil_annees            -- garde-fou 1
   -- garde-fou 3 : rien d'autre ne réclame l'atome sur le trou
   AND NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = t.atom_id AND m.niveau = t.niveau
                      AND m.periode && daterange(t.trou_de, t.trou_a, '[)'));

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM lac_pose;
    IF n > 10 THEN
        RAISE EXCEPTION 'lac_pose contient % trous, attendu de l''ordre de 2. '
                        'La sélection a dérivé : rien n''est posé.', n;
    END IF;
END $$;

\echo ''
\echo '=== 2. Ce qui va être refermé ==='
SELECT p.atom_id, a.insee_geofla, coalesce(n.nom, '?') AS commune,
       p.niveau, p.unit_id, coalesce(u.nom, '?') AS unite,
       p.trou_de, p.trou_a, p.annees
  FROM lac_pose p
  JOIN atom a ON a.atom_id = p.atom_id
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
  LEFT JOIN unit u ON u.unit_id = p.unit_id AND u.niveau = p.niveau
 ORDER BY p.atom_id, p.niveau;

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, trou_de, trou_a FROM lac_pose
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO lacune_trace (membership_id, atom_id, unit_id, niveau,
                          valid_from, valid_to, annees)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to,
       extract(year FROM i.valid_to)::int - extract(year FROM i.valid_from)::int
  FROM ins i;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Cherré, le cas qui a révélé le défaut ==='
SELECT m.niveau, m.unit_id, coalesce(u.nom, '?') AS unite,
       m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 44' END AS origine
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN lacune_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '72080' AND m.valid_from < DATE '1941-01-01'
 ORDER BY m.niveau, m.valid_from;
-- Attendu : canton de La Ferté-Bernard continu de 1870 à 1941, et la chaîne
-- des circonscriptions sans trou entre 1885 et 1889.

\echo ''
\echo '=== 4. Aucun chevauchement ==='
SELECT count(*) AS chevauchements
  FROM membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id AND a.periode && b.periode;

\echo ''
\echo '=== 5. Trous intérieurs restants, par durée ==='
WITH suite AS (
    SELECT m.atom_id, m.niveau, m.valid_to,
           lead(m.valid_from) OVER (PARTITION BY m.atom_id, m.niveau
                                    ORDER BY m.valid_from) AS suivant
      FROM membership m
)
SELECT extract(year FROM suivant)::int - extract(year FROM valid_to)::int AS annees,
       count(*) AS trous
  FROM suite WHERE suivant IS NOT NULL AND suivant > valid_to
 GROUP BY 1 ORDER BY 1;
-- Attendu : plus aucun trou court. Ne doivent rester que ceux de 48 ans —
-- l'Alsace-Moselle — et les trous bornés par des unités DIFFÉRENTES, qui sont
-- des changements d'appartenance et non des omissions.

-- ---------------------------------------------------------------------------
-- 5. Pour défaire
--
--   DELETE FROM membership m USING lacune_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE lacune_trace;
-- ---------------------------------------------------------------------------

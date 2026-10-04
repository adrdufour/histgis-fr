-- ============================================================================
-- 57_paris_circo_1848.sql — 1848-1852 : le département EST la circonscription
--
--   psql -d histgis -f sql/57_paris_circo_1848.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/57_paris_circo_1848.sql
--
-- Ce que ce fichier corrige
-- -------------------------
-- `54` laissait 1848-1852 vide, et son en-tête parlait d'un trou : « aucune
-- division n'est transcrite ». **C'était mal dit.** L'atlas ne transcrit rien
-- parce qu'il n'y avait rien à transcrire.
--
-- Le gouvernement provisoire de 1848 rétablit le **scrutin majoritaire
-- plurinominal dans le cadre du département**. Les élections du 23 avril 1848
-- (Assemblée constituante) et des 13-14 mai 1849 (Assemblée législative) se
-- tiennent ainsi : le département forme une seule circonscription, avec autant
-- de sièges que de représentants à élire. **Il n'existe aucune circonscription
-- territoriale à l'intérieur de Paris entre 1848 et 1852.**
--
-- Sources : Wikipédia, « Élections législatives françaises de 1848 »,
-- « … de 1849 » et « Élections en France sous la Deuxième République ».
-- Vérifiables par URL publique, comme l'exige le projet.
--
-- Ce n'est donc pas une interpolation
-- -----------------------------------
-- Poser une unité unique sur les 48 quartiers n'invente rien : c'est énoncer
-- que le découpage était départemental. TRF-GIS fait exactement cela pour
-- 1870-1876 et 1885-1889, deux autres périodes de scrutin de liste, avec son
-- unité « Seine » — et la base l'accepte sans broncher depuis le début.
--
-- **La distinction vaut d'être retenue** : un trou de source et une absence
-- d'objet se ressemblent sur une carte, et ne se traitent pas pareil. Celui-ci
-- se comble, celui de 1941-1945 ne se comble pas — il n'y a pas eu d'élection.
--
-- Une limite déclarée
-- -------------------
-- La circonscription est le département de la SEINE, qui déborde largement
-- Paris : elle comprend les communes de la banlieue. Nous ne posons que sa
-- part parisienne, faute d'atomes pour le reste avant 1870. L'unité porte donc
-- un nom qui le dit, et sa géométrie n'est pas celle de la circonscription
-- réelle mais de ce que nous en connaissons.
--
-- Réversible : `paris_1848_trace`.
-- Prérequis : `54_paris_circo_1815.sql` joué — il crée les atomes `PV01`…`PV48`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set debut '1848-01-01'
\set fin   '1852-01-01'
\set unite 'L7501@1848'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = 'PV01') THEN
        RAISE EXCEPTION E'Atomes PV01…PV48 absents.\n'
            '  psql -d histgis -1 -v appliquer=1 -v src=circo/paris_circo_1815.csv'
            ' -f sql/54_paris_circo_1815.sql';
    END IF;
END $$;

\echo ''
\echo '=== 1. La periode est-elle bien vide ? ==='
SELECT count(*) AS rattachements_parisiens
  FROM membership m
  JOIN atom a ON a.atom_id = m.atom_id AND a.atom_id LIKE 'PV%'
 WHERE m.niveau = 'circo'
   AND m.periode && daterange(:'debut', :'fin', '[)');
-- Attendu : 0. Sinon `54` a deja pose quelque chose et il faut comprendre quoi.

\echo ''
\echo '=== 2. Combien d''atomes vont etre rattaches ==='
SELECT count(*) AS quartiers FROM atom WHERE atom_id LIKE 'PV%';
-- Attendu : 48.

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS paris_1848_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- Effacer sa trace AVANT de juger : la leçon de `55`, dont le garde-fou se
-- prenait lui-même pour la donnée qu'il devait protéger.
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM paris_1848_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM paris_1848_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE paris_1848_trace;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    VALUES (:'unite', 'circo', '75', '75-00', 'liste', 1848,
            'Seine — scrutin de liste départemental (part parisienne)', false)
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO paris_1848_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT :'unite', 'Seine — scrutin de liste départemental',
       :'debut'::date, :'fin'::date
 WHERE EXISTS (SELECT 1 FROM paris_1848_trace t
                WHERE t.quoi = 'unit' AND t.cle = :'unite');

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT a.atom_id, :'unite', 'circo', :'debut'::date, :'fin'::date
      FROM atom a WHERE a.atom_id LIKE 'PV%'
    RETURNING membership_id
)
INSERT INTO paris_1848_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 3. Pose ==='
SELECT quoi, count(*) FROM paris_1848_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 1 unite, 48 rattachements.

\echo ''
\echo '=== 4. Paris de 1815 a 1863 : la chaine est-elle continue ? ==='
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) AS quartiers,
       count(DISTINCT m.unit_id) AS circos,
       string_agg(DISTINCT u.regime, ', ') AS regime
  FROM (VALUES ('1816-06-01'::date),('1825-06-01'),('1840-06-01'),
               ('1849-06-01'),('1850-06-01'),('1855-06-01'),
               ('1860-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN atom a ON a.atom_id = m.atom_id AND a.atom_id LIKE 'PV%'
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo'
 WHERE a.atom_id IS NOT NULL OR m.atom_id IS NULL
 GROUP BY d ORDER BY d;
-- 1849 et 1850 doivent desormais donner 48 quartiers, 1 circonscription,
-- regime LISTE. Plus aucun trou entre 1815 et 1863.

\echo ''
\echo '=== 5. Pour tout defaire ==='
\echo '    DELETE membership puis unit, via paris_1848_trace.'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

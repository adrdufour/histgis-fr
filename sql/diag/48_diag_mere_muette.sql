-- ============================================================================
-- 48_diag_mere_muette.sql — DIAGNOSTIC, lecture seule
--
--   psql -d histgis -f sql/diag/48_diag_mere_muette.sql
--
-- La question
-- -----------
-- `40_scission_circo.sql` comble les trous de la couche circo par l'unanimité
-- des VOISINS DE CANTON. Il s'abstient quand les voisins se taisent — c'est-à-
-- dire quand aucun autre membre du canton n'a lui-même de circonscription à
-- cette date.
--
-- Port-Saint-Louis-du-Rhône, née en 1904 par détachement d'Arles, est le cas
-- pur : son canton 1304 ne compte en 1870 que deux membres, elle et une
-- FRACTION d'Arles — laquelle n'a pas de circonscription, précisément parce que
-- le garde-fou 3 de `40` écarte les fractions. Le voisin unique est muet par
-- construction, et la circularité est parfaite.
--
-- Pourtant la réponse existe à côté : l'atome PLEIN d'Arles, `1256`, porte une
-- chaîne circo continue de 1870 à 1941. Et la ligne native de Port-Saint-Louis
-- en 1902, `U1303@1902`, concorde déjà avec celle de sa mère — ce qui est une
-- confirmation gratuite de la filiation.
--
-- D'où la règle candidate : **quand les voisins se taisent, demander à la
-- mère.** C'est le principe de `46_creation_serie.sql`, appliqué à la couche
-- circo au lieu de la couche cantonale.
--
-- Ce que ce fichier mesure, et pourquoi il ne pose rien
-- ----------------------------------------------------
-- Écrire un correctif pour un seul atome serait disproportionné ; en écrire un
-- général sans savoir combien de cas il touche serait aveugle. Ce diagnostic
-- compte la classe AVANT d'écrire quoi que ce soit.
--
-- Il ne modifie rien. Aucun INSERT, aucun UPDATE, aucun DELETE sur les tables
-- de la base.
--
-- Prérequis : `40` et `46` joués (`hac_filiation` est créée par `46`).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.hac_filiation') IS NULL THEN
        RAISE EXCEPTION 'hac_filiation absente : jouer 46_creation_serie.sql '
                        'avant (c''est lui qui charge la filiation HAC).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les trous : atome PLEIN, avec canton, sans circonscription
--
-- On reste sur les atomes pleins. Les fractions sont écartées par le garde-fou
-- 3 de `40`, et la décision du 20 août 2026 est d'attendre les vraies
-- géométries (ANR-COMMUNES, embargo levé le 1er septembre) plutôt que de leur
-- poser des rattachements qui feraient dessiner 14 281 km² deux fois.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS mm_trou;
CREATE TEMP TABLE mm_trou AS
SELECT mc.atom_id, y, make_date(y, 1, 1) AS d, mc.unit_id AS canton
  FROM generate_series(1870, 1940) y
  JOIN membership mc ON mc.niveau = 'canton'
                    AND mc.periode @> make_date(y, 1, 1)
  JOIN atom a ON a.atom_id = mc.atom_id AND NOT a.fraction
 WHERE NOT EXISTS (SELECT 1 FROM membership mx
                    WHERE mx.atom_id = mc.atom_id AND mx.niveau = 'circo'
                      AND mx.periode @> make_date(y, 1, 1));

CREATE INDEX mm_trou_idx ON mm_trou (canton, d);
ANALYZE mm_trou;

-- ---------------------------------------------------------------------------
-- 2. Ceux dont les voisins de canton se taisent
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS mm_muet;
CREATE TEMP TABLE mm_muet AS
SELECT t.*
  FROM mm_trou t
 WHERE NOT EXISTS (
    SELECT 1
      FROM membership mk
      JOIN membership mv ON mv.atom_id = mk.atom_id AND mv.niveau = 'circo'
                        AND mv.periode @> t.d
     WHERE mk.niveau = 'canton' AND mk.unit_id = t.canton
       AND mk.atom_id <> t.atom_id AND mk.periode @> t.d);

ANALYZE mm_muet;

-- ---------------------------------------------------------------------------
-- 3. La mère nommée par HAC a-t-elle une circonscription à cette date ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS mm_mere;
CREATE TEMP TABLE mm_mere AS
SELECT m.atom_id, m.y, m.d, m.canton,
       f.cassini_mere, f.nom_mere_hac,
       (SELECT count(DISTINCT mv.unit_id)
          FROM atom am
          JOIN membership mv ON mv.atom_id = am.atom_id AND mv.niveau = 'circo'
                            AND mv.periode @> m.d
         WHERE am.cassini = f.cassini_mere AND NOT am.fraction) AS circos_mere,
       (SELECT min(mv.unit_id)
          FROM atom am
          JOIN membership mv ON mv.atom_id = am.atom_id AND mv.niveau = 'circo'
                            AND mv.periode @> m.d
         WHERE am.cassini = f.cassini_mere AND NOT am.fraction) AS circo_mere
  FROM mm_muet m
  JOIN atom a ON a.atom_id = m.atom_id
  LEFT JOIN hac_filiation f ON f.cassini_fille = a.cassini AND f.voie = 'unique';

\echo ''
\echo '=== 1. Verdict, sur toute la serie ==='
SELECT CASE WHEN cassini_mere IS NULL      THEN 'pas de filiation HAC unique'
            WHEN coalesce(circos_mere,0)=0 THEN 'mere muette elle aussi'
            WHEN circos_mere = 1           THEN 'MERE RENSEIGNEE, reponse unique'
            ELSE                                'mere partagee entre circos'
       END AS verdict,
       count(*) AS annees_communes, count(DISTINCT atom_id) AS atomes
  FROM mm_mere GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '=== 2. Le meme verdict, hors Alsace-Moselle annexee (1871-1918) ==='
-- Entre 1871 et 1918 l'Alsace-Moselle n'a legitimement AUCUNE circonscription
-- francaise : la mere y est muette pour une bonne raison, et ce vide doit
-- rester. Le filtre est grossier — il ecarte aussi des cas legitimes ailleurs
-- en France — mais il donne l'ordre de grandeur du reste.
SELECT CASE WHEN cassini_mere IS NULL      THEN 'pas de filiation HAC unique'
            WHEN coalesce(circos_mere,0)=0 THEN 'mere muette elle aussi'
            WHEN circos_mere = 1           THEN 'MERE RENSEIGNEE, reponse unique'
            ELSE                                'mere partagee entre circos'
       END AS verdict,
       count(*) AS annees_communes, count(DISTINCT atom_id) AS atomes
  FROM mm_mere WHERE y NOT BETWEEN 1871 AND 1918 GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '=== 3. Les communes concernees, quand la mere repond ==='
SELECT n.nom, n.dep, mm.nom_mere_hac AS mere,
       min(mm.y) AS de, max(mm.y) AS a, count(*) AS annees
  FROM mm_mere mm
  JOIN atom a ON a.atom_id = mm.atom_id
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
 WHERE mm.circos_mere = 1
 GROUP BY n.nom, n.dep, mm.nom_mere_hac
 ORDER BY annees DESC, n.dep, n.nom
 LIMIT 40;

\echo ''
\echo '=== 4. Port-Saint-Louis-du-Rhone, le cas qui a pose la question ==='
SELECT mm.y, mm.canton, mm.nom_mere_hac AS mere, mm.circo_mere
  FROM mm_mere mm
  JOIN atom a ON a.atom_id = mm.atom_id AND a.insee_geofla = '13078'
 ORDER BY mm.y;
-- Attendu : 1870 a 1901, mere Arles, et la circo de la mere alternant
-- L1301@1870 et U1303@1876 au rythme du mode de scrutin. La ligne native de
-- 1902 de Port-Saint-Louis, U1303@1902, doit prolonger la meme chaine — c'est
-- une confirmation independante de la filiation, et non une hypothese.

\echo ''
\echo '=== 5. Ce fichier n''a rien ecrit ==='
\echo '    Diagnostic seul. Le correctif ne sera ecrit qu''au vu de la taille'
\echo '    de la classe mesuree en 1 et 2.'

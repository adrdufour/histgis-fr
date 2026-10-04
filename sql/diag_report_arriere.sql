-- ============================================================================
-- histgis — diag_report_arriere.sql : ce que le report arrière de `11` dessine
-- avant la naissance attestée
--
--   psql -d histgis -f sql/diag_report_arriere.sql
--
-- NE POSE RIEN, NE MODIFIE RIEN. Trois requêtes, à lire avant de décider.
--
-- LA QUESTION, ET POURQUOI ELLE EST MAL POSÉE SI ON VA VITE
-- =========================================================
-- Le 6 septembre 2026, en travaillant la Seine d'avant 1870, on a remarqué
-- qu'Alfortville — créée en 1885 — est dessinée dès 1870. Formulé comme ça,
-- cela ressemble à un relâchement à corriger.
--
-- Ce n'en est pas un. `11_scission.sql` prolonge délibérément vers l'arrière le
-- rattachement des communes nées ENTRE 1870 et 1940, que TRF-GIS suit et dont
-- l'atome existe. C'est un **pari écrit**, avec sa raison : *le territoire
-- d'une commune née après la série appartenait au canton de sa mère.* Et il a
-- été contrôlé — ETAT § 3.5, ANR valide 357 dates de naissance sur 359.
--
-- Le pari porte sur l'ATTRIBUTION, et il est bon. Ce qu'il coûte est
-- l'IDENTITÉ : le sol est dessiné sous le nom de la fille, pas de la mère.
--
-- CE QUE LE CORRECTIF NAÏF COÛTERAIT, MESURÉ HORS BASE
-- =====================================================
-- Fermer la vie de ces atomes à leur naissance attestée :
--
--     367 atomes, dans 70 départements
--     4 572,2 km² qui cesseraient d'être dessinés à 1870
--     naissances : 92 dans les années 1870, 70 dans les 1880,
--                  44 / 63 / 25 / 48 / 24 ensuite, 1 après 1950
--
-- C'est exactement le trou que `11` existe pour fermer, et l'ordre de grandeur
-- de la couture de la trame hybride (4 542,8 km²). **Le correctif naïf rouvre
-- ce que le fichier ferme.**
--
-- LE VRAI CORRECTIF, SI ON LE VEUT UN JOUR
-- =========================================
-- Ce n'est pas « fermer la vie de la fille ». C'est **rendre le sol à la mère
-- jusqu'à la naissance de la fille** : la fille disparaît de la carte avant sa
-- date, et son territoire est dessiné sous le nom qui était le sien. Cela
-- change les attributions de 1870-1940, demande sa propre recette de
-- couverture, et n'a rien à voir avec le chantier de la Seine.
--
-- *Un défaut d'identité et un défaut de couverture se ressemblent sur une
-- carte. Le premier se corrige en renommant, le second en comblant — et les
-- confondre fait perdre le second en croyant gagner le premier.*
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '=== 1. Combien d atomes vivent avant leur naissance ANR, et ou ==='
WITH naissance AS (
    SELECT atom_id, min(lower(periode)) AS ne_le
      FROM atom_geom_anr GROUP BY atom_id
), avant AS (
    SELECT m.atom_id, n.ne_le, min(lower(m.periode)) AS vit_depuis
      FROM membership m
      JOIN naissance n ON n.atom_id = m.atom_id
      JOIN atom a ON a.atom_id = m.atom_id AND NOT a.fraction
     GROUP BY m.atom_id, n.ne_le
    HAVING min(lower(m.periode)) < n.ne_le
)
SELECT count(*)                                        AS atomes,
       min(ne_le)                                      AS naissance_la_plus_tot,
       max(ne_le)                                      AS naissance_la_plus_tard,
       round((sum(ST_Area(g.geom)) / 1e6)::numeric, 1) AS km2_cumules
  FROM avant a
  JOIN atom_geom_anr g ON g.atom_id = a.atom_id AND lower(g.periode) = a.ne_le;
-- Attendu, mesure hors base sur le GeoPackage : 367 atomes, 4 572,2 km2.
-- Un ecart notable voudrait dire que la base et le GeoPackage ne portent pas
-- la meme arbitration de variantes, et il faudrait le comprendre.

\echo ''
\echo '=== 2. Par decennie de naissance ==='
WITH naissance AS (
    SELECT atom_id, min(lower(periode)) AS ne_le FROM atom_geom_anr GROUP BY atom_id
)
SELECT (extract(year FROM n.ne_le)::int / 10) * 10 AS decennie,
       count(*) AS atomes
  FROM membership m
  JOIN naissance n ON n.atom_id = m.atom_id
  JOIN atom a ON a.atom_id = m.atom_id AND NOT a.fraction
 GROUP BY m.atom_id, n.ne_le
HAVING min(lower(m.periode)) < n.ne_le
 ORDER BY 1;

\echo ''
\echo '=== 3. Les vingt plus grosses, nommement ==='
WITH naissance AS (
    SELECT atom_id, min(lower(periode)) AS ne_le FROM atom_geom_anr GROUP BY atom_id
), avant AS (
    SELECT m.atom_id, n.ne_le, min(lower(m.periode)) AS vit_depuis
      FROM membership m
      JOIN naissance n ON n.atom_id = m.atom_id
      JOIN atom a ON a.atom_id = m.atom_id AND NOT a.fraction
     GROUP BY m.atom_id, n.ne_le
    HAVING min(lower(m.periode)) < n.ne_le
)
SELECT a.atom_id, at.insee_geofla,
       a.vit_depuis, a.ne_le,
       round((ST_Area(g.geom) / 1e6)::numeric, 2) AS km2
  FROM avant a
  JOIN atom at ON at.atom_id = a.atom_id
  JOIN atom_geom_anr g ON g.atom_id = a.atom_id AND lower(g.periode) = a.ne_le
 ORDER BY 5 DESC LIMIT 20;

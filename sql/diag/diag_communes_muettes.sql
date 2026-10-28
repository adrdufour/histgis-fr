-- ============================================================================
-- diag_communes_muettes.sql — les communes qu'ANR dessine et que la base ne
-- rattache à RIEN (ni canton ni circonscription), période par période
--
--   psql -d histgis -f sql/diag/diag_communes_muettes.sql
--   → build/communes_sans_rattachement.csv
--
-- LECTURE SEULE. Écrit le 27 octobre 2026, après Missy-aux-Bois (02) : sans
-- canton de 1941 à 1968, son sol était donné au voisin par le comblement de
-- `84`, et l'erreur ne se voyait pas sur la carte. Depuis le bloc « LES
-- MUETS » de `84`, ces communes restent BLANCHES ; ce fichier en donne la
-- liste, avec la même garde : un polygone recouvert à plus de 5 % par une
-- commune rattachée est un ancien contour (fusion), pas un oubli.
--
-- Une période de moins de trois ans qui commence au 1941-01-01 et finit à la
-- fin du polygone ANR est le plus souvent une commune absorbée entre 1941 et
-- 1943, dont le canton s'arrête au 1er janvier 1941 au lieu de sa fusion.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\copy (WITH vie AS (SELECT atom_id, range_agg(periode) * datemultirange(daterange('1919-01-01', '2013-01-01')) AS mr FROM atom_geom_anr GROUP BY 1), rat AS (SELECT split_part(atom_id, '#', 1) AS mere, range_agg(periode) AS mr FROM membership GROUP BY 1), trou AS (SELECT v.atom_id, unnest(v.mr - coalesce(r.mr, '{}'::datemultirange)) AS p FROM vie v JOIN atom a USING (atom_id) LEFT JOIN rat r ON r.mere = v.atom_id WHERE NOT a.fraction AND v.atom_id NOT LIKE '%#%'), muet AS (SELECT t.*, g.geom FROM trou t JOIN atom_geom_anr g ON g.atom_id = t.atom_id AND g.periode @> lower(t.p) WHERE upper(t.p) - lower(t.p) > 1 AND NOT EXISTS (SELECT 1 FROM atom_geom_anr o JOIN membership m ON split_part(m.atom_id, '#', 1) = o.atom_id AND m.periode @> lower(t.p) WHERE o.atom_id <> t.atom_id AND o.periode @> lower(t.p) AND o.geom && g.geom AND ST_Area(ST_Intersection(o.geom, g.geom)) > 0.05 * ST_Area(g.geom))) SELECT (SELECT trim(u.dep::text) FROM membership m JOIN unit u USING (unit_id) WHERE split_part(m.atom_id, '#', 1) = t.atom_id ORDER BY abs(m.valid_from - lower(t.p)) LIMIT 1) AS departement, (SELECT c.namecom FROM atom_geom_anr g JOIN anr_commune c USING (poly_id) WHERE g.atom_id = t.atom_id AND g.periode && t.p ORDER BY lower(g.periode) LIMIT 1) AS commune, a.insee_geofla AS insee, t.atom_id AS atome, lower(t.p) AS sans_rattachement_du, upper(t.p) AS au, round((upper(t.p) - lower(t.p)) / 365.25, 1) AS annees, (SELECT m.unit_id || ' ' || coalesce(u.nom, '') FROM membership m JOIN unit u USING (unit_id) WHERE m.atom_id = t.atom_id AND m.niveau = 'canton' AND m.valid_to <= lower(t.p) ORDER BY m.valid_to DESC LIMIT 1) AS canton_avant, (SELECT m.unit_id || ' ' || coalesce(u.nom, '') FROM membership m JOIN unit u USING (unit_id) WHERE m.atom_id = t.atom_id AND m.niveau = 'canton' AND m.valid_from >= upper(t.p) ORDER BY m.valid_from LIMIT 1) AS canton_apres, '' AS decision, '' AS note FROM muet t JOIN atom a USING (atom_id) ORDER BY 1, 2, 5) TO 'build/communes_sans_rattachement.csv' WITH (FORMAT csv, HEADER true)

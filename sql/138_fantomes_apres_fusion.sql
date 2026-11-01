-- ============================================================================
-- histgis — 138_fantomes_apres_fusion.sql : rattachements posés sur une
--           commune après sa fusion, ramenés sur la commune qu'ANR dessine
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/138_fantomes_apres_fusion.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/138_fantomes_apres_fusion.sql
--   psql -d histgis -1 -v defaire=1 -f sql/138_fantomes_apres_fusion.sql
--
-- Signalé par Adrien le 28 octobre 2026 : deux Moussy-Verneuil (02) en 1996.
-- ANR dit la fusion dans le `poly_id` : `1923_1_0000000009731658` (Moussy-sur-
-- Aisne, atome 24286) et `1923_0_0000000009731658` (Verneuil-Courtonne,
-- 39485) sont les morceaux d'avant 1923 du polygone IGN
-- `COMMUNE_0000000009731658`, Moussy-Verneuil, qu'ANR donne à 39485 dès 1923.
-- Or les jalons, qui lisent par code INSEE, avaient posé le canton de Craonne
-- de 1968 à 2013 sur 24286 : sans polygone ANR, l'export lui prêtait le
-- contour GEOFLA de la commune actuelle, par-dessus 39485 (que la règle
-- `muet_meme_commune` de `137` venait de rattacher aussi).
--
-- Ici : tout rattachement d'un atome APRÈS LA FIN DE SA VIE DANS ANR, quand un
-- successeur est désigné par ANR — un atome dont le polygone, au lendemain de
-- cette fin, couvre plus de la moitié du dernier polygone de l'atome ET porte
-- le même numéro IGN. La partie d'après la fin est retirée du fantôme
-- (ligne coupée ou retirée) et donnée au successeur là où il n'a rien à ce
-- niveau. Elle n'est PAS touchée quand le successeur a, sur cette partie, une
-- AUTRE unité au même niveau : commune associée restée dans un autre canton
-- (fusions-associations des années 1970). Ces lignes-là sont listées dans
-- `build/fantomes_divergents.csv`, à relire ; de même les atomes sans
-- successeur ANR, dans le même fichier.
--
-- Exception à l'exception, signalée par Adrien le 1er novembre 2026 : Aurent
-- (04, atome 1891), absorbée par Braux en 1932, était au canton d'Entrevaux
-- de 1954 à 2013, sans circonscription. Ce n'était pas une commune associée :
-- elle porte le code GEOFLA 04042 de Castellet-lès-Sausses (7097), à qui
-- Braux a cédé le hameau en 1961, et les jalons lisant par INSEE avaient posé
-- sur les deux atomes la ligne de Castellet. D'où le cas `jumeau` : une ligne
-- ouverte APRÈS la fin de vie, que porte aussi, sur toute sa durée, un atome
-- vivant de même code GEOFLA, est celle du jumeau. Elle est retirée, même
-- divergente, et rien n'est donné au successeur. Les lignes ouvertes avant la
-- fin (quartiers de Paris rognés par les bois en 1925) n'en sont pas.
--
-- Réversible : `p138_trace`. Rejouable. Après `137`, dont il corrige la règle
-- `muet_meme_commune` sans la défaire (le successeur garde ce qu'elle lui a
-- donné : c'était juste ; c'est le fantôme qui était de trop).
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p138_trace (
    quoi text NOT NULL, cle text NOT NULL,
    atom_id text, unit_id text, niveau text,
    ancien_from date, ancien_to date,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM p138_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
UPDATE membership m SET valid_to = t.ancien_to
  FROM p138_trace t WHERE t.quoi = 'coupe' AND t.cle = m.membership_id::text;
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT cle::bigint, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p138_trace WHERE quoi = 'retire';
DELETE FROM p138_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- La vie de chaque atome dans ANR, et son successeur à la fin
DROP TABLE IF EXISTS t138_vie;
CREATE TEMP TABLE t138_vie AS
SELECT atom_id, max(upper(periode)) AS fin FROM atom_geom_anr
 WHERE atom_id NOT LIKE '%#%' GROUP BY 1 HAVING max(upper(periode)) < DATE '2020-01-01';

DROP TABLE IF EXISTS t138_succ;
CREATE TEMP TABLE t138_succ AS
SELECT DISTINCT ON (v.atom_id) v.atom_id, v.fin, y.atom_id AS succ,
       substring(cx.poly_id from '([0-9]{10,})$') = substring(cy.poly_id from '([0-9]{10,})$') AS meme_ign
FROM   t138_vie v
JOIN   atom_geom_anr x ON x.atom_id = v.atom_id AND upper(x.periode) = v.fin
JOIN   anr_commune cx ON cx.poly_id = x.poly_id
JOIN   atom_geom_anr y ON y.periode @> v.fin AND y.atom_id <> v.atom_id AND y.atom_id NOT LIKE '%#%'
                      AND y.geom && x.geom
JOIN   anr_commune cy ON cy.poly_id = y.poly_id
WHERE  ST_Area(ST_Intersection(y.geom, x.geom)) > 0.5 * ST_Area(x.geom)
ORDER  BY v.atom_id, ST_Area(ST_Intersection(y.geom, x.geom)) DESC;

-- Les lignes qui débordent la fin de vie
DROP TABLE IF EXISTS t138_ligne;
CREATE TEMP TABLE t138_ligne AS
SELECT m.membership_id, m.atom_id, m.unit_id, m.niveau, m.valid_from, m.valid_to, v.fin,
       daterange(greatest(m.valid_from, v.fin), m.valid_to) AS apres,
       s.succ, coalesce(s.meme_ign, false) AS meme_ign,
       EXISTS (SELECT 1 FROM membership o
                WHERE o.atom_id = s.succ AND o.niveau = m.niveau AND o.unit_id <> m.unit_id
                  AND o.periode && daterange(greatest(m.valid_from, v.fin), m.valid_to)) AS divergent,
       m.valid_from >= v.fin AND EXISTS (
           SELECT 1 FROM atom j JOIN membership o ON o.atom_id = j.atom_id
            WHERE j.insee_geofla = a.insee_geofla AND j.atom_id <> m.atom_id
              AND o.niveau = m.niveau AND o.unit_id = m.unit_id
              AND o.periode @> daterange(m.valid_from, m.valid_to)
              AND EXISTS (SELECT 1 FROM atom_geom_anr g
                           WHERE g.atom_id = j.atom_id AND g.periode @> m.valid_from)) AS jumeau
FROM   membership m
JOIN   t138_vie v ON v.atom_id = m.atom_id
JOIN   atom a ON a.atom_id = m.atom_id
LEFT   JOIN t138_succ s ON s.atom_id = m.atom_id
WHERE  m.valid_to > v.fin;

DROP TABLE IF EXISTS t138_agir;
CREATE TEMP TABLE t138_agir AS
SELECT * FROM t138_ligne WHERE (meme_ign AND NOT divergent) OR jumeau;

\echo ''
\echo '-- lignes au-delà de la fin de vie ANR'
SELECT CASE WHEN jumeau THEN 'jumeau'
            WHEN succ IS NULL THEN 'sans_successeur'
            WHEN NOT meme_ign THEN 'successeur_autre_ign'
            WHEN divergent THEN 'divergent'
            ELSE 'ramene' END AS cas,
       niveau, count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       round(sum((upper(apres) - lower(apres)) / 365.25)) AS atome_annees
FROM   t138_ligne GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '-- témoin : Aurent (1891), jumeau GEOFLA de Castellet-lès-Sausses (7097)'
SELECT atom_id, niveau, unit_id, valid_from, valid_to, fin FROM t138_agir
 WHERE atom_id = '1891' ORDER BY niveau, valid_from;

\echo ''
\echo '-- témoin : Moussy-sur-Aisne (24286) → Moussy-Verneuil (39485)'
SELECT atom_id, succ, niveau, unit_id, valid_from, valid_to, fin FROM t138_agir
 WHERE atom_id = '24286' ORDER BY niveau, valid_from;

\copy (SELECT (SELECT trim(u.dep::text) FROM unit u WHERE u.unit_id = l.unit_id) AS departement, (SELECT c.namecom FROM atom_geom_anr g JOIN anr_commune c USING (poly_id) WHERE g.atom_id = l.atom_id ORDER BY upper(g.periode) DESC LIMIT 1) AS commune, l.atom_id AS atome, l.fin AS fin_anr, (SELECT c.namecom FROM atom_geom_anr g JOIN anr_commune c USING (poly_id) WHERE g.atom_id = l.succ AND g.periode @> l.fin) AS successeur, l.succ AS atome_successeur, l.niveau, l.unit_id || ' ' || coalesce((SELECT u.nom FROM unit u WHERE u.unit_id = l.unit_id), '') AS unite_fantome, (SELECT string_agg(DISTINCT o.unit_id || ' ' || coalesce(u.nom, ''), ' ; ') FROM membership o JOIN unit u USING (unit_id) WHERE o.atom_id = l.succ AND o.niveau = l.niveau AND o.periode && l.apres) AS unite_successeur, lower(l.apres) AS du, upper(l.apres) AS au, CASE WHEN l.succ IS NULL THEN 'sans_successeur' WHEN NOT l.meme_ign THEN 'successeur_autre_ign' ELSE 'divergent' END AS cas, '' AS decision, '' AS note FROM t138_ligne l WHERE NOT (l.meme_ign AND NOT l.divergent) AND NOT l.jumeau ORDER BY 1, 2, 7, 10) TO 'build/fantomes_divergents.csv' WITH (FORMAT csv, HEADER true)

\if :{?appliquer}
-- Coupe ou retrait côté fantôme
INSERT INTO p138_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to
  FROM t138_agir WHERE valid_from >= fin;
INSERT INTO p138_trace (quoi, cle, atom_id, unit_id, niveau, ancien_to)
SELECT 'coupe', membership_id::text, atom_id, unit_id, niveau, valid_to
  FROM t138_agir WHERE valid_from < fin;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t138_agir WHERE valid_from >= fin);
UPDATE membership m SET valid_to = a.fin
  FROM t138_agir a WHERE a.membership_id = m.membership_id AND a.valid_from < a.fin;

-- Le successeur reçoit ce qui lui manque à ce niveau
-- Deux fantômes peuvent avoir le même successeur (Thionville : Garche,
-- Koeking, Oeutrange) : à recouvrement, le premier par date de début l'emporte.
WITH manque AS (
    SELECT a.succ, a.unit_id, a.niveau, a.membership_id,
           unnest(datemultirange(a.apres)
                  - coalesce((SELECT range_agg(o.periode) FROM membership o
                               WHERE o.atom_id = a.succ AND o.niveau = a.niveau),
                             '{}'::datemultirange)) AS p
      FROM t138_agir a WHERE a.meme_ign AND NOT a.divergent),
num AS (SELECT *, row_number() OVER (PARTITION BY succ, niveau ORDER BY lower(p), membership_id) AS rang
          FROM manque WHERE NOT isempty(p)),
seul AS (
    SELECT n.succ, n.unit_id, n.niveau,
           unnest(datemultirange(n.p)
                  - coalesce((SELECT range_agg(q.p) FROM num q
                               WHERE q.succ = n.succ AND q.niveau = n.niveau AND q.rang < n.rang),
                             '{}'::datemultirange)) AS p
      FROM num n),
ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT succ, unit_id, niveau, lower(p), upper(p) FROM seul WHERE NOT isempty(p)
    RETURNING membership_id)
INSERT INTO p138_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p138_trace GROUP BY 1 ORDER BY 1;
\else
\echo ''
\echo '== À BLANC : rien n''est écrit. Pour poser : -1 -v appliquer=1'
\endif

\echo ''
\echo '-- témoin après : Moussy-Verneuil après 1960'
SELECT atom_id, niveau, unit_id, valid_from, valid_to FROM membership
 WHERE atom_id IN ('24286', '39485') AND valid_to > '1960-01-01' ORDER BY 1, 2, 4;
\endif

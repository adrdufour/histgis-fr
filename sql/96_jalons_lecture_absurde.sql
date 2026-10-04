-- ============================================================================
-- histgis — 96_jalons_lecture_absurde.sql : la géométrie juge les jalons
--                                           de 1954 et de 1968
--
--   psql -d histgis -f sql/96_jalons_lecture_absurde.sql                 (à blanc)
--   psql -d histgis -1 -v appliquer=1 -f sql/96_jalons_lecture_absurde.sql
--
-- Puis, parce qu'ils lisent les jalons dans `membership` :
--   psql -d histgis -1 -f sql/81_report_1968_avant.sql
--   psql -d histgis -1 -f sql/93_report_1940_1954.sql
--   psql -d histgis -1 -f sql/95_report_deux_bouts_1969_1999.sql
--
-- ÉCRIT DANS `membership`, et SEULEMENT sur les lignes de `59` et de `68`
-- (celles de `c68_trace` et de `c54_trace`). Tout est tracé dans `p96_trace` ;
-- le passage précédent est défait avant d'écrire, et le JUGEMENT est rendu
-- sur les lectures brutes, reconstituées depuis la trace : le fichier donne
-- donc le même verdict à blanc, après un premier passage ou sur une base neuve.
--
-- CE QUI L'A FAIT ÉCRIRE — 23 septembre 2026
-- ==========================================
-- Mesuré sur l'export de la carte (`sorties/diag_comblements_2026-09-23/`) :
-- les communes à plus de 15 km de tout autre membre de leur canton sont
--
--     1940 : 9      1950 (`93`) : 9      1954 : 158
--     1968-1972 : 446                     1999 : 3
--
-- Les comblements (`93`, `95`) sont propres ; les deux JALONS ne le sont pas,
-- et `81` prolonge celui de 1968 jusqu'au premier acte sans jamais le
-- confronter à l'autre bout. 804 communes ont en 1968 un canton qui contredit
-- 1954 (ou 1940) ET 1999 alors que ceux-ci s'accordent ; 84 % ne diffèrent
-- que d'UN chiffre, et les couples sont ceux de l'OCR : 3/5, 3/8, 6/8, 0/9.
-- Laon « dans » Sains-Richaumont, Montluçon « dans » Ébreuil, La Salle-les-
-- Alpes « dans » Orpierre à 95 km. Et Lamastre, chef-lieu de SON canton, lue
-- « 3 19 » au lieu de « 3 10 » dans le fascicule de 1954 (p. 132) : placée à
-- Saint-Péray en 1954, donc en désaccord avec 1940, donc laissée vide par `93`
-- de 1941 à 1953 — la commune disparaît de la carte pendant treize ans.
--
-- `71` avait mesuré ces lectures pour 1954 (227 « transferts » SÉPARÉS sur
-- 311) ; il ne corrigeait rien, et le jalon les a gardées. *Un diagnostic qui
-- n'entre pas dans la chaîne ne protège que celui qui le relit.*
--
-- LA RÈGLE — trois arbitres indépendants, comme le séparateur de 1954
-- ====================================================================
-- Une ligne de jalon est ABSURDE quand :
--   * la commune ne TOUCHE pas son canton lu (aucun membre à moins de
--     :seuil_contigu m, distance entre polygones, `atom_geom`, Lambert 93) —
--     le canton étant pris dans son EMPRISE : l'union de ses membres aux
--     quatre dates (1940, 1954, 1968, 1999). Un jalon ne lit que 79 % des
--     communes en 1954 : le voisin qui ferait la jonction manque souvent à la
--     date même, pas dans l'emprise ;
--   * ET son canton n'est confirmé par AUCUN bout attesté — 1940 (TRF-GIS),
--     l'autre jalon, 1999 (COG) ; faute de tout bout, il faut :seuil_sans_bout m.
-- Une île loin de son chef-lieu mais confirmée par 1940 n'est donc pas
-- absurde : c'est `loin_confirme`, compté et laissé.
--
-- PREMIER PASSAGE À BLANC, 23 septembre 2026 : le seuil était de 5 km, celui
-- que `71` appelait « éloigné ». Lamastre n'est pas sortie : Saint-Péray est à
-- moins de 5 km de son bord. **Un vrai transfert se fait vers un canton
-- CONTIGU** — c'est l'argument même de `71` —, et l'exiger ne coûte rien à la
-- prudence tant que le bout attesté protège les lectures confirmées.
--
-- Une ligne absurde est CORRIGÉE si un canton EXISTANT À LA DATE du jalon,
-- et un seul, satisfait à la fois :
--   A1 la GÉOMÉTRIE — son emprise touche la commune (≤ :seuil_contigu m) ;
--   A2 la LECTURE   — son numéro ne diffère du numéro lu que d'un chiffre,
--                     ou il porte le nom de la commune (chef-lieu) ;
--   A3 un BOUT      — 1940, l'autre jalon ou 1999 le donne.
-- Sinon elle est RETIRÉE : un trou déclaré plutôt qu'un canton faux. C'est la
-- préférence du dépôt, et un retrait ne coûte que l'année du jalon et le
-- report de `81`, qu'un canton faux coûtait tout autant.
--
-- Aucun arbitre ne suffit seul. La géométrie seule prendrait n'importe quel
-- voisin ; la lecture seule, n'importe quel numéro voisin ; un bout seul
-- reviendrait à reporter. C'est leur CONJONCTION qui fait une correction,
-- exactement comme la nomenclature et le dictionnaire de noms arbitrent
-- ensemble le séparateur relâché de 1954.
--
-- CE QUE LE FICHIER NE TOUCHE PAS
-- ===============================
--   * les FRACTIONS (`atome#canton`) : leur identifiant porte le canton lu ;
--     le corriger serait renommer un atome. Comptées au § 4.
--   * les lignes des autres fichiers au même instant (`60` Forbach-II, `87`
--     Seine…) : elles servent de voisins, jamais de cibles.
--   * les échanges croisés entre deux cantons CONTIGUS (Falaise-Nord/Sud,
--     Issoudun) : chaque ligne est géographiquement plausible, la distance ne
--     les voit pas. Ils restent au § 5 de `71`.
--
-- Prérequis : `05` (atom_geom), `24` (couche 1999), `59` et `68` (les jalons).
-- Place dans la chaîne : après `87`/`88`, avant `72` — donc avant `79`, `81`,
-- `93` et `95`, qui lisent les jalons.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set seuil_sans_bout 15000
\set seuil_contigu   1000

\echo ''
\echo '============================================================'
\echo ' 96 — les jalons de 1954 et 1968 jugés par la géométrie'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.c68_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/59_cog1968_membership.sql.';
    END IF;
    IF to_regclass('histgis.c54_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/68_cog1954_membership.sql.';
    END IF;
    IF to_regclass('histgis.atom_geom') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : atom_geom (sql/05_geom.sql).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> DATE '1999-06-01') THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1999 est vide (sql/24_canton_moderne.sql).';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS p96_trace (
    membership_id bigint   NOT NULL,
    jalon         smallint NOT NULL,    -- 1954 | 1968
    atom_id       text     NOT NULL,
    unit_lu       text     NOT NULL,    -- la lecture du fascicule
    unit_pose     text,                 -- le canton corrigé ; NULL si retiré
    valid_from    date     NOT NULL,
    valid_to      date     NOT NULL,
    action        text     NOT NULL CHECK (action IN ('corrige', 'retire')),
    pose          timestamptz NOT NULL DEFAULT now()
);

-- Normalisation des noms pour l'arbitre « chef-lieu ». Sans `unaccent`, pour
-- ne pas ajouter une dépendance d'extension à la chaîne.
CREATE OR REPLACE FUNCTION p96_norme(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT btrim(regexp_replace(
             translate(upper(coalesce(t, '')),
                       'ÀÂÄÁÃÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜŸ''’-',
                       'AAAAACEEEEIIIINOOOOOUUUUY   '),
             '\s+', ' ', 'g'))
$f$;

-- ---------------------------------------------------------------------------
-- 1. Les lectures BRUTES, reconstituées
--
-- Ce qui est en base peut déjà porter un passage de ce fichier. On rend donc
-- à chaque ligne corrigée son canton lu, et on réintègre les lignes retirées,
-- depuis `p96_trace`. Le jugement ne lit que cette table : il ne dépend pas
-- de l'état laissé par le passage précédent.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p96_ligne;
CREATE TABLE p96_ligne AS
WITH jalon AS (
    SELECT 1954::smallint AS jalon, DATE '1954-06-01' AS d, 'c54' AS src, cle
      FROM c54_trace WHERE quoi = 'membership'
    UNION ALL
    SELECT 1968::smallint, DATE '1968-06-01', 'c68', cle
      FROM c68_trace WHERE quoi = 'membership'
)
SELECT j.jalon, j.d, m.atom_id,
       coalesce(t.unit_lu, m.unit_id) AS unit_lu,
       m.valid_from, m.valid_to
FROM   jalon j
JOIN   membership m ON m.membership_id::text = j.cle AND m.niveau = 'canton'
LEFT   JOIN p96_trace t ON t.membership_id = m.membership_id
                       AND t.action = 'corrige'
UNION ALL
SELECT t.jalon, CASE t.jalon WHEN 1954 THEN DATE '1954-06-01'
                             ELSE DATE '1968-06-01' END,
       t.atom_id, t.unit_lu, t.valid_from, t.valid_to
FROM   p96_trace t
WHERE  t.action = 'retire';

CREATE INDEX p96_ligne_idx ON p96_ligne (jalon, atom_id);

\echo ''
\echo '-- 1. lectures brutes des deux jalons'
SELECT jalon, count(*) AS lignes,
       count(*) FILTER (WHERE atom_id LIKE '%#%') AS dont_fractions
FROM   p96_ligne GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 2. L'état cantonal aux quatre dates, et les membres géométrés
--
-- 1940 et 1999 : tel qu'en base (ni `79`, ni `81`, ni `93`, ni `95` n'y
-- touchent). 1954 et 1968 : les lectures brutes du § 1, plus les lignes des
-- AUTRES fichiers au même instant (Seine, Forbach-II…).
-- La base d'un atome-fraction est sa commune : une fraction de X dans le
-- canton C dit que X touche C.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p96_etat;
CREATE TABLE p96_etat AS
SELECT d, split_part(atom_id, '#', 1) AS base, atom_id, unit_id
FROM (
    SELECT DATE '1940-06-01' AS d, atom_id, unit_id FROM membership
     WHERE niveau = 'canton' AND periode @> DATE '1940-06-01'
    UNION ALL
    SELECT DATE '1999-06-01', atom_id, unit_id FROM membership
     WHERE niveau = 'canton' AND periode @> DATE '1999-06-01'
    UNION ALL
    SELECT d, atom_id, unit_lu FROM p96_ligne
    UNION ALL
    SELECT x.d, m.atom_id, m.unit_id
    FROM   (VALUES (DATE '1954-06-01'), (DATE '1968-06-01')) x(d)
    JOIN   membership m ON m.niveau = 'canton' AND m.periode @> x.d
    WHERE  NOT EXISTS (SELECT 1 FROM c54_trace t
                        WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text)
      AND  NOT EXISTS (SELECT 1 FROM c68_trace t
                        WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text)
) s;

CREATE INDEX p96_etat_idx ON p96_etat (base, d);

DROP TABLE IF EXISTS p96_membre;
CREATE TABLE p96_membre AS
SELECT e.d, e.unit_id, e.base, g.geom
FROM   p96_etat e JOIN atom_geom g ON g.atom_id = e.base;

CREATE INDEX p96_membre_u_idx ON p96_membre (d, unit_id);
CREATE INDEX p96_membre_g_idx ON p96_membre USING gist (geom);
-- L'emprise : le canton à toutes les dates, sans la date.
DROP TABLE IF EXISTS p96_emprise;
CREATE TABLE p96_emprise AS
SELECT DISTINCT unit_id, base FROM p96_etat;
ALTER TABLE p96_emprise ADD COLUMN geom geometry;
UPDATE p96_emprise e SET geom = g.geom FROM atom_geom g WHERE g.atom_id = e.base;
DELETE FROM p96_emprise WHERE geom IS NULL;
CREATE INDEX p96_emprise_u_idx ON p96_emprise (unit_id);
CREATE INDEX p96_emprise_g_idx ON p96_emprise USING gist (geom);
ANALYZE p96_etat; ANALYZE p96_membre; ANALYZE p96_emprise;

\echo ''
\echo '-- 2. membres géométrés, par date'
SELECT d, count(*) AS lignes, count(DISTINCT unit_id) AS cantons
FROM   p96_membre GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 3. LE TÉMOIN — la même mesure sur les deux couches de référence
--
-- Combien de lignes de 1940 et de 1999 ne touchent pas l'emprise de leur
-- canton (:seuil_contigu m) ? C'est le bruit de fond — îles, enclaves, polygones
-- GEOFLA partagés — auquel les jalons doivent être ramenés.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. témoin : lignes sans voisin de leur canton, 1940 et 1999'
SELECT a.d,
       count(*)                                          AS lignes,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM p96_emprise b
            WHERE b.unit_id = a.unit_id AND b.base <> a.base
              AND ST_DWithin(a.geom, b.geom, :seuil_contigu)))
                                                         AS sans_voisin
FROM   p96_membre a
WHERE  a.d IN (DATE '1940-06-01', DATE '1999-06-01')
  AND  EXISTS (SELECT 1 FROM p96_emprise b
                WHERE b.unit_id = a.unit_id AND b.base <> a.base)
GROUP  BY a.d ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. La mesure, ligne à ligne
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p96_mesure;
CREATE TABLE p96_mesure AS
WITH l AS (
    SELECT l.*, g.geom,
           (SELECT count(*) FROM p96_emprise b
             WHERE b.unit_id = l.unit_lu
               AND b.base <> l.atom_id)                       AS n_autres,
           EXISTS (SELECT 1 FROM p96_emprise b
                    WHERE b.unit_id = l.unit_lu
                      AND b.base <> l.atom_id
                      AND ST_DWithin(g.geom, b.geom, :seuil_contigu)) AS proche,
           ARRAY(SELECT DISTINCT e.unit_id FROM p96_etat e
                  WHERE e.base = l.atom_id AND e.d <> l.d
                    AND e.d IN (DATE '1940-06-01', DATE '1954-06-01',
                                DATE '1968-06-01', DATE '1999-06-01')
                  ORDER BY 1)                                 AS bouts
    FROM   p96_ligne l
    LEFT   JOIN atom_geom g ON g.atom_id = l.atom_id
    WHERE  l.atom_id NOT LIKE '%#%'
)
SELECT l.jalon, l.d, l.atom_id, l.unit_lu, l.valid_from, l.valid_to,
       l.n_autres, l.proche, l.bouts,
       l.unit_lu = ANY (l.bouts)                               AS lu_confirme,
       CASE WHEN l.geom IS NULL OR l.proche OR l.n_autres = 0 THEN NULL
            ELSE (SELECT round(min(ST_Distance(l.geom, b.geom))::numeric)
                    FROM p96_emprise b
                   WHERE b.unit_id = l.unit_lu
                     AND b.base <> l.atom_id)
       END                                                     AS d_lu_m,
       l.geom
FROM   l;

ALTER TABLE p96_mesure ADD COLUMN classe text;
UPDATE p96_mesure SET classe = CASE
    WHEN geom IS NULL                               THEN 'sans_geometrie'
    WHEN n_autres = 0                               THEN 'seul_dans_son_canton'
    WHEN proche                                     THEN 'contigu'
    WHEN lu_confirme                                THEN 'loin_confirme'
    WHEN cardinality(bouts) > 0                     THEN 'absurde'
    WHEN d_lu_m > :seuil_sans_bout                  THEN 'absurde'
    ELSE                                                 'douteux_sans_bout'
END;

\echo ''
\echo '-- 4. les lignes des jalons, par classe (fractions exclues)'
SELECT jalon, classe, count(*) AS lignes
FROM   p96_mesure GROUP BY 1, 2 ORDER BY 1, 3 DESC;

-- ---------------------------------------------------------------------------
-- 5. Les candidats d'une ligne absurde, et leurs trois arbitres
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p96_candidat;
CREATE TABLE p96_candidat AS
WITH abs AS (SELECT * FROM p96_mesure WHERE classe = 'absurde'),
cand AS (
    SELECT a.jalon, a.atom_id, unnest(a.bouts) AS unit_id FROM abs a
    UNION
    SELECT a.jalon, a.atom_id, b.unit_id
    FROM   abs a JOIN p96_emprise b
      ON   b.base <> a.atom_id
     AND   ST_DWithin(a.geom, b.geom, :seuil_contigu)
)
SELECT c.jalon, c.atom_id, a.unit_lu, c.unit_id,
       -- A1 la géométrie
       -- A0 le canton existe à la date du jalon (un canton de 1999 créé en
       --    1973 ne corrige pas une lecture de 1954)
       EXISTS (SELECT 1 FROM p96_etat e
                WHERE e.d = a.d AND e.unit_id = c.unit_id)              AS a0_existe,
       EXISTS (SELECT 1 FROM p96_emprise b
                WHERE b.unit_id = c.unit_id AND b.base <> a.atom_id
                  AND ST_DWithin(a.geom, b.geom, :seuil_contigu))      AS a1_contigu,
       -- A2 la lecture : un seul chiffre du numéro, ou le nom du chef-lieu
       (length(c.unit_id) = length(a.unit_lu)
        AND left(c.unit_id, 2) = left(a.unit_lu, 2)
        AND (substr(c.unit_id, 3, 1) = substr(a.unit_lu, 3, 1))::int
          + (substr(c.unit_id, 4, 1) = substr(a.unit_lu, 4, 1))::int = 1) AS a2_un_chiffre,
       (p96_norme(coalesce(
            (SELECT v.nom FROM unit_version v
              WHERE v.unit_id = c.unit_id AND v.periode @> a.d LIMIT 1),
            (SELECT u.nom FROM unit u WHERE u.unit_id = c.unit_id)))
          || ' ') LIKE p96_norme(n.nom) || ' %'                       AS a2_chef_lieu,
       -- A3 un bout attesté
       c.unit_id = ANY (a.bouts)                                        AS a3_bout
FROM   cand c
JOIN   abs a ON a.jalon = c.jalon AND a.atom_id = c.atom_id
LEFT   JOIN atom t ON t.atom_id = a.atom_id
LEFT   JOIN noms_geofla n ON n.insee = t.insee_geofla
WHERE  c.unit_id <> a.unit_lu;

DROP TABLE IF EXISTS p96_decision;
CREATE TABLE p96_decision AS
WITH ok AS (
    SELECT jalon, atom_id,
           count(*) FILTER (WHERE a0_existe AND a1_contigu AND a3_bout
                              AND (a2_un_chiffre OR coalesce(a2_chef_lieu, false))) AS n_ok,
           min(unit_id) FILTER (WHERE a0_existe AND a1_contigu AND a3_bout
                              AND (a2_un_chiffre OR coalesce(a2_chef_lieu, false))) AS unit_ok,
           bool_or(a0_existe AND a1_contigu AND a3_bout)                                         AS voisin_confirme
    FROM   p96_candidat GROUP BY 1, 2
)
SELECT m.jalon, m.atom_id, m.unit_lu, m.valid_from, m.valid_to, m.d_lu_m, m.bouts,
       CASE WHEN o.n_ok = 1 THEN 'corrige' ELSE 'retire' END   AS action,
       CASE WHEN o.n_ok = 1 THEN o.unit_ok END                 AS unit_pose,
       CASE WHEN o.n_ok = 1        THEN 'trois arbitres, un seul canton'
            WHEN o.n_ok > 1        THEN 'plusieurs cantons satisfont les trois arbitres'
            WHEN o.voisin_confirme THEN 'voisin confirmé par un bout, numéro trop éloigné'
            WHEN cardinality(m.bouts) = 0 THEN 'aucun bout attesté'
            ELSE 'aucun canton contigu confirmé par un bout'
       END                                                     AS motif
FROM   p96_mesure m
LEFT   JOIN ok o ON o.jalon = m.jalon AND o.atom_id = m.atom_id
WHERE  m.classe = 'absurde';

\echo ''
\echo '-- 5. décision, par jalon'
SELECT jalon, action, motif, count(*) AS lignes
FROM   p96_decision GROUP BY 1, 2, 3 ORDER BY 1, 2, 4 DESC;

\echo ''
\echo '-- 5 bis. les corrections : couples lu → posé les plus fréquents'
SELECT jalon, right(unit_lu, 2) AS lu, right(unit_pose, 2) AS pose, count(*) AS n
FROM   p96_decision WHERE action = 'corrige'
GROUP  BY 1, 2, 3 ORDER BY n DESC LIMIT 15;

\echo ''
\echo '-- 5 ter. contrôles nommés (Lamastre 07129, Laon 02408, Holnon 02382,'
\echo '         Montluçon 03185, La Salle-les-Alpes 05161)'
SELECT d.jalon, t.insee_geofla AS insee, n.nom, d.unit_lu, d.action, d.unit_pose,
       d.d_lu_m, d.motif
FROM   p96_decision d
JOIN   atom t ON t.atom_id = d.atom_id
LEFT   JOIN noms_geofla n ON n.insee = t.insee_geofla
WHERE  t.insee_geofla IN ('07129', '02408', '02382', '03185', '05161')
ORDER  BY 2, 1;
-- Attendu : Lamastre 1954 corrigée 0719 → 0710 ; Holnon 1968 corrigée
-- 0235 → 0233 ; La Salle-les-Alpes 1968 corrigée 0515 → 0513.

\echo ''
\echo '-- 5 quater. les 20 retraits les plus lointains'
SELECT d.jalon, t.insee_geofla AS insee, n.nom, d.unit_lu,
       round(d.d_lu_m / 1000.0, 1) AS km, d.bouts, d.motif
FROM   p96_decision d
JOIN   atom t ON t.atom_id = d.atom_id
LEFT   JOIN noms_geofla n ON n.insee = t.insee_geofla
WHERE  d.action = 'retire'
ORDER  BY d.d_lu_m DESC NULLS LAST LIMIT 20;

-- ---------------------------------------------------------------------------
-- 6. L'ÉCRITURE — sous -v appliquer=1 seulement
-- ---------------------------------------------------------------------------
\if :{?appliquer}

-- 6 a. Défaire le passage précédent.
--
-- Une correction se défait en place. Un retrait se défait en reposant la
-- ligne — si la place est libre : `59` ou `68` rejoués depuis l'ont peut-être
-- déjà reposée — et en rendant son nouvel identifiant à la trace et à la
-- qualité du fichier d'origine, sans quoi le prochain rejeu de `59`/`68` ne
-- la retrouverait pas.
UPDATE membership m
   SET unit_id = t.unit_lu
  FROM p96_trace t
 WHERE t.action = 'corrige'
   AND m.membership_id = t.membership_id
   AND m.unit_id = t.unit_pose;

DO $$
DECLARE r record; nouveau bigint;
BEGIN
    FOR r IN SELECT * FROM p96_trace WHERE action = 'retire' LOOP
        IF NOT EXISTS (SELECT 1 FROM membership m
                        WHERE m.atom_id = r.atom_id AND m.niveau = 'canton'
                          AND m.periode && daterange(r.valid_from, r.valid_to, '[)')) THEN
            INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
            VALUES (r.atom_id, r.unit_lu, 'canton', r.valid_from, r.valid_to)
            RETURNING membership_id INTO nouveau;
            IF r.jalon = 1954 THEN
                UPDATE c54_trace SET cle = nouveau::text
                 WHERE quoi = 'membership' AND cle = r.membership_id::text;
                UPDATE c54_qualite SET membership_id = nouveau
                 WHERE membership_id = r.membership_id;
            ELSE
                UPDATE c68_trace SET cle = nouveau::text
                 WHERE quoi = 'membership' AND cle = r.membership_id::text;
                UPDATE c68_qualite SET membership_id = nouveau
                 WHERE membership_id = r.membership_id;
            END IF;
        END IF;
    END LOOP;
END $$;

TRUNCATE p96_trace;

-- 6 b. Garde-fou : chaque décision retrouve sa ligne, une et une seule.
DROP TABLE IF EXISTS p96_cible;
CREATE TABLE p96_cible AS
SELECT d.*, m.membership_id
FROM   p96_decision d
JOIN   membership m ON m.atom_id = d.atom_id AND m.niveau = 'canton'
                   AND m.valid_from = d.valid_from AND m.valid_to = d.valid_to
                   AND m.unit_id = d.unit_lu
WHERE  EXISTS (SELECT 1 FROM c54_trace t WHERE d.jalon = 1954
                  AND t.quoi = 'membership' AND t.cle = m.membership_id::text)
   OR  EXISTS (SELECT 1 FROM c68_trace t WHERE d.jalon = 1968
                  AND t.quoi = 'membership' AND t.cle = m.membership_id::text);

DO $$
DECLARE n_dec bigint; n_cib bigint; n_dbl bigint;
BEGIN
    SELECT count(*) INTO n_dec FROM p96_decision;
    SELECT count(*), count(*) - count(DISTINCT (jalon, atom_id))
      INTO n_cib, n_dbl FROM p96_cible;
    IF n_cib <> n_dec OR n_dbl > 0 THEN
        RAISE EXCEPTION 'GARDE-FOU : % décisions, % lignes retrouvées (% en double). '
            'La base ne porte pas les lectures que le § 1 a reconstituées.',
            n_dec, n_cib, n_dbl;
    END IF;
    -- l'alarme sur l'effectif, celle de `42` : ce fichier corrige des
    -- lectures, il ne refait pas un jalon
    IF n_dec > 3000 THEN
        RAISE EXCEPTION 'GARDE-FOU : % lignes jugées absurdes — plus de 3 000, '
            'c''est la règle qui est fausse, pas les jalons.', n_dec;
    END IF;
END $$;

-- 6 c. Écrire, et tracer.
WITH maj AS (
    UPDATE membership m
       SET unit_id = c.unit_pose
      FROM p96_cible c
     WHERE c.action = 'corrige' AND m.membership_id = c.membership_id
    RETURNING m.membership_id
)
INSERT INTO p96_trace (membership_id, jalon, atom_id, unit_lu, unit_pose,
                       valid_from, valid_to, action)
SELECT c.membership_id, c.jalon, c.atom_id, c.unit_lu, c.unit_pose,
       c.valid_from, c.valid_to, 'corrige'
FROM   p96_cible c JOIN maj USING (membership_id);

WITH sup AS (
    DELETE FROM membership m
     USING p96_cible c
     WHERE c.action = 'retire' AND m.membership_id = c.membership_id
    RETURNING m.membership_id
)
INSERT INTO p96_trace (membership_id, jalon, atom_id, unit_lu, unit_pose,
                       valid_from, valid_to, action)
SELECT c.membership_id, c.jalon, c.atom_id, c.unit_lu, NULL,
       c.valid_from, c.valid_to, 'retire'
FROM   p96_cible c JOIN sup USING (membership_id);

ANALYZE membership;

\echo ''
\echo '-- 6. écrit'
SELECT jalon, action, count(*) FROM p96_trace GROUP BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 7. RECETTES
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 7 a. une ligne corrigée qui ne touche pas son nouveau canton (doit valoir 0)'
SELECT count(*) FROM p96_trace t
JOIN   atom_geom g ON g.atom_id = t.atom_id
WHERE  t.action = 'corrige'
  AND  NOT EXISTS (
         SELECT 1 FROM p96_emprise b
          WHERE b.unit_id = t.unit_pose AND b.base <> t.atom_id
            AND ST_DWithin(g.geom, b.geom, :seuil_contigu));

\echo ''
\echo '-- 7 b. 1940 et 1999 intacts (écarts à 0)'
SELECT (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1940-06-01')
     - (SELECT count(*) FROM p96_etat WHERE d = DATE '1940-06-01') AS ecart_1940,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1999-06-01')
     - (SELECT count(*) FROM p96_etat WHERE d = DATE '1999-06-01') AS ecart_1999;

\echo ''
\echo '-- 7 c. les jalons : effectif avant, retraits, effectif après (écart à 0)'
SELECT e.d,
       count(*)                                                     AS avant,
       (SELECT count(*) FROM p96_trace t WHERE t.action = 'retire'
          AND t.jalon = extract(year FROM e.d))                     AS retraits,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'canton'
          AND m.periode @> e.d)                                     AS apres,
       count(*)
     - (SELECT count(*) FROM p96_trace t WHERE t.action = 'retire'
          AND t.jalon = extract(year FROM e.d))
     - (SELECT count(*) FROM membership m WHERE m.niveau = 'canton'
          AND m.periode @> e.d)                                     AS ecart
FROM   p96_etat e
WHERE  e.d IN (DATE '1954-06-01', DATE '1968-06-01')
GROUP  BY e.d ORDER BY 1;

\echo ''
\echo '   Suite obligée : rejouer 81, 93 puis 95, qui lisent les jalons.'
\echo '   Revenir aux jalons bruts : rejouer 59 et 68, puis TRUNCATE p96_trace.'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -1 -v appliquer=1 ==='
\endif

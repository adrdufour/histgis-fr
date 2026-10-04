-- ============================================================================
-- histgis — diag_yonne_1815.sql : la carte communale de 1815 est-elle celle
--                                 de 1870, dans l'Yonne ?
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/diag_yonne_1815.sql
--   psql -d histgis -v dep=88 -f sql/diag_yonne_1815.sql      -- un autre
--   psql -d histgis -v an=1820 -f sql/diag_yonne_1815.sql     -- une autre année
--
-- LECTURE SEULE. Tables temporaires uniquement : rien n'est écrit en base.
--
-- LA QUESTION
-- ===========
-- `64` a refusé, le 22 août, de poser les rattachements de 1815 sur les atomes
-- de 1870 : les communes avaient bougé, et l'on n'avait aucune source pour le
-- dire. Depuis, `82` a chargé ANR de 1790 à 2020. La source existe ; il reste à
-- mesurer ce qu'elle dit pour l'Yonne.
--
-- LE PRINCIPE
-- ===========
-- Gaudillère garantit qu'aucun CANTON de l'Yonne n'a bougé de 1815 à 1870. Le
-- territoire d'un canton en 1870 (union des polygones ANR de ses atomes) est
-- donc aussi son territoire de 1815. Chaque polygone communal ANR de 1815 est
-- posé sur ces 37 cantons, et l'on mesure la part de sa surface qui tombe
-- dans chacun :
--   * entièrement dans un canton  -> le rattachement de 1815 se LIT, il ne se
--                                    devine pas ;
--   * à cheval sur deux cantons   -> une commune a changé de canton, ou ANR et
--                                    la trame de 1870 divergent : à regarder.
-- Les deux trames sortent de la même source, d'où une part de 100 % exacte pour
-- toute commune inchangée.
--
-- AUCUN SEUIL NE DÉCIDE. Le seuil de 99 % ne sert qu'aux décomptes du § 4 ;
-- la liste du § 5 montre la part réelle de tout ce qui est sous 99,9 %.
--
-- CE QU'IL NE VOIT PAS
-- ====================
-- * les échanges de territoire entre communes d'un MÊME canton n'ont pas
--   d'effet sur la composition cantonale ; ils sont comptés (`retouchée`) mais
--   ne sont pas un problème ;
-- * un atome-fraction n'a pas de polygone ANR (`82`) : sa commune-mère sortira
--   « à cheval », et c'est juste ;
-- * les communes en repli sur `atom_geom` (pas de polygone ANR à 1870) rendent
--   l'empreinte du canton moins sûre : elles sont comptées au § 1.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?dep}
\else
    \set dep '89'
\endif
\if :{?an}
\else
    \set an 1815
\endif
\set d70 '1870-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche anr_commune (voir l''en-tête de sql/82_anr_geom.sql).';
    END IF;
    IF to_regclass('histgis.atom_geom_anr') IS NULL
       OR to_regclass('histgis.anr_variante') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql avant celui-ci.';
    END IF;
    IF to_regclass('histgis.c15_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/64_composition_1815_stage.sql avant celui-ci.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' Département' :dep ' — la carte communale de' :an 'contre celle de 1870'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- § 0. Les atomes du département à 1870, et l'empreinte de ses cantons
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE y_atome70 AS
SELECT m.atom_id, a.cassini, a.fraction, m.unit_id, u.nom AS canton,
       ga.geom AS geom_anr, ag.geom AS geom_repli
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
JOIN   atom a ON a.atom_id = m.atom_id
LEFT   JOIN atom_geom_anr ga ON ga.atom_id = m.atom_id
                            AND ga.periode @> :'d70'::date
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'d70'::date
  AND  u.dep = :'dep';

CREATE TEMP TABLE y_canton70 AS
SELECT unit_id, canton,
       count(*)                                         AS n_atomes,
       count(*) FILTER (WHERE geom_anr IS NOT NULL)     AS n_anr,
       count(*) FILTER (WHERE geom_anr IS NULL
                          AND geom_repli IS NOT NULL)   AS n_repli,
       count(*) FILTER (WHERE fraction)                 AS n_fractions,
       ST_Multi(ST_MakeValid(ST_UnaryUnion(ST_Collect(
           coalesce(geom_anr, geom_repli)))))           AS geom
FROM   y_atome70
GROUP  BY unit_id, canton;
CREATE INDEX ON y_canton70 USING gist (geom);

CREATE TEMP TABLE y_emprise AS
SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM y_canton70;

\echo ''
\echo '-- 1. le département à 1870'
SELECT count(DISTINCT unit_id)  AS cantons,
       sum(n_atomes)            AS atomes,
       sum(n_anr)               AS avec_polygone_anr,
       sum(n_repli)             AS en_repli_atom_geom,
       sum(n_fractions)         AS fractions,
       round((ST_Area((SELECT geom FROM y_emprise)) / 1e6)::numeric, 1) AS km2
FROM   y_canton70;

\echo ''
\echo '-- 1 bis. les cantons de 1870 et ceux de c15_composition concordent-ils ?'
\echo '         (aucune ligne = mêmes noms des deux côtés)'
SELECT 'en base à 1870, absent de c15' AS cote, k.canton
FROM   y_canton70 k
WHERE  NOT EXISTS (SELECT 1 FROM c15_composition c
                    WHERE c.dep = :'dep' AND c.canton = k.canton)
UNION ALL
SELECT DISTINCT 'dans c15, absent à 1870', c.canton
FROM   c15_composition c
WHERE  c.dep = :'dep'
  AND  NOT EXISTS (SELECT 1 FROM y_canton70 k WHERE k.canton = c.canton);

-- ---------------------------------------------------------------------------
-- § 2. Les polygones ANR du département, de l'année demandée à 1870
--
--      Mêmes règles que `82` : fenêtre [StartDt, EndDt) non vide (R1),
--      variantes écartées exclues (R3), doublons exacts retirés (R2).
--      Sont retenus les polygones dont un point intérieur tombe dans
--      l'empreinte de 1870, ou dont l'id_com est celui d'un atome du
--      département — une commune passée d'un département à l'autre sortira
--      ainsi au § 5, hors emprise, au lieu de disparaître.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE y_anr AS
WITH brut AS (
    SELECT an.id_com::text                              AS id_com,
           an.namecom                                   AS nom,
           an.poly_id,
           (nullif(an.startdt::text, ''))::numeric::int AS an_debut,
           (nullif(an.enddt::text,   ''))::numeric::int AS an_fin,
           coalesce(an.pseudo_t::boolean, false)        AS pseudo_t,
           an.geom
    FROM   anr_commune an
    WHERE  an.geom IS NOT NULL
      AND  an.geom && (SELECT ST_Envelope(geom) FROM y_emprise)
), fenetre AS (
    SELECT b.*
    FROM   brut b
    LEFT   JOIN anr_variante v ON v.poly_id = b.poly_id
    WHERE  b.an_debut IS NOT NULL AND b.an_fin > b.an_debut
      AND  b.an_debut <= 1870 AND b.an_fin > :an          -- touche [an, 1870]
      AND  (v.poly_id IS NULL OR v.verdict = 'retenu')
), unique_poly AS (
    SELECT DISTINCT ON (poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin) *
    FROM   fenetre
    ORDER  BY poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin
)
SELECT u.id_com, u.nom, u.poly_id, u.an_debut, u.an_fin, u.pseudo_t,
       ST_Multi(ST_MakeValid(u.geom)) AS geom
FROM   unique_poly u
WHERE  ST_Within(ST_PointOnSurface(u.geom), (SELECT geom FROM y_emprise))
   OR  u.id_com IN (SELECT cassini FROM y_atome70);
CREATE INDEX ON y_anr USING gist (geom);
CREATE INDEX ON y_anr (id_com);

-- L'état à l'année demandée, et le devenir de chaque commune à 1870.
CREATE TEMP TABLE y_commune AS
SELECT p.id_com, p.nom, p.poly_id, p.pseudo_t, p.geom,
       ST_Area(p.geom) / 1e6                                  AS km2,
       q.poly_id                                              AS poly_id_1870,
       CASE WHEN q.poly_id IS NULL                       THEN 'disparue avant 1870'
            WHEN q.poly_id = p.poly_id
              OR md5(ST_AsBinary(q.geom)) = md5(ST_AsBinary(p.geom))
                                                         THEN 'inchangée'
            ELSE 'retouchée' END                              AS statut,
       CASE WHEN q.poly_id IS NOT NULL
            THEN ST_Area(ST_SymDifference(p.geom, q.geom)) / 1e6 END AS km2_ecart,
       (SELECT count(DISTINCT e.poly_id) FROM y_anr e
         WHERE e.id_com = p.id_com
           AND e.an_debut > :an AND e.an_debut <= 1870)        AS editions,
       (SELECT string_agg(DISTINCT x.canton, ' / ' ORDER BY x.canton)
          FROM y_atome70 x WHERE x.cassini = p.id_com)        AS canton_atome_1870
FROM   y_anr p
LEFT   JOIN LATERAL (
         SELECT q.poly_id, q.geom FROM y_anr q
         WHERE  q.id_com = p.id_com
           AND  q.an_debut <= 1870 AND q.an_fin > 1870
         LIMIT  1) q ON true
WHERE  p.an_debut <= :an AND p.an_fin > :an;

\echo ''
\echo '-- 2. ce que sont devenues, en 1870, les communes de l''année demandée'
SELECT statut,
       count(*)                                  AS communes,
       round(sum(km2)::numeric, 1)               AS km2,
       round(sum(km2_ecart)::numeric, 2)         AS km2_ecart_cumule,
       count(*) FILTER (WHERE editions > 0)      AS editees_entre_temps,
       count(*) FILTER (WHERE pseudo_t)          AS pseudo_territoires
FROM   y_commune
GROUP  BY statut ORDER BY statut;

\echo ''
\echo '-- 3. couverture : la trame de l''année demandée recouvre-t-elle l''empreinte de 1870 ?'
SELECT round((ST_Area(e.geom) / 1e6)::numeric, 1)                          AS km2_emprise_1870,
       round((ST_Area(c.geom) / 1e6)::numeric, 1)                          AS km2_trame_ancienne,
       round((ST_Area(ST_Difference(e.geom, c.geom)) / 1e6)::numeric, 2)   AS km2_sans_commune_ancienne,
       round((ST_Area(ST_Difference(c.geom, e.geom)) / 1e6)::numeric, 2)   AS km2_hors_emprise
FROM   y_emprise e,
       (SELECT ST_UnaryUnion(ST_Collect(geom)) AS geom FROM y_commune) c;

-- ---------------------------------------------------------------------------
-- § 4. L'attribution : chaque commune ancienne posée sur les cantons de 1870
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE y_part AS
SELECT c.id_com, k.canton,
       ST_Area(ST_Intersection(c.geom, k.geom)) / nullif(ST_Area(c.geom), 0) AS part
FROM   y_commune c
JOIN   y_canton70 k ON c.geom && k.geom AND ST_Intersects(c.geom, k.geom);

CREATE TEMP TABLE y_attrib AS
SELECT c.id_com, c.nom, c.statut, c.km2, c.km2_ecart, c.editions,
       c.canton_atome_1870,
       m.canton                                         AS canton_lu,
       coalesce(m.part, 0)                              AS part_max,
       coalesce(t.part_totale, 0)                       AS part_dans_dep,
       t.detail
FROM   y_commune c
LEFT   JOIN LATERAL (
         SELECT p.canton, p.part FROM y_part p
         WHERE  p.id_com = c.id_com ORDER BY p.part DESC LIMIT 1) m ON true
LEFT   JOIN LATERAL (
         SELECT sum(p.part) AS part_totale,
                string_agg(p.canton || ' ' || round(100 * p.part::numeric, 2) || ' %',
                           ', ' ORDER BY p.part DESC)
                    FILTER (WHERE p.part >= 0.0001)     AS detail
         FROM   y_part p WHERE p.id_com = c.id_com) t ON true;

\echo ''
\echo '-- 4. bilan de l''attribution (le seuil de 99 % ne sert qu''à ce décompte)'
SELECT CASE WHEN part_dans_dep < 0.99 THEN 'hors emprise de 1870'
            WHEN part_max     >= 0.99 THEN 'un seul canton'
            ELSE                           'à cheval' END              AS verdict,
       CASE WHEN canton_atome_1870 IS NULL      THEN 'sans atome en 1870'
            WHEN canton_atome_1870 = canton_lu  THEN 'concorde avec 1870'
            ELSE                                     'DISCORDE avec 1870' END AS face_a_1870,
       count(*)                                                        AS communes
FROM   y_attrib
GROUP  BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- § 5. Ce qu'il faut regarder, nommé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. communes à regarder : part < 99,9 %, discorde, disparue ou retouchée'
SELECT id_com, nom, statut,
       round(km2::numeric, 2)          AS km2,
       round(km2_ecart::numeric, 3)    AS km2_ecart,
       editions,
       canton_lu,
       round(100 * part_max::numeric, 2) AS pct,
       canton_atome_1870,
       detail
FROM   y_attrib
WHERE  part_max < 0.999
   OR  part_dans_dep < 0.999
   OR  statut <> 'inchangée'
   OR  canton_atome_1870 IS DISTINCT FROM canton_lu
ORDER  BY (canton_atome_1870 IS DISTINCT FROM canton_lu) DESC,
          part_max, statut, nom;

\echo ''
\echo '-- 6. atomes de 1870 sans polygone à l''année demandée : nés entre-temps ?'
SELECT x.atom_id, x.cassini, x.canton, x.fraction,
       (SELECT min(e.an_debut) FROM y_anr e WHERE e.id_com = x.cassini) AS anr_nait_en
FROM   y_atome70 x
WHERE  NOT EXISTS (SELECT 1 FROM y_commune c WHERE c.id_com = x.cassini)
ORDER  BY x.canton, x.cassini;

\echo ''
\echo '============================================================'
\echo ' Lecture : si le § 4 ne montre que « un seul canton » et'
\echo ' « concorde » (plus des « sans atome » rangés sans ambiguïté),'
\echo ' les rattachements de 1815 se LISENT sur ANR et peuvent être'
\echo ' écrits. Toute ligne « à cheval » ou « DISCORDE » se règle à'
\echo ' la main, sur la planche, avant d''écrire quoi que ce soit.'
\echo '============================================================'

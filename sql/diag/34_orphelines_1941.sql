-- ============================================================================
-- histgis — 34_orphelines_1941.sql : les communes que la couche moderne
--                                    n'a pas reprises
--
--   psql -d histgis -v dep=02 -f 34_orphelines_1941.sql
--
-- Le signal
-- ---------
-- `33_diff_cantonal.sql` classe en « fusion » toute commune rattachée à un
-- canton en 1940 et à aucun en 1999. Dans l'Aisne, dix-huit communes tombent
-- dans ce cas — et **toutes finissent exactement le 1er janvier 1941**, date de
-- fin de la série TRF-GIS.
--
-- C'est le signal d'un défaut, pas d'une fusion. Une commune fusionnée en 1965
-- doit vivre de 1943 à 1965 dans la couche moderne, puis s'éteindre à sa vraie
-- date. Une commune dont le dernier rattachement coïncide avec la fin d'une
-- source n'a pas disparu : elle n'a pas été reprise.
--
-- La leçon de forme : une date qui vaut pour TOUTES les lignes n'est pas une
-- donnée, c'est une frontière de source. Il faut la lire comme telle.
--
-- Ce que le script sépare
-- -----------------------
--   fusion_documentee  — l'Insee porte un mouvement entre 1941 et 1999 :
--                        la commune a bien disparu, le classement de `33`
--                        tient, et sa date d'effet est connue
--   trou_1941_1942     — disparue dans l'intervalle non couvert, entre la fin
--                        de TRF-GIS et le premier mouvement Insee ; à déclarer
--   NON_REPRISE        — vivante après 1943 selon l'Insee, mais sans aucun
--                        rattachement cantonal moderne : DÉFAUT de la couche
--
-- Lecture seule.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set d40 '1940-06-01'
\set d99 '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' COMMUNES SANS RATTACHEMENT MODERNE'
\echo '============================================================'

DROP TABLE IF EXISTS orph;
CREATE TEMP TABLE orph AS
WITH c40 AS (
    SELECT DISTINCT a.insee_geofla AS insee
    FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
    WHERE  m.niveau = 'canton' AND m.periode @> :'d40'::date
      AND  left(a.insee_geofla, 2) = :'dep'
), c99 AS (
    SELECT DISTINCT a.insee_geofla AS insee
    FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
    WHERE  m.niveau = 'canton' AND m.periode @> :'d99'::date
      AND  left(a.insee_geofla, 2) = :'dep'
)
SELECT insee FROM c40 EXCEPT SELECT insee FROM c99;

-- ---------------------------------------------------------------------------
-- 1. Ce que l'Insee dit de chacune
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS orph_v;
CREATE TEMP TABLE orph_v AS
SELECT o.insee,
       coalesce(max(mv.libelle_av), max(mv2.libelle_ap), '(nom inconnu)') AS nom,
       min(mv.date_eff)   AS disparue_le,
       max(mv.mod)        AS modalite,
       max(mv.libelle_ap) AS absorbee_par,
       (SELECT max(valid_to) FROM membership m JOIN atom a
          ON a.atom_id = m.atom_id
        WHERE a.insee_geofla = o.insee AND m.niveau = 'canton') AS dernier_rat,
       -- Une absence isolée ne prouve rien ; deux absences concordantes, si.
       -- Pas de mouvement Insee ET pas de commune GEOFLA 2011 : la commune a
       -- disparu avant que le fichier de mouvements ne commence, donc dans le
       -- trou 1941-1942. C'est le cas de Lompnes (01220), fondue dans
       -- Hauteville-Lompnes avant 1943 — en 1964 la commune absorbante porte
       -- déjà son nom composé.
       -- Tester la seule nullité de `date_eff` classait ce cas en anomalie.
       CASE
         WHEN min(mv.date_eff) IS NOT NULL
              AND min(mv.date_eff) < '1943-01-01' THEN 'trou_1941_1942'
         WHEN min(mv.date_eff) IS NOT NULL        THEN 'fusion_documentee'
         WHEN max(g.insee_com) IS NULL            THEN 'trou_1941_1942'
         ELSE 'sans_trace_insee'
       END AS verdict
FROM   orph o
LEFT   JOIN insee_mvt mv  ON mv.com_av = o.insee
LEFT   JOIN insee_mvt mv2 ON mv2.com_ap = o.insee
LEFT   JOIN geofla_commune g ON g.insee_com = o.insee
GROUP  BY o.insee;

\echo ''
\echo '=== 1. Le verdict, commune par commune ==='
SELECT * FROM orph_v ORDER BY verdict, disparue_le, insee;

\echo ''
\echo '=== 2. Bilan ==='
SELECT verdict, count(*) AS communes FROM orph_v GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 3. LE VRAI DÉFAUT : les années vécues sans canton
-- ---------------------------------------------------------------------------
-- Une commune morte en 1974 a existé trente et un ans après le début de la
-- couche moderne, et a relevé d'un canton pendant tout ce temps. Si son
-- dernier rattachement est daté de 1941, ces années sont vides.
--
-- La cause est structurelle : `24` construit les cantons modernes à partir
-- des millésimes du COG, qui commencent en 1999. Une commune éteinte avant
-- 1999 ne figure dans aucun d'eux et ne reçoit donc jamais de canton. La
-- couche moderne est un instantané projeté, pas une chronologie.
--
-- Ce n'est pas un bogue de `24` mais une conséquence de sa source. Ce qui
-- manquait, c'est la mesure : combien de communes, combien d'années.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Les annees vecues sans rattachement cantonal ==='
SELECT count(*) AS communes,
       min(disparue_le) AS premiere_mort,
       max(disparue_le) AS derniere_mort,
       round(sum(extract(year FROM age(disparue_le, '1943-01-01'::date)))::numeric, 0)
                        AS annees_communes_sans_canton
FROM   orph_v
WHERE  disparue_le >= '1943-01-01'
  AND  dernier_rat <= '1941-01-01';

\echo ''
\echo '=== 4. Les cas sans trace Insee — a instruire un par un ==='
SELECT * FROM orph_v WHERE verdict = 'sans_trace_insee' ORDER BY insee;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    fusion_documentee : `33` a raison, la ligne est bien une fusion,'
\echo '        et sa date d''effet est maintenant connue — a verser au'
\echo '        registre, qui gagne des dates exactes la ou il n''avait que'
\echo '        des bornes.'
\echo '    trou_1941_1942 : disparue entre la fin de TRF-GIS et le premier'
\echo '        mouvement Insee. Limite deja declaree, rien a corriger.'
\echo '    sans_trace_insee : ni mort documentee ni survie. Rare, a'
\echo '        instruire une par une (§ 4).'
\echo ''
\echo 'Le § 3 porte le vrai enjeu : ces communes ont vecu des decennies'
\echo 'apres 1943 sans qu''aucun canton ne leur soit attribue. Le trou'
\echo '1941-1998 ne se limite donc pas aux cantons dont on ignore la'
\echo 'composition : il comprend aussi des communes entieres, absentes de'
\echo 'la couche cantonale pendant toute leur seconde vie.'

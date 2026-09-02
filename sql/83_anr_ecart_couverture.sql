-- ============================================================================
-- histgis — 83_anr_ecart_couverture.sql : pourquoi 486 et non 40
--
--   psql -d histgis -v date=1870-01-01 -f sql/83_anr_ecart_couverture.sql
--
-- LECTURE SEULE. N'écrit que sa propre table de diagnostic, `a83_ecart`.
--
-- CE QU'IL RÉPOND
-- ===============
-- La recette de `82` annonçait « 40 à 1870, dont 20 Paris ». La base en a rendu
-- **486**. L'écart n'est pas une erreur de `82` : il vient de ce que les 40
-- avaient été comptés sur `build/atom.csv` et `build/membership_canton.csv`,
-- c'est-à-dire sur la base telle qu'elle sort de l'extraction — avant que `11`,
-- `15`, `40`, `41`, `44` et `46` ne l'enrichissent de plusieurs centaines
-- d'atomes et ne prolongent des rattachements vers l'arrière.
--
-- *Un chiffre attendu mesuré sur les CSV d'entrée ne décrit pas la base qui en
-- est sortie.* Septième fois que ce dépôt paie une confusion de dénominateur.
--
-- ET CE QU'IL RÉVÈLE, QUI VAUT MIEUX QUE LA CORRECTION
-- ====================================================
-- La cause principale n'est pas un trou d'ANR : c'est que **notre base fait
-- vivre à cette date des communes qu'ANR ne fait naître que plus tard**.
--
-- `11_scission.sql` prolonge vers l'arrière, jusqu'en 1870, les atomes de
-- communes nées après — sur le pari qu'*une commune nouvelle reste dans le
-- canton de sa mère*. Sa table de trace porte d'ailleurs la colonne qui le dit :
-- `debut_reel`, « date d'apparition réelle de l'atome ». Nous savions donc, et
-- nous l'avons écrit, que ces rattachements étaient une INFÉRENCE.
--
-- ANR, lui, ne connaît la commune qu'à partir de sa création. Là où il refuse
-- un polygone, il ne se trompe pas : **il refuse de suivre notre report.**
--
-- D'où l'usage réel de ce fichier : il ne compte pas des trous, il **mesure la
-- part de notre couverture de 1870 qui relève de l'inférence et non de
-- l'attestation** — et il la mesure avec une source qui n'a jamais vu notre
-- code. C'est le troisième contrôle indépendant du projet, après Gay et HAC, et
-- il porte sur une question que ni l'un ni l'autre ne posait.
--
-- CE QU'IL NE DIT PAS
-- ===================
-- Qu'un atome soit reporté ne le rend pas faux. Le pari de `11` a été mesuré
-- contre Gay : 4 perdus sur 414, 99,0 %. Ce fichier ne rouvre pas ce procès, il
-- donne l'effectif exact de ce qui repose dessus **à la date demandée**, ce
-- qu'aucune requête ne savait dire jusqu'ici.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-01-01'
\endif

DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql AVANT celui-ci.';
    END IF;
END $$;

DROP TABLE IF EXISTS a83_ecart;
CREATE TABLE a83_ecart AS
SELECT a.atom_id,
       a.cassini,
       a.insee_geofla                                   AS insee,
       ag.source                                        AS source_geom_actuelle,
       (SELECT min(lower(g.periode)) FROM atom_geom_anr g
         WHERE g.atom_id = a.atom_id)                    AS anr_debut,
       (SELECT max(upper(g.periode)) FROM atom_geom_anr g
         WHERE g.atom_id = a.atom_id)                    AS anr_fin,
       NULL::date                                        AS debut_reel_11,
       NULL::text                                        AS motif
FROM   atom a
LEFT   JOIN atom_geom ag ON ag.atom_id = a.atom_id
WHERE  NOT a.fraction
  AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                   WHERE g.atom_id = a.atom_id AND g.periode @> :'date'::date)
  AND  EXISTS (SELECT 1 FROM membership m
               WHERE m.atom_id = a.atom_id AND m.periode @> :'date'::date);

-- `debut_reel_11` se remplit à part, et par du SQL dynamique. Un `CASE WHEN
-- to_regclass(…) IS NULL` ne suffit PAS : PostgreSQL résout les relations à
-- l'ANALYSE de la requête, avant d'évaluer la moindre branche, si bien qu'une
-- table absente fait échouer un `CASE` censé la contourner. Le banc l'a montré.
-- *Un garde-fou évalué à l'exécution ne protège pas d'une erreur d'analyse.*
DO $$
BEGIN
    IF to_regclass('histgis.scission_trace') IS NOT NULL THEN
        EXECUTE $q$
            UPDATE a83_ecart e SET debut_reel_11 = s.d
            FROM  (SELECT atom_id, min(debut_reel) AS d
                     FROM scission_trace GROUP BY atom_id) s
            WHERE s.atom_id = e.atom_id
        $q$;
    ELSE
        RAISE NOTICE 'scission_trace absente : la colonne debut_reel_11 reste vide, et les § 2 et 4 ne veulent rien dire.';
    END IF;
END $$;

-- Le classement. L'ordre des branches est l'ordre de spécificité : le premier
-- motif qui s'applique est le bon.
UPDATE a83_ecart SET motif =
    CASE
        WHEN left(insee, 2) = '75'      THEN 'Paris — couvert par la trame des quartiers'
        WHEN anr_debut IS NULL          THEN 'ANR ignore cet id_com'
        WHEN anr_debut >  :'date'::date THEN 'ANR ne fait naître la commune qu''après cette date'
        WHEN anr_fin   <= :'date'::date THEN 'ANR arrête la commune avant cette date'
        ELSE                                 'trou interne dans la chronologie ANR'
    END;

CREATE INDEX a83_ecart_motif_idx ON a83_ecart (motif);
ANALYZE a83_ecart;

\echo ''
\echo '--- 1. de quoi l''écart est fait ---'
SELECT motif, count(*) AS n,
       count(*) FILTER (WHERE debut_reel_11 IS NOT NULL) AS dont_posés_par_11,
       count(*) FILTER (WHERE source_geom_actuelle = 'successeur') AS dont_route_successeur
FROM   a83_ecart GROUP BY motif ORDER BY n DESC;

\echo ''
\echo '--- 2. le report de 11, confronté à ANR ---'
\echo '    ANR confirme-t-il que ces communes naissent après la date ?'
SELECT CASE WHEN debut_reel_11 IS NULL THEN 'non posé par 11' ELSE 'posé par 11' END AS origine,
       count(*) AS n,
       count(*) FILTER (WHERE anr_debut > :'date'::date) AS anr_les_fait_naitre_apres,
       round(100.0 * count(*) FILTER (WHERE anr_debut > :'date'::date)
             / nullif(count(*), 0), 1)                  AS pct_accord
FROM   a83_ecart GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '--- 3. quand ANR fait-il naître ce que nous faisons vivre à la date ? ---'
SELECT extract(decade from anr_debut) * 10 AS decennie,
       count(*) AS n
FROM   a83_ecart WHERE anr_debut > :'date'::date
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- 4. les deux dates de naissance comparées ---'
\echo '    debut_reel de 11 (mouvements INSEE) contre le début d''ANR (éditions).'
\echo '    Deux sources, une question, aucun code commun.'
\echo ''
\echo '    LE FILTRE COMPTE : seules les lignes « ANR ne fait naître qu''après »'
\echo '    ont un début d''ANR qui SOIT une date de naissance. Sur un trou interne,'
\echo '    anr_debut est le début de la période d''AVANT le trou — souvent 1790 —'
\echo '    et le comparer à debut_reel ne compare rien. Les mêler tirait l''écart'
\echo '    moyen à -14,8 ans alors que 357 lignes sur 427 tombaient sur l''année.'
SELECT motif,
       count(*) AS n,
       count(*) FILTER (WHERE date_trunc('year', debut_reel_11)
                            = date_trunc('year', anr_debut))          AS meme_annee,
       round(100.0 * count(*) FILTER (WHERE date_trunc('year', debut_reel_11)
                                          = date_trunc('year', anr_debut))
             / nullif(count(*), 0), 1)                                AS pct,
       round(avg(extract(year from anr_debut)
               - extract(year from debut_reel_11)), 1)                AS ecart_moyen_annees
FROM   a83_ecart
WHERE  debut_reel_11 IS NOT NULL AND anr_debut IS NOT NULL
GROUP  BY motif ORDER BY n DESC;

\echo ''
\echo '--- 4 bis. les trous de chronologie d''ANR, qui ne sont PAS des naissances ---'
\echo '    ANR laisse un polygone avant, un polygone après, et rien entre les deux.'
\echo '    532 id_com sur 40 572 (1,31 %) sont dans ce cas quelque part, pour'
\echo '    11 113 années-communes, largeur médiane 12 ans. Le trou frappe surtout'
\echo '    1870 : 75 communes, contre 17 en 1900, 6 en 1940, 0 en 1954.'
\echo '    Vingt communes des Ardennes partagent la même signature 1828 | 1871.'
\echo '    R5 les rattrape — elles gardent atom_geom — mais ANR ne les déclare pas.'
SELECT e.atom_id, e.cassini, e.insee, e.anr_debut, e.anr_fin,
       (SELECT string_agg(to_char(lower(g.periode), 'YYYY') || '-' ||
                          to_char(upper(g.periode), 'YYYY'), ' | ' ORDER BY g.periode)
          FROM atom_geom_anr g WHERE g.atom_id = e.atom_id)  AS fenetres_anr
FROM   a83_ecart e
WHERE  e.motif = 'trou interne dans la chronologie ANR'
ORDER  BY e.insee LIMIT 25;

\echo ''
\echo '--- 5. ce qui reste vraiment inexpliqué ---'
SELECT atom_id, cassini, insee, source_geom_actuelle, anr_debut, anr_fin
FROM   a83_ecart
WHERE  motif IN ('ANR ignore cet id_com', 'trou interne dans la chronologie ANR')
ORDER  BY motif, insee LIMIT 40;

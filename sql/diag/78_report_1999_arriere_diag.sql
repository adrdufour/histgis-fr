-- ============================================================================
-- histgis — 78_report_1999_arriere_diag.sql : reporter le COG 1999 EN ARRIÈRE ?
--
--   psql -d histgis -f sql/diag/78_report_1999_arriere_diag.sql
--
-- LECTURE SEULE. N'écrit ni dans `atom`, ni dans `unit`, ni dans `membership`.
-- Tout ce qu'il crée est préfixé `r78_` et se jette.
--
-- LA QUESTION
-- ===========
-- La couche cantonale de 1999 est en base (`24`), exacte, et elle n'est pas
-- océrisée : c'est le COG, lu dans un fichier de l'INSEE. Le registre des
-- actes est en base (`72`), 343 décrets de 1958 à 1999. Si le registre est
-- complet, alors pour un département dont le dernier acte date de 1988, RIEN
-- n'a bougé de 1988 à 1999 — et la composition de 1999 vaut pour 1988.
--
-- C'est le report du § 5 de `cantons/note_decrets.md` (partie « Ce qui peut entrer en base »), mais pris par
-- l'autre bout de la chaîne : « étendre là où un acte borne l'intervalle des
-- deux côtés ». Ici les deux bornes sont des faits — le COG en haut, un acte
-- daté en bas — là où l'extension du jalon de 1968 n'avait qu'un OCR de chaque
-- côté et voyait son test propre déclaré indisponible.
--
-- CE QUE CE FICHIER MESURE, ET DANS QUEL ORDRE
-- ============================================
--   § 2  le PLANCHER par département, sous deux conventions concurrentes
--   § 3  ce qui INTERDIT le report : actes sans département, `82-82`
--   § 4  ce que le report couvrirait, et ce qui est déjà occupé
--   § 5  LE CONTRÔLE — la seule section qui juge, cf. ci-dessous
--   § 6  le témoin (1940 -> 1954) et ce qui resterait invisible
--
-- LE CONTRÔLE DU § 5, ET POURQUOI IL EST GRATUIT
-- ===============================================
-- `75` et `76` ont posé, depuis le TEXTE DES DÉCRETS, la composition des
-- cantons touchés par le dernier acte de leur département, de la date d'effet
-- jusqu'à 1999. Le COG de 1999 dit la composition de ces mêmes cantons au
-- 1er janvier 1999. Les deux se touchent sans se recouvrir.
--
-- Or l'hypothèse du report est exactement : *entre le dernier acte et 1999,
-- rien n'a bougé.* Si elle est vraie, les deux doivent coïncider. Le JO
-- océrisé et le COG n'ont aucun lien : c'est un contrôle indépendant, et il ne
-- coûte rien puisque les deux couches sont déjà en base.
--
-- **Un désaccord n'est pas nécessairement un mouvement non enregistré** — ce
-- peut être une lecture fautive du JO. Le § 5 ne peut donc pas prouver le
-- report ; il peut le TUER. C'est le seul verdict qu'on lui demande.
--
-- CE QU'IL NE MESURE PAS, ET QU'AUCUNE REQUÊTE NE MESURERA
-- ========================================================
-- Les transferts isolés de commune que l'annexe VII ne recense jamais par
-- construction — 274 non datés au registre cantonal. S'ils n'ont pas laissé de
-- décret au registre, le plancher les ignore et le report passe par-dessus
-- sans que rien ne le signale. Le seul ordre de grandeur disponible vient du
-- report 1940 -> 1954 : 0,29 % des communes en quatorze ans (`70`, `71`).
--
-- Prérequis : `24` (couche 1999), `72` (registre), `75` (acte_effet,
--             scrutin_cantonal). `76` et `77` améliorent le § 5 sans être
--             indispensables.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set fin_serie '1999-01-01'
\set date_1999 '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' Le report EN ARRIÈRE depuis le COG 1999 — diagnostic'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_cantonal') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql.';
    END IF;
    IF to_regclass('histgis.acte_departement') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : rejouer sql/72_registre_actes.sql (acte_departement, § 3 bis).';
    END IF;
    IF to_regclass('histgis.acte_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/75_composition_1973_1982.sql (acte_effet).';
    END IF;
    -- psql n'interpole PAS ses variables dans une chaîne dollar-quotée :
    -- la date est écrite en clair ici, et nulle part ailleurs.
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton'
                      AND periode @> '1999-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1999 est absente — jouer sql/24_canton_moderne.sql.';
    END IF;
    IF to_regclass('histgis.p75_trace') IS NULL
       OR to_regclass('histgis.p76_trace') IS NULL
       OR to_regclass('histgis.p75_lien')  IS NULL
       OR to_regclass('histgis.p76_lien')  IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS des §§ 5 : jouer sql/75_… puis sql/76_… (p7*_trace, p7*_lien).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. LE PLANCHER — jusqu'où le report peut descendre, département par
--    département
--
-- Deux conventions, et il faut les distinguer parce qu'elles ne disent pas la
-- même chose :
--
--   plancher_effet     la date d'effet du dernier acte (convention de `75`,
--                      premier tour du renouvellement suivant la signature).
--                      C'est la date à laquelle la composition nouvelle vaut.
--
--   plancher_signature la date de SIGNATURE du dernier acte. ANTÉRIEURE de
--                      183 jours en moyenne, donc plancher plus BAS, donc
--                      fenêtre plus LONGUE.
--
-- **On retient `plancher_effet`, et le premier jet de ce fichier retenait
-- l'autre — à tort.** Le raisonnement fautif était : « signature est plus
-- haute, donc plus prudente ». Elle est plus BASSE. Et sur l'intervalle
-- [signature, effet) c'est encore l'ANCIENNE composition qui vaut, celle que
-- le décret défait : y reporter l'état de 1999 est faux par construction, sur
-- 183 jours et 96 départements.
--
-- *Une borne plus large n'est pas une borne plus prudente ; c'est l'inverse.*
--
-- `plancher_effet` traite d'ailleurs correctement le cas qui avait servi
-- d'argument à l'erreur : un acte signé avant 1999 dont l'effet tombe après
-- est écarté par le FILTER, et le plancher retombe sur l'acte précédent — ce
-- qui est juste, puisque sa modification n'avait pas encore pris effet
-- en 1999.
-- ---------------------------------------------------------------------------
-- Le département vient de `acte_departement` (`72` § 3 bis) et non de
-- `acte_cantonal.dep` : un acte peut en toucher DEUX — le décret n° 96-709
-- déplace une commune de la Meuse vers la Meurthe-et-Moselle — et la colonne
-- unique de `acte_cantonal` ne peut pas le dire.
DROP TABLE IF EXISTS r78_plancher;
CREATE TABLE r78_plancher AS
SELECT d.dep,
       count(*)                                            AS actes,
       max(e.date_effet) FILTER (
           WHERE e.date_effet < :'fin_serie'::date)         AS plancher_effet,
       max(a.date_signature) FILTER (
           WHERE a.date_signature < :'fin_serie'::date)     AS plancher_signature,
       count(*) FILTER (WHERE a.texte_integral = 'non')     AS sans_texte,
       count(*) FILTER (
           WHERE NOT EXISTS (SELECT 1 FROM acte_composition c
                              WHERE c.date_acte = a.date_signature
                                AND c.dep = d.dep))         AS non_depouilles
FROM   acte_departement d
JOIN   acte_cantonal a ON a.legifrance_id = d.legifrance_id
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  length(d.dep) = 2
  -- un acte lu et déclaré sans effet sur l'appartenance ne borne rien
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                    WHERE x.legifrance_id = a.legifrance_id)
GROUP  BY d.dep;

ALTER TABLE r78_plancher ADD PRIMARY KEY (dep);

-- `date - date` rend un ENTIER de jours, pas un intervalle : pas d'`extract`
-- ici, c'est une division directe.
ALTER TABLE r78_plancher ADD COLUMN profondeur_annees numeric;
UPDATE r78_plancher
   SET profondeur_annees =
         round((:'fin_serie'::date - plancher_effet) / 365.25, 1)
 WHERE plancher_effet IS NOT NULL;

\echo ''
\echo '-- 2. le plancher, vue d''ensemble'
SELECT count(*)                                          AS departements,
       count(*) FILTER (WHERE plancher_effet IS NULL)    AS sans_aucun_acte,
       round(avg(profondeur_annees), 1)                  AS profondeur_moyenne,
       -- `percentile_cont` n'a pas de variante numeric : il rend un
       -- double precision, que `round(x, n)` refuse. D'où le cast.
       round((percentile_cont(0.5) WITHIN GROUP (
              ORDER BY profondeur_annees))::numeric, 1)  AS mediane,
       min(profondeur_annees)                            AS mini,
       max(profondeur_annees)                            AS maxi
FROM   r78_plancher;

\echo ''
\echo '-- 2 bis. répartition de la profondeur de report'
SELECT CASE WHEN profondeur_annees IS NULL   THEN 'aucun acte (report ouvert)'
            WHEN profondeur_annees <  5      THEN 'moins de 5 ans'
            WHEN profondeur_annees < 10      THEN '5 à 10 ans'
            WHEN profondeur_annees < 15      THEN '10 à 15 ans'
            WHEN profondeur_annees < 20      THEN '15 à 20 ans'
            ELSE                                  '20 ans et plus'
       END                                   AS tranche,
       count(*)                              AS departements
FROM   r78_plancher GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 2 ter. ce que la signature ferait reporter EN TROP (donc à tort)'
SELECT count(*) FILTER (WHERE plancher_effet = plancher_signature) AS identiques,
       count(*) FILTER (WHERE plancher_effet <> plancher_signature) AS differents,
       round(avg(plancher_effet - plancher_signature) FILTER (
             WHERE plancher_effet <> plancher_signature), 0)       AS jours_en_trop
FROM   r78_plancher
WHERE  plancher_effet IS NOT NULL AND plancher_signature IS NOT NULL;

\echo ''
\echo '   Positif = l''effet est POSTÉRIEUR à la signature. Prendre la'
\echo '   signature pour plancher reporterait l''état de 1999 sur une période'
\echo '   où l''ANCIENNE composition valait encore. C''est l''erreur du premier'
\echo '   jet, corrigée : une borne plus large n''est pas plus prudente.'

-- ---------------------------------------------------------------------------
-- 3. CE QUI INTERDIT LE REPORT
--
-- Un acte SANS DÉPARTEMENT est le seul vrai poison : il a pu toucher
-- n'importe quel département, donc il abaisse potentiellement TOUS les
-- planchers, et rien dans les données ne dit lesquels. `82-82` (« divers
-- départements ») est le cas d'école.
--
-- Un acte connu mais NON DÉPOUILLÉ, en revanche, ne gêne pas : il porte son
-- département et sa date, donc il fixe le plancher correctement même si
-- personne n'a lu son texte. C'est précisément ce que `72` cherchait à rendre
-- possible — « aucun acte n'est enregistré ici » plutôt que « on ne sait pas ».
-- ---------------------------------------------------------------------------
-- ATTENTION — deux cas que le premier jet confondait, et que le banc a
-- séparés : un acte d'OUTRE-MER porte un département (`971`), il est
-- simplement hors de la nomenclature métropolitaine et ne touche aucun
-- plancher d'ici. Un acte SANS département est le seul poison. Les compter
-- ensemble gonflerait le nombre d'actes bloquants — 17 au lieu de 9 — et
-- pourrait abaisser le plafond global sur la foi d'un acte guadeloupéen.
\echo ''
\echo '-- 3. les actes hors nomenclature métropolitaine, par nature'
SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM acte_departement d
                              WHERE d.legifrance_id = a.legifrance_id)
            THEN 'SANS DÉPARTEMENT — bloquant'
            ELSE 'outre-mer — sans effet ici' END AS nature,
       a.legifrance_id,
       coalesce(nullif(a.decret, ''), '(non numéroté)') AS decret,
       a.date_signature, a.objet,
       coalesce((SELECT string_agg(d.dep, '+' ORDER BY d.dep)
                   FROM acte_departement d
                  WHERE d.legifrance_id = a.legifrance_id), '(vide)') AS dep,
       a.texte_integral
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id
                      AND length(d.dep) = 2)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id)
ORDER  BY 1, a.date_signature;

\echo ''
\echo '   Seuls les « SANS DÉPARTEMENT » comptent : chacun abaisse le plancher'
\echo '   de tous les départements qu''il touche, et on ignore lesquels. Tant'
\echo '   qu''ils ne sont pas attribués un par un, le report doit être plafonné'
\echo '   à leur date de signature. Les actes d''outre-mer portent un'
\echo '   département et ne bornent rien en métropole — les mêler aux premiers'
\echo '   ferait passer le nombre d''actes bloquants de 9 à 17.'

\echo ''
\echo '-- 3 bis. le plafond imposé par les SEULS actes non attribués'
SELECT max(a.date_signature) FILTER (
         WHERE a.date_signature < :'fin_serie'::date)  AS plafond_global,
       count(*)                                        AS actes_non_attribues,
       (SELECT count(DISTINCT d.legifrance_id) FROM acte_departement d
         WHERE length(d.dep) <> 2)                     AS dont_outre_mer_ecartes
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id);

\echo ''
\echo '-- 3 ter. actes connus et non dépouillés — ils BORNENT sans être lus'
SELECT count(*)                                            AS actes,
       count(*) FILTER (WHERE texte_integral = 'non')      AS sans_texte_legifrance,
       count(DISTINCT dep) FILTER (WHERE length(dep) = 2)  AS departements_touches
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_composition c
                    WHERE c.date_acte = a.date_signature
                      AND c.dep = a.dep);

-- ---------------------------------------------------------------------------
-- 4. LE VOLUME — ce que le report couvrirait, et ce qui est déjà occupé
--
-- La contrainte `membership_non_chevauchant` interdit de poser là où quelque
-- chose est déjà en place. Un atome dont la fenêtre de report est déjà
-- occupée — par `59` (jalon 1968), `74`, `75`, `76` ou `77` — n'est pas un
-- échec : c'est une place prise par mieux renseigné que le report.
-- ---------------------------------------------------------------------------
-- `p79_trace` peut ne pas exister (79 jamais joué) : on la crée vide plutôt
-- que de conditionner la requête, pour que le fichier reste lisible.
CREATE TABLE IF NOT EXISTS p79_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DROP TABLE IF EXISTS r78_cible;
CREATE TABLE r78_cible AS
SELECT m.atom_id,
       m.unit_id,
       u.dep,
       p.plancher_effet                        AS depuis,
       :'fin_serie'::date                      AS jusqu_a,
       p.profondeur_annees
FROM   membership m
JOIN   unit u        ON u.unit_id = m.unit_id AND u.niveau = 'canton'
JOIN   r78_plancher p ON p.dep = u.dep::text
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1999'::date
  AND  p.plancher_effet IS NOT NULL;

CREATE INDEX r78_cible_idx ON r78_cible (atom_id);

-- LE PIÈGE D'ORDRE, TROUVÉ LE 29 AOÛT 2026 AU TROISIÈME PASSAGE.
--
-- `78` mesure une OPPORTUNITÉ : ce que le report pourrait poser. Si `79` a
-- déjà tourné, ses propres lignes occupent les fenêtres, et le § 4 rend
-- `fenetre_entierement_libre = 0`. Le fichier comptait alors son propre
-- résultat comme un obstacle, sans que rien ne le dise — les chiffres restaient
-- cohérents, ils ne voulaient simplement plus rien dire.
--
-- On exclut donc de l'occupation ce que `79` a posé, quand la trace existe.
-- *Un diagnostic qui voit l'effet du remède le prend pour la maladie.*
ALTER TABLE r78_cible ADD COLUMN occupe_jours integer;
UPDATE r78_cible c
   SET occupe_jours = coalesce((
       SELECT sum(
           greatest(0,
             least(m.valid_to,   c.jusqu_a)
           - greatest(m.valid_from, c.depuis)))
       FROM   membership m
       WHERE  m.atom_id = c.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(c.depuis, c.jusqu_a, '[)')
         AND  NOT EXISTS (SELECT 1 FROM p79_trace t
                           WHERE t.quoi = 'membership'
                             AND t.cle  = m.membership_id::text)), 0);

\echo ''
\echo '-- 4. le volume du report'
\echo '   (l''occupation IGNORE ce que `79` a lui-même posé : sinon le remède'
\echo '    serait compté comme la maladie et tout paraîtrait déjà pris)'
SELECT count(*)                                                AS atomes_1999,
       count(*) FILTER (WHERE occupe_jours = 0)                AS fenetre_entierement_libre,
       count(*) FILTER (WHERE occupe_jours > 0
                          AND occupe_jours < (jusqu_a - depuis)) AS partiellement_occupee,
       count(*) FILTER (WHERE occupe_jours >= (jusqu_a - depuis)) AS deja_pleine,
       round(sum(profondeur_annees) FILTER (WHERE occupe_jours = 0)
             / 1000.0, 1)                                      AS milliers_atome_annees
FROM   r78_cible;

\echo ''
\echo '-- 4 bis. les 15 départements où le report rend le plus'
SELECT c.dep,
       max(c.profondeur_annees)                  AS annees,
       count(*)                                  AS atomes,
       count(*) FILTER (WHERE c.occupe_jours = 0) AS libres,
       round(max(c.profondeur_annees)
             * count(*) FILTER (WHERE c.occupe_jours = 0))
                                                 AS atome_annees
FROM   r78_cible c
GROUP  BY c.dep
ORDER  BY atome_annees DESC NULLS LAST
LIMIT  15;

-- ---------------------------------------------------------------------------
-- 5. LE CONTRÔLE — le JO et le COG disent-ils la même chose ?
--
-- On prend les rattachements posés par `75` et `76` depuis le texte des
-- décrets, dont la période se termine à la fin de série. Pour ces atomes-là,
-- le décret dit un canton du jour de l'acte à 1999, et le COG en dit un au
-- 1er janvier 1999. Le report suppose qu'ils sont le même.
--
-- ATTENTION — CE CONTRÔLE N'EST PAS INDÉPENDANT, ET LE PREMIER JET DE CE
-- FICHIER PRÉTENDAIT QU'IL L'ÉTAIT.
--
-- `75` et `76` ne LISENT pas un `unit_id` dans le décret : le décret nomme un
-- canton, et le fichier le résout **en votant contre la couche de 1999** — le
-- canton retenu est celui de 1999 qui partage au moins 80 % des communes de la
-- liste. La population testée ici est donc celle qui a été RETENUE PARCE
-- QU'ELLE CONCORDAIT avec 1999. Mesurer son accord avec 1999, c'est lui faire
-- mesurer son propre critère d'admission.
--
-- C'est exactement le piège que `70` § 2 documente pour `ferme_canton`, et
-- j'ai marché dedans. *Un échantillon filtré par le critère qu'on mesure ne
-- mesure plus rien.*
--
-- CE QUE LE § 5 DIT ENCORE, ET C'EST PEU : le vote se fait au niveau du
-- CANTON, la pose au niveau de la COMMUNE. Une commune minoritaire — jusqu'à
-- 20 % de la liste — est posée dans le canton majoritaire et ressort ici comme
-- désaccord. Le taux mesure donc l'unanimité des votes retenus, pas la
-- validité du report.
--
-- CE QU'IL NE VOIT PAS : les cantons refusés entre 50 % et 80 % (`accord
-- partiel`) et sous 50 % (`desaccord`) n'ont jamais été posés, donc n'entrent
-- pas dans l'échantillon. **Ce sont précisément les cas où quelque chose a
-- bougé entre l'acte et 1999.** Le § 5 ter les compte : c'est là qu'est
-- l'information, et elle contredit le § 5.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r78_controle;
CREATE TABLE r78_controle AS
SELECT m.atom_id,
       m.unit_id                                AS dit_par_le_decret,
       m.valid_from,
       (SELECT n.unit_id FROM membership n
         WHERE n.atom_id = m.atom_id
           AND n.niveau  = 'canton'
           AND n.periode @> :'date_1999'::date
         LIMIT 1)                               AS dit_par_le_cog,
       CASE WHEN t75.cle IS NOT NULL THEN '75' ELSE '76' END AS pose_par
FROM   membership m
LEFT   JOIN p75_trace t75 ON t75.quoi = 'membership'
                         AND t75.cle  = m.membership_id::text
LEFT   JOIN p76_trace t76 ON t76.quoi = 'membership'
                         AND t76.cle  = m.membership_id::text
WHERE  m.niveau   = 'canton'
  AND  m.valid_to = :'fin_serie'::date
  AND  (t75.cle IS NOT NULL OR t76.cle IS NOT NULL);

\echo ''
\echo '-- 5. le décret contre le COG, sur la fenêtre même du report'
SELECT pose_par,
       count(*)                                                  AS atomes,
       count(*) FILTER (WHERE dit_par_le_cog IS NULL)            AS sans_canton_en_1999,
       count(*) FILTER (WHERE dit_par_le_cog = dit_par_le_decret) AS accord,
       count(*) FILTER (WHERE dit_par_le_cog IS NOT NULL
                          AND dit_par_le_cog <> dit_par_le_decret) AS desaccord,
       round(100.0 * count(*) FILTER (WHERE dit_par_le_cog = dit_par_le_decret)
             / nullif(count(*) FILTER (WHERE dit_par_le_cog IS NOT NULL), 0), 2)
                                                                 AS pct_accord
FROM   r78_controle
GROUP  BY pose_par
ORDER  BY pose_par;

\echo ''
\echo '-- 5 bis. les désaccords, vus de près (25 premiers)'
SELECT c.atom_id, c.valid_from, c.pose_par,
       c.dit_par_le_decret,
       unit_nom(c.dit_par_le_decret, c.valid_from) AS nom_decret,
       c.dit_par_le_cog,
       unit_nom(c.dit_par_le_cog, :'date_1999'::date) AS nom_cog
FROM   r78_controle c
WHERE  c.dit_par_le_cog IS NOT NULL
  AND  c.dit_par_le_cog <> c.dit_par_le_decret
ORDER  BY c.atom_id
LIMIT  25;

\echo ''
-- ---------------------------------------------------------------------------
-- 5 ter. LA POPULATION EXCLUE — la seule mesure du § 5 qui vaille
--
-- Les cantons que `75`/`76` ont REFUSÉS sont ceux dont la liste du décret ne
-- se retrouve pas dans la couche de 1999. Deux lectures possibles, et le
-- fichier ne tranche pas : une lecture fautive du JO, ou un mouvement réel
-- entre l'acte et 1999. Dans le second cas le report est faux sur ce canton.
--
-- Le rapport `refusés / (refusés + résolus)` est la BORNE HAUTE honnête du
-- taux d'erreur du report. Le § 5, lui, a exclu tous les refusés de son
-- échantillon avant de compter.
-- ---------------------------------------------------------------------------
-- LA RESTRICTION QUI MANQUAIT AU PREMIER JET DE CE §, ET SANS LAQUELLE IL
-- COMPTE TROP.
--
-- Un décret de 1973 dans un département qui a rebougé en 1985 n'a AUCUN
-- rapport avec le report : la fenêtre du report s'arrête au dernier acte,
-- 1985, et ne descend jamais jusqu'à 1973. Que sa composition ne se retrouve
-- pas dans le COG de 1999 est attendu — c'est l'acte de 1985 qui l'a défaite,
-- et cela ne dit rien du report.
--
-- `75` et `76` posent `valid_to = least(effet de l'acte suivant, fin de
-- série)`. Un lien dont la période s'arrête EXACTEMENT à la fin de série est
-- donc, par construction, un lien qu'aucun acte postérieur n'a interrompu :
-- c'est la population du report, et elle seule.
--
-- *Une mesure juste sur la mauvaise population reste une mesure fausse.*
-- Troisième fois que ce fichier se fait prendre au même endroit : ce qu'on
-- compte importe plus que la façon dont on le compte.
DROP TABLE IF EXISTS r78_lien;
CREATE TABLE r78_lien AS
SELECT '75' AS src, verdict, communes, taux, valid_to FROM p75_lien
UNION ALL
SELECT '76',        verdict, communes, taux, valid_to FROM p76_lien;

\echo ''
\echo '-- 5 ter. ce que le vote a REFUSÉ — SUR LA POPULATION DU REPORT'
\echo '   (liens qu''aucun acte postérieur n''interrompt : valid_to = fin de série)'
SELECT src, verdict, count(*) AS cantons, sum(communes) AS communes,
       round(avg(taux), 1) AS taux_moyen
FROM   r78_lien
WHERE  valid_to = :'fin_serie'::date
GROUP  BY src, verdict
ORDER  BY src, cantons DESC;

\echo ''
\echo '-- 5 quater. la borne haute honnête, et ce que la restriction change'
SELECT CASE WHEN restreint THEN 'population du report'
            ELSE                'TOUS les actes (compte trop)' END AS population,
       count(*) FILTER (WHERE verdict = 'resolu')            AS resolus,
       count(*) FILTER (WHERE verdict IN ('accord partiel',
                                          'desaccord'))      AS contredits,
       sum(communes) FILTER (WHERE verdict IN ('accord partiel',
                                               'desaccord')) AS communes_contredites,
       round(100.0 * count(*) FILTER (WHERE verdict IN ('accord partiel',
                                                        'desaccord'))
             / nullif(count(*) FILTER (WHERE verdict IN ('resolu',
                       'accord partiel', 'desaccord')), 0), 1)
                                                             AS pct_borne_haute
FROM  (SELECT verdict, communes, true  AS restreint FROM r78_lien
        WHERE valid_to = :'fin_serie'::date
       UNION ALL
       SELECT verdict, communes, false                FROM r78_lien) y
GROUP  BY restreint
ORDER  BY restreint DESC;

\echo ''
\echo '   `trop court` est exclu du ratio : moins de trois communes, le vote'
\echo '   ne s''y prononce pas. Ce n''est pas un désaccord, c''est un silence.'

\echo ''
\echo '   Lecture : un désaccord peut être un mouvement non enregistré — ce qui'
\echo '   condamne le report sur ce département — ou une lecture fautive du JO,'
\echo '   ce qui ne dit rien du report. Le § 5 ne tranche pas entre les deux ;'
\echo '   il donne la BORNE HAUTE du taux d''erreur du report.'

-- ---------------------------------------------------------------------------
-- 6. LE TÉMOIN, ET CE QUI RESTE INVISIBLE
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. les repères déjà mesurés par le dépôt'
\echo '   1940 -> 1954, 14 ans,  3 créations  : 99,50 % (accord par commune, `70`)'
\echo '   1954 -> 1968, 14 ans, 30 créations  : 89,80 % (accord des partitions, `66`)'
\echo '   transferts non datés imputés         : 0,29 % des communes en 14 ans'
\echo ''
\echo '   Le report d''ici est plus court que ces deux-là (médiane ~10 ans) et'
\echo '   s''appuie en haut sur une source NON océrisée.'
\echo ''
\echo '   COMPARER AU § 5 QUATER, PAS AU § 5. Le § 5 mesure un échantillon'
\echo '   choisi pour concorder avec 1999 ; son taux est vrai et ne juge rien.'
\echo '   Le § 5 quater compte ce que le vote a écarté — c''est la borne haute'
\echo '   honnête, et c''est elle qui doit tenir devant les 89,8 % de 1954.'

\echo ''
\echo '-- 6 bis. ce que le registre ne peut pas voir'
SELECT 'transferts isolés non datés au registre cantonal' AS angle_mort,
       274                                                AS ordre_de_grandeur,
       'l''annexe VII ne les recense jamais, par construction' AS pourquoi;

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo ' Tables jetables laissées en place : r78_plancher, r78_cible,'
\echo ' r78_controle.'
\echo '============================================================'

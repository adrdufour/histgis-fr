-- ============================================================================
-- histgis — 81_report_1968_avant.sql : le jalon de 1968 descend le temps
--
--   psql -d histgis -1 -f sql/81_report_1968_avant.sql
--
-- ÉCRIT DANS `membership`. Tout est tracé dans `p81_trace` et le § 2 défait le
-- passage précédent : le fichier est rejouable seul.
--
-- CE QU'IL POSE, ET SUR QUELLE AUTORITÉ
-- =====================================
-- Le jumeau de `79`, pris par l'autre bout. Pour chaque département, le
-- registre des actes (`72`) dit quel est le PREMIER acte postérieur au jalon de
-- 1968. Si le registre est complet, rien n'a bougé entre le 1er janvier 1969 et
-- la date d'effet de cet acte, et la composition lue au recensement de 1968
-- (`59`) vaut sur tout l'intervalle.
--
-- Comme `79`, c'est une INFÉRENCE et non une convention : elle ne suppose rien
-- sur une date, elle suppose une ABSENCE — et une absence se vérifie.
--
-- L'HYPOTHÈSE A ÉTÉ ÉPROUVÉE, ET C'EST NEUF
-- =========================================
-- `79` a été écrit sur une borne haute de 2,8 %, tirée d'un échantillon de 108
-- cantons hérité du vote de `75`/`76` — son propre en-tête disait « ce n'est
-- pas une preuve ». Le § 6 quinquies de `80`, joué le 30 août 2026, a fait
-- mieux, sur toute la France et sans vote :
--
--   accord 1968/1999, atomes JAMAIS NOMMÉS par un décret   94,90 %  (30 306)
--   accord 1968/1999, atomes NOMMÉS par un décret          33,49 %  ( 2 536)
--
--   test de signe apparié : 49 départements sur 49 dans le même sens,
--   zéro contre, écart médian +62,1 points. Sous l'hypothèse nulle, 2⁻⁴⁹.
--   Sur les 54 départements intégralement dépouillés : 28 sur 28, +58,3.
--
-- L'affirmation testée n'était pas la tautologie « les communes que les décrets
-- nomment ont changé de canton », mais celle, forte et réfutable, que le
-- registre porte : **en dehors de ces 2 536 atomes, RIEN n'a bougé en trente et
-- un ans.** Si le registre était incomplet, les communes déplacées par des
-- actes qu'il ignore se trouveraient chez les jamais-nommés et feraient chuter
-- leur taux. Elles n'y sont pas.
--
-- **`79` est validé par la même mesure** : les deux fichiers reposent sur
-- l'hypothèse unique qui vient d'être éprouvée.
--
-- CE QUE 94,9 % NE DIT PAS
-- ========================
-- Ce n'est pas 100 %. Les 5,1 % résiduels mêlent trois choses qu'aucune requête
-- ne sépare : l'OCR de 1968 (`59` : 79,9 % `ferme`, 3,1 % `canton_conteste`),
-- les cantons **vidés sans être nommés** par un décret — biais connu, de sens
-- connu — et d'éventuels vrais trous du registre. Repère : 94,9 % se place
-- entre les 89,80 % de 1954 → 1968 et les 99,50 % de 1940 → 1954, sur un
-- intervalle de 31 ans contre 14.
--
-- D'où le § 10 : **chaque ligne posée porte le taux mesuré de son propre
-- département**. Une ligne du 95 (78,1 %, le plus bas) et une ligne du 03
-- (98,5 %) ne valent pas la même chose, et rien dans `membership` ne le dirait.
-- `p79_qualite` n'a pas cette colonne ; elle lui manque.
--
-- LA BORNE HAUTE EST LA DATE D'EFFET, JAMAIS LA SIGNATURE
-- =======================================================
-- Sur [signature, effet) c'est encore l'ANCIENNE composition qui vaut — celle
-- que le décret défait, donc celle de 1968. Reporter jusqu'à l'effet n'est pas
-- une hypothèse : le décret lui-même dit que rien n'a changé avant cette date.
-- Mesuré ici : l'effet suit la signature de 59 jours, sur 96 départements
-- sur 96. **La même convention raccourcit la fenêtre de `79` et allonge celle
-- de `81`** — elle est juste dans les deux cas, et c'est le même fait qui la
-- fonde.
--
-- LA BORNE DES ACTES INCONNUS, ET POURQUOI ELLE EST INVERSE DE CELLE DE `79`
-- ==========================================================================
-- Un acte encore SANS DÉPARTEMENT a pu toucher n'importe lequel. Pour `79`,
-- qui remonte, la part risquée est SOUS la date de l'acte ; pour `81`, qui
-- descend, elle est AU-DESSUS :
--
--   [1969-01-01, borne)  `sous_acte_inconnu = false`  aucun acte inconnu avant
--   [borne, premier acte) `sous_acte_inconnu = true`  un acte inconnu a pu y tomber
--
-- Au 30 août 2026 il n'y a **plus aucun acte sans département** (`72` § 3 ter,
-- les huit derniers lus le 29 août) : le mécanisme est inerte. Il est conservé
-- parce qu'un acte non attribué peut reparaître, et qu'alors rien d'autre ne le
-- signalerait. La part marquée se retire seule :
--
--   DELETE FROM histgis.membership m USING histgis.p81_qualite q
--    WHERE q.membership_id = m.membership_id AND q.sous_acte_inconnu;
--
-- CE QUI N'EST PAS POSÉ, ET C'EST VOULU
-- =====================================
--   * les atomes dont la fenêtre est même partiellement occupée. `74`, `75`,
--     `76`, `77` et `79` sont mieux renseignés que le report. Au diagnostic
--     `80`, aucun ne l'était : les 32 842 fenêtres sont libres, parce que `79`
--     s'arrête au DERNIER acte et `81` au PREMIER. Le tamis reste en place.
--   * `75` (Paris) : aucun atome dans le jalon de 1968, donc rien à reporter.
--     Ce n'est pas un trou du registre — Paris ne relève pas du régime des
--     décrets de délimitation (`79` § 10 b/c).
--
-- LA LIGNE POSÉE EST DISTINCTE DE CELLE DU JALON
-- ==============================================
-- `59` pose [1968-01-01, 1969-01-01) ; `81` pose [1969-01-01, premier acte).
-- Deux lignes jointives, même `unit_id`, deux fichiers, deux autorités : un
-- recensement d'un côté, une inférence de l'autre. Les fondre ferait perdre la
-- distinction, et c'est le choix qu'a fait `79` avant celui-ci.
--
-- Prérequis : `59` (jalon 1968), `24` (couche 1999), `72` (registre +
--             `acte_departement` + `acte_sans_effet`), `75` (`acte_effet`).
--             À jouer APRÈS `79`. Le diagnostic `80` n'est pas requis.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut  '1968-01-01'
\set jalon_fin    '1969-01-01'
\set jalon_temoin '1968-06-01'
\set fin_serie    '1999-01-01'
\set date_1999    '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' REPORT DU JALON DE 1968 VERS L''AVANT'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_departement') IS NULL
       OR to_regclass('histgis.acte_sans_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : rejouer sql/72_registre_actes.sql (acte_departement, acte_sans_effet).';
    END IF;
    IF to_regclass('histgis.acte_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/75_composition_1973_1982.sql (acte_effet).';
    END IF;
    -- psql n'interpole PAS ses variables dans une chaîne dollar-quotée :
    -- les dates sont écrites en clair ici, et nulle part ailleurs.
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> '1968-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : le jalon 1968 est absent — jouer sql/59_cog1968_membership.sql.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> '1999-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1999 est absente — jouer sql/24_canton_moderne.sql.';
    END IF;
    -- Les §§ 2 et 11 b prennent `79` pour témoin : si ses lignes bougent
    -- pendant ce passage, il faut le voir. Un témoin absent ne se remplace pas
    -- par un zéro — il rendrait la recette muette au lieu de fausse.
    IF to_regclass('histgis.p79_trace') IS NULL
       OR to_regclass('histgis.p79_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/79_report_1999_arriere.sql AVANT celui-ci (p79_trace, p79_qualite).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. DÉFAIRE LE PASSAGE PRÉCÉDENT
--
-- `p81_trace` ne porte que des `membership_id` posés par ce fichier. Rien
-- d'autre n'est touché, donc rien d'autre n'est à défaire.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p81_trace (
    quoi text NOT NULL,          -- 'membership'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p81_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p81_trace;
DROP TABLE IF EXISTS p81_qualite;

-- Les témoins, pris AVANT toute écriture. `79` a payé de trois erreurs le fait
-- de comparer à des nombres venus d'ailleurs : *une recette qui compare à un
-- nombre recopié mesure la mémoire de celui qui l'a écrite, pas la base.*
DROP TABLE IF EXISTS p81_temoin;
CREATE TABLE p81_temoin AS
SELECT (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1968-06-01'::date) AS jalon_1968,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1999-06-01'::date) AS couche_1999,
       (SELECT count(*) FROM membership WHERE niveau = 'canton')    AS total_canton,
       coalesce((SELECT count(*) FROM p79_trace
                  WHERE quoi = 'membership'), 0)                    AS lignes_de_79;

-- ---------------------------------------------------------------------------
-- 3. LA BORNE HAUTE PAR DÉPARTEMENT — la date d'effet du PREMIER acte
--
-- Le département vient de `acte_departement`, jamais de `acte_cantonal.dep` :
-- un acte peut en toucher deux (décret n° 96-709, Meuse → Meurthe-et-Moselle).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p81_borne;
CREATE TABLE p81_borne AS
SELECT d.dep,
       count(*)                                          AS actes,
       min(e.date_effet) FILTER (
           WHERE e.date_effet >= :'jalon_fin'::date
             AND e.date_effet <  :'fin_serie'::date)      AS borne,
       count(*) FILTER (
           WHERE e.date_effet >= :'jalon_fin'::date
             AND e.date_effet <  :'fin_serie'::date
             AND NOT EXISTS (SELECT 1 FROM acte_composition c
                              WHERE c.date_acte = a.date_signature
                                AND c.dep = d.dep))       AS actes_non_depouilles,
       -- un acte prenant effet DANS l'année du jalon défait la composition que
       -- `59` a posée, à l'intérieur même de sa fenêtre : le point de départ du
       -- report n'est alors pas sûr. Le § 7 refuse ces départements.
       count(*) FILTER (
           WHERE e.date_effet >= :'jalon_debut'::date
             AND e.date_effet <  :'jalon_fin'::date)      AS actes_dans_le_jalon,
       -- le DERNIER acte : c'est le plancher de `79`. Rangé ici pour que la
       -- recette 11 g mesure la jonction sans dépendre des tables de `79`.
       max(e.date_effet) FILTER (
           WHERE e.date_effet < :'fin_serie'::date)       AS plancher_de_79
FROM   acte_departement d
JOIN   acte_cantonal a  ON a.legifrance_id = d.legifrance_id
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  length(d.dep) = 2
  -- un acte lu et déclaré sans effet sur l'appartenance ne borne rien
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                    WHERE x.legifrance_id = a.legifrance_id)
GROUP  BY d.dep;

-- Un département SANS acte postérieur au jalon a un report ouvert jusqu'à la
-- fin de série. Ce n'est pas une absence de borne, c'est la borne maximale.
UPDATE p81_borne SET borne = :'fin_serie'::date WHERE borne IS NULL;
ALTER TABLE p81_borne ADD PRIMARY KEY (dep);

-- l'acte qui FIXE la borne, nommé : une ligne de qualité doit pouvoir dire
-- « ce report tient parce que cet acte-là est le premier »
ALTER TABLE p81_borne ADD COLUMN premier_acte text;
UPDATE p81_borne p
   SET premier_acte = (
       SELECT min(d.legifrance_id)
       FROM   acte_departement d
       JOIN   acte_effet e ON e.legifrance_id = d.legifrance_id
       WHERE  d.dep = p.dep AND e.date_effet = p.borne);

\echo ''
\echo '-- 3. la borne haute'
SELECT count(*)                                            AS departements,
       round(avg((borne - :'jalon_fin'::date) / 365.25), 1) AS profondeur_moyenne,
       min(borne)                                          AS la_plus_basse,
       max(borne)                                          AS la_plus_haute,
       count(*) FILTER (WHERE premier_acte IS NULL)        AS sans_acte_nomme,
       count(*) FILTER (WHERE actes_dans_le_jalon > 0)     AS acte_dans_le_jalon
FROM   p81_borne;

-- ---------------------------------------------------------------------------
-- 4. LA BORNE DES ACTES INCONNUS — inverse de celle de `79`
--
-- On prend la date d'EFFET la plus BASSE, faute de quoi on affirmerait que
-- rien n'a bougé après qu'un acte inconnu a pu agir. `coalesce` sur la
-- signature quand l'effet manque : plus tôt, donc plus prudent pour une borne
-- de ce sens.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p81_inconnu;
CREATE TABLE p81_inconnu AS
SELECT min(coalesce(e.date_effet, a.date_signature)) FILTER (
         WHERE coalesce(e.date_effet, a.date_signature) >= :'jalon_fin'::date) AS borne,
       count(*)                                                               AS actes_anonymes
FROM   acte_cantonal a
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id);

\echo ''
\echo '-- 4. la borne des actes sans département'
SELECT borne, actes_anonymes,
       CASE WHEN borne IS NULL THEN 'aucun — le report monte jusqu''au premier acte'
            ELSE 'au-DESSUS de cette date, sous_acte_inconnu = true' END AS effet
FROM   p81_inconnu;

\echo ''
\echo '   Attendu depuis le 29 août 2026 : zéro acte, borne NULL. Le mécanisme'
\echo '   est inerte et conservé — un acte non attribué peut reparaître, et'
\echo '   alors rien d''autre ne le signalerait.'

-- ---------------------------------------------------------------------------
-- 5. LE TAUX MESURÉ PAR DÉPARTEMENT — ce que `p79_qualite` n'a pas
--
-- Reprise du § 6 quinquies de `80`, recalculée ici pour que le fichier ne
-- dépende pas de tables jetables. Elle nourrit la colonne de qualité : chaque
-- ligne posée porte le taux d'accord 1968/1999 des atomes de son département
-- QUE LE REGISTRE DIT INTACTS. C'est la mesure directe de ce que le report
-- affirme, département par département.
--
-- Le biais est connu et de sens connu : un décret nomme les cantons qu'il crée
-- ou modifie, jamais ceux qu'il vide, donc des atomes réellement déplacés sont
-- comptés « jamais nommés » et font BAISSER le taux. Un taux élevé est donc
-- acquis malgré le biais ; un taux bas peut n'être que lui.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p81_nomme;
CREATE TABLE p81_nomme AS
SELECT DISTINCT c.atome AS atom_id
FROM   acte_composition c
WHERE  c.atome IS NOT NULL
  AND  c.date_acte >= :'jalon_debut'::date
  AND  c.date_acte <  :'fin_serie'::date;

ALTER TABLE p81_nomme ADD PRIMARY KEY (atom_id);

DROP TABLE IF EXISTS p81_accord;
CREATE TABLE p81_accord AS
WITH j AS (
    SELECT m.atom_id,
           u.dep::text AS dep,
           m.unit_id   AS unit_1968,
           (SELECT n.unit_id FROM membership n
             WHERE n.atom_id = m.atom_id
               AND n.niveau  = 'canton'
               AND n.periode @> :'date_1999'::date
             LIMIT 1)  AS unit_1999
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
    WHERE  m.niveau = 'canton'
      AND  m.periode @> :'jalon_temoin'::date)
SELECT j.dep,
       count(*) FILTER (WHERE n.atom_id IS NULL)                  AS atomes_jamais_nommes,
       round(100.0 * count(*) FILTER (WHERE n.atom_id IS NULL
                                        AND j.unit_1999 = j.unit_1968)
             / nullif(count(*) FILTER (WHERE n.atom_id IS NULL
                                        AND j.unit_1999 IS NOT NULL), 0), 1)
                                                                  AS pct_jamais_nommes
FROM   j LEFT JOIN p81_nomme n ON n.atom_id = j.atom_id
GROUP  BY j.dep;

ALTER TABLE p81_accord ADD PRIMARY KEY (dep);

\echo ''
\echo '-- 5. le taux mesuré, répartition'
SELECT CASE WHEN pct_jamais_nommes IS NULL THEN 'non mesurable'
            WHEN pct_jamais_nommes >= 95   THEN '95 % et plus'
            WHEN pct_jamais_nommes >= 90   THEN '90 à 95 %'
            WHEN pct_jamais_nommes >= 85   THEN '85 à 90 %'
            ELSE                                'moins de 85 % — À REGARDER'
       END                                  AS tranche,
       count(*)                             AS departements,
       string_agg(dep, ' ' ORDER BY dep) FILTER (
           WHERE pct_jamais_nommes < 85)    AS lesquels
FROM   p81_accord GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 6. CE QUI SERA POSÉ — la fenêtre doit être ENTIÈREMENT libre
--
-- On ne pose pas dans les interstices : découper autour d'un occupant
-- fabriquerait des périodes que personne ne saurait relire. Au diagnostic `80`
-- les 32 842 fenêtres étaient libres — `79` s'arrête au dernier acte, `81`
-- monte au premier, les deux ne se rencontrent jamais à l'intérieur.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p81_cible;
CREATE TABLE p81_cible AS
SELECT m.atom_id,
       m.unit_id,
       u.dep::text                         AS dep,
       :'jalon_fin'::date                  AS depuis,
       b.borne                             AS jusqu_a,
       b.premier_acte,
       b.actes_non_depouilles,
       b.actes_dans_le_jalon,
       (m.atom_id LIKE '%#%')              AS fraction,
       (n.atom_id IS NOT NULL)             AS atome_nomme,
       a.pct_jamais_nommes,
       a.atomes_jamais_nommes
FROM   membership m
JOIN   unit u       ON u.unit_id = m.unit_id AND u.niveau = 'canton'
JOIN   p81_borne b  ON b.dep = u.dep::text
LEFT   JOIN p81_accord a ON a.dep = u.dep::text
LEFT   JOIN p81_nomme  n ON n.atom_id = m.atom_id
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'jalon_temoin'::date;

CREATE INDEX p81_cible_idx ON p81_cible (atom_id);

DROP TABLE IF EXISTS p81_libre;
CREATE TABLE p81_libre AS
SELECT c.* FROM p81_cible c
WHERE  c.depuis < c.jusqu_a
  -- un acte a pris effet dans l'année même du jalon : le point de départ
  -- n'est pas sûr, on ne pose pas. Zéro cas au 30 août 2026.
  AND  c.actes_dans_le_jalon = 0
  AND  NOT EXISTS (
       SELECT 1 FROM membership m
       WHERE  m.atom_id = c.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(c.depuis, c.jusqu_a, '[)'));

\echo ''
\echo '-- 6. le tamis'
SELECT (SELECT count(*) FROM p81_cible) AS atomes_de_1968,
       (SELECT count(*) FROM p81_libre) AS fenetre_libre,
       (SELECT count(*) FROM p81_cible) - (SELECT count(*) FROM p81_libre)
                                        AS ecartes;

\echo ''
\echo '   qui occupe déjà ces fenêtres — ce n''est pas une perte'
SELECT coalesce(u.nom, m.unit_id) AS occupant, count(DISTINCT c.atom_id) AS atomes
FROM   p81_cible c
JOIN   membership m ON m.atom_id = c.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(c.depuis, c.jusqu_a, '[)')
LEFT   JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
GROUP  BY 1 ORDER BY atomes DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- 7. LA COUPURE À LA BORNE DES ACTES INCONNUS
--
-- Une ligne devient deux quand la borne tombe DANS la fenêtre. La moitié
-- BASSE — la plus proche du jalon — ne dépend d'aucun acte inconnu ; la moitié
-- haute est marquée et se retire seule. C'est l'inverse exact de `79` § 6, et
-- pour la même raison exactement.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p81_pose;
CREATE TABLE p81_pose AS
-- moitié basse (ou période entière quand la borne ne mord pas)
SELECT l.atom_id, l.unit_id, l.dep,
       l.depuis                                                        AS valid_from,
       least(l.jusqu_a, coalesce((SELECT borne FROM p81_inconnu),
                                 l.jusqu_a))                           AS valid_to,
       false                                                           AS sous_acte_inconnu,
       l.premier_acte, l.actes_non_depouilles, l.fraction,
       l.atome_nomme, l.pct_jamais_nommes, l.atomes_jamais_nommes
FROM   p81_libre l
UNION ALL
-- moitié haute, seulement si la borne tombe DANS la fenêtre
SELECT l.atom_id, l.unit_id, l.dep,
       (SELECT borne FROM p81_inconnu)   AS valid_from,
       l.jusqu_a                         AS valid_to,
       true                              AS sous_acte_inconnu,
       l.premier_acte, l.actes_non_depouilles, l.fraction,
       l.atome_nomme, l.pct_jamais_nommes, l.atomes_jamais_nommes
FROM   p81_libre l
WHERE  (SELECT borne FROM p81_inconnu) IS NOT NULL
  AND  (SELECT borne FROM p81_inconnu) > l.depuis
  AND  (SELECT borne FROM p81_inconnu) < l.jusqu_a;

DELETE FROM p81_pose WHERE valid_from >= valid_to;

\echo ''
\echo '-- 7. ce qui va être posé, avant écriture'
SELECT sous_acte_inconnu, count(*) AS lignes,
       count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS du, max(valid_to) AS au
FROM   p81_pose GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 8. GARDE-FOUS — avant d'écrire, pas après
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p81_pose GROUP BY atom_id, valid_from HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes à la même date (p. ex. %).', n, ex;
    END IF;

    SELECT count(*), min(atom_id) INTO n, ex FROM p81_pose a
     WHERE EXISTS (SELECT 1 FROM p81_pose b
                    WHERE b.atom_id = a.atom_id
                      AND (b.valid_from, b.valid_to) <> (a.valid_from, a.valid_to)
                      AND daterange(b.valid_from, b.valid_to, '[)')
                       && daterange(a.valid_from, a.valid_to, '[)'));
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) qui se chevauchent (p. ex. %).', n, ex;
    END IF;

    -- ne jamais mordre sur le jalon : `59` tient [1968-01-01, 1969-01-01)
    SELECT count(*) INTO n FROM p81_pose WHERE valid_from < '1969-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) empiètent sur l''année du jalon.', n;
    END IF;

    SELECT count(*) INTO n FROM p81_pose WHERE valid_to > '1999-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) débordent la fin de série.', n;
    END IF;

    SELECT count(*), min(p.atom_id) INTO n, ex FROM p81_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u
                        WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une unité absente (p. ex. %).', n, ex;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 9. L'ÉCRITURE
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p81_pose
    RETURNING membership_id, atom_id, valid_from
)
INSERT INTO p81_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 9. posé'
SELECT count(*) AS rattachements FROM p81_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 10. LA QUALITÉ, LIGNE À LIGNE
--
-- Ce n'est pas de la documentation, c'est une colonne : une lecture qui ne
-- joint pas cette table prend une inférence pour un relevé.
--
-- `pct_jamais_nommes` est la nouveauté, et elle manque à `p79_qualite` :
-- **le taux mesuré du département où la ligne est posée**. Une ligne du 95
-- (78,1 %) et une ligne du 03 (98,5 %) ne valent pas la même chose.
--
-- ET SON DÉNOMINATEUR VOYAGE AVEC LUI — `atomes_jamais_nommes`. Le banc du
-- 30 août l'a imposé : un département où trois atomes seulement sont
-- jamais-nommés y affichait un taux de 66,7 %, aussi précis d'apparence que
-- les 94,9 % nationaux et sans aucune valeur. `80` § 6 sexies s'en gardait par
-- un seuil de 20 ; ici on ne seuille pas, on JOINT le compte, parce qu'un
-- seuil décide à la place du lecteur et qu'un dénominateur le laisse décider.
-- ***Un taux sans son dénominateur est une opinion présentée comme une
-- mesure*** — c'est la quatrième fois que ce dépôt le paie (villes à découper
-- 270/369/119, vote de `75` à 333 %, § 6 de `80`).
-- ---------------------------------------------------------------------------
CREATE TABLE p81_qualite AS
SELECT m.membership_id,
       p.atom_id,
       p.unit_id,
       p.dep,
       p.sous_acte_inconnu,
       p.fraction,
       p.atome_nomme,
       p.pct_jamais_nommes,
       p.atomes_jamais_nommes,
       p.premier_acte,
       (SELECT a.date_signature FROM acte_cantonal a
         WHERE a.legifrance_id = p.premier_acte)          AS premier_acte_date,
       p.actes_non_depouilles,
       round((p.valid_to - p.valid_from) / 365.25, 2)     AS annees_reportees
FROM   p81_pose p
JOIN   membership m ON m.atom_id    = p.atom_id
                   AND m.valid_from = p.valid_from
                   AND m.niveau     = 'canton';

ALTER TABLE p81_qualite ADD PRIMARY KEY (membership_id);
CREATE INDEX p81_qualite_dep_idx ON p81_qualite (dep, sous_acte_inconnu);
CREATE INDEX p81_qualite_pct_idx ON p81_qualite (pct_jamais_nommes);

\echo ''
\echo '-- 10. la qualité du report'
SELECT sous_acte_inconnu, fraction, count(*) AS lignes,
       round(sum(annees_reportees))    AS atome_annees,
       round(avg(annees_reportees), 1) AS annees_moyennes
FROM   p81_qualite GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '-- 10 bis. la couverture par tranche de fiabilité mesurée'
SELECT CASE WHEN pct_jamais_nommes IS NULL     THEN 'non mesurable'
            WHEN atomes_jamais_nommes < 20     THEN 'trop peu d''atomes pour un taux'
            WHEN pct_jamais_nommes >= 95       THEN '95 % et plus'
            WHEN pct_jamais_nommes >= 90       THEN '90 à 95 %'
            WHEN pct_jamais_nommes >= 85       THEN '85 à 90 %'
            ELSE                                    'moins de 85 % — À REGARDER'
       END                              AS fiabilite,
       count(*)                         AS lignes,
       round(sum(annees_reportees))     AS atome_annees
FROM   p81_qualite GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   Pour ne garder que le report le mieux étayé :'
\echo '     ... JOIN p81_qualite q USING (membership_id)'
\echo '      WHERE q.pct_jamais_nommes >= 90 AND q.atomes_jamais_nommes >= 20'
\echo ''
\echo '   Le second terme n''est pas décoratif : sans lui on retient des'
\echo '   départements dont le taux se calcule sur trois communes.'

\echo ''
\echo '   départements dont le premier acte n''a jamais été dépouillé'
\echo '   (la borne est juste, la composition de l''acte est inconnue — ce'
\echo '    n''est pas un défaut du report, c''est une réserve à connaître)'
SELECT count(DISTINCT dep) AS departements, count(*) AS lignes
FROM   p81_qualite WHERE actes_non_depouilles > 0;

-- ---------------------------------------------------------------------------
-- 11. RECETTES — elles doivent toutes valoir zéro, ou le nombre annoncé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 11 a. un atome à deux cantons à la même date (doit valoir 0)'
SELECT count(*) AS atomes_a_deux_cantons FROM (
    SELECT m.atom_id, m.valid_from
    FROM   membership m WHERE m.niveau = 'canton'
    GROUP  BY 1, 2 HAVING count(DISTINCT m.unit_id) > 1) q;

\echo ''
\echo '-- 11 b. les trois couches existantes sont-elles intactes ?'
\echo '   (les écarts doivent valoir 0 — témoins pris avant l''écriture, § 2)'
SELECT t.jalon_1968                                        AS jalon_1968_avant,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1968-06-01'::date) - t.jalon_1968 AS ecart_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1999-06-01'::date) - t.couche_1999 AS ecart_1999,
       coalesce((SELECT count(*) FROM p79_trace
                  WHERE quoi = 'membership'), 0) - t.lignes_de_79 AS ecart_79
FROM   p81_temoin t;

\echo ''
\echo '-- 11 c. aucune ligne ne mord sur le jalon ni ne le déborde (doit valoir 0)'
SELECT count(*) AS hors_bornes
FROM   p81_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
WHERE  m.valid_from < :'jalon_fin'::date
   OR  m.valid_to   > :'fin_serie'::date;

\echo ''
\echo '-- 11 d. aucune ligne au-delà de la borne de son département (doit valoir 0)'
SELECT count(*) AS au_dela_de_la_borne
FROM   p81_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
JOIN   p81_borne  b ON b.dep = q.dep
WHERE  m.valid_to > b.borne;

\echo ''
\echo '-- 11 e. toute ligne posée a-t-elle sa qualité ? (doit valoir 0)'
SELECT count(*) AS sans_qualite
FROM   p81_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p81_qualite q
                    WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '-- 11 f. ce que snapshot répond désormais'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements
FROM   (VALUES ('1969-06-01'), ('1970-06-01'), ('1972-06-01'), ('1974-06-01'),
               ('1976-06-01'), ('1980-06-01'), ('1985-06-01'),
               ('1990-06-01')) v(d);

\echo ''
\echo '   1969 doit passer de ZÉRO à plusieurs dizaines de milliers.'
\echo ''
\echo '   1974 DOIT BOUGER, ET C''EST NORMAL. Cette ligne portait jusqu''au'
\echo '   6 septembre 2026 l''attendu inverse — « 1974 et au-delà ne doit PAS'
\echo '   bouger : la borne de la plupart des départements est la salve du'
\echo '   23 septembre 1973 ». Le premier passage réel l''a démenti : le § 3'
\echo '   rend une profondeur MOYENNE de 6,3 ans depuis 1969, donc 1975, et une'
\echo '   borne la plus haute au 1985-03-10. « La plupart » était une supposition'
\echo '   écrite avant que la borne soit mesurée.'
\echo ''
\echo '   CE QUI PROTÈGE VRAIMENT N''EST PAS CETTE LIGNE, ce sont les § 6'
\echo '   (aucune fenêtre même partiellement occupée), 11 a, 11 b et 11 d. Un'
\echo '   report qui déborderait sur une couche existante y serait vu ; un'
\echo '   report qui couvre plus d''années que prévu ne se voit qu''ici, et ce'
\echo '   n''est pas un défaut.'
\echo ''
\echo '   *Une recette qui annonce un nombre supposé apprend à ignorer ses'
\echo '    propres alarmes.* Les dates ci-dessus ne servent qu''à LIRE la'
\echo '   couverture ; le refus est ailleurs.'

\echo ''
\echo '-- 11 g. la jonction avec `79` — départements couverts de 1969 à 1999'
\echo '   (la borne de `81` rejoint ou dépasse le plancher de `79` : entre les'
\echo '    deux, plus aucun intervalle sans composition)'
SELECT CASE WHEN b.plancher_de_79 IS NULL
              OR b.borne >= b.plancher_de_79
            THEN 'couvert de bout en bout'
            ELSE 'intervalle noir résiduel' END          AS situation,
       count(*)                                          AS departements,
       round(sum(CASE WHEN b.plancher_de_79 > b.borne
                      THEN (b.plancher_de_79 - b.borne) / 365.25
                      ELSE 0 END))                       AS dep_annees_noires
FROM   p81_borne b
WHERE  EXISTS (SELECT 1 FROM p81_qualite q WHERE q.dep = b.dep)
GROUP  BY 1 ORDER BY 2 DESC;

ANALYZE membership; ANALYZE p81_qualite;

\echo ''
\echo '============================================================'
\echo ' Report posé. Pour retirer la part dépendant d''un acte inconnu :'
\echo ''
\echo '   DELETE FROM histgis.membership m USING histgis.p81_qualite q'
\echo '    WHERE q.membership_id = m.membership_id AND q.sous_acte_inconnu;'
\echo ''
\echo ' Pour tout défaire : rejouer ce fichier, ou lancer le DELETE du § 2.'
\echo '============================================================'

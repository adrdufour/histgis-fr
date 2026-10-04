-- ============================================================================
-- histgis — 79_report_1999_arriere.sql : la composition de 1999 remonte le temps
--
--   psql -d histgis -1 -f sql/79_report_1999_arriere.sql
--
-- ÉCRIT DANS `membership`. Tout est tracé dans `p79_trace` et le § 2 défait le
-- passage précédent : le fichier est rejouable seul.
--
-- CE QU'IL POSE, ET SUR QUELLE AUTORITÉ
-- =====================================
-- Pour chaque département, le registre des actes (`72`) dit quel est le
-- DERNIER acte antérieur à 1999. Si le registre est complet, rien n'a bougé
-- entre cet acte et 1999, et la composition du COG de 1999 — exacte, non
-- océrisée, posée par `24` — vaut sur tout l'intervalle.
--
-- Ce n'est pas une convention comme celle de `75`, c'est une INFÉRENCE : elle
-- ne suppose rien sur une date, elle suppose une ABSENCE. Et une absence se
-- vérifie, ce qui est précisément l'objet de `72`.
--
-- Ce que `78` a mesuré avant d'autoriser ce fichier :
--   * 96 départements pourvus d'un plancher, profondeur médiane 10,3 ans ;
--   * 36 557 atomes de 1999 sur 37 266 à fenêtre entièrement libre ;
--   * borne haute du taux d'erreur, sur la population du report : **2,8 %**
--     (105 cantons résolus, 3 contredits, 25 communes).
--
-- **2,8 % n'est pas une preuve.** L'échantillon est de 108 cantons jugeables,
-- il hérite du cadre du vote de `75`/`76`, et il ne se compare pas terme à
-- terme aux 89,8 % de 1954 → 1968, qui portent sur des paires de communes dans
-- toute la France. C'est ce qui autorise à poser AVEC une colonne de qualité,
-- pas à déclarer le report acquis.
--
-- LE PLANCHER EST LA DATE D'EFFET, JAMAIS LA SIGNATURE
-- ====================================================
-- L'effet est postérieur à la signature de 183 jours en moyenne, sur 96
-- départements sur 96. Sur [signature, effet) c'est encore l'ANCIENNE
-- composition qui vaut — celle que le décret défait. Y reporter l'état de 1999
-- serait faux par construction. *Une borne plus large n'est pas plus prudente.*
--
-- LE PLAFOND, ET POURQUOI LA PÉRIODE EST COUPÉE EN DEUX
-- =====================================================
-- Les actes encore SANS DÉPARTEMENT (`72` § 3 bis) ont pu toucher n'importe
-- lequel : au-dessous de la date du plus tardif, aucun report n'est sûr. Plutôt
-- que de s'y arrêter ou de l'ignorer, le fichier **coupe la période au
-- plafond** :
--
--   [plafond, 1999)   `sous_plafond = false`  aucun acte inconnu au-dessus
--   [plancher, plafond) `sous_plafond = true`  un acte inconnu a pu y tomber
--
-- Les deux moitiés sont posées, la seconde est marquée, et elle se retire
-- seule :
--
--   DELETE FROM histgis.membership m USING histgis.p79_qualite q
--    WHERE q.membership_id = m.membership_id AND q.sous_plafond;
--
-- C'est le motif de `p76_qualite` et `c68_qualite` : *on signale, on ne
-- supprime pas* — mais on rend le retrait possible en une ligne.
--
-- CE QUI N'EST PAS POSÉ, ET C'EST VOULU
-- =====================================
--   * les atomes dont la fenêtre est même partiellement occupée. `59`, `74`,
--     `75`, `76` et `77` sont mieux renseignés que le report ; là où ils ont
--     écrit, ils gardent la main. Le § 6 les compte.
--   * les départements sans aucun acte au registre — il n'y a pas de plancher,
--     donc pas de borne basse, donc rien à poser.
--
-- CE QUE PERSONNE NE VERRA
-- ========================
-- Un transfert isolé de commune qui n'a pas laissé de décret au registre. Le
-- plancher l'ignore et le report passe par-dessus en silence. Le dépôt en
-- compte 274 non datés, et le seul ordre de grandeur mesuré vient du report
-- 1940 → 1954 : 0,29 % des communes en quatorze ans (`70`, `71`).
--
-- Prérequis : `24` (couche 1999), `72` (registre + `acte_departement`),
--             `75` (`acte_effet`). À jouer APRÈS `77`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set fin_serie '1999-01-01'
\set date_1999 '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' REPORT DE LA COMPOSITION DE 1999 VERS L''ARRIÈRE'
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
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> '1999-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1999 est absente — jouer sql/24_canton_moderne.sql.';
    END IF;
    -- Ajouté le 22 septembre 2026 : le § 5 écarte les pseudo-cantons de `25`
    -- par sa trace. Sans elle, l'exclusion serait muette et la convention
    -- repasserait en report.
    IF to_regclass('histgis.pseudo_canton_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/25_pseudo_canton.sql (pseudo_canton_trace).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. DÉFAIRE LE PASSAGE PRÉCÉDENT
--
-- `p79_trace` ne porte que des `membership_id` posés par ce fichier. Rien
-- d'autre n'est touché, donc rien d'autre n'est à défaire.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p79_trace (
    quoi text NOT NULL,          -- 'membership'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p79_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p79_trace;
DROP TABLE IF EXISTS p79_qualite;

-- Le témoin de la recette 10 c, pris AVANT toute écriture. Le premier jet
-- comparait à 37 266, nombre recopié de `78` § 4 — où il désigne les atomes
-- des départements POURVUS D'UN PLANCHER, pas la couche de 1999. La recette
-- criait donc au faux, sur 20 atomes qui n'étaient jamais dans le périmètre.
-- *Une recette qui compare à un nombre venu d'ailleurs mesure la mémoire de
-- celui qui l'a écrite, pas la base.*
DROP TABLE IF EXISTS p79_temoin;
CREATE TABLE p79_temoin AS
SELECT (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1999-06-01'::date) AS couche_1999,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1968-06-01'::date) AS jalon_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'canton')    AS total_canton;

-- ---------------------------------------------------------------------------
-- 3. LE PLANCHER PAR DÉPARTEMENT — la date d'effet du dernier acte
--
-- Le département vient de `acte_departement`, jamais de `acte_cantonal.dep` :
-- un acte peut en toucher deux (décret n° 96-709, Meuse → Meurthe-et-Moselle).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p79_plancher;
CREATE TABLE p79_plancher AS
SELECT d.dep,
       count(*)                                          AS actes,
       max(e.date_effet) FILTER (
           WHERE e.date_effet < :'fin_serie'::date)       AS plancher,
       count(*) FILTER (
           WHERE NOT EXISTS (SELECT 1 FROM acte_composition c
                              WHERE c.date_acte = a.date_signature
                                AND c.dep = d.dep))       AS actes_non_depouilles
FROM   acte_departement d
JOIN   acte_cantonal a  ON a.legifrance_id = d.legifrance_id
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  length(d.dep) = 2
  -- un acte lu et déclaré sans effet sur l'appartenance ne borne rien
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                    WHERE x.legifrance_id = a.legifrance_id)
GROUP  BY d.dep;

DELETE FROM p79_plancher WHERE plancher IS NULL;
ALTER TABLE p79_plancher ADD PRIMARY KEY (dep);

-- l'acte qui FIXE le plancher, nommé : une ligne de qualité doit pouvoir dire
-- « ce report tient parce que cet acte-là est le dernier »
ALTER TABLE p79_plancher ADD COLUMN dernier_acte text;
UPDATE p79_plancher p
   SET dernier_acte = (
       SELECT min(d.legifrance_id)
       FROM   acte_departement d
       JOIN   acte_effet e ON e.legifrance_id = d.legifrance_id
       WHERE  d.dep = p.dep AND e.date_effet = p.plancher);

\echo ''
\echo '-- 3. le plancher'
SELECT count(*)                                   AS departements,
       round(avg((:'fin_serie'::date - plancher) / 365.25), 1) AS profondeur_moyenne,
       min(plancher)                              AS le_plus_bas,
       max(plancher)                              AS le_plus_haut,
       count(*) FILTER (WHERE dernier_acte IS NULL) AS sans_acte_nomme
FROM   p79_plancher;

-- ---------------------------------------------------------------------------
-- 4. LE PLAFOND — ce que les actes encore anonymes interdisent
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p79_plafond;
CREATE TABLE p79_plafond AS
SELECT max(a.date_signature) AS plafond,
       count(*)              AS actes_anonymes
FROM   acte_cantonal a
WHERE  a.date_signature < :'fin_serie'::date
  AND  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id);

\echo ''
\echo '-- 4. le plafond des actes anonymes'
SELECT plafond, actes_anonymes,
       CASE WHEN plafond IS NULL THEN 'aucun — le report descend jusqu''au plancher'
            ELSE 'au-dessous de cette date, sous_plafond = true' END AS effet
FROM   p79_plafond;

-- ---------------------------------------------------------------------------
-- 5. CE QUI SERA POSÉ — la fenêtre doit être ENTIÈREMENT libre
--
-- On ne pose pas dans les interstices. Un atome dont la fenêtre est même
-- partiellement occupée est laissé tel quel : ce qui l'occupe (`59`, `74`,
-- `75`, `76`, `77`) est mieux renseigné que le report, et découper autour
-- fabriquerait des périodes que personne ne saurait relire.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p79_cible;
CREATE TABLE p79_cible AS
SELECT m.atom_id,
       m.unit_id,
       u.dep,
       p.plancher                          AS depuis,
       :'fin_serie'::date                  AS jusqu_a,
       p.dernier_acte,
       p.actes_non_depouilles,
       (m.atom_id LIKE '%#%')              AS fraction
FROM   membership m
JOIN   unit u          ON u.unit_id = m.unit_id AND u.niveau = 'canton'
JOIN   p79_plancher p  ON p.dep = u.dep::text
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1999'::date
  -- PAS les pseudo-cantons de `25` — décidé le 22 septembre 2026.
  --
  -- « La ville est un canton » n'est pas une composition attestée : c'est
  -- une convention, prise parce que la trame communale ne sait pas couper
  -- Marseille et Lyon. `25` la pose sur 1999-2012 et affirme en recette que
  -- « le trou 1941-1998 reste vide ». Ce fichier, qui ne connaissait pas les
  -- pseudo-cantons, la reportait en arrière comme n'importe quelle
  -- composition : Lyon depuis le 1985-03-10, Marseille depuis le 1992-03-22,
  -- 25 lignes, marquées dans `p79_qualite` comme un report ordinaire.
  -- Invisible sur `histgis`, où `25` n'avait jamais tourné ; vu à la
  -- première chaîne complète, par +9 rattachements dans le Rhône en 1990.
  --
  -- *Un report transporte ce qu'il trouve, et ne sait pas distinguer une
  -- composition lue d'une convention posée. C'est à la sélection de le dire.*
  AND  NOT EXISTS (SELECT 1 FROM pseudo_canton_trace t
                    WHERE t.quoi = 'unit' AND t.cle = m.unit_id);

CREATE INDEX p79_cible_idx ON p79_cible (atom_id);

DROP TABLE IF EXISTS p79_libre;
CREATE TABLE p79_libre AS
SELECT c.* FROM p79_cible c
WHERE  c.depuis < c.jusqu_a
  AND  NOT EXISTS (
       SELECT 1 FROM membership m
       WHERE  m.atom_id = c.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(c.depuis, c.jusqu_a, '[)'));

\echo ''
\echo '-- 5. le tamis'
SELECT (SELECT count(*) FROM p79_cible) AS atomes_de_1999,
       (SELECT count(*) FROM p79_libre) AS fenetre_libre,
       (SELECT count(*) FROM p79_cible) - (SELECT count(*) FROM p79_libre)
                                        AS fenetre_occupee;

\echo ''
\echo '   qui occupe déjà ces fenêtres — ce n''est pas une perte'
SELECT coalesce(u.nom, m.unit_id) AS occupant, count(DISTINCT c.atom_id) AS atomes
FROM   p79_cible c
JOIN   membership m ON m.atom_id = c.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(c.depuis, c.jusqu_a, '[)')
LEFT   JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
GROUP  BY 1 ORDER BY atomes DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- 6. LA COUPURE AU PLAFOND
--
-- Une ligne devient deux quand le plancher passe sous le plafond. La moitié
-- haute ne dépend d'aucun acte inconnu ; la moitié basse est marquée et se
-- retire seule.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p79_pose;
CREATE TABLE p79_pose AS
WITH pl AS (SELECT plafond FROM p79_plafond)
-- moitié haute (ou période entière quand le plafond ne mord pas)
SELECT l.atom_id, l.unit_id, l.dep,
       greatest(l.depuis, coalesce((SELECT plafond FROM pl), l.depuis)) AS valid_from,
       l.jusqu_a                                                       AS valid_to,
       false                                                           AS sous_plafond,
       l.dernier_acte, l.actes_non_depouilles, l.fraction
FROM   p79_libre l
UNION ALL
-- moitié basse, seulement si le plafond tombe DANS la fenêtre
SELECT l.atom_id, l.unit_id, l.dep,
       l.depuis                          AS valid_from,
       (SELECT plafond FROM pl)          AS valid_to,
       true                              AS sous_plafond,
       l.dernier_acte, l.actes_non_depouilles, l.fraction
FROM   p79_libre l
WHERE  (SELECT plafond FROM pl) IS NOT NULL
  AND  (SELECT plafond FROM pl) > l.depuis
  AND  (SELECT plafond FROM pl) < l.jusqu_a;

DELETE FROM p79_pose WHERE valid_from >= valid_to;

\echo ''
\echo '-- 6. ce qui va être posé, avant écriture'
SELECT sous_plafond, count(*) AS lignes,
       count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS du, max(valid_to) AS au
FROM   p79_pose GROUP BY sous_plafond ORDER BY sous_plafond;

-- ---------------------------------------------------------------------------
-- 7. GARDE-FOUS — avant d'écrire, pas après
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p79_pose GROUP BY atom_id, valid_from HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes à la même date (p. ex. %).', n, ex;
    END IF;

    SELECT count(*), min(atom_id) INTO n, ex FROM p79_pose a
     WHERE EXISTS (SELECT 1 FROM p79_pose b
                    WHERE b.atom_id = a.atom_id
                      AND (b.valid_from, b.valid_to) <> (a.valid_from, a.valid_to)
                      AND daterange(b.valid_from, b.valid_to, '[)')
                       && daterange(a.valid_from, a.valid_to, '[)'));
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) qui se chevauchent (p. ex. %).', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p79_pose WHERE valid_to > '1999-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) débordent la fin de série.', n;
    END IF;

    SELECT count(*), min(p.atom_id) INTO n, ex FROM p79_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u
                        WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une unité absente (p. ex. %).', n, ex;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 8. L'ÉCRITURE
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p79_pose
    RETURNING membership_id, atom_id, valid_from
)
INSERT INTO p79_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 8. posé'
SELECT count(*) AS rattachements FROM p79_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 9. LA QUALITÉ, LIGNE À LIGNE
--
-- Ce n'est pas de la documentation, c'est une colonne : une lecture qui ne
-- joint pas cette table prend une inférence pour un relevé.
-- ---------------------------------------------------------------------------
CREATE TABLE p79_qualite AS
SELECT m.membership_id,
       p.atom_id,
       p.unit_id,
       p.dep,
       p.sous_plafond,
       p.fraction,
       p.dernier_acte,
       (SELECT a.date_signature FROM acte_cantonal a
         WHERE a.legifrance_id = p.dernier_acte)          AS dernier_acte_date,
       p.actes_non_depouilles,
       round((p.valid_to - p.valid_from) / 365.25, 2)     AS annees_reportees
FROM   p79_pose p
JOIN   membership m ON m.atom_id    = p.atom_id
                   AND m.valid_from = p.valid_from
                   AND m.niveau     = 'canton';

ALTER TABLE p79_qualite ADD PRIMARY KEY (membership_id);
CREATE INDEX p79_qualite_dep_idx ON p79_qualite (dep, sous_plafond);

\echo ''
\echo '-- 9. la qualité du report'
SELECT sous_plafond, fraction, count(*) AS lignes,
       round(sum(annees_reportees)) AS atome_annees,
       round(avg(annees_reportees), 1) AS annees_moyennes
FROM   p79_qualite GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '   départements dont le dernier acte n''a jamais été dépouillé'
\echo '   (le plancher est juste, la composition de l''acte est inconnue —'
\echo '    ce n''est pas un défaut du report, c''est une réserve à connaître)'
SELECT count(DISTINCT dep) AS departements,
       count(*)            AS lignes
FROM   p79_qualite WHERE actes_non_depouilles > 0;

-- ---------------------------------------------------------------------------
-- 10. RECETTES — elles doivent toutes valoir zéro, ou le nombre annoncé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 10 a. un atome à deux cantons à la même date (doit valoir 0)'
SELECT count(*) AS atomes_a_deux_cantons FROM (
    SELECT m.atom_id, m.valid_from
    FROM   membership m WHERE m.niveau = 'canton'
    GROUP  BY 1, 2 HAVING count(DISTINCT m.unit_id) > 1) q;

\echo ''
\echo '-- 10 b/c. les deux couches existantes sont-elles intactes ?'
\echo '   (les écarts doivent valoir 0 — témoin pris avant l''écriture, § 2)'
SELECT t.jalon_1968                                       AS jalon_1968_avant,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1968-06-01'::date)               AS jalon_1968_apres,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1968-06-01'::date) - t.jalon_1968 AS ecart_1968,
       t.couche_1999                                      AS couche_1999_avant,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> :'date_1999'::date)               AS couche_1999_apres,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> :'date_1999'::date) - t.couche_1999 AS ecart_1999
FROM   p79_temoin t;

\echo ''
\echo '   les atomes de 1999 HORS périmètre — département sans plancher.'
\echo '   Ils expliquent l''écart entre la couche de 1999 et `p79_cible`,'
\echo '   et ils méritent d''être regardés : un département sans aucun acte'
\echo '   au registre est soit un fait, soit un trou du moissonnage.'
SELECT u.dep, count(*) AS atomes, min(m.unit_id) AS un_canton,
       coalesce(min(u.nom), '?') AS un_nom
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1999'::date
  AND  NOT EXISTS (SELECT 1 FROM p79_plancher p WHERE p.dep = u.dep::text)
GROUP  BY u.dep ORDER BY atomes DESC;

\echo ''
\echo '-- 10 d. ce que snapshot répond désormais, avant et après'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements
FROM   (VALUES ('1988-06-01'), ('1990-06-01'), ('1993-06-01'),
               ('1995-06-01'), ('1997-06-01'), ('1998-06-01')) v(d);

\echo ''
\echo '-- 10 e. toute ligne posée a-t-elle sa qualité ? (doit valoir 0)'
SELECT count(*) AS sans_qualite
FROM   p79_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p79_qualite q
                    WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '-- 10 f. aucune ligne hors de la fenêtre de son département (doit valoir 0)'
SELECT count(*) AS hors_fenetre
FROM   p79_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
JOIN   p79_plancher p ON p.dep = q.dep
WHERE  m.valid_from < p.plancher OR m.valid_to > '1999-01-01'::date;

\echo ''
\echo '-- 10 g. aucune ligne sur un pseudo-canton de 25 (doit valoir 0)'
\echo '   (Lyon et Marseille restent sans canton avant 1999 : la ville-canton'
\echo '    est une convention de 25, pas une composition à reporter)'
SELECT count(*) AS sur_pseudo_canton
FROM   p79_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
JOIN   pseudo_canton_trace t ON t.quoi = 'unit' AND t.cle = m.unit_id;

ANALYZE membership; ANALYZE p79_qualite;

\echo ''
\echo '============================================================'
\echo ' Report posé. Pour retirer la seule part risquée :'
\echo ''
\echo '   DELETE FROM histgis.membership m USING histgis.p79_qualite q'
\echo '    WHERE q.membership_id = m.membership_id AND q.sous_plafond;'
\echo ''
\echo ' Pour tout défaire : rejouer ce fichier après avoir vidé'
\echo ' p79_trace, ou lancer le DELETE du § 2.'
\echo '============================================================'

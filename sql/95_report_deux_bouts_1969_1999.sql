-- ============================================================================
-- histgis — 95_report_deux_bouts_1969_1999.sql : l'intervalle noir entre
--                                               `81` et `79`, par ses deux bouts
--
--   psql -d histgis -1 -f sql/95_report_deux_bouts_1969_1999.sql
--
-- ÉCRIT DANS `membership`. Tout est tracé dans `p95_trace` et le § 2 défait le
-- passage précédent : le fichier est rejouable seul, et il passe dans
-- `rejouer_apres_rebuild.sh` après `79`, `81` et `93`.
--
-- CE QU'IL COMBLE
-- ===============
-- Les trous de la couche cantonale ENTIÈREMENT compris dans [1969, 1999] :
-- 357 788 atome-années noires au 23 septembre 2026, 36,3 % de la période,
-- mesurées par `diag_intervalle_noir.sql`. Le trou s'ouvre au scrutin du
-- 23 septembre 1973, et non au « mur 1986-1989 » qu'on lui prêtait : `81`
-- arrête son report pour TOUT un département au premier acte, alors qu'un
-- décret de « création de cantons » ne déplace que les communes des cantons
-- qu'il crée ou modifie.
--
-- LA RÈGLE — celle de `93`, transposée
-- ====================================
-- Pour chaque atome, le trou a un bout gauche (la ligne qui le ferme : `81`,
-- ou `75`/`76`/`77`) et un bout droit (celle qui l'ouvre : `79`, ou
-- `75`/`76`/`77`). **Si les deux bouts portent le même canton, et qu'aucun
-- acte lu ne nomme la commune dans le trou, on pose ce canton sur le trou.**
-- Sinon, on laisse vide : un désaccord n'est pas arbitré.
--
-- Le registre n'AUTORISE rien : il sert à écarter les communes nommées (un
-- acte les a déplacées ; un accord des bouts y serait un aller-retour, à lire)
-- et à expliquer les désaccords. C'est le rôle qu'il joue dans `93`, l'inverse
-- de celui qu'il joue dans `79` et `81`.
--
-- POURQUOI PAS LE CHAÎNAGE ACTE PAR ACTE
-- ======================================
-- Franchir un acte pour toute commune qu'il ne nomme pas suppose l'acte lu EN
-- ENTIER. 62 cantons annoncés au titre d'un décret n'ont jamais été lus : une
-- commune d'un de ces cantons passerait pour « non nommée » et serait reportée
-- à tort. L'accord des deux bouts ne dépend d'aucune complétude de lecture.
--
-- CE QUE LA MESURE A DIT — `diag_deux_bouts_1969_1999.sql`, 23 sept. 2026
-- =======================================================================
--   trous à deux bouts, hors fractions        25 566
--   accord                                    91,68 %  (23 440)
--   accord, commune NON nommée               93,14 %  sur 24 997
--   accord, commune NOMMÉE par un acte       27,59 %  sur    569
--   aucun acte dans le trou                 100,00 %  sur    261
--   témoin 1954 → 1968 (`66`)                89,80 %
--
-- **La pente est là, et forte** : l'accord s'effondre exactement quand un
-- décret nomme la commune. C'est ce qui fait de l'accord une mesure des
-- décrets et non un artefact. Elle n'est PAS monotone en nombre d'actes ni en
-- longueur de trou (91 % à un acte, 94-96 % à trois et plus) : les désaccords
-- résiduels des communes non nommées ne sont donc pas des mouvements cachés
-- qui s'accumulent avec le temps, mais surtout des lectures — `59` mesurait
-- déjà 88,3 % d'accord 1968/1999 toutes populations — et des identités de
-- cantons qui glissent (§ 5 du diag : Corse, Sarreguemines-Campagne…). Ni
-- les unes ni les autres ne sont posées.
--
-- CE QUE L'ACCORD NE VOIT PAS
-- ===========================
-- Une commune partie puis revenue par un acte NON lu. Les aller-retours par
-- acte lu sont écartés (157 cas, 2 393 atome-années, § 4 : « accord mais
-- nommé »). La borne de l'autre est celle de `93` : 0,29 % de transferts non
-- datés en quatorze ans, au sens d'une borne haute.
--
-- CE QU'IL NE FAIT PAS
-- ====================
--   * les FRACTIONS (215 trous) : une fraction porte son canton dans son
--     identifiant, son accord ne mesure rien. Même réserve que `93` ;
--   * la CORSE : ses cantons changent d'identifiant au 1er janvier 1976
--     (20NN → 2ANN / 2BNN). Aucun de ses trous n'est en accord ; les
--     renumérotations pures relèvent d'une règle à part, pas de celle-ci ;
--   * les désaccords EN BLOC (Sarreguemines → Sarreguemines-Campagne) : un
--     canton scindé dont on connaît la fille, mais pas la date d'effet pour
--     chaque commune. C'est le chaînage, sur ces seuls cantons.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.p81_trace') IS NULL
       OR to_regclass('histgis.p79_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer `79` puis `81` — ce fichier comble ENTRE leurs deux reports.';
    END IF;
    IF to_regclass('histgis.acte_composition') IS NULL
       OR to_regclass('histgis.scrutin_cantonal') IS NULL
       OR to_regclass('histgis.acte_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` et `75` (acte_composition, scrutin_cantonal, acte_effet).';
    END IF;
    IF to_regclass('histgis.pseudo_canton_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `25` (pseudo_canton_trace) — une convention ne se reporte pas.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. DÉFAIRE LE PASSAGE PRÉCÉDENT, ET PRENDRE LES TÉMOINS AVANT D'ÉCRIRE
-- ---------------------------------------------------------------------------
-- Défaire d'abord : les trous se recalculent sur une base où ce fichier n'a
-- rien posé, faute de quoi un rejeu ne trouverait plus rien à combler et
-- rendrait « zéro » comme un succès.
CREATE TABLE IF NOT EXISTS p95_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p95_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p95_trace;
DROP TABLE IF EXISTS p95_qualite;

DROP TABLE IF EXISTS p95_temoin;
CREATE TABLE p95_temoin AS
SELECT (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1968-06-01'::date) AS jalon_1968,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1980-06-01'::date) AS canton_1980,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1999-06-01'::date) AS couche_1999,
       (SELECT count(*) FROM membership WHERE niveau = 'canton')    AS total_canton,
       (SELECT count(*) FROM membership WHERE niveau = 'circo')     AS total_circo;

\echo ''
\echo '============================================================'
\echo ' 1969-1998 : LE REPORT ENTRE DEUX BOUTS ATTESTÉS'
\echo '============================================================'
\echo ''
\echo '-- 2. les témoins, pris avant toute écriture'
SELECT * FROM p95_temoin;

-- ---------------------------------------------------------------------------
-- 3. L'origine de chaque ligne, et les trous
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p95_origine;
CREATE TABLE p95_origine (membership_id bigint PRIMARY KEY, fichier text NOT NULL);
INSERT INTO p95_origine
SELECT DISTINCT ON (cle::bigint) cle::bigint, f
FROM (
          SELECT cle, '81' AS f, 1 AS rang FROM p81_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '79', 2 FROM p79_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '75', 3 FROM p75_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '76', 4 FROM p76_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '77', 5 FROM p77_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '74', 6 FROM y67_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '59', 7 FROM c68_trace WHERE quoi LIKE 'membership%'
-- `24` : la couche de 1999 elle-même, bout droit de 262 trous qui finissent
-- au 1999-01-01. Oubliée au premier passage (23 septembre 2026), où ces
-- lignes sortaient en « ? » et donc hors de `bouts_releves` — alors que le
-- COG 1999 est un relevé, pas un report.
UNION ALL SELECT cle, '24', 8 FROM canton_moderne_trace WHERE quoi = 'membership'
) t
WHERE cle ~ '^[0-9]+$'
ORDER BY cle::bigint, rang;

-- Un trou : entre la fin d'une ligne cantonale et le début de la suivante,
-- pour le même atome, ENTIÈREMENT dans [1969-01-01, 1999-01-01].
DROP TABLE IF EXISTS p95_trou;
CREATE TABLE p95_trou AS
WITH l AS (
    SELECT m.atom_id, m.membership_id, m.unit_id, m.valid_to,
           lead(m.membership_id) OVER w AS id_d,
           lead(m.unit_id)       OVER w AS unit_d,
           lead(m.valid_from)    OVER w AS from_d
    FROM   membership m
    WHERE  m.niveau = 'canton'
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT l.atom_id,
       a.insee_geofla                          AS insee,
       (a.fraction OR l.atom_id LIKE '%#%')    AS fraction,
       trim(u.dep::text)                       AS dep,
       l.valid_to                              AS valid_from,
       l.from_d                                AS valid_to,
       l.unit_id                               AS unit_g,
       l.unit_d,
       coalesce(og.fichier, '?')               AS source_g,
       coalesce(od.fichier, '?')               AS source_d
FROM   l
JOIN   atom a ON a.atom_id = l.atom_id
JOIN   unit u ON u.unit_id = l.unit_id AND u.niveau = 'canton'
LEFT   JOIN p95_origine og ON og.membership_id = l.membership_id
LEFT   JOIN p95_origine od ON od.membership_id = l.id_d
WHERE  l.from_d > l.valid_to
  AND  l.valid_to >= DATE '1969-01-01'
  AND  l.from_d   <= DATE '1999-01-01';
CREATE INDEX ON p95_trou (atom_id);

-- Les communes nommées par un acte lu, à la date d'effet de `75` (premier
-- tour du renouvellement qui suit la signature).
DROP TABLE IF EXISTS pg_temp.p95_nom;
CREATE TEMP TABLE p95_nom AS
SELECT DISTINCT c.insee,
       (SELECT min(s.tour1) FROM scrutin_cantonal s
         WHERE s.tour1 >= c.date_acte) AS effet
FROM   acte_composition c
WHERE  c.insee IS NOT NULL;
CREATE INDEX ON p95_nom (insee, effet);

ALTER TABLE p95_trou ADD COLUMN actes int, ADD COLUMN nomme boolean,
                     ADD COLUMN verdict text;
UPDATE p95_trou t SET
    actes = (SELECT count(DISTINCT e.legifrance_id)
             FROM   acte_departement d
             JOIN   acte_effet e ON e.legifrance_id = d.legifrance_id
             WHERE  d.dep = t.dep
               AND  e.date_effet >= t.valid_from AND e.date_effet < t.valid_to
               AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                                 WHERE x.legifrance_id = e.legifrance_id)),
    nomme = EXISTS (SELECT 1 FROM p95_nom n
                    WHERE  n.insee = t.insee
                      AND  n.effet >= t.valid_from AND n.effet < t.valid_to);

-- ---------------------------------------------------------------------------
-- 4. LE VERDICT, TROU PAR TROU — le tamis est nommé, pas subi
-- ---------------------------------------------------------------------------
UPDATE p95_trou SET verdict = CASE
    WHEN fraction                   THEN 'fraction'
    WHEN EXISTS (SELECT 1 FROM pseudo_canton_trace p
                  WHERE p.quoi = 'unit'
                    AND p.cle IN (unit_g, unit_d))
                                    THEN 'pseudo_canton'
    WHEN unit_g <> unit_d           THEN 'desaccord'
    WHEN nomme                      THEN 'accord_nomme'
    ELSE                                 'accord' END;

\echo ''
\echo '-- 4. le tamis, classe par classe'
\echo '   `accord` est le seul poste posé. `accord_nomme` : les deux bouts'
\echo '   disent le même canton, mais un acte lu a nommé la commune entre les'
\echo '   deux — un aller-retour possible, à lire, pas à supposer.'
SELECT verdict,
       count(*)                                        AS trous,
       count(DISTINCT atom_id)                         AS atomes,
       round(sum((valid_to - valid_from) / 365.25))    AS atome_annees
FROM   p95_trou GROUP BY 1 ORDER BY 4 DESC;

\echo ''
\echo '-- 4 bis. la pente, relue ici (hors fractions et pseudo-cantons)'
\echo '   Attendu du diag : non nommé 93,14 %, nommé 27,59 %. Si ces deux'
\echo '   nombres ne sont pas retrouvés, ce fichier ne sélectionne pas la'
\echo '   population que le diag a mesurée, et son fondement tombe.'
SELECT nomme, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE unit_g = unit_d) / count(*), 2) AS pct_accord
FROM   p95_trou
WHERE  verdict NOT IN ('fraction', 'pseudo_canton')
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. CE QUI SERA POSÉ
-- ---------------------------------------------------------------------------
-- Le trou est libre PAR CONSTRUCTION — il est l'intervalle entre deux lignes
-- consécutives du même atome. Le tamis d'occupation de `79` et `93` est donc
-- sans objet ; c'est le garde-fou 7 c qui le vérifie au lieu de le supposer.
DROP TABLE IF EXISTS p95_pose;
CREATE TABLE p95_pose AS
SELECT atom_id, unit_g AS unit_id, dep, valid_from, valid_to,
       source_g, source_d, actes
FROM   p95_trou
WHERE  verdict = 'accord';

\echo ''
\echo '-- 5. ce qui va être posé, avant écriture'
SELECT count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS du, max(valid_to) AS au,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p95_pose;

-- ---------------------------------------------------------------------------
-- 6. GARDE-FOUS — avant d'écrire, pas après
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p95_pose GROUP BY atom_id, valid_from HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes à la même date (p. ex. %).', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p95_pose
     WHERE valid_from < '1969-01-01'::date OR valid_to > '1999-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) hors de [1969, 1999].', n;
    END IF;

    -- le trou est libre par construction : on le VÉRIFIE
    SELECT count(*), min(p.atom_id) INTO n, ex FROM p95_pose p
     WHERE EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une période déjà occupée (p. ex. %). Le calcul des trous est faux.', n, ex;
    END IF;

    SELECT count(*), min(p.atom_id) INTO n, ex FROM p95_pose p
     WHERE NOT EXISTS (SELECT 1 FROM unit u
                        WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une unité absente (p. ex. %).', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p95_pose WHERE atom_id LIKE '%#%';
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % fraction(s) dans les lignes à poser.', n;
    END IF;

    -- Le seuil : la sélection a dérivé si elle s'écarte beaucoup de la mesure
    -- du 23 septembre 2026 (23 283 trous). C'est l'alarme de `42` : un saut
    -- ne veut pas dire que l'histoire a changé, il veut dire que la sélection
    -- a dérivé. Seuil large, parce que les fichiers voisins bougent.
    SELECT count(*) INTO n FROM p95_pose;
    IF n > 30000 OR n < 15000 THEN
        RAISE EXCEPTION 'REFUS : % lignes à poser, attendu de l''ordre de 23 000. La sélection a dérivé : rien n''est posé.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. L'ÉCRITURE
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p95_pose
    RETURNING membership_id
)
INSERT INTO p95_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 7. posé'
SELECT count(*) AS rattachements FROM p95_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 8. LA QUALITÉ, LIGNE À LIGNE
--
-- Une colonne, pas une note : une lecture qui ne joint pas cette table prend
-- un report pour un relevé.
--
--   source_g, source_d   les fichiers qui ont posé les deux bouts
--   actes                les actes du département qui prennent effet dans le
--                        trou — autant d'occasions qu'avait la commune de
--                        bouger sans que rien ne le dise
--   bouts_releves        vrai si AUCUN des deux bouts n'est un report : ni
--                        `81` ni `79`, mais une composition lue (`75`-`77`).
--                        C'est le seul cas où les deux bouts sont des faits.
-- ---------------------------------------------------------------------------
CREATE TABLE p95_qualite AS
SELECT m.membership_id,
       p.atom_id, p.unit_id, p.dep,
       p.source_g, p.source_d, p.actes,
       (p.source_g NOT IN ('81', '79', '?') AND p.source_d NOT IN ('81', '79', '?'))
                                                        AS bouts_releves,
       round((p.valid_to - p.valid_from) / 365.25, 2)  AS annees_reportees
FROM   p95_pose p
JOIN   membership m ON m.atom_id    = p.atom_id
                   AND m.valid_from = p.valid_from
                   AND m.niveau     = 'canton';
ALTER TABLE p95_qualite ADD PRIMARY KEY (membership_id);
CREATE INDEX p95_qualite_dep_idx ON p95_qualite (dep);

\echo ''
\echo '-- 8. la qualité du report'
SELECT source_g || ' → ' || source_d  AS bouts,
       count(*)                       AS lignes,
       round(sum(annees_reportees))   AS atome_annees,
       round(avg(actes), 1)           AS actes_moyens
FROM   p95_qualite GROUP BY 1 ORDER BY 2 DESC;

-- ---------------------------------------------------------------------------
-- 9. CE QUE LE TROU GARDE — la file d'attente, chiffrée par la base
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 9. ce qui reste vide, par classe'
SELECT verdict, count(*) AS trous,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p95_trou WHERE verdict <> 'accord'
GROUP  BY 1 ORDER BY 3 DESC;

-- ---------------------------------------------------------------------------
-- 10. RECETTES — elles doivent toutes valoir zéro, ou le nombre annoncé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 10 a. un atome à deux cantons à la même date (doit valoir 0)'
SELECT count(*) AS atomes_a_deux_cantons
FROM   (SELECT atom_id, periode FROM membership WHERE niveau = 'canton'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\echo ''
\echo '-- 10 b. les couches existantes sont-elles intactes ? (écarts à 0)'
SELECT (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> '1968-06-01'::date) - t.jalon_1968   AS ecart_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> '1999-06-01'::date) - t.couche_1999  AS ecart_1999,
       (SELECT count(*) FROM membership WHERE niveau = 'circo') - t.total_circo AS ecart_circo,
       (SELECT count(*) FROM membership WHERE niveau = 'canton') - t.total_canton
         - (SELECT count(*) FROM p95_trace)                   AS ecart_total
FROM   p95_temoin t;

\echo ''
\echo '-- 10 c. toute ligne posée a-t-elle sa qualité ? (doit valoir 0)'
SELECT count(*) AS sans_qualite
FROM   p95_trace t
WHERE  NOT EXISTS (SELECT 1 FROM p95_qualite q WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '-- 10 d. aucune ligne sur un pseudo-canton de `25` (doit valoir 0)'
SELECT count(*) AS sur_pseudo_canton
FROM   p95_qualite q
JOIN   pseudo_canton_trace p ON p.quoi = 'unit' AND p.cle = q.unit_id;

\echo ''
\echo '-- 10 e. chaque ligne posée est jointive des deux côtés (doit valoir 0)'
\echo '   (une ligne d''ici finit où la suivante commence, et commence où la'
\echo '    précédente finit — trois lignes, deux sources, aucune fondue)'
SELECT count(*) AS non_jointives
FROM   p95_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
WHERE  NOT EXISTS (SELECT 1 FROM membership g WHERE g.atom_id = m.atom_id
                     AND g.niveau = 'canton' AND g.valid_to = m.valid_from
                     AND g.unit_id = m.unit_id)
   OR  NOT EXISTS (SELECT 1 FROM membership d WHERE d.atom_id = m.atom_id
                     AND d.niveau = 'canton' AND d.valid_from = m.valid_to
                     AND d.unit_id = m.unit_id);

\echo ''
\echo '-- 10 f. ce que snapshot répond désormais'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements
FROM   (VALUES ('1968-06-01'), ('1974-06-01'), ('1980-06-01'), ('1986-06-01'),
               ('1990-06-01'), ('1995-06-01'), ('1999-06-01')) v(d);
\echo '   1968 et 1999 ne doivent PAS bouger (§ 10 b). 1974 à 1995 doivent'
\echo '   monter vers l''effectif de 1968 et de 1999, sans l''atteindre : ce'
\echo '   qui reste est le § 9.'

ANALYZE membership; ANALYZE p95_qualite;

\echo ''
\echo '============================================================'
\echo ' Report posé. Pour ne garder que les lignes dont les deux bouts'
\echo ' sont des compositions lues et non des reports :'
\echo ''
\echo '   DELETE FROM histgis.membership m USING histgis.p95_qualite q'
\echo '    WHERE q.membership_id = m.membership_id AND NOT q.bouts_releves;'
\echo ''
\echo ' Pour tout défaire : rejouer ce fichier, ou lancer le DELETE du § 2.'
\echo '============================================================'

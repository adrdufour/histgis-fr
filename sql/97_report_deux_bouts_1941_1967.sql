-- ============================================================================
-- histgis — 97_report_deux_bouts_1941_1967.sql : la carte vide de 1955 à
--          1967, et les absents de 1954, par leurs deux bouts
--
--   cd ~/Téléchargements/projet_carte     (le \copy de l'annexe VII est relatif)
--   psql -d histgis -1 -f sql/97_report_deux_bouts_1941_1967.sql
--
-- ÉCRIT DANS `membership`. Tout est tracé dans `p97_trace` et le § 2 défait le
-- passage précédent : le fichier est rejouable seul. Il passe dans
-- `rejouer_apres_rebuild.sh` après `93` et `95` — il ne dépend que de `93`
-- (qui borne les trous par la gauche) et des jalons jugés par `96`.
--
-- CE QU'IL COMBLE
-- ===============
--   A. [1955-01-01, 1968-01-01) — entre le jalon de 1954 et celui de 1968.
--      Sur l'export servi, 160 communes étaient dessinées de 1955 à 1967.
--   B. [1941-01-01, 1968-01-01) — les atomes ABSENTS du relevé de 1954, que
--      `93` ne pouvait pas poser faute de second bout : de la couche 1940 au
--      jalon de 1968.
--
-- LA RÈGLE — celle de `93` et de `95`
-- ===================================
-- **Si les deux bouts portent le même canton, et qu'aucun acte du registre ne
-- nomme la commune dans le trou, on pose ce canton sur le trou.** Sinon on
-- laisse vide. Les textes n'autorisent rien ; ils écartent et ils expliquent.
--
-- CE QUE LA MESURE A DIT — `diag_deux_bouts_1955_1967.sql`, 23 sept. 2026
-- ======================================================================
--                                           trous     accord
--   A, comparables                          24 514    98,49 %
--   B, comparables                           6 473    97,73 %
--   A, canton nommé par l'annexe VII           389    57,84 %
--   A, département sans événement           17 407    99,20 %
--   A, commune nommée par un acte               45     8,89 %
--   A, non nommée                           24 469    98,66 %
--   A, bout corrigé par `96`                   566    99,65 %
--   B, bout corrigé par `96`                   130   100,00 %
--
-- **La pente est là, et plus franche qu'en 1969-1999** : l'accord tombe de
-- 99 % à 58 % dans les cantons que l'annexe VII divise, à 9 % pour les
-- communes qu'un acte nomme. L'accord mesure donc bien les textes. Et les
-- bouts corrigés par `96` s'accordent MIEUX que les autres : la correction a
-- levé l'erreur, elle ne l'a pas déplacée.
--
-- CE QUI EST POSÉ, CE QUI NE L'EST PAS
-- ====================================
-- Posé :
--   * `accord`                — les deux bouts d'accord, rien ne nomme la
--                               commune ni son canton ;
--   * `accord_canton_annexe`  — les deux bouts d'accord dans un canton que
--                               l'annexe VII divise. La commune n'est PAS
--                               nommée — c'est la règle de `95`, qui pose les
--                               communes non nommées d'un canton qu'un acte
--                               modifie. Une commune restée dans Tours-Sud
--                               de 1954 à 1968 n'a pas quitté Tours-Sud
--                               pendant la division de 1956. Marqué, pour
--                               être retiré d'un DELETE si on en juge
--                               autrement (§ 11).
-- Laissé vide et compté (§ 9) :
--   * les DÉSACCORDS — 370 en A, 147 en B ; l'annexe en explique la moitié
--     (Metz-Campagne → Rombas, Woippy ; Belfort ; Houdain → Bruay) ;
--   * les communes NOMMÉES par un acte, même d'accord (aller-retour ?) ;
--   * les IDENTITÉS INCOMPARABLES — Seine, Seine-et-Oise, changement de
--     département : 1954 et 1968 n'y numérotent pas les cantons de la même
--     façon, un « accord » 78nn = 78nn serait une coïncidence ;
--   * les FRACTIONS ;
--   * les bouts d'origine inconnue (`?`) : seuls des RELEVÉS bornent — la
--     couche 1940, `68`, `87` à gauche ; `59`, `60`, `74` à droite.
--
-- CE QUE L'ACCORD NE VOIT PAS
-- ===========================
-- Une commune partie puis revenue entre les deux bouts. En B, les bouts sont
-- à vingt-sept ans l'un de l'autre et la fenêtre enjambe les deux vagues
-- (1940-1954, 1954-1968) : c'est le report le plus long du dépôt, et la
-- qualité le dit ligne à ligne (`fenetre`).
--
-- Prérequis : `59`, `60`, `68`, `74`, `87` (les bouts), `93` (qui borne A par
--             la gauche : sans lui, A et B se confondent), `96` (les jalons
--             jugés), `72` (acte_composition).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.c54_trace') IS NULL OR to_regclass('histgis.c68_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `59` et `68` (les jalons).';
    END IF;
    IF to_regclass('histgis.p93_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `93` — sans lui, les trous A et B se confondent.';
    END IF;
    IF to_regclass('histgis.p96_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `96` — reporter des jalons non jugés reporterait l''OCR.';
    END IF;
    IF to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` (acte_composition).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. DÉFAIRE LE PASSAGE PRÉCÉDENT, ET PRENDRE LES TÉMOINS AVANT D'ÉCRIRE
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p97_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p97_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p97_trace;
DROP TABLE IF EXISTS p97_qualite;

DROP TABLE IF EXISTS p97_temoin;
CREATE TABLE p97_temoin AS
SELECT (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1940-06-01')                     AS couche_1940,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1950-06-01')                     AS report_1950,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1954-06-01')                     AS jalon_1954,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1968-06-01')                     AS jalon_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'canton') AS total_canton,
       (SELECT count(*) FROM membership WHERE niveau = 'circo')  AS total_circo;

\echo ''
\echo '============================================================'
\echo ' 1941-1967 : LE REPORT ENTRE DEUX BOUTS ATTESTÉS'
\echo '============================================================'
\echo ''
\echo '-- 2. les témoins, pris avant toute écriture'
SELECT * FROM p97_temoin;

-- ---------------------------------------------------------------------------
-- 3. Les textes : l'annexe VII (fenêtre 1954-1968) et le registre
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.norme(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT regexp_replace(
             btrim(regexp_replace(
               translate(upper(coalesce(t, '')),
                         'ÀÂÄÁÃÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜŸ''’-.,()',
                         'AAAAACEEEEIIIINOOOOOUUUUY       '),
               '\s+', ' ', 'g')),
             '\mSAINTE?\M', 'ST', 'g')
$f$;

CREATE OR REPLACE FUNCTION pg_temp.base_canton(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT btrim(regexp_replace(pg_temp.norme(t),
       '( (NORD|SUD|EST|OUEST|CENTRE|CAMPAGNE|VILLE|RIVE|N|S|E|O|NE|NO|SE|SO|CANTON|[0-9]+(ER|E)?|[IVX]+(ER|E)?))+( .*)?$',
       ''))
$f$;

DROP TABLE IF EXISTS pg_temp.p97_annexe;
CREATE TEMP TABLE p97_annexe (dep text, dep_nom text, date_texte text,
                              date_iso date, type text, texte text, page text);
\copy pg_temp.p97_annexe FROM 'cantons/annexe_vii.csv' WITH (FORMAT csv, HEADER true)
DELETE FROM p97_annexe
 WHERE date_iso <  DATE '1940-06-01' OR date_iso >= DATE '1968-01-01'
    OR type IN ('renommage_departement', 'transfert_arr', 'creation_arr',
                'transfert_sp', 'suppression_departement');
UPDATE p97_annexe SET dep = '78' WHERE dep = '78O';
ALTER TABLE p97_annexe ADD COLUMN texte_n text;
UPDATE p97_annexe SET texte_n = ' ' || pg_temp.norme(texte) || ' ';

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM p97_annexe WHERE date_iso >= DATE '1954-06-01';
    IF n < 40 THEN
        RAISE EXCEPTION 'REFUS : % événements de l''annexe VII en 1954-1968, '
            'attendu 47. Le \copy a-t-il lu le bon fichier ? (lancer depuis la racine)', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Les trous, et leur verdict
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.p97_origine;
CREATE TEMP TABLE p97_origine (membership_id bigint PRIMARY KEY, fichier text);
INSERT INTO p97_origine
SELECT DISTINCT ON (cle::bigint) cle::bigint, f
FROM (
          SELECT cle, '68' AS f, 1 AS rang FROM c54_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '87', 2 FROM seine_canton_trace
UNION ALL SELECT cle, '93', 3 FROM p93_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '59', 4 FROM c68_trace WHERE quoi = 'membership'
UNION ALL SELECT cle, '60', 5 FROM c60_trace WHERE quoi LIKE 'membership%'
UNION ALL SELECT cle, '74', 6 FROM y67_trace WHERE quoi LIKE 'membership%'
) t
WHERE cle ~ '^[0-9]+$'
ORDER BY cle::bigint, rang;

DROP TABLE IF EXISTS p97_trou;
CREATE TABLE p97_trou AS
WITH l AS (
    SELECT m.atom_id, m.membership_id, m.unit_id, m.valid_from, m.valid_to,
           lead(m.membership_id) OVER w AS id_d,
           lead(m.unit_id)       OVER w AS unit_d,
           lead(m.valid_from)    OVER w AS from_d
    FROM   membership m
    WHERE  m.niveau = 'canton'
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT l.atom_id,
       a.insee_geofla                         AS insee,
       a.fraction,
       trim(u.dep::text)                      AS dep,
       l.valid_to                             AS valid_from,
       l.from_d                               AS valid_to,
       l.membership_id                        AS id_g,
       l.id_d,
       l.unit_id                              AS unit_g,
       l.unit_d,
       coalesce(og.fichier,
                CASE WHEN l.valid_to = DATE '1941-01-01' THEN '1940'
                     ELSE '?' END)            AS source_g,
       coalesce(od.fichier, '?')              AS source_d,
       CASE WHEN l.valid_to = DATE '1955-01-01' THEN 'A'
            ELSE 'B' END                      AS fenetre
FROM   l
JOIN   atom a ON a.atom_id = l.atom_id
JOIN   unit u ON u.unit_id = l.unit_id AND u.niveau = 'canton'
LEFT   JOIN p97_origine og ON og.membership_id = l.membership_id
LEFT   JOIN p97_origine od ON od.membership_id = l.id_d
WHERE  l.from_d = DATE '1968-01-01'
  AND  l.valid_to IN (DATE '1955-01-01', DATE '1941-01-01');
CREATE INDEX ON p97_trou (atom_id);

ALTER TABLE p97_trou
    ADD COLUMN nomme_acte boolean,
    ADD COLUMN annexe     boolean,
    ADD COLUMN verdict    text;

UPDATE p97_trou t SET nomme_acte = EXISTS (
    SELECT 1 FROM acte_composition c
     WHERE (c.atome = t.atom_id OR c.insee = t.insee)
       AND c.date_acte >= t.valid_from AND c.date_acte < t.valid_to);

UPDATE p97_trou t SET annexe = EXISTS (
    SELECT 1 FROM p97_annexe x
     WHERE x.dep = t.dep AND x.date_iso >= t.valid_from AND x.date_iso < t.valid_to
       AND (   x.texte_n LIKE '% ' || pg_temp.base_canton(
                 (SELECT v.nom FROM unit_version v WHERE v.unit_id = t.unit_g
                   ORDER BY abs(v.valid_from - t.valid_from) LIMIT 1)) || ' %'
            OR x.texte_n LIKE '% ' || pg_temp.base_canton(
                 (SELECT v.nom FROM unit_version v WHERE v.unit_id = t.unit_d
                   ORDER BY abs(v.valid_from - t.valid_to) LIMIT 1)) || ' %'));

UPDATE p97_trou SET verdict = CASE
    WHEN fraction OR atom_id LIKE '%#%'                         THEN 'fraction'
    WHEN source_g NOT IN ('1940', '68', '87')
      OR source_d NOT IN ('59', '60', '74')                     THEN 'bout_inconnu'
    WHEN left(unit_g, 2) IN ('75', '78')
      OR left(unit_d, 2) IN ('75', '78', '91', '92', '93', '94', '95')
      OR left(unit_g, 2) <> left(unit_d, 2)                     THEN 'identites_incomparables'
    WHEN unit_g <> unit_d                                       THEN 'desaccord'
    WHEN nomme_acte                                             THEN 'accord_nomme'
    WHEN annexe                                                 THEN 'accord_canton_annexe'
    ELSE                                                             'accord'
END;

\echo ''
\echo '-- 4. le tamis, trou par trou'
SELECT fenetre, verdict, count(*) AS trous,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p97_trou GROUP BY 1, 2 ORDER BY 1, 4 DESC;

\echo ''
\echo '-- 4 bis. la pente, relue ici (comparables hors fractions)'
\echo '   Attendu (diag du 23 sept.) : A 98,49 %, B 97,73 % ; canton nommé par'
\echo '   l''annexe ~57 % ; commune nommée par un acte ~9 % (A).'
SELECT fenetre,
       CASE WHEN nomme_acte THEN 'commune nommée par un acte'
            WHEN annexe     THEN 'canton nommé par l''annexe VII'
            ELSE                 'aucun texte' END            AS texte,
       count(*)                                               AS trous,
       round(100.0 * count(*) FILTER (WHERE unit_g = unit_d) / count(*), 2) AS pct_accord
FROM   p97_trou
WHERE  verdict IN ('accord', 'accord_nomme', 'accord_canton_annexe', 'desaccord')
GROUP  BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 5. CE QUI SERA POSÉ
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p97_pose;
CREATE TABLE p97_pose AS
SELECT atom_id, unit_g AS unit_id, dep, valid_from, valid_to,
       fenetre, verdict, source_g, source_d, id_g, id_d
FROM   p97_trou
WHERE  verdict IN ('accord', 'accord_canton_annexe');

\echo ''
\echo '-- 5. ce qui va être posé, avant écriture'
SELECT fenetre, verdict, count(*) AS lignes, min(valid_from) AS du,
       max(valid_to) AS au,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p97_pose GROUP BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 6. GARDE-FOUS — avant d'écrire, pas après
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p97_pose GROUP BY atom_id HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes (p. ex. %).', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p97_pose
     WHERE valid_from < DATE '1941-01-01' OR valid_to > DATE '1968-01-01';
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) hors de [1941, 1968).', n;
    END IF;

    SELECT count(*), min(p.atom_id) INTO n, ex FROM p97_pose p
     WHERE EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une période déjà occupée (p. ex. %). Le calcul des trous est faux.', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p97_pose WHERE atom_id LIKE '%#%';
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % fraction(s) dans les lignes à poser.', n;
    END IF;

    -- L'alarme de `42` : la mesure du 23 septembre 2026 annonçait
    -- 23 919 + 221 (A) et 6 282 + 40 (B), soit 30 462. Seuil large, parce que
    -- les fichiers voisins bougent ; un saut veut dire que la sélection a
    -- dérivé, pas que l'histoire a changé.
    SELECT count(*) INTO n FROM p97_pose;
    IF n > 36000 OR n < 24000 THEN
        RAISE EXCEPTION 'REFUS : % lignes à poser, attendu de l''ordre de 30 500. La sélection a dérivé : rien n''est posé.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. L'ÉCRITURE
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p97_pose
    RETURNING membership_id
)
INSERT INTO p97_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 7. posé'
SELECT count(*) AS rattachements FROM p97_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 8. LA QUALITÉ, LIGNE À LIGNE
--
--   fenetre      A (1954 ↔ 1968, treize ans) | B (1940 ↔ 1968, vingt-sept)
--   verdict      accord | accord_canton_annexe
--   q54, q68     la qualité de lecture des deux jalons (`c54_qualite`,
--                `c68_qualite`) ; NULL pour la couche 1940 et `60`/`74`/`87`
--   corrige_96   un des deux bouts a été corrigé par `96`
-- ---------------------------------------------------------------------------
CREATE TABLE p97_qualite AS
SELECT m.membership_id,
       p.atom_id, p.unit_id, p.dep, p.fenetre, p.verdict,
       p.source_g, p.source_d,
       (SELECT q.appariement FROM c54_qualite q WHERE q.membership_id = p.id_g) AS q54,
       (SELECT q.qualite     FROM c68_qualite q WHERE q.membership_id = p.id_d) AS q68,
       EXISTS (SELECT 1 FROM p96_trace x WHERE x.action = 'corrige'
                  AND x.membership_id IN (p.id_g, p.id_d))                  AS corrige_96,
       round((p.valid_to - p.valid_from) / 365.25, 2)                       AS annees_reportees
FROM   p97_pose p
JOIN   membership m ON m.atom_id    = p.atom_id
                   AND m.valid_from = p.valid_from
                   AND m.niveau     = 'canton';
ALTER TABLE p97_qualite ADD PRIMARY KEY (membership_id);
CREATE INDEX p97_qualite_dep_idx ON p97_qualite (dep);

\echo ''
\echo '-- 8. la qualité du report'
SELECT fenetre, verdict, source_g || ' → ' || source_d AS bouts,
       count(*) AS lignes, round(sum(annees_reportees)) AS atome_annees,
       count(*) FILTER (WHERE corrige_96) AS dont_bout_corrige_96
FROM   p97_qualite GROUP BY 1, 2, 3 ORDER BY 1, 4 DESC;

-- ---------------------------------------------------------------------------
-- 9. CE QUE LE TROU GARDE
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 9. ce qui reste vide, par classe'
SELECT fenetre, verdict, count(*) AS trous,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p97_trou WHERE verdict NOT IN ('accord', 'accord_canton_annexe')
GROUP  BY 1, 2 ORDER BY 1, 4 DESC;

-- ---------------------------------------------------------------------------
-- 10. RECETTES — elles doivent toutes valoir zéro, ou le nombre annoncé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 10 a. un atome à deux cantons à la même date (doit valoir 0)'
SELECT count(*) AS atomes_a_deux_cantons
FROM   membership a JOIN p97_qualite q ON q.membership_id = a.membership_id
JOIN   membership b ON b.atom_id = a.atom_id AND b.niveau = 'canton'
                   AND b.membership_id <> a.membership_id
                   AND b.periode && a.periode;

\echo ''
\echo '-- 10 b. les couches existantes sont-elles intactes ? (écarts à 0)'
SELECT (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1940-06-01') - t.couche_1940            AS ecart_1940,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1954-06-01') - t.jalon_1954             AS ecart_1954,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
          AND periode @> DATE '1968-06-01') - t.jalon_1968             AS ecart_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'circo') - t.total_circo AS ecart_circo,
       (SELECT count(*) FROM membership WHERE niveau = 'canton') - t.total_canton
         - (SELECT count(*) FROM p97_trace)                            AS ecart_total
FROM   p97_temoin t;

\echo ''
\echo '-- 10 c. toute ligne posée a-t-elle sa qualité ? (doit valoir 0)'
SELECT count(*) AS sans_qualite
FROM   p97_trace t
WHERE  NOT EXISTS (SELECT 1 FROM p97_qualite q WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '-- 10 d. chaque ligne posée est jointive des deux côtés, au même canton'
\echo '   (doit valoir 0)'
SELECT count(*) AS non_jointives
FROM   p97_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
WHERE  NOT EXISTS (SELECT 1 FROM membership g WHERE g.atom_id = m.atom_id
                     AND g.niveau = 'canton' AND g.valid_to = m.valid_from
                     AND g.unit_id = m.unit_id)
   OR  NOT EXISTS (SELECT 1 FROM membership d WHERE d.atom_id = m.atom_id
                     AND d.niveau = 'canton' AND d.valid_from = m.valid_to
                     AND d.unit_id = m.unit_id);

\echo ''
\echo '-- 10 e. contrôle nommé : Lamastre (07129), 1955-1967 à 0710'
SELECT q.fenetre, q.verdict, q.unit_id, m.valid_from, m.valid_to, q.corrige_96
FROM   p97_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
JOIN   atom a ON a.atom_id = q.atom_id
WHERE  a.insee_geofla = '07129';

\echo ''
\echo '-- 10 f. ce que snapshot répond désormais'
SELECT d AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements
FROM   (VALUES ('1940-06-01'), ('1945-06-01'), ('1950-06-01'), ('1954-06-01'),
               ('1955-06-01'), ('1960-06-01'), ('1965-06-01'), ('1967-06-01'),
               ('1968-06-01')) v(d);
\echo '   1940, 1954 et 1968 ne doivent PAS bouger (§ 10 b). 1945-1950 montent'
\echo '   des atomes de B ; 1955-1967 passent de ZÉRO à l''effectif de A + B.'

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 11. POUR DÉFAIRE, EN TOUT OU EN PARTIE
-- ---------------------------------------------------------------------------
\echo ''
\echo '============================================================'
\echo ' Report posé. Pour retirer les accords dans un canton divisé :'
\echo '   DELETE FROM histgis.membership m USING histgis.p97_qualite q'
\echo '    WHERE q.membership_id = m.membership_id'
\echo '      AND q.verdict = ''accord_canton_annexe'';'
\echo ' Pour ne garder que la fenêtre A (treize ans) : même DELETE sur'
\echo '      q.fenetre = ''B''.'
\echo ' Pour tout défaire : rejouer ce fichier, ou lancer le DELETE du § 2.'
\echo '============================================================'

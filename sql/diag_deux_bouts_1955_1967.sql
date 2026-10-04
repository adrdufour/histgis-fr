-- ============================================================================
-- diag_deux_bouts_1955_1967.sql — la carte vide de 1955 à 1967, lue par ses
-- deux bouts : les jalons de 1954 et de 1968
--
--   cd ~/Téléchargements/projet_carte     (le \copy de l'annexe VII est relatif)
--   psql -d histgis -f sql/diag_deux_bouts_1955_1967.sql | tee build/deux_bouts_1955.txt
--
-- LECTURE SEULE. Tables temporaires seulement. Écrit le 23 septembre 2026,
-- après `96`. C'est à un futur `97` ce que `diag_deux_bouts_1969_1999` a été
-- à `95` et `70` à `93` : la mesure qui dit si le fichier qui pose vaut
-- d'être écrit.
--
-- LE CONSTAT
-- ----------
-- Sur l'export servi, 160 communes sont dessinées de 1955 à 1967 — la Seine,
-- par sa circo. Le reste de la France est vide treize ans : aucun canton entre
-- le jalon de 1954 ([1954, 1955)) et celui de 1968 ([1968, 1969)). Et les
-- 7 999 atomes absents du relevé de 1954 sont vides depuis 1941 : leur trou
-- court de la couche 1940 au jalon de 1968, vingt-sept ans.
--
-- CE QUI REND LA RÈGLE DE `93` TRANSPOSABLE, ET CE QUI LA REND PLUS DURE
-- ----------------------------------------------------------------------
-- Les deux bouts sont des relevés, lus par nous, sans source commune — comme
-- en 1941-1953. Et depuis `96` ils ne portent plus leurs lectures absurdes.
--
-- Mais l'intervalle n'est pas calme. L'annexe VII compte une trentaine de
-- créations de 1954 à 1968 — contre trois de 1940 à 1954 —, presque toutes
-- URBAINES : Nice, Tours, Caen, Le Mans, Strasbourg, Lens, Villeurbanne…
-- Et le registre des actes (`72`) ne commence qu'en 1958, clairsemé avant
-- 1970 (dix-huit décrets pour 1958-1972). Le test « commune nommée par un
-- acte », qui a porté la pente de `95`, sera donc MAIGRE ici. D'où un second
-- témoin, indépendant du registre : **le canton nommé par l'annexe VII**.
--
-- LE PIÈGE DES IDENTITÉS — la Seine et la Seine-et-Oise
-- -----------------------------------------------------
-- 1954 code la Seine-et-Oise `78nn` ; 1968 la lit dans les départements
-- successeurs, `78nn` compris, avec une AUTRE numérotation (`66` § 6 ter).
-- Un « accord » 78nn = 78nn y serait une coïncidence de numéros. Ces trous
-- sont écartés de la mesure, pas mesurés à tort.
--
-- CE QUE LE FICHIER DOIT DIRE AVANT QU'ON ÉCRIVE `97`
-- ---------------------------------------------------
--   § 1  les trous, par fenêtre (A : 1955-1967 ; B : 1941-1967) ;
--   § 3  l'accord, et SON DÉNOMINATEUR ;
--   § 4  la PENTE : l'accord doit baisser là où un texte touche la commune
--        ou son canton, et presque pas ailleurs. Sans pente, pas de `97` ;
--   § 4 d la même mesure sur les bouts que `96` a corrigés : s'ils
--        s'accordent moins que les autres, `96` s'est trompé ;
--   § 5  les désaccords en bloc (identités) ;
--   § 6  ce que `97` poserait.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.c54_trace') IS NULL
       OR to_regclass('histgis.c68_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `59` et `68` (les jalons).';
    END IF;
    IF to_regclass('histgis.p96_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `96` — mesurer sur des jalons non jugés '
                        'reviendrait à mesurer l''OCR.';
    END IF;
    IF to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` (acte_composition).';
    END IF;
END $$;

-- Normalisation des noms (même règle que `96`, en fonction temporaire pour
-- ne rien laisser en base). SAINT est ramené à ST : l'annexe abrège.
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

-- Le nom « de base » d'un canton : sans ses suffixes de ville divisée.
-- « Tours-Sud » → TOURS, « Metz-Campagne » → METZ, « Nice 2e canton » → NICE.
CREATE OR REPLACE FUNCTION pg_temp.base_canton(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $f$
    SELECT btrim(regexp_replace(pg_temp.norme(t),
       '( (NORD|SUD|EST|OUEST|CENTRE|CAMPAGNE|VILLE|RIVE|N|S|E|O|NE|NO|SE|SO|CANTON|[0-9]+(ER|E)?|[IVX]+(ER|E)?))+( .*)?$',
       ''))
$f$;

-- ---------------------------------------------------------------------------
-- 0. L'annexe VII, fenêtre 1954-1968
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.b_annexe;
CREATE TEMP TABLE b_annexe (dep text, dep_nom text, date_texte text,
                            date_iso date, type text, texte text, page text);
\copy pg_temp.b_annexe FROM 'cantons/annexe_vii.csv' WITH (FORMAT csv, HEADER true)

-- Seuls comptent les événements qui peuvent déplacer une commune entre deux
-- cantons. Les renommages de département, les transferts d'arrondissement ou
-- de sous-préfecture n'en déplacent aucune.
DELETE FROM b_annexe
 WHERE date_iso <  DATE '1954-06-01' OR date_iso >= DATE '1968-01-01'
    OR type IN ('renommage_departement', 'transfert_arr', 'creation_arr',
                'transfert_sp', 'suppression_departement');
UPDATE b_annexe SET dep = '78' WHERE dep = '78O';
ALTER TABLE b_annexe ADD COLUMN texte_n text;
UPDATE b_annexe SET texte_n = ' ' || pg_temp.norme(texte) || ' ';

\echo ''
\echo '============================================================'
\echo ' 1955-1967 PAR LES DEUX BOUTS — mesure, rien n''est écrit'
\echo '============================================================'
\echo ''
\echo '-- 0. l''annexe VII retenue (1954-06 → 1967-12, événements qui déplacent)'
SELECT count(*) AS evenements, count(DISTINCT dep) AS departements FROM b_annexe;

-- ---------------------------------------------------------------------------
-- 1. L'origine de chaque ligne, et les trous
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.b_origine;
CREATE TEMP TABLE b_origine (membership_id bigint PRIMARY KEY, fichier text);
INSERT INTO b_origine
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

DROP TABLE IF EXISTS pg_temp.b_trou;
CREATE TEMP TABLE b_trou AS
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
       l.valid_to                             AS debut,
       l.from_d                               AS fin,
       round(((l.from_d - l.valid_to) / 365.25)::numeric, 2) AS annees,
       l.membership_id                        AS id_g,
       l.id_d,
       l.unit_id                              AS unit_g,
       l.unit_d,
       coalesce(og.fichier,
                CASE WHEN l.valid_to = DATE '1941-01-01' THEN 'couche 1940'
                     ELSE '?' END)            AS source_g,
       coalesce(od.fichier, '?')              AS source_d
FROM   l
JOIN   atom a ON a.atom_id = l.atom_id
JOIN   unit u ON u.unit_id = l.unit_id AND u.niveau = 'canton'
LEFT   JOIN b_origine og ON og.membership_id = l.membership_id
LEFT   JOIN b_origine od ON od.membership_id = l.id_d
WHERE  l.from_d > l.valid_to
  AND  l.valid_to >= DATE '1941-01-01'
  AND  l.from_d   <= DATE '1968-01-01';
CREATE INDEX ON b_trou (atom_id);

ALTER TABLE b_trou ADD COLUMN fenetre text;
UPDATE b_trou SET fenetre = CASE
    WHEN debut = DATE '1955-01-01' AND fin = DATE '1968-01-01'
         THEN 'A. 1955-1967 (1954 ↔ 1968)'
    WHEN debut = DATE '1941-01-01' AND fin = DATE '1968-01-01'
         THEN 'B. 1941-1967 (1940 ↔ 1968)'
    WHEN fin = DATE '1954-01-01'
         THEN 'refus de 93 (1941-1953)'
    ELSE 'autre' END;

\echo ''
\echo '-- 1. les trous sous 1968, par fenêtre'
SELECT fenetre, count(*) AS trous, count(DISTINCT atom_id) AS atomes,
       round(sum(annees)) AS atome_annees,
       count(*) FILTER (WHERE fraction) AS dont_fractions
FROM   b_trou GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 1 bis. « autre » : dix exemples, pour savoir ce que c''est'
SELECT atom_id, insee, debut, fin, source_g, source_d, unit_g, unit_d
FROM   b_trou WHERE fenetre = 'autre' ORDER BY annees DESC LIMIT 10;

-- La suite ne porte que sur les deux fenêtres qu'un `97` comblerait.
DELETE FROM b_trou WHERE fenetre NOT LIKE 'A.%' AND fenetre NOT LIKE 'B.%';

\echo ''
\echo '-- 2. qui borne les trous : fichier de gauche × fichier de droite'
SELECT fenetre, source_g, source_d, count(*) AS trous,
       round(sum(annees)) AS atome_annees
FROM   b_trou GROUP BY 1, 2, 3 ORDER BY 1, 4 DESC;

-- ---------------------------------------------------------------------------
-- Les témoins de chaque trou
-- ---------------------------------------------------------------------------
ALTER TABLE b_trou
    ADD COLUMN incomparable boolean,
    ADD COLUMN accord       boolean,
    ADD COLUMN nomme_acte   boolean,
    ADD COLUMN annexe       text,
    ADD COLUMN q68          text,
    ADD COLUMN q54          text,
    ADD COLUMN corrige_96   boolean;

UPDATE b_trou SET
    incomparable = left(unit_g, 2) IN ('75', '78')
                OR left(unit_d, 2) IN ('75', '78', '91', '92', '93', '94', '95')
                OR left(unit_g, 2) <> left(unit_d, 2),
    accord = (unit_g = unit_d);

-- Nommée par un acte du registre dans le trou (par son atome ou son code).
UPDATE b_trou t SET nomme_acte = EXISTS (
    SELECT 1 FROM acte_composition c
     WHERE (c.atome = t.atom_id OR c.insee = t.insee)
       AND c.date_acte >= t.debut AND c.date_acte < t.fin);

-- Le canton, à l'un ou l'autre bout, nommé par l'annexe VII dans le trou.
UPDATE b_trou t SET annexe = CASE
    WHEN EXISTS (
        SELECT 1 FROM b_annexe x
         WHERE x.dep = t.dep AND x.date_iso >= t.debut AND x.date_iso < t.fin
           AND (   x.texte_n LIKE '% ' || pg_temp.base_canton(
                     (SELECT v.nom FROM unit_version v WHERE v.unit_id = t.unit_g
                       ORDER BY abs(v.valid_from - t.debut) LIMIT 1)) || ' %'
                OR x.texte_n LIKE '% ' || pg_temp.base_canton(
                     (SELECT v.nom FROM unit_version v WHERE v.unit_id = t.unit_d
                       ORDER BY abs(v.valid_from - t.fin) LIMIT 1)) || ' %'))
         THEN 'a. canton nommé par l''annexe VII'
    WHEN EXISTS (SELECT 1 FROM b_annexe x
                  WHERE x.dep = t.dep AND x.date_iso >= t.debut AND x.date_iso < t.fin)
         THEN 'b. département touché, canton non nommé'
    ELSE      'c. département sans événement' END;

UPDATE b_trou t SET
    q68 = (SELECT q.qualite     FROM c68_qualite q WHERE q.membership_id = t.id_d),
    q54 = (SELECT q.appariement FROM c54_qualite q WHERE q.membership_id = t.id_g),
    corrige_96 = EXISTS (SELECT 1 FROM p96_trace p
                          WHERE p.action = 'corrige'
                            AND p.membership_id IN (t.id_g, t.id_d));

-- ---------------------------------------------------------------------------
-- 3. L'accord, avec son dénominateur
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. l''accord des deux bouts'
\echo '   Dénominateur : trous hors fractions et hors identités incomparables'
\echo '   (Seine, Seine-et-Oise, changement de département).'
SELECT fenetre,
       count(*) FILTER (WHERE incomparable)                     AS incomparables,
       count(*) FILTER (WHERE NOT incomparable)                 AS comparables,
       count(*) FILTER (WHERE NOT incomparable AND accord)      AS accord,
       round(100.0 * count(*) FILTER (WHERE NOT incomparable AND accord)
             / nullif(count(*) FILTER (WHERE NOT incomparable), 0), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. La pente — le test qui décide
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4 a. selon l''annexe VII — l''accord doit chuter en a., pas en c.'
SELECT fenetre, annexe, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT incomparable
GROUP  BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '-- 4 b. selon le registre des actes (maigre avant 1970, cf. en-tête)'
SELECT fenetre, nomme_acte, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT incomparable
GROUP  BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '-- 4 c. selon la qualité des lectures aux deux bouts'
\echo '   (ferme_canton et la couche 1940 ne sont pas indépendants du canton :'
\echo '    à lire, pas à retenir comme preuve)'
SELECT fenetre, coalesce(q54, '(' || source_g || ')') AS bout_gauche,
       coalesce(q68, '(' || source_d || ')') AS bout_droit,
       count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT incomparable
GROUP  BY 1, 2, 3 HAVING count(*) >= 20 ORDER BY 1, 4 DESC;

\echo ''
\echo '-- 4 d. LE CONTRÔLE DE `96` : les bouts qu''il a corrigés s''accordent-ils'
\echo '   autant que les autres ? Nettement moins voudrait dire que la'
\echo '   correction a déplacé l''erreur au lieu de la lever.'
SELECT fenetre, corrige_96, count(*) AS trous,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 2) AS pct_accord
FROM   b_trou WHERE NOT fraction AND NOT incomparable
GROUP  BY 1, 2 ORDER BY 1, 2;

-- ---------------------------------------------------------------------------
-- 5. Les désaccords — mouvements, ou identités qui ont glissé ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.b_paire;
CREATE TEMP TABLE b_paire AS
SELECT unit_g, unit_d, count(*) AS n,
       (SELECT count(*) FROM b_trou t2
         WHERE t2.unit_g = t.unit_g AND NOT t2.fraction) AS n_gauche
FROM   b_trou t
WHERE  NOT fraction AND NOT accord AND NOT incomparable
GROUP  BY 1, 2;

\echo ''
\echo '-- 5 a. les désaccords, classés'
SELECT CASE WHEN p.n >= 3 AND p.n >= 0.8 * p.n_gauche THEN 'en bloc — identité ?'
            WHEN t.annexe LIKE 'a.%' OR t.nomme_acte   THEN 'expliqué par un texte'
            ELSE                                            'isolé, sans texte — à instruire' END
                                                   AS classe,
       count(*)                                    AS trous,
       round(sum(t.annees))                        AS atome_annees
FROM   b_trou t
JOIN   b_paire p ON p.unit_g = t.unit_g AND p.unit_d = t.unit_d
WHERE  NOT t.fraction AND NOT t.accord AND NOT t.incomparable
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 5 b. les vingt plus gros couples en désaccord, nommés'
SELECT p.unit_g, ug.nom AS nom_1954, p.unit_d, ud.nom AS nom_1968,
       p.n AS atomes, p.n_gauche
FROM   b_paire p
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = p.unit_g
                      ORDER BY abs(v.valid_from - DATE '1954-06-01') LIMIT 1) ug ON true
LEFT   JOIN LATERAL (SELECT nom FROM unit_version v WHERE v.unit_id = p.unit_d
                      ORDER BY abs(v.valid_from - DATE '1968-06-01') LIMIT 1) ud ON true
ORDER  BY p.n DESC LIMIT 20;

-- ---------------------------------------------------------------------------
-- 6. Ce que `97` poserait
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. ce qu''un report par les deux bouts poserait, et ce qu''il laisserait'
SELECT fenetre,
       CASE WHEN fraction                  THEN 'fraction'
            WHEN incomparable              THEN 'identités incomparables'
            WHEN NOT accord                THEN 'désaccord — laissé vide'
            WHEN nomme_acte                THEN 'accord mais nommé par un acte — à lire'
            WHEN annexe LIKE 'a.%'         THEN 'accord, canton nommé par l''annexe'
            ELSE                                'accord, aucun texte — posable' END AS verdict,
       count(*)                AS trous,
       count(DISTINCT atom_id) AS atomes,
       round(sum(annees))      AS atome_annees
FROM   b_trou GROUP BY 1, 2 ORDER BY 1, 5 DESC;

\echo ''
\echo '-- 6 bis. les départements, par accord (comparables hors fractions)'
SELECT dep,
       count(*)                                                   AS comparables,
       round(100.0 * count(*) FILTER (WHERE accord) / count(*), 1) AS pct_accord,
       round(sum(annees) FILTER (WHERE accord AND NOT nomme_acte)) AS posable_aa
FROM   b_trou WHERE NOT fraction AND NOT incomparable
GROUP  BY dep ORDER BY 3, 2 DESC LIMIT 25;

\echo ''
\echo '-- 6 ter. contrôle nommé : Lamastre (07129)'
SELECT atom_id, fenetre, source_g, unit_g, source_d, unit_d, accord, annexe, corrige_96
FROM   b_trou WHERE insee = '07129';

\echo ''
\echo '-- fin — rien n''a été écrit. Tables et fonctions temporaires seulement.'

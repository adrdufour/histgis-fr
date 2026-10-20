-- ============================================================================
-- histgis — 120_trous_par_dela_1968.sql : les deux familles de trous que
--           `93`, `95` et `97` ne pouvaient pas voir
--
--   ESSAI (défaut) :  psql -d histgis -f sql/120_trous_par_dela_1968.sql
--   POSE          :  psql -d histgis -v poser=on -f sql/120_trous_par_dela_1968.sql
--   + chaînage large (voir C) : ajouter -v chainage_large=on
--   (depuis la RACINE du dépôt : les \copy sont relatifs au répertoire de lancement)
--
-- Une transaction. Sans `-v poser=on` : tout est calculé, affiché, ROLLBACK.
-- ÉCRIT DANS `membership`, seulement dans des TROUS ; tracé dans `p120_trace` ;
-- le § 1 défait le passage précédent : rejouable seul.
--
-- Écrit le 19 octobre 2026, sur deux exemples d'Adrien : BELLEY (01034), qui
-- n'a aucun canton du 1er janvier 1955 au 15 mars 1998, et CIVRIEUX (01105),
-- qui n'en a aucun du 23 septembre 1973 au 10 mars 1985.
--
-- CE QUE LA BASE DISAIT LE 19 OCTOBRE 2026, AVANT CE FICHIER
-- ==========================================================
-- 8 500 trous cantonaux intérieurs à [1941, 1999], 240 764 atome-années,
-- 8 043 atomes. Trois familles, et deux tiennent à une seule cause :
--
--   A  même canton aux deux bouts, aucun acte lu ne nomme la commune
--        4 844 trous, 171 968 atome-années, 91 départements, QUI TRAVERSENT 1968
--   B  désaccord, un seul acte lu nomme la commune
--        1 363 trous, ~23 600 atome-années
--   C  désaccord, aucun acte lu — la lecture (OCR des jalons, identités)
--        1 426 trous, ~26 000 atome-années — non traités ici
--
-- A — BELLEY. `95` comble [1969, 1999] et `97` [1941, 1967], chacun avec le
-- JALON DE 1968 pour bout. Une commune absente du jalon (ligne non lue, ou
-- jugée absurde par `96`) n'a pas ce bout : son trou va de 1941 ou 1955 jusqu'à
-- 1973-1998, et n'est ENTIÈREMENT dans aucune des deux fenêtres. Aucun des
-- deux fichiers ne le voit. Sept départements manquent presque entiers au
-- jalon de 1968 (76, 77, 71, 61, 74, 72, 73) ; ailleurs ce sont des communes
-- isolées, souvent des chefs-lieux — Belley.
--
-- LA RÈGLE A est celle de `93`, `95` et `97`, sans la fenêtre : mêmes deux
-- bouts, même canton, aucun acte lu ne nomme la commune dans le trou →
-- on pose ce canton. Elle s'applique à TOUT trou intérieur restant, qu'il
-- traverse 1968 ou non (les 159 qui ne le traversent pas sont des bouts posés
-- par `110`/`111`, après `95`).
--
-- `accord_confirme` : même canton aux deux bouts, et les actes lus qui
-- nomment la commune dans le trou la placent TOUS dans ce même canton (un
-- canton recomposé autour d'elle). `95` les rangeait en `accord_nomme`, par
-- crainte d'un aller-retour ; un acte qui la nomme là où elle était déjà n'en
-- est pas un. Restent `accord_nomme` ceux qu'un acte place AILLEURS.
--
-- Garde ajoutée : un même code a servi à deux cantons (7803 : Aulnay-sous-Bois
-- en Seine-et-Oise, puis La Celle-Saint-Cloud dans les Yvelines). « Même
-- unit_id » n'est donc « même canton » que si l'unité porte le même nom aux
-- deux bords — verdict `identite_glissante` sinon.
--
-- B — CIVRIEUX. Bout gauche Trévoux (`81`, arrêté au premier acte de l'Ain,
-- 23 septembre 1973), bout droit Reyrieux à partir du 10 mars 1985, posé par
-- le décret n° 84-1222 qui NOMME Civrieux dans le canton qu'il crée. Le
-- désaccord est expliqué : la commune a quitté Trévoux à cette date. Mais
-- `95` n'arbitre pas un désaccord, et la règle de composition de `110` ne
-- porte que sur ses propres lectures (1949-1968), pas sur le registre.
--
-- LA RÈGLE B (chaînage par l'acte qui ouvre le bout droit) : on pose le canton
-- GAUCHE sur tout le trou si
--   * un seul acte lu nomme la commune dans le trou, et son effet (règle de
--     `75` : premier tour qui suit la signature) EST le début du bout droit ;
--   * le canton que l'acte nomme est celui du bout droit (nom comparé à la
--     date, comme `110`) ;
--   * aucun AUTRE acte du département ne prend effet dans le trou (`110`,
--     moitié gauche) — verdict `chainage_acte`.
-- Pour Civrieux, cette dernière condition ÉCHOUE : le décret n° 82-77 (Bourg,
-- Oyonnax, Montluel, Miribel) prend effet le 14 mars 1982. D'où :
--
-- LA RÈGLE B LARGE, posée SEULEMENT avec `-v chainage_large=on` — c'est un
-- changement de règle, il se décide en le disant. Un acte intermédiaire ne
-- bloque pas si (1) son titre Légifrance nomme ses cantons, (2) TOUS ces
-- cantons ont une composition lue, et (3) aucune ne nomme la commune. La
-- réserve est celle de `diag_titre_composition.sql` : un titre ne nomme pas
-- toujours tous les cantons touchés. Verdict `chainage_acte_large`.
--
-- CE QU'IL NE FAIT PAS
-- ====================
--   * les FRACTIONS et les PSEUDO-CANTONS (comme `95`) ;
--   * la CORSE quand le trou traverse le recodage de 1976 (règle de `95`) ;
--   * les désaccords sans acte (famille C) : de la lecture, département par
--     département ;
--   * les trous où l'acte nomme la commune AU MILIEU (effet < bout droit) :
--     la moitié droite franchirait d'autres actes. Comptés au § 4, `nomme_milieu`.
--
-- Prérequis : `72`, `75` (acte_effet, acte_composition, scrutin_cantonal),
--             `25` (pseudo_canton_trace), et tout ce qui pose des cantons
--             avant lui — `93`, `95`, `97`, `110`, `111`. Il passe APRÈS `111`
--             et AVANT `113`, qui lit les cantons de 1958.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?poser}
\else
\set poser off
\endif
\if :{?chainage_large}
\else
\set chainage_large off
\endif

BEGIN;

DO $$
BEGIN
    IF to_regclass('histgis.acte_effet') IS NULL OR to_regclass('histgis.acte_composition') IS NULL
       OR to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` et `75` (acte_effet, acte_composition, scrutin_cantonal).';
    END IF;
    IF to_regclass('histgis.pseudo_canton_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `25` (pseudo_canton_trace).';
    END IF;
    IF to_regclass('histgis.p95_trace') IS NULL OR to_regclass('histgis.p97_trace') IS NULL
       OR to_regclass('histgis.p110_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `95`, `97` et `110` d''abord — ce fichier comble ce qu''ils laissent.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p120_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m
 USING p120_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;
TRUNCATE p120_trace;

\echo ''
\echo '============================================================'
\echo ' 120 — LES TROUS PAR-DELÀ 1968, ET LE CHAÎNAGE PAR L''ACTE'
\echo '============================================================'
\echo ''
\echo '-- 1. témoins, avant écriture'
SELECT d AS date,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'canton' AND m.periode @> d) AS rattachements
FROM   unnest(ARRAY['1960-06-01','1968-06-01','1975-06-01','1980-06-01','1990-06-01']::date[]) d;

-- ---------------------------------------------------------------------------
-- 2. Les noms : normalisation et comparaison — celles de `110`, à l'identique
-- ---------------------------------------------------------------------------
CREATE FUNCTION pg_temp.k(t text) RETURNS text[]
LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
    s text := upper(coalesce(t, ''));
    r text[] := ARRAY['XIII','13', 'XII','12', 'XI','11', 'IX','9', 'VIII','8', 'VII','7',
                      'VI','6', 'IV','4', 'V','5', 'III','3', 'II','2', 'X','10', 'I','1'];
    i int;
BEGIN
    s := replace(s, 'Œ', 'OE');
    s := translate(s, 'ÀÂÄÁÃÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜŸ''’-.,()',
                      'AAAAACEEEEIIIINOOOOOUUUUY       ');
    s := regexp_replace(s, '\m(LE|LA|LES|L|D|DE|DU|DES|CANTON|SUR|EN|ET)\M', ' ', 'g');
    s := regexp_replace(s, '\mSAINTE?\M', 'ST', 'g');
    FOR i IN 1 .. array_length(r, 1) BY 2 LOOP
        s := regexp_replace(s, '\m' || r[i] || '\M', r[i + 1], 'g');
    END LOOP;
    s := regexp_replace(s, '\m([0-9]+)(ER|EME|E)\M', '\1', 'g');
    RETURN array_remove(string_to_array(btrim(regexp_replace(s, '\s+', ' ', 'g')), ' '), '');
END $f$;

CREATE FUNCTION pg_temp.meme(a text, b text) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
    x text[] := pg_temp.k(a);
    y text[] := pg_temp.k(b);
    q text[] := ARRAY['NORD','SUD','EST','OUEST','CENTRE','NE','NO','SE','SO','CAMPAGNE','VILLE',
                      '1','2','3','4','5','6','7','8','9','10','11','12','13'];
    reste text[];
BEGIN
    IF cardinality(x) = 0 OR cardinality(y) = 0 THEN RETURN false; END IF;
    IF x <@ y AND y <@ x THEN RETURN true; END IF;
    IF x <@ y THEN
        reste := ARRAY(SELECT e FROM unnest(y) e WHERE e <> ALL (x));
    ELSIF y <@ x THEN
        reste := ARRAY(SELECT e FROM unnest(x) e WHERE e <> ALL (y));
    ELSE
        RETURN false;
    END IF;
    RETURN NOT (reste && q);
END $f$;

-- Le nom qu'une unité porte au plus près d'une date : la version qui la
-- couvre, sinon la plus proche ; `unit.nom` faute de version.
CREATE FUNCTION pg_temp.nom_a(u text, d date) RETURNS text
LANGUAGE sql STABLE AS $f$
    SELECT coalesce(
        (SELECT v.nom FROM unit_version v WHERE v.unit_id = u
          ORDER BY CASE WHEN v.periode @> d THEN 0
                        WHEN d < v.valid_from THEN v.valid_from - d
                        ELSE d - v.valid_to + 1 END, v.valid_from
          LIMIT 1),
        (SELECT n.nom FROM unit n WHERE n.unit_id = u AND n.niveau = 'canton'));
$f$;

-- ---------------------------------------------------------------------------
-- 3. Les événements lus : qui nomme quelle commune, à quelle date d'effet
-- ---------------------------------------------------------------------------
-- Le registre (`acte_composition`), à la date d'effet de `75` ; et les
-- lectures de `110`, à SA date d'effet (règle C) — une commune nommée par
-- l'une ou l'autre est « nommée ».
CREATE TEMP TABLE p120_lj_transfert (
    decret text, date date, dep text, commune text, insee text, nom_ref text, appariement text,
    canton_source text, canton_destination text, legifrance_url text, jo text, date_jo date, source text);
\copy p120_lj_transfert FROM 'cantons/transferts_complement.csv' WITH (FORMAT csv, HEADER true)
\copy p120_lj_transfert FROM 'cantons/transferts_tables_jo.csv' WITH (FORMAT csv, HEADER true)
CREATE TEMP TABLE p120_lj_compo (
    jo text, decret text, date date, dep text, canton text, nom_texte text, insee text, nom_ref text,
    dep_insee text, appariement text, attribution text, legifrance_url text);
\copy p120_lj_compo FROM 'cantons/composition_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE p120_scrutin (tour1 date PRIMARY KEY);
INSERT INTO p120_scrutin SELECT tour1 FROM scrutin_cantonal;
INSERT INTO p120_scrutin VALUES ('1945-09-23'), ('1949-03-20'), ('1951-10-07'), ('1955-04-17'), ('1958-04-20')
ON CONFLICT DO NOTHING;

CREATE TEMP TABLE p120_nom AS
SELECT 'registre'::text AS origine, c.dep, c.decret, c.date_acte, c.insee, c.canton,
       (SELECT min(s.tour1) FROM p120_scrutin s WHERE s.tour1 >= c.date_acte) AS effet
FROM   acte_composition c
WHERE  c.insee IS NOT NULL AND c.insee <> ''
UNION ALL
SELECT 'compo_110', c.dep, c.decret, c.date, c.insee, c.canton,
       (SELECT min(s.tour1) FROM p120_scrutin s WHERE s.tour1 >= c.date)
FROM   p120_lj_compo c WHERE c.insee <> ''
UNION ALL
SELECT 'transfert_110', t.dep, t.decret, t.date, t.insee, t.canton_destination, t.date_jo + 1
FROM   p120_lj_transfert t WHERE t.insee <> '';
CREATE INDEX ON p120_nom (insee, effet);

-- Les actes du département, comme `95` les compte (hors actes sans effet),
-- plus les actes du complément de `110` à leur signature.
CREATE TEMP TABLE p120_acte_dep AS
SELECT DISTINCT d.dep, e.date_effet AS quand, e.legifrance_id AS acte
FROM   acte_departement d
JOIN   acte_effet e ON e.legifrance_id = d.legifrance_id
WHERE  e.date_effet IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x WHERE x.legifrance_id = e.legifrance_id)
UNION
SELECT DISTINCT c.dep, c.date, 'compo_110:' || coalesce(c.decret, c.jo)
FROM   p120_lj_compo c;

-- Un acte du registre est LU EN ENTIER, au sens de la règle B large, si son
-- titre nomme des cantons et que chacun a une composition lue sous le même
-- décret. Le complément de `110` n'a pas de titre : jamais « entier ».
--
-- Le nom lu vient de l'OCR du JO, le titre de l'index Légifrance : une lettre
-- de travers (« Oycnnax-Sud » pour OYONNAX-SUD, décret n° 82-77) ne fait pas
-- un canton non lu. Tolérance : même longueur normalisée, UNE lettre
-- différente au plus — une substitution d'OCR, pas un nom voisin.
CREATE FUNCTION pg_temp.proche(a text, b text) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE AS $f$
DECLARE
    x text := array_to_string(pg_temp.k(a), ' ');
    y text := array_to_string(pg_temp.k(b), ' ');
    n int := 0;
    i int;
BEGIN
    IF pg_temp.meme(a, b) THEN RETURN true; END IF;
    IF length(x) <> length(y) OR length(x) < 5 THEN RETURN false; END IF;
    FOR i IN 1 .. length(x) LOOP
        IF substr(x, i, 1) <> substr(y, i, 1) THEN n := n + 1; END IF;
    END LOOP;
    RETURN n <= 1;
END $f$;

CREATE TEMP TABLE p120_acte_entier AS
SELECT k.legifrance_id AS acte
FROM   acte_cantonal k
WHERE  coalesce(btrim(k.cantons_titre), '') <> ''
  AND  NOT EXISTS (
        SELECT 1 FROM unnest(string_to_array(k.cantons_titre, ',')) t(nom)
        WHERE NOT EXISTS (
            SELECT 1 FROM acte_composition c
            WHERE c.date_acte = k.date_signature
              AND c.decret = replace(k.decret, 'n° ', '')
              AND pg_temp.proche(c.canton, btrim(t.nom))));

-- ---------------------------------------------------------------------------
-- 4. Les trous, et le verdict de chacun
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p120_trou AS
WITH l AS (
    SELECT m.atom_id, m.unit_id, m.valid_to,
           lead(m.unit_id)    OVER w AS unit_d,
           lead(m.valid_from) OVER w AS from_d
    FROM   membership m
    WHERE  m.niveau = 'canton'
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT l.atom_id, a.insee_geofla AS insee,
       (a.fraction OR l.atom_id LIKE '%#%') AS fraction,
       trim(u.dep::text) AS dep,
       l.valid_to AS valid_from, l.from_d AS valid_to,
       l.unit_id AS unit_g, l.unit_d
FROM   l
JOIN   atom a ON a.atom_id = l.atom_id
JOIN   unit u ON u.unit_id = l.unit_id AND u.niveau = 'canton'
WHERE  l.from_d > l.valid_to
  AND  l.valid_to >= DATE '1941-01-01'
  AND  l.from_d   <= DATE '1999-01-01';
CREATE INDEX ON p120_trou (atom_id);

ALTER TABLE p120_trou
    ADD COLUMN n_nomme int, ADD COLUMN effet_nomme date, ADD COLUMN canton_nomme text,
    ADD COLUMN n_actes int, ADD COLUMN n_actes_bloquants int,
    ADD COLUMN nom_g text, ADD COLUMN nom_d text, ADD COLUMN verdict text;

UPDATE p120_trou t SET
    n_nomme = (SELECT count(DISTINCT (n.effet, n.canton)) FROM p120_nom n
                WHERE n.insee = t.insee AND n.effet > t.valid_from AND n.effet <= t.valid_to),
    nom_g = pg_temp.nom_a(t.unit_g, t.valid_from - 1),
    nom_d = pg_temp.nom_a(t.unit_d, t.valid_to);
UPDATE p120_trou t SET
    effet_nomme  = n.effet,
    canton_nomme = n.canton
FROM (SELECT DISTINCT ON (x.atom_id, x.valid_from) x.atom_id, x.valid_from, n.effet, n.canton
        FROM p120_trou x JOIN p120_nom n
          ON n.insee = x.insee AND n.effet > x.valid_from AND n.effet <= x.valid_to
       WHERE x.n_nomme = 1
       ORDER BY x.atom_id, x.valid_from, n.origine) n
WHERE n.atom_id = t.atom_id AND n.valid_from = t.valid_from;

-- les actes du département qui prennent effet DANS le trou, hors celui qui
-- ouvre le bout droit ; et ceux d'entre eux qui ne sont pas « lus en entier »
-- ou qui nomment la commune
UPDATE p120_trou t SET
    n_actes = (SELECT count(DISTINCT a.acte) FROM p120_acte_dep a
                WHERE a.dep = t.dep AND a.quand > t.valid_from AND a.quand < t.valid_to),
    n_actes_bloquants = (SELECT count(DISTINCT a.acte) FROM p120_acte_dep a
                WHERE a.dep = t.dep AND a.quand > t.valid_from AND a.quand < t.valid_to
                  AND NOT EXISTS (SELECT 1 FROM p120_acte_entier e WHERE e.acte = a.acte));

UPDATE p120_trou t SET verdict = CASE
    WHEN fraction THEN 'fraction'
    WHEN EXISTS (SELECT 1 FROM pseudo_canton_trace p
                  WHERE p.quoi = 'unit' AND p.cle IN (t.unit_g, t.unit_d)) THEN 'pseudo_canton'
    WHEN (t.unit_g ~ '^20[0-9]{2}$' OR t.unit_d ~ '^2[AB0][0-9]{2}$')
     AND t.valid_from < DATE '1976-01-01' AND t.valid_to > DATE '1976-01-01' THEN 'corse_1976'
    -- A
    WHEN t.unit_g = t.unit_d AND t.n_nomme = 0 AND NOT pg_temp.meme(t.nom_g, t.nom_d)
                                                    THEN 'identite_glissante'
    WHEN t.unit_g = t.unit_d AND t.n_nomme = 0      THEN 'accord'
    WHEN t.unit_g = t.unit_d AND NOT EXISTS (
            SELECT 1 FROM p120_nom n
             WHERE n.insee = t.insee AND n.effet > t.valid_from AND n.effet <= t.valid_to
               AND NOT pg_temp.meme(n.canton, t.nom_d))
     AND pg_temp.meme(t.nom_g, t.nom_d)             THEN 'accord_confirme'
    WHEN t.unit_g = t.unit_d                        THEN 'accord_nomme'
    -- B
    WHEN t.n_nomme = 0                              THEN 'desaccord_sans_acte'
    WHEN t.n_nomme > 1                              THEN 'plusieurs_actes'
    WHEN t.effet_nomme < t.valid_to                 THEN 'nomme_milieu'
    WHEN NOT pg_temp.meme(t.canton_nomme, t.nom_d)  THEN 'acte_autre_canton'
    WHEN t.n_actes = 0                              THEN 'chainage_acte'
    WHEN t.n_actes_bloquants = 0                    THEN 'chainage_acte_large'
    ELSE                                                 'chainage_bloque'
END;

\echo ''
\echo '-- 4. le tamis. Posés : `accord`, `accord_confirme`, `chainage_acte`, et `chainage_acte_large`'
\echo '   avec -v chainage_large=on seulement.'
SELECT verdict, count(*) AS trous, count(DISTINCT atom_id) AS atomes,
       count(DISTINCT dep) AS deps,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees,
       count(*) FILTER (WHERE valid_from <= DATE '1968-06-01' AND valid_to > DATE '1968-06-01')
                                                     AS traversent_1968
FROM   p120_trou GROUP BY 1 ORDER BY 5 DESC;

-- ---------------------------------------------------------------------------
-- 5. Ce qui sera posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p120_pose AS
SELECT atom_id, unit_g AS unit_id, dep, valid_from, valid_to, verdict AS regle, n_actes
FROM   p120_trou
WHERE  verdict IN ('accord', 'accord_confirme', 'chainage_acte')
   OR (verdict = 'chainage_acte_large' AND :'chainage_large'::boolean);

\echo ''
\echo '-- 5. à poser'
SELECT regle, count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS du, max(valid_to) AS au,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p120_pose GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 5 bis. les deux exemples'
SELECT t.atom_id, t.insee, t.nom_g, t.nom_d, t.valid_from, t.valid_to, t.verdict,
       t.canton_nomme, t.effet_nomme, t.n_actes, t.n_actes_bloquants
FROM   p120_trou t WHERE t.insee IN ('01034', '01105');

-- ---------------------------------------------------------------------------
-- 6. Garde-fous — avant d'écrire
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p120_pose GROUP BY atom_id, valid_from HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes à la même date (p. ex. %).', n, ex;
    END IF;
    SELECT count(*), min(p.atom_id) INTO n, ex FROM p120_pose p
     WHERE EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une période occupée (p. ex. %).', n, ex;
    END IF;
    SELECT count(*) INTO n FROM p120_pose WHERE valid_from < '1941-01-01'::date OR valid_to > '1999-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) hors de [1941, 1999].', n;
    END IF;
    -- Seuil : 4 844 accords et quelques centaines de chaînages le 19 octobre
    -- 2026. Un saut veut dire que la sélection a dérivé, pas l'histoire.
    SELECT count(*) INTO n FROM p120_pose;
    IF n > 8000 OR n < 3000 THEN
        RAISE EXCEPTION 'REFUS : % lignes à poser, attendu de l''ordre de 5 000. La sélection a dérivé.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. L'écriture, et la qualité ligne à ligne
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p120_pose
    RETURNING membership_id
)
INSERT INTO p120_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

DROP TABLE IF EXISTS p120_qualite;
CREATE TABLE p120_qualite AS
SELECT m.membership_id, p.atom_id, p.unit_id, p.dep, p.regle, p.n_actes,
       round((p.valid_to - p.valid_from) / 365.25, 2) AS annees_reportees
FROM   p120_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.valid_from = p.valid_from AND m.niveau = 'canton';

-- la file qui reste, pour la lecture département par département
DROP TABLE IF EXISTS p120_reste;
CREATE TABLE p120_reste AS
SELECT t.*, n.nom AS commune
FROM   p120_trou t LEFT JOIN noms_geofla n ON n.insee = t.insee
WHERE  NOT EXISTS (SELECT 1 FROM p120_pose p WHERE p.atom_id = t.atom_id AND p.valid_from = t.valid_from);

\echo ''
\echo '-- 7. témoins après'
SELECT d AS date,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'canton' AND m.periode @> d) AS rattachements
FROM   unnest(ARRAY['1960-06-01','1968-06-01','1975-06-01','1980-06-01','1990-06-01']::date[]) d;

\echo ''
\echo '-- 7 bis. ce qui reste, par département (p120_reste)'
SELECT dep, count(*) AS trous, round(sum((valid_to - valid_from) / 365.25)) AS atome_annees,
       string_agg(DISTINCT verdict, ', ') AS verdicts
FROM   p120_reste GROUP BY 1 ORDER BY 3 DESC LIMIT 30;

\if :poser
\echo '== POSÉ (COMMIT). Défaire : rejouer ce fichier sans poser=on ne défait PAS ; supprimer les lignes de p120_trace.'
COMMIT;
\else
\echo '== ESSAI : rien n''est écrit (ROLLBACK). Pour poser : -v poser=on'
ROLLBACK;
\endif

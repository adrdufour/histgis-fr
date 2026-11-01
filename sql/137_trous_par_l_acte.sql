-- ============================================================================
-- histgis — 137_trous_par_l_acte.sql : les trous que `120` a laissés, suivis
--           acte par acte d'un bout à l'autre ; puis les circonscriptions
--
--   ESSAI (défaut) :  psql -d histgis -f sql/137_trous_par_l_acte.sql
--   POSE          :  psql -d histgis -v poser=on -f sql/137_trous_par_l_acte.sql
--   (depuis la RACINE du dépôt : les \copy sont relatifs au répertoire de lancement)
--
-- Une transaction. Sans `-v poser=on` : tout est calculé, affiché, ROLLBACK.
-- ÉCRIT DANS `membership`, seulement dans des TROUS ; tracé dans `p137_trace`,
-- règle par règle dans `p137_qualite` ; le § 1 défait le passage précédent :
-- rejouable seul. Ce qui reste est dans `p137_reste`, avec son motif.
--
-- Écrit le 26 octobre 2026, à la demande d'Adrien (« corriger les 2 600 trous
-- restants »), après `136` qui en avait relu dix à la main. Mesuré ce jour-là
-- sur la base : 1 976 trous cantonaux intérieurs à [1941, 1999] (les autres de
-- `p120_reste` avaient été comblés depuis par `127`-`136`).
--
-- POURQUOI `120` LES LAISSAIT
-- ===========================
-- `120` pose un trou quand il n'a qu'UNE lecture : même canton aux deux bouts
-- sans acte (règle A), ou un seul acte qui ouvre le bout droit (règle B). Tout
-- le reste allait dans `p120_reste`. Or les dix cas relus pour `136` avaient
-- tous une lecture simple, que `120` ne savait pas faire :
--   * Harly : DEUX actes la nomment, au même canton, au même effet ;
--   * Torvilliers : aucun acte lu ne la nomme, mais le canton d'arrivée
--     (Sainte-Savine) NAÎT au bout droit — elle ne pouvait pas y être avant ;
--   * Portel : un acte la nommait ailleurs… par erreur d'appariement.
--
-- LA RÈGLE : SUIVRE LA COMMUNE D'UN BOUT À L'AUTRE
-- ================================================
-- On part du canton du bout gauche. Chaque acte lu qui NOMME la commune
-- (`acte_composition`, compléments de `110`, rattachements des tables du JO
-- de `cantons/transferts_tables_trous.csv` ; même date d'effet que `120`)
-- la fait passer, à son effet, dans le canton qu'il nomme — reconnu par son
-- nom dans le département (celui du bout droit, du bout gauche, ou une unité
-- unique qui porte ce nom). Arrivé au bout droit, trois cas :
--   * on est dans le canton du bout droit : la chaîne est fermée ;
--   * le canton du bout droit n'a AUCUN autre atome pendant le reste du
--     trou : il naît (ou renaît) au bout droit, la commune y entre à ce
--     moment — `naissance` ;
--   * le canton où l'on est n'a plus aucun autre atome à partir d'une date D
--     du trou : il disparaît en D, la commune passe au bout droit en D —
--     `disparition`.
-- Sinon les deux cantons coexistent et rien de lu ne dit QUAND la commune a
-- changé : non posé, motif `coexistent` (lecture du jalon, transfert non lu).
--
-- Garde d'identité (celle de `120`) : un même code a servi à deux cantons.
-- Quand le canton suivi garde son code mais change de nom d'un bout à l'autre
-- (Crécy-en-Brie → Crécy-la-Chapelle, Soissons → Soissons-Nord), on exige
-- qu'un autre atome au moins y soit aux deux bouts ; sinon `identite_rompue`.
--
-- Ce que la règle accepte, et que `120` refusait : franchir un acte du
-- département dont la composition n'est pas lue. Un décret nomme les
-- communes qu'il déplace ; une commune qu'aucun acte lu ne nomme est
-- présumée rester. La présomption tombe si un acte NON LU l'a déplacée :
-- c'est le risque accepté, et il est compté au § 5 (`actes_non_lus`).
--
-- FRACTIONS : seulement le cas « même canton aux deux bouts » (Castelnaudary).
-- Un acte nomme la ville, pas la fraction : la chaîne n'a pas de sens.
--
-- LES CIRCONSCRIPTIONS (§ 8)
-- ==========================
-- Un trou de canton était aussi un trou de circonscription : `113` et `122`
-- lisent les cantons. Après la pose, pour CHAQUE atome qui a un canton et
-- pas de circonscription dans [1945-01-01, 1986-11-24) — pas seulement ceux
-- de ce fichier —, la circonscription est celle :
--   * 1958-1986 : du canton qu'il avait au 1er décembre 1958 (règle de
--     `113`), si ses autres atomes n'en ont qu'une à cette date ;
--   * sinon, et pour 1945-1958 : celle qu'ont les autres atomes de son
--     canton pendant le trou, si elle est unique.
-- Un canton partagé entre deux circonscriptions ne donne rien.
-- AVANT ces deux règles, dans les départements que `113` n'a pas posés
-- (cantons divisés, ou un canton absent de la lecture), l'atlas lui-même :
-- chaque canton qu'il range dans une seule circonscription — `circo_atlas_partiel`.
-- Les unités de ces circonscriptions sont créées ici et tracées.
-- Les trois règles ne prennent QUE dans le département du canton du trou
-- (la Corse ramenée à 20) — la garde de `113` du 20 octobre 2026. Sans elle,
-- le canton de 1958 d'une commune passée dans un autre département lui
-- rendait la circonscription de l'ancien : Rillieux, les Sathonay, Genay,
-- Montanay dans la 3e de l'Ain jusqu'en 1986, cinq communes cédées par
-- l'Isère dans la 5e de l'Isère, Ytres dans la 5e de la Somme (corrigé le
-- 1er novembre 2026 ; la base l'a été par `141`).
--
-- Prérequis : ceux de `120`, et `120` lui-même. Passe après `136`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?poser}
\else
\set poser off
\endif

BEGIN;

DO $$
BEGIN
    IF to_regclass('histgis.acte_effet') IS NULL OR to_regclass('histgis.acte_composition') IS NULL
       OR to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `72` et `75` (acte_effet, acte_composition, scrutin_cantonal).';
    END IF;
    IF to_regclass('histgis.p120_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : `120` d''abord — ce fichier comble ce qu''il laisse.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p137_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m
 USING p137_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;
DELETE FROM unit_version v
 USING p137_trace t
 WHERE t.quoi = 'version' AND t.cle = v.unit_version_id::text;
DELETE FROM unit u
 USING p137_trace t
 WHERE t.quoi = 'unit' AND t.cle = u.unit_id;
TRUNCATE p137_trace;

\echo ''
\echo '============================================================'
\echo ' 137 — LES TROUS SUIVIS ACTE PAR ACTE, PUIS LES CIRCONSCRIPTIONS'
\echo '============================================================'
\echo ''
\echo '-- 1. témoins, avant écriture'
SELECT d AS date,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'canton' AND m.periode @> d) AS cantons,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'circo'  AND m.periode @> d) AS circos
FROM   unnest(ARRAY['1950-06-01','1960-06-01','1968-06-01','1975-06-01','1980-06-01','1990-06-01']::date[]) d;

-- ===========================================================================
-- § 2 à 4 : REPRIS DE `120` À L'IDENTIQUE (noms, événements lus, trous et
-- verdicts de `120`). Le verdict de `120` n'est gardé que pour le compte
-- rendu : la règle de ce fichier ne s'en sert pas.
-- ===========================================================================

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
                WHERE n.insee = t.insee AND n.effet > t.valid_from AND (n.effet <= t.valid_to OR n.date_acte < t.valid_to)),
    nom_g = pg_temp.nom_a(t.unit_g, t.valid_from - 1),
    nom_d = pg_temp.nom_a(t.unit_d, t.valid_to);
UPDATE p120_trou t SET
    effet_nomme  = n.effet,
    canton_nomme = n.canton
FROM (SELECT DISTINCT ON (x.atom_id, x.valid_from) x.atom_id, x.valid_from, n.effet, n.canton
        FROM p120_trou x JOIN p120_nom n
          ON n.insee = x.insee AND n.effet > x.valid_from AND (n.effet <= x.valid_to OR n.date_acte < x.valid_to)
       WHERE x.n_nomme = 1
       ORDER BY x.atom_id, x.valid_from, n.origine) n
WHERE n.atom_id = t.atom_id AND n.valid_from = t.valid_from;

-- « Nommé dans le trou » : l'effet tombe dans le trou, OU l'acte est signé
-- avant la fin du trou et prend effet après — le bout droit a alors été posé
-- à la date du décret ou de sa parution, et non au scrutin qui suit (`117` :
-- Bourg-Couronne au 1982-01-26 ; `75` dirait 1982-03-14). Vandeins, nommé
-- par le n° 82-77, restait sinon `desaccord_sans_acte` (20 octobre 2026).

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
             WHERE n.insee = t.insee AND n.effet > t.valid_from AND (n.effet <= t.valid_to OR n.date_acte < t.valid_to)
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


-- ===========================================================================
-- FIN DE LA REPRISE DE `120`
-- ===========================================================================

-- Les rattachements des tables du JO dont la commune n'avait pas de canton en
-- base à la date : `transferts_tables.py` ne les convertissait pas, faute de
-- bord gauche (Missy-aux-Bois au canton de Soissons, table de 1950, signalé le
-- 27 octobre 2026). `cantons/transferts_tables_trous.py` les date par la page.
CREATE TEMP TABLE p137_table_trou (LIKE p120_lj_transfert);
\copy p137_table_trou FROM 'cantons/transferts_tables_trous.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO p120_nom
SELECT 'table_trou', t.dep, t.decret, t.date, t.insee, t.canton_destination, t.date_jo + 1
FROM   p137_table_trou t WHERE t.insee <> '';

\echo ''
\echo '-- 4. les trous restants, au tamis de `120`'
SELECT verdict, count(*) AS trous, count(DISTINCT atom_id) AS atomes, count(DISTINCT dep) AS deps,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p120_trou GROUP BY 1 ORDER BY 2 DESC;

-- ---------------------------------------------------------------------------
-- 5. Suivre la commune d'un bout à l'autre
-- ---------------------------------------------------------------------------
-- Le canton qu'un acte nomme : celui du bout droit ou du bout gauche, sinon
-- l'UNIQUE unité du département (des deux, pour la Corse) qui en porte le nom,
-- à n'importe quelle date — les noms datés sont rares en base (1870, 1999),
-- une fenêtre de dates ne trouvait pas « Lisieux-III » sous « Lisieux 3e
-- canton ». Trois essais, du plus sûr au moins sûr, chacun exigeant l'unicité :
-- même nom (`meme`) ; une lettre d'OCR (`proche` : « Fiers-Sud », « Bemay ») ;
-- nom tronqué, au moins huit lettres (« Marange-Silvang »). La fin de phrase
-- que la lecture a parfois collée au nom (« Montbazon il est créé un
-- canton… ») est coupée d'abord.
CREATE TEMP TABLE p137_unom AS
SELECT DISTINCT u.unit_id, trim(u.dep::text) AS dep, x.nom
FROM   unit u
CROSS JOIN LATERAL (SELECT v.nom FROM unit_version v WHERE v.unit_id = u.unit_id
                    UNION SELECT u.nom) x
WHERE  u.niveau = 'canton' AND x.nom IS NOT NULL;
CREATE INDEX ON p137_unom (dep);

CREATE FUNCTION pg_temp.resout(p_nom text, p_date date, p_g text, p_d text,
                               p_nom_g text, p_nom_d text, p_deps text[]) RETURNS text
LANGUAGE plpgsql STABLE AS $f$
DECLARE r text[]; n text; kn text;
BEGIN
    n := regexp_replace(p_nom, '\s+(il|est|qui|et|comprenant|prend|sont|dénommés?)\s.*$', '');
    IF pg_temp.meme(n, p_nom_d) OR pg_temp.meme(n, pg_temp.nom_a(p_d, p_date)) THEN
        RETURN p_d;
    END IF;
    IF pg_temp.meme(n, p_nom_g) OR pg_temp.meme(n, pg_temp.nom_a(p_g, p_date)) THEN
        RETURN p_g;
    END IF;
    SELECT array_agg(DISTINCT x.unit_id) INTO r FROM p137_unom x
     WHERE x.dep = ANY (p_deps) AND pg_temp.meme(x.nom, n);
    IF cardinality(r) = 1 THEN RETURN r[1]; END IF;
    IF cardinality(r) > 1 THEN RETURN NULL; END IF;
    SELECT array_agg(DISTINCT x.unit_id) INTO r FROM p137_unom x
     WHERE x.dep = ANY (p_deps) AND pg_temp.proche(x.nom, n);
    IF cardinality(r) = 1 THEN RETURN r[1]; END IF;
    IF cardinality(r) > 1 THEN RETURN NULL; END IF;
    kn := array_to_string(pg_temp.k(n), ' ');
    IF length(kn) >= 8 THEN
        SELECT array_agg(DISTINCT x.unit_id) INTO r FROM p137_unom x
         WHERE x.dep = ANY (p_deps)
           AND array_to_string(pg_temp.k(x.nom), ' ') LIKE kn || '%';
        IF cardinality(r) = 1 THEN RETURN r[1]; END IF;
    END IF;
    RETURN NULL;
END $f$;

CREATE TEMP TABLE p137_pose (
    atom_id text, unit_id text, dep text, valid_from date, valid_to date,
    regle text, verdict120 text, n_actes int);
CREATE TEMP TABLE p137_juge (
    atom_id text, insee text, dep text, valid_from date, valid_to date,
    unit_g text, unit_d text, nom_g text, nom_d text, verdict120 text,
    pose boolean, regle text, motif text);

DO $$
DECLARE
    t record; e record;
    cur text; d0 date; u text; dd date;
    us text[]; fs date[]; ts date[];
    ok boolean; motif text; regle text; deps text[];
    i int;
BEGIN
    FOR t IN SELECT * FROM p120_trou ORDER BY atom_id, valid_from LOOP
        us := '{}'; fs := '{}'; ts := '{}';
        ok := true; motif := NULL; regle := NULL;
        cur := t.unit_g; d0 := t.valid_from;
        deps := ARRAY[t.dep, (SELECT trim(dep::text) FROM unit WHERE unit_id = t.unit_d AND niveau = 'canton')];

        IF t.verdict = 'pseudo_canton' THEN
            ok := false; motif := 'pseudo_canton';
        ELSIF t.fraction THEN
            IF t.unit_g <> t.unit_d THEN
                ok := false; motif := 'fraction_desaccord';
            ELSE
                regle := 'fraction_meme_canton';
            END IF;
        ELSE
            -- les actes lus qui nomment la commune dans le trou, dans l'ordre
            FOR e IN
                SELECT DISTINCT least(n.effet, t.valid_to) AS eff, n.canton
                  FROM p120_nom n
                 WHERE n.insee = t.insee AND n.effet > t.valid_from
                   AND (n.effet <= t.valid_to OR n.date_acte < t.valid_to)
                 ORDER BY 1, 2
            LOOP
                u := pg_temp.resout(e.canton, e.eff, t.unit_g, t.unit_d, t.nom_g, t.nom_d, deps);
                IF u IS NULL THEN
                    ok := false; motif := 'canton_nomme_introuvable : ' || e.canton; EXIT;
                END IF;
                IF u <> cur THEN
                    IF e.eff > d0 THEN
                        us := us || cur; fs := fs || d0; ts := ts || e.eff;
                    END IF;
                    d0 := e.eff; cur := u;
                END IF;
                regle := 'acte';
            END LOOP;
        END IF;

        IF ok AND cur <> t.unit_d THEN
            IF NOT EXISTS (SELECT 1 FROM membership m
                            WHERE m.unit_id = t.unit_d AND m.niveau = 'canton' AND m.atom_id <> t.atom_id
                              AND m.periode && daterange(d0, t.valid_to, '[)')) THEN
                regle := coalesce(regle || '+', '') || 'naissance';
            ELSE
                SELECT max(least(m.valid_to, t.valid_to)) INTO dd
                  FROM membership m
                 WHERE m.unit_id = cur AND m.niveau = 'canton' AND m.atom_id <> t.atom_id
                   AND m.periode && daterange(d0, t.valid_to, '[)');
                dd := coalesce(dd, d0);
                IF dd < t.valid_to THEN
                    IF dd > d0 THEN
                        us := us || cur; fs := fs || d0; ts := ts || dd;
                    END IF;
                    d0 := dd; cur := t.unit_d;
                    regle := coalesce(regle || '+', '') || 'disparition';
                ELSE
                    ok := false; motif := 'coexistent';
                END IF;
            END IF;
        END IF;

        -- garde d'identité : même code, autre nom, et personne aux deux bouts
        IF ok AND t.unit_g = t.unit_d AND NOT pg_temp.meme(t.nom_g, t.nom_d)
           AND NOT EXISTS (SELECT 1 FROM membership a JOIN membership b
                              ON b.atom_id = a.atom_id AND b.unit_id = a.unit_id AND b.niveau = 'canton'
                           WHERE a.unit_id = t.unit_g AND a.niveau = 'canton' AND a.atom_id <> t.atom_id
                             AND a.periode @> (t.valid_from - 1) AND b.periode @> t.valid_to) THEN
            ok := false; motif := 'identite_rompue';
        END IF;

        IF ok THEN
            IF t.valid_to > d0 THEN
                us := us || cur; fs := fs || d0; ts := ts || t.valid_to;
            END IF;
            regle := coalesce(regle, 'meme_canton');
            FOR i IN 1 .. coalesce(array_length(us, 1), 0) LOOP
                INSERT INTO p137_pose VALUES (t.atom_id, us[i], t.dep, fs[i], ts[i], regle, t.verdict,
                                              t.n_actes_bloquants);
            END LOOP;
        END IF;

        INSERT INTO p137_juge VALUES (t.atom_id, t.insee, t.dep, t.valid_from, t.valid_to,
                                      t.unit_g, t.unit_d, t.nom_g, t.nom_d, t.verdict, ok, regle, motif);
    END LOOP;
END $$;

\echo ''
\echo '-- 5. ce qui sera posé, par règle ; `actes_non_lus` : trous qui franchissent un acte'
\echo '   du département dont la composition n''est pas lue (le risque accepté)'
SELECT regle, count(DISTINCT (atom_id, valid_from)) AS lignes, count(DISTINCT atom_id) AS atomes,
       count(DISTINCT dep) AS deps,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees,
       count(*) FILTER (WHERE n_actes > 0) AS actes_non_lus
FROM   p137_pose GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 5 bis. ce qui reste, par motif (p137_reste)'
SELECT split_part(motif, ' :', 1) AS motif, count(*) AS trous, count(DISTINCT dep) AS deps,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p137_juge WHERE NOT pose GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 5 ter. témoins : Harly, Torvilliers, Portel (déjà posés par 136 : absents) ;'
\echo '   Marnaz, Montois-la-Montagne, Grabels, Bernin, Penchard, Crécy-la-Chapelle, Sainte-Jalle'
SELECT j.insee, n.nom, j.valid_from, j.valid_to, j.nom_g, j.nom_d, j.verdict120, j.regle, j.motif,
       (SELECT string_agg(p.unit_id || ' ' || p.valid_from || '→' || p.valid_to, ', ' ORDER BY p.valid_from)
          FROM p137_pose p WHERE p.atom_id = j.atom_id AND p.valid_from >= j.valid_from
           AND p.valid_to <= j.valid_to) AS pose
FROM   p137_juge j LEFT JOIN noms_geofla n ON n.insee = j.insee
WHERE  j.insee IN ('02371', '10381', '11295', '74169', '57481', '34116', '38039', '77358', '77125', '26306')
ORDER  BY 1, 3;

-- ---------------------------------------------------------------------------
-- 6. Garde-fous — avant d'écrire
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM p137_pose WHERE valid_from >= valid_to;
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % segment(s) vide(s) (p. ex. %).', n, ex; END IF;
    SELECT count(*), min(a.atom_id) INTO n, ex FROM p137_pose a JOIN p137_pose b
        ON b.atom_id = a.atom_id AND (b.valid_from, b.unit_id) <> (a.valid_from, a.unit_id)
       AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % segment(s) qui se chevauchent (p. ex. %).', n, ex; END IF;
    SELECT count(*), min(p.atom_id) INTO n, ex FROM p137_pose p
     WHERE EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = p.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % ligne(s) sur une période occupée (p. ex. %).', n, ex; END IF;
    SELECT count(*) INTO n FROM p137_pose WHERE valid_from < '1941-01-01'::date OR valid_to > '1999-01-01'::date;
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % ligne(s) hors de [1941, 1999].', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 7. L'écriture des cantons
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p137_ins (membership_id bigint, atom_id text, unit_id text, niveau text,
                            valid_from date, regle text, verdict120 text, n_actes int);
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p137_pose
    RETURNING membership_id, atom_id, unit_id, valid_from
)
INSERT INTO p137_ins
SELECT i.membership_id, i.atom_id, i.unit_id, 'canton', i.valid_from, p.regle, p.verdict120, p.n_actes
FROM   ins i JOIN p137_pose p ON p.atom_id = i.atom_id AND p.valid_from = i.valid_from;

-- ---------------------------------------------------------------------------
-- 7 bis. Les MUETS : communes qu'ANR dessine et que la base ne rattache à rien
-- ---------------------------------------------------------------------------
-- Ajouté le 27 octobre 2026, après Missy-aux-Bois. Depuis le bloc « LES
-- MUETS » de `84`, une telle commune reste blanche sur la carte au lieu d'être
-- donnée au voisin ; `sql/diag/diag_communes_muettes.sql` en fait la liste.
-- Deux familles s'y corrigent par règle, sans lecture :
--   * `muet_meme_commune` — DEUX ATOMES POUR UNE COMMUNE. La base rattache le
--     code INSEE à l'un (Vauclerc, absorbé en 1923 par Bouconville) et laisse
--     l'autre (Bouconville même) sans rien depuis 1941. Le muet reçoit, sur
--     son trou, les rattachements de l'UNIQUE autre atome du même code qui en a ;
--   * `muet_jusqu_a_fusion` — LA COMMUNE ABSORBÉE. Son canton s'arrête au jalon
--     (1955) ou au premier acte (1973-09-23) alors qu'ANR la dessine jusqu'à sa
--     fusion (Castillon, noyée en 1948 ; les fusions de 1973-1974) : elle garde
--     son dernier canton jusqu'à la fin de son polygone, si rien ne la rattache
--     ensuite. Sa circonscription suit au § 8.
-- Le reste est fait de vrais trous, déjà comptés plus haut (`p137_reste`).
CREATE TEMP TABLE p137_mgap AS
WITH vie AS (SELECT atom_id,
                    range_agg(periode) * datemultirange(daterange('1941-01-01', '2013-01-01')) AS mr,
                    least(max(upper(periode)), DATE '2013-01-01') AS fin
               FROM atom_geom_anr GROUP BY 1),
rat AS (SELECT split_part(atom_id, '#', 1) AS mere, range_agg(periode) AS mr FROM membership GROUP BY 1)
SELECT v.atom_id, a.insee_geofla, v.fin, unnest(v.mr - coalesce(r.mr, '{}'::datemultirange)) AS p
FROM   vie v JOIN atom a USING (atom_id) LEFT JOIN rat r ON r.mere = v.atom_id
WHERE  NOT a.fraction AND v.atom_id NOT LIKE '%#%';

CREATE TEMP TABLE p137_mpose (atom_id text, unit_id text, niveau text, valid_from date, valid_to date, regle text);

INSERT INTO p137_mpose
SELECT g.atom_id, m.unit_id, m.niveau,
       greatest(lower(g.p), m.valid_from), least(upper(g.p), m.valid_to), 'muet_meme_commune'
FROM   p137_mgap g
JOIN   LATERAL (
        SELECT min(o.atom_id) AS autre FROM atom o
         WHERE o.insee_geofla = g.insee_geofla AND o.atom_id <> g.atom_id
           AND NOT o.fraction AND o.atom_id NOT LIKE '%#%'
           AND EXISTS (SELECT 1 FROM membership x WHERE x.atom_id = o.atom_id AND x.periode && g.p)
        HAVING count(*) = 1) y ON true
JOIN   membership m ON m.atom_id = y.autre AND m.periode && g.p;

INSERT INTO p137_mpose
SELECT g.atom_id, m.unit_id, 'canton', lower(g.p), upper(g.p), 'muet_jusqu_a_fusion'
FROM   p137_mgap g
JOIN   membership m ON m.atom_id = g.atom_id AND m.niveau = 'canton' AND m.valid_to = lower(g.p)
WHERE  upper(g.p) = g.fin
  AND  NOT EXISTS (SELECT 1 FROM p137_mpose x WHERE x.atom_id = g.atom_id);

-- Ajouté le 28 octobre 2026, après Bouconville-Vauclair (02), sans canton de
-- 1941 à 1968 et à Craonne des deux côtés :
--   * `muet_meme_canton_autour` — même canton juste avant et juste après le
--     trou, trou ouvert avant les actes de 1973 (les jalons de 1941, 1954,
--     1968 ne la lisaient pas) : elle n'a pas bougé. Les trous qu'un acte
--     relu contredit (`p137_juge` non posé, le futur `p137_reste`) n'y
--     entrent pas ;
--   * `muet_absorbe` — avant 1941 : une commune absorbée dont le canton
--     s'arrête à la fusion et qu'ANR dessine encore au plus trois ans (Vauclerc,
--     fusionnée en 1921 avec Bouconville, dessinée jusqu'en 1923) reçoit les
--     rattachements de la commune qui la recouvre ensuite. Les trous plus longs
--     d'avant 1941 sont l'Alsace-Moselle allemande et la banlieue de Paris
--     d'avant 1860 : ils ne sont pas des oublis.
WITH can AS (SELECT atom_id, unit_id, valid_from, valid_to FROM membership WHERE niveau = 'canton'
             UNION ALL
             SELECT atom_id, unit_id, valid_from, valid_to FROM p137_mpose WHERE niveau = 'canton'),
reste AS (SELECT g.atom_id,
                 unnest(datemultirange(g.p) - coalesce((SELECT range_agg(daterange(x.valid_from, x.valid_to))
                                                         FROM p137_mpose x WHERE x.atom_id = g.atom_id),
                                                        '{}'::datemultirange)) AS p
            FROM p137_mgap g)
INSERT INTO p137_mpose
SELECT g.atom_id, av.unit_id, 'canton', lower(g.p), upper(g.p), 'muet_meme_canton_autour'
FROM   reste g
JOIN   can av ON av.atom_id = g.atom_id AND av.valid_to = lower(g.p)
JOIN   can ap ON ap.atom_id = g.atom_id AND ap.valid_from = upper(g.p)
WHERE  ap.unit_id = av.unit_id AND lower(g.p) < DATE '1973-09-23'
  AND  NOT EXISTS (SELECT 1 FROM p137_juge r WHERE r.atom_id = g.atom_id AND NOT r.pose
                     AND daterange(r.valid_from, r.valid_to) && g.p);

WITH vie AS (SELECT atom_id, range_agg(periode) * datemultirange(daterange('1815-01-01', '1941-01-01')) AS mr,
                    max(upper(periode)) AS fin
               FROM atom_geom_anr GROUP BY 1),
rat AS (SELECT split_part(atom_id, '#', 1) AS mere, range_agg(periode) AS mr FROM membership GROUP BY 1),
trou AS (SELECT v.atom_id, v.fin, unnest(v.mr - coalesce(r.mr, '{}'::datemultirange)) AS p
           FROM vie v JOIN atom a USING (atom_id) LEFT JOIN rat r ON r.mere = v.atom_id
          WHERE NOT a.fraction AND v.atom_id NOT LIKE '%#%'),
absorbe AS (
    SELECT t.atom_id, t.p,
           (SELECT o.atom_id FROM atom_geom_anr s, atom_geom_anr o
             WHERE s.atom_id = t.atom_id AND upper(s.periode) = t.fin
               AND o.atom_id <> t.atom_id AND o.atom_id NOT LIKE '%#%' AND o.periode @> t.fin
               AND o.geom && s.geom
             ORDER BY ST_Area(ST_Intersection(o.geom, s.geom)) DESC LIMIT 1) AS hote
    FROM trou t
    WHERE upper(t.p) = t.fin AND upper(t.p) - lower(t.p) <= 3 * 366
      AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = t.atom_id AND m.niveau = 'canton'
                     AND m.valid_to = lower(t.p)))
INSERT INTO p137_mpose
SELECT b.atom_id, m.unit_id, m.niveau,
       greatest(lower(b.p), m.valid_from), least(upper(b.p), m.valid_to), 'muet_absorbe'
FROM   absorbe b JOIN membership m ON m.atom_id = b.hote AND m.periode && b.p;

\echo ''
\echo '-- 7 bis. les muets réglés par règle'
SELECT regle, niveau, count(*) AS lignes, count(DISTINCT atom_id) AS atomes,
       round(sum((valid_to - valid_from) / 365.25)) AS atome_annees
FROM   p137_mpose GROUP BY 1, 2 ORDER BY 1, 2;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM p137_mpose
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from
)
INSERT INTO p137_ins
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau, i.valid_from, p.regle, NULL, NULL
FROM   ins i JOIN p137_mpose p ON p.atom_id = i.atom_id AND p.niveau = i.niveau
                             AND p.valid_from = i.valid_from;

-- ---------------------------------------------------------------------------
-- 8. Les circonscriptions : tout atome à canton sans circonscription,
--    [1945-01-01, 1958-01-01) et [1958-01-01, 1986-11-24)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p137_cgap AS
WITH w(wn, w) AS (VALUES ('1945', daterange('1945-01-01', '1958-01-01')),
                         ('1958', daterange('1958-01-01', '1986-11-24'))),
circ AS (SELECT atom_id, range_agg(periode) AS mr FROM membership WHERE niveau = 'circo' GROUP BY 1),
can AS (SELECT m.atom_id, m.unit_id, m.periode * w.w AS p, w.wn
          FROM membership m JOIN w ON m.periode && w.w WHERE m.niveau = 'canton')
SELECT c.atom_id, c.unit_id AS canton, c.wn,
       unnest(datemultirange(c.p) - coalesce(ci.mr, '{}'::datemultirange)) AS p
FROM   can c LEFT JOIN circ ci USING (atom_id);
DELETE FROM p137_cgap WHERE isempty(p);
CREATE INDEX ON p137_cgap (atom_id);

-- Les paires (canton, circonscription) atome par atome, une fois : la
-- jointure latérale directe sur `membership` prenait plus de dix minutes.
CREATE TEMP TABLE p137_cc AS
SELECT o.unit_id AS canton, o.atom_id, c.unit_id AS circo, o.periode * c.periode AS r
FROM   membership o
JOIN   membership c ON c.atom_id = o.atom_id AND c.niveau = 'circo' AND c.periode && o.periode
WHERE  o.niveau = 'canton' AND o.periode && daterange('1945-01-01', '1986-11-24');
CREATE INDEX ON p137_cc (canton);

-- 1958-1986, D'ABORD L'ATLAS, DANS LES DÉPARTEMENTS QUE `113` N'A PAS POSÉS.
-- `113` ne pose un département que si TOUS ses cantons sont lus et qu'aucun
-- n'est divisé (`circo/composition_1958_etat.csv`, `posable`) : un seul canton
-- coupé (Vimy, Houdain) ou manquant (Douai-Nord) laissait le Nord, le
-- Pas-de-Calais, la Gironde… entièrement blancs de 1958 à 1986. Ici, dans
-- ces divisions-là seulement, chaque canton que l'atlas range dans UNE
-- circonscription la donne à ses atomes (règle de `113` : le canton du jour
-- de référence, sinon celui du trou). Les cantons divisés et les cantons
-- absents de la lecture restent blancs. Les unités `<dep>-NN@<depuis>` sont
-- créées ici, tracées (`unit`, `version`).
CREATE TEMP TABLE p137_comp (
    dep text, departement text, depuis int, jusqu int, reference date,
    circonscription text, canton_atlas text, canton_id text, canton_base text, note text);
\copy p137_comp FROM 'circo/composition_1958_1986.csv' WITH (FORMAT csv, HEADER true)
CREATE TEMP TABLE p137_etat (
    dep text, departement text, depuis int, jusqu int, circos int,
    cantons_base int, posable text, raison text, atlas_sans_unite text);
\copy p137_etat FROM 'circo/composition_1958_etat.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE p137_div AS
SELECT DISTINCT c.dep, c.departement, c.depuis, c.reference, c.canton_id,
       daterange(make_date(c.depuis, 1, 1),
                 CASE WHEN c.jusqu = 1986 THEN DATE '1986-11-24' ELSE make_date(c.jusqu, 1, 1) END) AS fen,
       c.dep || '-' || lpad(c.circonscription, 2, '0') || '@' || c.depuis AS circo,
       c.departement || ' ' || c.circonscription
           || CASE WHEN c.circonscription = '1' THEN 're' ELSE 'e' END || ' circonscription' AS nom
FROM   p137_comp c
JOIN   p137_etat e ON e.dep = c.dep AND e.depuis = c.depuis AND e.posable = 'non'
WHERE  c.canton_id <> ''
  AND  NOT EXISTS (SELECT 1 FROM p137_comp x
                    WHERE x.dep = c.dep AND x.depuis = c.depuis AND x.canton_id = c.canton_id
                      AND x.circonscription <> c.circonscription);

CREATE TEMP TABLE p137_cpose (atom_id text, p daterange, wn text, circo text, regle text);

-- Le département de chaque unité, la Corse ramenée à 20 : les trois règles
-- ne prennent que dans celui du canton du trou (garde de `113`).
CREATE TEMP TABLE p137_udep AS
SELECT unit_id, CASE WHEN dep::text IN ('2A', '2B') THEN '20' ELSE dep::text END AS dep
FROM   unit;
CREATE INDEX ON p137_udep (unit_id);

INSERT INTO p137_cpose
SELECT DISTINCT ON (g.atom_id, g.p, d.fen) g.atom_id, g.p * d.fen, g.wn, d.circo, 'circo_atlas_partiel'
FROM   p137_cgap g
JOIN   p137_udep ug ON ug.unit_id = g.canton
LEFT JOIN membership r0 ON r0.atom_id = g.atom_id AND r0.niveau = 'canton'
                       AND r0.periode @> DATE '1958-12-01'
                       AND EXISTS (SELECT 1 FROM p137_udep ur WHERE ur.unit_id = r0.unit_id AND ur.dep = ug.dep)
JOIN   p137_div d ON d.canton_id = coalesce(r0.unit_id, g.canton) AND d.fen && g.p
                 AND CASE WHEN d.dep IN ('2A', '2B') THEN '20' ELSE d.dep END = ug.dep
WHERE  g.wn = '1958'
ORDER  BY g.atom_id, g.p, d.fen;
DELETE FROM p137_cpose WHERE isempty(p);

CREATE TEMP TABLE p137_unit_neuve AS
SELECT DISTINCT d.circo AS unit_id, d.dep, d.depuis, d.nom, d.fen
FROM   p137_div d
WHERE  d.circo IN (SELECT circo FROM p137_cpose)
  AND  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = d.circo);

INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
SELECT unit_id, 'circo', dep, split_part(unit_id, '@', 1), 'uninominal', depuis, nom, false
FROM   p137_unit_neuve;
INSERT INTO p137_trace (quoi, cle) SELECT 'unit', unit_id FROM p137_unit_neuve;
WITH ins AS (
    INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
    SELECT unit_id, nom, lower(fen), upper(fen) FROM p137_unit_neuve
    RETURNING unit_version_id)
INSERT INTO p137_trace (quoi, cle) SELECT 'version', unit_version_id::text FROM ins;

-- 1958-1986, règle de `113` : le canton du 1er décembre 1958, s'il n'a
-- qu'une circonscription à cette date
CREATE TEMP TABLE p137_ref AS
SELECT canton, min(circo) AS circo
FROM   p137_cc WHERE r @> DATE '1958-12-01'
GROUP  BY 1 HAVING count(DISTINCT circo) = 1;

INSERT INTO p137_cpose
SELECT g.atom_id, g.p, g.wn, f.circo, 'circo_canton_1958'
FROM   p137_cgap g
JOIN   membership r0 ON r0.atom_id = g.atom_id AND r0.niveau = 'canton' AND r0.periode @> DATE '1958-12-01'
JOIN   p137_ref f ON f.canton = r0.unit_id
JOIN   p137_udep ug ON ug.unit_id = g.canton
JOIN   p137_udep ur ON ur.unit_id = r0.unit_id AND ur.dep = ug.dep
WHERE  g.wn = '1958'
  AND  NOT EXISTS (SELECT 1 FROM p137_cpose x WHERE x.atom_id = g.atom_id AND x.p && g.p);

-- sinon : les autres atomes du canton, pendant le trou
INSERT INTO p137_cpose
SELECT g.atom_id, g.p, g.wn, r.circo, 'circo_meme_canton'
FROM   p137_cgap g
CROSS JOIN LATERAL (
    SELECT min(c.circo) AS circo FROM p137_cc c
      JOIN p137_udep ux ON ux.unit_id = c.circo
      JOIN p137_udep ug ON ug.unit_id = g.canton AND ug.dep = ux.dep
     WHERE c.canton = g.canton AND c.atom_id <> g.atom_id AND c.r && g.p
    HAVING count(DISTINCT c.circo) = 1) r
WHERE  NOT EXISTS (SELECT 1 FROM p137_cpose x WHERE x.atom_id = g.atom_id AND x.p && g.p);

-- bornée à la vie de l'unité (la Corse de 1958 s'arrête en 1978)
UPDATE p137_cpose x SET p = x.p * v.vie
FROM  (SELECT unit_id, daterange(min(valid_from), max(valid_to)) AS vie
         FROM membership WHERE niveau = 'circo' GROUP BY 1) v
WHERE v.unit_id = x.circo AND x.regle <> 'circo_atlas_partiel';
DELETE FROM p137_cpose WHERE isempty(p);

\echo ''
\echo '-- 8. circonscriptions : trous trouvés, posés par règle, restants'
SELECT g.wn AS fenetre, count(*) AS trous,
       count(*) FILTER (WHERE x.regle = 'circo_atlas_partiel') AS atlas_partiel,
       count(*) FILTER (WHERE x.regle = 'circo_canton_1958') AS canton_1958,
       count(*) FILTER (WHERE x.regle = 'circo_meme_canton') AS meme_canton,
       count(*) FILTER (WHERE x.atom_id IS NULL) AS restent,
       round(sum(upper(g.p) - lower(g.p)) FILTER (WHERE x.atom_id IS NULL) / 365.25) AS atome_annees_restantes
FROM   p137_cgap g LEFT JOIN p137_cpose x ON x.atom_id = g.atom_id AND lower(x.p) >= lower(g.p)
                                         AND upper(x.p) <= upper(g.p)
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '-- 8 bis. circonscriptions restantes, par département (cantons partagés, départements sans 1958)'
SELECT u.dep, count(*) AS trous, round(sum(upper(g.p) - lower(g.p)) / 365.25) AS atome_annees
FROM   p137_cgap g JOIN unit u ON u.unit_id = g.canton
WHERE  NOT EXISTS (SELECT 1 FROM p137_cpose x WHERE x.atom_id = g.atom_id AND x.p && g.p)
GROUP  BY 1 ORDER BY 3 DESC LIMIT 25;

DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(x.atom_id) INTO n, ex FROM p137_cpose x
     WHERE EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = x.atom_id AND m.niveau = 'circo'
                      AND m.periode && x.p);
    IF n > 0 THEN RAISE EXCEPTION 'REFUS : % circonscription(s) sur une période occupée (p. ex. %).', n, ex; END IF;
END $$;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, circo, 'circo', lower(p), upper(p) FROM p137_cpose
    RETURNING membership_id, atom_id, unit_id, valid_from
)
INSERT INTO p137_ins
SELECT i.membership_id, i.atom_id, i.unit_id, 'circo', i.valid_from, x.regle, NULL, NULL
FROM   ins i JOIN p137_cpose x ON x.atom_id = i.atom_id AND lower(x.p) = i.valid_from;

INSERT INTO p137_trace (quoi, cle) SELECT 'membership', membership_id::text FROM p137_ins;

DROP TABLE IF EXISTS p137_qualite;
CREATE TABLE p137_qualite AS SELECT * FROM p137_ins;

DROP TABLE IF EXISTS p137_reste;
CREATE TABLE p137_reste AS
SELECT j.*, n.nom AS commune
FROM   p137_juge j LEFT JOIN noms_geofla n ON n.insee = j.insee
WHERE  NOT j.pose;

\echo ''
\echo '-- 9. témoins après'
SELECT d AS date,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'canton' AND m.periode @> d) AS cantons,
       (SELECT count(*) FROM membership m WHERE m.niveau = 'circo'  AND m.periode @> d) AS circos
FROM   unnest(ARRAY['1950-06-01','1960-06-01','1968-06-01','1975-06-01','1980-06-01','1990-06-01']::date[]) d;

\if :poser
\echo '== POSÉ (COMMIT). Défaire : supprimer les lignes de p137_trace (le § 1 le fait au rejeu).'
COMMIT;
\else
\echo '== ESSAI : rien n''est écrit (ROLLBACK). Pour poser : -v poser=on'
ROLLBACK;
\endif

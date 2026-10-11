-- ============================================================================
-- histgis — 110_pose_lecture_jo.sql : poser dans les TROUS ce que les JO
-- lus le 11 octobre 2026 disent, et rien d'autre
--
--   ESSAI (défaut) :  psql -d histgis -f sql/110_pose_lecture_jo.sql
--   POSE          :  psql -d histgis -v poser=on -f sql/110_pose_lecture_jo.sql
--   (depuis la RACINE du dépôt : les \copy sont relatifs au répertoire de lancement)
--
-- Le fichier tourne dans UNE transaction. Sans `-v poser=on`, il calcule tout,
-- affiche tout, et finit par ROLLBACK : la base n'a pas bougé. Avec, COMMIT.
--
-- ÉCRIT DANS `membership`, et seulement dans des TROUS : un intervalle libre
-- entre deux périodes déjà posées du même atome. Rien n'est écrasé ; la
-- contrainte d'exclusion de `membership` le garantirait de toute façon, et la
-- transaction entière tomberait au premier chevauchement.
--
-- Tout ce qui est écrit est tracé dans `p110_trace` ; le § 1 défait le passage
-- précédent avant de juger : le fichier est rejouable seul.
--
-- LES SOURCES
-- ===========
--   cantons/transferts_complement.csv   13 communes changées de canton, 1946-1969
--   cantons/composition_complement.csv  73 cantons créés ou recomposés, 1949-1968
--   cantons/corse_1975.csv              la Corse entière au 15 mai 1975 (loi 75-356)
--   cantons/transferts_tables_jo.csv    93 communes changées de canton, 1941-1990,
--       datées par les tables analytiques annuelles du JO (cantons/transferts_tables.py).
--       La table nomme la commune, le canton d'ARRIVÉE, l'année, la page, le plus
--       souvent la date du décret ; la date de PARUTION est estimée par la page
--       (contrôle sur 236 actes connus : écart médian 1 jour, 229 à 7 jours au plus).
--       Elle ne nomme pas le canton de départ : la moitié gauche est posée au
--       canton du bord gauche, sur la foi de la table, qui ne signale aucun autre
--       acte pour cette commune entre les deux bords. Nature : `transfert_table`.
-- Lues au JO : cantons/wikipedia/lecture_jo.md. Confrontées à la base, en
-- lecture seule, par sql/diag_lecture_jo.sql.
--
-- LA DATE D'EFFET — règle C, décidée par Adrien le 11 octobre 2026
-- ================================================================
-- Aucun de ces textes ne fixe sa date d'effet. Deux règles, selon la nature de
-- l'acte, comme la note de `77` les distingue déjà :
--   * RATTACHEMENT d'une commune à un autre canton : aucune élection n'est en
--     jeu ; l'acte vaut le lendemain de sa publication au JO (ce que l'INSEE
--     enregistre pour les cas de 1995, et ce que `77` fait pour Laprade) ;
--   * CRÉATION ou RECOMPOSITION de cantons : la carte doit exister au scrutin
--     qui élit ; l'acte vaut au premier tour du renouvellement qui suit
--     (règle de `75`). `scrutin_cantonal` commence en 1961 : les cinq
--     renouvellements de 1945 à 1958 sont ajoutés ICI, dans une table locale,
--     sans toucher à celle de `75`.
-- Les deux sont des CONVENTIONS, marquées comme telles dans `p110_qualite`.
--
-- CE QUI EST POSÉ, PAR LES BORDS DU TROU
-- ======================================
-- Un trou a un bord gauche (le canton de la période qui le précède) et un bord
-- droit (celui de la période qui le suit). L'acte, à sa date d'effet, coupe le
-- trou en deux moitiés. Chaque moitié n'est posée que si un FAIT la porte :
--   * TRANSFERT : moitié gauche au canton du bord gauche si son nom est celui
--     que le JO donne au canton de DÉPART ; moitié droite au canton du bord
--     droit si son nom est celui du canton d'ARRIVÉE ;
--   * COMPOSITION : moitié droite au canton du bord droit si son nom est celui
--     du canton que le JO compose ; moitié gauche au canton du bord gauche si
--     AUCUN autre acte connu (registre ou complément) ne tombe entre le bord
--     gauche et la date d'effet, dans le département ;
--   * CORSE : la loi donne le canton au 15 mai 1975 ; le trou est posé de bord à
--     bord si les deux bords portent le même NUMÉRO que ce canton (la règle du
--     recodage de 1976, celle de `95`), sinon du bord qui s'accorde jusqu'à
--     l'acte cantonal corse le plus proche de 1975 de ce côté. L'identifiant
--     change au 1er janvier 1976 : 20NN avant, 2ANN / 2BNN après.
-- Un atome qui a DEUX actes dans le même trou n'est pas posé : les moitiés se
-- recouvriraient, et l'ordre des deux changements ne se lit pas dans les bords.
--
-- CE QUI N'EST PAS POSÉ, ET POURQUOI C'EST LISTÉ
-- ==============================================
-- Tout le reste — effet hors du trou, nom qui ne s'accorde pas, place occupée,
-- canton corse sans unité connue (Ajaccio, Bastia, Bonifacio) — est compté au
-- § 6. Toussus-le-Noble et Châteaufort y tomberont : la base les garde à
-- Bièvres en 1971, contre le décret du 21 novembre 1969. C'est une période à
-- défaire, pas un trou à remplir, et ce fichier ne défait que ce qu'il a posé.
-- C'est `111_corrige_transferts.sql` qui le fait (11 octobre 2026), pour elles
-- et pour les autres transferts que la base dément ; il passe APRÈS celui-ci.
--
-- Prérequis : `72` (acte_departement), `75` (scrutin_cantonal, acte_effet),
--             et les reports `93`, `95`, `97` joués.
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
    IF to_regclass('histgis.acte_effet') IS NULL OR to_regclass('histgis.scrutin_cantonal') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72 puis sql/75 d''abord (acte_effet, scrutin_cantonal).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p110_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m
 USING p110_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;
TRUNCATE p110_trace;

-- ---------------------------------------------------------------------------
-- 2. Les lectures, et la normalisation des noms de cantons
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE lj_transfert (
    decret text, date date, dep text, commune text, insee text, nom_ref text, appariement text,
    canton_source text, canton_destination text, legifrance_url text, jo text, date_jo date, source text);
\copy lj_transfert FROM 'cantons/transferts_complement.csv' WITH (FORMAT csv, HEADER true)
\copy lj_transfert FROM 'cantons/transferts_tables_jo.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE lj_compo (
    jo text, decret text, date date, dep text, canton text, nom_texte text, insee text, nom_ref text,
    dep_insee text, appariement text, attribution text, legifrance_url text);
\copy lj_compo FROM 'cantons/composition_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE lj_corse (
    dep text, canton_1975 text, nom_texte text, insee text, nom_ref text, appariement text, jo text, acte text);
\copy lj_corse FROM 'cantons/corse_1975.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE lj_acte (
    cle text, date_signature date, date_publication_jo date, decret text, deps text, objet text,
    categorie text, jo text, page_jo text, legifrance_id text, url text, communes_insee text,
    resume text, source text, a_lire text);
\copy lj_acte FROM 'cantons/decrets_complement.csv' WITH (FORMAT csv, HEADER true)

-- Nom de canton -> suite de mots comparables : majuscules sans accents,
-- chiffres romains et ordinaux ramenés au chiffre, mots vides retirés.
-- « Le Havre-III » et « Le Havre 3e canton » donnent tous deux « HAVRE 3 ».
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

-- Même canton ? Mêmes mots ; ou les mots de l'un sont tous dans l'autre, et
-- ce que l'autre a en plus n'est PAS un qualificatif : « Avesnes-Sud » est
-- bien « Avesnes-sur-Helpe-Sud », mais « Lens » n'est pas « Lens-Est ».
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

-- tous les noms qu'une unité a portés
CREATE TEMP VIEW lj_noms AS
SELECT unit_id, nom FROM unit WHERE niveau = 'canton' AND nom IS NOT NULL
UNION
SELECT unit_id, nom FROM unit_version WHERE nom IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 3. La date d'effet (règle C)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE lj_scrutin (tour1 date PRIMARY KEY);
INSERT INTO lj_scrutin SELECT tour1 FROM scrutin_cantonal;
INSERT INTO lj_scrutin VALUES   -- renouvellements des conseils généraux, premiers tours
    ('1945-09-23'), ('1949-03-20'), ('1951-10-07'), ('1955-04-17'), ('1958-04-20')
ON CONFLICT DO NOTHING;

-- les événements : une commune, un acte, une date d'effet, un canton nommé
CREATE TEMP TABLE lj_evt AS
SELECT CASE WHEN t.source LIKE 'table analytique%' THEN 'transfert_table' ELSE 'transfert' END::text AS nature,
       t.jo, t.date AS date_acte, t.dep, t.insee, t.commune AS nom,
       t.canton_source AS canton_avant, t.canton_destination AS canton_apres,
       (t.date_jo + 1) AS effet, 'lendemain de la publication'::text AS regle_effet
FROM   lj_transfert t
UNION ALL
SELECT 'composition', c.jo, c.date, c.dep, c.insee, c.nom_texte, NULL, c.canton,
       (SELECT min(s.tour1) FROM lj_scrutin s WHERE s.tour1 >= c.date),
       'premier tour du renouvellement suivant'
FROM   lj_compo c
WHERE  c.insee <> '' AND c.appariement <> 'fraction seule'
  AND  NOT EXISTS (SELECT 1 FROM lj_transfert t WHERE t.insee = c.insee AND t.date = c.date);

ALTER TABLE lj_evt ADD COLUMN atom_id text;
UPDATE lj_evt e SET atom_id = (SELECT a.atom_id FROM atom a
                                WHERE a.insee_geofla = e.insee AND NOT a.fraction
                                ORDER BY a.atom_id LIMIT 1);

\echo ''
\echo '-- 3. événements lus'
SELECT nature, count(*) AS communes, count(atom_id) AS avec_atome,
       min(effet) AS premier_effet, max(effet) AS dernier_effet
FROM   lj_evt GROUP BY nature;

-- ---------------------------------------------------------------------------
-- 4. Les trous intérieurs, et ceux qui contiennent une date d'effet
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE lj_trou AS
WITH l AS (
    SELECT m.atom_id, m.unit_id, m.valid_from, m.valid_to,
           lag(m.unit_id)  OVER w AS unit_g,
           lag(m.valid_to) OVER w AS g
    FROM   membership m
    WHERE  m.niveau = 'canton'
      AND  m.atom_id IN (SELECT atom_id FROM lj_evt
                         UNION SELECT a.atom_id FROM atom a JOIN lj_corse k ON k.insee = a.insee_geofla
                                WHERE NOT a.fraction)
    WINDOW w AS (PARTITION BY m.atom_id ORDER BY m.valid_from)
)
SELECT atom_id, g AS valid_from, valid_from AS valid_to, unit_g, unit_id AS unit_d
FROM   l WHERE g IS NOT NULL AND g < valid_from;

CREATE TEMP TABLE lj_evt_trou AS
SELECT e.*, h.valid_from AS g, h.valid_to AS d, h.unit_g, h.unit_d
FROM   lj_evt e
LEFT   JOIN lj_trou h ON h.atom_id = e.atom_id AND h.valid_from < e.effet AND e.effet < h.valid_to;

-- deux actes dans le même trou : on n'y touche pas
ALTER TABLE lj_evt_trou ADD COLUMN plusieurs boolean;
UPDATE lj_evt_trou x SET plusieurs = (
    SELECT count(*) > 1 FROM lj_evt_trou y
     WHERE y.atom_id = x.atom_id AND y.g = x.g AND y.d = x.d);

-- les noms aux bords
ALTER TABLE lj_evt_trou ADD COLUMN accord_g boolean, ADD COLUMN accord_d boolean,
                        ADD COLUMN autre_acte_g boolean;
-- Le nom comparé est celui que l'unité porte PENDANT la moitié à poser.
-- Un même code a servi à deux cantons sans rapport (7803 : Aulnay-sous-Bois
-- en Seine-et-Oise, puis La Celle-Saint-Cloud dans les Yvelines) ; comparer à
-- tous ses noms avait fait poser le canton de 1967 sur 1964.
--   * si des versions de l'unité couvrent la moitié, TOUTES doivent porter le
--     nom du JO — une seule qui le contredit, et on ne pose pas ;
--   * si aucune ne la couvre (les versions s'arrêtent souvent en 1940 et
--     reprennent en 1999), on prend la version la plus proche du BORD, celle
--     que la base montre de l'autre côté du trou ;
--   * une unité sans aucune version retombe sur `unit.nom`.
CREATE FUNCTION pg_temp.nomme(u text, de date, a date, bord date, jo text) RETURNS boolean
LANGUAGE plpgsql STABLE AS $f$
DECLARE
    n_couvre int;
    n_accord int;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM unit_version v WHERE v.unit_id = u) THEN
        RETURN EXISTS (SELECT 1 FROM unit n WHERE n.unit_id = u AND n.niveau = 'canton'
                          AND pg_temp.meme(n.nom, jo));
    END IF;
    SELECT count(*), count(*) FILTER (WHERE pg_temp.meme(v.nom, jo))
      INTO n_couvre, n_accord
      FROM unit_version v WHERE v.unit_id = u AND v.periode && daterange(de, a);
    IF n_couvre > 0 THEN
        RETURN n_accord = n_couvre;
    END IF;
    -- Le code a-t-il porté un AUTRE nom juste avant la moitié, depuis 1941 ?
    -- C'est le cas des codes de Seine-et-Oise repris par les Yvelines : 7803
    -- est Aulnay-sous-Bois jusqu'en 1940 et La Celle-Saint-Cloud après 1967 ;
    -- le poser en 1964 sous le second nom serait le confondre avec le premier.
    -- Les versions closes avant 1941 (Belfort sous un code du Haut-Rhin
    -- avant 1871) ne comptent pas.
    IF EXISTS (SELECT 1 FROM unit_version v
                WHERE v.unit_id = u AND v.valid_to <= de AND v.valid_to >= DATE '1941-01-01'
                  AND v.valid_to = (SELECT max(w.valid_to) FROM unit_version w
                                     WHERE w.unit_id = u AND w.valid_to <= de)
                  AND NOT pg_temp.meme(v.nom, jo)) THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM (
            SELECT v.nom,
                   rank() OVER (ORDER BY CASE WHEN v.periode @> bord THEN 0
                                              WHEN bord < v.valid_from THEN v.valid_from - bord
                                              ELSE bord - v.valid_to + 1 END) AS r
            FROM unit_version v WHERE v.unit_id = u) z
        WHERE z.r = 1 AND pg_temp.meme(z.nom, jo));
END $f$;

UPDATE lj_evt_trou x SET
    accord_g = x.canton_avant IS NOT NULL AND x.g IS NOT NULL
               AND pg_temp.nomme(x.unit_g, x.g, x.effet, x.g - 1, x.canton_avant),
    accord_d = x.g IS NOT NULL AND pg_temp.nomme(x.unit_d, x.effet, x.d, x.d, x.canton_apres);

-- Les actes connus, par département : le registre (date d'effet de `75`) et
-- le complément (date de signature, faute de mieux — plus tôt que l'effet,
-- donc plus prudent pour borner).
CREATE TEMP TABLE lj_acte_dep AS
SELECT d.dep, f.date_effet AS quand, f.legifrance_id AS acte
FROM   acte_effet f JOIN acte_departement d ON d.legifrance_id = f.legifrance_id
WHERE  f.date_effet IS NOT NULL
UNION
SELECT unnest(string_to_array(a.deps, ' ')), a.date_signature, a.cle
FROM   lj_acte a
WHERE  a.categorie IN ('composition', 'departement');

-- Moitié gauche : un autre acte entre le bord gauche et l'effet ?
-- Moitié droite : combien d'actes entre l'effet et le bord droit, et le premier ?
-- Un seul acte ne peut pas faire sortir puis rentrer une commune : avec zéro
-- ou un, la moitié droite va jusqu'au bord. Avec deux ou plus, elle s'arrête
-- au premier — la continuité jusque-là est la règle du registre (`79`, `81`).
ALTER TABLE lj_evt_trou ADD COLUMN n_apres int, ADD COLUMN acte_suivant date;
UPDATE lj_evt_trou x SET
    autre_acte_g = x.g IS NOT NULL AND EXISTS (
        SELECT 1 FROM lj_acte_dep a WHERE a.dep = x.dep AND a.quand > x.g AND a.quand < x.date_acte),
    n_apres = (SELECT count(*) FROM lj_acte_dep a
                WHERE a.dep = x.dep AND a.quand > x.effet AND a.quand < x.d),
    acte_suivant = (SELECT min(a.quand) FROM lj_acte_dep a
                     WHERE a.dep = x.dep AND a.quand > x.effet AND a.quand < x.d);

-- ---------------------------------------------------------------------------
-- 5. Ce qui sera posé
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p110_pose (
    atom_id text, unit_id text, valid_from date, valid_to date,
    source text, fondement text, insee text, nom text, date_acte date, effet date, regle_effet text);

-- 5 a. transferts et compositions, moitié par moitié
INSERT INTO p110_pose
SELECT x.atom_id, x.unit_g, x.g, x.effet, x.nature,
       CASE x.nature WHEN 'transfert' THEN 'bord gauche = canton de départ du JO'
                     WHEN 'transfert_table' THEN 'bord gauche = canton de la base avant l''acte (la table ne nomme que l''arrivée)'
                     ELSE 'bord gauche, aucun autre acte avant l''effet' END,
       x.insee, x.nom, x.date_acte, x.effet, x.regle_effet
FROM   lj_evt_trou x
WHERE  x.g IS NOT NULL AND NOT x.plusieurs
  AND  (   (x.nature IN ('transfert', 'transfert_table') AND x.accord_g)
        OR (x.nature = 'composition' AND NOT x.autre_acte_g AND (x.accord_d OR x.unit_g = x.unit_d)))
UNION ALL
SELECT x.atom_id, x.unit_d, x.effet,
       CASE WHEN x.n_apres <= 1 THEN x.d ELSE x.acte_suivant END, x.nature,
       CASE WHEN x.n_apres <= 1 THEN 'bord droit = canton nommé par le JO, jusqu''au bord'
            ELSE 'bord droit = canton nommé par le JO, jusqu''à l''acte suivant' END,
       x.insee, x.nom, x.date_acte, x.effet, x.regle_effet
FROM   lj_evt_trou x
WHERE  x.g IS NOT NULL AND NOT x.plusieurs AND x.accord_d;

-- 5 b. la Corse
CREATE TEMP TABLE lj_corse_unite AS          -- canton de la loi -> unité, par ses communes placées
SELECT k.canton_1975, mode() WITHIN GROUP (ORDER BY m.unit_id) AS unite,
       count(DISTINCT m.unit_id) AS unites
FROM   lj_corse k
JOIN   atom a       ON a.insee_geofla = k.insee AND NOT a.fraction
JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton' AND m.periode @> DATE '1975-05-15'
GROUP  BY k.canton_1975;

CREATE TEMP TABLE lj_corse_trou AS
SELECT k.canton_1975, k.insee, k.nom_texte, a.atom_id, h.valid_from AS g, h.valid_to AS d,
       h.unit_g, h.unit_d, u.unite, u.unites, substr(u.unite, 3) AS num,
       CASE WHEN k.insee LIKE '2A%' THEN '2A' ELSE '2B' END AS dep_1976
FROM   lj_corse k
JOIN   atom a          ON a.insee_geofla = k.insee AND NOT a.fraction
JOIN   lj_trou h       ON h.atom_id = a.atom_id AND h.valid_from <= DATE '1975-05-15' AND DATE '1975-05-15' < h.valid_to
LEFT   JOIN lj_corse_unite u ON u.canton_1975 = k.canton_1975;

-- bornes : l'acte cantonal corse le plus proche de 1975, de chaque côté
CREATE TEMP TABLE lj_corse_acte AS
SELECT f.date_effet
FROM   acte_effet f JOIN acte_departement d ON d.legifrance_id = f.legifrance_id
WHERE  d.dep IN ('20', '2A', '2B') AND f.date_effet IS NOT NULL;

CREATE TEMP TABLE lj_corse_intervalle AS
SELECT t.*,
       (substr(t.unit_g, 3) = t.num AND t.unit_g ~ '^(20|2A|2B)') AS accord_g,
       (substr(t.unit_d, 3) = t.num AND t.unit_d ~ '^(20|2A|2B)') AS accord_d,
       (SELECT max(date_effet) FROM lj_corse_acte WHERE date_effet <= DATE '1975-05-15') AS acte_avant,
       (SELECT min(date_effet) FROM lj_corse_acte WHERE date_effet >  DATE '1975-05-15') AS acte_apres,
       -- un seul acte entre un bord et la loi ne peut pas faire sortir puis
       -- rentrer la commune ; deux le pourraient : on ne pose alors pas ce côté.
       (SELECT count(*) FROM lj_corse_acte WHERE date_effet > t.g AND date_effet <= DATE '1975-05-15') AS n_avant,
       (SELECT count(*) FROM lj_corse_acte WHERE date_effet > DATE '1975-05-15' AND date_effet < t.d) AS n_apres
FROM   lj_corse_trou t
WHERE  t.unites = 1;

UPDATE lj_corse_intervalle SET accord_g = false WHERE accord_g AND n_avant > 1;
UPDATE lj_corse_intervalle SET accord_d = false WHERE accord_d AND n_apres > 1;

CREATE TEMP TABLE lj_corse_pose AS
SELECT i.*,
       CASE WHEN i.accord_g AND i.accord_d THEN i.g
            WHEN i.accord_g                 THEN i.g
            WHEN i.accord_d                 THEN greatest(i.g, i.acte_avant) END AS de,
       CASE WHEN i.accord_g AND i.accord_d THEN i.d
            WHEN i.accord_g                 THEN least(i.d, coalesce(i.acte_apres, i.d))
            WHEN i.accord_d                 THEN i.d END AS a,
       CASE WHEN i.accord_g AND i.accord_d THEN 'les deux bords portent le numéro du canton de la loi'
            WHEN i.accord_g                 THEN 'bord gauche = canton de la loi, jusqu''à l''acte suivant'
            WHEN i.accord_d                 THEN 'bord droit = canton de la loi, depuis l''acte précédent' END AS fondement
FROM   lj_corse_intervalle i
WHERE  i.accord_g OR i.accord_d;

-- coupure au recodage du 1er janvier 1976
INSERT INTO p110_pose
SELECT p.atom_id, '20' || p.num, p.de, least(p.a, DATE '1976-01-01'), 'corse_1975', p.fondement,
       p.insee, p.nom_texte, DATE '1975-05-15', NULL::date, NULL::text
FROM   lj_corse_pose p
WHERE  p.de < least(p.a, DATE '1976-01-01')
  AND  EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = '20' || p.num AND u.niveau = 'canton')
UNION ALL
SELECT p.atom_id, p.dep_1976 || p.num, greatest(p.de, DATE '1976-01-01'), p.a, 'corse_1975', p.fondement,
       p.insee, p.nom_texte, DATE '1975-05-15', NULL::date, NULL::text
FROM   lj_corse_pose p
WHERE  greatest(p.de, DATE '1976-01-01') < p.a
  AND  EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = p.dep_1976 || p.num AND u.niveau = 'canton');

-- 5 c. on ne pose ni intervalle vide, ni unité absente
DELETE FROM p110_pose WHERE valid_from IS NULL OR valid_to IS NULL OR valid_from >= valid_to OR unit_id IS NULL;

-- Les deux moitiés d'un même trou restent deux lignes, même au même canton :
-- elles ne portent pas le même fondement. Seuls les doublons exacts tombent.
CREATE TEMP TABLE p110_pose_f AS
SELECT DISTINCT ON (atom_id, unit_id, valid_from, valid_to)
       row_number() OVER () AS n, *
FROM   p110_pose
ORDER  BY atom_id, unit_id, valid_from, valid_to;

DO $$
DECLARE n bigint;
BEGIN
    -- Deux lignes d'un même atome qui se recouvrent : la construction par
    -- trous ne doit jamais en produire. On s'arrête plutôt que de laisser la
    -- contrainte d'exclusion le dire à mi-chemin.
    SELECT count(*) INTO n FROM p110_pose_f a JOIN p110_pose_f b
      ON a.atom_id = b.atom_id AND a.n < b.n
     AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);
    IF n > 0 THEN RAISE EXCEPTION '% paires de périodes posées se recouvrent : rien n''est écrit.', n; END IF;
END $$;

\echo ''
\echo '-- 5. à poser'
SELECT source, count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       sum(valid_to - valid_from) / 365 AS atome_annees, min(valid_from) AS du, max(valid_to) AS au
FROM   p110_pose_f GROUP BY source ORDER BY source;

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p110_pose_f;
-- la trace, par la clé naturelle (une période par atome et par canton)
INSERT INTO p110_trace (quoi, cle)
SELECT 'membership', m.membership_id::text
FROM   membership m JOIN p110_pose_f p
  ON   p.atom_id = m.atom_id AND p.unit_id = m.unit_id AND m.niveau = 'canton'
 AND   p.valid_from = m.valid_from AND p.valid_to = m.valid_to;

DROP TABLE IF EXISTS p110_qualite;
CREATE TABLE p110_qualite AS
SELECT m.membership_id, p.atom_id, p.insee, p.nom, p.unit_id, p.valid_from, p.valid_to,
       p.source, p.fondement, p.date_acte, p.effet, p.regle_effet,
       (p.regle_effet IS NOT NULL) AS date_conventionnelle
FROM   p110_pose_f p
JOIN   membership m ON m.atom_id = p.atom_id AND m.unit_id = p.unit_id AND m.niveau = 'canton'
                   AND m.valid_from = p.valid_from AND m.valid_to = p.valid_to;

-- ---------------------------------------------------------------------------
-- 6. Ce qui n'est pas posé, et pourquoi
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. transferts et compositions : la raison, commune par commune'
SELECT x.nature,
       CASE WHEN x.atom_id IS NULL                       THEN 'pas d''atome entier pour ce code'
            WHEN x.g IS NULL AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = x.atom_id
                                           AND m.niveau = 'canton' AND m.periode @> x.effet)
                                                          THEN 'place occupée à la date d''effet'
            WHEN x.g IS NULL                              THEN 'pas de trou intérieur à la date d''effet'
            WHEN x.plusieurs                              THEN 'deux actes dans le même trou'
            WHEN NOT x.accord_d AND NOT coalesce(x.accord_g, false)
                                                          THEN 'aucun bord ne porte le nom du JO'
            ELSE 'posé (au moins une moitié)' END        AS issue,
       count(*) AS communes
FROM   lj_evt_trou x
GROUP  BY 1, 2 ORDER BY 1, 3 DESC;

\echo ''
\echo '   le détail, événement par événement : sorties/p110_evenements.csv'
\copy (SELECT x.nature, x.dep, x.insee, x.nom, x.date_acte, x.effet, x.canton_avant, x.canton_apres, x.g, x.d, x.unit_g, (SELECT string_agg(DISTINCT n.nom, ' / ') FROM lj_noms n WHERE n.unit_id = x.unit_g) AS noms_g, x.unit_d, (SELECT string_agg(DISTINCT n.nom, ' / ') FROM lj_noms n WHERE n.unit_id = x.unit_d) AS noms_d, x.accord_g, x.accord_d, x.autre_acte_g, x.n_apres, x.acte_suivant, x.plusieurs, (SELECT m.unit_id FROM membership m WHERE m.atom_id = x.atom_id AND m.niveau = 'canton' AND m.periode @> x.effet LIMIT 1) AS unite_a_l_effet, (SELECT string_agg(DISTINCT n.nom, ' / ') FROM lj_noms n JOIN membership m ON m.unit_id = n.unit_id WHERE m.atom_id = x.atom_id AND m.niveau = 'canton' AND m.periode @> x.effet) AS noms_a_l_effet, EXISTS (SELECT 1 FROM p110_pose_f p WHERE p.atom_id = x.atom_id AND p.source = x.nature) AS pose FROM lj_evt_trou x ORDER BY x.nature, x.dep, x.date_acte, x.nom) TO 'sorties/p110_evenements.csv' WITH (FORMAT csv, HEADER true)
\copy (SELECT atom_id, unit_id, (SELECT string_agg(DISTINCT n.nom, ' / ') FROM lj_noms n WHERE n.unit_id = p.unit_id) AS noms, valid_from, valid_to, source, fondement, insee, nom, date_acte, effet, regle_effet FROM p110_pose_f p ORDER BY source, insee, valid_from) TO 'sorties/p110_pose.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 6 bis. Corse : communes sans canton au 15 mai 1975, et leur sort'
SELECT CASE WHEN t.unite IS NULL   THEN 'canton de la loi sans unité connue (Ajaccio, Bastia, Bonifacio)'
            WHEN t.unites > 1      THEN 'canton de la loi éclaté en base'
            WHEN p.atom_id IS NULL THEN 'aucun bord ne porte le numéro du canton'
            ELSE 'posé' END AS issue,
       count(*) AS communes
FROM   lj_corse_trou t
LEFT   JOIN lj_corse_pose p ON p.atom_id = t.atom_id
GROUP  BY 1 ORDER BY 2 DESC;

-- ---------------------------------------------------------------------------
-- 7. Fin : COMMIT seulement si on l'a demandé
-- ---------------------------------------------------------------------------
\if :poser
\echo ''
\echo '== POSÉ (COMMIT). Défaire : rejouer ce fichier, puis supprimer les lignes de p110_trace.'
COMMIT;
\else
\echo ''
\echo '== ESSAI : rien n''est écrit (ROLLBACK). Pour poser : -v poser=on'
ROLLBACK;
\endif

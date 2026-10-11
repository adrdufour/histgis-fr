-- ============================================================================
-- histgis — 111_corrige_transferts.sql : corriger les périodes que les
-- transferts lus au JO et dans ses tables DÉMENTENT
--
--   ESSAI (défaut) :  psql -d histgis -f sql/111_corrige_transferts.sql
--   CORRECTION     :  psql -d histgis -v poser=on -f sql/111_corrige_transferts.sql
--   DÉFAIRE SEUL   :  psql -d histgis -v defaire=on -f sql/111_corrige_transferts.sql
--   (depuis la RACINE du dépôt : les \copy sont relatifs au répertoire de lancement)
--
-- À jouer APRÈS 110. Une seule transaction : sans `-v poser=on`, tout est
-- calculé, affiché, puis ROLLBACK ; avec, COMMIT.
--
-- POURQUOI
-- ========
-- 110 ne remplit que des trous. Quand la base a déjà une période à la date
-- d'effet d'un transfert (« place occupée »), 110 s'abstient. Ce fichier
-- regarde ces cas-là, et deux seulement :
--
--   A. la base garde la commune dans son canton de DÉPART après l'acte
--      (Toussus-le-Noble et Châteaufort à Bièvres après le décret du
--      21 novembre 1969 ; Milizac à Plabennec après 1971…). La période est
--      COUPÉE à la date d'effet ; la suite est posée au canton d'ARRIVÉE ;
--   B. la base met la commune dans son canton d'ARRIVÉE avant l'acte
--      (Prémontré, Arrans…). La période est RACCOURCIE : elle commence à la
--      date d'effet ; ce qui précède est posé au canton de DÉPART.
--
-- Tout le reste est listé et laissé : période posée par 110 (rien à
-- corriger), base d'accord à la date près, canton de la base qui n'est ni le
-- départ ni l'arrivée (Orgerus, 7815), commune à plusieurs transferts.
--
-- LES BORNES DE CE QUI EST POSÉ
-- =============================
-- Comme 110, la continuité ne se suppose que là où aucun autre acte connu du
-- département (registre `acte_effet`, complément) ne tombe :
--   A. la suite au canton d'arrivée va jusqu'à la fin de l'ancienne période si
--      aucun acte n'y tombe, ou un seul et que la période suivante est déjà au
--      canton d'arrivée ; sinon jusqu'au premier acte. Au-delà : un trou.
--      Un trou est plus juste qu'une période que le JO dément.
--   B. ce qui précède, au canton de départ, part du début de l'ancienne
--      période si aucun acte n'y tombe, ou un seul et que la période
--      précédente est déjà au canton de départ ; sinon du dernier acte avant
--      le transfert. En deçà : un trou.
-- Le canton d'arrivée (A) ou de départ (B) est l'unité voisine si son nom
-- s'accorde, sinon la seule unité du département qui porte ce nom à la date ;
-- s'il n'y en a pas une et une seule, on ne corrige pas.
--
-- Date d'effet : règle C, celle de 110 — le lendemain de la parution. Pour
-- les transferts des tables, la parution est estimée par la page (écart
-- médian d'un jour) : une période qui commence moins de 15 jours avant
-- l'effet estimé est tenue pour d'accord, et laissée.
--
-- TRACE ET RETOUR ARRIÈRE
-- =======================
-- `p111_trace` garde, pour chaque période modifiée, ses bornes d'avant, et
-- l'identifiant de chaque période insérée. Le § 1 rend à la base son état
-- d'avant le passage précédent : le fichier est rejouable seul.
-- ATTENTION : une période modifiée ici peut venir d'un report (79, 81, 93,
-- 95, 97 ; la colonne `provenance` le dit). Rejouer ce report ensuite la
-- remettrait en cause : après un rebuild, 110 puis 111 viennent en dernier.
-- Pour rejouer 110 : défaire 111 d'abord (`-v defaire=on`), jouer 110, puis
-- 111. Sinon 110 peut remplir les trous que 111 a laissés, et le retour
-- arrière de 111 buterait sur eux (la transaction tomberait, sans dommage).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?poser}
\else
\set poser off
\endif
\if :{?defaire}
\else
\set defaire off
\endif

BEGIN;

DO $$
BEGIN
    IF to_regclass('histgis.acte_effet') IS NULL OR to_regclass('histgis.p110_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/75 puis sql/110 d''abord.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p111_trace (
    quoi          text   NOT NULL CHECK (quoi IN ('modifie', 'insere')),
    membership_id bigint NOT NULL,
    ancien_from   date,
    ancien_to     date,
    pose          timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m USING p111_trace t
 WHERE t.quoi = 'insere' AND t.membership_id = m.membership_id;
UPDATE membership m SET valid_from = t.ancien_from, valid_to = t.ancien_to
  FROM p111_trace t
 WHERE t.quoi = 'modifie' AND t.membership_id = m.membership_id;
TRUNCATE p111_trace;
DROP TABLE IF EXISTS p111_qualite;

\if :defaire
\echo '== 111 DÉFAIT (COMMIT) : périodes rendues à leurs bornes d''avant, insertions retirées.'
COMMIT;
\q
\endif

-- ---------------------------------------------------------------------------
-- 2. Les transferts (les deux lectures de 110), les noms
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE c_transfert (
    decret text, date date, dep text, commune text, insee text, nom_ref text, appariement text,
    canton_source text, canton_destination text, legifrance_url text, jo text, date_jo date, source text);
\copy c_transfert FROM 'cantons/transferts_complement.csv' WITH (FORMAT csv, HEADER true)
\copy c_transfert FROM 'cantons/transferts_tables_jo.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE c_acte (
    cle text, date_signature date, date_publication_jo date, decret text, deps text, objet text,
    categorie text, jo text, page_jo text, legifrance_id text, url text, communes_insee text,
    resume text, source text, a_lire text);
\copy c_acte FROM 'cantons/decrets_complement.csv' WITH (FORMAT csv, HEADER true)

-- mêmes fonctions de nom que 110
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

-- le nom que porte l'unité PENDANT [de, a) — règle de 110, voir son § 4
CREATE FUNCTION pg_temp.nomme(u text, de date, a date, bord date, jo text) RETURNS boolean
LANGUAGE plpgsql STABLE AS $f$
DECLARE
    n_couvre int;
    n_accord int;
BEGIN
    IF u IS NULL OR jo IS NULL THEN RETURN false; END IF;
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

-- la seule unité du département qui porte ce nom à cette date, ou NULL
CREATE FUNCTION pg_temp.unite_nommee(d text, jo text, quand date) RETURNS text
LANGUAGE sql STABLE AS $f$
    SELECT CASE WHEN count(*) = 1 THEN min(u.unit_id) END
    FROM   unit u
    WHERE  u.niveau = 'canton' AND u.dep = d
      AND  pg_temp.nomme(u.unit_id, quand, quand + 1, quand, jo);
$f$;

-- d'où vient une période : les tables de qualité des reports et de 110
CREATE FUNCTION pg_temp.provenance(id bigint) RETURNS text
LANGUAGE plpgsql STABLE AS $f$
DECLARE
    t text;
    ok boolean;
    r text := '';
BEGIN
    FOR t IN SELECT c.table_name FROM information_schema.columns c
              WHERE c.table_schema = 'histgis' AND c.column_name = 'membership_id'
                AND c.table_name ~ '^p[0-9]+_qualite$' ORDER BY c.table_name LOOP
        EXECUTE format('SELECT EXISTS (SELECT 1 FROM histgis.%I WHERE membership_id = $1)', t)
           INTO ok USING id;
        IF ok THEN r := r || ' ' || split_part(t, '_', 1); END IF;
    END LOOP;
    RETURN coalesce(nullif(btrim(r), ''), 'base');
END $f$;

-- les actes connus, par département (comme 110)
CREATE TEMP TABLE c_acte_dep AS
SELECT d.dep, f.date_effet AS quand
FROM   acte_effet f JOIN acte_departement d ON d.legifrance_id = f.legifrance_id
WHERE  f.date_effet IS NOT NULL
UNION
SELECT unnest(string_to_array(a.deps, ' ')), a.date_signature
FROM   c_acte a
WHERE  a.categorie IN ('composition', 'departement');

-- ---------------------------------------------------------------------------
-- 3. Les transferts, et la période de la base à leur date d'effet
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE c_evt AS
SELECT CASE WHEN t.source LIKE 'table analytique%' THEN 'transfert_table' ELSE 'transfert' END AS nature,
       t.dep, t.insee, t.commune AS nom, t.date AS date_acte, t.date_jo + 1 AS effet,
       t.canton_source AS canton_avant, t.canton_destination AS canton_apres, t.jo,
       (SELECT a.atom_id FROM atom a WHERE a.insee_geofla = t.insee AND NOT a.fraction
         ORDER BY a.atom_id LIMIT 1) AS atom_id
FROM   c_transfert t;

CREATE TEMP TABLE c_cas AS
SELECT e.*,
       (SELECT count(*) FROM c_evt f WHERE f.atom_id = e.atom_id) > 1 AS plusieurs,
       m.membership_id AS p_id, m.unit_id AS p_unit, m.valid_from AS p_from, m.valid_to AS p_to,
       pg_temp.provenance(m.membership_id) AS provenance
FROM   c_evt e
JOIN   membership m ON m.atom_id = e.atom_id AND m.niveau = 'canton' AND m.periode @> e.effet;

ALTER TABLE c_cas ADD COLUMN cas text;
UPDATE c_cas x SET cas = CASE
    WHEN x.provenance ~ '\mp110\M'  THEN 'posé par 110'
    WHEN x.plusieurs                 THEN 'plusieurs transferts : à la main'
    WHEN pg_temp.nomme(x.p_unit, x.effet, x.p_to, x.effet, x.canton_apres) THEN
         CASE WHEN x.p_from >= x.effet - CASE x.nature WHEN 'transfert_table' THEN 15 ELSE 0 END
              THEN 'base d''accord, à la date près'
              ELSE 'B' END
    WHEN x.p_from < x.effet
     AND pg_temp.nomme(x.p_unit, x.p_from, x.effet, x.effet - 1, x.canton_avant) THEN 'A'
    ELSE 'canton de la base ni départ ni arrivée : à la main' END;

-- ---------------------------------------------------------------------------
-- 4. Les corrections
-- ---------------------------------------------------------------------------
-- A : couper à l'effet ; la suite au canton d'arrivée
CREATE TEMP TABLE c_a AS
SELECT x.*,
       r.unit_id AS r_unit,
       pg_temp.nomme(r.unit_id, x.effet, x.p_to, x.p_to, x.canton_apres) AS r_accord,
       (SELECT count(*) FROM c_acte_dep a WHERE a.dep = x.dep AND a.quand > x.effet AND a.quand < x.p_to) AS n_actes,
       (SELECT min(a.quand) FROM c_acte_dep a WHERE a.dep = x.dep AND a.quand > x.effet AND a.quand < x.p_to) AS acte_suivant
FROM   c_cas x
LEFT   JOIN membership r ON r.atom_id = x.atom_id AND r.niveau = 'canton' AND r.valid_from = x.p_to
WHERE  x.cas = 'A';

-- B : commencer à l'effet ; ce qui précède au canton de départ
CREATE TEMP TABLE c_b AS
SELECT x.*,
       l.unit_id AS l_unit,
       pg_temp.nomme(l.unit_id, x.p_from, x.effet, x.p_from - 1, x.canton_avant) AS l_accord,
       (SELECT count(*) FROM c_acte_dep a WHERE a.dep = x.dep AND a.quand > x.p_from AND a.quand < x.date_acte) AS n_actes,
       (SELECT max(a.quand) FROM c_acte_dep a WHERE a.dep = x.dep AND a.quand > x.p_from AND a.quand < x.date_acte) AS acte_precedent
FROM   c_cas x
LEFT   JOIN membership l ON l.atom_id = x.atom_id AND l.niveau = 'canton' AND l.valid_to = x.p_from
WHERE  x.cas = 'B';

CREATE TEMP TABLE c_action (
    cas text, nature text, dep text, insee text, nom text, date_acte date, effet date, jo text,
    atom_id text, p_id bigint, provenance text, p_unit text, p_from date, p_to date,
    nouveau_from date, nouveau_to date,
    ins_unit text, ins_from date, ins_to date, fondement text, canton_avant text, canton_apres text);

INSERT INTO c_action
SELECT 'A', z.nature, z.dep, z.insee, z.nom, z.date_acte, z.effet, z.jo, z.atom_id, z.p_id, z.provenance,
       z.p_unit, z.p_from, z.p_to,
       z.p_from, z.effet,
       z.u, z.effet,
       CASE WHEN z.n_actes = 0 OR (z.n_actes = 1 AND z.r_accord) THEN z.p_to ELSE z.acte_suivant END,
       CASE WHEN z.n_actes = 0 THEN 'arrivée jusqu''à la fin de l''ancienne période (aucun acte)'
            WHEN z.n_actes = 1 AND z.r_accord THEN 'arrivée jusqu''à la fin de l''ancienne période (un acte, période suivante à l''arrivée)'
            ELSE 'arrivée jusqu''au premier acte du département' END,
       z.canton_avant, z.canton_apres
FROM  (SELECT a.*, CASE WHEN a.r_accord THEN a.r_unit
                        ELSE pg_temp.unite_nommee(a.dep, a.canton_apres, a.effet) END AS u
       FROM c_a a) z
WHERE z.u IS NOT NULL;

INSERT INTO c_action
SELECT 'B', z.nature, z.dep, z.insee, z.nom, z.date_acte, z.effet, z.jo, z.atom_id, z.p_id, z.provenance,
       z.p_unit, z.p_from, z.p_to,
       z.effet, z.p_to,
       z.u,
       CASE WHEN z.n_actes = 0 OR (z.n_actes = 1 AND z.l_accord) THEN z.p_from ELSE z.acte_precedent END,
       z.effet,
       CASE WHEN z.n_actes = 0 THEN 'départ depuis le début de l''ancienne période (aucun acte)'
            WHEN z.n_actes = 1 AND z.l_accord THEN 'départ depuis le début de l''ancienne période (un acte, période précédente au départ)'
            ELSE 'départ depuis le dernier acte du département' END,
       z.canton_avant, z.canton_apres
FROM  (SELECT b.*, CASE WHEN b.l_accord THEN b.l_unit
                        ELSE pg_temp.unite_nommee(b.dep, b.canton_avant, b.effet - 1) END AS u
       FROM c_b b) z
WHERE z.u IS NOT NULL;

-- une insertion vide ne se fait pas, mais la coupe, elle, se fait : la
-- période démentie ne doit pas survivre faute de savoir quoi mettre
UPDATE c_action SET ins_unit = NULL WHERE ins_from IS NULL OR ins_to IS NULL OR ins_from >= ins_to;

\echo ''
\echo '-- 3. les transferts dont la date d''effet tombe dans une période de la base'
SELECT nature, cas, count(*) AS communes FROM c_cas GROUP BY 1, 2 ORDER BY 1, 3 DESC;

\echo ''
\echo '-- 4. corrections, commune par commune'
SELECT a.cas, a.dep, a.nom, a.effet,
       a.p_unit || ' ' || a.p_from || '→' || a.p_to                       AS periode_base,
       a.provenance,
       a.nouveau_from || '→' || a.nouveau_to                              AS devient,
       coalesce(a.ins_unit || ' ' || a.ins_from || '→' || a.ins_to, '—')   AS insere,
       (SELECT u.nom FROM unit u WHERE u.unit_id = a.ins_unit AND u.niveau = 'canton') AS nom_insere
FROM   c_action a ORDER BY a.cas, a.dep, a.nom;

\echo ''
\echo '-- 4 bis. laissés'
SELECT x.cas, x.nature, x.dep, x.nom, x.effet, x.p_unit, x.p_from, x.p_to, x.provenance,
       x.canton_avant, x.canton_apres
FROM   c_cas x
WHERE  x.cas NOT IN ('posé par 110')
  AND  NOT EXISTS (SELECT 1 FROM c_action a WHERE a.p_id = x.p_id)
ORDER  BY x.cas, x.dep, x.nom;
\echo '   cas A ou B dans cette liste : canton d''arrivée (A) ou de départ (B) sans unité unique.'

-- ---------------------------------------------------------------------------
-- 5. Écrire
-- ---------------------------------------------------------------------------
INSERT INTO p111_trace (quoi, membership_id, ancien_from, ancien_to)
SELECT 'modifie', p_id, p_from, p_to FROM c_action;

-- d'abord rétrécir (la place se libère), puis insérer
UPDATE membership m SET valid_from = a.nouveau_from, valid_to = a.nouveau_to
  FROM c_action a WHERE m.membership_id = a.p_id;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, ins_unit, 'canton', ins_from, ins_to FROM c_action WHERE ins_unit IS NOT NULL
    RETURNING membership_id
)
INSERT INTO p111_trace (quoi, membership_id) SELECT 'insere', membership_id FROM ins;

DROP TABLE IF EXISTS p111_qualite;
CREATE TABLE p111_qualite AS
SELECT m.membership_id, a.cas, a.nature, a.insee, a.nom, a.atom_id, m.unit_id, m.valid_from, m.valid_to,
       a.date_acte, a.effet, a.jo, a.fondement,
       'règle C : lendemain de la parution' ||
       CASE a.nature WHEN 'transfert_table' THEN ', parution estimée par la page de la table' ELSE '' END AS regle_effet,
       a.p_id AS periode_corrigee, a.provenance AS provenance_periode_corrigee
FROM   c_action a
JOIN   membership m ON m.atom_id = a.atom_id AND m.unit_id = a.ins_unit AND m.niveau = 'canton'
                   AND m.valid_from = a.ins_from AND m.valid_to = a.ins_to;

\copy (SELECT * FROM c_action ORDER BY cas, dep, nom) TO 'sorties/p111_corrections.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 5. écrit'
SELECT quoi, count(*) FROM p111_trace GROUP BY quoi;

\if :poser
\echo ''
\echo '== CORRIGÉ (COMMIT). Défaire : psql -d histgis -v defaire=on -f sql/111_corrige_transferts.sql'
COMMIT;
\else
\echo ''
\echo '== ESSAI : rien n''est écrit (ROLLBACK). Pour corriger : -v poser=on'
ROLLBACK;
\endif

-- ============================================================================
-- histgis — diag_lecture_jo.sql : ce que la lecture des JO du 11 octobre 2026
-- dit de la base, AVANT qu'on en pose quoi que ce soit
--
--   psql -d histgis -f sql/diag/diag_lecture_jo.sql
--   (depuis la RACINE du dépôt : les \copy sont relatifs au répertoire de lancement)
--
-- LECTURE SEULE. Tables temporaires uniquement.
--
-- Trois lectures, trois questions :
--   cantons/transferts_complement.csv   13 communes changées de canton, 1946-1969 :
--       la base les montre-t-elle dans le canton de départ AVANT l'acte et dans
--       celui d'arrivée APRÈS, ou un trou, ou une période qui enjambe l'acte ?
--   cantons/composition_complement.csv  73 cantons créés ou recomposés, 1949-1968 :
--       deux ans après l'acte, les communes que le JO met ensemble sont-elles
--       ensemble dans la base ?
--   cantons/corse_1975.csv              la Corse entière au 15 mai 1975 :
--       combien de communes la base laisse-t-elle sans canton à cette date
--       (les « trous corses » de 95), et celles qu'elle place, les place-t-elle
--       comme la loi ?
--
-- Sources : cantons/wikipedia/lecture_jo.py, composition_complement.py.
-- ============================================================================

\set ON_ERROR_STOP on

CREATE TEMP TABLE lj_transfert (
    decret text, date date, dep text, commune text, insee text, nom_ref text, appariement text,
    canton_source text, canton_destination text, legifrance_url text, jo text, date_jo date, source text);
\copy lj_transfert FROM 'cantons/transferts_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE lj_compo (
    jo text, decret text, date date, dep text, canton text, nom_texte text, insee text, nom_ref text,
    dep_insee text, appariement text, attribution text, legifrance_url text);
\copy lj_compo FROM 'cantons/composition_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE lj_corse (
    dep text, canton_1975 text, nom_texte text, insee text, nom_ref text, appariement text, jo text, acte text);
\copy lj_corse FROM 'cantons/corse_1975.csv' WITH (FORMAT csv, HEADER true)

-- canton d'un atome entier à une date, avec son nom
CREATE TEMP VIEW lj_canton AS
SELECT a.insee_geofla AS insee, m.valid_from, m.valid_to, m.unit_id, u.nom
FROM   atom a
JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
JOIN   unit u       ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  NOT a.fraction;

-- ---------------------------------------------------------------------------
-- 1. Les treize transferts
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 1. transferts : canton de la base un an avant et deux ans après l''acte'
SELECT t.date, t.dep, t.commune, t.insee,
       t.canton_source      AS jo_avant,
       (SELECT string_agg(c.unit_id || ' ' || coalesce(c.nom, ''), ' | ') FROM lj_canton c
         WHERE c.insee = t.insee AND c.valid_from <= t.date - 365 AND c.valid_to > t.date - 365) AS base_avant,
       t.canton_destination AS jo_apres,
       (SELECT string_agg(c.unit_id || ' ' || coalesce(c.nom, ''), ' | ') FROM lj_canton c
         WHERE c.insee = t.insee AND c.valid_from <= t.date + 730 AND c.valid_to > t.date + 730) AS base_apres,
       (SELECT count(*) FROM lj_canton c
         WHERE c.insee = t.insee AND c.valid_from <= t.date - 365 AND c.valid_to > t.date + 730) AS periode_qui_enjambe
FROM   lj_transfert t
ORDER  BY t.date, t.commune;
\echo '   base_avant / base_apres vides : un trou que l''acte vient expliquer et dater.'
\echo '   periode_qui_enjambe > 0 : la base affirme une immobilité que le JO dément.'

-- ---------------------------------------------------------------------------
-- 2. Les cantons recomposés : leurs communes sont-elles ensemble deux ans après ?
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE lj_compo_base AS
SELECT p.dep, p.canton, p.date, p.insee, p.nom_texte,
       (SELECT c.unit_id FROM lj_canton c
         WHERE c.insee = p.insee AND c.valid_from <= p.date + 730 AND c.valid_to > p.date + 730
         LIMIT 1) AS unit_base
FROM   lj_compo p
WHERE  p.insee <> '' AND p.appariement <> 'fraction seule';

\echo ''
\echo '-- 2. cantons recomposés : unités de la base, deux ans après l''acte'
WITH g AS (
    SELECT b.date, b.dep, b.canton,
           count(*)                                        AS communes_jo,
           count(*) FILTER (WHERE b.unit_base IS NULL)      AS sans_canton_en_base,
           count(DISTINCT b.unit_base)                      AS unites_base,
           mode() WITHIN GROUP (ORDER BY b.unit_base)       AS majoritaire
    FROM   lj_compo_base b
    GROUP  BY b.date, b.dep, b.canton
)
SELECT g.date, g.dep, g.canton, g.communes_jo, g.sans_canton_en_base, g.unites_base,
       g.majoritaire || ' ' || coalesce(u.nom, '') AS unite_majoritaire
FROM   g
LEFT   JOIN unit u ON u.unit_id = g.majoritaire AND u.niveau = 'canton'
ORDER  BY (g.sans_canton_en_base > 0) DESC, g.unites_base DESC, g.date, g.dep, g.canton;
\echo '   Attendu : unites_base = 1 et sans_canton_en_base = 0. Plusieurs unités pour un'
\echo '   même canton du JO : la base a reporté un état antérieur par-dessus l''acte.'

\echo ''
\echo '-- 2 bis. synthèse'
SELECT count(DISTINCT (dep, canton, date))                                   AS cantons,
       count(*)                                                              AS communes,
       count(*) FILTER (WHERE unit_base IS NULL)                             AS communes_sans_canton,
       count(DISTINCT (dep, canton, date)) FILTER (WHERE unit_base IS NULL)  AS cantons_touches_par_un_trou
FROM   lj_compo_base;

-- ---------------------------------------------------------------------------
-- 3. La Corse au 15 mai 1975
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE lj_corse_base AS
SELECT k.dep, k.canton_1975, k.insee, k.nom_texte,
       (SELECT c.unit_id FROM lj_canton c
         WHERE c.insee = k.insee AND c.valid_from <= DATE '1975-05-15' AND c.valid_to > DATE '1975-05-15'
         LIMIT 1) AS unit_base
FROM   lj_corse k;

\echo ''
\echo '-- 3. Corse, 15 mai 1975 : la loi 75-356 contre la base'
SELECT count(*)                                    AS communes_loi,
       count(*) FILTER (WHERE unit_base IS NULL)    AS sans_canton_en_base,
       count(DISTINCT canton_1975)                  AS cantons_loi,
       count(DISTINCT unit_base)                    AS unites_base
FROM   lj_corse_base;

\echo ''
\echo '   par canton de la loi (Ajaccio I-V et Bastia I-IV sont groupés par la loi)'
SELECT k.dep, k.canton_1975,
       count(*)                                      AS communes,
       count(*) FILTER (WHERE k.unit_base IS NULL)    AS sans_canton,
       count(DISTINCT k.unit_base)                    AS unites_base,
       string_agg(DISTINCT k.unit_base, ' ')          AS unites
FROM   lj_corse_base k
GROUP  BY k.dep, k.canton_1975
ORDER  BY sans_canton DESC, unites_base DESC, k.canton_1975;
\echo '   Attendu hors Ajaccio et Bastia : unites_base = 1. sans_canton > 0 : un trou que'
\echo '   la loi comble ; unites_base > 1 : un désaccord à instruire.'

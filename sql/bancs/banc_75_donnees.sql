-- ============================================================================
-- banc_75_donnees.sql — données SYNTHÉTIQUES pour le banc d'essai de `75`
--
-- N'A RIEN À FAIRE DANS LA CHAÎNE. Ce fichier n'est joué que par
-- `sql/bancs/banc_75.sh`, sur une base jetable. Il fabrique le strict minimum dont
-- `72` et `75` ont besoin — `cm_atome`, la couche cantonale de 1999, un jalon
-- de 1968 — à partir des VRAIS fichiers de composition du dépôt.
--
-- Le point n'est pas de reproduire la base : c'est d'exercer CHAQUE CHEMIN de
-- `75`, y compris ceux qu'une base saine ne montrerait jamais. Les
-- perturbations du § 4 sont donc voulues et documentées une par une.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- 1. Les compositions, en table d'appoint (72 les rechargera pour de bon)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE src (
    jo text, decret text, date_acte date, dep text, canton text,
    nom_texte text, insee text, nom_ref text, dep_insee text,
    appariement text, attribution text, url text
);
\copy src FROM 'cantons/composition_jo.csv'         WITH (FORMAT csv, HEADER true)
\copy src FROM 'cantons/composition_legifrance.csv' WITH (FORMAT csv, HEADER true)

DELETE FROM src WHERE insee IS NULL OR insee = '';

-- ---------------------------------------------------------------------------
-- 2. Un atome par commune citée, et `cm_atome` qui les nomme
--
-- Dans la vraie base, `cm_atome` est une UNION ALL de deux voies (directe et
-- par succession) posée par `20_commune_moderne.sql`. Ici, une table suffit :
-- `72` ne lui demande que `code` et `atom_id`.
-- ---------------------------------------------------------------------------
INSERT INTO atom (atom_id, cassini, com_act)
SELECT DISTINCT insee, insee, 1 FROM src
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS cm_atome;
CREATE TABLE cm_atome (code text NOT NULL, atom_id text NOT NULL);
INSERT INTO cm_atome (code, atom_id) SELECT atom_id, atom_id FROM atom;
CREATE INDEX cm_atome_code_idx ON cm_atome (code);

-- ---------------------------------------------------------------------------
-- 3. La couche cantonale de 1999, fabriquée depuis les décrets eux-mêmes
--
-- Chaque canton de décret des deux salves devient une unité de 1999, et ses
-- communes lui sont rattachées sur [1999-01-01, 2013-01-01). Le résultat est
-- volontairement TROP BEAU — c'est la référence dont on s'écarte au § 4.
--
-- Le département de l'unité est celui du code INSEE, pas celui du décret :
-- c'est ainsi que la Corse de 1973 (écrite `20`) se retrouve portée par des
-- unités `2A`/`2B`, et que le banc exerce la normalisation du § 5 de `75`.
-- ---------------------------------------------------------------------------
-- TOUTES les années, et non les deux salves de `75`. La première version du
-- banc se limitait à 1973 et 1982 : `74` et `76` n'y posaient alors presque
-- rien, faute d'unités de 1999 à retrouver, et le banc les déclarait « joués »
-- sans les avoir exercés. *Un banc qui ne fournit pas de cible ne mesure pas
-- un tir.*
CREATE TEMP TABLE cible AS
SELECT DISTINCT s.dep AS dep_acte, s.canton, s.insee FROM src s;

CREATE TEMP TABLE ct AS
SELECT dep_acte, canton,
       -- deux caractères, sinon la contrainte char(2) de `unit` tronque
       -- La Corse est forcée en `2B` : les décrets de 1973 écrivent `20`, et
       -- c'est précisément l'écart que la normalisation de `75` § 5 doit
       -- absorber. Sans ce forçage, le banc ne l'exercerait pas.
       CASE WHEN c.dep_acte IN ('20', '2A', '2B') THEN '2B'
            ELSE coalesce((SELECT mode() WITHIN GROUP (ORDER BY left(c2.insee, 2))
                             FROM cible c2
                            WHERE c2.dep_acte = c.dep_acte
                              AND c2.canton   = c.canton), '99')
       END                                                                    AS dep99,
       'B' || lpad((row_number() OVER (ORDER BY dep_acte, canton))::text, 4, '0') AS unit_id
FROM   (SELECT DISTINCT dep_acte, canton FROM cible) c;

INSERT INTO unit (unit_id, niveau, dep, nom)
SELECT unit_id, 'canton', dep99, canton FROM ct;

-- une commune ne peut appartenir qu'à un canton : quand les deux salves la
-- placent ailleurs, on garde la plus tardive (c'est aussi ce que fait
-- l'histoire, et cela crée de vrais accords partiels pour 1973)
CREATE TEMP TABLE m99 AS
SELECT DISTINCT ON (s.insee) s.insee, t.unit_id
FROM   src s JOIN ct t ON t.dep_acte = s.dep AND t.canton = s.canton
ORDER  BY s.insee, s.date_acte DESC;

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT insee, unit_id, 'canton', DATE '1999-01-01', DATE '2013-01-01' FROM m99;

-- ---------------------------------------------------------------------------
-- 4. LES PERTURBATIONS — une par chemin de refus de `75`
-- ---------------------------------------------------------------------------

-- 4a. « accord partiel » et « désaccord » : on arrache à 1999 une part
--     croissante des communes de deux départements.
DELETE FROM membership m
 USING ct t, cible c
 WHERE m.unit_id = t.unit_id AND c.dep_acte = t.dep_acte AND c.canton = t.canton
   AND m.atom_id = c.insee
   AND t.dep_acte = '35'
   AND ('x' || md5(m.atom_id))::bit(16)::int % 10 < 6;   -- ~60 % arrachés

-- 4b. « collision » : deux cantons du même département renvoyés vers la même
--     unité. C'est ce que produirait un OCR ayant coupé un nom en deux.
UPDATE membership m
   SET unit_id = (SELECT min(unit_id) FROM ct WHERE dep_acte = '44')
 WHERE m.unit_id IN (SELECT unit_id FROM ct WHERE dep_acte = '44'
                     ORDER BY unit_id LIMIT 2);

-- 4c. « département incompatible » : une unité déménage.
UPDATE unit SET dep = '75'
 WHERE unit_id = (SELECT min(unit_id) FROM ct WHERE dep_acte = '01');

-- 4d. « place non libre » : ce que fait `38_decret_1982_ain.sql`, qui pose
--     une ligne du 26 janvier 1982 au 1er janvier 1999 et occuperait donc la
--     période que `75` veut écrire. On reproduit le cas sur dix communes
--     tirées de la salve de 1982 — le § 6 de `75` doit les écarter et les
--     compter, sans échouer.
INSERT INTO unit (unit_id, niveau, dep, nom)
VALUES ('B9999', 'canton', '01', 'Banc — occupant à la façon de sql/38');

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT insee, 'B9999', 'canton', DATE '1982-01-26', DATE '1999-01-01'
FROM   (SELECT DISTINCT s.insee FROM src s
         WHERE  extract(year FROM s.date_acte) = 1982
         ORDER  BY s.insee LIMIT 10) q
WHERE  NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = q.insee AND m.niveau = 'canton'
                      AND m.periode && daterange('1982-01-26','1999-01-01','[)'));

-- ---------------------------------------------------------------------------
-- 5. Un jalon de 1968, pour que le diagnostic du § 8 de `75` ait de quoi lire
--
-- Deux tiers des communes y sont rattachées à leur unité de 1999 (« identité
-- confirmée »), un sixième à une autre unité du même département (« signature
-- d'une création »), le reste absent (« fascicule manquant »).
-- ---------------------------------------------------------------------------
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT m.insee,
       CASE WHEN ('x' || md5('68' || m.insee))::bit(16)::int % 6 = 0
            THEN (SELECT t2.unit_id FROM ct t2
                   WHERE t2.dep99 = (SELECT dep FROM unit WHERE unit_id = m.unit_id)
                     AND t2.unit_id <> m.unit_id ORDER BY t2.unit_id LIMIT 1)
            ELSE m.unit_id END,
       'canton', DATE '1968-01-01', DATE '1969-01-01'
FROM   m99 m
WHERE  ('x' || md5('68' || m.insee))::bit(16)::int % 6 < 5
  AND  CASE WHEN ('x' || md5('68' || m.insee))::bit(16)::int % 6 = 0
            THEN (SELECT t2.unit_id FROM ct t2
                   WHERE t2.dep99 = (SELECT dep FROM unit WHERE unit_id = m.unit_id)
                     AND t2.unit_id <> m.unit_id ORDER BY t2.unit_id LIMIT 1)
            ELSE m.unit_id END IS NOT NULL;

ANALYZE atom; ANALYZE unit; ANALYZE membership; ANALYZE cm_atome;

\echo ''
\echo '-- banc : ce qui a été fabriqué'
SELECT (SELECT count(*) FROM atom)                                   AS atomes,
       (SELECT count(*) FROM unit WHERE niveau = 'canton')           AS unites,
       (SELECT count(*) FROM membership WHERE periode @> DATE '1999-06-01') AS m_1999,
       (SELECT count(*) FROM membership WHERE periode @> DATE '1968-06-01') AS m_1968;

-- ---------------------------------------------------------------------------
-- 6. DE QUOI EXERCER `77` — les cantons d'arrivée des transferts
--
-- Sans cette section, `77` rendait 54 « unité absente de la nomenclature » et
-- 14 « commune sans atome », et posait ZÉRO. Le banc le déclarait pourtant
-- « joué ». C'est la troisième fois qu'il faut lui fournir une cible pour
-- qu'il mesure quelque chose — après la Corse, puis les salves de `76`.
--
-- `77` résout ses cantons d'arrivée par le code `DDNN` de l'INSEE, alors que
-- la couche synthétique du § 3 invente des `Bnnnn`. On crée donc ici les
-- vraies unités nommées par `cantons/transferts_insee.csv`, et on y rattache
-- les communes concernées en 1999 — ce que fait la vraie base par `24`.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE tr (
    dep text, insee text, commune text, canton_arrivee text,
    date_acte date, date_jo date, date_effet date
);
\copy tr FROM 'cantons/transferts_insee.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO unit (unit_id, niveau, dep, nom)
SELECT DISTINCT t.canton_arrivee, 'canton', t.dep,
       'Banc — canton d''arrivée ' || t.canton_arrivee
FROM   tr t
WHERE  NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = t.canton_arrivee);

INSERT INTO atom (atom_id, cassini, com_act)
SELECT DISTINCT t.insee, t.insee, 1 FROM tr t
ON CONFLICT DO NOTHING;
INSERT INTO cm_atome (code, atom_id)
SELECT DISTINCT t.insee, t.insee FROM tr t
WHERE  NOT EXISTS (SELECT 1 FROM cm_atome c WHERE c.code = t.insee);

-- une seule appartenance en 1999, et c'est le canton d'arrivée : c'est ce que
-- le COG dit, et c'est la seconde source que `77` § 4 exige
DELETE FROM membership m
 WHERE m.niveau = 'canton' AND m.periode @> DATE '1999-06-01'
   AND m.atom_id IN (SELECT insee FROM tr);
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT DISTINCT ON (t.insee) t.insee, t.canton_arrivee, 'canton',
       DATE '1999-01-01', DATE '2013-01-01'
FROM   tr t ORDER BY t.insee, t.canton_arrivee;

-- 6a. « le COG 1999 dit un autre canton » : une commune déménage en 1999.
UPDATE membership m SET unit_id = (SELECT min(unit_id) FROM ct)
 WHERE m.niveau = 'canton' AND m.periode @> DATE '1999-06-01'
   AND m.atom_id = (SELECT min(insee) FROM tr);

-- 6b. « commune sans atome » : on en prive une.
DELETE FROM cm_atome WHERE code = (SELECT max(insee) FROM tr);

ANALYZE unit; ANALYZE membership; ANALYZE cm_atome;

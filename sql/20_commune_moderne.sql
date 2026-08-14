-- ============================================================================
-- histgis — 20_commune_moderne.sql : la chronologie communale 1943-2012
--
-- Première brique de la période moderne. Elle ne touche NI `atom` NI
-- `membership` : elle reconstitue, à partir des seuls mouvements INSEE, quelles
-- communes existaient à quelle date, et dit lesquelles se raccordent à un atome
-- existant. Écrire dans le modèle viendra après, quand ces chiffres auront été
-- notés.
--
-- La conception, établie par note_1943_2012.md
-- --------------------------------------------
-- Un seul continuum d'atomes 1870-2012. 2 404 des 2 407 codes de communes
-- disparues entre 1943 et 2011 qui préexistaient à 1943 se raccordent à un
-- atome TRF-GIS — directement pour 1 501, par la fermeture transitive de `06`
-- pour 903 autres (les recodages de 1968 et 1976). Le pont Cassini → INSEE
-- n'a pas à être construit : il passe par le code INSEE.
--
-- La méthode : simuler, puis se faire contredire
-- ----------------------------------------------
-- On ne devine pas l'état de 1943. On part de l'ensemble des codes jamais
-- cités, on retire ceux qui ont un acte de naissance postérieur à 1943, et on
-- SIMULE la chronologie en avant, mouvement par mouvement.
--
-- La simulation est alors vérifiable : l'ensemble des communes vivantes au
-- 1er janvier 2011 doit être exactement celui de GEOFLA 2011. C'est la recette
-- de la section 5, et elle est la raison d'être de cette construction — une
-- chronologie qui ne retombe pas sur la trame est fausse quelque part.
--
-- Les modalités, lues dans le fichier et non supposées
-- ---------------------------------------------------
--   * Les lignes où `com_av = com_ap` sont des TÉMOINS : la commune qui
--     subsiste, restatée. 609 des 1 316 fusions simples en sont. Les traiter
--     comme des mouvements ferait mourir puis renaître la survivante.
--   * `typecom` distingue COM, ARM (arrondissement municipal), COMA (commune
--     associée) et COMD (commune déléguée). Seul COM est une commune. Les 16
--     mod 20 vers ARM sont les arrondissements de Marseille et Lyon : ce ne
--     sont pas des créations de communes.
--   * Disparition d'un code : mod 30, 31, 32, 33, 34.
--   * Recodage — le code change, le territoire non : mod 41 (changement de
--     département, 1968 et 1976 pour l'essentiel) et 50 (transfert de
--     chef-lieu). PIÈGE : les traiter comme une disparition suivie d'une
--     création doublerait le territoire. Ici le code meurt et un autre naît,
--     mais les deux pointent vers LE MÊME atome.
--   * Création : mod 20 et 21 (rétablissement, y compris depuis une COMA).
--   * Sans effet sur l'existence : 10 (nom), 35, 70, 71 (COMA/COMD).
--
-- Prérequis : base chargée, `insee_mvt` peuplée par 06_insee_mvt.sql,
-- `commune_successeur` idem, `geofla_commune` chargée.
-- Lecture seule sur le modèle. Crée ses propres tables `cm_*`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- bornes de la période moderne
\set debut_serie '1943-02-19'
\set fin_serie   '2013-01-01'
\set ancre       '2011-01-01'

DO $$
BEGIN
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE EXCEPTION 'insee_mvt absente : lancer 06_insee_mvt.sql avant.';
    END IF;
    IF to_regclass('histgis.geofla_commune') IS NULL THEN
        RAISE EXCEPTION 'geofla_commune absente : charger GEOFLA avant.';
    END IF;
END $$;

\echo ''
\echo '============================================================'
\echo ' CHRONOLOGIE COMMUNALE 1943-2012'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Les mouvements qui comptent
--
-- On ne garde que ce qui touche l'existence d'un code de commune. Les témoins
-- (com_av = com_ap) sont écartés ici, une bonne fois.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_mvt;
CREATE TABLE cm_mvt AS
SELECT i.mod,
       i.date_eff,
       i.com_av,
       i.com_ap,
       i.libelle_av,
       i.libelle_ap,
       CASE WHEN i.mod IN ('41', '50') THEN 'recodage'
            WHEN i.mod IN ('20', '21') THEN 'creation'
            ELSE                            'disparition'
       END AS effet
FROM   insee_mvt i
WHERE  i.date_eff >= :'debut_serie'::date
  AND  i.date_eff <  :'fin_serie'::date
  AND  i.com_av IS DISTINCT FROM i.com_ap        -- témoins écartés
  AND  i.com_av IS NOT NULL AND i.com_av <> ''
  AND  i.com_ap IS NOT NULL AND i.com_ap <> ''
  AND  i.mod IN ('20', '21', '30', '31', '32', '33', '34', '41', '50')
  -- seule une COM est une commune ; ARM, COMA, COMD ne le sont pas.
  -- Exception assumée : mod 21 depuis une COMA est un rétablissement, le code
  -- d'arrivée est bien une commune.
  AND  i.typecom_ap = 'COM'
  AND  (i.typecom_av = 'COM' OR (i.mod = '21' AND i.typecom_av IN ('COMA', 'COMD')));

CREATE INDEX cm_mvt_av_idx ON cm_mvt (com_av, date_eff);
CREATE INDEX cm_mvt_ap_idx ON cm_mvt (com_ap, date_eff);

\echo ''
\echo '=== 1. Mouvements retenus ==='
SELECT effet, mod, count(*) AS n, min(date_eff) AS du, max(date_eff) AS au
FROM   cm_mvt GROUP BY effet, mod ORDER BY effet, mod;

-- ---------------------------------------------------------------------------
-- 2. Les actes de naissance et de décès
--
-- Un recodage tue le code de départ et fait naître celui d'arrivée : c'est
-- vrai des CODES. Le territoire, lui, ne bouge pas — la section 4 s'en charge
-- en les faisant pointer vers le même atome.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_evt;
CREATE TABLE cm_evt AS
SELECT DISTINCT com_ap AS code, date_eff AS d, 1 AS delta
FROM   cm_mvt WHERE effet IN ('creation', 'recodage')
UNION
SELECT DISTINCT com_av, date_eff, -1
FROM   cm_mvt WHERE effet IN ('disparition', 'recodage');

-- l'univers : tout code jamais cité comme commune, plus la trame 2011
DROP TABLE IF EXISTS cm_univers;
CREATE TABLE cm_univers AS
SELECT DISTINCT code FROM (
    SELECT com_av AS code FROM cm_mvt
    UNION SELECT com_ap FROM cm_mvt
    UNION SELECT insee_com FROM geofla_commune
) u;

ALTER TABLE cm_univers ADD PRIMARY KEY (code);

-- Présent au 19 février 1943 ?
--
-- Le critère n'est PAS « ce code n'a pas d'acte de naissance ». Une commune
-- qui existait en 1943, a fusionné en 1965 et a été rétablie en 1975 a bien un
-- acte de naissance — celui de 1975 —, et l'exclure lui ferait perdre sa
-- première vie. C'est l'erreur du premier jet : 246 communes de GEOFLA
-- disparaissaient de la simulation, soit à peu près les 248 rétablissements.
--
-- Le bon critère : **le premier événement du code est un décès**. On ne meurt
-- que si l'on était vivant. Un code sans aucun événement était là depuis 1943
-- et n'en est jamais parti.
INSERT INTO cm_evt (code, d, delta)
SELECT u.code, :'debut_serie'::date, 1
FROM   cm_univers u
WHERE  NOT EXISTS (SELECT 1 FROM cm_evt e WHERE e.code = u.code)
   OR  (SELECT e.delta FROM cm_evt e
         WHERE e.code = u.code
         ORDER BY e.d, e.delta          -- à date égale, le décès d'abord
         LIMIT 1) = -1;

CREATE INDEX cm_evt_idx ON cm_evt (code, d);

\echo ''
\echo '=== 2. Univers et événements ==='
SELECT (SELECT count(*) FROM cm_univers)                              AS codes_univers,
       (SELECT count(*) FROM cm_evt WHERE delta =  1)                 AS naissances,
       (SELECT count(*) FROM cm_evt WHERE delta = -1)                 AS deces,
       (SELECT count(*) FROM cm_evt
         WHERE delta = 1 AND d = :'debut_serie'::date)                AS presents_en_1943;

-- ---------------------------------------------------------------------------
-- 3. Recollage en intervalles d'existence
--
-- Somme courante des deltas : l'intervalle s'ouvre quand elle passe de 0 à 1,
-- se ferme quand elle retombe à 0. Un code peut vivre plusieurs fois — fusionné
-- puis rétabli — et le motif le gère sans cas particulier.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_commune;
CREATE TABLE cm_commune AS
WITH e AS (
    SELECT code, d, delta,
           sum(delta) OVER (PARTITION BY code ORDER BY d, delta DESC
                            ROWS UNBOUNDED PRECEDING) AS etat
    FROM   cm_evt
),
bornes AS (
    -- on ne garde que les bascules : ouverture (0 → 1) et fermeture (1 → 0)
    SELECT code, d, delta,
           row_number() OVER (PARTITION BY code ORDER BY d, delta DESC) AS rang
    FROM   e
    WHERE  (delta =  1 AND etat = 1)
       OR  (delta = -1 AND etat = 0)
),
paires AS (
    SELECT code, d AS valid_from, delta,
           lead(d) OVER (PARTITION BY code ORDER BY rang) AS valid_to
    FROM   bornes
)
SELECT code,
       valid_from,
       coalesce(valid_to, :'fin_serie'::date) AS valid_to
FROM   paires
WHERE  delta = 1
  AND  valid_from < coalesce(valid_to, :'fin_serie'::date);

ALTER TABLE cm_commune ADD PRIMARY KEY (code, valid_from);
CREATE INDEX cm_commune_periode_idx ON cm_commune
    USING gist (daterange(valid_from, valid_to, '[)'));

\echo ''
\echo '=== 3. Intervalles d''existence ==='
\echo '    `vies_multiples` doit être NON NUL : il y a 248 rétablissements dans'
\echo '    le fichier, donc autant de communes qui ont vécu deux fois. Une'
\echo '    valeur nulle signale que les premières vies ont été perdues.'
SELECT count(*)                                       AS intervalles,
       count(DISTINCT code)                           AS codes,
       count(*) FILTER (WHERE valid_from > :'debut_serie'::date) AS nes_apres_1943,
       count(*) FILTER (WHERE valid_to  < :'fin_serie'::date)    AS morts_avant_2013,
       count(*) - count(DISTINCT code)                AS vies_multiples
FROM   cm_commune;

\echo ''
\echo '--- effectif communal à quelques dates ---'
\echo '    Repères publiés : ~38 000 communes en 1943, 36 569 en 2011.'
SELECT d::date AS date, count(*) AS communes
FROM   (VALUES ('1943-03-01'), ('1962-01-01'), ('1968-04-01'),
               ('1975-01-01'), ('1990-01-01'), ('1999-03-08'),
               ('2011-01-01'), ('2012-12-31')) AS t(d)
JOIN   cm_commune c ON daterange(c.valid_from, c.valid_to, '[)') @> d::date
GROUP  BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 4. Le raccord : quel atome porte ce territoire ?
--
-- Deux voies, dans cet ordre. Directe : un atome dont `insee_geofla` est ce
-- code. Par succession : la fermeture transitive de `06` mène du code à un
-- code de 2011, dont un atome porte le polygone — c'est elle qui résout les
-- recodages de 1968 et 1976.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_atome;
CREATE TABLE cm_atome AS
WITH direct AS (
    SELECT DISTINCT c.code, a.atom_id, 'direct'::text AS voie
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   atom a ON a.insee_geofla = c.code
),
par_succession AS (
    SELECT DISTINCT c.code, a.atom_id, 'succession'::text
    FROM   (SELECT DISTINCT code FROM cm_commune) c
    JOIN   commune_successeur s ON s.insee_ancien = c.code
    JOIN   atom a ON a.insee_geofla = s.insee_2011
    WHERE  NOT EXISTS (SELECT 1 FROM atom a2 WHERE a2.insee_geofla = c.code)
)
SELECT * FROM direct UNION ALL SELECT * FROM par_succession;

CREATE INDEX cm_atome_idx ON cm_atome (code);

\echo ''
\echo '=== 4. Raccord au continuum d''atomes ==='
WITH r AS (
    SELECT c.code,
           (SELECT count(*)                    FROM cm_atome x WHERE x.code = c.code) AS n,
           (SELECT min(x.voie)                 FROM cm_atome x WHERE x.code = c.code) AS voie
    FROM   (SELECT DISTINCT code FROM cm_commune) c
)
SELECT CASE WHEN n = 0 THEN '0 - aucun atome : a creer'
            WHEN n = 1 THEN '1 - atome unique (' || voie || ')'
            ELSE            'n - plusieurs atomes sur ce code'
       END          AS situation,
       count(*)     AS codes
FROM   r GROUP BY 1 ORDER BY 1;

\echo ''
\echo '--- la voie croisée avec l''ancienneté du code ---'
\echo '    C''est ici que se cache la seule affirmation fragile. Pour un code'
\echo '    PRÉEXISTANT à 1943, la voie `succession` est solide : elle suit un'
\echo '    recodage ou une fusion, le territoire est le même ou l''englobe.'
\echo '    Pour un code NÉ après 1943 puis disparu, elle l''est beaucoup moins :'
\echo '    l''atome trouvé est celui de la commune qui l''a absorbé, donc TROP'
\echo '    GRAND — la fille n''était qu''une fraction de ce polygone. Même limite'
\echo '    de trame qu''au § 6.1 de METHODE.md, et même remède : ANR-COMMUNES.'
SELECT x.voie,
       count(*) FILTER (WHERE p.debut =  :'debut_serie'::date) AS code_de_1943,
       count(*) FILTER (WHERE p.debut <> :'debut_serie'::date) AS ne_apres_1943,
       count(*) FILTER (WHERE p.debut <> :'debut_serie'::date
                          AND p.fin  <   :'fin_serie'::date)   AS ne_puis_disparu
FROM   (SELECT code, min(valid_from) AS debut, max(valid_to) AS fin
        FROM   cm_commune GROUP BY code) p
JOIN   (SELECT code, min(voie) AS voie FROM cm_atome GROUP BY code) x USING (code)
GROUP  BY x.voie ORDER BY 1;

\echo ''
\echo '    `ne_puis_disparu` par la voie `succession` est le chiffre à retenir :'
\echo '    ce sont les seuls codes dont le rattachement géométrique est'
\echo '    surdimensionné. À déclarer comme limite, pas à corriger.'

\echo ''
\echo '--- les codes sans atome : préexistaient-ils à 1943 ? ---'
\echo '    Un code né après 1943 et sans atome est attendu (247 selon la note).'
\echo '    Un code présent dès 1943 et sans atome est une anomalie à expliquer.'
SELECT c.valid_from = :'debut_serie'::date AS present_des_1943,
       count(DISTINCT c.code)              AS codes
FROM   cm_commune c
WHERE  NOT EXISTS (SELECT 1 FROM cm_atome x WHERE x.code = c.code)
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- les 25 plus gros codes sans atome présents dès 1943 (anomalies) ---'
SELECT DISTINCT c.code, c.valid_from, c.valid_to,
       (SELECT m.libelle_av FROM cm_mvt m WHERE m.com_av = c.code
         ORDER BY m.date_eff LIMIT 1) AS libelle
FROM   cm_commune c
WHERE  c.valid_from = :'debut_serie'::date
  AND  NOT EXISTS (SELECT 1 FROM cm_atome x WHERE x.code = c.code)
ORDER  BY c.code LIMIT 25;

-- ---------------------------------------------------------------------------
-- 5. LA recette : la simulation retombe-t-elle sur GEOFLA 2011 ?
--
-- Si la chronologie est juste, l'ensemble des communes vivantes au 1er janvier
-- 2011 est exactement celui de la trame. Toute différence, dans un sens ou dans
-- l'autre, est une erreur de reconstitution — et elle se lit ici avant d'avoir
-- écrit quoi que ce soit dans le modèle.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. RECETTE — la simulation retombe-t-elle sur GEOFLA 2011 ? ==='
\echo '    GEOFLA 2011 ne couvre que la métropole : les communes d''outre-mer'
\echo '    (codes 97/98) sont vivantes chez nous et absentes de la trame sans'
\echo '    que ce soit une erreur. Elles sont comptées à part.'
WITH vivantes AS (
    SELECT code FROM cm_commune
    WHERE  daterange(valid_from, valid_to, '[)') @> :'ancre'::date
),
trame AS (SELECT insee_com AS code FROM geofla_commune)
SELECT (SELECT count(*) FROM vivantes)                          AS simulees_2011,
       (SELECT count(*) FROM trame)                             AS geofla_2011,
       (SELECT count(*) FROM (SELECT code FROM vivantes
                              EXCEPT SELECT code FROM trame) x
         WHERE  left(x.code, 2) NOT IN ('97', '98'))            AS nous_seuls_metropole,
       (SELECT count(*) FROM (SELECT code FROM vivantes
                              EXCEPT SELECT code FROM trame) x
         WHERE  left(x.code, 2) IN ('97', '98'))                AS nous_seuls_outre_mer,
       (SELECT count(*) FROM (SELECT code FROM trame
                              EXCEPT SELECT code FROM vivantes) x) AS chez_geofla_seulement;

\echo ''
\echo '--- vivantes chez nous, absentes de GEOFLA (25 premières) ---'
\echo '    Une commune que nous croyons vivante en 2011 alors que la trame ne'
\echo '    la connaît pas : disparition manquée, ou modalité mal interprétée.'
SELECT c.code, c.valid_from, c.valid_to
FROM   cm_commune c
WHERE  daterange(c.valid_from, c.valid_to, '[)') @> :'ancre'::date
  AND  NOT EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = c.code)
ORDER  BY c.code LIMIT 25;

\echo ''
\echo '--- dans GEOFLA, mortes ou inconnues chez nous (25 premières) ---'
\echo '    L''inverse : création manquée, ou disparition à tort.'
SELECT g.insee_com, g.nom_comm,
       (SELECT max(c.valid_to) FROM cm_commune c WHERE c.code = g.insee_com) AS morte_le
FROM   geofla_commune g
WHERE  NOT EXISTS (
           SELECT 1 FROM cm_commune c
           WHERE  c.code = g.insee_com
             AND  daterange(c.valid_from, c.valid_to, '[)') @> :'ancre'::date)
ORDER  BY g.insee_com LIMIT 25;

\echo ''
\echo '--- répartition par département des divergences ---'
WITH div AS (
    SELECT left(code, 2) AS dep, 'nous seuls' AS cote FROM cm_commune
    WHERE  daterange(valid_from, valid_to, '[)') @> :'ancre'::date
      AND  NOT EXISTS (SELECT 1 FROM geofla_commune g WHERE g.insee_com = code)
    UNION ALL
    SELECT left(g.insee_com, 2), 'geofla seul' FROM geofla_commune g
    WHERE  NOT EXISTS (SELECT 1 FROM cm_commune c WHERE c.code = g.insee_com
                        AND daterange(c.valid_from, c.valid_to, '[)') @> :'ancre'::date)
)
SELECT dep, count(*) FILTER (WHERE cote = 'nous seuls')  AS nous_seuls,
            count(*) FILTER (WHERE cote = 'geofla seul') AS geofla_seul
FROM   div GROUP BY dep ORDER BY 2 + 3 DESC LIMIT 15;

\echo ''
\echo '=== Grille de lecture ==='
\echo '    § 5 à zéro sur `nous_seuls_metropole` et `chez_geofla_seulement`'
\echo '        → la chronologie est bonne, on peut écrire dans le modèle.'
\echo '        `nous_seuls_outre_mer` non nul est normal : hors trame.'
\echo '    Divergences concentrées sur quelques départements → une modalité'
\echo '        est mal interprétée (regarder 20, 75, 78, 91-95 : recodages).'
\echo '    Divergences diffuses → le fichier des mouvements est incomplet, et'
\echo '        c''est une limite de source à documenter, pas un bogue.'
\echo ''
\echo '    Restent attendus en métropole, et ce ne sont pas des erreurs :'
\echo '    Lyon 69123 et Marseille 13055, que GEOFLA ne connaît que sous leurs'
\echo '    arrondissements. Le dispositif `union_prefixe` de 05 les réunit pour'
\echo '    1870-1940 ; la période moderne devra trancher, les arrondissements'
\echo '    étant des entités GEOFLA à part entière. Cf. § 4, codes sans atome.'
\echo ''
\echo 'Tables : cm_mvt, cm_evt, cm_univers, cm_commune, cm_atome.'
\echo 'Rien n''a été écrit dans atom ni membership.'

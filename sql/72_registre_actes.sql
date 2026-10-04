-- ============================================================================
-- histgis — 72_registre_actes.sql : les actes cantonaux entrent en base
--
--   psql -d histgis -1 -f sql/72_registre_actes.sql
--   (à lancer depuis la RACINE du dépôt : les \copy sont relatifs au
--    répertoire de lancement, cf. le piège noté par `58`)
--
-- CE QUE CE FICHIER FAIT, ET CE QU'IL NE FAIT PAS
-- ===============================================
-- Il pose TROIS TABLES DE RÉFÉRENCE et n'écrit pas une seule ligne de
-- `membership`. Aucun `snapshot` ne répondra différemment après son passage.
--
-- Ce n'est pas une timidité, c'est le bon ordre. Le report d'un état d'une
-- date à l'autre — la méthode retenue pour combler 1943-1999 — n'est licite
-- que si la LISTE DES ACTES de l'intervalle est complète. Tant que cette liste
-- n'est pas en base, la condition n'est pas vérifiable : on ne peut pas
-- distinguer « rien ne s'est passé » de « on ne sait pas ». Avec ces tables,
-- la distinction devient une requête.
--
-- C'est donc la colonne vertébrale de tout ce qui suivra, et c'est aussi la
-- seule chose qui puisse être posée sans trancher la convention de date
-- d'effet (cf. § 5 et `cantons/note_entree_en_base.md`).
--
-- LES TROIS TABLES
-- ================
--   acte_cantonal    343 décrets 1958-1999 : date, département, objet, URL
--   acte_composition 4 958 lignes (acte × canton × commune)
--   acte_transfert   5 mouvements isolés de commune, datés au jour près
--
-- LA RÉSOLUTION VERS LE MODÈLE
-- ============================
-- Chaque commune citée est rattachée à un atome par `cm_atome`, exactement
-- comme `58` le fait pour le recensement de 1968 — même fonction, mêmes
-- limites, y compris celle des codes nés après 1943 puis disparus, dont
-- l'atome trouvé est surdimensionné.
--
-- La résolution est STOCKÉE, pas imposée : une ligne sans atome reste dans la
-- table avec `atome IS NULL`. On signale, on ne supprime pas.
--
-- CE QUI N'EST PAS RÉSOLU, ET POURQUOI
-- ====================================
-- Les cantons sont nommés par les décrets, pas codés. Les rapprocher d'un
-- `unit_id` demande de passer par la composition (c'est ce que fait
-- `cantons/controle_composition.py`, et ce que `73` refait en SQL pour 1967).
-- Ce fichier ne le tente pas : il laisse `canton` en texte. Un nom de canton
-- n'est pas une identité, et le dépôt a déjà payé pour l'avoir cru — la série
-- havraise décalée d'un rang après 1991 en est l'exemple.
--
-- REJOUABLE
-- =========
-- Les trois tables sont reconstruites de zéro à chaque passage. Rien n'est
-- écrit hors d'elles, donc rien à défaire ailleurs.
--
-- Prérequis : `20_commune_moderne.sql` (cm_atome).
-- Sources : cantons/decrets_cantonaux.csv, composition_jo.csv,
--           composition_legifrance.csv, transferts_legifrance.csv
--           — voir cantons/note_moisson_legifrance.md, note_composition_jo.md
--           et note_legifrance_1990_1999.md.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' REGISTRE DES ACTES CANTONAUX 1958-1999'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.cm_atome') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20_commune_moderne.sql (cm_atome).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les actes
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS acte_composition;   -- dépend de acte_cantonal
DROP TABLE IF EXISTS acte_sans_effet;    -- dépend de acte_cantonal
DROP TABLE IF EXISTS acte_departement;   -- dépend de acte_cantonal
DROP TABLE IF EXISTS acte_transfert;
DROP TABLE IF EXISTS acte_cantonal;

CREATE TABLE acte_cantonal (
    legifrance_id   text PRIMARY KEY,
    date_signature  date NOT NULL,
    date_publication date,
    decret          text,          -- 'n° 73-651' ; vide pour un décret simple
    dep             text,          -- vide pour « divers départements » (82-82)
    dep_nom         text,
    objet           text NOT NULL,
    cantons_titre   text,
    url             text NOT NULL,
    deja_repere     text NOT NULL, -- 'oui' = connu avant le moissonnage d'août 2026
    texte_integral  text NOT NULL  -- 'oui' = lisible sur Légifrance, sans PDF
);

\copy acte_cantonal (date_signature, date_publication, decret, dep, dep_nom, objet, cantons_titre, legifrance_id, url, deja_repere, texte_integral) FROM 'cantons/decrets_cantonaux.csv' WITH (FORMAT csv, HEADER true)

CREATE INDEX acte_cantonal_dep_date_idx ON acte_cantonal (dep, date_signature);
CREATE INDEX acte_cantonal_date_idx     ON acte_cantonal (date_signature);

\echo ''
\echo '-- 1. actes chargés'
SELECT count(*) AS actes,
       count(*) FILTER (WHERE deja_repere = 'non')    AS nouveaux_aout_2026,
       count(*) FILTER (WHERE texte_integral = 'oui') AS texte_sur_legifrance,
       count(*) FILTER (WHERE dep = '')               AS sans_departement,
       min(date_signature) AS du, max(date_signature) AS au
FROM   acte_cantonal;

\echo ''
\echo '   par objet'
SELECT objet, count(*) AS actes
FROM   acte_cantonal GROUP BY objet ORDER BY actes DESC;

-- ---------------------------------------------------------------------------
-- 2. Les compositions
--
-- Deux extractions, une seule table. `provenance` dit laquelle :
--   'jo'          le texte OCRisé du Journal officiel numérisé
--   'legifrance'  le texte intégral natif, 1991-1997
-- Elles n'ont ni le même point d'entrée ni le même découpage ; là où elles
-- traitent le même canton, 277 listes sur 283 sont identiques et aucune ne
-- diverge (cf. note_composition_jo.md § 4).
-- ---------------------------------------------------------------------------
CREATE TABLE acte_composition (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jo            text,     -- numéro du JO d'où vient la lecture, ou 'legifrance'
    decret        text,
    date_acte     date NOT NULL,
    dep           text,
    canton        text NOT NULL,   -- le NOM tel que le décret l'écrit
    nom_texte     text,            -- la commune telle que le décret l'écrit
    insee         text,
    nom_ref       text,            -- la commune telle que le référentiel l'écrit
    dep_insee     text,            -- département du code INSEE trouvé
    appariement   text NOT NULL,   -- exact | disparue | ressemblance | …
    attribution   text NOT NULL,   -- ancre | vote (ancre contredite) | vote | titre
    url           text,
    -- laissée nullable le temps du chargement : les deux \copy ne la
    -- renseignent pas, c'est l'UPDATE qui suit chacun d'eux qui la pose.
    -- Le NOT NULL est ajouté ensuite, et sert alors de recette.
    provenance    text,
    atome         text             -- rempli au § 4
);

\copy acte_composition (jo, decret, date_acte, dep, canton, nom_texte, insee, nom_ref, dep_insee, appariement, attribution, url) FROM 'cantons/composition_jo.csv' WITH (FORMAT csv, HEADER true)
UPDATE acte_composition SET provenance = 'jo' WHERE provenance IS NULL;

\copy acte_composition (jo, decret, date_acte, dep, canton, nom_texte, insee, nom_ref, dep_insee, appariement, attribution, url) FROM 'cantons/composition_legifrance.csv' WITH (FORMAT csv, HEADER true)
UPDATE acte_composition SET provenance = 'legifrance' WHERE provenance IS NULL;

ALTER TABLE acte_composition ALTER COLUMN provenance SET NOT NULL;
CREATE INDEX acte_composition_date_idx   ON acte_composition (date_acte, dep);
CREATE INDEX acte_composition_canton_idx ON acte_composition (dep, canton);
CREATE INDEX acte_composition_insee_idx  ON acte_composition (insee);

\echo ''
\echo '-- 2. compositions chargées'
SELECT provenance,
       count(*)                          AS lignes,
       count(DISTINCT (dep, canton))     AS cantons,
       count(DISTINCT insee)             AS communes,
       count(DISTINCT date_acte)         AS dates
FROM   acte_composition GROUP BY provenance ORDER BY lignes DESC;

\echo ''
\echo '   qualité de l''appariement des noms de communes'
SELECT appariement, count(*) AS lignes,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM   acte_composition GROUP BY appariement ORDER BY lignes DESC;

\echo ''
\echo '   comment le décret a été attribué au segment de texte'
\echo '   (« vote (ancre contredite) » = l''OCR avait perdu le numéro du décret'
\echo '    et les communes ont désigné un autre département — cf. § 5 de la note)'
SELECT attribution, count(*) AS lignes
FROM   acte_composition GROUP BY attribution ORDER BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 3. Les transferts isolés de commune
--
-- Cinq lignes, et elles valent leur table. `mouvements_cantonaux.csv` porte,
-- dès sa première ligne, la remarque : « l'annexe VII ne recense jamais ce
-- type de mouvement ». Le dépôt en compte 274 non datés. Voici les cinq dont
-- le texte donne la date, la commune, le canton d'origine ET le canton
-- d'arrivée — les quatre à la fois.
--
-- Les cinq sont confirmées par le COG 1999 : chaque commune s'y trouve dans le
-- canton nommé comme destination.
-- ---------------------------------------------------------------------------
CREATE TABLE acte_transfert (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    decret        text,
    date_acte     date NOT NULL,
    dep           text NOT NULL,
    commune       text NOT NULL,
    insee         text,
    nom_ref       text,
    appariement   text,
    canton_source text NOT NULL,
    canton_dest   text NOT NULL,
    url           text,
    atome         text            -- rempli au § 4
);

\copy acte_transfert (decret, date_acte, dep, commune, insee, nom_ref, appariement, canton_source, canton_dest, url) FROM 'cantons/transferts_legifrance.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 3. transferts isolés de commune'
SELECT date_acte, dep, commune, insee, canton_source, canton_dest
FROM   acte_transfert ORDER BY date_acte, dep;

-- ---------------------------------------------------------------------------
-- 3 bis. QUEL DÉPARTEMENT UN ACTE TOUCHE-T-IL ? — table ajoutée le 29 août 2026
--
-- `acte_cantonal.dep` est une colonne unique sous clé primaire `legifrance_id` :
-- **un acte ne peut y désigner qu'un seul département**. Le modèle ne le
-- supportait pas, et deux actes l'ont montré :
--
--   * le décret **n° 96-709** du 7 août 1996 rattache Han-devant-Pierrepont de
--     la Meuse à la Meurthe-et-Moselle — il touche 54 ET 55 ;
--   * le décret **82-82**, « dans divers départements », n'en nomme aucun, et
--     l'ancien fichier lui donnait 54 par défaut, ce qui était une invention.
--
-- Tant qu'un acte reste sans département, il interdit tout report par-dessus sa
-- date DANS TOUS LES DÉPARTEMENTS, puisqu'on ignore lequel il touche. C'est le
-- plafond mesuré par `78` § 3 bis, et il coûtait cher : 204 département-années
-- au lieu de 986.
--
-- La table est bâtie EN CREUX : un acte dont le département est connu et
-- unique tire sa ligne de `acte_cantonal` ; seuls les cas irréguliers sont
-- listés à la main dans le CSV, avec le FONDEMENT de l'attribution. Le CSV
-- l'emporte quand il parle. *Un fichier d'exceptions ne doit contenir que des
-- exceptions, sinon il devient une seconde source de vérité.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS acte_departement;
CREATE TABLE acte_departement (
    legifrance_id text NOT NULL REFERENCES acte_cantonal(legifrance_id),
    dep           text NOT NULL,
    origine       text NOT NULL,   -- 'registre' | 'lecture de l''acte'
    fondement     text,            -- pourquoi, pour les seules lectures
    PRIMARY KEY (legifrance_id, dep)
);

DROP TABLE IF EXISTS ad_lu;
CREATE TABLE ad_lu (legifrance_id text, dep text, fondement text);
\copy ad_lu (legifrance_id, dep, fondement) FROM 'cantons/acte_departement.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO acte_departement (legifrance_id, dep, origine, fondement)
SELECT legifrance_id, dep, 'lecture de l''acte', fondement FROM ad_lu;

INSERT INTO acte_departement (legifrance_id, dep, origine, fondement)
SELECT a.legifrance_id, a.dep, 'registre', NULL
FROM   acte_cantonal a
WHERE  a.dep IS NOT NULL AND a.dep <> ''
  AND  NOT EXISTS (SELECT 1 FROM ad_lu l WHERE l.legifrance_id = a.legifrance_id);

DROP TABLE ad_lu;
CREATE INDEX acte_departement_dep_idx ON acte_departement (dep);

-- ---------------------------------------------------------------------------
-- 3 ter. LES ACTES SANS EFFET SUR L'APPARTENANCE — table du 29 août 2026
--
-- « Modification de limites cantonales » recouvre deux choses que le titre ne
-- distingue pas, et qui n'ont rien à voir :
--
--   * un décret qui déplace une COMMUNE d'un canton à un autre — événement ;
--   * un décret qui échange des PARCELLES entre deux communes voisines. Les
--     limites cantonales bougent « par voie de conséquence », mais aucune
--     commune ne change de canton. Pour le `membership`, c'est un
--     non-événement ; c'est de la géométrie, et la géométrie du dépôt est
--     celle de 2011.
--
-- La distinction ne se lit QUE dans le texte. Sept actes ont été lus au JO le
-- 29 août 2026 et relèvent tous du second cas — c'est ce qui a permis de lever
-- le plafond sans avoir à leur attribuer un département.
--
-- **Un acte inscrit ici ne borne plus le report** : il n'entre ni dans le
-- calcul du plancher, ni dans celui du plafond. C'est une affirmation forte, et
-- c'est pourquoi la colonne `fondement` doit citer le passage lu — le CSV n'est
-- pas une liste d'identifiants, c'est un recueil de preuves.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS acte_sans_effet;
CREATE TABLE acte_sans_effet (
    legifrance_id text PRIMARY KEY REFERENCES acte_cantonal(legifrance_id),
    fondement     text NOT NULL
);
\copy acte_sans_effet (legifrance_id, fondement) FROM 'cantons/acte_sans_effet.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 3 ter. actes lus et déclarés sans effet sur l''appartenance'
SELECT a.date_signature,
       coalesce(nullif(a.decret, ''), '(non numéroté)') AS decret,
       a.objet,
       left(s.fondement, 60) || '…'                     AS fondement
FROM   acte_sans_effet s
JOIN   acte_cantonal a ON a.legifrance_id = s.legifrance_id
ORDER  BY a.date_signature DESC;

\echo ''
\echo '-- 3 bis. attribution des actes à un département'
SELECT origine, count(*) AS lignes, count(DISTINCT legifrance_id) AS actes
FROM   acte_departement GROUP BY origine ORDER BY origine;

\echo ''
\echo '   actes ENCORE anonymes — ils plafonnent le report partout'
\echo '   (un acte lu et déclaré sans effet, § 3 ter, ne plafonne plus rien)'
SELECT a.date_signature, coalesce(nullif(a.decret, ''), '(non numéroté)') AS decret,
       a.objet, a.texte_integral, a.url
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id)
ORDER  BY a.date_signature DESC;

\echo ''
\echo '   le plafond qu''ils imposent (métropole, avant la fin de série)'
SELECT max(a.date_signature) AS plafond, count(*) AS actes_anonymes
FROM   acte_cantonal a
WHERE  a.date_signature < '1999-01-01'
  AND  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id);

-- ---------------------------------------------------------------------------
-- 4. Raccord au continuum d'atomes
--
-- Même mécanique que `58` § 3 : `cm_atome` est une UNION ALL de deux voies
-- (directe et par succession). Un LEFT JOIN nu dupliquerait les lignes en
-- silence ; on prend donc l'atome par sous-requête, et on compte séparément
-- les codes qui en ont plusieurs.
-- ---------------------------------------------------------------------------
UPDATE acte_composition c
   SET atome = (SELECT min(x.atom_id) FROM cm_atome x WHERE x.code = c.insee)
 WHERE c.insee <> '' AND c.insee IS NOT NULL;

UPDATE acte_transfert t
   SET atome = (SELECT min(x.atom_id) FROM cm_atome x WHERE x.code = t.insee)
 WHERE t.insee <> '' AND t.insee IS NOT NULL;

\echo ''
\echo '-- 4. raccord des communes citées au continuum d''atomes'
SELECT CASE
         WHEN insee IS NULL OR insee = '' THEN 'a - pas de code INSEE (fraction, ou nom non apparié)'
         WHEN atome IS NULL               THEN 'b - code INSEE sans atome'
         ELSE                                  'c - atome trouvé'
       END        AS situation,
       count(*)   AS lignes,
       count(DISTINCT insee) FILTER (WHERE insee <> '') AS codes
FROM   acte_composition GROUP BY 1 ORDER BY 1;

\echo ''
\echo '   les codes INSEE portés par PLUSIEURS atomes (cf. `58` § 3)'
SELECT count(*) AS codes_a_plusieurs_atomes
FROM   (SELECT c.insee FROM acte_composition c
        WHERE  c.insee <> ''
        GROUP  BY c.insee
        HAVING (SELECT count(*) FROM cm_atome x WHERE x.code = c.insee) > 1) q;

-- ---------------------------------------------------------------------------
-- 5. LA RECETTE QUI JUSTIFIE CE FICHIER : le silence par département
--
-- Pour chaque département, l'intervalle autour du jalon de 1968 dans lequel
-- AUCUN acte n'est enregistré. C'est la matière première de l'extension que
-- `RESTE_A_FAIRE.md` appelait de ses vœux (« demande une source par
-- département, pas un seuil »).
--
-- ATTENTION À LA LECTURE. Un silence n'est pas une preuve de stabilité : c'est
-- une absence d'acte DANS NOTRE LISTE. La liste est exhaustive pour ce que
-- l'index par titre de Légifrance contient — vérifié : sur 32 numéros de JO à
-- numérotation contiguë, 128 numéros voisins apparaissent dans le texte sans
-- figurer à l'index, et un seul parle de cantons (une coquille d'OCR du
-- sommaire). Mais le fonds JORF est clairsemé avant 1970 : dix-huit décrets
-- pour 1958-1972, quand le registre en suppose davantage.
--
-- La mesure disponible, faite hors base sur 25 398 communes lues en 1954 ET en
-- 1968 : 94,2 % d'accord là où aucun acte n'est enregistré, 90,9 % là où il y
-- en a. L'écart va dans le bon sens — la liste porte de l'information — mais
-- 94,2 % n'est pas 100 %, et les deux lectures viennent d'un OCR.
--
-- Cette table est donc un OUTIL DE TRAVAIL, pas une autorisation d'étendre.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS acte_silence;
CREATE TABLE acte_silence AS
WITH deps AS (
    SELECT DISTINCT dep FROM acte_cantonal WHERE dep <> '' AND dep IS NOT NULL
)
SELECT d.dep,
       (SELECT max(a.date_signature) FROM acte_cantonal a
         WHERE a.dep = d.dep AND a.date_signature < DATE '1968-01-01')  AS dernier_acte_avant,
       (SELECT min(a.date_signature) FROM acte_cantonal a
         WHERE a.dep = d.dep AND a.date_signature >= DATE '1969-01-01') AS premier_acte_apres,
       (SELECT count(*) FROM acte_cantonal a
         WHERE a.dep = d.dep AND a.date_signature BETWEEN DATE '1943-01-01'
                                                      AND DATE '1999-12-31') AS actes_1943_1999
FROM   deps d;

ALTER TABLE acte_silence ADD PRIMARY KEY (dep);

\echo ''
\echo '-- 5. le silence autour du jalon de 1968, par département'
\echo '   (borne basse = 1943-01-01 quand aucun acte n''est connu avant 1968)'
SELECT count(*)                                                   AS departements,
       count(*) FILTER (WHERE dernier_acte_avant IS NULL)         AS aucun_acte_avant_1968,
       count(*) FILTER (WHERE premier_acte_apres IS NULL)         AS aucun_acte_apres_1968,
       round(avg(extract(year FROM coalesce(premier_acte_apres, DATE '1999-01-01'))
               - extract(year FROM coalesce(dernier_acte_avant,  DATE '1943-01-01'))), 1)
                                                                  AS silence_moyen_annees
FROM   acte_silence;

\echo ''
\echo '   les dix départements au silence le plus court — ceux où il y a le'
\echo '   plus à lire, et le moins à supposer'
SELECT dep, dernier_acte_avant, premier_acte_apres, actes_1943_1999
FROM   acte_silence
ORDER  BY coalesce(premier_acte_apres, DATE '1999-01-01')
        - coalesce(dernier_acte_avant,  DATE '1943-01-01')
LIMIT  10;

-- ---------------------------------------------------------------------------
-- 6. Cohérence interne
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. cohérence'

\echo '   compositions dont l''acte n''est pas au registre (doit valoir 0) :'
SELECT count(*) AS orphelines
FROM   acte_composition c
WHERE  NOT EXISTS (SELECT 1 FROM acte_cantonal a WHERE a.url = c.url);

\echo '   transferts dont l''acte n''est pas au registre (doit valoir 0) :'
SELECT count(*) AS orphelins
FROM   acte_transfert t
WHERE  NOT EXISTS (SELECT 1 FROM acte_cantonal a WHERE a.url = t.url);

\echo '   actes dont on a le texte mais aucune composition ni transfert :'
\echo '   (attendu : les modifications de limites décrites par des rues, et'
\echo '    les transferts de parcelles entre communes — sans effet cantonal)'
SELECT count(*) AS actes_muets
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_composition c WHERE c.url = a.url)
  AND  NOT EXISTS (SELECT 1 FROM acte_transfert  t WHERE t.url = a.url);

ANALYZE acte_cantonal; ANALYZE acte_composition; ANALYZE acte_transfert;
ANALYZE acte_departement; ANALYZE acte_sans_effet;

\echo ''
\echo '============================================================'
\echo ' Le registre est posé. Aucun membership n''a été touché.'
\echo ' Suite : 73 (recette 1967 contre le COG 1968), puis la pose'
\echo ' des compositions — qui demande d''abord de trancher la'
\echo ' convention de date d''effet (note_entree_en_base.md § 4).'
\echo '============================================================'

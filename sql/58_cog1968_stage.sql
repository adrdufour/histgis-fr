-- ============================================================================
-- histgis — 58_cog1968_stage.sql : le recensement de 1968 entre en base
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF, cf. § « le piège »
--   psql -d histgis -f sql/58_cog1968_stage.sql
--
-- Ce fichier N'ÉCRIT NI DANS `atom` NI DANS `membership`.
--
-- C'est la méthode de `20_commune_moderne.sql`, reprise telle quelle : « elle
-- reconstitue, et dit lesquelles se raccordent à un atome existant. Écrire
-- dans le modèle viendra après, quand ces chiffres auront été notés. » Poser
-- 31 981 rattachements cantonaux sans avoir mesuré combien se résolvent, et
-- contre quoi, serait exactement la faute que `21` a coûté quatre passages.
--
-- L'ENJEU
-- =======
-- `24_canton_moderne.sql` le dit sans détour : « le `membership` s'arrête en
-- 1941 et reprend en 1999, avec RIEN entre les deux ». Cinquante-huit ans
-- pendant lesquels `snapshot(1970)` ne renvoie aucun canton. C'est le trou
-- cantonal 1943-1999, et il bloque le découpage législatif de 1958, qui se
-- définit par cantons.
--
-- Le recensement de 1968 est **un jalon daté à l'intérieur de ce trou**. Il ne
-- le comble pas : il y plante un repère au 1er janvier 1968.
--
-- CE QUE CE FICHIER NE FERA PAS, ET POURQUOI C'EST LE POINT PRINCIPAL
-- ===================================================================
-- Un recensement dit un ÉTAT à une DATE. Il ne dit pas une durée. Étendre le
-- rattachement de 1968 jusqu'en 1999 — ou le faire remonter à 1941 — serait
-- supposer une stabilité cantonale que rien n'établit, et que
-- `30_stabilite_cantonale.sql` ne concède qu'au cas par cas, département par
-- département, avec un test qu'il déclare lui-même « nécessaire, pas
-- suffisant ».
--
-- Le registre cantonal consolidé date 77 % des démembrements et en compte 48
-- postérieurs à 1986 : la composition BOUGE dans l'intervalle. Une extension
-- automatique produirait des rattachements faux sans qu'aucune recette interne
-- ne puisse les distinguer des vrais — la leçon de l'Ain, § 51.
--
-- Donc : ce fichier MESURE la résolution. L'écriture des `membership`, et le
-- choix de leurs bornes, feront l'objet d'un fichier séparé, une fois ces
-- chiffres connus et notés dans le journal.
--
-- LE PIÈGE DU \copy
-- =================
-- `\copy` résout les chemins relatifs depuis le répertoire de LANCEMENT de
-- psql, pas depuis celui du script. Lancer ce fichier depuis `sql/` cherchera
-- `sql/cog1968/…` et échouera. Se placer à la racine du dépôt.
--
-- Prérequis : base chargée, `20_commune_moderne.sql` (cm_commune, cm_atome),
-- `24_canton_moderne.sql` (les unités canton). Lecture seule sur le modèle ;
-- crée ses propres tables `c68_*`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set date_1968 '1968-01-01'

-- `c68_trace` est créée par `59`. Au tout premier passage elle n'existe pas
-- encore, et la section 5 bis la joint : on la crée vide plutôt que d'exiger
-- un ordre d'exécution.
CREATE TABLE IF NOT EXISTS c68_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

\echo ''
\echo '============================================================'
\echo ' COG 1968 — dépôt et résolution'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Le dépôt brut
--
-- Une ligne par ligne du CSV, sans transformation. Le fichier doit rester
-- relisible à côté de sa source, comme `cog_commune_src` pour 1999-2012.
-- ---------------------------------------------------------------------------
-- L'ORDRE ET LE NOMBRE DES COLONNES SUIVENT LE CSV, et il a bougé deux fois.
--
-- `\copy … WITH (HEADER true)` ne lit PAS l'en-tête pour apparier les colonnes :
-- il le saute, et se fie à l'ordre de la table. Ajouter une colonne en amont —
-- `libelle_canton` dans `extrait_1968.py`, `lectures` dans `fusionne_passes.py`
-- — casse donc le chargement avec un « extra data after last expected column »
-- qui ne dit pas laquelle manque.
--
-- La section 0 ci-dessous compare le compte de colonnes AVANT de charger, pour
-- que l'erreur nomme sa cause. C'est le prix d'un format qui vit : on ne peut
-- pas empêcher le CSV de gagner des colonnes, on peut faire en sorte que le
-- message le dise.
DROP TABLE IF EXISTS c68_src CASCADE;
CREATE TABLE c68_src (
    dep            char(2),
    insee          char(5),
    insee_ocr      text,    -- la lecture d'origine si le code a été réparé
    insee3         text,
    arr            text,
    canton         text,
    nom            text,
    pop1968        text,    -- texte : l'OCR produit des valeurs non numériques
    etoile         text,    -- l'astérisque du fascicule, sens non établi
    libelle_canton text,    -- « | 1er Canton » sur les lignes de continuation
    hors_borne     text,
    page           text,
    accord         text,    -- accord | fraction | majorite | canton_conteste
                            -- | psm6 | psm4 | 600
    desaccord      text,    -- champs divergents entre les lectures
    canton_autre   text,    -- la ou les lectures cantonales écartées
    lectures       text,    -- combien de passes portent cette ligne
    doublon_probable text   -- `codes_orphelins.py` : la commune est déjà lue
                            -- ailleurs sous son bon code, cette ligne-ci est
                            -- une lecture fautive de la même
);

\copy c68_src FROM 'cog1968/communes_1968_fusion.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- 1 bis. Les lignes dont le NOM désigne une autre commune que le CODE
--
-- Ajouté le 21 octobre 2026. `cog1968/controle_nom_code_base.py` a trouvé
-- 629 lignes du dépôt portant le nom d'une autre commune du département que
-- celle de leur code, dont 325 qui mettaient en base un canton faux en 1968 —
-- 286 sous forme de FAUSSES FRACTIONS : le code apparaît deux fois, et `59`
-- coupe la commune en deux (Viriat, Buellas, Trévoux dans l'Ain ; Suippes, Le
-- Pin…). `cog1968/c68_codes_corriges.csv` dit, ligne à ligne :
--   rendre   la ligne passe au code de la commune nommée, qui n'en avait pas
--            et dont c'est bien le canton (`insee_ocr` garde le code lu) ;
--   retirer  la commune nommée a déjà sa ligne, ou le canton n'est celui
--            d'aucune des deux communes — sauf la DERNIÈRE ligne d'un code
--            dont la lecture était déjà écartée en aval : elle reste, `96` la
--            corrige (sans elle, Laon, Dax, Château-Gontier… perdaient leur
--            canton de 1968). 392 lignes : 77 rendues, 315 retirées.
-- Les lignes sont reconnues par (dep, code lu, canton, nom lu, page) : une
-- correction qui ne trouve pas exactement UNE ligne arrête tout, parce qu'un
-- fichier source modifié ne doit pas recevoir en silence les corrections d'un
-- autre. Le détail est gardé dans `c68_correction`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c68_correction;
CREATE TABLE c68_correction (
    dep text, insee_lu char(5), canton text, nom_lu text, page text,
    action text CHECK (action IN ('rendre', 'retirer')),
    insee_corrige char(5), nom_corrige text, verdict text, motif text
);
\copy c68_correction FROM 'cog1968/c68_codes_corriges.csv' WITH (FORMAT csv, HEADER true)

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM c68_correction c
     WHERE (SELECT count(*) FROM c68_src s
             WHERE s.dep = c.dep AND s.insee = c.insee_lu AND s.canton = c.canton
               AND s.nom = c.nom_lu AND s.page IS NOT DISTINCT FROM c.page) <> 1;
    IF n > 0 THEN
        RAISE EXCEPTION 'CORRECTIONS 1968 : % ligne(s) de c68_codes_corriges.csv ne '
                        'désignent pas exactement une ligne du dépôt.', n;
    END IF;
    SELECT count(*) INTO n FROM c68_correction
     WHERE action = 'rendre' AND (insee_corrige IS NULL OR left(insee_corrige, 2) <> dep);
    IF n > 0 THEN
        RAISE EXCEPTION 'CORRECTIONS 1968 : % ligne(s) à rendre sans code valable.', n;
    END IF;
END $$;

DELETE FROM c68_src s USING c68_correction c
 WHERE c.action = 'retirer'
   AND s.dep = c.dep AND s.insee = c.insee_lu AND s.canton = c.canton
   AND s.nom = c.nom_lu AND s.page IS NOT DISTINCT FROM c.page;

UPDATE c68_src s
   SET insee_ocr = coalesce(s.insee_ocr, s.insee),
       insee     = c.insee_corrige,
       insee3    = right(c.insee_corrige, 3)
  FROM c68_correction c
 WHERE c.action = 'rendre'
   AND s.dep = c.dep AND s.insee = c.insee_lu AND s.canton = c.canton
   AND s.nom = c.nom_lu AND s.page IS NOT DISTINCT FROM c.page;

\echo ''
\echo '-- 1 bis. corrections nom / code appliquées'
SELECT action, count(*) AS lignes FROM c68_correction GROUP BY action ORDER BY action;

\echo ''
\echo '-- 1. dépôt'
SELECT count(*)                              AS lignes,
       count(DISTINCT insee)                 AS communes,
       count(DISTINCT dep)                   AS departements,
       count(DISTINCT dep || canton)         AS cantons_cites
FROM   c68_src;

-- ---------------------------------------------------------------------------
-- 2. Contrôles préalables — ils ANNULENT plutôt que de laisser passer
--
-- La leçon de `21`, appliquée comme dans `24` : rien n'est mesuré tant que la
-- forme n'est pas vérifiée. Un canton sur trois caractères, ou un code INSEE
-- qui ne serait pas dans son département, fausserait toute la suite en
-- silence.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint;
BEGIN
    -- les prérequis, nommés. Un « relation inexistante » au milieu d'un
    -- diagnostic ne dit pas QUEL fichier il fallait jouer avant.
    IF to_regclass('histgis.cm_commune') IS NULL
       OR to_regclass('histgis.cm_atome') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20_commune_moderne.sql (cm_commune, cm_atome).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM unit WHERE niveau = 'canton') THEN
        RAISE EXCEPTION 'PRÉREQUIS : aucune unité canton — jouer sql/24_canton_moderne.sql.';
    END IF;

    SELECT count(*) INTO n FROM c68_src WHERE length(canton) <> 2;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 1 : % lignes dont le canton ne fait pas 2 caractères.', n;
    END IF;

    SELECT count(*) INTO n FROM c68_src WHERE left(insee, 2) <> dep;
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 2 : % lignes dont le code INSEE contredit le département.', n;
    END IF;

    -- Les statuts d'accord ont changé quand la fusion est passée à TROIS
    -- lectures : `deux` et `deux+fraction` sont devenus `accord` et `fraction`,
    -- et `majorite` est apparu. Les anciens sont acceptés pour qu'un fichier
    -- produit à deux passes reste chargeable.
    SELECT count(*) INTO n FROM c68_src
     WHERE accord NOT IN ('accord', 'fraction', 'majorite', 'canton_conteste',
                          'psm6', 'psm4', '600',
                          'deux', 'deux+fraction');
    IF n > 0 THEN
        RAISE EXCEPTION 'PRÉALABLE 3 : % lignes au statut d''accord inconnu '
                        '(vu : %).', n,
                        (SELECT string_agg(DISTINCT accord, ', ') FROM c68_src
                          WHERE accord NOT IN ('accord', 'fraction', 'majorite',
                                'canton_conteste', 'psm6', 'psm4', '600',
                                'deux', 'deux+fraction'));
    END IF;

    RAISE NOTICE 'Contrôle préalable : les trois assertions passent.';
END $$;

-- ---------------------------------------------------------------------------
-- 3. Résolution
--
-- Deux jointures indépendantes, et l'on garde la trace de chacune :
--
--   * la COMMUNE — le code INSEE de 1968 désigne-t-il une commune que
--     `cm_commune` sait vivante au 1er janvier 1968, et quel atome la porte ?
--   * le CANTON  — `dep || canton` est-il une unité canton connue ?
--     L'espace de noms est unique 1870-2012 (§ 1 de `24`), aligné sur le COG
--     de 1954 par TRF-GIS. Un canton de 1968 DEVRAIT donc s'y retrouver.
--
-- Les deux peuvent échouer séparément, et le diagnostic doit le dire :
-- confondre « commune inconnue » et « canton inconnu » masquerait deux causes
-- très différentes.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c68_lien;
CREATE TABLE c68_lien AS
SELECT s.dep,
       s.insee,
       s.nom,
       s.canton,
       s.dep || s.canton                                   AS canton_id,
       s.accord,
       s.canton_autre,
       -- la commune existait-elle à cette date, selon les mouvements INSEE ?
       EXISTS (SELECT 1 FROM cm_commune c
                WHERE c.code = s.insee
                  AND daterange(c.valid_from, c.valid_to, '[)')
                      @> :'date_1968'::date)               AS commune_vivante,
       a.atome,
       a.n_atomes,                                          -- > 1 : ambigu
       EXISTS (SELECT 1 FROM unit u
                WHERE u.unit_id = s.dep || s.canton
                  AND u.niveau = 'canton')                 AS canton_connu
FROM   c68_src s
-- `cm_atome` est une UNION ALL de deux voies (directe et par succession) : un
-- même code peut y apparaître plusieurs fois. Un LEFT JOIN nu DUPLIQUERAIT
-- silencieusement les lignes de 1968, et tous les compteurs qui suivent
-- seraient faux sans que rien ne le signale. On agrège, et l'on conserve le
-- nombre d'atomes pour pouvoir écarter les cas ambigus au lieu d'en choisir un.
LEFT   JOIN LATERAL (
           SELECT min(x.atom_id)             AS atome,
                  count(DISTINCT x.atom_id)  AS n_atomes
           FROM   cm_atome x WHERE x.code = s.insee
       ) a ON true;

CREATE INDEX c68_lien_insee_idx  ON c68_lien (insee);
CREATE INDEX c68_lien_canton_idx ON c68_lien (canton_id);

\echo ''
\echo '-- 3. résolution, par classe'
SELECT commune_vivante,
       atome IS NOT NULL AS a_un_atome,
       canton_connu,
       count(*)                       AS lignes,
       count(DISTINCT insee)          AS communes
FROM   c68_lien
GROUP  BY 1, 2, 3
ORDER  BY lignes DESC;

\echo ''
\echo '   la classe pleinement résolue, isolée :'
SELECT count(*)              AS lignes,
       count(DISTINCT insee) AS communes,
       count(DISTINCT atome) AS atomes,
       count(DISTINCT canton_id) AS cantons
FROM   c68_lien
WHERE  commune_vivante AND atome IS NOT NULL
  AND  canton_connu AND n_atomes = 1;

\echo ''
\echo '-- 3 bis. la même chose, croisée avec la confiance de lecture'
SELECT accord,
       count(*)                                                  AS lignes,
       count(*) FILTER (WHERE commune_vivante AND atome IS NOT NULL
                          AND canton_connu)                      AS resolues,
       round(100.0 * count(*) FILTER (WHERE commune_vivante
                                        AND atome IS NOT NULL
                                        AND canton_connu) / count(*), 1) AS pct
FROM   c68_lien
GROUP  BY accord
ORDER  BY lignes DESC;

-- ---------------------------------------------------------------------------
-- 4. Ce qui ne se résout pas — nommé, pas seulement compté
--
-- Un compteur d'échecs sans exemples n'est pas exploitable : on ne sait pas
-- s'il s'agit d'une classe ou d'une poussière.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4a. cantons cités par 1968 mais inconnus de la nomenclature'
SELECT canton_id,
       count(*)                    AS lignes,
       min(nom)                    AS un_exemple_de_commune
FROM   c68_lien
WHERE  NOT canton_connu
GROUP  BY canton_id
ORDER  BY lignes DESC
LIMIT  25;

\echo ''
\echo '   ... et leur nombre total :'
SELECT count(DISTINCT canton_id) AS cantons_inconnus,
       count(*)                  AS lignes_concernees
FROM   c68_lien WHERE NOT canton_connu;

\echo ''
\echo '-- 4b. communes que cm_commune ne connaît pas vivantes en 1968'
SELECT dep, count(*) AS lignes, min(insee) AS exemple_code, min(nom) AS exemple_nom
FROM   c68_lien
WHERE  NOT commune_vivante
GROUP  BY dep
ORDER  BY lignes DESC
LIMIT  20;

\echo ''
\echo '-- 4c. communes vivantes mais sans atome porteur'
SELECT count(*) AS lignes, count(DISTINCT insee) AS communes
FROM   c68_lien
WHERE  commune_vivante AND atome IS NULL;

\echo ''
\echo '-- 4 bis. lignes parasites repérées par codes_orphelins.py'
\echo '   (la commune est déjà lue ailleurs sous son bon code)'
SELECT count(*)                                        AS lignes,
       count(*) FILTER (WHERE s.accord = 'accord')     AS dont_trois_lectures_accordees
FROM   c68_src s WHERE s.doublon_probable = 'oui';

\echo ''
\echo '   La seconde colonne est le fait notable : les TROIS lectures'
\echo '   s''accordent sur un code faux, et seul le nom le révèle. Un accord'
\echo '   ne garantit pas la justesse — même image, même moteur, erreurs'
\echo '   corrélées.'

\echo ''
\echo '-- 4d. codes portés par PLUSIEURS atomes — à écarter, pas à trancher'
\echo '   (un LEFT JOIN nu sur cm_atome les aurait dupliqués en silence)'
SELECT count(*) AS lignes, count(DISTINCT insee) AS communes
FROM   c68_lien WHERE n_atomes > 1;

\echo ''
\echo '   vérification que le dépôt n''a pas été dupliqué par la jointure :'
SELECT (SELECT count(*) FROM c68_src)  AS lignes_deposees,
       (SELECT count(*) FROM c68_lien) AS lignes_resolues,
       CASE WHEN (SELECT count(*) FROM c68_src) = (SELECT count(*) FROM c68_lien)
            THEN 'identiques — pas de duplication'
            ELSE 'DIVERGENCE : la résolution a changé le nombre de lignes'
       END AS verdict;

-- ---------------------------------------------------------------------------
-- 5. Ce que 1968 apporterait vraiment
--
-- La question qui décide de la suite : combien d'atomes recevraient un
-- rattachement cantonal qu'ils n'ont PAS aujourd'hui à cette date ? Si la
-- réponse est « presque tous », le jalon vaut la peine d'être posé. Si des
-- rattachements existent déjà en 1968, il y a conflit et il faut le savoir
-- AVANT d'écrire.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. couverture actuelle de la date, et apport'
SELECT
  (SELECT count(DISTINCT m.atom_id) FROM membership m
    WHERE m.niveau = 'canton'
      AND daterange(m.valid_from, m.valid_to, '[)') @> :'date_1968'::date)
                                                        AS atomes_deja_rattaches_1968,
  (SELECT count(DISTINCT atome) FROM c68_lien
    WHERE atome IS NOT NULL AND canton_connu AND commune_vivante)
                                                        AS atomes_que_1968_pourrait_rattacher;

-- DEUX SORTES DE RATTACHEMENTS EXISTANTS, à ne pas confondre.
--
-- Au premier passage, la date était vide et tout conflit aurait signifié que
-- 1968 contredit une autre source. Au REJEU, l'écrasante majorité vient de
-- `59` lui-même, qui a posé au tour précédent — et le compter comme un conflit
-- ferait croire à un problème là où il n'y a qu'une chaîne rejouée.
--
-- On distingue donc ce que NOUS avons posé (tracé dans `c68_trace`) de ce
-- qu'un tiers a posé, qui seul mérite le nom de conflit.
\echo ''
\echo '-- 5 bis. rattachements cantonaux déjà présents à cette date'
SELECT count(*) FILTER (WHERE t.cle IS NOT NULL)  AS poses_par_59_au_tour_precedent,
       count(*) FILTER (WHERE t.cle IS NULL)      AS poses_par_un_tiers
FROM   c68_lien l
JOIN   membership m ON m.atom_id = l.atome AND m.niveau = 'canton'
                   AND daterange(m.valid_from, m.valid_to, '[)') @> :'date_1968'::date
LEFT   JOIN c68_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
WHERE  l.atome IS NOT NULL;

\echo ''
\echo '   La colonne « tiers » est celle qui compte : 60_canton_forbach2.sql y'
\echo '   apparaît, et 59 laissera ces atomes en place plutôt que de les'
\echo '   écraser. Un chiffre inattendu ailleurs signalerait une vraie'
\echo '   contradiction entre sources.';

-- ---------------------------------------------------------------------------
-- 6. Le contrôle qui n'est pas circulaire
--
-- Tout ce qui précède mesure 1968 contre des tables construites par ce dépôt.
-- Le seul rapprochement qui ne doive rien à notre chaîne : les cantons que
-- 1968 attribue à une commune sont-ils ceux que le COG DE 1999 lui attribue,
-- pour les communes dont le canton n'a pas bougé ?
--
-- Ce n'est PAS une recette — la composition a pu changer entre 1968 et 1999,
-- et c'est même l'hypothèse par défaut. C'est une MESURE DE DISTANCE : un
-- accord élevé rend l'extension plausible pour ces départements, un accord
-- faible l'interdit. Aucune conclusion ne doit être tirée d'un cas isolé.
-- ---------------------------------------------------------------------------
-- `cog_rat` vient de 23_cog_diag.sql. Si elle manque, la section 6 est sautée
-- proprement : elle est INDICATIVE, et son absence ne doit pas faire échouer
-- un diagnostic dont tout le reste est valable. `ON_ERROR_STOP` étant actif,
-- il faut tester avant d'exécuter, pas rattraper après.
SELECT to_regclass('histgis.cog_rat') IS NULL AS sauter_6 \gset

\if :sauter_6
\echo ''
\echo '-- 6. SAUTÉE : cog_rat absente. Jouer sql/23_cog_diag.sql pour l''obtenir.'
\else

\echo ''
\echo '-- 6. distance entre le canton de 1968 et celui de 1999 (INDICATIF)'
SELECT count(*)                                              AS communes_comparables,
       count(*) FILTER (WHERE l.canton_id = r99.canton_cog)  AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE l.canton_id = r99.canton_cog)
             / nullif(count(*), 0), 1)                       AS pct_accord
FROM   c68_lien l
JOIN   (SELECT DISTINCT code, canton_cog FROM cog_rat WHERE annee = 1999) r99
       ON r99.code = l.insee
WHERE  l.accord <> 'canton_conteste';

\echo ''
\echo '-- 6 bis. le même accord, par département — c''est là que ça se décide'
SELECT l.dep,
       count(*)                                              AS communes,
       count(*) FILTER (WHERE l.canton_id = r99.canton_cog)  AS meme_canton,
       round(100.0 * count(*) FILTER (WHERE l.canton_id = r99.canton_cog)
             / nullif(count(*), 0), 1)                       AS pct
FROM   c68_lien l
JOIN   (SELECT DISTINCT code, canton_cog FROM cog_rat WHERE annee = 1999) r99
       ON r99.code = l.insee
WHERE  l.accord <> 'canton_conteste'
GROUP  BY l.dep
ORDER  BY pct
LIMIT  25;

\endif

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans atom ni membership.'
\echo ' Noter ces chiffres dans JOURNAL.md avant d''écrire 59.'
\echo '============================================================'

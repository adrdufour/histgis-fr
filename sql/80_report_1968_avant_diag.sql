-- ============================================================================
-- histgis — 80_report_1968_avant_diag.sql : reporter le jalon 1968 EN AVANT ?
--
--   psql -d histgis -f sql/80_report_1968_avant_diag.sql
--
-- LECTURE SEULE. N'écrit ni dans `atom`, ni dans `unit`, ni dans `membership`.
-- Tout ce qu'il crée est préfixé `r80_` et se jette.
--
-- LA QUESTION, ET POURQUOI ELLE N'A PAS ENCORE ÉTÉ POSÉE
-- ======================================================
-- `78` et `79` reportent la couche de 1999 EN ARRIÈRE, jusqu'au dernier acte
-- de chaque département. Personne n'a fait le mouvement symétrique : le jalon
-- de 1968 est en base (`59`, 32 842 rattachements), il est daté, et si le
-- registre des actes est complet alors pour un département dont le PREMIER
-- acte postérieur date de 1973, rien n'a bougé de 1969 à 1973 — et la
-- composition de 1968 vaut jusque-là.
--
-- Le raisonnement est exactement celui de `78`, pris par l'autre bout. Ce
-- fichier ne demande pas qu'on lui fasse confiance sur ce point : il mesure la
-- même chose que `78` mesurait, dans l'autre sens, avec les mêmes pièges
-- devant lui.
--
-- CE QUE CE FICHIER MESURE, ET DANS QUEL ORDRE
-- ============================================
--   § 2  le PLAFOND par département — jusqu'où le report peut monter
--   § 3  ce qui INTERDIT le report : actes sans département, actes dans 1968
--   § 4  ce que le report couvrirait, et par qui la place est déjà prise
--   § 5  LA JONCTION — où le report avant rencontre le report arrière de `79`
--   § 6  LE CONTRÔLE — 1968 contre 1999, là où le registre dit « rien n'a bougé »
--   § 7  le chaînage : combien de départements sont intégralement dépouillés
--   § 8  les témoins déjà mesurés par le dépôt
--
-- LE CONTRÔLE DU § 6, ET POURQUOI IL EST MEILLEUR QUE CELUI DE `78`
-- =================================================================
-- Le § 5 de `78` s'est révélé non indépendant : `75`/`76` résolvent le canton
-- d'un décret **en votant contre la couche de 1999**, si bien que mesurer leur
-- accord avec 1999 revenait à leur faire mesurer leur propre critère
-- d'admission. Le piège est documenté dans `78` lui-même.
--
-- Ici il n'y a pas de vote. La couche de 1968 vient d'un OCR de fascicules du
-- recensement ; la couche de 1999 vient d'un fichier de l'INSEE, non océrisé.
-- Aucune des deux n'a jamais vu l'autre : `59` ne lit pas `24`, et `24` a été
-- écrit deux mois plus tôt. **Les deux lectures sont indépendantes.**
--
-- Et le contrôle a un pouvoir de RÉFUTATION, ce qui manquait à `78` § 5 :
-- le registre des actes prétend savoir quand un département a bougé. Si c'est
-- vrai, l'accord 1968/1999 doit être franchement PLUS HAUT dans les
-- départements sans aucun acte que dans ceux qui en portent trois ou plus.
-- Si les deux taux sont voisins, alors le registre ne capte pas les mouvements
-- réels et le report — dans les deux sens, `79` compris — est mort.
--
-- *Un contrôle qui ne peut pas mal tourner ne contrôle rien.* Celui-ci peut.
--
-- CE QU'IL NE MESURE PAS, ET QU'AUCUNE REQUÊTE NE MESURERA
-- ========================================================
-- Les transferts isolés de commune que l'annexe VII ne recense jamais par
-- construction — 274 non datés au registre cantonal. S'ils n'ont pas laissé
-- de décret, le plafond les ignore et le report passe par-dessus sans que rien
-- ne le signale. Ordre de grandeur disponible : 0,29 % des communes en
-- quatorze ans (`70`, `71`).
--
-- Prérequis : `59` (jalon 1968), `24` (couche 1999), `72` (registre,
--             acte_departement, acte_sans_effet), `75` (acte_effet).
--             `79` n'est pas indispensable ; s'il est joué, le § 5 mesure la
--             jonction, sinon il la mesure comme opportunité.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut  '1968-01-01'
\set jalon_fin    '1969-01-01'
\set jalon_temoin '1968-06-01'
\set fin_serie    '1999-01-01'
\set date_1999    '1999-06-01'

\echo ''
\echo '============================================================'
\echo ' Le report EN AVANT depuis le jalon 1968 — diagnostic'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_cantonal') IS NULL
       OR to_regclass('histgis.acte_departement') IS NULL
       OR to_regclass('histgis.acte_sans_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql.';
    END IF;
    IF to_regclass('histgis.acte_effet') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/75_composition_1973_1982.sql (acte_effet).';
    END IF;
    -- psql n'interpole PAS ses variables dans une chaîne dollar-quotée :
    -- les dates sont écrites en clair ici, et nulle part ailleurs.
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton'
                      AND periode @> '1968-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : le jalon 1968 est absent — jouer sql/59_cog1968_membership.sql.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton'
                      AND periode @> '1999-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1999 est absente — jouer sql/24_canton_moderne.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. LE PLAFOND — jusqu'où le report peut monter, département par département
--
-- Symétrique du plancher de `78` § 2. On part de la fin du jalon
-- (1969-01-01 : `59` pose sur [1968-01-01, 1969-01-01) et sur cette année
-- seule) et on monte jusqu'à la date d'EFFET du premier acte postérieur.
--
-- POURQUOI LA DATE D'EFFET, ET PAS LA SIGNATURE
-- ---------------------------------------------
-- Sur l'intervalle [signature, effet) c'est encore l'ANCIENNE composition qui
-- vaut — celle que le décret défait, donc celle de 1968 si aucun acte n'est
-- intervenu avant. Reporter jusqu'à l'effet n'est donc pas une hypothèse : le
-- décret lui-même dit que rien n'a changé avant cette date.
--
-- **La même convention change de rôle avec le sens du report.** Dans `78`
-- elle RACCOURCIT la fenêtre (le plancher remonte de 183 jours) ; ici elle
-- l'ALLONGE d'autant. Elle est juste dans les deux cas, et c'est le même fait
-- qui la fonde. Le § 2 ter chiffre ce qu'on gagnerait à ne pas se tromper de
-- borne — c'est un gain gratuit, sans hypothèse ajoutée.
-- ---------------------------------------------------------------------------
-- Le département vient de `acte_departement` (`72` § 3 bis) et non de
-- `acte_cantonal.dep` : un acte peut en toucher DEUX (décret n° 96-709,
-- Meuse -> Meurthe-et-Moselle) et la colonne unique ne peut pas le dire.
DROP TABLE IF EXISTS r80_plafond;
CREATE TABLE r80_plafond AS
SELECT d.dep,
       -- le premier acte qui prend effet APRÈS le jalon : c'est lui le plafond
       min(e.date_effet) FILTER (
           WHERE e.date_effet >= :'jalon_fin'::date
             AND e.date_effet <  :'fin_serie'::date)      AS plafond_effet,
       min(a.date_signature) FILTER (
           WHERE a.date_signature >= :'jalon_fin'::date
             AND a.date_signature <  :'fin_serie'::date)  AS plafond_signature,
       -- symétrique : le dernier acte avant 1999, c'est le plancher de `79`.
       -- Recalculé ici pour que le fichier ne dépende pas de `78`.
       max(e.date_effet) FILTER (
           WHERE e.date_effet < :'fin_serie'::date)       AS plancher_effet,
       count(*) FILTER (
           WHERE e.date_effet >= :'jalon_fin'::date
             AND e.date_effet <  :'fin_serie'::date)      AS actes_dans_le_trou,
       count(*) FILTER (
           WHERE e.date_effet >= :'jalon_fin'::date
             AND e.date_effet <  :'fin_serie'::date
             AND NOT EXISTS (SELECT 1 FROM acte_composition c
                              WHERE c.date_acte = a.date_signature
                                AND c.dep = d.dep))       AS non_depouilles,
       -- un acte qui prend effet DANS l'année du jalon défait la composition
       -- que `59` a posée, à l'intérieur même de sa fenêtre. Le report avant
       -- n'a alors aucun point de départ sûr — cf. § 3 bis.
       count(*) FILTER (
           WHERE e.date_effet >= :'jalon_debut'::date
             AND e.date_effet <  :'jalon_fin'::date)      AS actes_dans_le_jalon
FROM   acte_departement d
JOIN   acte_cantonal a ON a.legifrance_id = d.legifrance_id
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  length(d.dep) = 2
  -- un acte lu et déclaré sans effet sur l'appartenance ne borne rien
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet x
                    WHERE x.legifrance_id = a.legifrance_id)
GROUP  BY d.dep;

ALTER TABLE r80_plafond ADD PRIMARY KEY (dep);

-- Les départements que le registre ne connaît pas du tout n'apparaissent pas
-- ci-dessus : on les ajoute avec un plafond NULL, qui veut dire « report
-- ouvert jusqu'à 1999 » et non « report impossible ». La distinction est celle
-- que `72` cherchait à rendre disponible.
--
-- LE DÉFAUT DU PREMIER JET, TROUVÉ AU PREMIER PASSAGE (30 août 2026).
-- Cet INSERT prenait tout département connu de `unit`, sans vérifier qu'il a
-- des atomes dans le jalon. Il a fait entrer `75` et `99`, qui n'en ont AUCUN,
-- avec 30 ans de profondeur chacun : **60 département-années fictives sur un
-- total annoncé de 668**, et deux départements comptés « couverts de bout en
-- bout » au § 5 alors qu'il n'y a rien à couvrir.
--
-- Pour `75` ce n'est pas un accident : aucun décret cantonal parisien n'est au
-- registre, et c'est un fait — Paris ne relève pas du régime des décrets de
-- délimitation (cf. `79` § 10 b/c). Le fichier confondait « le registre ne dit
-- rien » avec « rien n'a bougé », alors que la première proposition peut aussi
-- vouloir dire que le département est hors du champ du registre.
--
-- ***Un département sans atome n'est pas un département couvert*** — et un
-- report ouvert sur un ensemble vide affiche la profondeur maximale, donc se
-- place en tête de tous les classements. La faute était visible au § 6 bis,
-- qui ne rendait aucune ligne là où l'on attendait le témoin.
INSERT INTO r80_plafond (dep, actes_dans_le_trou, non_depouilles, actes_dans_le_jalon)
SELECT DISTINCT u.dep::text, 0, 0, 0
FROM   unit u
WHERE  u.niveau = 'canton'
  AND  NOT EXISTS (SELECT 1 FROM r80_plafond p WHERE p.dep = u.dep::text)
  AND  EXISTS (SELECT 1 FROM membership m
                JOIN unit v ON v.unit_id = m.unit_id AND v.niveau = 'canton'
               WHERE v.dep = u.dep
                 AND m.niveau = 'canton'
                 AND m.periode @> :'jalon_temoin'::date);

\echo ''
\echo '-- 2 zéro. les départements écartés : connus de `unit`, sans atome en 1968'
\echo '   (ils n''ont rien à reporter ; les compter gonflerait le total de 30 ans'
\echo '    chacun — c''est le défaut du premier jet, corrigé)'
SELECT DISTINCT u.dep::text                                   AS dep,
       EXISTS (SELECT 1 FROM acte_departement d
                WHERE d.dep = u.dep::text)                    AS connu_du_registre,
       CASE WHEN u.dep::text = '75'
            THEN 'Paris — hors du régime des décrets de délimitation (fait)'
            WHEN u.dep::text = '99'
            THEN 'Meurthe 1870-1871 — `39` NON APPLIQUÉ sur cette base'
            ELSE 'à identifier' END                           AS pourquoi
FROM   unit u
WHERE  u.niveau = 'canton'
  AND  NOT EXISTS (SELECT 1 FROM r80_plafond p WHERE p.dep = u.dep::text)
ORDER  BY 1;

\echo ''
\echo '   `99` N''EST PAS UN DÉPARTEMENT. C''est le code que TRF-GIS donne aux'
\echo '   29 cantons de la Meurthe (1870-1871), et `39_meurthe_1870.sql` est'
\echo '   censé leur avoir rendu le 54 qu''ils portaient. S''il apparaît'
\echo '   ci-dessus, c''est que `39` n''a pas été rejoué depuis le dernier'
\echo '   `rebuild.sh` — sa recette 1 dit « 99 absent » et personne ne la lit.'
\echo '   Sans effet sur ce fichier (la Meurthe meurt 97 ans avant le jalon),'
\echo '   mais tout regroupement par département sur 1870-1871 est faussé.'

-- `date - date` rend un ENTIER de jours, pas un intervalle : division directe.
ALTER TABLE r80_plafond ADD COLUMN profondeur_annees numeric;
UPDATE r80_plafond
   SET profondeur_annees = round(
         (coalesce(plafond_effet, :'fin_serie'::date) - :'jalon_fin'::date)
         / 365.25, 1);

\echo ''
\echo '-- 2. le plafond, vue d''ensemble'
SELECT count(*)                                          AS departements,
       count(*) FILTER (WHERE plafond_effet IS NULL)     AS sans_acte_apres_1968,
       round(avg(profondeur_annees), 1)                  AS profondeur_moyenne,
       -- `percentile_cont` rend un double precision, que `round(x, n)` refuse
       round((percentile_cont(0.5) WITHIN GROUP (
              ORDER BY profondeur_annees))::numeric, 1)  AS mediane,
       min(profondeur_annees)                            AS mini,
       max(profondeur_annees)                            AS maxi,
       round(sum(profondeur_annees))                     AS departement_annees
FROM   r80_plafond;

\echo ''
\echo '   `sans_acte_apres_1968` n''est PAS un échec : ces départements-là ont'
\echo '   un report ouvert de 1969 à 1999, donc les plus profonds de tous.'

\echo ''
\echo '-- 2 bis. répartition de la profondeur de report'
SELECT CASE WHEN plafond_effet IS NULL      THEN 'aucun acte (report ouvert)'
            WHEN profondeur_annees <  5     THEN 'moins de 5 ans'
            WHEN profondeur_annees < 10     THEN '5 à 10 ans'
            WHEN profondeur_annees < 15     THEN '10 à 15 ans'
            WHEN profondeur_annees < 20     THEN '15 à 20 ans'
            ELSE                                 '20 ans et plus'
       END                                  AS tranche,
       count(*)                             AS departements,
       round(sum(profondeur_annees))        AS departement_annees
FROM   r80_plafond GROUP BY 1 ORDER BY 1;

\echo ''
\echo '-- 2 ter. ce que la SIGNATURE ferait perdre (donc à tort)'
SELECT count(*) FILTER (WHERE plafond_effet = plafond_signature)  AS identiques,
       count(*) FILTER (WHERE plafond_effet <> plafond_signature) AS differents,
       round(avg(plafond_effet - plafond_signature) FILTER (
             WHERE plafond_effet <> plafond_signature), 0)        AS jours_perdus
FROM   r80_plafond
WHERE  plafond_effet IS NOT NULL AND plafond_signature IS NOT NULL;

\echo ''
\echo '   Positif = l''effet est POSTÉRIEUR à la signature, donc s''arrêter à la'
\echo '   signature amputerait la fenêtre d''autant, pour rien : sur'
\echo '   [signature, effet) c''est encore la composition de 1968 qui vaut.'
\echo '   Dans `78` la même convention raccourcissait la fenêtre ; ici elle'
\echo '   l''allonge. Même fait, deux effets — c''est le sens du report qui change.'

-- ---------------------------------------------------------------------------
-- 3. CE QUI INTERDIT LE REPORT
--
-- Deux poisons, et ils ne sont pas de même nature :
--
--   a) un acte SANS DÉPARTEMENT a pu toucher n'importe lequel, donc il ABAISSE
--      potentiellement TOUS les plafonds et rien ne dit lesquels. Au 29 août
--      2026 les huit derniers ont été lus et attribués (`72` § 3 ter) : cette
--      section devrait être vide. Si elle ne l'est pas, le report avant est
--      plafonné globalement à la date trouvée.
--
--   b) un acte connu mais NON DÉPOUILLÉ ne gêne PAS : il porte son département
--      et sa date, donc il fixe le plafond correctement même si personne n'a lu
--      son texte. Il empêche seulement d'aller AU-DELÀ — c'est l'objet du § 7.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. les actes hors nomenclature métropolitaine, par nature'
SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM acte_departement d
                              WHERE d.legifrance_id = a.legifrance_id)
            THEN 'SANS DÉPARTEMENT — bloquant'
            ELSE 'outre-mer — sans effet ici' END AS nature,
       a.legifrance_id,
       coalesce(nullif(a.decret, ''), '(non numéroté)') AS decret,
       a.date_signature, a.objet
FROM   acte_cantonal a
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id
                      AND length(d.dep) = 2)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id)
  AND  a.date_signature >= :'jalon_debut'::date
ORDER  BY 1, a.date_signature;

\echo ''
\echo '-- 3 bis. le plafond global imposé par les seuls actes NON ATTRIBUÉS'
SELECT count(*)                                    AS actes_non_attribues,
       min(coalesce(e.date_effet, a.date_signature)) FILTER (
         WHERE coalesce(e.date_effet, a.date_signature) >= :'jalon_fin'::date)
                                                   AS plafond_global
FROM   acte_cantonal a
LEFT   JOIN acte_effet e ON e.legifrance_id = a.legifrance_id
WHERE  NOT EXISTS (SELECT 1 FROM acte_departement d
                    WHERE d.legifrance_id = a.legifrance_id)
  AND  NOT EXISTS (SELECT 1 FROM acte_sans_effet s
                    WHERE s.legifrance_id = a.legifrance_id);

\echo ''
\echo '   Attendu depuis le 29 août 2026 : ZÉRO acte, plafond global NULL.'
\echo '   Un acte qui reparaîtrait ici plafonnerait TOUS les départements.'

\echo ''
\echo '-- 3 ter. les actes qui prennent effet DANS l''année du jalon'
\echo '   (ils défont la composition de 1968 à l''intérieur même de sa fenêtre :'
\echo '    pour ces départements, le point de départ du report n''est pas sûr)'
SELECT p.dep, p.actes_dans_le_jalon,
       (SELECT string_agg(coalesce(nullif(a.decret,''), a.legifrance_id)
                          || ' (' || e.date_effet || ')', ', '
                          ORDER BY e.date_effet)
          FROM acte_departement d
          JOIN acte_cantonal a ON a.legifrance_id = d.legifrance_id
          JOIN acte_effet   e ON e.legifrance_id = a.legifrance_id
         WHERE d.dep = p.dep
           AND e.date_effet >= :'jalon_debut'::date
           AND e.date_effet <  :'jalon_fin'::date) AS actes
FROM   r80_plafond p
WHERE  p.actes_dans_le_jalon > 0
ORDER  BY p.dep;

\echo ''
\echo '   Rappel : `59` a posé le jalon sur [1968-01-01, 1969-01-01) parce'
\echo '   qu''un recensement dit un état à une DATE, pas une durée. Un acte'
\echo '   tombant dans cette année n''invalide pas le jalon ; il invalide'
\echo '   l''idée que le jalon vaut encore au 1er janvier 1969.'

-- ---------------------------------------------------------------------------
-- 4. LE VOLUME — ce que le report couvrirait, et par qui la place est prise
--
-- La contrainte `membership_non_chevauchant` interdit de poser là où quelque
-- chose est déjà en place. Ici l'occupation est ATTENDUE et de deux sortes,
-- qu'il faut absolument séparer :
--
--   - occupé par `79` (report arrière depuis 1999) : ce n'est pas un obstacle,
--     c'est la JONCTION. Les deux reports se rejoignent et le département est
--     couvert de bout en bout. C'est le meilleur résultat possible, et il
--     ressortirait comme un échec si on le comptait avec le reste.
--   - occupé par `74`/`75`/`76`/`77` : place prise par mieux renseigné que le
--     report — un texte de décret. Rien à regretter non plus.
--
-- `78` avait dû EXCLURE `79` de son occupation, parce qu'il mesurait sa propre
-- opportunité et voyait l'effet de son remède comme la maladie. Ici c'est
-- l'inverse : `79` est une couche étrangère et légitime, il ne faut pas
-- l'exclure — il faut le compter à part.
-- ---------------------------------------------------------------------------
-- Les traces peuvent manquer (fichiers jamais joués) : on les crée vides
-- plutôt que de conditionner les requêtes, pour que le fichier reste lisible.
CREATE TABLE IF NOT EXISTS p79_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DROP TABLE IF EXISTS r80_cible;
CREATE TABLE r80_cible AS
SELECT m.atom_id,
       m.unit_id                                       AS unit_1968,
       u.dep,
       :'jalon_fin'::date                              AS depuis,
       coalesce(p.plafond_effet, :'fin_serie'::date)   AS jusqu_a,
       p.profondeur_annees,
       p.plafond_effet IS NULL                         AS report_ouvert
FROM   membership m
JOIN   unit u       ON u.unit_id = m.unit_id AND u.niveau = 'canton'
JOIN   r80_plafond p ON p.dep = u.dep::text
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'jalon_temoin'::date;

CREATE INDEX r80_cible_idx ON r80_cible (atom_id);

ALTER TABLE r80_cible ADD COLUMN occupe_jours    integer;
ALTER TABLE r80_cible ADD COLUMN occupe_79_jours integer;

UPDATE r80_cible c
   SET occupe_jours = coalesce((
       SELECT sum(greatest(0,
                    least(m.valid_to,     c.jusqu_a)
                  - greatest(m.valid_from, c.depuis)))
       FROM   membership m
       WHERE  m.atom_id = c.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(c.depuis, c.jusqu_a, '[)')), 0),
       occupe_79_jours = coalesce((
       SELECT sum(greatest(0,
                    least(m.valid_to,     c.jusqu_a)
                  - greatest(m.valid_from, c.depuis)))
       FROM   membership m
       WHERE  m.atom_id = c.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(c.depuis, c.jusqu_a, '[)')
         AND  EXISTS (SELECT 1 FROM p79_trace t
                       WHERE t.quoi = 'membership'
                         AND t.cle  = m.membership_id::text)), 0);

\echo ''
\echo '-- 4. le volume du report avant'
SELECT count(*)                                                   AS atomes_1968,
       count(*) FILTER (WHERE occupe_jours = 0)                   AS fenetre_libre,
       count(*) FILTER (WHERE occupe_jours > 0
                          AND occupe_79_jours = occupe_jours)     AS occupee_par_79_seul,
       count(*) FILTER (WHERE occupe_jours > 0
                          AND occupe_79_jours < occupe_jours)     AS occupee_par_un_decret,
       count(*) FILTER (WHERE occupe_jours >= (jusqu_a - depuis))  AS deja_pleine,
       round(sum(profondeur_annees) FILTER (WHERE occupe_jours = 0)
             / 1000.0, 1)                                         AS milliers_atome_annees
FROM   r80_cible;

\echo ''
\echo '-- 4 bis. les 15 départements où le report avant rend le plus'
SELECT c.dep,
       max(c.profondeur_annees)                   AS annees,
       count(*)                                   AS atomes,
       count(*) FILTER (WHERE c.occupe_jours = 0) AS libres,
       bool_or(c.report_ouvert)                   AS aucun_acte,
       round(max(c.profondeur_annees)
             * count(*) FILTER (WHERE c.occupe_jours = 0))  AS atome_annees
FROM   r80_cible c
GROUP  BY c.dep
ORDER  BY atome_annees DESC NULLS LAST
LIMIT  15;

-- ---------------------------------------------------------------------------
-- 5. LA JONCTION — les deux reports se rencontrent-ils ?
--
-- Le report avant monte de 1969 au premier acte ; le report arrière de `79`
-- descend de 1999 au dernier acte. Un département dont le PREMIER acte est
-- aussi le DERNIER — ou qui n'en a aucun — voit les deux fenêtres se toucher
-- ou se recouvrir : il est alors couvert **de bout en bout, 1969 à 1999**,
-- sans qu'aucun texte de décret ait eu besoin d'être lu.
--
-- C'est le chiffre qui décide si ce chantier vaut la peine. Il ne se déduit
-- d'aucun des deux fichiers pris seul.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. la jonction, par département'
SELECT CASE
         WHEN plafond_effet IS NULL
           THEN 'aucun acte — couvert de bout en bout'
         WHEN plancher_effet IS NOT NULL AND plafond_effet >= plancher_effet
           THEN 'un seul acte — les deux reports se touchent'
         ELSE 'plusieurs actes — il reste un intervalle noir'
       END                                        AS situation,
       count(*)                                   AS departements,
       round(sum(profondeur_annees))              AS dep_annees_gagnees_par_l_avant
FROM   r80_plafond
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 5 bis. l''intervalle noir qui resterait, département par département'
\echo '   (du premier acte au dernier : ce que ni `79` ni `80` n''atteignent)'
SELECT dep,
       plafond_effet                 AS premier_acte,
       plancher_effet                AS dernier_acte,
       round((plancher_effet - plafond_effet) / 365.25, 1) AS annees_noires,
       actes_dans_le_trou            AS actes,
       non_depouilles
FROM   r80_plafond
WHERE  plafond_effet IS NOT NULL
  AND  plancher_effet IS NOT NULL
  AND  plancher_effet > plafond_effet
ORDER  BY annees_noires DESC, dep
LIMIT  20;

\echo ''
\echo '-- 5 ter. le total de l''intervalle noir'
SELECT count(*)                                                    AS departements,
       round(sum((plancher_effet - plafond_effet) / 365.25))        AS dep_annees_noires,
       sum(actes_dans_le_trou)                                      AS actes_a_l_interieur,
       sum(non_depouilles)                                          AS dont_non_depouilles
FROM   r80_plafond
WHERE  plafond_effet IS NOT NULL AND plancher_effet IS NOT NULL
  AND  plancher_effet > plafond_effet;

-- ---------------------------------------------------------------------------
-- 6. LE CONTRÔLE — 1968 contre 1999, et il peut tuer le report
--
-- Deux lectures indépendantes : le recensement de 1968 océrisé (`59`) et le
-- COG 1999 de l'INSEE (`24`). Aucune n'a vu l'autre.
--
-- L'HYPOTHÈSE TESTÉE N'EST PAS « le report est bon » mais « LE REGISTRE DES
-- ACTES SAIT QUAND UN DÉPARTEMENT A BOUGÉ ». C'est elle qui fonde `78`, `79`
-- et ce fichier. Elle prédit une chose vérifiable :
--
--   accord 1968/1999 dans les départements SANS acte  >>  accord là où il y en a
--
-- Si la pente existe, le registre voit les mouvements et le report tient. Si
-- les deux taux sont voisins, des mouvements échappent au registre, et alors
-- `79` aussi est en cause — 36 296 rattachements reposent dessus.
--
-- Le taux global 1968/1999 est déjà connu : 88,3 % (`59`). C'est le témoin
-- auquel comparer, et il mêle les deux populations.
--
-- ===========================================================================
-- CE § A ÉTÉ JOUÉ LE 30 AOÛT 2026 ET IL NE CONCLUT RIEN. DEUX DÉFAUTS.
-- ===========================================================================
--     1 acte 88,31 %  |  2 ou 3 actes 91,27 %  |  4 et plus 88,75 %
--
-- **1. LE TÉMOIN N'EXISTE PAS.** La ligne « 0 acte » est VIDE : tout
-- département pourvu d'atomes en 1968 porte au moins un acte. La comparaison
-- annoncée — sans acte contre avec actes — n'a jamais eu de premier terme.
-- *Une mesure sans témoin n'est pas une mesure* : c'est la leçon du § 6 ter de
-- `66`, écrite dans ce dépôt il y a deux jours, et je l'ai refaite.
--
-- **2. LA STRATE NE SÉPARE PAS CE QU'ELLE PRÉTEND SÉPARER.** Le nombre d'actes
-- n'est pas le volume de changement. Et surtout : 74 départements sur 98 ont
-- pour premier acte la salve du 23 septembre 1973 — le plus gros redécoupage
-- de la période. La catégorie « 1 acte » n'est donc pas le groupe qui a peu
-- bougé, c'est le groupe qui n'a reçu QUE l'événement majeur. Les strates sont
-- confondues à la racine, et une courbe plate n'y démontre rien.
--
-- ***Un test qui ne pouvait pas montrer la pente ne réfute pas la pente.***
-- Lire ce plateau comme une réfutation aurait été plus grave que l'écrire :
-- il aurait condamné `79` sur une mesure incapable.
--
-- Le test valide est au § 6 quinquies : il compare, DANS UN MÊME DÉPARTEMENT,
-- les atomes qu'un décret nomme et ceux qu'aucun décret ne nomme. Le §§ 6 à
-- 6 quater est conservé tel quel — un résultat qui ne conclut pas reste un
-- résultat, et l'effacer masquerait le défaut au lieu de l'enseigner.
--
-- CE QUE LE CONTRÔLE NE PEUT PAS FAIRE : un désaccord ne dit pas laquelle des
-- deux lectures a tort. `59` mesure lui-même 79,9 % de rattachements `ferme`
-- et 3,1 % de `canton_conteste` — une part du désaccord est de l'OCR, pas de
-- l'histoire. Le § 6 ter restreint donc aux atomes `ferme` des deux côtés,
-- ce qui est la seule façon d'isoler la question posée.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r80_controle;
CREATE TABLE r80_controle AS
SELECT c.atom_id,
       c.dep,
       c.unit_1968,
       (SELECT n.unit_id FROM membership n
         WHERE n.atom_id = c.atom_id
           AND n.niveau  = 'canton'
           AND n.periode @> :'date_1999'::date
         LIMIT 1)                                    AS unit_1999,
       p.actes_dans_le_trou,
       p.plafond_effet IS NULL                       AS aucun_acte
FROM   r80_cible c
JOIN   r80_plafond p ON p.dep = c.dep;

CREATE INDEX r80_controle_idx ON r80_controle (atom_id);

\echo ''
\echo '-- 6. l''accord 1968/1999 selon le nombre d''actes enregistrés'
SELECT CASE WHEN aucun_acte              THEN '0 acte'
            WHEN actes_dans_le_trou = 1  THEN '1 acte'
            WHEN actes_dans_le_trou <= 3 THEN '2 ou 3 actes'
            ELSE                              '4 actes et plus'
       END                                                        AS registre,
       count(*)                                                   AS atomes,
       count(*) FILTER (WHERE unit_1999 IS NULL)                  AS absents_en_1999,
       count(*) FILTER (WHERE unit_1999 = unit_1968)              AS accord,
       round(100.0 * count(*) FILTER (WHERE unit_1999 = unit_1968)
             / nullif(count(*) FILTER (WHERE unit_1999 IS NOT NULL), 0), 2)
                                                                  AS pct_accord
FROM   r80_controle
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '   LECTURE. La colonne `pct_accord` doit DÉCROÎTRE de haut en bas. Si'
\echo '   elle est plate, le registre ne capte pas les mouvements et le report'
\echo '   — celui de `79` compris — repose sur une hypothèse fausse.'
\echo '   Témoin : 88,3 % toutes populations confondues (`59`),'
\echo '            89,8 % pour 1954 -> 1968 (accord des partitions, `66`).'

\echo ''
\echo '-- 6 bis. les départements sans acte, un par un'
SELECT c.dep,
       count(*)                                                   AS atomes,
       count(*) FILTER (WHERE c.unit_1999 = c.unit_1968)          AS accord,
       round(100.0 * count(*) FILTER (WHERE c.unit_1999 = c.unit_1968)
             / nullif(count(*) FILTER (WHERE c.unit_1999 IS NOT NULL), 0), 1)
                                                                  AS pct
FROM   r80_controle c
WHERE  c.aucun_acte
GROUP  BY c.dep
ORDER  BY pct NULLS LAST
LIMIT  25;

\echo ''
\echo '   Un département sans acte et à faible accord est un TROU DU REGISTRE,'
\echo '   pas un département stable. C''est la liste à lire en premier — et'
\echo '   c''est aussi celle où `79` a reporté le plus loin, donc le plus risqué.'

-- Le contrôle restreint aux lectures fermes des deux côtés. `c68_qualite`
-- existe depuis `59` ; si elle manque (fichier non rejoué), la section se
-- signale au lieu de mentir par omission.
DO $$
BEGIN
    IF to_regclass('histgis.c68_qualite') IS NULL THEN
        RAISE NOTICE '§ 6 ter INDISPONIBLE : c68_qualite absente (rejouer 59).';
    END IF;
END $$;

\echo ''
\echo '-- 6 ter. le même contrôle, sur les seules lectures FERMES de 1968'
SELECT CASE WHEN c.aucun_acte              THEN '0 acte'
            WHEN c.actes_dans_le_trou = 1  THEN '1 acte'
            WHEN c.actes_dans_le_trou <= 3 THEN '2 ou 3 actes'
            ELSE                                '4 actes et plus'
       END                                                        AS registre,
       count(*)                                                   AS atomes_fermes,
       round(100.0 * count(*) FILTER (WHERE c.unit_1999 = c.unit_1968)
             / nullif(count(*) FILTER (WHERE c.unit_1999 IS NOT NULL), 0), 2)
                                                                  AS pct_accord
FROM   r80_controle c
WHERE  EXISTS (SELECT 1 FROM membership m
                JOIN c68_qualite q ON q.membership_id = m.membership_id
               WHERE m.atom_id = c.atom_id
                 AND m.niveau  = 'canton'
                 AND m.periode @> :'jalon_temoin'::date
                 AND q.qualite = 'ferme')
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '   Si la pente du § 6 disparaît ici, elle était de l''OCR et non de'
\echo '   l''histoire. Si elle se renforce, elle est réelle.'

\echo ''
\echo '-- 6 quater. les désaccords en département SANS acte, vus de près'
SELECT c.atom_id, c.dep,
       c.unit_1968, unit_nom(c.unit_1968, :'jalon_temoin'::date) AS nom_1968,
       c.unit_1999, unit_nom(c.unit_1999, :'date_1999'::date)    AS nom_1999
FROM   r80_controle c
WHERE  c.aucun_acte
  AND  c.unit_1999 IS NOT NULL
  AND  c.unit_1999 <> c.unit_1968
ORDER  BY c.dep, c.atom_id
LIMIT  25;

-- ---------------------------------------------------------------------------
-- 6 quinquies. LE CONTRÔLE QUI, LUI, PEUT CONCLURE
--
-- Le § 6 comparait des DÉPARTEMENTS entre eux, et échouait pour cela : ils ne
-- diffèrent pas seulement par leur activité cantonale mais par la qualité de
-- l'OCR de 1968 (Belfort 67,9 %, Corse 85,9 %, Moselle 86,5 % — `66`), et la
-- salve de 1973 les a presque tous touchés.
--
-- On compare donc, DANS LE MÊME DÉPARTEMENT, deux populations d'atomes :
--
--   nommés     l'atome figure dans la composition d'au moins un décret de
--              1968-1999 (`acte_composition.atome`, rempli par `72` § 4).
--              Le registre affirme que quelque chose lui est arrivé.
--   jamais nommés   aucun décret ne le cite. Le registre affirme que rien ne
--              lui est arrivé entre 1969 et 1999.
--
-- Si le registre dit vrai, l'accord 1968/1999 doit être NETTEMENT plus haut
-- chez les jamais-nommés. Le département étant le même, l'OCR est le même, la
-- salve de 1973 est la même : le confondant du § 6 disparaît.
--
-- LE BIAIS RESTANT, ET SON SENS — un décret nomme les cantons qu'il crée ou
-- modifie, jamais ceux qu'il vide. Des atomes réellement déplacés sont donc
-- classés « jamais nommés » et y font BAISSER l'accord. Le biais joue contre
-- l'hypothèse : un accord élevé chez les jamais-nommés est acquis malgré lui,
-- un accord faible peut n'être que lui. *Un biais dont on connaît le sens
-- n'invalide qu'une moitié des conclusions* — et c'est celle qu'on cherche
-- qui survit.
--
-- Seconde limite, honnête : `acte_composition` ne porte que les actes
-- DÉPOUILLÉS. Dans les 42 départements aux 86 actes non lus, des atomes
-- nommés par un acte jamais ouvert tombent aussi chez les jamais-nommés.
-- Même sens de biais. Le § 6 septies restreint aux 54 départements
-- intégralement dépouillés, où cette seconde limite n'existe pas.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS r80_nomme;
CREATE TABLE r80_nomme AS
SELECT DISTINCT c.atome AS atom_id
FROM   acte_composition c
WHERE  c.atome IS NOT NULL
  AND  c.date_acte >= :'jalon_debut'::date
  AND  c.date_acte <  :'fin_serie'::date;

ALTER TABLE r80_nomme ADD PRIMARY KEY (atom_id);

\echo ''
\echo '-- 6 quinquies. nommés par un décret contre jamais nommés'
SELECT CASE WHEN n.atom_id IS NOT NULL
            THEN 'nommé par un décret — le registre dit : ça a bougé'
            ELSE 'jamais nommé — le registre dit : rien n''a bougé' END AS registre,
       count(*)                                                   AS atomes,
       count(*) FILTER (WHERE c.unit_1999 = c.unit_1968)          AS accord,
       round(100.0 * count(*) FILTER (WHERE c.unit_1999 = c.unit_1968)
             / nullif(count(*) FILTER (WHERE c.unit_1999 IS NOT NULL), 0), 2)
                                                                  AS pct_accord
FROM   r80_controle c
LEFT   JOIN r80_nomme n ON n.atom_id = c.atom_id
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '   LECTURE. C''est l''écart entre les deux lignes qui juge, et lui seul.'
\echo '   Un écart franc : le registre voit les mouvements, `79` et `80` tiennent.'
\echo '   Un écart nul   : le registre ne les voit pas, et le report est mort'
\echo '                    dans les deux sens.'

-- La comparaison APPARIÉE. Chaque département fournit ses deux taux ; on
-- regarde le signe de l'écart, département par département. Un test de signe
-- ne suppose aucune homogénéité entre départements — c'est précisément ce que
-- le § 6 supposait à tort.
DROP TABLE IF EXISTS r80_apparie;
CREATE TABLE r80_apparie AS
SELECT c.dep,
       count(*) FILTER (WHERE n.atom_id IS NOT NULL)              AS n_nommes,
       count(*) FILTER (WHERE n.atom_id IS NULL)                  AS n_jamais,
       round(100.0 * count(*) FILTER (WHERE n.atom_id IS NOT NULL
                                        AND c.unit_1999 = c.unit_1968)
             / nullif(count(*) FILTER (WHERE n.atom_id IS NOT NULL
                                        AND c.unit_1999 IS NOT NULL), 0), 1)
                                                                  AS pct_nommes,
       round(100.0 * count(*) FILTER (WHERE n.atom_id IS NULL
                                        AND c.unit_1999 = c.unit_1968)
             / nullif(count(*) FILTER (WHERE n.atom_id IS NULL
                                        AND c.unit_1999 IS NOT NULL), 0), 1)
                                                                  AS pct_jamais
FROM   r80_controle c
LEFT   JOIN r80_nomme n ON n.atom_id = c.atom_id
GROUP  BY c.dep;

\echo ''
\echo '-- 6 sexies. le test de signe, département par département'
\echo '   (seuls les départements offrant au moins 20 atomes de chaque côté)'
SELECT count(*)                                              AS departements,
       count(*) FILTER (WHERE pct_jamais > pct_nommes)       AS jamais_mieux,
       count(*) FILTER (WHERE pct_jamais < pct_nommes)       AS nommes_mieux,
       count(*) FILTER (WHERE pct_jamais = pct_nommes)       AS ex_aequo,
       round((percentile_cont(0.5) WITHIN GROUP (
              ORDER BY pct_jamais - pct_nommes))::numeric, 1) AS ecart_median
FROM   r80_apparie
WHERE  n_nommes >= 20 AND n_jamais >= 20
  AND  pct_nommes IS NOT NULL AND pct_jamais IS NOT NULL;

\echo ''
\echo '   Sous l''hypothèse NULLE (le registre ne sait rien), `jamais_mieux` et'
\echo '   `nommes_mieux` doivent être à peu près égaux et l''écart médian nul.'
\echo '   Le seuil de 20 atomes écarte les départements où un taux se calcule'
\echo '   sur trois communes et ne veut rien dire.'

\echo ''
\echo '-- 6 septies. le même test, sur les 54 départements intégralement dépouillés'
\echo '   (là, « jamais nommé » veut vraiment dire « aucun décret ne le cite »)'
SELECT count(*)                                              AS departements,
       count(*) FILTER (WHERE a.pct_jamais > a.pct_nommes)   AS jamais_mieux,
       count(*) FILTER (WHERE a.pct_jamais < a.pct_nommes)   AS nommes_mieux,
       round((percentile_cont(0.5) WITHIN GROUP (
              ORDER BY a.pct_jamais - a.pct_nommes))::numeric, 1) AS ecart_median
FROM   r80_apparie a
JOIN   r80_plafond p ON p.dep = a.dep
WHERE  a.n_nommes >= 20 AND a.n_jamais >= 20
  AND  a.pct_nommes IS NOT NULL AND a.pct_jamais IS NOT NULL
  AND  p.non_depouilles = 0 AND p.actes_dans_le_trou > 0;

\echo ''
\echo '-- 6 octies. les 20 départements où l''écart est le plus défavorable'
\echo '   (jamais-nommés qui s''accordent MOINS bien que les nommés : anomalie)'
SELECT a.dep, a.n_nommes, a.n_jamais, a.pct_nommes, a.pct_jamais,
       a.pct_jamais - a.pct_nommes AS ecart,
       p.non_depouilles
FROM   r80_apparie a
JOIN   r80_plafond p ON p.dep = a.dep
WHERE  a.n_nommes >= 20 AND a.n_jamais >= 20
  AND  a.pct_nommes IS NOT NULL AND a.pct_jamais IS NOT NULL
ORDER  BY ecart
LIMIT  20;

\echo ''
\echo '   Un département en tête de cette liste est soit un trou du registre,'
\echo '   soit un département dont l''OCR de 1968 est mauvais là où les décrets'
\echo '   ne passent pas. `c68_qualite` tranche — c''est le § 6 ter du même'
\echo '   fichier, à refaire sur cette partition si la liste n''est pas vide.'

-- ---------------------------------------------------------------------------
-- 7. LE CHAÎNAGE — combien de départements sont intégralement dépouillés ?
--
-- Le report avant s'arrête au premier acte, le report arrière au dernier. Ce
-- qui est entre les deux ne s'atteint qu'en repartant de la composition que
-- chaque acte donne — c'est-à-dire en ayant LU l'acte.
--
-- Un département dont TOUS les actes 1969-1999 sont dépouillés est donc
-- candidat à une couverture continue par chaînage : c'est le fichier `81`, et
-- c'est ce § qui dit s'il vaut d'être écrit.
--
-- RÉSERVE À NE PAS OUBLIER : un décret donne la composition des cantons qu'il
-- crée ou modifie, jamais celle des 4 000 autres. « Acte dépouillé » autorise
-- à franchir sa date ; cela ne garantit pas la composition des cantons qu'il a
-- vidés sans les nommer. C'est le défaut connu de `75`/`76`, et il se paiera
-- ici. *Un acte lu n'est pas un acte entièrement connu.*
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 7. les départements candidats au chaînage'
SELECT CASE WHEN actes_dans_le_trou = 0 THEN 'aucun acte — déjà couvert par `80` + `79`'
            WHEN non_depouilles   = 0 THEN 'tous les actes dépouillés — chaînable'
            ELSE                           'actes non dépouillés — bloqué'
       END                                  AS situation,
       count(*)                             AS departements,
       sum(actes_dans_le_trou)              AS actes,
       sum(non_depouilles)                  AS non_depouilles
FROM   r80_plafond
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '-- 7 bis. les actes à lire, par département — la file de travail'
SELECT dep, actes_dans_le_trou AS actes, non_depouilles,
       round((plancher_effet - plafond_effet) / 365.25, 1) AS annees_noires
FROM   r80_plafond
WHERE  non_depouilles > 0
ORDER  BY non_depouilles DESC, annees_noires DESC NULLS LAST
LIMIT  20;

-- ---------------------------------------------------------------------------
-- 8. LES TÉMOINS
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 8. les repères déjà mesurés par le dépôt'
\echo '   1940 -> 1954, 14 ans,  3 créations  : 99,50 % (accord par commune, `70`)'
\echo '   1954 -> 1968, 14 ans, 30 créations  : 89,80 % (accord des partitions, `66`)'
\echo '   1968 -> 1999, toutes populations    : 88,30 % (`59`)'
\echo '   transferts non datés imputés        :  0,29 % des communes en 14 ans'
\echo ''
\echo '   Le report d''ici est CONTINU avec celui de `79` : les deux partagent'
\echo '   la même hypothèse, et le § 6 la teste pour les deux à la fois. Un'
\echo '   verdict négatif ne condamnerait pas seulement `80`.'

\echo ''
\echo '-- 8 bis. ce que le registre ne peut pas voir'
SELECT 'transferts isolés non datés au registre cantonal' AS angle_mort,
       274                                                AS ordre_de_grandeur,
       'l''annexe VII ne les recense jamais, par construction' AS pourquoi;

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo ' Tables jetables laissées en place : r80_plafond, r80_cible,'
\echo ' r80_controle.'
\echo ''
\echo ' À LIRE DANS CET ORDRE : § 6 d''abord — si la pente n''y est pas,'
\echo ' le reste du fichier ne vaut rien, et `79` non plus.'
\echo '============================================================'

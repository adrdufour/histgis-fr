-- ============================================================================
-- histgis — 64_composition_1815_stage.sql : les découpages de 1815-1870
--
--   cd ~/Téléchargements/projet_carte        <-- le \copy résout depuis ICI
--   psql -d histgis -f sql/64_composition_1815_stage.sql
--
-- CE FICHIER N'ÉCRIT NI DANS `atom` NI DANS `membership`. Décision du 22 août
-- 2026, et c'est le point principal.
--
-- POURQUOI ON NE POSE PAS DE RATTACHEMENTS
-- ========================================
-- **La base ne contient aucun atome avant 1870.** Mesuré : le plus ancien
-- `membership` s'ouvre au 1er janvier 1870, pour les cantons comme pour les
-- circonscriptions.
--
-- Gaudillère garantit qu'aucun CANTON n'a bougé entre 1815 et 1870 dans ces
-- trois départements. Mais les COMMUNES, elles, ont bougé — créations, fusions,
-- scissions — et nous n'avons aucune source pour ces mouvements-là : le fichier
-- INSEE commence en 1943, TRF-GIS en 1870.
--
-- Poser les rattachements de 1815 sur les atomes de 1870 reviendrait donc à
-- **affirmer que la carte communale de 1815 est celle de 1870**. C'est faux
-- d'un nombre inconnu de communes, et — c'est le pire — parfaitement invisible à
-- toute recette : la couverture bouclerait, aucun atome ne serait orphelin.
-- Exactement le profil de l'Ain, et celui des villes divisées trouvé le même
-- jour.
--
-- On dépose donc la composition CANTONALE, qui est ce que la source dit, et
-- l'on s'arrête là. `snapshot(1830)` ne renverra rien plutôt qu'une géométrie
-- inventée.
--
-- CE QUE LA TABLE CONTIENT
-- ========================
-- Une ligne par (département, période, circonscription, canton) — 434 lignes
-- pour trois départements et quatorze périodes, reconstruites par
-- `circo/remonte_1815.py` à partir de la composition de 1876 déjà en base.
--
-- L'atlas décrit chaque découpage PAR DIFFÉRENCE avec un autre : 1852 par
-- rapport à 1876, 1820 par rapport à 1852, 1831 par rapport à 1815, 1815 par
-- rapport à 1876. La colonne `base` garde la trace de cette chaîne.
--
-- LA RECETTE, DÉJÀ PASSÉE
-- =======================
-- Les quatorze périodes forment chacune une PARTITION des cantons vivants du
-- département : chacun dans une circonscription et une seule, aucun oublié.
-- C'est un filet contre les fautes de saisie, pas une preuve d'exactitude —
-- une permutation de deux circonscriptions y passerait au travers.
--
-- CE QUI EST INTERPRÉTÉ, ET SIGNALÉ COMME TEL
-- ===========================================
-- `interprete = oui` sur **5 lignes** : les Vosges en 1824-1828. L'atlas dit ce
-- que deviennent les 1re, 2e, 4e et 5e circonscriptions de 1831 et ne dit RIEN
-- de la 3e (Bulgnéville, Châtenois, Coussey, Lamarche, Neufchâteau). Lecture
-- retenue : ce qui n'est pas mentionné ne change pas.
--
-- Deux autres réserves, hors table :
--   * le « canton de Bains » des Vosges — la nomenclature porte Bains-les-Bains
--     ET Plombières-les-Bains ; on a retenu le premier, et la partition est
--     valide dans les deux cas, donc la recette ne peut pas trancher ;
--   * Saales et Schirmeck sont cités par l'atlas pour 1852-1870 mais n'ont plus
--     d'atome français en 1876 — l'annexion de 1871 les a retirés.
--
-- LES PÉRIODES ABSENTES LE SONT EXPRÈS
-- ====================================
-- 1848-1852 partout (la Deuxième République vote au scrutin de liste
-- départemental) et 1820-1831 / 1828-1831 pour les Vosges (« pas de découpage,
-- collège de département »). Rien n'y est posé.
--
-- Prérequis : aucun sur le modèle. Crée sa propre table `c15_composition`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' DÉCOUPAGES 1815-1870 — dépôt de la composition cantonale'
\echo '============================================================'

DROP TABLE IF EXISTS c15_composition;
CREATE TABLE c15_composition (
    dep             char(2),
    departement     text,
    depuis          smallint,
    jusqu           smallint,
    base            text,      -- le découpage de référence de la règle
    circonscription text,      -- numéro ou nom, selon ce que dit l'atlas
    canton          text,      -- nom de la NOMENCLATURE, pas celui de l'atlas
    interprete      text       -- 'oui' : non mentionné par l'atlas, reconduit
);

\copy c15_composition FROM 'circo/composition_1815_1870.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 1. ce qui est déposé'
SELECT count(*)                                   AS lignes,
       count(DISTINCT dep)                        AS departements,
       count(DISTINCT (dep, depuis))              AS periodes,
       count(*) FILTER (WHERE interprete = 'oui') AS lignes_interpretees
FROM   c15_composition;

\echo ''
\echo '-- 2. par département et par période'
SELECT dep, departement, depuis, jusqu, base,
       count(DISTINCT circonscription) AS circos,
       count(*)                        AS cantons
FROM   c15_composition
GROUP  BY dep, departement, depuis, jusqu, base
ORDER  BY dep, depuis DESC;

-- ---------------------------------------------------------------------------
-- 3. La recette, rejouée depuis la BASE et non depuis le script
--
-- `remonte_1815.py` vérifie déjà la partition. La refaire ici n'est pas une
-- redite : elle porte sur ce qui a été CHARGÉ, pas sur ce qui a été calculé.
-- Un \copy tronqué ou un encodage fautif passerait inaperçu autrement.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. recette : aucun canton dans deux circonscriptions à la même période'
SELECT dep, depuis, canton, count(*) AS n_circos
FROM   c15_composition
GROUP  BY dep, depuis, canton
HAVING count(*) > 1;

\echo ''
\echo '   (aucune ligne ci-dessus = partition disjointe)'

\echo ''
\echo '-- 4. les cantons cités existent-ils dans la nomenclature ?'
SELECT c.dep, count(DISTINCT c.canton) AS cantons_inconnus,
       string_agg(DISTINCT c.canton, ', ') AS lesquels
FROM   c15_composition c
WHERE  NOT EXISTS (SELECT 1 FROM unit u
                    WHERE u.niveau = 'canton' AND u.dep = c.dep
                      AND u.nom = c.canton)
GROUP  BY c.dep;

\echo ''
\echo '   (aucune ligne = tous les noms concordent avec `unit`)'

\echo ''
\echo '-- 5. les 5 lignes interprétées, nommées'
SELECT dep, depuis, jusqu, circonscription, canton
FROM   c15_composition WHERE interprete = 'oui'
ORDER  BY dep, depuis, canton;

\echo ''
\echo '============================================================'
\echo ' Rien dans atom ni membership. La composition cantonale est'
\echo ' ce que la source dit ; la géométrie communale de 1815 n''est'
\echo ' pas connue, et ne sera pas inventée.'
\echo '============================================================'

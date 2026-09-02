-- ============================================================================
-- histgis — 61_cantons_disparus_diag.sql : les cantons que la nomenclature
--                                          ne peut pas connaître
--
--   psql -d histgis -f sql/61_cantons_disparus_diag.sql
--
-- LECTURE SEULE. Aucun canton n'est créé ici.
--
-- LE PROBLÈME, ÉNONCÉ APRÈS FORBACH-II
-- ====================================
-- `unit` est faite de deux sources : TRF-GIS (1870-1940) et le COG (1999-2012).
-- **Un canton créé après 1940 et supprimé avant 1999 n'est dans ni l'une ni
-- l'autre.** Il est invisible par construction — et le recensement de 1968 est
-- la seule source du dépôt qui le voie.
--
-- Forbach-II (D. 8.8.1967 - D. 24.12.1984) en était un. L'annexe VII de
-- Gaudillère en documente **29 créations entre 1954 et 1968** dans 18
-- départements, très majoritairement urbaines, dont beaucoup disparaissent dès
-- 1973.
--
-- Conséquence mesurée par `58` et mal interprétée sur le moment : les
-- départements les plus mal lus (92, 13, 94, 93, 06, 69, 90) ne souffraient pas
-- d'une mise en page particulière. **Leurs cantons de 1968 n'existent plus en
-- 1999.** Le Territoire de Belfort à 59 % d'accord avec 1999 s'explique par les
-- sept cantons créés le 9 août 1967.
--
-- CE QUE CE FICHIER FAIT
-- ======================
-- Il confronte les cantons cités par 1968 et inconnus de `unit` à la liste des
-- créations documentées, et sépare deux populations qui se ressemblent :
--
--   * un canton inconnu à effectif SUBSTANTIEL, dans un département où une
--     création est documentée à la bonne date : candidat sérieux ;
--   * un canton inconnu cité une ou deux fois : un code mal lu, conforme à la
--     table de confusion (« 3 » lu « 5 » ou « 8 »).
--
-- CE QU'IL NE FAIT PAS, ET POURQUOI
-- =================================
-- Il ne nomme pas les cantons. L'annexe VII donne des NOMS (« Cr. Nice-5 et
-- Nice-6 »), le recensement donne des CODES (`0641`) : l'appariement des deux
-- demande, pour chaque département, de comparer les compositions à une source
-- publiée — c'est ce qu'a exigé Forbach-II, seize communes vérifiées une à une.
--
-- **Un canton posé sur un appariement automatique nom/code serait un canton
-- inventé.** Le fichier prépare le travail, il ne le fait pas.
--
-- Prérequis : sql/58_cog1968_stage.sql.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.c68_lien') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/58_cog1968_stage.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Les créations documentées, transcrites de l'annexe VII de Gaudillère
--
-- Le cadre « 78O » (Seine-et-Oise) est écarté : le département a disparu en
-- 1968 et ses codes ne se rapportent à rien dans la nomenclature actuelle.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c61_creation;
CREATE TABLE c61_creation (dep char(2), date_texte date, texte text);

INSERT INTO c61_creation (dep, date_texte, texte) VALUES
  ('06', '1955-01-19', 'Cr. Nice-5 et Nice-6 (division Nice-2, 3 et 4)'),
  ('06', '1957-10-21', 'Cr. Le Cannet (division Cannes)'),
  ('14', '1967-08-08', 'Cr. Caen-N. et Caen-S. (division Caen-E. et Caen-O.)'),
  ('26', '1964-01-28', 'Cr. Valence-N. et Valence-S. (dédoublement Valence)'),
  ('33', '1957-09-24', 'Cr. Mérignac (division Pessac)'),
  ('37', '1956-08-04', 'Cr. Tours-E. et Tours-O. (division Tours-S.)'),
  ('49', '1961-08-10', 'Cr. Cholet-O. et Cholet-E. (dédoublement Cholet)'),
  ('49', '1964-01-28', 'Cr. Angers-N. et Angers-E. (dédoublement Angers-N.E.)'),
  ('57', '1967-08-08', 'Cr. Forbach-1 et Forbach-2 (dédoublement Forbach)'),
  ('57', '1967-08-08', 'Cr. Florange (division Hayange)'),
  ('57', '1967-08-08', 'Cr. Montigny-les-Metz, Rombas et Woippy (division de Metz-Campagne qui disparaît)'),
  ('57', '1967-08-08', 'Cr. Freyming (division St-Avold)'),
  ('57', '1967-08-08', 'Cr. Basse-Yutz (division Thionville)'),
  ('59', '1958-03-26', 'Cr. Hautmont (Maubeuge-N. + Bavay)'),
  ('59', '1964-01-28', 'Cr. Marcq-en-Baroeul (division Tourcoing-S.)'),
  ('62', '1962-01-10', 'Cr. Bruay-en-Artois, Hénin-Liétard, Lens-N.E., Lens-N.O., Liévin-N., Liévin-N.O. (division de Carvin, Houdain, Lens-E. et Liévin)'),
  ('67', '1962-01-22', 'Cr. Strasbourg-5, Strasbourg-6, Strasbourg-7 et Strasbourg-8 (division des 4 anciens cantons)'),
  ('68', '1958-02-26', 'Cr. Colmar-N. et Colmar-S. (dédoublement Colmar)'),
  ('68', '1958-02-26', 'Cr. Mulhouse-O., Mulhouse-E. et Wittenheim (division Mulhouse-N. et Mulhouse-S.)'),
  ('69', '1959-02-19', 'Cr. VIIIe Arrondissement de Lyon'),
  ('69', '1964-01-10', 'Cr. Villeurbanne-N., Villeurbanne-S. et Bron (division Villeurbanne, qui disparaît)'),
  ('69', '1964-01-28', 'Cr. Lyon-13 (division Lyon-12)'),
  ('69', '1964-08-12', 'Cr. IXe Arrondissement de Lyon'),
  ('72', '1967-08-08', 'Cr. Le Mans-Centre, Le Mans-E., Le Mans-N., Le Mans-N.-O., Le Mans-S. et Le Mans-S.-O. (division des 3 anciens cantons du Mans)'),
  ('76', '1964-01-28', 'Cr. Le Havre-7 (division Le Havre-3 à 6)'),
  ('77', '1964-07-29', 'Cr. Chelles (division Lagny)'),
  ('78', '1966-06-02', 'Cr. St-Arnoult-en-Yvelines'),
  ('83', '1964-01-28', 'Cr. Toulon-5 (division Toulon-1 et Toulon-3)'),
  ('90', '1967-08-09', 'Cr. Belfort-Centre, Belfort-E., Belfort-N., Belfort-O., Chatenais-les-Forges, Danjoutin et Valdoie (division Belfort qui disparaît)');

\echo ''
\echo '-- 1. créations cantonales documentées entre 1954 et 1968'
SELECT count(*) AS creations, count(DISTINCT dep) AS departements FROM c61_creation;

-- ---------------------------------------------------------------------------
-- 2. Les cantons que 1968 cite et que la nomenclature ignore
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c61_inconnu;
CREATE TABLE c61_inconnu AS
SELECT l.dep,
       l.canton_id,
       count(*)                                   AS communes,
       count(*) FILTER (WHERE l.accord = 'deux')  AS lues_deux_fois,
       count(DISTINCT l.arr_lu)                   AS arrondissements,
       string_agg(l.nom, ', ' ORDER BY l.insee)   AS composition
FROM   (SELECT c.*, s.arr AS arr_lu
          FROM c68_lien c JOIN c68_src s
            ON s.insee = c.insee AND s.dep || s.canton = c.canton_id) l
WHERE  NOT l.canton_connu
GROUP  BY l.dep, l.canton_id;

\echo ''
\echo '-- 2. répartition des cantons inconnus par effectif'
SELECT CASE WHEN communes >= 8 THEN 'a. 8 et plus'
            WHEN communes >= 5 THEN 'b. 5 a 7'
            WHEN communes >= 3 THEN 'c. 3 ou 4'
            ELSE                    'd. 1 ou 2' END  AS classe,
       count(*)      AS cantons,
       sum(communes) AS lignes
FROM   c61_inconnu GROUP BY classe ORDER BY classe;

-- ---------------------------------------------------------------------------
-- 3. LE CROISEMENT — un effectif substantiel ET une création documentée
--
-- Les deux signaux sont indépendants : l'effectif vient de notre lecture,
-- la création vient de l'atlas. Leur conjonction vaut mieux que chacun seul.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. candidats sérieux : >= 3 communes, dans un département à création'
SELECT i.dep, i.canton_id, i.communes, i.lues_deux_fois, i.arrondissements,
       left(i.composition, 70) AS debut_composition
FROM   c61_inconnu i
WHERE  i.communes >= 3
  AND  EXISTS (SELECT 1 FROM c61_creation c WHERE c.dep = i.dep)
ORDER  BY i.communes DESC, i.dep, i.canton_id;

\echo ''
\echo '   ... et le texte des créations pour ces départements :'
SELECT c.dep, c.date_texte, left(c.texte, 88) AS texte
FROM   c61_creation c
WHERE  EXISTS (SELECT 1 FROM c61_inconnu i
                WHERE i.dep = c.dep AND i.communes >= 3)
ORDER  BY c.dep, c.date_texte;

-- ---------------------------------------------------------------------------
-- 4. Le contre-signal : effectif substantiel SANS création documentée
--
-- Ceux-là sont probablement des erreurs de lecture — ou bien l'annexe VII est
-- incomplète pour ce département, ce qui serait un fait notable en soi.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. >= 3 communes mais AUCUNE création documentée dans ce département'
SELECT i.dep, i.canton_id, i.communes, i.arrondissements,
       left(i.composition, 60) AS debut_composition
FROM   c61_inconnu i
WHERE  i.communes >= 3
  AND  NOT EXISTS (SELECT 1 FROM c61_creation c WHERE c.dep = i.dep)
ORDER  BY i.communes DESC
LIMIT  30;

-- ---------------------------------------------------------------------------
-- 5. L'indice qui a démasqué 5181 : un canton sur plusieurs arrondissements
--
-- Un canton est contenu dans un arrondissement. Une composition qui en
-- chevauche deux ou trois trahit une lecture fautive, quel que soit l'effectif.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. cantons inconnus chevauchant plusieurs arrondissements'
SELECT dep, canton_id, communes, arrondissements, left(composition, 60) AS debut
FROM   c61_inconnu
WHERE  arrondissements > 1 AND communes >= 3
ORDER  BY arrondissements DESC, communes DESC
LIMIT  20;

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit. Chaque candidat demande une source'
\echo ' publiée et une confrontation commune par commune, comme'
\echo ' Forbach-II : 16 codes vérifiés un à un avant d''écrire.'
\echo '============================================================'

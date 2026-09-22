-- ============================================================================
-- histgis — 91_seine_1815_1870.sql : la banlieue de la Seine avant 1870
--
--   cd ~/Téléchargements/projet_carte        <-- IMPÉRATIF pour les \copy
--   psql -d histgis -f sql/91_seine_1815_1870.sql              -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/91_seine_1815_1870.sql
--
-- CE QUE L'ATLAS DONNE, ET IL DONNE BEAUCOUP PLUS QUE PRÉVU
-- =========================================================
-- Les planches « SEINE » de l'atlas Gaudillère ne signalent pas que des
-- circonscriptions débordent de Paris : **elles cartographient la banlieue
-- commune par commune et numérotent ses circonscriptions.** La colonne
-- `remarque` de `paris_decoupage.xlsx` (`rattaché hors-paris`, neuf lignes)
-- n'en était que l'ombre textuelle.
--
--     1815        deux collèges : Saint-Denis (nord), Sceaux (sud)
--     1820-1831   UNE circonscription pour toute la banlieue — la 8e
--     1831-1848   comme 1815 : 13e = Sceaux, 14e = Saint-Denis
--     1852-1857   8 au nord, 9 au sud, hors Paris
--     1857-1863   9 au nord, 10 au sud, hors Paris
--     1863-1869   circos 8 et 9 DE PARIS, étendues à la banlieue nord et sud
--     1869-1870   idem
--
-- 1848-1852 manque à cette liste : c'est `90`, une seule circonscription
-- départementale, Paris compris. Lecture complète dans
-- `circo/note_seine_1815_1870.md`.
--
-- LA BASCULE DE 1863 EST CELLE DE L'ANNEXION
-- ===========================================
-- Avant 1860, la **petite banlieue** — les onze communes que Paris absorbe —
-- est rattachée aux circonscriptions PARISIENNES limitrophes, et c'est cela
-- que marque `rattaché hors-paris`. La **grande banlieue** a ses propres
-- circonscriptions. Après 1860 il n'y a plus de petite banlieue, et la grande
-- rejoint les circos 8 et 9 de Paris.
--
-- Les onze annexées sont posées partout où les planches les nomment — voir la
-- section « les exceptions » plus bas — sauf Belleville en 1857-1863, que
-- l'atlas déclare coupée. En 1820-1831 elles n'appellent aucun arbitrage :
-- toute la banlieue y forme une unique circonscription.
--
-- LA LIGNE NORD/SUD, ET POURQUOI ELLE N'EST PAS TRACÉE À LA MAIN
-- ==============================================================
-- La planche de 1815 porte la seule définition écrite : « les deux
-- arrondissements de Sceaux et de Saint-Denis étaient séparés, sur le
-- territoire actuel de Paris, par la Seine à l'Ouest et la rue de Lagny à
-- l'Est. »
--
-- Cette frontière est celle des ARRONDISSEMENTS du département, et le jalon
-- cantonal de 1954 la porte encore : la nomenclature de la page 758 du
-- recensement donne l'arrondissement de chacun des 22 cantons de banlieue.
-- C'est `circo/seine_arrondissements.csv`, et rien d'autre n'est utilisé ici.
--
-- Mesuré hors base, en déployant cette table sur les communes :
--
--     Saint-Denis   37 communes   174,22 km²   2 composantes connexes
--     Sceaux        43 communes   199,99 km²   1 composante
--
-- La seconde composante de Saint-Denis est **Boulogne-Billancourt seule**,
-- 6,16 km², coupée de son arrondissement par Paris. Boulogne est sur la rive
-- DROITE, dans la boucle, et la planche dit que la séparation suit la Seine à
-- l'ouest : deux sources séparées de cent trente-neuf ans décrivent la même
-- ligne.
--
-- **Mais cette anomalie disait AUSSI autre chose**, et il a fallu la relecture
-- des planches pour l'entendre : la circonscription de 1852 et de 1857 qui
-- prend Boulogne n'est pas celle de la banlieue nord, c'est la 1re de PARIS.
-- Voir la section « les exceptions ».
--
-- L'HYPOTHÈSE, ET ELLE SE DIT
-- ============================
-- La répartition Saint-Denis / Sceaux est **lue à 1954 et projetée sur
-- 1815-1870**. Ce qui la soutient : la planche de 1815 nomme les deux mêmes
-- arrondissements, et la ligne qu'elle décrit explique l'anomalie mesurée à
-- 1954. Ce qui ne la soutient pas : rien n'interdit qu'une commune ait changé
-- d'arrondissement en cent quarante ans. Les unités portent donc
-- `provisoire = true`, comme celles de `88`.
--
-- L'EXISTENCE EST ATTESTÉE, ET LA VIE NE COMMENCE PAS AVANT LA NAISSANCE
-- ======================================================================
-- Même règle que `90` : on ne rattache que ce dont l'existence à la date est
-- attestée par un polygone ANR. **Et le rattachement commence à la naissance,
-- pas au début de la division** — Levallois-Perret naît en 1866, elle entre
-- dans la 8e le 1er janvier 1866 et non en 1863.
--
-- C'est exactement ce que le report arrière de `11` ne fait pas, et c'est
-- délibéré : `11` comble un trou de couverture au prix de l'identité du
-- dessin (voir `sql/diag_report_arriere.sql`, 367 atomes, 4 572,2 km²). Ici
-- il n'y a pas de trou à combler — la commune n'existait pas, et sa mère est
-- dessinée à sa place par la trame ANR.
--
-- LES EXCEPTIONS, LUES SUR LES PLANCHES LE 6 SEPTEMBRE AU SOIR
-- =============================================================
-- La première version de ce fichier laissait les onze annexées sans
-- rattachement de 1852 à 1863, faute d'un texte qui les nomme. Les planches
-- ont été relues, et elles les nomment. `circo/seine_annexees_circo.csv`
-- porte les 24 lignes, et elles priment sur le côté nord/sud :
--
--     circo 1 de Paris    Passy, Auteuil, BOULOGNE-BILLANCOURT
--     circo 2 de Paris    La Chapelle, Batignolles-Monceau, Montmartre
--     banlieue nord       Charonne, La Villette, Belleville (1852-1857)
--     banlieue sud        Bercy, Grenelle, Vaugirard
--
-- **BOULOGNE-BILLANCOURT EST LA CORRECTION QUI COMPTE.** Ce n'est pas une
-- annexée : c'est une commune de la banlieue actuelle, que la ligne nord/sud
-- de 1954 plaçait dans l'arrondissement de Saint-Denis, donc dans la
-- circonscription de banlieue nord. Les planches la donnent à la 1re
-- circonscription PARISIENNE, avec Passy et Auteuil. Le premier jeu l'a donc
-- rattachée au mauvais endroit pendant onze ans.
--
-- *L'indice était dans la mesure du matin et je ne l'ai pas lu.* Boulogne
-- formait la seconde composante connexe de l'arrondissement de Saint-Denis,
-- seule, coupée du reste par Paris. J'y ai vu une confirmation de la ligne —
-- la Seine sépare à l'ouest — et je me suis arrêté là. Une commune que Paris
-- sépare de son arrondissement est précisément celle que Paris capte
-- électoralement. **Une anomalie qui confirme une règle peut en annoncer une
-- autre, et on cesse de lire dès qu'elle donne raison.**
--
-- CE QUI N'EST PAS POSÉ, ET POURQUOI
-- ===================================
--   * **Belleville en 1857-1863**, et elle seule. L'atlas se dénonce
--     lui-même : « deux bureaux de vote étaient inclus dans la 5e
--     circonscription, et le reste de la commune dans la 9e. Faute de
--     précisions supplémentaires, la ligne de séparation cartographiée
--     ci-dessus est purement arbitraire. » Elle est donc **nommée et non
--     attribuée**, comme les quartiers parisiens coupés par une rue dans `52`
--     et `55` — son `unit_id` vaut `(coupee)` dans le CSV, et la recette 3
--     l'affiche.
--   * **1848-1852**, posé par `90`.
--
-- LE NOM DES UNITÉS DE 1863-1870 CHANGE
-- ======================================
-- `55` les a nommées « Paris 8e / 9e circonscription ». Elles débordent de
-- Paris — c'est tout l'objet de ce fichier — et deviennent « Seine ». Comme
-- dans `90`, l'ancien libellé est conservé dans la trace et revient avec elle.
--
-- Réversible : `seine_1870_trace`, section 6.
-- Prérequis : `55_paris_circo_serie.sql`, `89` et `90` joués.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM unit WHERE unit_id = 'V1863_1869#8') THEN
        RAISE EXCEPTION E'Les circonscriptions parisiennes de 1863 manquent.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/55_paris_circo_serie.sql';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = '23671') THEN
        RAISE EXCEPTION E'Les communes annexees a Paris en 1860 n''existent pas.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/89_seine_annexees_1860.sql';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS seine_1870_trace (
    quoi text NOT NULL, cle text NOT NULL, valeur text,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

DROP TABLE IF EXISTS s70_div;
CREATE TEMP TABLE s70_div (
    division text, du date, au date, cote text, unit_id text,
    nom text, regime text, provenance text, planche text
);
\copy s70_div FROM 'circo/seine_1815_1870.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS s70_exc;
CREATE TEMP TABLE s70_exc (
    division text, commune text, atom_id text, unit_id text, note text
);
\copy s70_exc FROM 'circo/seine_annexees_circo.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS s70_arr;
CREATE TEMP TABLE s70_arr (
    canton text, code_1954 int, arrondissement text, cote text
);
\copy s70_arr FROM 'circo/seine_arrondissements.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- 1. Le côté de chaque commune, par l'arrondissement de son canton en 1954
--
-- Le lot est celui de `88` et de `90` — la planche cantonale du 1er juin 1954 —
-- et il ne sert ici qu'à porter le côté. Les onze communes annexées n'y sont
-- évidemment pas : elles étaient mortes depuis un siècle. Elles sont ajoutées
-- sous un côté à elles, `annexee`, qui ne rejoint qu'une seule division.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS s70_cote;
CREATE TEMP TABLE s70_cote AS
SELECT m.atom_id, u.nom AS canton, a.arrondissement, a.cote
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton' AND u.dep = '75'
  JOIN s70_arr a ON a.canton = u.nom
 WHERE m.niveau = 'canton' AND m.periode @> DATE '1954-06-01'
UNION ALL
-- Les onze annexées portent le côté `annexee`, qui n'est ni `nord` ni `sud`.
-- Elles ne rejoignent donc QUE la division dont le côté vaut `tout` —
-- 1820-1831, où la banlieue entière ne fait qu'une circonscription et où leur
-- rattachement ne demande aucun arbitrage. Partout ailleurs elles restent sans
-- rattachement, faute d'un texte qui les nomme.
SELECT a.atom_id, NULL::text, NULL::text, 'annexee'::text
  FROM atom a
 WHERE a.atom_id IN ('1960','2924','3564','3719','8509','16141',
                     '8165','40600','23671','26284','39042');

\echo ''
\echo '=== 1. La ligne nord/sud, telle que 1954 la porte ==='
SELECT cote, arrondissement, count(DISTINCT canton) AS cantons,
       count(*) AS communes
  FROM s70_cote GROUP BY 1, 2 ORDER BY 1;
-- Attendu : nord    / Saint-Denis  13 cantons  37 communes
--           sud     / Sceaux        9 cantons  43 communes
--           annexee / (aucun)        0 cantons  11 communes

\echo ''
\echo '=== 1 bis. Garde-fou : tout canton de 1954 a-t-il un cote ? ==='
SELECT u.nom AS canton_sans_cote
  FROM unit u
 WHERE u.niveau = 'canton' AND u.dep = '75'
   AND EXISTS (SELECT 1 FROM membership m WHERE m.unit_id = u.unit_id
                AND m.niveau = 'canton' AND m.periode @> DATE '1954-06-01')
   AND NOT EXISTS (SELECT 1 FROM s70_arr a WHERE a.canton = u.nom)
 ORDER BY 1;
-- Attendu : aucune ligne. Une sortie voudrait dire que la nomenclature de la
-- page 758 a ete transcrite incompletement.

-- ---------------------------------------------------------------------------
-- 2. Ce qui va être posé : commune × division, borné par la naissance
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS s70_pose;
CREATE TEMP TABLE s70_pose AS
WITH naissance AS (
    SELECT atom_id, min(lower(periode)) AS ne_le, max(upper(periode)) AS mort_le
      FROM atom_geom_anr GROUP BY atom_id
)
SELECT d.division, d.unit_id, d.provenance, c.atom_id, c.cote,
       greatest(d.du, n.ne_le)     AS valid_from,
       least(d.au, n.mort_le)      AS valid_to,
       n.ne_le
  FROM s70_div d
  JOIN s70_cote c ON (d.cote = 'tout' OR d.cote = c.cote)
  JOIN naissance n ON n.atom_id = c.atom_id
 WHERE n.ne_le < d.au          -- née avant la fin de la division
   AND n.mort_le > d.du        -- encore vivante à son début
   -- Un atome nommé par les planches pour cette division ne prend pas son
   -- rattachement du côté nord/sud : le texte prime sur la règle.
   AND NOT EXISTS (SELECT 1 FROM s70_exc e
                    WHERE e.division = d.division AND e.atom_id = c.atom_id)
UNION ALL
-- Les exceptions, sauf celles dont l'unité vaut `(coupee)` : celles-là sont
-- nommées et non attribuées.
SELECT e.division, e.unit_id, 'exception', e.atom_id, 'planche',
       greatest(d.du, n.ne_le), least(d.au, n.mort_le), n.ne_le
  FROM s70_exc e
  -- Une division porte deux lignes dans `s70_div`, nord et sud ; on ne veut
  -- que ses bornes, une fois. Un `JOIN` direct dedoublerait chaque exception.
  JOIN (SELECT division, min(du) AS du, max(au) AS au
          FROM s70_div GROUP BY division) d ON d.division = e.division
  JOIN naissance n ON n.atom_id = e.atom_id
 WHERE e.unit_id <> '(coupee)'
   AND n.ne_le < d.au AND n.mort_le > d.du;

\echo ''
\echo '=== 2. Ce que chaque division recevra ==='
-- On groupe sur `s70_pose` et non sur `s70_div` : les circonscriptions
-- PARISIENNES qui reçoivent une exception ne figurent pas dans `s70_div`, et
-- un groupement sur les divisions les rendrait invisibles.
SELECT p.division, p.unit_id, min(p.provenance) AS provenance,
       count(*)                                        AS communes,
       count(*) FILTER (WHERE p.valid_from > d.du)     AS entrees_en_cours
  FROM s70_pose p
  JOIN (SELECT division, min(du) AS du FROM s70_div GROUP BY division) d
       ON d.division = p.division
 GROUP BY p.division, p.unit_id
 ORDER BY p.division, p.unit_id;
-- Attendu :
--
--     1815-1820   S1815@nord   31   S1815@sud    38            total 69
--     1820-1831   S1820@8      80                              total 80
--     1831-1848   S1831@14     31   S1831@13     38            total 69
--     1852-1857   75-01@1852    3   75-02@1852    3
--                 S1852@8      33   S1852@9      41            total 80
--     1857-1863   75-01@1857    3   75-02@1857    3
--                 S1857@9      32   S1857@10     41            total 79
--     1863-1869   V1863_1869#8 33   V1863_1869#9 38            total 71
--     1869-1870   V1869_1870#8 33   V1869_1870#9 38            total 71
--
-- 31 et 38 et non 37 et 43 : onze communes de la banlieue actuelle naissent
-- apres 1815 — six au nord, cinq au sud.
--
-- 1852-1857 et 1857-1863 sont les seules divisions ou les circonscriptions
-- PARISIENNES apparaissent : elles recoivent les six annexees de l'ouest et du
-- nord, plus Boulogne-Billancourt. La banlieue nord y perd donc Boulogne
-- (31 -> 30) et gagne Charonne, La Villette et Belleville (-> 33 en 1852, 32
-- en 1857 ou Belleville est coupee). La banlieue sud gagne Bercy, Grenelle et
-- Vaugirard (38 -> 41).
--
-- **1852-1857 partitionne les 80.** 1857-1863 en couvre 79, Belleville etant
-- nommee et non attribuee.
--
-- `entrees_en_cours` doit valoir 2 en 1820-1831 (Batignolles-Monceau et
-- Grenelle, nees en 1830) et 2 en 1863-1869 (Levallois-Perret en 1866 et Les
-- Lilas en 1867, toutes deux au nord). Partout ailleurs, zero.

\echo ''
\echo '=== 3. Les exceptions des planches, et ce qu elles deviennent ==='
SELECT e.division, e.commune, e.atom_id, e.unit_id AS planche,
       coalesce(p.unit_id, '(non posee)') AS pose,
       p.valid_from, p.valid_to
  FROM s70_exc e
  LEFT JOIN s70_pose p ON p.division = e.division AND p.atom_id = e.atom_id
 ORDER BY e.division, e.unit_id, e.commune;
-- Attendu : 24 lignes, `planche` = `pose` partout SAUF Belleville en
-- 1857-1863, ou `planche` vaut `(coupee)` et `pose` vaut `(non posee)`.
--
-- Un ecart entre les deux colonnes ailleurs voudrait dire que la regle
-- nord/sud a repris le dessus sur le texte, ce qu'elle ne doit jamais faire.

\echo ''
\echo '=== 4. Garde-fou : ces periodes sont-elles libres pour ces atomes ? ==='
SELECT p.division, count(*) AS rattachements_deja_presents
  FROM s70_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
 WHERE NOT EXISTS (SELECT 1 FROM seine_1870_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle = m.membership_id::text)
 GROUP BY p.division ORDER BY 1;
-- Attendu : aucune ligne. `90` occupe 1848-1852, qui n'est pas dans ce fichier.

\if :{?appliquer}

-- Retirer sa trace AVANT de juger — la leçon de `55`. Les noms d'abord, pour
-- qu'un rejeu reparte du libellé d'origine.
UPDATE unit u SET nom = t.valeur
  FROM seine_1870_trace t
 WHERE t.quoi = 'nom_unit' AND t.cle = u.unit_id;
UPDATE unit_version v SET nom = t.valeur
  FROM seine_1870_trace t
 WHERE t.quoi = 'nom_version' AND t.cle = v.unit_version_id::text;
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM seine_1870_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM seine_1870_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
TRUNCATE seine_1870_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n
      FROM unit u
     WHERE u.niveau = 'canton' AND u.dep = '75'
       AND EXISTS (SELECT 1 FROM membership m WHERE m.unit_id = u.unit_id
                    AND m.niveau = 'canton' AND m.periode @> DATE '1954-06-01')
       AND NOT EXISTS (SELECT 1 FROM s70_arr a WHERE a.canton = u.nom);
    IF n > 0 THEN
        RAISE EXCEPTION '% canton(s) de 1954 sans cote. La nomenclature de la '
            'page 758 est incomplete. Voir la recette 1 bis.', n;
    END IF;

    -- Le lot de 1954 se compte SANS les onze annexees, qui n'en font pas
    -- partie et n'y ont jamais figure. Le premier ecrit comptait `s70_cote`
    -- entiere et trouvait 91 la ou il attendait 80 : *un garde-fou ecrit avant
    -- la table qu'il surveille compte ce qu'il croit, pas ce qui est.*
    SELECT count(*) INTO n FROM s70_cote WHERE cote IN ('nord', 'sud');
    IF n <> 80 THEN
        RAISE EXCEPTION 'Le lot de 1954 compte % communes au lieu de 80. '
            'Rejouer 87_seine_canton_1954.sql.', n;
    END IF;

    SELECT count(*) INTO n FROM s70_cote WHERE cote = 'annexee';
    IF n <> 11 THEN
        RAISE EXCEPTION 'Les communes annexees sont % au lieu de 11. '
            'Rejouer 89_seine_annexees_1860.sql.', n;
    END IF;

    SELECT count(*) INTO n
      FROM s70_pose p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) circo existent deja. Ce fichier '
            'COMBLE, il ne remplace pas. Voir la recette 4.', n;
    END IF;

    SELECT count(*) INTO n FROM s70_pose WHERE valid_from >= valid_to;
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) de duree nulle ou negative.', n;
    END IF;

    -- Toute exception nommee par les planches doit etre posee, sauf celles
    -- que l'atlas declare coupees. Une exception qui ne resout pas serait un
    -- atome mal identifie ou une unite qui n'existe pas.
    SELECT count(*) INTO n
      FROM s70_exc e
     WHERE e.unit_id <> '(coupee)'
       AND NOT EXISTS (SELECT 1 FROM s70_pose p
                        WHERE p.division = e.division AND p.atom_id = e.atom_id);
    IF n > 0 THEN
        RAISE EXCEPTION '% exception(s) des planches ne se posent pas. Voir la '
            'recette 3.', n;
    END IF;

    SELECT count(*) INTO n
      FROM s70_exc e
      JOIN s70_pose p ON p.division = e.division AND p.atom_id = e.atom_id
     WHERE e.unit_id <> '(coupee)' AND p.unit_id <> e.unit_id;
    IF n > 0 THEN
        RAISE EXCEPTION '% exception(s) posees ailleurs que ce que la planche '
            'dit. La regle nord/sud a repris le dessus sur le texte.', n;
    END IF;

    SELECT count(*) INTO n
      FROM s70_exc e
      JOIN s70_pose p ON p.division = e.division AND p.atom_id = e.atom_id
     WHERE e.unit_id = '(coupee)';
    IF n > 0 THEN
        RAISE EXCEPTION '% commune(s) declaree(s) coupee(s) par l''atlas sont '
            'posees quand meme.', n;
    END IF;

    -- Une unité citée par les planches doit exister EN BASE **ou** être créée
    -- par ce fichier. Le premier écrit ne testait que la base — et il tourne
    -- APRÈS le retrait de trace, qui vient de supprimer les neuf unités
    -- neuves. Il a donc dénoncé onze lignes citant `S1852@8`, `S1852@9`,
    -- `S1857@9` et `S1857@10`, c'est-à-dire quatre unités que le fichier
    -- s'apprêtait à recréer vingt lignes plus bas.
    --
    -- *C'est la faute du matin retournée : là un diagnostic comptait l'ouvrage
    -- du fichier parmi les obstacles, ici un garde-fou exigeait que l'ouvrage
    -- fût déjà fait. Dans les deux cas il lisait la base à un instant où elle
    -- ne pouvait pas encore lui répondre.*
    SELECT count(*) INTO n
      FROM s70_exc e
     WHERE e.unit_id <> '(coupee)'
       AND NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = e.unit_id)
       AND NOT EXISTS (SELECT 1 FROM s70_div d WHERE d.unit_id = e.unit_id);
    IF n > 0 THEN
        RAISE EXCEPTION '% unite(s) citee(s) par les planches n''existent ni '
            'en base ni dans seine_1815_1870.csv.', n;
    END IF;
END $$;

-- Les unités neuves.
WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT d.unit_id, 'circo', '75', '75-' || d.cote, d.regime,
           extract(year FROM d.du)::int, d.nom, true
      FROM s70_div d WHERE d.provenance = 'neuve'
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO seine_1870_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT d.unit_id, d.nom, d.du, d.au
  FROM s70_div d
 WHERE d.provenance = 'neuve'
   AND EXISTS (SELECT 1 FROM seine_1870_trace t
                WHERE t.quoi = 'unit' AND t.cle = d.unit_id);

-- Les unités existantes de `55` cessent d'être « Paris » : elles débordent.
--
-- **Et `unit_version` doit suivre.** Le premier jeu n'a change que `unit.nom`,
-- alors que l'export lit le nom DANS `unit_version` : la carte a continue
-- d'afficher « Paris 8e circonscription » apres le renommage.
-- *Un nom denormalise qu'on corrige sans corriger sa source ne corrige rien.*
INSERT INTO seine_1870_trace (quoi, cle, valeur)
SELECT 'nom_unit', u.unit_id, u.nom
  FROM unit u JOIN s70_div d ON d.unit_id = u.unit_id
 WHERE d.provenance = 'existante';
UPDATE unit u SET nom = d.nom || ' (' || d.division || ')'
  FROM s70_div d
 WHERE d.unit_id = u.unit_id AND d.provenance = 'existante';

INSERT INTO seine_1870_trace (quoi, cle, valeur)
SELECT 'nom_version', v.unit_version_id::text, v.nom
  FROM unit_version v JOIN s70_div d ON d.unit_id = v.unit_id
 WHERE d.provenance = 'existante';
UPDATE unit_version v SET nom = d.nom
  FROM s70_div d
 WHERE d.unit_id = v.unit_id AND d.provenance = 'existante';

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM s70_pose
    RETURNING membership_id
)
INSERT INTO seine_1870_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM seine_1870_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 9 unites neuves, 4 noms d'unite et 4 noms de version changes,
-- et **519 rattachements**, contre 498 au premier jeu. Le detail :
--
--     1815-1820   69      1852-1857   80   (69 -> 80, les annexees entrent)
--     1820-1831   80      1857-1863   79   (Belleville coupee)
--     1831-1848   69      1863-1869   71
--                         1869-1870   71
--
-- 69+80+69+80+79+71+71 = 519.

\echo ''
\echo '=== 6. La Seine de 1815 a 1870, annee par annee ==='
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (WHERE a.atom_id LIKE 'PV%')     AS quartiers_1815,
       count(DISTINCT m.atom_id) FILTER (WHERE a.atom_id LIKE 'PQ%')     AS quartiers_1860,
       count(DISTINCT m.atom_id) FILTER (WHERE a.atom_id NOT LIKE 'P%')  AS communes,
       count(DISTINCT m.unit_id) AS circos
  FROM (VALUES ('1817-06-01'::date),('1825-06-01'),('1840-06-01'),
               ('1849-06-01'),('1855-06-01'),('1858-06-01'),
               ('1861-06-01'),('1866-06-01'),('1869-06-01'),
               ('1875-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo' AND u.dep = '75'
  LEFT JOIN atom a ON a.atom_id = m.atom_id
 WHERE u.unit_id IS NOT NULL
 GROUP BY d ORDER BY d;
-- 1855 et 1858 : 48 + **80** et **79** desormais, et non 69 — les annexees
--   sont rattachees depuis la relecture des planches. 1858 en compte 79 :
--   Belleville y est coupee.
-- 1817 et 1840 : 48 quartiers de Vasserot + 69 communes.
-- 1825 : 48 + **78**, et non 80. Les 80 sont l'effectif de la DIVISION
--   1820-1831 ; a la date de 1825, Batignolles-Monceau et Grenelle ne sont pas
--   encore nees. *Un effectif de periode et un effectif de date portent le meme
--   nom et ne comptent pas la meme chose.* C'est neanmoins la seule fenetre
--   d'avant 1848 ou les annexees sont rattachees.
-- 1861 : 48 + 69, et c'est un TROU HERITE, pas un defaut d'ici. Les onze
--   annexees meurent en 1859 selon ANR, mais la division parisienne de
--   1857-1863 porte sur les 48 quartiers de Vasserot et court jusqu'en 1863 :
--   de 1860 a 1863 un anneau vide separe Paris de la grande banlieue. Le
--   combler demanderait de basculer Paris sur la trame des 80 au 1er janvier
--   1860 en gardant la division de 1857 — un changement dans `55`, pas ici.
-- 1849 : 48 + 80, une seule circonscription — c'est `90`.
-- 1855, 1858 : 48 + 69. Les onze annexees manquent, et c'est declare.
-- 1861, 1866, 1869 : 80 quartiers de 1860 + 69, 70, 71 communes.
-- 1875 : la couche TRF-GIS reprend, 20 arrondissements + 80 communes.

\echo ''
\echo '=== 7. Aucun atome dans deux circos a la meme date, France entiere ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\echo ''
\echo '=== 8. Ce que la carte rend a quatre dates ==='
-- `carte_partition_atome` est la fonction de `84`, qui passe APRES ce fichier
-- dans `rejouer_apres_rebuild.sh`. Sur une base reconstruite elle n'existe
-- pas encore, et ce fichier etant joue en `-1`, la recette aurait annule la
-- POSE entiere et arrete la chaine. Trouve le 22 septembre 2026 par l'audit
-- des lectures en avant, apres l'arret de `47` sur `scission_circo_trace`.
-- La recette se relit alors apres `84`, en rejouant le fichier AVEC
-- `appliquer` : elle est dans cette branche, et le rejeu retire la trace
-- avant de reposer. La commande est affichee.
SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'carte_partition_atome')
       AS a_84 \gset
\if :a_84
SELECT d::date AS a_la_date, count(*) AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 2) AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                          AS recouvrement_km2
  FROM (VALUES ('1825-06-01'::date),('1855-06-01'),('1866-06-01')) v(d),
       LATERAL carte_partition_atome(d, '75')
 GROUP BY d ORDER BY d;
\else
\echo '    84 pas encore joue : recette a relire apres lui, par'
\echo '    psql -d $PGDATABASE -1 -v appliquer=1 -f sql/91_seine_1815_1870.sql'
\echo '    (rejeu sans risque : le fichier retire sa trace avant de reposer.'
\echo '     Sans appliquer, il tourne a blanc et n atteint pas la recette.)'
\endif
-- 1825 doit approcher les 475,83 km2 de `90` : meme lot, meme trame.
-- 1855 valait 455,25 avant la relecture des planches, soit 24,39 km2 de moins
-- que la Seine entiere. Les annexees etant desormais rattachees, il doit
-- REJOINDRE 1825 — autour de 475,8. L'ecart residuel est le bois de Boulogne
-- et le trou ANR de Nogent, pas un refus de notre part.
-- 1866 rend 479,64, la Seine entiere : Paris y est sur la trame des 80.

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

-- ============================================================================
-- histgis — 90_seine_1848_banlieue.sql : la limite déclarée par `57` est levée
--
--   psql -d histgis -f sql/90_seine_1848_banlieue.sql            -- diagnostic
--   psql -d histgis -1 -v appliquer=1 -f sql/90_seine_1848_banlieue.sql
--
-- CE QUE `57` AVAIT ÉCRIT, ET QU'IL FAUT RELIRE
-- =============================================
-- > « La circonscription est le département de la SEINE, qui déborde largement
-- >   Paris : elle comprend les communes de la banlieue. **Nous ne posons que
-- >   sa part parisienne, faute d'atomes pour le reste avant 1870.** L'unité
-- >   porte donc un nom qui le dit, et sa géométrie n'est pas celle de la
-- >   circonscription réelle mais de ce que nous en connaissons. »
--
-- Ce fichier lève exactement cette limite, et rien d'autre. `57` reste vrai :
-- de 1848 à 1852 le département forme UNE circonscription, scrutin majoritaire
-- plurinominal départemental. Ce n'est pas une interpolation, c'est l'énoncé
-- du découpage. Ce qui manquait n'était pas la source, c'étaient les atomes.
--
-- CE QU'IL POSE
-- =============
-- Les 80 communes non parisiennes de la Seine vivantes en 1848, rattachées à
-- l'unité `L7501@1848` que `57` a créée :
--
--     69 communes de la banlieue actuelle
--     11 communes annexées à Paris en 1860, créées par `89`
--
-- Avec les 48 quartiers de Vasserot déjà posés par `57`, l'unité compte
-- **128 atomes**.
--
-- L'EXISTENCE EST ATTESTÉE, PAS SUPPOSÉE
-- =======================================
-- Le critère de pose est unique : **l'atome a un polygone ANR couvrant le
-- 1er juin 1848**. Rien d'autre. Ce n'est pas une commodité technique, c'est
-- la règle de fond — nous ne rattachons que ce dont l'existence à la date est
-- attestée par la source géométrique.
--
-- Onze communes de la banlieue actuelle sont donc écartées, et c'est ce qu'il
-- faut : Alfortville (1885), Bois-Colombes (1896), Cachan (1922), La
-- Garenne-Colombes (1910), Le Kremlin-Bicêtre (1896), Levallois-Perret (1866),
-- Les Lilas (1867), Malakoff (1883), Les Pavillons-sous-Bois (1905), Le
-- Perreux-sur-Marne (1887), Villeneuve-la-Garenne (1929). Elles n'existaient
-- pas en 1848.
--
-- *Sans ce critère, `carte_partition_atome` les dessinerait quand même — avec
-- leur forme de 2011, par le repli sur `atom_geom`. Une commune de 1929
-- dessinée en 1848 n'est pas une approximation, c'est une invention.*
--
-- CE QUE LE CHIFFRE DE 1848 VAUT, MESURÉ HORS BASE
-- =================================================
-- Sur le GeoPackage ANR, centroïdes testés contre l'emprise de la Seine :
--
--     1815 :  79 communes    69 + 9 annexées + Paris
--     1830 :  81             Batignolles-Monceau et Grenelle naissent
--     1848 :  81             identique
--     1859 :  70             l'annexion a eu lieu
--     1866 :  71             Levallois-Perret naît
--
-- **Aucune commune inconnue de la base n'apparaît**, hors les onze annexées.
-- Le recensement du territoire est donc complet : la Seine de 1848 est faite
-- de ces 81 objets et d'aucun autre. L'union des 80 non parisiennes vaut
-- 441,56 km² pour une Seine de 479,64.
--
-- LE NOM DE L'UNITÉ CHANGE, ET C'EST UNE MODIFICATION
-- ====================================================
-- `57` a nommé l'unité « Seine — scrutin de liste départemental (part
-- parisienne) ». La parenthèse dit une limite qui n'existe plus. Ce fichier la
-- retire — **c'est la seule donnée existante qu'il touche**, l'ancien libellé
-- est conservé dans la trace, et le retrait se défait avec le reste.
--
-- CE QUI RESTE OUVERT
-- ===================
--   * **1815-1848** — suffrage censitaire, l'unité est le collège
--     d'arrondissement et non la circonscription. `54` pose la part
--     parisienne ; la banlieue relève des collèges de Saint-Denis et de
--     Sceaux, à chercher.
--   * **1852-1859 et 1859-1870** — les circonscriptions du Second Empire.
--     `55` en pose la part parisienne (7, 8 puis 9 divisions) ; la banlieue
--     manque. Attention à la borne : ANR ferme les annexées en 1859, pas en
--     1860 (voir `89`).
--
-- Réversible : `seine_1848_trace`, section 5.
-- Prérequis : `57_paris_circo_1848.sql` et `89_seine_annexees_1860.sql` joués.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set debut '1848-01-01'
\set fin   '1852-01-01'
\set unite 'L7501@1848'
\set nom_neuf 'Seine — scrutin de liste départemental'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM unit WHERE unit_id = 'L7501@1848') THEN
        RAISE EXCEPTION E'L''unite L7501@1848 n''existe pas.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/57_paris_circo_1848.sql';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = '23671') THEN
        RAISE EXCEPTION E'Les communes annexees a Paris en 1860 n''existent pas.\n'
            '  psql -d histgis -1 -v appliquer=1 -f sql/89_seine_annexees_1860.sql';
    END IF;
END $$;

-- La trace se crée AVANT les recettes : PostgreSQL résout les noms de tables
-- à l'analyse, donc une garde `to_regclass(...) IS NULL OR …` échoue à la
-- planification au lieu de court-circuiter. Une trace vide ne pose rien.
CREATE TABLE IF NOT EXISTS seine_1848_trace (
    quoi text NOT NULL, cle text NOT NULL, valeur text,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

-- ---------------------------------------------------------------------------
-- 1. Le lot : les communes de la Seine hors Paris, et leur existence en 1848
--
-- Deux origines, aucune n'étant une liste écrite à la main :
--   * la planche cantonale de 1954 pour la banlieue actuelle, comme dans `88` ;
--   * les onze atomes que `89` a créés, reconnaissables à leur `com_act = 3`
--     et à leur absence de code INSEE.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS s48_lot;
CREATE TEMP TABLE s48_lot AS
SELECT a.atom_id, a.insee_geofla, 'banlieue actuelle'::text AS origine
  FROM atom a
 WHERE a.atom_id IN (
        SELECT DISTINCT m.atom_id FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton' AND u.dep = '75'
         WHERE m.niveau = 'canton' AND m.periode @> DATE '1954-06-01')
UNION ALL
SELECT a.atom_id, a.insee_geofla, 'annexee en 1860'
  FROM atom a
 WHERE a.atom_id IN ('1960','2924','3564','3719','8509','16141',
                     '8165','40600','23671','26284','39042');

DROP TABLE IF EXISTS s48_pose;
CREATE TEMP TABLE s48_pose AS
SELECT l.atom_id, l.origine, g.periode AS fenetre_anr
  FROM s48_lot l
  JOIN atom_geom_anr g ON g.atom_id = l.atom_id
                      AND g.periode @> DATE '1848-06-01';

\echo ''
\echo '=== 1. Qui est vivant en 1848, et qui ne l est pas ==='
SELECT l.origine,
       count(*)                                        AS dans_le_lot,
       count(p.atom_id)                                AS vivants_1848,
       count(*) - count(p.atom_id)                     AS pas_encore_nes
  FROM s48_lot l LEFT JOIN s48_pose p ON p.atom_id = l.atom_id
 GROUP BY l.origine ORDER BY 1;
-- Attendu : banlieue actuelle 80 -> 69 vivants, 11 pas encore nees
--           annexee en 1860    11 -> 11 vivants,  0

\echo ''
\echo '=== 2. Les ecartees, nommement ==='
SELECT l.atom_id, l.insee_geofla,
       (SELECT min(lower(g.periode)) FROM atom_geom_anr g WHERE g.atom_id = l.atom_id)
                                                       AS naissance_anr
  FROM s48_lot l
 WHERE NOT EXISTS (SELECT 1 FROM s48_pose p WHERE p.atom_id = l.atom_id)
 ORDER BY 3;
-- Attendu : onze lignes, toutes nees apres 1848. Une naissance ANTERIEURE a
-- 1848 dans cette liste serait un defaut : la commune existait et n'a pas de
-- polygone, ce qui est autre chose que ne pas exister.

\echo ''
\echo '=== 3. Garde-fou : ces atomes sont-ils libres de tout circo en 1848 ? ==='
SELECT count(*) AS rattachements_deja_presents
  FROM membership m
 WHERE m.niveau = 'circo'
   AND m.periode && daterange(:'debut', :'fin', '[)')
   AND m.atom_id IN (SELECT atom_id FROM s48_pose)
   AND NOT EXISTS (SELECT 1 FROM seine_1848_trace t
                    WHERE t.quoi = 'membership'
                      AND t.cle = m.membership_id::text);
-- Attendu : 0.

\echo ''
\echo '=== 4. Ce que l unite contient aujourd hui ==='
SELECT u.nom, count(m.atom_id) AS atomes
  FROM unit u LEFT JOIN membership m ON m.unit_id = u.unit_id AND m.niveau = 'circo'
 WHERE u.unit_id = :'unite' GROUP BY u.nom;
-- Avant la pose : 48 quartiers de Vasserot. Apres : 128.

\if :{?appliquer}

-- Retirer sa trace AVANT de juger — la leçon de `55`. Le nom de l'unité se
-- restitue à sa valeur d'avant, conservée dans la trace : *un correctif qui
-- ne sait pas ce qu'il a remplacé n'est pas réversible, il est seulement
-- effaçable.*
UPDATE unit u SET nom = t.valeur
  FROM seine_1848_trace t
 WHERE t.quoi = 'nom_unit' AND t.cle = u.unit_id;
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM seine_1848_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
TRUNCATE seine_1848_trace;

DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM s48_pose;
    IF n <> 80 THEN
        RAISE EXCEPTION 'La Seine de 1848 devrait compter 80 communes hors '
            'Paris, ANR en atteste %. Voir les recettes 1 et 2.', n;
    END IF;

    SELECT count(*) INTO n
      FROM membership m
     WHERE m.niveau = 'circo'
       AND m.periode && daterange(DATE '1848-01-01', DATE '1852-01-01', '[)')
       AND m.atom_id IN (SELECT atom_id FROM s48_pose);
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) circo existent deja sur 1848-1852 '
            'pour ces atomes. Ce fichier COMBLE, il ne remplace pas.', n;
    END IF;
END $$;

INSERT INTO seine_1848_trace (quoi, cle, valeur)
SELECT 'nom_unit', unit_id, nom FROM unit WHERE unit_id = :'unite';
UPDATE unit SET nom = :'nom_neuf' WHERE unit_id = :'unite';

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atom_id, :'unite', 'circo', :'debut'::date, :'fin'::date
      FROM s48_pose p
    RETURNING membership_id
)
INSERT INTO seine_1848_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 5. Pose ==='
SELECT quoi, count(*) FROM seine_1848_trace GROUP BY quoi ORDER BY quoi;
-- Attendu : 1 nom_unit, 80 membership.

\echo ''
\echo '=== 6. Recette : la Seine de 1848 est-elle pavee ? ==='
-- Le test qui decide. On demande la partition au moteur de `84` lui-meme, a
-- une date de la periode, et on pese ce qu'il rend.
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
SELECT count(*)                                              AS atomes_dessines,
       round((ST_Area(ST_Union(geom)) / 1e6)::numeric, 2)    AS union_km2,
       round(((sum(ST_Area(geom)) - ST_Area(ST_Union(geom))) / 1e6)::numeric, 3)
                                                             AS recouvrement_km2
  FROM carte_partition_atome(DATE '1849-06-01', '75');
\else
\echo '    84 pas encore joue : recette a relire apres lui, par'
\echo '    psql -d $PGDATABASE -1 -v appliquer=1 -f sql/90_seine_1848_banlieue.sql'
\echo '    (rejeu sans risque : le fichier retire sa trace avant de reposer.'
\echo '     Sans appliquer, il tourne a blanc et n atteint pas la recette.)'
\endif
-- Attendu : 128 atomes. L'union doit approcher 479,6 km2 — la Seine officielle
-- vaut 479,9. Les 80 communes hors Paris pesent 441,56 km2 mesures hors base,
-- donc Paris doit rendre environ 38.
--
-- LE CHIFFRE A SURVEILLER EST LE RECOUVREMENT. Les 48 quartiers viennent
-- d'ALPAGE-Vasserot et la couronne d'ANR : deux leves independants, aucune
-- raison qu'ils s'emboitent au metre pres. Un recouvrement de quelques
-- hectares serait la couture attendue ; quelques km2 diraient que les deux
-- trames ne parlent pas du meme Paris, et il faudrait le comprendre avant
-- d'aller plus loin.

\echo ''
\echo '=== 7. Paris de 1815 a 1863 : la chaine tient-elle toujours ? ==='
-- La recette 4 de `57`, elargie a la banlieue. Elle ne doit pas avoir bouge
-- pour Paris.
SELECT d::date AS a_la_date,
       count(DISTINCT m.atom_id) FILTER (WHERE a.atom_id LIKE 'PV%')  AS quartiers,
       count(DISTINCT m.atom_id) FILTER (WHERE a.atom_id NOT LIKE 'PV%') AS communes,
       count(DISTINCT m.unit_id) AS circos,
       string_agg(DISTINCT u.regime, ', ') AS regime
  FROM (VALUES ('1816-06-01'::date),('1825-06-01'),('1840-06-01'),
               ('1849-06-01'),('1850-06-01'),('1855-06-01'),
               ('1860-06-01')) v(d)
  LEFT JOIN membership m ON m.niveau = 'circo' AND m.periode @> d
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo' AND u.dep = '75'
  LEFT JOIN atom a ON a.atom_id = m.atom_id
 WHERE u.unit_id IS NOT NULL
 GROUP BY d ORDER BY d;
-- 1849 et 1850 : 48 quartiers ET 80 communes, 1 circonscription, regime liste.
-- Les autres dates gardent 48 quartiers et 0 commune — la banlieue n'est pas
-- encore attribuee hors 1848-1852, et ce fichier ne le pretend pas.

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

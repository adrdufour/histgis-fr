-- ============================================================================
-- 39_meurthe_1870.sql — la Meurthe reprend son numéro : 99 -> 54
--
--   psql -d histgis -f sql/39_meurthe_1870.sql
--
-- SANS `-1` : ce fichier ouvre et ferme sa propre transaction (voir la même
-- note en tête de `38`).
--
-- Ce que fait ce fichier
-- ---------------------
-- TRF-GIS range les 29 cantons de l'ancienne Meurthe sous un département « 99 »
-- qui n'a jamais existé. Ce fichier leur rend le numéro qu'ils portaient :
-- **54**.
--
-- La Meurthe était bien le département n° 54 avant 1871. Le code 99 est un
-- artefact de la source, commode pour isoler un département dont le territoire
-- ne se superpose à aucun département actuel — mais c'est une commodité de
-- traitement, pas un fait administratif. La base doit porter le fait.
--
-- TRACE — ajoutée le 2 septembre 2026
-- -----------------------------------
-- Ce fichier a été joué le 15 août, déclaré clos, puis **défait par un
-- `rebuild.sh` sans que rien ne le signale**. Personne ne l'a su avant le
-- 30 août, et encore par hasard, en lisant la recette d'un autre fichier.
-- C'est la dette la plus coûteuse du dépôt, et elle se solde ici.
--
-- **L'idempotence protège du rejeu, pas de l'oubli.** Un fichier idempotent
-- qu'un `DROP SCHEMA` a emporté se tait exactement comme un fichier qui vient
-- de réussir : dans les deux cas, zéro ligne modifiée et code de retour nul.
-- Seule une table dans la base peut faire la différence, parce qu'elle
-- disparaît avec le schéma qu'elle atteste.
--
-- LA CIBLE EST L'IDENTIFIANT, PAS LE DÉPARTEMENT — et ce n'est pas un détail.
-- Les 29 cantons gardent leur `unit_id` en `99xx` (§ « Ce que ce fichier NE
-- fait PAS »). Cet identifiant, lui, ne bouge jamais : il désigne les mêmes
-- unités que le fichier soit déjà passé ou non. Viser `dep = '99'` aurait
-- donné une trace VIDE sur une base déjà conforme — donc le verdict « joué
-- puis défait ? » de `diag_passages.sql`, c'est-à-dire précisément la fausse
-- alarme qu'on cherche à supprimer. `avant` garde le département d'origine,
-- et dit lequel des deux cas on était.
--
-- Ce que cela implique, et qu'il faut savoir
-- ------------------------------------------
-- **Le département 54 change de territoire au 1er janvier 1871, sans changer
-- de numéro.** C'est un fait, pas un défaut :
--
--   1870-1871   dep 54 = Meurthe            29 cantons, 708 communes
--   1871-1941   dep 54 = Meurthe-et-Moselle 32 cantons
--
-- Les deux périodes ne se recouvrent pas — `99` s'arrête au 1871-01-01, `54`
-- commence au 1871-01-01 — donc aucune ambiguïté à une date donnée. Mais une
-- carte qui empile « le département 54 » sur toute la série montrera deux
-- emprises différentes, et c'est ce qui s'est passé.
--
-- Deux mouvements se croisent en 1871, et aucun n'est symétrique :
--
--   * la Meurthe PERD sa partie est, annexée par l'Empire allemand — les
--     cantons d'Albestroff, Château-Salins, Dieuze, Fénétrange, Lorquin,
--     Phalsbourg, Sarrebourg, Vic-sur-Seille et Delme. Mesuré dans la base :
--     **242 des 708 communes de la Meurthe portent aujourd'hui un code INSEE
--     57**, parce qu'elles sont revenues dans la Moselle en 1919 et non dans
--     la Meurthe-et-Moselle ;
--   * la Meurthe GAGNE l'arrondissement de Briey, qui venait de la Moselle.
--     Mesuré aussi : les cantons 5711 Fontoy et 5715 Hayange de 1870-1871
--     portent respectivement 25 et 21 communes dont l'INSEE moderne commence
--     par 54.
--
-- Meurthe-et-Moselle n'est donc PAS la Meurthe amputée : c'est la Meurthe
-- amputée plus Briey. Le numéro 54 survit, le territoire non.
--
-- Ce que ce fichier NE fait PAS
-- ----------------------------
-- **L'identifiant ne change pas.** Les 29 cantons gardent leur `unit_id` en
-- `99xx`. Un identifiant est opaque ; le renuméroter en `54xx` entrerait en
-- collision avec les 32 cantons de Meurthe-et-Moselle, qui occupent déjà
-- 5401 à 5432. Le département est un attribut, pas un préfixe.
--
-- Un seul endroit du dépôt déduisait le département du préfixe de l'identifiant
-- — `cog1968/extrait_1968.py`, fonction `bornes_cantonales()` — et il ne traite
-- que 1968, où les cantons de 1870 n'apparaissent pas. Vérifié avant écriture.
--
-- Reste ouvert, et signalé sans être tranché
-- ------------------------------------------
-- Neuf noms de cantons existent à la fois sous `99xx` et sous `57xx` pour la
-- même période 1870-1871 : Albestroff, Château-Salins, Delme, Dieuze,
-- Fénétrange, Lorquin, Phalsbourg, Sarrebourg, Vic-sur-Seille. Ce sont
-- exactement les cantons annexés. Ils portent des communes DISTINCTES — le
-- contrôle des doubles rattachements n'en signale aucun — mais je ne sais pas
-- dire lequel des deux jeux fait foi pour 1870. Question sur la source, pas
-- sur la base : à porter à Victor Gay.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. DÉFAIRE LE PASSAGE PRÉCÉDENT
--
-- Une MISE À JOUR ne se défait pas par un DELETE : `avant` garde le
-- département d'origine, et c'est lui qu'on restaure. Sur une base où ce
-- fichier était déjà passé avant que la trace existe, `avant` vaudra `54` et
-- la restauration sera un geste nul — c'est le comportement voulu, pas un
-- raté : on ne rend `99` qu'à ce qui le portait.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p39_trace (
    quoi  text NOT NULL,          -- 'unit_dep'
    cle   text NOT NULL,          -- unit_id, stable : jamais renuméroté
    avant text,                   -- le département d'avant le passage
    pose  timestamptz NOT NULL DEFAULT now()
);

UPDATE unit u
   SET dep = t.avant::char(2)
  FROM p39_trace t
 WHERE t.quoi = 'unit_dep' AND t.cle = u.unit_id;

TRUNCATE p39_trace;

-- État avant, pour que la recette ait un point de comparaison.
\echo ''
\echo '-- 1 bis. état avant écriture'
SELECT count(*) FILTER (WHERE dep = '99')      AS cantons_en_99_avant,
       count(*) FILTER (WHERE dep = '54')      AS cantons_en_54_avant
  FROM unit WHERE niveau = 'canton';

-- ---------------------------------------------------------------------------
-- 2. LE DÉPARTEMENT RENDU, ET SA TRACE DANS LA MÊME INSTRUCTION
--
-- La cible est l'identifiant `99xx`, pas le département `99` : voir l'en-tête.
--
-- `avant` n'est PAS lu par `RETURNING` : celui-ci rend la ligne d'APRÈS la
-- mise à jour, donc `54` dans tous les cas. La valeur est posée en dur à `99`,
-- et la note qui suit dit pourquoi c'est la bonne.
-- ---------------------------------------------------------------------------
WITH maj AS (
    UPDATE unit u
       SET dep = '54'
     WHERE u.niveau = 'canton'
       AND (u.dep = '99' OR u.unit_id LIKE '99%')
    RETURNING u.unit_id
)
INSERT INTO p39_trace (quoi, cle, avant)
SELECT 'unit_dep', unit_id, '99' FROM maj;

COMMIT;

-- ---------------------------------------------------------------------------
-- Note sur `avant` : il vaut `99` par construction, et non le département lu
-- avant la mise à jour. C'est volontaire et il faut le dire, sinon la colonne
-- ment. Deux cas seulement se présentent :
--   * base fraîche — les 29 unités portent `99`, `avant` est exact ;
--   * base où `39` était déjà passé sans trace — elles portent `54`, et
--     `avant` dit `99`, c'est-à-dire ce que la source TRF-GIS avait posé et ce
--     à quoi un retrait doit revenir. Défaire `39` sur une telle base rend le
--     `99` de la source, pas l'état de la veille.
-- Dans les deux cas la trace est peuplée, et c'est ce qu'on lui demande : dire
-- que ce fichier est passé, et sur quelles unités.
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- RECETTE
-- ===========================================================================
\echo ''
\echo '-- 3 a. la trace : 29 unités attendues'
SELECT count(*) AS unites_tracees, min(pose) AS pose
  FROM p39_trace WHERE quoi = 'unit_dep';

\echo ''
\echo '-- 3 b. plus aucun canton en 99, et 54 les a repris'
SELECT dep, count(*) AS cantons
  FROM unit
 WHERE niveau = 'canton' AND dep IN ('54', '55', '57', '99')
 GROUP BY dep
 ORDER BY dep;
-- Mesuré le 15 août 2026 : 54 -> 73, 55 -> 31, 57 -> 51, et 99 absent.
--
-- REJOUÉ LE 30 AOÛT 2026 : 54 -> 73, 55 -> 31, **57 -> 52**, 99 absent.
-- Le 57 a gagné un canton, et ce n'est pas ce fichier : `60_canton_forbach2.sql`
-- a créé `5740` Forbach-II le 22 août, un canton que ni TRF-GIS ni le COG 1999
-- ne connaissent et que seul le recensement de 1968 révèle. **Vérifié en base
-- le 30 août 2026** (`5740` = Forbach-II), et non pas seulement déduit. L'attendu écrit
-- ici datait d'avant. *Un attendu inscrit en dur vieillit dès qu'un autre
-- fichier touche la même table* — il faut le dater, ce qui est fait ci-dessus.
--
-- ET IL A FALLU LE REJOUER : `99` était de retour en base. `39` figure pourtant
-- dans `rejouer_apres_rebuild.sh`, mais il n'avait **aucune table de trace**, donc
-- rien ne disait s'il était passé — c'est cette recette-ci, lue par hasard
-- depuis `80`, qui l'a montré. **Dette soldée le 2 septembre 2026** :
-- `p39_trace` existe (§ 3 a), et `diag_passages.sql` la déclare.
--
-- J'avais annoncé 61, 28 et 36 : c'était faux, et l'erreur mérite d'être
-- gardée. Ces chiffres viennent de `build/unit_canton.csv`, qui ne porte que
-- la part TRF-GIS, 1870-1940. La base, elle, contient EN PLUS les cantons
-- modernes chargés par `21_atomes_modernes.sql` et `24_canton_moderne.sql`
-- pour 1999-2012. Un compte tiré du fichier de chargement n'est pas un compte
-- de la base — c'est la même confusion que le dénominateur des villes à
-- découper, 270 puis 369 puis 119.

-- ---------------------------------------------------------------------------
-- 3 c. Aucun ATOME ne relève de deux cantons à la même date.
--
-- Premier jet, et il était faux : je groupais par `insee_geofla`. Il a sorti
-- une ligne — Moyenvic (57490), rattachée à la fois à Château-Salins (9905) et
-- à Vic-sur-Seille (9929) en 1870-1871 — et j'ai cru à un recouvrement créé
-- par la fusion des deux emprises du 54.
--
-- Ce n'en était pas un. Moyenvic porte DEUX ATOMES, 24365 et 35117, deux
-- identifiants Cassini distincts : ce sont deux communes de 1870, fondues
-- depuis en une seule, qui partagent le même code INSEE de 2011. Chacune était
-- dans son canton, et les deux rattachements sont justes.
--
-- C'est le piège que `METHODE.md` documente et que ce projet a déjà payé trois
-- fois : **grouper par un code, jamais par la géométrie ni par l'atome**. Le
-- même geste avait donné 369 villes à découper au lieu de 119. Sept autres
-- communes du même secteur sont dans ce cas — Malzéville, Ars-Laquenexy,
-- Azoudange, Fonteny, Maizières-lès-Vic, Richeval, Sérémange-Erzange — et
-- aucune n'est un défaut.
--
-- La bonne unité est l'ATOME. C'est d'ailleurs ce que la contrainte
-- `EXCLUDE USING gist` garantit déjà, et elle tient.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3 c. atomes rattachés à deux cantons du 54 à la même date (attendu : 0)'
SELECT count(*) AS atomes_a_double_dans_le_54
  FROM (SELECT m.atom_id, m.periode
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id
         WHERE m.niveau = 'canton' AND u.dep = '54'
         GROUP BY 1, 2
        HAVING count(DISTINCT m.unit_id) > 1) x;

-- ---------------------------------------------------------------------------
-- 3 d. La Meurthe au 1er juin 1870, telle qu'on pourra désormais
--      l'interroger. 29 cantons attendus.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3 d. la Meurthe au 1er juin 1870 (29 cantons attendus)'
SELECT u.unit_id, u.nom, count(*) AS communes
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id
 WHERE m.niveau = 'canton'
   AND u.dep = '54'
   AND m.periode @> DATE '1870-06-01'
 GROUP BY 1, 2
 ORDER BY u.unit_id;


-- ---------------------------------------------------------------------------
-- Diagnostic, conservé : il montre les communes MODERNES qui recouvrent
-- plusieurs communes de 1870. Ce n'est pas une anomalie, c'est le mécanisme
-- des absorptions — utile à connaître avant de cartographier le 54 ancien.
-- ---------------------------------------------------------------------------
SELECT a.insee_geofla,
       n.nom                                   AS commune,
       string_agg(m.unit_id || ' ' || u.nom || ' [' ||
                  m.valid_from || ' → ' || m.valid_to || ']',
                  '   |   ' ORDER BY m.unit_id) AS rattachements
  FROM membership m
  JOIN atom a USING (atom_id)
  JOIN unit u ON u.unit_id = m.unit_id
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
 WHERE m.niveau = 'canton' AND u.dep = '54' AND NOT a.fraction
 GROUP BY a.insee_geofla, n.nom, m.periode
HAVING count(DISTINCT m.unit_id) > 1;

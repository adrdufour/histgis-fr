-- ============================================================================
-- 39_meurthe_1870.sql — la Meurthe reprend son numéro : 99 -> 54
--
--   psql -d histgis -f sql/39_meurthe_1870.sql
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
-- Idempotent : ne touche que ce qui est encore en 99.
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

SET search_path TO histgis, public;

BEGIN;

-- État avant, pour que la recette ait un point de comparaison.
SELECT count(*) AS cantons_en_99_avant
  FROM unit WHERE niveau = 'canton' AND dep = '99';

UPDATE unit
   SET dep = '54'
 WHERE niveau = 'canton'
   AND dep = '99';

COMMIT;

-- ---------------------------------------------------------------------------
-- Recette 1 : plus aucun canton en 99, et 54 en compte 29 de plus.
-- ---------------------------------------------------------------------------
SELECT dep, count(*) AS cantons
  FROM unit
 WHERE niveau = 'canton' AND dep IN ('54', '55', '57', '99')
 GROUP BY dep
 ORDER BY dep;
-- Mesuré le 15 août 2026 : 54 -> 73, 55 -> 31, 57 -> 51, et 99 absent.
--
-- J'avais annoncé 61, 28 et 36 : c'était faux, et l'erreur mérite d'être
-- gardée. Ces chiffres viennent de `build/unit_canton.csv`, qui ne porte que
-- la part TRF-GIS, 1870-1940. La base, elle, contient EN PLUS les cantons
-- modernes chargés par `21_atomes_modernes.sql` et `24_canton_moderne.sql`
-- pour 1999-2012. Un compte tiré du fichier de chargement n'est pas un compte
-- de la base — c'est la même confusion que le dénominateur des villes à
-- découper, 270 puis 369 puis 119.

-- ---------------------------------------------------------------------------
-- Recette 2 : aucun ATOME ne relève de deux cantons à la même date.
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
SELECT count(*) AS atomes_a_double_dans_le_54
  FROM (SELECT m.atom_id, m.periode
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id
         WHERE m.niveau = 'canton' AND u.dep = '54'
         GROUP BY 1, 2
        HAVING count(DISTINCT m.unit_id) > 1) x;
-- Attendu : 0, et cette fois l'attendu porte sur la bonne unité.

-- ---------------------------------------------------------------------------
-- Recette 3 : la Meurthe au 1er juin 1870, telle qu'on pourra désormais
-- l'interroger. 29 cantons attendus.
-- ---------------------------------------------------------------------------
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

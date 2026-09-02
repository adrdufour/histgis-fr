-- ============================================================================
-- histgis — 84_carte_partition.sql : une carte sans trou et sans superposition
--
--     psql -d histgis -f sql/84_carte_partition.sql
--     SELECT unit_id, nom, geom FROM carte_partition('1885-06-01', 'canton');
--
-- CE QUE CE FICHIER CORRIGE
-- -------------------------
-- Depuis `82`, la carte se dessine sur `coalesce(atom_geom_anr @ date,
-- atom_geom)` : ANR quand il parle, GEOFLA 2011 en repli (R5). C'est une trame
-- HYBRIDE, et une trame hybride a des coutures. Là où un atome retombe sur
-- GEOFLA pendant que ses voisins viennent d'ANR, les bords ne coïncident plus.
--
-- Mesuré le 2 septembre 2026 sur l'export web, à 1870, entre communes
-- ordinaires (fractions et villes partagées mises à part) :
--
--     ANR × ANR ...........  2 353 paires ......    1,0 km²
--     ANR × repli .......... 1 618 paires .... 4 542,8 km²   ← la couture
--     repli × repli ........     2 paires ......    0,0 km²
--
-- 72 départements. 393 paires sont des superpositions franches — 4 267 km²,
-- une fille reportée en arrière posée tout entière sur sa mère intacte — et
-- 1 225 des lisières : 275 km², le double trait que l'œil repère entre
-- Villieu-Loyes-Mollon et Meximieux dans l'Ain.
--
-- CE QUE LA RECETTE DE `82` NE POUVAIT PAS VOIR. `check_geom_anr` joint
-- `atom_geom_anr` à elle-même. Ses 101,0 km² mesurent le recouvrement DE LA
-- SOURCE ; la carte, elle, dessine le COMPOSITE, et personne ne l'avait mesuré.
-- *Une recette qui mesure la source ne mesure pas le composite qu'on en tire.*
--
-- CE QUE CE FICHIER NE TOUCHE PAS
-- -------------------------------
-- `atom_geom`, `atom_geom_anr` et `membership` restent intacts : `84` est une
-- couche DÉRIVÉE, lue à la demande, jamais une réécriture. `snapshot_geom_anr()`
-- continue de répondre exactement ce qu'elle répondait — la carte brute reste
-- consultable, et c'est elle qui fait foi pour dire d'où vient un polygone.
--
-- Les **333 fractions et les villes partagées** ne sont pas résolues ici. Elles
-- entrent dans le treillis comme UN propriétaire — la commune-mère — et en
-- ressortent dupliquées par canton avec leur drapeau `partagee`, comme
-- aujourd'hui. Leur superposition est connue, nommée, hachurée en légende ;
-- la lever demanderait de tracer une ligne qu'aucune source ne porte.
--
-- L'ALGORITHME, ET POURQUOI IL N'A AUCUN SEUIL
-- --------------------------------------------
-- 1. LA REPRISE (§ 4). Un atome que la base fait vivre à la date et qu'ANR ne
--    pourvoit pas alors reçoit la DIFFÉRENCE des deux polygones du voisin qui
--    s'en sépare l'année de sa prochaine apparition chez ANR :
--
--        territoire(fille, D) = voisin(D) − voisin(Y′)
--        Y′ = première année > D où ANR pourvoit la fille
--        voisin = celui dont la chronologie ANR porte une coupure en Y′
--
--    C'est la lecture symétrique de R1 : ANR écrit la fin du polygone de la
--    mère et le début de celui de la fille sur le même millésime. Deux
--    polygones datés, une soustraction, et une frontière d'époque au lieu
--    d'une frontière de 2011.
--
--    DEUX RÈGLES FAUSSES ONT PRÉCÉDÉ CELLE-LÀ, et `sql/banc_84.py` garde le
--    détail des deux échecs. En bref :
--
--    — *Le repli n'est pas le territoire de la fille.* Lui faire garder son
--      polygone GEOFLA puis le retrancher de la mère réduisait Loyes de 10,08
--      à 0,48 km² et Rillieux-la-Pape à 0,08. `atom_geom` porte le polygone de
--      la commune TERMINALE de la lignée Cassini : pour l'atome 40689 c'est
--      Villieu-Loyes-Mollon, la fusionnée de 1973, qui contient sa propre mère.
--      *Un polygone de repli dit où une commune est aujourd'hui, pas quel sol
--      elle tenait alors.*
--
--    — *Un trou de chronologie n'est pas une lacune.* Une première version
--      comblait les trous d'ANR en reportant le dernier polygone antérieur.
--      Sur l'Aveyron, les dix plus grosses faces disputées portaient toutes ce
--      motif — Saint-Beaulize contre Fondamente, La Serre contre
--      Saint-Sernin-sur-Rance, Les Albres contre Aspriéres. Ces communes ont
--      été RÉUNIES à leur voisine puis rétablies (chantier `41`) : le trou
--      d'ANR est un fait. Reporter le polygone d'avant la réunion par-dessus
--      la voisine qui l'avait absorbée recréait le double comptage qu'on
--      venait d'ôter. *Un trou dans une source datée peut être ce qu'elle a de
--      plus exact.* La règle unique traite naissance et rétablissement sans
--      les distinguer : vus d'ANR, ce sont le même événement.
--
-- 2. LE TREILLIS (§ 5). Nouer toutes les frontières, polygoniser. Une face est
--    indivisible : elle a un propriétaire et un seul. Le recouvrement devient
--    IMPOSSIBLE par construction, au lieu d'être corrigé après coup.
--
-- 3. L'ARBITRAGE (§ 5), dans l'ordre, chaque face gardant son motif :
--      unique        un seul candidat ;
--      source_datee  un polygone ANR contre un repli : à l'ANR, la source
--                    datée garde son bord ;
--      departage     à égalité, au plus petit polygone puis au plus petit
--                    atom_id — déterministe, et mesuré à 0,4 km² sur 23 dép. ;
--      comblement    aucun candidat, donc un trou interne : au voisin
--                    partageant le plus long bord, itéré jusqu'à épuisement.
--
-- 4. LA DISSOLUTION (§ 6). Les limites cantonales sont faites des mêmes arêtes
--    que les limites communales : elles coïncident sans qu'on l'ait demandé.
--
-- LE CADRE DOIT ÊTRE PLUS LARGE QUE LE DÉPARTEMENT. Un territoire enclavé —
-- la Seine dans la Seine-et-Oise de 1870, l'enclave des papes dans la Drôme —
-- ressemble à un trou du dessin si on ne regarde qu'un département, et le
-- comblement le donne au premier voisin venu. Le premier jet du banc offrait
-- ainsi les 478 km² du département de la Seine à ses voisines. D'où l'anneau
-- de contexte du § 5 : les atomes des 20 km alentour entrent dans le treillis
-- et n'en sortent jamais. *Un trou n'est un trou que dans un cadre assez large
-- pour contenir ce qui le remplit.*
--
-- CHIFFRES ATTENDUS, mesurés hors base par `sql/banc_84.py` sur l'export web
-- (WGS84, grille 25 m — les COMPTES sont exacts, les km² approchés à ±0,3 %).
--
-- TOUS AU 1ᵉʳ DÉCEMBRE, comme `export_web.py` (`MOIS_JOUR`). Les comparer à un
-- `check_partition` lancé au 1ᵉʳ janvier, c'est comparer deux cartes distantes
-- de onze mois — voir la note du § 7.
--
--     à 1870, sur 23 départements (01-23)
--       recouvrement ................. 6 923,6 km²  →  0,000 km²
--       trou non comblé .............................  0,000 km²
--       perte de polygonisation .....................  0,000 km²
--       atome sans aucune face ......................  0
--       faces : unique 10 813 · source_datee 1 473 (367,5 km²)
--               departage 975 (0,4 km²) · comblement 1 988 (33,0 km²)
--
--     à 1870, passe nationale sur les 89 départements servis
--       atomes dessinés ............................. 38 331
--       pourvus par ANR ............................. 37 497
--       repris par différence .......................    432  (25 fratries)
--       repli GEOFLA résiduel .......................    111
--       fractions et partagées, inchangées ..........    291
--
-- Les 111 orphelins sont une limite DU BANC, pas de l'algorithme : il cherche
-- la mère dans le seul département courant. `84` la cherche dans l'anneau de
-- contexte et doit en trouver davantage. C'est le premier chiffre à comparer.
--
-- JOUÉ LE 2 SEPTEMBRE 2026. Recouvrement hors fraction **0,000 km²** et zéro
-- géométrie invalide sur l'Ain comme sur l'Aveyron. Le fichier s'était chargé
-- sans une erreur AVANT d'être corrigé six fois : *un corps PL/pgSQL n'est
-- analysé qu'au premier appel*, si bien qu'un chargement propre ne prouve rien
-- d'une fonction procédurale — pour `82`, écrit en SQL pur, il valait contrôle.
-- Reste à jouer : les autres départements et la passe nationale.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- § 1. Garde-fous.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql avant celui-ci.';
    END IF;
    IF to_regclass('histgis.atom_geom') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : la base n''est pas chargée (atom_geom absente).';
    END IF;
    IF to_regclass('histgis.membership') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : la base n''est pas chargée (membership absente).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 2. Rejouabilité. Ce fichier ne pose que des fonctions et une table de
--      trace : les défaire suffit à défaire son passage.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS carte_partition(date, text, text);
DROP FUNCTION IF EXISTS carte_partition_atome(date, text);
DROP FUNCTION IF EXISTS partition_un_dep(date, text);
DROP FUNCTION IF EXISTS partition_reprise(date, text);
DROP FUNCTION IF EXISTS check_partition(date, text);
DROP PROCEDURE IF EXISTS partition_journalise(date, text);
DROP TABLE IF EXISTS p84_trace;

CREATE TABLE p84_trace (
    fait      timestamptz NOT NULL DEFAULT now(),
    p_date    date        NOT NULL,
    dep       text,
    quoi      text        NOT NULL,
    n         bigint,
    km2       numeric,
    note      text
);

COMMENT ON TABLE p84_trace IS
    'Ce que 84 a arbitré, date par date et département par département. Une carte propre qui ne dit pas où elle a tranché est une carte qui ment par omission.';

-- ---------------------------------------------------------------------------
-- § 3. L'anneau de contexte : les atomes à charger pour traiter `p_dep`.
--      NULL = la France entière, et alors l'anneau n'a pas lieu d'être.
--
--      20 km en Lambert-93. Ce n'est pas un seuil d'arbitrage — aucun résultat
--      n'en dépend — c'est une fenêtre de chargement : au-delà, un polygone ne
--      peut plus toucher le département. La plus grande commune de France
--      métropolitaine (Arles, 759 km²) tient dans un disque de 20 km de rayon.
-- ---------------------------------------------------------------------------
CREATE FUNCTION partition_reprise(p_date date, p_dep text DEFAULT NULL)
RETURNS TABLE (atom_id text, geom geometry, mere_id text, an_reprise int,
               fratrie int)
LANGUAGE sql STABLE AS $$
    WITH cadre AS (
        -- ST_SetSRID est obligatoire : `ST_Extent` rend un box2d, et un box2d
        -- casté en geometry perd son SRID. Sans lui, `ST_Intersects` refuse la
        -- comparaison — panne muette au premier appel avec un département.
        SELECT CASE WHEN p_dep IS NULL THEN NULL
               ELSE ST_Expand(ST_SetSRID(ST_Extent(ag.geom)::geometry, 2154),
                              20000) END AS boite
        FROM   membership m
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
        WHERE  m.periode @> p_date
          AND  (p_dep IS NULL OR u.dep = p_dep)
    ),
    -- Les atomes vivants à la date, dans le cadre.
    vivant AS (
        SELECT DISTINCT m.atom_id, a.fraction
        FROM   membership m
        JOIN   atom a ON a.atom_id = m.atom_id
        LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
        CROSS  JOIN cadre c
        WHERE  m.periode @> p_date
          AND  (c.boite IS NULL OR ag.geom IS NULL OR ST_Intersects(ag.geom, c.boite))
    ),
    -- Ceux qu'ANR ne pourvoit pas à cette date, et qui ont un repli pour dire
    -- où ils sont. Les fractions sont hors sujet : ANR ne les pourvoit jamais.
    manquant AS (
        SELECT v.atom_id, ag.geom AS g_repli
        FROM   vivant v
        JOIN   atom_geom ag ON ag.atom_id = v.atom_id
        WHERE  NOT v.fraction
          AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                           WHERE g.atom_id = v.atom_id AND g.periode @> p_date)
    ),
    -- Y′ : la première année > D où ANR reparle d'eux. Naissance ou
    -- rétablissement, ANR n'a qu'une manière de le dire.
    reprise AS (
        SELECT mq.atom_id, mq.g_repli,
               min(lower(g.periode)) AS d_reprise
        FROM   manquant mq
        JOIN   atom_geom_anr g ON g.atom_id = mq.atom_id
                              AND lower(g.periode) > p_date
        GROUP  BY mq.atom_id, mq.g_repli
    ),
    -- La mère : le voisin pourvu à la date, que le repli touche, et dont la
    -- chronologie ANR se coupe exactement en Y′. À plusieurs candidats, celui
    -- que le repli recouvre le plus — un départage, pas un critère.
    mere AS (
        SELECT DISTINCT ON (r.atom_id)
               r.atom_id, r.d_reprise, gb.atom_id AS mere_id,
               gb.geom AS g_avant, gm.geom AS g_apres
        FROM   reprise r
        JOIN   atom_geom_anr gb ON gb.periode @> p_date
                               AND gb.atom_id <> r.atom_id
                               AND ST_Intersects(gb.geom, r.g_repli)
        JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                               AND lower(gm.periode) = r.d_reprise
        ORDER  BY r.atom_id,
                  ST_Area(ST_Intersection(gb.geom, r.g_repli)) DESC,
                  gb.atom_id
    ),
    -- La différence, et les fratries. `count(*)` est ici un agrégat ordinaire
    -- sur les filles d'un même couple (mère, Y′) — surtout pas une fonction de
    -- fenêtre posée après le GROUP BY, qui compterait les groupes et rendrait
    -- 1 partout.
    -- `(array_agg(…))[1]` et non `min(…)` : PostGIS ne fournit pas d'agrégat
    -- `min` sur une géométrie. Les deux polygones du couple (mère, Y′) sont
    -- identiques dans tout le groupe — n'importe lequel fait l'affaire, il
    -- faut juste pouvoir en désigner un sans invoquer un ordre qui n'existe pas.
    -- `ST_CollectionExtract(…, 3)` ne garde que le surfacique. Une différence
    -- entre deux polygones qui partagent un bout de frontière rend volontiers
    -- une GeometryCollection avec des lisières linéaires ; `ST_Multi` refuse
    -- une GeometryCollection, et l'erreur ne tomberait que sur le département
    -- où le cas se présente. On la retire ici plutôt que de l'apprendre là-bas.
    diff AS (
        SELECT m.mere_id, m.d_reprise, count(*)::int AS fratrie,
               ST_CollectionExtract(
                   ST_Difference((array_agg(m.g_avant))[1],
                                 (array_agg(m.g_apres))[1]), 3) AS reste
        FROM   mere m
        GROUP  BY m.mere_id, m.d_reprise
    ),
    -- Le dépliage AVANT la numérotation, en deux niveaux : `ST_Dump` est une
    -- fonction à retour multiple et `row_number()` une fonction de fenêtre, et
    -- les mettre dans la même liste de sélection fait dépendre le résultat de
    -- l'ordre d'évaluation choisi par le planificateur.
    --
    -- Chaque morceau porte ensuite un identifiant entier : `DISTINCT ON` sur
    -- une géométrie s'appuierait sur l'opérateur `=` de PostGIS, dont la
    -- sémantique a changé entre versions. Un entier ne change pas de sens.
    eclat AS (
        SELECT d.mere_id, d.d_reprise, d.fratrie,
               (ST_Dump(d.reste)).geom AS g
        FROM   diff d
    ),
    morceau AS (
        SELECT row_number() OVER () AS mid, e.*
        FROM   eclat e
    ),
    attribue AS (
        SELECT DISTINCT ON (mo.mid)
               me.atom_id, mo.mid, mo.g, mo.mere_id, mo.d_reprise, mo.fratrie
        FROM   morceau mo
        JOIN   mere me ON me.mere_id = mo.mere_id
                      AND me.d_reprise = mo.d_reprise
        JOIN   reprise r ON r.atom_id = me.atom_id
        ORDER  BY mo.mid,
                  ST_Area(ST_Intersection(r.g_repli, mo.g)) DESC,
                  me.atom_id
    )
    SELECT a.atom_id,
           ST_Multi(ST_CollectionExtract(ST_UnaryUnion(ST_Collect(a.g)), 3)),
           max(a.mere_id),
           extract(year FROM max(a.d_reprise))::int,
           max(a.fratrie)::int
    FROM   attribue a
    GROUP  BY a.atom_id;
$$;

COMMENT ON FUNCTION partition_reprise(date, text) IS
    'La reprise : territoire(fille, D) = voisin(D) − voisin(Y′). Ne rend que les atomes repris ; les autres gardent ce que 82 leur donne.';

-- ---------------------------------------------------------------------------
-- § 4-5. Le treillis, l'arbitrage, le comblement.
--
--      Écrit en PL/pgSQL et pas en SQL pur pour une seule raison : le
--      comblement est ITÉRATIF. Un trou peut ne toucher que d'autres trous, et
--      il faut recommencer jusqu'à ce qu'un tour n'attribue plus rien — après
--      quoi ce qui reste est DÉCLARÉ, jamais comblé au jugé.
-- ---------------------------------------------------------------------------
-- VOLATILE, et non STABLE : la fonction crée des tables temporaires. Le
-- déclarer STABLE serait un mensonge au planificateur, et interdirait l'appel
-- dans une transaction en lecture seule sans que l'erreur dise pourquoi.
--
-- UN DÉPARTEMENT À LA FOIS, TOUJOURS, ET C'EST STRUCTUREL.
-- Cette fonction-ci ne traite qu'un département ; `carte_partition_atome` la
-- boucle. La première version acceptait `NULL` et bâtissait UN SEUL treillis
-- national : `ST_Union` sur les frontières des 38 000 communes de France, puis
-- `ST_Polygonize` dessus. Lancée le 2 septembre, elle n'a jamais rendu la main.
--
-- Ce n'est pas une lenteur, c'est un changement de régime : nouer un graphe
-- planaire coûte en n log n dans le meilleur cas et bien davantage quand les
-- arêtes se croisent, et rien dans le résultat ne le justifie — un atome ne
-- dispute jamais une face à un autre situé à cent kilomètres. Le découpage par
-- département avec anneau de contexte rend EXACTEMENT le même dessin, puisque
-- l'anneau contient tout ce qui peut toucher le département.
--
-- *Une opération globale qui n'a que des effets locaux doit être découpée ;
-- le seul travail est de choisir un cadre plus large que la portée des effets.*
CREATE FUNCTION partition_un_dep(p_date date, p_dep text)
RETURNS TABLE (atom_id text, geom geometry(MultiPolygon, 2154),
               source text, motif text, dedans boolean)
LANGUAGE plpgsql VOLATILE AS $$
-- `RETURNS TABLE` déclare `atom_id`, `geom`, `source`, `motif` et `dedans`
-- comme des VARIABLES PL/pgSQL, et les tables temporaires ci-dessous portent
-- des colonnes des mêmes noms. Sans cette directive, la moindre référence non
-- qualifiée — `DELETE FROM t84_src WHERE geom IS NULL` — échoue à l'exécution
-- sur « column reference is ambiguous », et pas au chargement du fichier : le
-- corps d'une fonction PL/pgSQL n'est analysé qu'au premier appel.
--
-- `use_column` est sans danger ici : les seules vraies variables sont `n_pose`
-- et `tour`, qui ne portent le nom d'aucune colonne. *Une fonction qui rend une
-- table se donne un jeu de noms réservés, et il vaut mieux le déclarer une fois
-- que le contourner à chaque ligne.*
#variable_conflict use_column
DECLARE
    n_pose bigint;
    tour   int := 0;
BEGIN
    -- Le garde-fou qui manquait. Sans lui, un `NULL` égaré ici rebâtit le
    -- treillis national et la session semble bloquée sans un mot.
    IF p_dep IS NULL THEN
        RAISE EXCEPTION 'partition_un_dep : un département est obligatoire. '
                        'Pour la France entière, appeler '
                        'carte_partition_atome(date), qui boucle.';
    END IF;

    -- `partition_reprise` est appelée une fois et matérialisée : elle est
    -- coûteuse, et le § 4 en a besoin deux fois — pour donner à la fille, puis
    -- pour retrancher de la mère.
    DROP TABLE IF EXISTS t84_rep;
    CREATE TEMP TABLE t84_rep ON COMMIT DROP AS
    SELECT * FROM partition_reprise(p_date, p_dep);
    CREATE INDEX ON t84_rep (atom_id);
    CREATE INDEX ON t84_rep (mere_id);

    -- (a) La source : ANR, la reprise, le repli — un polygone par atome.
    DROP TABLE IF EXISTS t84_src;
    CREATE TEMP TABLE t84_src ON COMMIT DROP AS
    WITH cadre AS (
        SELECT CASE WHEN p_dep IS NULL THEN NULL
               ELSE ST_Expand(ST_SetSRID(ST_Extent(ag.geom)::geometry, 2154),
                              20000) END AS boite
        FROM   membership m
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
        WHERE  m.periode @> p_date AND (p_dep IS NULL OR u.dep = p_dep)
    ),
    -- `dedans` sépare le département demandé de son anneau de contexte : le
    -- contexte tient la topologie et ne sort jamais du résultat.
    vivant AS (
        SELECT DISTINCT m.atom_id, a.fraction,
               bool_or(p_dep IS NULL OR u.dep = p_dep) AS dedans
        FROM   membership m
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        JOIN   atom a ON a.atom_id = m.atom_id
        LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
        CROSS  JOIN cadre c
        WHERE  m.periode @> p_date
          AND  (c.boite IS NULL OR ag.geom IS NULL
                OR ST_Intersects(ag.geom, c.boite))
        GROUP  BY m.atom_id, a.fraction
    ),
    rep AS (SELECT * FROM t84_rep)
    SELECT v.atom_id,
           v.fraction,
           v.dedans,
           coalesce(r.geom, ga.geom, ag.geom)              AS geom,
           CASE WHEN r.atom_id IS NOT NULL THEN 'reprise'
                WHEN ga.atom_id IS NOT NULL THEN 'anr'
                WHEN ag.atom_id IS NOT NULL THEN 'repli'
                ELSE 'sans_geom' END                       AS source
    FROM   vivant v
    LEFT   JOIN rep r ON r.atom_id = v.atom_id
    LEFT   JOIN atom_geom_anr ga
           ON ga.atom_id = v.atom_id AND ga.periode @> p_date
    LEFT   JOIN atom_geom ag ON ag.atom_id = v.atom_id;

    DELETE FROM t84_src WHERE geom IS NULL;

    -- La mère se réduit à ce qu'elle garde. Sans cela, le treillis verrait la
    -- fille ET sa mère revendiquer le même sol, et `source_datee` donnerait le
    -- sol à la mère — le contraire de ce que la reprise vient d'établir.
    UPDATE t84_src s
       SET geom = ST_Multi(ST_CollectionExtract(
                      ST_Difference(s.geom, x.pris), 3))
      FROM (SELECT r.mere_id, ST_UnaryUnion(ST_Collect(r.geom)) AS pris
              FROM t84_rep r
             GROUP BY r.mere_id) x
     WHERE s.atom_id = x.mere_id
       AND NOT ST_IsEmpty(ST_CollectionExtract(
                              ST_Difference(s.geom, x.pris), 3));

    -- (b) Un propriétaire par polygone DISTINCT. Les fractions d'une même
    --     commune partagent le leur : elles ne doivent pas se disputer le
    --     treillis, elles ressortiront dupliquées au § 6, drapeau compris.
    --
    --     Le regroupement porte sur l'EMPREINTE seule. Ajouter `geom` au
    --     GROUP BY reviendrait à grouper aussi par l'opérateur d'égalité de
    --     PostGIS, dont la sémantique a changé entre versions : deux polygones
    --     identiques pourraient former deux groupes, et le treillis les verrait
    --     se disputer leur propre sol.
    DROP TABLE IF EXISTS t84_prop;
    CREATE TEMP TABLE t84_prop ON COMMIT DROP AS
    --     `(array_agg(...))[1]` plutôt que `min(geom)` : l'agrégat `min` sur
    --     une géométrie dépend d'un opclass btree que toutes les versions de
    --     PostGIS n'exposent pas de la même façon. Un tableau, si.
    SELECT (row_number() OVER (ORDER BY min(atom_id)))::int   AS pid,
           md5(ST_AsBinary(geom))                             AS empreinte,
           (array_agg(geom ORDER BY atom_id))[1]              AS geom,
           ST_Area((array_agg(geom ORDER BY atom_id))[1])     AS aire,
           bool_and(source = 'repli')                         AS est_repli,
           bool_or(dedans)                                    AS dedans,
           min(source)                                        AS source
    FROM   t84_src
    GROUP  BY md5(ST_AsBinary(geom));

    CREATE INDEX ON t84_prop USING gist (geom);
    ANALYZE t84_prop;

    -- (c) Le treillis. L'AGRÉGAT `ST_Union` sur les frontières, et surtout pas
    --     `ST_Node(ST_Collect(...))` : `ST_Collect` empile sans nouer et rend
    --     une GeometryCollection que `ST_Node` refuse. `ST_Union` noue en
    --     rendant une MultiLineString — sans quoi deux frontières qui se
    --     croisent hors sommet ne polygonisent pas, et la face manquante
    --     devient un trou que le § (e) comblerait sans savoir pourquoi.
    DROP TABLE IF EXISTS t84_face;
    CREATE TEMP TABLE t84_face ON COMMIT DROP AS
    SELECT (row_number() OVER ())::int AS fid,
           g                           AS geom,
           ST_PointOnSurface(g)        AS pt,
           NULL::int                   AS pid,
           NULL::text                  AS motif
    --     Trois niveaux et pas deux : `ST_Polygonize` n'a pas de variante
    --     scalaire, c'est un AGRÉGAT. L'appeler dans la même liste de sélection
    --     que le `ST_Dump` qui le consomme mêle un agrégat et une fonction à
    --     retour multiple, ce que le planificateur traite mal selon la version.
    --     On agrège d'abord, on déplie ensuite.
    FROM  (SELECT (ST_Dump(p)).geom AS g
             FROM (SELECT ST_Polygonize(l) AS p
                     FROM (SELECT ST_Union(ST_Boundary(geom)) AS l
                             FROM t84_prop) n) q) d
    WHERE NOT ST_IsEmpty(g);

    CREATE INDEX ON t84_face USING gist (pt);
    CREATE INDEX ON t84_face USING gist (geom);
    CREATE INDEX ON t84_face (fid);
    ANALYZE t84_face;

    -- (d) L'arbitrage. Une face, un propriétaire.
    WITH cand AS (
        SELECT f.fid, p.pid, p.est_repli, p.aire
        FROM   t84_face f
        JOIN   t84_prop p ON ST_Contains(p.geom, f.pt)
    ),
    enr AS (
        SELECT c.*,
               count(*)      OVER (PARTITION BY fid) AS n_cand,
               count(*) FILTER (WHERE NOT est_repli)
                             OVER (PARTITION BY fid) AS n_date
        FROM   cand c
    ),
    pris AS (
        SELECT DISTINCT ON (fid) fid, pid,
               CASE WHEN n_cand = 1 THEN 'unique'
                    WHEN n_date = 1 THEN 'source_datee'
                    ELSE 'departage' END AS motif
        FROM   enr
        ORDER  BY fid, est_repli, aire, pid
    )
    UPDATE t84_face f SET pid = pris.pid, motif = pris.motif
      FROM pris WHERE pris.fid = f.fid;

    -- (e) Le comblement, itératif. Au voisin partageant le plus long bord.
    LOOP
        tour := tour + 1;
        WITH orphelin AS (SELECT fid, geom FROM t84_face WHERE pid IS NULL),
        voisin AS (
            SELECT DISTINCT ON (o.fid) o.fid, v.pid
            FROM   orphelin o
            JOIN   t84_face v ON v.pid IS NOT NULL
                             AND v.fid <> o.fid
                             AND ST_Intersects(o.geom, v.geom)
            ORDER  BY o.fid,
                      ST_Length(ST_Intersection(ST_Boundary(o.geom),
                                                ST_Boundary(v.geom))) DESC,
                      v.pid
        )
        UPDATE t84_face f SET pid = voisin.pid, motif = 'comblement'
          FROM voisin WHERE voisin.fid = f.fid;
        GET DIAGNOSTICS n_pose = ROW_COUNT;
        EXIT WHEN n_pose = 0 OR tour > 20;
    END LOOP;

    -- (f) Recomposer, puis rendre à chaque atome ce que porte son polygone.
    --     Le motif rendu est le plus NOTABLE des faces qui composent l'atome,
    --     pas le premier venu : un polygone dont une seule face a été comblée
    --     doit le dire. L'ordre va du plus arbitraire au plus sûr.
    RETURN QUERY
    WITH net AS (
        SELECT f.pid,
               ST_Multi(ST_CollectionExtract(
                   ST_UnaryUnion(ST_Collect(f.geom)), 3)) AS g,
               CASE WHEN bool_or(f.motif = 'comblement')   THEN 'comblement'
                    WHEN bool_or(f.motif = 'departage')    THEN 'departage'
                    WHEN bool_or(f.motif = 'source_datee') THEN 'source_datee'
                    ELSE 'unique' END AS motif
        FROM   t84_face f
        WHERE  f.pid IS NOT NULL
        GROUP  BY f.pid
    )
    SELECT s.atom_id, n.g, s.source, n.motif, s.dedans
    FROM   t84_src s
    JOIN   t84_prop p ON p.empreinte = md5(ST_AsBinary(s.geom))
    JOIN   net n ON n.pid = p.pid
    WHERE  s.dedans;
END $$;

COMMENT ON FUNCTION partition_un_dep(date, text) IS
    'Le treillis d''UN département, anneau de contexte compris. Passer par carte_partition_atome() plutôt que l''appeler directement.';


-- Le dispatcheur. Un département, ou la France département par département —
-- jamais la France d'un seul tenant, pour la raison exposée plus haut.
--
-- `RAISE NOTICE` à chaque département : une passe nationale dure des minutes,
-- et une fonction muette qui dure des minutes est indiscernable d'une fonction
-- bloquée. C'est précisément ce qui s'est passé au premier essai.
CREATE FUNCTION carte_partition_atome(p_date date, p_dep text DEFAULT NULL)
RETURNS TABLE (atom_id text, geom geometry(MultiPolygon, 2154),
               source text, motif text, dedans boolean)
LANGUAGE plpgsql VOLATILE AS $$
#variable_conflict use_column
DECLARE
    d      text;
    n_dep  int := 0;
    i      int := 0;
BEGIN
    IF p_dep IS NOT NULL THEN
        RETURN QUERY SELECT * FROM partition_un_dep(p_date, p_dep);
        RETURN;
    END IF;

    SELECT count(DISTINCT u.dep) INTO n_dep
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.periode @> p_date;

    FOR d IN
        SELECT DISTINCT u.dep
        FROM   membership m
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE  m.periode @> p_date
        ORDER  BY 1
    LOOP
        i := i + 1;
        RAISE NOTICE 'carte_partition_atome %/% : département %', i, n_dep, d;
        RETURN QUERY SELECT * FROM partition_un_dep(p_date, d);
    END LOOP;
END $$;

COMMENT ON FUNCTION carte_partition_atome(date, text) IS
    'La trame communale nettoyée à une date : une face, un propriétaire. Un département, ou la France département par département. Ex : SELECT * FROM carte_partition_atome(''1870-12-01'', ''01'');';

-- ---------------------------------------------------------------------------
-- § 6. La carte dissoute. Les limites cantonales sortent des mêmes arêtes que
--      les limites communales : elles coïncident sans qu'on l'ait demandé.
--
--      `n_repris`, `n_repli` et `n_partagees` restent exportés : une unité qui
--      doit sa forme à une reprise, ou qui contient une ville partagée, doit
--      pouvoir le dire à la légende. *Une carte propre qui ne dit pas où elle
--      a tranché est une carte qui ment par omission.*
-- ---------------------------------------------------------------------------
CREATE FUNCTION carte_partition(p_date date, p_niveau text DEFAULT 'canton',
                                p_dep text DEFAULT NULL)
RETURNS TABLE (unit_id text, niveau text, dep text, nom text,
               n_atomes bigint, n_anr bigint, n_repris bigint, n_repli bigint,
               n_partagees bigint,
               geom geometry(MultiPolygon, 2154))
-- VOLATILE par contagion : elle appelle `carte_partition_atome`, qui crée des
-- tables temporaires. Une fonction n'est pas plus stable que ce qu'elle appelle.
LANGUAGE sql VOLATILE AS $$
    WITH pris AS (
        SELECT m.unit_id, m.niveau, c.atom_id, c.geom, c.source, a.fraction
        FROM   carte_partition_atome(p_date, p_dep) c
        JOIN   membership m ON m.atom_id = c.atom_id AND m.periode @> p_date
        JOIN   atom a ON a.atom_id = c.atom_id
        WHERE  m.niveau = p_niveau
    )
    SELECT u.unit_id, u.niveau, u.dep,
           coalesce(uv.nom, u.nom),
           count(*),
           count(*) FILTER (WHERE p.source = 'anr'),
           count(*) FILTER (WHERE p.source = 'reprise'),
           count(*) FILTER (WHERE p.source = 'repli'),
           count(*) FILTER (WHERE p.fraction),
           ST_Multi(ST_CollectionExtract(
               ST_UnaryUnion(ST_Collect(p.geom)), 3))
    FROM   pris p
    JOIN   unit u ON u.unit_id = p.unit_id AND u.niveau = p.niveau
    LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION carte_partition(date, text, text) IS
    'La carte dissoute, sans trou ni superposition hors fractions. Ex : SELECT unit_id, nom, geom FROM carte_partition(''1885-06-01'', ''canton'', ''01'');';

-- ---------------------------------------------------------------------------
-- § 7. La recette. Elle mesure LE COMPOSITE — c'est tout l'objet du fichier.
--
--      Le recouvrement se mesure entre atomes NON-FRACTION : les fractions
--      partagent le polygone de leur mère par construction et se recouvrent
--      exactement, ce qui est déclaré, pas subi.
-- ---------------------------------------------------------------------------
-- LA DATE PAR DÉFAUT EST LE 1ᵉʳ DÉCEMBRE, ET CE N'EST PAS UN DÉTAIL.
-- `cartes/export_web.py` observe l'année au 1ᵉʳ décembre (`MOIS_JOUR`), et
-- `sql/banc_84.py` en hérite. Cette recette a d'abord porté `1870-01-01` : ses
-- chiffres attendus, tirés du banc, décrivaient donc une carte observée onze
-- mois plus tard que celle qu'elle mesurait. Sur l'Aveyron l'écart s'est vu —
-- 19 reprises contre 18, 3 replis résiduels contre 1 — et rien dans la sortie
-- ne disait que les deux colonnes ne parlaient pas de la même date.
-- *Une colonne « attendu » qui ne partage pas la convention de ce qu'elle
-- compare est pire qu'une colonne vide : elle a l'air de valider.*
-- ET LA RECETTE PASSE PAR UNE TABLE, PAS PAR UNE CTE. Le premier jet lisait
-- `WITH c AS MATERIALIZED (SELECT * FROM carte_partition_atome(…))` puis
-- joignait `c` à `c` par `ST_Intersects`. Sur un département, imperceptible ;
-- sur la France, la fonction a fini ses 90 départements — les NOTICE le
-- disaient — puis n'a plus rendu la main.
--
-- **C'est exactement le piège que `82_anr_geom.sql` documente en toutes lettres
-- au § 7**, sous le titre « deux pièges de coût, payés en direct » : une CTE
-- matérialisée n'a pas d'index, et `ST_Intersects` a beau porter son `&&` en
-- lui, il n'a plus rien à consulter — PostgreSQL part sur 38 000 × 38 000
-- paires en boucle imbriquée. Je l'ai réécrit six mois après l'avoir lu.
--
-- *Un piège consigné dans le dépôt n'est pas un piège évité : il faut encore
-- que la relecture se fasse à l'endroit où il reparaît.*
--
-- D'où la table temporaire indexée ci-dessous, et le `ST_Intersection` calculé
-- une seule fois par paire — l'autre moitié du même § 7 de `82`.
CREATE FUNCTION check_partition(p_date date DEFAULT '1870-12-01',
                                p_dep text DEFAULT NULL)
RETURNS TABLE (controle text, valeur numeric, attendu text)
LANGUAGE plpgsql VOLATILE AS $$
#variable_conflict use_column
BEGIN
    -- `DISTINCT ON` : un atome rattaché à des unités de deux départements
    -- (voir `35_atomes_hors_departement.sql`) serait rendu par les deux passes
    -- de la boucle, et se recouvrirait lui-même de toute sa surface. Le
    -- recouvrement afficherait alors un chiffre énorme et parfaitement faux.
    DROP TABLE IF EXISTS t84_chk;
    CREATE TEMP TABLE t84_chk ON COMMIT DROP AS
    SELECT DISTINCT ON (c.atom_id)
           c.atom_id, c.geom, c.source, a.fraction,
           (SELECT min(u.dep)
              FROM membership m
              JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
             WHERE m.atom_id = c.atom_id AND m.periode @> p_date) AS dep
    FROM   carte_partition_atome(p_date, p_dep) c
    JOIN   atom a ON a.atom_id = c.atom_id
    ORDER  BY c.atom_id, c.source;

    CREATE INDEX ON t84_chk USING gist (geom);
    CREATE INDEX ON t84_chk (atom_id);
    ANALYZE t84_chk;

    RETURN QUERY
    SELECT 'atomes dessinés', count(*)::numeric,
           '38 331 à 1870, France entière ; 01 : 458 · 12 : 306 · 78 : 692'
    FROM   t84_chk
    UNION ALL
    SELECT 'dont repris par différence', count(*)::numeric,
           '01 : 7 · 12 : 19 · 78 : 7 · France 432 au banc'
    FROM   t84_chk WHERE source = 'reprise'
    UNION ALL
    SELECT 'dont repli GEOFLA résiduel', count(*)::numeric,
           '01 : 0 · 12 : 3 · 78 : 0 · France 111 au banc. Les nommer : § 8'
    FROM   t84_chk WHERE source = 'repli'
    UNION ALL
    SELECT 'recouvrement hors fraction, km²',
           round((coalesce(sum(s.aire) FILTER (WHERE s.meme_dep), 0)
                  / 1e6)::numeric, 3),
           '0,000 — c''est le contrôle du fichier'
    FROM  (SELECT ST_Area(ST_Intersection(a.geom, b.geom)) AS aire,
                  (a.dep IS NOT DISTINCT FROM b.dep) AS meme_dep
             FROM t84_chk a
             JOIN t84_chk b ON a.atom_id < b.atom_id
                           AND a.geom && b.geom
                           AND ST_Intersects(a.geom, b.geom)
            WHERE NOT a.fraction AND NOT b.fraction) s
    UNION ALL
    -- LA COUTURE ENTRE DÉPARTEMENTS EST UNE LIGNE À PART, ET IL FAUT LA LIRE.
    -- Le treillis est construit département par département : deux communes
    -- séparées par une limite départementale sont donc arbitrées DEUX FOIS,
    -- une fois dans chaque cadre. Les frontières nouées sont les mêmes, mais
    -- rien ne garantit qu'une lisière disputée tombe du même côté dans les
    -- deux passes, parce que les tiers présents dans le cadre diffèrent.
    -- Attendu : nul ou négligeable. Un chiffre qui monte dirait que
    -- l'assemblage national demande une passe de raccord, et il vaut mieux le
    -- voir sur sa propre ligne que noyé dans le total.
    SELECT 'dont couture entre départements, km²',
           round((coalesce(sum(s.aire) FILTER (WHERE NOT s.meme_dep), 0)
                  / 1e6)::numeric, 3),
           'nul ou négligeable ; sans objet sur un seul département'
    FROM  (SELECT ST_Area(ST_Intersection(a.geom, b.geom)) AS aire,
                  (a.dep IS NOT DISTINCT FROM b.dep) AS meme_dep
             FROM t84_chk a
             JOIN t84_chk b ON a.atom_id < b.atom_id
                           AND a.geom && b.geom
                           AND ST_Intersects(a.geom, b.geom)
            WHERE NOT a.fraction AND NOT b.fraction) s
    UNION ALL
    SELECT 'somme des aires hors fraction, km²',
           round((sum(ST_Area(geom)) / 1e6)::numeric, 0),
           'à comparer à l''emprise de snapshot_geom_anr à la même date'
    FROM   t84_chk WHERE NOT fraction
    UNION ALL
    SELECT 'géométries invalides', count(*)::numeric, '0'
    FROM   t84_chk WHERE NOT ST_IsValid(geom);
END $$;

COMMENT ON FUNCTION check_partition(date, text) IS
    'Recettes de 84_carte_partition.sql. Ex : SELECT * FROM check_partition(''1870-01-01'', ''01'');';

-- Une procédure, et pas une fonction : `check_partition` est en lecture seule
-- par construction, donc c'est ici — et seulement ici — que la mesure se pose
-- dans `p84_trace`. Un même couple (date, département) peut être journalisé
-- plusieurs fois : la table garde l'historique, elle ne le remplace pas.
CREATE PROCEDURE partition_journalise(p_date date DEFAULT '1870-01-01',
                                      p_dep text DEFAULT NULL)
LANGUAGE sql AS $$
    INSERT INTO p84_trace (p_date, dep, quoi, n, km2, note)
    SELECT p_date, p_dep, c.controle,
           CASE WHEN c.controle LIKE '%km²' THEN NULL ELSE c.valeur::bigint END,
           CASE WHEN c.controle LIKE '%km²' THEN c.valeur END,
           c.attendu
    FROM   check_partition(p_date, p_dep) c;
$$;

COMMENT ON PROCEDURE partition_journalise(date, text) IS
    'Pose les recettes de 84 dans p84_trace. Ex : CALL partition_journalise(''1870-01-01'', ''01'');';

-- ---------------------------------------------------------------------------
-- § 8. Ce qui reste ouvert, et qu'il ne faut pas croire réglé.
--
--   1. LES FRACTIONS. 333 atomes-fraction et les villes partagées gardent le
--      polygone de la commune entière. Le § 6 les compte dans `n_partagees` ;
--      la page les hachure. Rien ici ne prétend les découper.
--
--   2. LE REPLI RÉSIDUEL. Les atomes qu'ANR ne pourvoit à AUCUNE date — les
--      six doublons nommés au § 8 de `82` en tête — n'ont pas de reprise
--      possible et gardent leur polygone de 2011. Ils sont peu nombreux et
--      identifiés : `check_partition` les compte, et ils méritent d'être
--      nommés un par un plutôt que corrigés en bloc. Pour les nommer :
--
--        SELECT c.atom_id, a.insee_geofla, coalesce(n.nom, g.nom_comm) AS nom
--        FROM   carte_partition_atome('1870-12-01', '12') c
--        JOIN   atom a ON a.atom_id = c.atom_id
--        LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
--        LEFT   JOIN geofla_commune g ON g.insee_com = a.insee_geofla
--        WHERE  c.source = 'repli';
--
--   2 bis. LE COÛT. Le treillis se paie par département, jamais en bloc : voir
--      l'en-tête de `partition_un_dep`. Un appel national boucle sur les
--      départements et annonce chacun par un NOTICE ; c'est long, mais ça
--      finit. Pour suivre un chantier, préférer département par département —
--      `check_partition` accepte un `dep` en second argument.
--
--   3. LE COMBLEMENT EST UN ARBITRAGE, pas une mesure. 33 km² sur 23
--      départements à 1870, en 1 988 faces — 1,7 ha en moyenne, donc des
--      lisières et non du territoire. Mais si une exécution future voit ce
--      chiffre grossir, c'est le signe que le cadre est trop étroit (§ 3) ou
--      qu'une source manque, pas que la carte s'améliore.
--
--   4. CE FICHIER NE VALIDE PAS LE REPORT ARRIÈRE DE `11`. Il rend dessinable
--      ce que la base affirme ; il ne dit pas si elle a raison de faire vivre
--      Villieu en 1870. Cette question-là est celle de
--      `83_anr_ecart_couverture.sql`, et elle reste à jouer.
--
--   5. `export_web.py` NE LIT PAS ENCORE `84`. Tant qu'il tire
--      `coalesce(ga.geom, ag.geom)`, la carte web garde ses coutures. Le
--      branchement est une étape à part, pour que la trame nettoyée puisse
--      être comparée à l'ancienne avant de la remplacer.
-- ---------------------------------------------------------------------------

\echo ''
\echo '84_carte_partition.sql posé. Rien n''a été modifié : atom_geom,'
\echo 'atom_geom_anr et membership sont intacts. Éprouver dans cet ordre —'
\echo ''
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_partition(''1870-12-01'', ''01'');"'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_partition(''1870-12-01'', ''78'');"'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_partition(''1870-12-01'');"'
\echo ''
\echo 'La ligne « recouvrement hors fraction » doit valoir 0,000.'
\echo ''
\echo 'La passe nationale boucle sur les départements et annonce chacun par un'
\echo 'NOTICE. Elle dure des minutes ; si elle se taisait, ce serait un blocage.'
\echo ''
\echo 'Comparer ensuite à ce que la carte dessine aujourd''hui :'
\echo '  SELECT unit_id, nom, n_repli FROM histgis.snapshot_geom_anr(''1870-01-01'');'
\echo '  SELECT unit_id, nom, n_repris, n_repli FROM histgis.carte_partition(''1870-01-01'', ''canton'', ''01'');'
\echo ''

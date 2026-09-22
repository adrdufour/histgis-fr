-- ============================================================================
-- histgis — 82_anr_geom.sql : la trame communale historique entre en base
--
--   ogr2ogr -f PostgreSQL PG:"dbname=histgis" \
--       ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg geometries_only_processed \
--       -nln histgis.anr_commune -nlt MULTIPOLYGON \
--       -lco GEOMETRY_NAME=geom -lco FID=gid -a_srs EPSG:2154 -overwrite \
--       -lco SPATIAL_INDEX=NONE -lco UNLOGGED=YES \
--       --config PG_USE_COPY YES -gt 65536
--
--   550 Mo de géométrie, 34 millions de sommets : de dix minutes à une
--   demi-heure. `SPATIAL_INDEX=NONE` est le gros gain — ce fichier ne fait
--   AUCUN prédicat spatial sur `anr_commune`, il joint sur `id_com` et recopie
--   `geom`. Voir `sql/JOUER_82.md`.
--
--   psql -d histgis -1 -v variantes=build/anr_variantes.csv -f sql/82_anr_geom.sql
--
-- N'ÉCRIT PAS dans `membership`, ni dans `atom_geom`. Crée une table NOUVELLE,
-- `atom_geom_anr`, et une fonction de carte qui la préfère quand elle parle.
-- Tout est tracé dans `a82_trace` et le § 2 défait le passage précédent : le
-- fichier est rejouable seul, et se défait par un DROP.
--
-- CE QU'IL POSE, ET SUR QUELLE AUTORITÉ
-- =====================================
-- ANR-COMMUNES (Litvine / INED / Univ. Bourgogne, Zenodo 10.5281/zenodo.3727274)
-- reconstruit le polygone de chaque commune française année par année de 1790 à
-- 2020. Embargo levé le 1er septembre 2026.
--
-- Le pont n'a pas eu à être fabriqué : **`id_com` d'ANR EST l'identifiant
-- Cassini**, la clé que `atom.cassini` porte depuis le premier chargement.
-- 38 074 des 38 109 atomes non-fraction s'y retrouvent — 99,91 % — et 99,66 %
-- des noms concordent. C'est une jointure d'entiers, pas un appariement.
--
-- POURQUOI UNE TABLE DATÉE, ET PAS UN REMPLACEMENT D'`atom_geom`
-- ==============================================================
-- `atom_geom` donne UN polygone par atome, pour toujours : c'est la trame
-- GEOFLA 2011, qui n'a pas d'épaisseur temporelle. ANR en a une, et c'est
-- l'essentiel de ce qu'il apporte — une commune qui perd un hameau en 1875 a
-- deux polygones successifs. Écraser `atom_geom` jetterait cela.
--
-- `atom_geom_anr` porte donc une `periode`, et `snapshot_geom_anr(date)` choisit
-- à la date demandée. `atom_geom` reste intacte, et sert de repli (R5).
-- C'est le découplage annoncé dans ETAT.md : la géométrie bouge dans le temps
-- sans qu'un seul rattachement soit touché.
--
-- LES CINQ RÈGLES, ET CE QU'ELLES ONT COÛTÉ
-- =========================================
-- Aucune n'arbitre une frontière. Toutes se vérifient par un décompte.
--
-- R1  INTERVALLE SEMI-OUVERT [StartDt, EndDt).
--     ANR écrit la fin d'un polygone et le début du suivant sur la MÊME année :
--     Eaux-Bonnes est 1790-1861 puis 1861-2020. Tout test `Start <= a <= End`
--     compte donc deux fois toute commune dont l'édition tombe pile sur
--     l'année interrogée — 26 cas à 1870, 4 à 1940. Ce n'est pas un conflit de
--     territoire, c'est une convention d'intervalle, et elle épouse celle du
--     28 août : sur [signature, effet) c'est l'ancienne composition qui vaut.
--     COÛT MESURÉ : **zéro atome perdu**, à 1870 comme à 1940. C'était la seule
--     chose à vérifier — une règle d'intervalle qui gagne sur le recouvrement
--     en perdant des communes n'aurait fait que déplacer le problème.
--     Effet de bord à connaître : le dernier polygone d'une commune s'arrête au
--     31 décembre 2019, `EndDt` valant 2020. Sans conséquence sur 1870-1940.
--
-- R2  DÉDOUBLONNAGE EXACT sur (Poly_ID, empreinte de la géométrie, FENÊTRE).
--     66 lignes strictement identiques dans tout le jeu. Rien à arbitrer.
--
--     La fenêtre fait partie de la clé, et le banc a montré pourquoi. Sans
--     elle, 69 lignes tombaient au lieu de 66 : trois `Poly_ID` portent DEUX
--     FOIS la même géométrie sur deux fenêtres SUCCESSIVES — la commune a été
--     éditée à une date où sa forme n'a pas bougé. Les confondre coûtait deux
--     atomes à 1870 et deux à 1940, silencieusement. *Un dédoublonnage qui
--     oublie une dimension de la clé ne déduplique pas, il tronque.*
--
-- R3  VARIANTES d'un même (id_com, fenêtre) — 58 groupes, 126 polygones sur
--     tout 1790-2020. Arbitrées HORS SQL, par `anr_variantes_verdict.py`, et
--     le verdict entre ici par `build/anr_variantes.csv` : chaque ligne porte
--     la part de sa surface revendiquée par une commune TIERCE, et le motif.
--     Règle : **retenir la moins revendiquée ; à égalité, la plus grande.**
--
--     Le premier jet écartait les variantes au-dessus de 50 % et gardait la
--     plus grande des autres. Il donnait à PARIS, sur 1790-1859, sa variante de
--     66,3 km² — revendiquée à 48,6 %, sous le seuil d'un cheveu — c'est-à-dire
--     Paris après l'annexion de 1860, reporté jusqu'en 1790, avalant la moitié
--     de Vaugirard, Clichy et Auteuil. **Le seuil décidait à la place du
--     lecteur**, cinquième fois dans ce dépôt. La règle sans seuil retient la
--     variante 0H, 34,1 km², revendiquée par personne : le Paris d'avant 1860.
--     Le seuil ne sert plus qu'à l'ABSTENTION.
--
-- R4  (absorbée par R3.) BEAUVAIS, `id_com` 3332 : ses deux polygones d'avant
--     1943 sont revendiqués à 100 % par Notre-Dame-du-Thil, qui possède par
--     ailleurs son propre `id_com` 12335. Il n'y a pas deux versions de
--     Beauvais — ANR a rangé sous Beauvais un morceau de la commune qu'elle
--     absorbera, et le vrai Beauvais d'avant 1943 est ABSENT du jeu. Deux
--     autres cas de la même famille : Flipou et Senneville, dont ANR a croisé
--     les deux polygones. Ces trois groupes sont en abstention.
--
-- R5  REPLI. Un atome que ce fichier ne pourvoit pas garde sa géométrie
--     actuelle : `snapshot_geom_anr()` retombe sur `atom_geom`. La trame est
--     hybride, et les colonnes `n_anr` / `n_repli` le disent à chaque ligne.
--
--     COMBIEN D'ATOMES ? La réponse dépend de la base qu'on interroge, et il
--     faut le dire une fois pour toutes. Sur les seuls CSV de `build/`, 40 à
--     1870 dont 20 Paris. **Sur la base réelle, 486** — parce que `11`, `15`,
--     `41`, `44` et `46` y ont ajouté des atomes et prolongé des rattachements
--     vers l'arrière depuis l'extraction.
--
--     Et l'écart n'est pas un défaut d'ANR : ce sont, pour l'essentiel, des
--     communes que **notre base fait vivre en 1870 et qu'ANR ne fait naître que
--     plus tard**. `11_scission.sql` les y a portées sur le pari qu'une commune
--     nouvelle reste dans le canton de sa mère — sa trace porte la colonne
--     `debut_reel` qui l'avoue. Là où ANR refuse un polygone, il refuse de
--     suivre notre report. `83_anr_ecart_couverture.sql` décompose les 486 et
--     mesure, source indépendante à l'appui, la part de notre couverture de
--     1870 qui relève de l'inférence et non de l'attestation.
--
-- CE QUE CE FICHIER NE FAIT PAS, ET IL FAUT LE LIRE
-- =================================================
-- 1. **Les atomes-fractions n'y entrent pas.** Une commune partagée entre deux
--    cantons donne deux atomes-fractions ; ANR livre le polygone de la commune
--    MÈRE entière et ne sait pas le découper. Les leur donner recréerait
--    exactement le double comptage qu'on vient de retirer. Les 333 fractions
--    gardent donc `atom_geom`, avec sa limite connue. L'espoir consigné le
--    9 août — « ANR résoudra les 333 fractions » — est déçu.
-- 2. **La Corse est un instantané.** 360 polygones justes au km² près
--    (8 754 contre 8 753 attendus au facteur Lambert-93), mais ZÉRO édition
--    historique, contre 27,1 % pour la France entière : ANR projette la trame
--    moderne jusqu'en 1790. Sans effet sur 1870-1940, où aucun mouvement corse
--    n'est attesté chez nous — mais à porter en légende. C'est le défaut que ce
--    dépôt a déjà nommé chez lui : *un instantané projeté n'est pas une
--    chronologie.*
-- 3. **101,0 km² de recouvrement subsistent**, contre 3 945 aujourd'hui, et ils
--    sont nommés : 93,6 pour Notre-Dame-de-Briançon, à qui ANR donne le
--    polygone de la future La Léchère tout en accordant le leur à Naves, Doucy,
--    Celliers, Pussy, Petit-Cœur et Les Avanchers ; 6,9 pour Tours face à
--    Joué-lès-Tours, Saint-Avertin et Saint-Pierre-des-Corps. **Deux communes
--    font 99,4 % du reste.** Corriger par soustraction du parent laisse 19 et
--    14 éclats : écarté. On déclare.
--
-- CE QUE LA CONFRONTATION A APPRIS SUR NOTRE PROPRE BASE
-- ======================================================
-- Des atomes que ce fichier ne pourvoit pas ne sont pas des trous d'ANR : ce
-- sont des DOUBLONS chez nous — deux atomes pour un même code INSEE, le poids
-- mort de la route `successeur` (limite 7 de METHODE.md) — et **ANR nomme le
-- survivant**. Le § 8 en liste **six**, ceux qu'ANR ne pourvoit à AUCUNE date :
-- Sebrazac, Venaco, L'Aubépin, Fonteny, Saint-Hubert, La Salvetat-Belmontet.
--
-- Trois autres — Sébazac-Concourès, Goutrens, Roches-Prémarie-Andillé — sont du
-- même tonneau mais n'y figurent pas : ANR leur donne un polygone sur une
-- fenêtre ANTÉRIEURE à 1870 (elle s'arrête en 1820, 1844, 1819), si bien qu'ils
-- sont pourvus quelque part et manquent seulement à la date qui nous intéresse.
-- **Le § 8 répond à « jamais pourvu », pas à « pourvu à cette date »** : deux
-- questions voisines et deux réponses différentes, 6 et 9.
--
-- Leur suppression est une décision séparée, qui n'est pas prise ici.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?variantes}
\else
    \set variantes 'build/anr_variantes.csv'
\endif

-- ---------------------------------------------------------------------------
-- § 1. Garde-fous. Rien ne commence sans eux.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.anr_commune') IS NULL THEN
        RAISE EXCEPTION
          'Table histgis.anr_commune absente : charger la couche geometries_only_processed du GeoPackage ANR avec ogr2ogr (voir l''en-tête).';
    END IF;
    IF to_regclass('histgis.atom') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : la base n''est pas chargée (table atom absente).';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'btree_gist') THEN
        RAISE EXCEPTION 'PRÉREQUIS : extension btree_gist (la contrainte EXCLUDE du § 4 en dépend).';
    END IF;
    IF to_regclass('histgis.atom_geom_source') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/07_reliquat.sql AVANT celui-ci (le § 5 déclare sa source dans atom_geom_source).';
    END IF;
    -- La couche « with_pseudo_territories » n'a rien à faire ici : sur
    -- 1870-1940 elle n'apporte que 2 à 4 atomes et en compte 267 de MOINS.
    IF EXISTS (SELECT 1 FROM anr_commune WHERE poly_id IS NULL) THEN
        RAISE EXCEPTION 'anr_commune : colonne poly_id absente ou vide — mauvaise couche chargée ?';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 2. Rejouabilité. Ce fichier ne touche à rien d'autre que ses propres
--      tables : les défaire suffit à défaire son passage.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS snapshot_geom_anr(date, text);
DROP FUNCTION IF EXISTS check_geom_anr(date);
DROP FUNCTION IF EXISTS check_geom_anr();
DROP TABLE IF EXISTS atom_geom_anr;
DROP TABLE IF EXISTS anr_variante;
DROP TABLE IF EXISTS a82_trace;

CREATE TABLE a82_trace (
    quoi text NOT NULL,
    n    bigint,
    note text,
    pose timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- § 3. R3 : le verdict des variantes, calculé hors SQL et importé tel quel.
--
--      Le calcul demande de mesurer, pour chaque variante, la part de sa
--      surface que revendique une commune TIERCE valide sur la même fenêtre.
--      C'est une mesure de voisinage, pas une règle : elle est faite par
--      `sorties/anr/anr_variantes_verdict.py`, elle est relisible ligne à
--      ligne, et elle entre ici comme une donnée.
-- ---------------------------------------------------------------------------
CREATE TABLE anr_variante (
    id_com          integer NOT NULL,
    nom             text,
    poly_id         text PRIMARY KEY,
    an_debut        integer NOT NULL,
    an_fin          integer NOT NULL,
    km2             numeric,
    pct_revendique  numeric,
    revendique_par  text,
    verdict         text NOT NULL
);

\set cmd '\\copy anr_variante FROM ' :'variantes' ' WITH (FORMAT csv, HEADER true)'
:cmd

INSERT INTO a82_trace (quoi, n, note)
SELECT 'variantes lues', count(*),
       count(*) FILTER (WHERE verdict = 'retenu') || ' retenues, '
    || count(*) FILTER (WHERE verdict = 'ecarte : aucune variante libre') || ' en abstention'
FROM anr_variante;

-- ---------------------------------------------------------------------------
-- § 4. `atom_geom_anr` — un polygone par (atome, période), et la contrainte
--      qui interdit structurellement d'en avoir deux.
--
--      `EXCLUDE (atom_id WITH =, periode WITH &&)` n'est pas une recette : une
--      recette se lit après coup, une contrainte refuse l'écriture. C'est elle
--      qui garantit ce que la mesure du 1er septembre avait constaté à la main
--      — un polygone par id_com, 37 624 pour 37 624 (dont 37 618 rejoignent
--      un atome non-fraction : six id_com d'ANR n'en ont aucun chez nous).
-- ---------------------------------------------------------------------------
CREATE TABLE atom_geom_anr (
    atom_id  text        NOT NULL REFERENCES atom(atom_id) ON DELETE CASCADE,
    periode  daterange   NOT NULL,
    geom     geometry(MultiPolygon, 2154) NOT NULL,
    poly_id  text        NOT NULL,
    pseudo_t boolean     NOT NULL DEFAULT false,
    source   text        NOT NULL DEFAULT 'anr',
    EXCLUDE USING gist (atom_id WITH =, periode WITH &&)
);

WITH brut AS (
    SELECT an.id_com::text                          AS id_com,
           an.poly_id,
           (nullif(an.startdt::text, ''))::numeric::int AS an_debut,
           (nullif(an.enddt::text,   ''))::numeric::int AS an_fin,
           coalesce(an.pseudo_t::boolean, false)     AS pseudo_t,
           ST_Multi(an.geom)                         AS geom
    FROM   anr_commune an
    WHERE  an.geom IS NOT NULL
), bornes AS (                       -- R1 : fenêtre non vide, semi-ouverte
    SELECT * FROM brut
    WHERE  an_debut IS NOT NULL AND an_fin IS NOT NULL AND an_fin > an_debut
), arbitre AS (                      -- R3 : les variantes écartées sortent ici
    SELECT b.*
    FROM   bornes b
    LEFT   JOIN anr_variante v ON v.poly_id = b.poly_id
    WHERE  v.poly_id IS NULL OR v.verdict = 'retenu'
), unique_poly AS (                  -- R2 : doublons exacts, FENÊTRE COMPRISE
    SELECT DISTINCT ON (poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin) *
    FROM   arbitre
    ORDER  BY poly_id, md5(ST_AsBinary(geom)), an_debut, an_fin
)
INSERT INTO atom_geom_anr (atom_id, periode, geom, poly_id, pseudo_t)
SELECT a.atom_id,
       daterange(make_date(u.an_debut, 1, 1), make_date(u.an_fin, 1, 1), '[)'),
       u.geom,
       u.poly_id,
       u.pseudo_t
FROM   unique_poly u
JOIN   atom a ON a.cassini = u.id_com
WHERE  NOT a.fraction;               -- ANR ne sait pas découper une fraction

CREATE INDEX atom_geom_anr_geom_idx ON atom_geom_anr USING gist (geom);
CREATE INDEX atom_geom_anr_atom_idx ON atom_geom_anr (atom_id);
ANALYZE atom_geom_anr;

INSERT INTO a82_trace (quoi, n, note)
SELECT 'polygones posés', count(*), count(DISTINCT atom_id) || ' atomes pourvus'
FROM   atom_geom_anr;

-- ---------------------------------------------------------------------------
-- § 5. Déclarer la source, pour que `atom_geom_source` reste le registre.
-- ---------------------------------------------------------------------------
INSERT INTO atom_geom_source (source, pose_par, note) VALUES
    ('anr', '82_anr_geom.sql',
     'ANR-COMMUNES 22042026, couche only_processed, sous R1-R3 ; géométrie datée dans atom_geom_anr')
ON CONFLICT (source) DO NOTHING;

-- ---------------------------------------------------------------------------
-- § 6. `snapshot_geom_anr(date, niveau)` — la carte, avec la trame historique.
--
--      Même signature que `snapshot_geom()`, deux colonnes en plus :
--      `n_anr` dit combien d'atomes de l'unité tiennent leur polygone d'ANR, et
--      `n_repli` combien retombent sur `atom_geom` (R5). Une unité dont
--      `n_repli` est grand n'est pas fausse, elle est moins bien datée — et il
--      faut pouvoir le lire sans relire ce fichier.
-- ---------------------------------------------------------------------------
CREATE FUNCTION snapshot_geom_anr(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (
    unit_id     text,
    niveau      text,
    dep         char(2),
    nom         text,
    n_atomes    bigint,
    n_anr       bigint,
    n_repli     bigint,
    n_sans_geom bigint,
    geom        geometry(MultiPolygon, 2154)
)
LANGUAGE sql STABLE AS $$
    WITH pris AS (
        SELECT m.unit_id, m.niveau, m.atom_id,
               coalesce(ga.geom, ag.geom)              AS geom,
               (ga.atom_id IS NOT NULL)                AS vient_d_anr,
               (ga.atom_id IS NULL AND ag.atom_id IS NOT NULL) AS repli
        FROM   membership m
        LEFT   JOIN atom_geom_anr ga
               ON ga.atom_id = m.atom_id AND ga.periode @> p_date
        LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
        WHERE  m.niveau = p_niveau
          AND  m.periode @> p_date
    )
    SELECT u.unit_id, u.niveau, u.dep,
           coalesce(uv.nom, u.nom),
           count(*),
           count(*) FILTER (WHERE p.vient_d_anr),
           count(*) FILTER (WHERE p.repli),
           count(*) FILTER (WHERE p.geom IS NULL),
           ST_Multi(ST_UnaryUnion(ST_Collect(p.geom)))
    FROM   pris p
    JOIN   unit u ON u.unit_id = p.unit_id AND u.niveau = p.niveau
    LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION snapshot_geom_anr(date, text) IS
    'Carte dissoute à une date, trame ANR quand elle parle, atom_geom en repli. Ex : SELECT unit_id, nom, n_repli, geom FROM snapshot_geom_anr(''1885-06-01'');';

-- ---------------------------------------------------------------------------
-- § 7. Les recettes. Chiffres attendus au 1er septembre 2026, mesurés hors base
--      avant écriture :
--
--        recouvrement à 1870 et à 1940 ......... 101,0 km², 11 paires
--        dont deux atomes d'un même id_com .....   0,0 km²   (contrainte § 4)
--        somme des aires ....................... 548 496 km² projetés
--        emprise nette (somme − recouvrement) .. 548 395 km²
--        étalon GEOFLA 2014, même projection ... 548 489 km²  (-0,02 %)
--
--      La trame ANR entière fait 548 932 km² ; les 548 496 sont ce qui reste une
--      fois retirés les six `id_com` qu'aucun atome non-fraction ne réclame chez
--      nous (436 km²).
--
--      Un écart sur ces lignes ne veut pas dire que la base est fausse : il veut
--      dire que ce fichier ne fait plus ce que son en-tête raconte.
--
-- DEUX PIÈGES DE COÛT, PAYÉS EN DIRECT
-- ====================================
-- La première écriture de ces recettes lisait une CTE — `WITH v AS (SELECT …
-- WHERE periode @> p_date)` — puis joignait `v` à `v` par `ST_Intersects`.
-- Élégant, et **inexécutable** : une CTE référencée plusieurs fois est
-- MATÉRIALISÉE, donc dépourvue d'index. `ST_Intersects` est pourtant
-- index-conscient — il porte son `&&` en lui —, mais il n'y avait plus d'index
-- à consulter. PostgreSQL partait sur 37 618 × 37 618 paires en boucle
-- imbriquée. Le fichier ne s'est pas trompé de résultat : il ne rendait pas la
-- main.
--
-- Le second piège était dans la même requête : `ST_Intersection` calculé DEUX
-- fois par paire, au `WHERE` puis au `sum`. D'où la sous-requête ci-dessous.
--
-- Et l'emprise passait par `ST_UnaryUnion(ST_Collect(geom))` sur 37 618
-- multipolygones — l'opération qui avait déjà fait tomber le script Python par
-- épuisement mémoire le matin même. Elle est remplacée par la somme des aires,
-- dont on retranche le recouvrement : **même nombre, et il tient dans une
-- ligne.** Une union géométrique n'est pas nécessaire pour connaître une
-- surface quand on sait déjà ce qui se recouvre.
--
-- ***Une recette qu'on ne peut pas attendre ne contrôle rien.*** Le banc ne
-- pouvait pas trouver ces trois-là : sans postgis, `ST_Intersects` y renvoie
-- `false` et le coût réel est invisible.
-- ---------------------------------------------------------------------------

-- L'index qui rend la recette possible. La contrainte EXCLUDE en pose déjà un
-- sur (atom_id, periode) ; celui-ci sert le filtre par date seul.
CREATE INDEX atom_geom_anr_periode_idx ON atom_geom_anr USING gist (periode);
ANALYZE atom_geom_anr;

-- `SET search_path` porté par la fonction elle-même, ajouté le 22 septembre
-- 2026 : appelée par `psql -c "SELECT * FROM histgis.check_...()"`, elle
-- s'exécutait avec le search_path de la SESSION, et ses appels non qualifiés
-- ne résolvaient que sur `histgis`, où le chemin avait été posé à la main
-- une fois, hors de tout script. Sur `histgis_essai` : « function ... does
-- not exist ». Une recette ne doit pas dépendre du réglage de qui la lance.
CREATE FUNCTION check_geom_anr(p_date date DEFAULT '1870-01-01')
RETURNS TABLE (controle text, valeur numeric, attendu text)
LANGUAGE sql STABLE
SET search_path = histgis, public
AS $$
    SELECT 'atomes pourvus par ANR', count(*)::numeric, '37 618 à 1870, 38 006 à 1940'
    FROM   atom_geom_anr WHERE periode @> p_date
    UNION ALL
    SELECT 'atomes non-fraction sans polygone ANR', count(*)::numeric,
           '533 à 1870 et 145 à 1940 en base ; 491 et 103 sur les seuls CSV de build/'
    FROM   atom a
    WHERE  NOT a.fraction
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                       WHERE g.atom_id = a.atom_id AND g.periode @> p_date)
    UNION ALL
    SELECT 'dont vivants à cette date', count(*)::numeric,
           '486 à 1870 en base — presque tous du report arrière de 11 ; voir 83'
    FROM   atom a
    WHERE  NOT a.fraction
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                       WHERE g.atom_id = a.atom_id AND g.periode @> p_date)
      AND  EXISTS (SELECT 1 FROM membership m
                   WHERE m.atom_id = a.atom_id AND m.periode @> p_date)
    UNION ALL
    SELECT 'somme des aires, km² projetés',
           round((sum(ST_Area(geom)) / 1e6)::numeric, 0),
           '548 496 ; étalon GEOFLA 2014 = 548 489'
    FROM   atom_geom_anr WHERE periode @> p_date
    UNION ALL
    -- Le contrôle. La jointure porte sur la TABLE, pas sur une CTE : `&&`
    -- consulte l'index gist, et `ST_Intersection` n'est calculé qu'une fois.
    SELECT 'recouvrement entre polygones, km²',
           round((coalesce(sum(aire), 0) / 1e6)::numeric, 1),
           '101,0 — Notre-Dame-de-Briançon 93,6 et Tours 6,9 en font 99,4 %'
    FROM   (SELECT ST_Area(ST_Intersection(a.geom, b.geom)) AS aire
            FROM   atom_geom_anr a
            JOIN   atom_geom_anr b
                   ON  a.atom_id < b.atom_id
                   AND a.geom && b.geom
                   AND ST_Intersects(a.geom, b.geom)
            WHERE  a.periode @> p_date AND b.periode @> p_date) s
    WHERE  s.aire > 1.0
    UNION ALL
    SELECT 'géométries invalides', count(*)::numeric, '0'
    FROM   atom_geom_anr WHERE periode @> p_date AND NOT ST_IsValid(geom);
$$;

COMMENT ON FUNCTION check_geom_anr(date) IS
    'Recettes de 82_anr_geom.sql. Ex : SELECT * FROM check_geom_anr(''1940-01-01'');';

-- ---------------------------------------------------------------------------
-- § 8. Ce que la confrontation dit de NOTRE base : les atomes doublons dont
--      ANR nomme le survivant. Lecture seule — supprimer un atome est une
--      décision qui ne se prend pas dans un fichier de chargement.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS a82_doublon;
CREATE TABLE a82_doublon AS
SELECT a.atom_id       AS atom_orphelin,
       a.cassini       AS cassini_orphelin,
       a.insee_geofla  AS insee,
       j.atom_id       AS atom_retenu_par_anr,
       j.cassini       AS cassini_retenu_par_anr
FROM   atom a
JOIN   atom j ON j.insee_geofla = a.insee_geofla
              AND j.atom_id <> a.atom_id
              AND NOT j.fraction
WHERE  NOT a.fraction
  AND  a.insee_geofla IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g WHERE g.atom_id = a.atom_id)
  AND  EXISTS     (SELECT 1 FROM atom_geom_anr g WHERE g.atom_id = j.atom_id);

INSERT INTO a82_trace (quoi, n, note)
SELECT 'atomes doublons tranchés par ANR', count(*),
       'lecture seule ; leur suppression est une décision séparée'
FROM   a82_doublon;

-- ---------------------------------------------------------------------------
-- § 9. Rapport de passage — TOUT CE QUI EST BON MARCHÉ, ET RIEN D'AUTRE.
--
--      Les recettes ne sont PAS appelées ici, et c'est délibéré. Ce fichier se
--      joue en une transaction (`psql -1`) : y faire tourner un contrôle de
--      plusieurs minutes, c'est tenir la transaction ouverte pendant tout ce
--      temps et n'avoir, si l'on s'impatiente, qu'un `ROLLBACK` pour solde.
--
--      La recette se lit APRÈS le `COMMIT`, sur des données acquises, où
--      l'interrompre ne coûte rien :
--
--        psql -d histgis -c "SELECT * FROM histgis.check_geom_anr('1870-01-01');"
--
--      *Un contrôle long n'a rien à faire dans la transaction qu'il contrôle.*
-- ---------------------------------------------------------------------------
SELECT quoi, n, note FROM a82_trace ORDER BY pose, quoi;

\echo ''
\echo '--- atomes doublons dont ANR nomme le survivant ---'
SELECT * FROM a82_doublon ORDER BY insee;

\echo ''
\echo '=== chargé. Les recettes se lisent maintenant, hors transaction :'
\echo '    psql -d histgis -c "SELECT * FROM histgis.check_geom_anr(''1870-01-01'');"'
\echo '    psql -d histgis -c "SELECT * FROM histgis.check_geom_anr(''1940-01-01'');"'
\echo '    (la ligne « recouvrement » demande une à trois minutes ; elle doit valoir 101,0)'

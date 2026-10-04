-- ============================================================================
-- histgis — 98_coupe_ville.sql : les villes multicantonales, découpées par
--                                leurs lignes, pas par leurs polygones
--
--   psql -d histgis -f sql/98_coupe_ville.sql                 (à blanc)
--   psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql
--
-- ÉCRIT `coupe_ville`, `coupe_ville_ancre` et deux fonctions. Tout est tracé
-- dans `p98_trace` ; le passage précédent est défait avant d'écrire.
--
-- LA VÉRITÉ EST DANS DEUX CSV VERSIONNÉS, PAS DANS LA BASE
-- ========================================================
--   cartes/coupes_ville.csv          les lignes de coupe, en WKT Lambert 93
--   cartes/coupes_ville_ancres.csv   un point par fraction, qui dit laquelle
--
-- C'est du travail À LA MAIN — le plus cher du projet, 214 coupes. Le mettre
-- dans la base seule serait le perdre au prochain `rebuild.sh`, comme
-- `iris_ville` l'a été sans que rien ne le signale. Les CSV restent auprès de
-- leur script et dans git ; ce fichier ne fait que les charger.
--
-- POURQUOI DES LIGNES, ET PAS DES POLYGONES — décidé le 23 septembre 2026
-- =======================================================================
-- La trame d'accrochage est CONTOURS-IRIS (`iris_ville`, 4 219 IRIS, les 119
-- villes servies). Son union ne coïncide pas avec le polygone communal, et
-- l'écart dépend entièrement de la trame à laquelle on la confronte :
--
--                          | GEOFLA 2011  | ANR (`atom_geom_anr`)
--   recouvrement moyen     |     95,7 %   |      99,9 %
--   pire ville             |     89,1 %   |      99,2 %
--   largeur de lisière     |     110 m    |       24 m
--   médiane / max (GEOFLA) |  80 m / 2 494 m
--
-- 24 m, c'est la maille de quantification de l'export web (`--grille 25`) :
-- à la résolution où le projet publie, IRIS et ANR sont confondus. L'écart à
-- GEOFLA, lui, va dans les deux sens — 175 km² d'atome hors IRIS, 208 km²
-- d'IRIS hors atome — et ANR couvre les 119 villes, en 223 polygones datés.
-- Depuis `82` la carte dessine `coalesce(anr @ date, geofla)` : pour ces
-- villes, elle dessine donc déjà ANR.
--
-- Découper sur GEOFLA aurait inscrit une décision arbitraire de 80 à 110 m sur
-- tout le pourtour de 119 villes, sur une trame que la carte n'utilise pas
-- pour elles. Remplacer la géométrie communale par les IRIS aurait déplacé le
-- référentiel de 119 communes pendant que leurs 36 500 voisines restent sur
-- GEOFLA : les 383 km² d'écart seraient devenus des trous francs le long de
-- chaque limite partagée. C'est le premier piège du `LISEZMOI.md` appliqué à
-- soi-même.
--
-- Ce fichier ne stocke donc AUCUN polygone. Il stocke la ligne, et
-- `carte_coupe_ville()` découpe au tirage le polygone courant, à la date
-- demandée — comme `84` recalcule la partition à chaque année géométrique au
-- lieu de la figer. *Une ligne survit à un changement de trame ; un polygone
-- de fraction en meurt.*
--
-- LE RACCORD, ET POURQUOI CE N'EST PAS UN PROLONGEMENT
-- ====================================================
-- Une ligne tirée des IRIS s'arrête là où les IRIS s'arrêtent : à quelques
-- dizaines de mètres du bord communal. Tant qu'elle n'atteint pas le bord aux
-- DEUX bouts, le découpage ne se ferme pas et `ST_Polygonize` rend la commune
-- entière — sans erreur, sans avertissement, un seul morceau.
--
-- Premier essai, le 23 septembre : prolonger chaque bout de 300 m dans l'axe
-- de son dernier segment. Sur Vienne, le bout nord est resté DEDANS — 48,8 m
-- du bord à vol d'oiseau, mais l'axe du dernier segment ne pointe pas vers le
-- bord le plus proche. Un prolongement plus long serait sorti par le mauvais
-- côté.
--
-- `raccorde_ligne()` joint donc chaque bout au POINT LE PLUS PROCHE du bord.
-- Sur Vienne : 48,8 m et 11,7 m, très en dessous des 110 m de lisière que les
-- deux trames se disputent de toute façon. Ce n'est pas du dessin, c'est un
-- raccord sous le bruit.
--
-- LA RECETTE, ET CE QU'ELLE INTERDIT
-- ==================================
-- Pour chaque ville, après découpe : autant de morceaux que de fractions,
-- chaque morceau contenant exactement UNE ancre, et la somme des aires égale
-- à l'aire de la cible. Une ligne qui ne ferme pas se voit là, et nulle part
-- ailleurs — le code de retour, lui, vaut zéro dans les deux cas.
--
-- CE QUE CE FICHIER NE FAIT PAS
-- =============================
--   * il ne décide pas QUEL morceau revient à QUEL canton : c'est l'ancre qui
--     le dit, et l'ancre est posée à la main, sur lecture du texte. La
--     géométrie ne sait pas lire un décret.
--   * il ne traite pas les trois villes sans ligne interne — Confolens
--     (16106), Tartas (40313), Le Quesnoy (59481), un seul IRIS chacune.
--   * il ne date pas encore les lignes par période géométrique. Une ville à
--     11 états ANR peut demander une ligne par état ; `coupe_ville.periode`
--     est là pour ça, la recette dira quand ça devient nécessaire.
--
-- DEPUIS LE 3 OCTOBRE 2026, LES QUARTIERS DE PARIS coupés entre deux
-- circonscriptions passent par ici : clé `PQnn`, niveau `circo`, fractions
-- posées par `101_paris_fractions_quartier.sql` — voir `coupe_cle()` au § 4.
--
-- ÉTAT AU 23 SEPTEMBRE 2026 : une seule ville chargée, Vienne (38544), et sa
-- ligne est un BANC D'ESSAI — la limite entre les grands quartiers INSEE 3-4
-- et 1-2. Elle sépare bien un nord d'un sud, ce que les noms des deux cantons
-- attestent, mais son tracé exact n'est établi par aucun texte. Elle est là
-- pour éprouver la mécanique, et `source = 'banc'` la désigne. **Ne pas la
-- prendre pour un résultat.**
--
-- Prérequis : `05` (atom_geom), `82` (atom_geom_anr), et `iris_ville` chargée
-- par `cartes/recupere_iris.py --charger`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' 98 — les villes multicantonales, découpées par leurs lignes'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.atom_geom_anr') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/82_anr_geom.sql.';
    END IF;
    IF to_regclass('histgis.iris_ville') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : iris_ville absente — '
            'python3 cartes/recupere_iris.py --charger, '
            'ou recharger depuis cartes/sorties/iris_villes.geojson.';
    END IF;
END $$;

\if :{?appliquer}

-- ---------------------------------------------------------------------------
-- 1. Les tables AVANT le défaisage : au premier passage il n'y a rien à
--    défaire, mais le défaisage lirait quand même des tables absentes.
--    `IF NOT EXISTS` — leur contenu vient des CSV, leur existence ne doit pas
--    dépendre d'un rejeu réussi.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS coupe_ville (
    coupe_id   text PRIMARY KEY,
    insee      char(5) NOT NULL,
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    periode    daterange GENERATED ALWAYS AS
               (daterange(valid_from, valid_to, '[)')) STORED,
    source     text NOT NULL,     -- 'banc' | 'iris' | 'main' | 'texte'
    note       text,
    geom       geometry(LineString, 2154) NOT NULL
);
CREATE INDEX IF NOT EXISTS coupe_ville_insee_idx ON coupe_ville (insee);

-- Une ancre par fraction : le point qui dit à quel atome revient le morceau
-- qui le contient. Un point plutôt qu'un « côté gauche / côté droit », qui
-- dépendrait du sens de parcours de la ligne et se retournerait en silence.
CREATE TABLE IF NOT EXISTS coupe_ville_ancre (
    atom_id text NOT NULL REFERENCES atom(atom_id) ON DELETE CASCADE,
    note    text,
    geom    geometry(Point, 2154) NOT NULL
);
-- PLUSIEURS ANCRES PAR FRACTION — 25 septembre 2026, sur Lisieux. Le 1er
-- canton y tient deux morceaux disjoints de la ville (« partie nord », « partie
-- sud » chez Gaudillère) : une ancre dans chacun. L'unicité d'`atom_id` d'abord
-- posée l'interdisait ; `carte_coupe_ville()` réunit les morceaux d'une même
-- fraction.
ALTER TABLE coupe_ville_ancre DROP CONSTRAINT IF EXISTS coupe_ville_ancre_pkey;
CREATE INDEX IF NOT EXISTS coupe_ville_ancre_atom_idx ON coupe_ville_ancre (atom_id);
-- DES ANCRES DATÉES — Lille, 27 septembre 2026. Les cinq cantons de 1870 y
-- retrouvent leur numéro en 1889 avec d'autres limites : le Centre de 1858 est au
-- nord de la vieille ville, celui de 1889 est taillé dans l'ancien Sud-Ouest. Une
-- ancre sans date vaut toujours (toutes les villes d'avant) ; une ancre datée ne
-- joue que sur [valid_from, valid_to).
ALTER TABLE coupe_ville_ancre ADD COLUMN IF NOT EXISTS valid_from date;
ALTER TABLE coupe_ville_ancre ADD COLUMN IF NOT EXISTS valid_to date;

-- ---------------------------------------------------------------------------
-- 2. Défaire le passage précédent, dans l'ordre inverse de la pose
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p98_trace (
    quoi text NOT NULL,           -- 'ligne' | 'ancre'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM coupe_ville_ancre a USING p98_trace t
 WHERE t.quoi = 'ancre' AND t.cle = a.atom_id;
DELETE FROM coupe_ville c USING p98_trace t
 WHERE t.quoi = 'ligne' AND t.cle = c.coupe_id;

-- `quoi IN (…)` et non `DELETE FROM p98_trace` : on n'efface que ce qu'on a
-- posé soi-même. Écrit ce fichier d'abord sous le numéro 97, il a trouvé un
-- `p97_trace` déjà là — celui de `97_report_deux_bouts_1941_1967.sql`, qui
-- existait sur disque et avait tourné — et son `DELETE` sans clause a emporté
-- les 30 453 lignes de trace de l'autre, laissant ses rattachements dans
-- `membership` sans rien pour les défaire. Restaurées depuis `p97_qualite`,
-- qui porte le `membership_id` de chacune ; seul l'horodatage de pose est
-- perdu. `CREATE TABLE IF NOT EXISTS` ne protège de rien quand deux fichiers
-- suivent la même convention de nommage : c'est le NUMÉRO qu'il faut vérifier
-- libre, dans `sql/` ET dans l'inventaire de `diag_passages.sql`, où `97`
-- était réservé d'avance pour un fichier pas encore écrit.
DELETE FROM p98_trace WHERE quoi IN ('ligne', 'ancre');

-- ---------------------------------------------------------------------------
-- 3. Charger les CSV. Chemins relatifs à la RACINE du dépôt, comme `72`.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE csv_coupe(insee text, coupe_id text, valid_from date,
                            valid_to date, source text, note text, wkt text)
    ON COMMIT DROP;
\copy csv_coupe FROM 'cartes/coupes_ville.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE csv_ancre(atom_id text, note text, wkt text, valid_from date, valid_to date) ON COMMIT DROP;
\copy csv_ancre FROM 'cartes/coupes_ville_ancres.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO coupe_ville (coupe_id, insee, valid_from, valid_to, source, note, geom)
SELECT coupe_id, insee, valid_from, valid_to, source, note,
       ST_SetSRID(ST_GeomFromText(wkt), 2154)
  FROM csv_coupe;
INSERT INTO p98_trace (quoi, cle) SELECT 'ligne', coupe_id FROM csv_coupe;

INSERT INTO coupe_ville_ancre (atom_id, note, geom, valid_from, valid_to)
SELECT atom_id, note, ST_SetSRID(ST_GeomFromText(wkt), 2154), valid_from, valid_to FROM csv_ancre;
INSERT INTO p98_trace (quoi, cle) SELECT 'ancre', atom_id FROM csv_ancre;

\endif

-- ---------------------------------------------------------------------------
-- 4. Les deux fonctions. Posées à blanc comme sous `appliquer` : ce sont du
--    code, pas de la donnée, et la section 5 en a besoin pour diagnostiquer.
-- ---------------------------------------------------------------------------

-- Joint chaque bout de `l` au point le plus proche de `bord`, et le DÉPASSE de
-- `d` mètres.
--
-- Les trois essais du 23 septembre, dans l'ordre, parce que les deux premiers
-- échouent en silence et qu'on les refera sinon :
--
--   1. prolonger de 300 m dans l'axe du dernier segment — le bout nord de
--      Vienne est resté dedans : 48,8 m du bord à vol d'oiseau, mais l'axe ne
--      pointait pas vers lui. Allonger aurait fait sortir par le mauvais côté.
--   2. joindre exactement au point le plus proche — la ligne touche le bord
--      sans le traverser. `ST_Node` ne node pas de façon fiable sur un contact
--      ponctuel en flottant : `ST_Polygonize` rendait encore un seul morceau.
--   3. dépasser de quelques mètres — une ligne qui TRAVERSE node toujours.
--
-- 5 m par défaut : très au-dessus du bruit de nodage, très en dessous des
-- 110 m de lisière que les deux trames se disputent. Le dépassement ressort du
-- polygone et `ST_Polygonize` l'ignore comme pendant.
--
-- UN BOUT DÉJÀ SUR LE BORD — corrigé le 24 septembre 2026, sur Montluçon.
-- La direction « du bout vers son point le plus proche » n'existe pas quand
-- les deux sont confondus : une distance de 1e-8 m donne une direction
-- arbitraire, et le dépassement de 5 m part n'importe où. C'est le cas de
-- toute ligne tirée d'un découpage fait sur le même contour — celle de
-- Montluçon est la frontière entre deux morceaux du polygone, ses bouts SONT
-- sur le bord. Sous 0,5 m, on prolonge donc dans l'axe du dernier segment de
-- la ligne elle-même : elle arrive au bord de l'intérieur, elle en ressort
-- par le même chemin.
DROP FUNCTION IF EXISTS raccorde_ligne(geometry, geometry);
-- PLUS DE `DROP` DE LA SIGNATURE COURANTE — 3 octobre 2026. Le DROP puis CREATE
-- donnait à `raccorde_ligne` un nouvel identifiant à chaque passage de `98` ;
-- une session qui découpait au même moment (`check_coupe_partition` de `99`,
-- pendant qu'un `pose_coupe.py --ecrire` rejouait `98`) tombait sur « cache
-- lookup failed for function ». `CREATE OR REPLACE` garde l'identifiant. Seule
-- l'ancienne signature à deux arguments, abandonnée, est encore retirée.
CREATE OR REPLACE FUNCTION raccorde_ligne(l geometry, bord geometry,
                                          d double precision DEFAULT 5)
RETURNS geometry AS $$
-- UNE LIGNE FERMÉE N'A PAS DE BOUT — 25 septembre 2026, Lisieux : la
-- « partie sud » du 1er canton est un îlot au milieu de la ville, bordé d'une
-- boucle de rues. Raccorder son « bout » au bord y tirerait une coupure qui
-- n'existe pas. On la rend telle quelle.
-- UN POINT RÉPÉTÉ AU BOUT — 27 septembre 2026, Chalon-sur-Saône : la traversée
-- de la Saône finissait par deux sommets identiques ; le dernier segment, de
-- longueur nulle, ne donnait plus de direction (division par zéro). On retire
-- les sommets répétés avant tout.
WITH z AS (SELECT ST_RemoveRepeatedPoints(l) zl),
     pts AS (SELECT (ST_DumpPoints(zl)).geom g, (ST_DumpPoints(zl)).path[1] i FROM z),
     a AS (SELECT zl, ST_StartPoint(zl) s, ST_PointN(zl, 2) s2,
                  ST_EndPoint(zl) e, ST_PointN(zl, ST_NPoints(zl) - 1) e2,
                  ST_ClosestPoint(bord, ST_StartPoint(zl)) cs,
                  ST_ClosestPoint(bord, ST_EndPoint(zl)) ce FROM z)
SELECT CASE WHEN ST_IsClosed(zl) THEN zl ELSE ST_SetSRID(ST_MakeLine(
    ARRAY[CASE WHEN ST_Distance(s, cs) < 0.5 THEN
               ST_Translate(s, (ST_X(s) - ST_X(s2)) * d / ST_Distance(s, s2),
                               (ST_Y(s) - ST_Y(s2)) * d / ST_Distance(s, s2))
          ELSE ST_Translate(cs, (ST_X(cs) - ST_X(s)) * d / ST_Distance(s, cs),
                                (ST_Y(cs) - ST_Y(s)) * d / ST_Distance(s, cs)) END]
 || (SELECT array_agg(g ORDER BY i) FROM pts)
 || ARRAY[CASE WHEN ST_Distance(e, ce) < 0.5 THEN
               ST_Translate(e, (ST_X(e) - ST_X(e2)) * d / ST_Distance(e, e2),
                               (ST_Y(e) - ST_Y(e2)) * d / ST_Distance(e, e2))
          ELSE ST_Translate(ce, (ST_X(ce) - ST_X(e)) * d / ST_Distance(e, ce),
                                (ST_Y(ce) - ST_Y(e)) * d / ST_Distance(e, ce)) END]),
    ST_SRID(zl)) END
FROM a;
$$ LANGUAGE sql IMMUTABLE;

-- LA CLÉ D'UNE COUPE N'EST PAS TOUJOURS UNE COMMUNE — 3 octobre 2026, Paris.
-- Un quartier parisien coupé entre deux circonscriptions (la Muette par le
-- boulevard de Beauséjour, le 11e par le boulevard Voltaire) se découpe comme
-- une ville : une ligne, deux fractions, deux ancres. Mais il n'a pas de code
-- INSEE à lui — ses fractions (`PQ62#58N`, posées par `101`) portent celui de
-- l'arrondissement — et son partage est de niveau `circo`, pas `canton`.
-- `coupe_ville.insee` porte alors l'atome du quartier (`PQ62`), et deux
-- fonctions disent, pour toute la mécanique qui suit :
--   * `coupe_cle()`    : à quelle clé de coupe un atome répond — son quartier
--                        (`cassini`) pour un atome `PQ…`, sa commune sinon ;
--   * `coupe_niveau()` : à quel niveau la clé se partage.
-- Rien ne change pour les villes : leur clé reste `insee_geofla`, leur niveau
-- `canton`.
CREATE OR REPLACE FUNCTION coupe_cle(p_cassini text, p_insee_geofla text)
RETURNS text AS $$
  SELECT CASE WHEN p_cassini LIKE 'PQ%' THEN p_cassini ELSE p_insee_geofla END;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION coupe_niveau(p_cle text)
RETURNS text AS $$
  SELECT CASE WHEN p_cle LIKE 'PQ%' THEN 'circo' ELSE 'canton' END;
$$ LANGUAGE sql IMMUTABLE;

-- Le polygone à découper, à la date demandée : ANR s'il parle, `atom_geom` en
-- repli. C'est exactement ce que la carte dessine depuis `82`.
-- UNE FRACTION PREND L'ANR DE SON ATOME-MÈRE — Lille, 27 septembre 2026. Les
-- fractions (`19581#5934`…) n'ont pas d'ANR à elles : chacune retombait sur
-- `atom_geom`, le contour GEOFLA d'aujourd'hui, et la cible devenait l'union du
-- Lille de 1880 (ANR, 2 184 ha) et du Lille de 2000, Lomme et Hellemmes compris
-- (3 633 ha). C'est aussi ce qui faussait Lisieux avant 1960, Gap et Briançon.
-- Une fraction prend donc l'ANR de l'atome dont elle est la fraction (`cassini`)
-- quand elle n'en a pas en propre ; `atom_geom` ne sert qu'en dernier repli.
-- UNE COMMUNE ABSORBÉE N'A PLUS DE REPLI — 2 octobre 2026, Le Havre. Graville
-- (atome 16104) a ses ANR jusqu'en 1919, date de son annexion ; ensuite elle
-- retombait sur `atom_geom`, le contour GEOFLA du Havre d'aujourd'hui (5 536 ha),
-- et la cible de 1930 faisait 5 829 ha au lieu de 3 666. Même défaut à Gap
-- (atome 8884, absorbé en 1895 : 1 450 ha de trop jusqu'en 1974). Un atome dont
-- TOUTES les ANR sont closes à la date n'existe plus : il est écarté. Celui dont
-- l'ANR ne commence que plus tard (Beauvais, ANR depuis 1943) garde son repli.
-- UNE COMMUNE ENCORE À PART N'EST PAS À DÉCOUPER — même jour. Avant 1919,
-- Graville est une commune entière, dans son propre canton (Le Havre-6) : sa
-- `membership` est celle de l'atome 16104 lui-même. Elle entrait pourtant dans
-- la cible du Havre (même `insee_geofla`), par l'atome et par ses fractions
-- modernes (16104#…, qui prennent son ANR) : 3 666 ha en 1900 au lieu de 2 012,
-- et une « aire perdue » à la recette. Un atome (ou ses fractions) dont l'atome-
-- mère a lui-même un canton à la date est écarté, quand d'AUTRES fractions de
-- la ville ont un canton à cette date. Saumur 1968-1973 (l'atome entier dans le
-- Sud, aucune fraction) n'est pas touché ; éprouvé sur toutes les villes
-- coupées : seul Le Havre change.
CREATE OR REPLACE FUNCTION cible_ville(p_insee text, p_date date)
RETURNS geometry AS $$
  SELECT ST_UnaryUnion(ST_Collect(COALESCE(n.geom, nm.geom, g.geom)))
    FROM atom a
    JOIN atom_geom g ON g.atom_id = a.atom_id
    LEFT JOIN atom_geom_anr n ON n.atom_id = a.atom_id AND n.periode @> p_date
    LEFT JOIN atom_geom_anr nm ON nm.atom_id = a.cassini AND a.cassini <> a.atom_id
                              AND nm.periode @> p_date
   WHERE coupe_cle(a.cassini, a.insee_geofla::text) = p_insee
     AND (n.geom IS NOT NULL OR nm.geom IS NOT NULL
          OR NOT EXISTS (SELECT 1 FROM atom_geom_anr x WHERE x.atom_id IN (a.atom_id, a.cassini))
          OR EXISTS (SELECT 1 FROM atom_geom_anr x
                      WHERE x.atom_id IN (a.atom_id, a.cassini) AND upper(x.periode) > p_date))
     AND NOT (EXISTS (SELECT 1 FROM membership m
                       WHERE m.atom_id = a.cassini AND m.niveau = coupe_niveau(p_insee) AND m.periode @> p_date)
              AND EXISTS (SELECT 1 FROM atom f
                            JOIN membership mf ON mf.atom_id = f.atom_id AND mf.niveau = coupe_niveau(p_insee)
                                              AND mf.periode @> p_date
                           WHERE coupe_cle(f.cassini, f.insee_geofla::text) = p_insee AND f.atom_id LIKE '%#%'
                             AND f.cassini <> a.cassini));
$$ LANGUAGE sql STABLE;

-- Le découpage lui-même. Rend un morceau par ancre contenue ; une ville sans
-- ligne rend son polygone entier, une ligne qui ne ferme pas aussi — et c'est
-- la recette, pas cette fonction, qui fait la différence entre les deux.
--
-- LE CONTOUR EST UN PARAMÈTRE — 3 octobre 2026, pour `99_partition_coupes.sql`.
-- La découpe ne vit plus que dans `carte_coupe_ville_sur(insee, date, contour)` ;
-- `carte_coupe_ville(insee, date)` l'appelle avec `cible_ville()` et rend
-- exactement ce qu'elle rendait (recette du § 5, `pose_coupe.py`,
-- `tableau_villes.py`). `99` l'appelle avec le polygone que le treillis de `84`
-- vient d'arbitrer pour la commune. C'est l'en-tête de ce fichier pris au mot :
-- une ligne se raccorde au polygone DU JOUR, quel qu'il soit. Une seule copie
-- de la découpe : une correction faite ici vaut pour la carte comme pour la
-- recette.
CREATE OR REPLACE FUNCTION carte_coupe_ville_sur(p_insee text, p_date date,
                                                 p_cible geometry)
RETURNS TABLE(atom_id text, geom geometry(MultiPolygon, 2154)) AS $$
WITH cible AS (SELECT p_cible g),
     -- Le raccord se fait ICI, au tirage, et jamais au stockage. La ligne
     -- rangée dans le CSV est le CHOIX — une limite d'IRIS, ou un tracé à la
     -- main — et elle ne connaît aucune trame. C'est en la découpant qu'on la
     -- joint au bord du polygone du jour : ANR en 2010, `atom_geom` ailleurs,
     -- un autre référentiel demain. Raccorder au stockage reviendrait à figer
     -- la ligne sur une trame, c'est-à-dire à reperdre ce qu'on a gagné en ne
     -- stockant pas de polygones.
     --
     -- C'est aussi ce qui a mordu le 23 septembre : la ligne avait été
     -- raccordée AVANT d'être écrite, puis arrondie au centimètre par
     -- `ST_SnapToGrid`. Un centimètre suffit à décoller un bout du bord ;
     -- `ST_Polygonize` rend alors la commune entière, sans un mot, et les
     -- deux ancres tombent dans le même morceau. La recette l'a vu — deux
     -- morceaux d'aire identique, somme exactement double de la cible.
     -- UN BOUT SE RACCORDE AU BORD OU À UNE AUTRE LIGNE — 25 septembre 2026.
     -- À Charleville-Mézières, cinq cantons, trois limites se rejoignent au
     -- pont du faubourg du Theux, à 1 151 m du bord communal. Raccordées au
     -- seul bord, elles y tiraient un trait droit d'un kilomètre. Un bout de
     -- ligne rejoint donc le plus proche, du bord ou des autres lignes de la
     -- ville à la même date.
     -- ET ELLE Y EST CALÉE À 1 M PRÈS (`ST_Snap`) — même jour, même ville.
     -- Au pont ferroviaire sud, L3 arrive par le rail et repart vers l'ouest
     -- le long de la Meuse ; L4 part vers l'est le long de la même Meuse. Le
     -- départ de L4 tombait à une fraction de millimètre de L3, et son
     -- prolongement de 5 m partait DANS L'AXE de L3 : il la longeait sans la
     -- couper. Villers-Semeuse et Mézières-Est communiquaient par ce trou et
     -- sortaient en un seul morceau. Un raccord qui dépasse ne suffit pas
     -- quand il est colinéaire ; il faut que les sommets coïncident.
     reference AS (SELECT c.coupe_id, ST_Union(ST_Boundary((SELECT g FROM cible)),
                       coalesce((SELECT ST_Union(o.geom) FROM coupe_ville o
                                  WHERE o.insee = p_insee AND o.coupe_id <> c.coupe_id
                                    AND o.periode @> p_date),
                                ST_GeomFromText('LINESTRING EMPTY', 2154))) r
                     FROM coupe_ville c WHERE c.insee = p_insee AND c.periode @> p_date),
     lames AS (SELECT ST_UnaryUnion(ST_Collect(
                   ST_Snap(raccorde_ligne(c.geom, ref.r), ref.r, 1.0))) g
                 FROM coupe_ville c JOIN reference ref USING (coupe_id)
                WHERE c.insee = p_insee AND c.periode @> p_date),
     trait AS (SELECT ST_Node(ST_Union(
                   ST_Boundary((SELECT g FROM cible)),
                   COALESCE((SELECT g FROM lames),
                            ST_Boundary((SELECT g FROM cible))))) g),
     morceaux AS (SELECT row_number() OVER () k, g FROM
                    (SELECT (ST_Dump(ST_Polygonize((SELECT g FROM trait)))).geom g) x),
     -- LES ANCRES DES SEULES FRACTIONS QUI ONT UN CANTON À LA DATE — Lisieux,
     -- 25 septembre 2026. Le 3e canton (1985/1991) a son ancre au sud ; en
     -- 1900, ce sud appartient au 2e, et le morceau sortait deux fois, une
     -- fois par ancre. Si AUCUNE fraction n'a de canton à la date (trou de
     -- `membership` : Aix 1973-1992, Lisieux 1973-1998), toutes les ancres
     -- jouent : la ligne, elle, est datée par son texte.
     actives AS (SELECT a.atom_id FROM atom a
                  WHERE coupe_cle(a.cassini, a.insee_geofla::text) = p_insee AND a.atom_id LIKE '%#%'
                    AND EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id
                                  AND m.niveau = coupe_niveau(p_insee) AND m.periode @> p_date)),
     -- … mais seulement les ancres de fractions qui ont un canton PENDANT la
     -- période des lignes du jour : Bourg-en-Bresse 1973-1982 (I, II, III)
     -- n'a aucune fraction en base, et les ancres de 1982 étiquetaient à tort
     -- les morceaux de 1973. Sans fraction, pas de morceau : c'est un trou de
     -- la base, la ligne reste rangée pour le jour où il sera comblé.
     portee AS (SELECT daterange(min(valid_from), max(valid_to), '[)') r
                  FROM coupe_ville WHERE insee = p_insee AND periode @> p_date),
     ancres AS (SELECT an.*, (SELECT min(lower(m.periode)) FROM membership m
                                WHERE m.atom_id = an.atom_id AND m.niveau = coupe_niveau(p_insee)) premier
                  FROM coupe_ville_ancre an
                  JOIN atom a ON a.atom_id = an.atom_id AND coupe_cle(a.cassini, a.insee_geofla::text) = p_insee
                 WHERE (an.valid_from IS NULL OR an.valid_from <= p_date)
                   AND (an.valid_to IS NULL OR p_date < an.valid_to)
                   AND (an.atom_id IN (SELECT atom_id FROM actives)
                    OR (NOT EXISTS (SELECT 1 FROM actives)
                        -- UNE ANCRE DATÉE VAUT POUR SA PÉRIODE — 27 septembre 2026,
                        -- Boulogne 1958-1985 : le Nord n'a de canton en base qu'en
                        -- 1870-1941 et après 1992, hors de la portée des lignes.
                        -- Une ancre posée expressément pour la période joue quand
                        -- même dans un trou de la base.
                        AND (an.valid_from IS NOT NULL
                          OR EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = an.atom_id
                                      AND m.niveau = coupe_niveau(p_insee)
                                      AND m.periode && (SELECT r FROM portee)))))),
     -- Dans un trou, deux ancres peuvent tomber dans un même morceau (Lisieux
     -- 1960-1968 : les lignes du 3e canton ne sont pas encore posées) : la
     -- fraction la plus ancienne le garde.
     attribue AS (SELECT DISTINCT ON (m.k) m.k, an.atom_id, m.g
                    FROM morceaux m JOIN ancres an ON ST_Contains(m.g, an.geom)
                   WHERE ST_Contains((SELECT g FROM cible), ST_PointOnSurface(m.g))
                   ORDER BY m.k, an.premier NULLS LAST, an.atom_id),
     -- LES ÎLOTS — Antibes, 26 septembre 2026. La cible est un multipolygone :
     -- la commune et une dizaine d'îlots du cap (0,4 ha). Aucune ligne ne les
     -- touche ; sans ancre, ils étaient perdus et la recette criait « AIRE
     -- PERDUE ». Un morceau sans ancre QU'AUCUNE LIGNE NE TOUCHE est une partie
     -- entière de la cible : il va au morceau ancré le plus proche. Un morceau
     -- sans ancre bordé par une ligne reste perdu : c'est une ligne qui ne ferme
     -- pas, et la recette doit continuer de le voir.
     -- LES MIETTES DE RACCORD — Lille, 27 septembre 2026. Depuis que la cible
     -- suit l'ANR (voir `cible_ville`), les bouts de lignes tracées contre l'ancien
     -- contour laissent des éclats de moins d'un hectare le long du bord (Soissons,
     -- Briançon, Lisieux). Un morceau sans ancre DE MOINS D'UN HECTARE va lui
     -- aussi au morceau ancré voisin, celui avec qui il partage le plus de bord.
     -- Au-delà d'un hectare, un morceau sans ancre reste perdu et signalé.
     ilots AS (SELECT DISTINCT ON (m.k) m.k, at.atom_id, m.g
                 FROM morceaux m CROSS JOIN attribue at
                WHERE m.k NOT IN (SELECT k FROM attribue)
                  AND ST_Contains((SELECT g FROM cible), ST_PointOnSurface(m.g))
                  AND (NOT ST_Intersects(m.g, coalesce((SELECT g FROM lames),
                                                       ST_GeomFromText('LINESTRING EMPTY', 2154)))
                       OR ST_Area(m.g) < 1e4)
                  AND EXISTS (SELECT 1 FROM lames WHERE g IS NOT NULL)
                ORDER BY m.k, ST_Distance(m.g, at.g),
                         ST_Length(ST_Intersection(ST_Boundary(m.g), ST_Boundary(at.g))) DESC),
     -- L'ANCRE HORS DU CONTOUR DU JOUR — 3 octobre 2026, Saint-Quentin, vue par
     -- `99`. Une ancre posée sur une pointe que l'ANR donne à la ville (le Nord,
     -- POINT(723299 6972394)) tombe HORS du polygone que le treillis de `84` lui
     -- laisse (GEOFLA arbitré : 87 ha de moins). Elle n'est dans aucun morceau ;
     -- le reste de la pointe, 5,3 ha bordés par la ligne, sortait sans
     -- propriétaire, et `99` laissait la ville entière.
     -- Une ancre hors du contour va au morceau LE PLUS PROCHE d'elle, et
     -- seulement si ce morceau est PERDU (ni ancré, ni îlot, ni miette). Aucun
     -- seuil de distance : si le morceau le plus proche a déjà un propriétaire,
     -- l'ancre ne prend rien et la perte reste signalée. Une ville conforme n'a
     -- pas de morceau perdu : elle n'est pas touchée.
     dans AS (SELECT m.k, m.g FROM morceaux m
               WHERE ST_Contains((SELECT g FROM cible), ST_PointOnSurface(m.g))),
     dehors AS (SELECT row_number() OVER () n, an.atom_id, an.geom FROM ancres an
                 WHERE NOT ST_Contains((SELECT g FROM cible), an.geom)),
     rattrape AS (SELECT DISTINCT ON (pr.k) pr.k, pr.atom_id, pr.g
                    FROM (SELECT DISTINCT ON (d.n) d.atom_id, m.k, m.g,
                                 ST_Distance(m.g, d.geom) dist
                            FROM dehors d CROSS JOIN dans m
                           ORDER BY d.n, ST_Distance(m.g, d.geom), m.k) pr
                   WHERE pr.k NOT IN (SELECT k FROM attribue)
                     AND pr.k NOT IN (SELECT k FROM ilots)
                   ORDER BY pr.k, pr.dist)
-- SANS LIGNE À LA DATE, RIEN — Lille, 27 septembre 2026. Une ville ancrée pour
-- un régime (Troyes 1870-1973) rendait, à une date sans ligne (Troyes 2000), la
-- commune entière à la plus ancienne de ses fractions : une découpe fausse, et
-- muette. Une date sans ligne active n'est pas découpée.
SELECT atom_id, ST_Multi(ST_Union(g))
  FROM (SELECT atom_id, g FROM attribue UNION ALL SELECT atom_id, g FROM ilots
        UNION ALL SELECT atom_id, g FROM rattrape) x
 WHERE EXISTS (SELECT 1 FROM coupe_ville c WHERE c.insee = p_insee AND c.periode @> p_date)
 GROUP BY atom_id;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION carte_coupe_ville(p_insee text, p_date date)
RETURNS TABLE(atom_id text, geom geometry(MultiPolygon, 2154)) AS $$
SELECT * FROM carte_coupe_ville_sur(p_insee, p_date, cible_ville(p_insee, p_date));
$$ LANGUAGE sql STABLE;

-- ---------------------------------------------------------------------------
-- 5. RECETTE — la seule lecture qui vaille. Le code de retour vaut zéro qu'une
--    ligne ferme ou non ; c'est ce tableau qui le dit.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5 a. Ville par ville, à la date de départ de ses lignes : morceaux,'
\echo '--      fractions ayant un canton à cette date, aire rendue vs aire cible'
-- UNE DATE PAR VILLE — corrigé le 24 septembre 2026. La première version
-- jugeait tout au 1er janvier 2010 et comptait TOUTES les fractions de la
-- commune. Montluçon a deux cantons de 1870 à 1985 (Est, Ouest : « séparation
-- le Cher ») et CINQ ensuite ; sa ligne ne vaut que pour le premier régime.
-- Jugée en 2010, elle aurait été déclarée « ne ferme pas » — deux morceaux
-- pour cinq fractions — alors qu'elle est juste. On juge donc chaque ville au
-- départ de ses lignes, et on n'y compte que les fractions qui ont un canton
-- à cette date.
--
-- Et si la base n'a AUCUN canton pour les fractions à cette date — Aix-en-
-- Provence : le décret du 2 février 1982 crée Centre, Nord-Est et Sud-Ouest,
-- la base ne les fait commencer qu'au 22 mars 1992 —, on juge au premier
-- jour, dans la période des lignes, où elle en a. La ligne garde la date du
-- texte ; le trou est celui de `membership`, pas celui de la ligne.
WITH villes0 AS (
    SELECT c.insee, count(DISTINCT c.coupe_id) lignes, min(c.valid_from) d0, max(c.valid_to) f0
      FROM coupe_ville c GROUP BY 1),
     villes AS (
    SELECT v0.insee, v0.lignes,
           CASE WHEN EXISTS (SELECT 1 FROM atom a
                  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = coupe_niveau(v0.insee::text) AND m.periode @> v0.d0
                 WHERE coupe_cle(a.cassini, a.insee_geofla::text) = v0.insee::text AND a.atom_id LIKE '%#%')
                THEN v0.d0
                ELSE coalesce((SELECT min(lower(m.periode)) FROM atom a
                  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = coupe_niveau(v0.insee::text)
                 WHERE coupe_cle(a.cassini, a.insee_geofla::text) = v0.insee::text AND a.atom_id LIKE '%#%'
                   AND lower(m.periode) > v0.d0 AND lower(m.periode) < coalesce(v0.f0, 'infinity')), v0.d0)
           END d
      FROM villes0 v0),
     v AS (
    SELECT villes.*,
           (SELECT count(DISTINCT a.atom_id) FROM atom a
              JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = coupe_niveau(villes.insee::text)
                               AND m.periode @> villes.d
             WHERE coupe_cle(a.cassini, a.insee_geofla::text) = villes.insee::text AND a.atom_id LIKE '%#%') fractions,
           (SELECT count(*) FROM atom a JOIN coupe_ville_ancre an ON an.atom_id = a.atom_id
             WHERE coupe_cle(a.cassini, a.insee_geofla::text) = villes.insee::text) ancres,
           -- fractions qui ont un canton à la date SANS ancre valable à la date
           (SELECT count(DISTINCT a.atom_id) FROM atom a
              JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = coupe_niveau(villes.insee::text)
                               AND m.periode @> villes.d
             WHERE coupe_cle(a.cassini, a.insee_geofla::text) = villes.insee::text AND a.atom_id LIKE '%#%'
               AND NOT EXISTS (SELECT 1 FROM coupe_ville_ancre an WHERE an.atom_id = a.atom_id
                                  AND (an.valid_from IS NULL OR an.valid_from <= villes.d)
                                  AND (an.valid_to IS NULL OR villes.d < an.valid_to))) sans_ancre,
           -- fractions ANCRÉES pour la date (ancre valable) mais SANS canton en base à la date
           (SELECT count(DISTINCT an.atom_id) FROM coupe_ville_ancre an JOIN atom a ON a.atom_id = an.atom_id
             WHERE coupe_cle(a.cassini, a.insee_geofla::text) = villes.insee::text
               AND (an.valid_from IS NULL OR an.valid_from <= villes.d)
               AND (an.valid_to IS NULL OR villes.d < an.valid_to)
               AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = an.atom_id
                                  AND m.niveau = coupe_niveau(villes.insee::text) AND m.periode @> villes.d)) absentes,
           (SELECT count(*) FROM carte_coupe_ville(villes.insee, villes.d)) morceaux,
           (SELECT sum(ST_Area(geom)) FROM carte_coupe_ville(villes.insee, villes.d)) m2_rendu,
           ST_Area(cible_ville(villes.insee, villes.d)) m2_cible
      FROM villes)
SELECT insee, d AS a_la_date, lignes, fractions, ancres, morceaux,
       round((m2_rendu / 1e4)::numeric, 1) ha_rendu,
       round((m2_cible / 1e4)::numeric, 1) ha_cible,
       -- UNE FRACTION QUE LE TEXTE NE CONNAÎT PAS — 27 septembre 2026, Wattrelos :
       -- la base y met une fraction de Roubaix-Ouest de 1892 à 1941, le texte de 1892
       -- n'a que Nord et Est. La ligne ferme, la ville est couverte : c'est la base
       -- qui a une fraction de trop (a_inscrire_en_base.md), pas la ligne qui fuit.
       -- UN RÉGIME QUE LA BASE N'A PAS — 27 septembre 2026, Beauvais 1958-1986 :
       -- aucune fraction n'a de canton pendant toute la période des lignes. Rien
       -- n'est tiré ; ce n'est pas une aire perdue, c'est une inscription à faire.
       -- UNE FRACTION QUE LA BASE N'A PAS À LA DATE — 27 septembre 2026, Boulogne :
       -- en 1968-1973 la base n'a que le Sud ; le morceau du Nord, ancré, n'est pas
       -- tiré. C'est une appartenance à inscrire, pas une ligne qui perd de l'aire.
       CASE WHEN fractions = 0 THEN 'RÉGIME ABSENT DE LA BASE'
            WHEN absentes > 0 AND morceaux = fractions - sans_ancre
                 AND abs(coalesce(m2_rendu, 0) - m2_cible) > 1.0
                 THEN CASE WHEN sans_ancre > 0 THEN 'FRACTION ABSENTE + FRACTION SANS ANCRE (base)'
                           ELSE 'FRACTION ABSENTE (base)' END
            WHEN morceaux = fractions - sans_ancre AND sans_ancre > 0
                 AND abs(coalesce(m2_rendu, 0) - m2_cible) <= 1.0 THEN 'FRACTION SANS ANCRE (base)'
            WHEN morceaux <> fractions THEN 'LIGNE QUI NE FERME PAS'
            WHEN abs(coalesce(m2_rendu, 0) - m2_cible) > 1.0 THEN 'AIRE PERDUE'
            ELSE 'conforme' END verdict
  FROM v ORDER BY insee;

\echo ''
\echo '-- 5 b. Les lignes de banc d''essai, à refaire sur texte'
SELECT coupe_id, insee, source, left(note, 60) note FROM coupe_ville
 WHERE source = 'banc' ORDER BY coupe_id;

\echo ''
\echo '-- 5 c. Avancement : 315 villes, 750 coupes (toutes origines, COG compris)'
WITH a_couper AS (SELECT coupe_cle(cassini, insee_geofla::text) insee FROM atom JOIN atom_geom USING (atom_id)
                   WHERE insee_geofla IS NOT NULL AND fraction AND atom_id LIKE '%#%'
                   GROUP BY 1 HAVING count(*) > 1)
SELECT (SELECT count(DISTINCT insee) FROM coupe_ville) villes_amorcees,
       (SELECT count(*) FROM coupe_ville) lignes_posees,
       (SELECT count(*) FROM coupe_ville WHERE source <> 'banc') lignes_etablies,
       (SELECT count(*) FROM a_couper
         WHERE insee NOT IN (SELECT insee::text FROM coupe_ville)) villes_restantes;

\if :{?appliquer}
\echo ''
\echo '=== 98 appliqué. Lire la recette ci-dessus, pas le code de retour. ==='
\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

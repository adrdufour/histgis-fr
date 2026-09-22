-- ============================================================================
-- 40_scission_circo.sql — combler les trous de la couche CIRCO
--
--   psql -d histgis -f sql/40_scission_circo.sql
--
-- Le défaut, trouvé le 15 août 2026 par Arrien-en-Bethmale
-- --------------------------------------------------------
-- Cette commune de l'Ariège, née en 1931 par détachement de Bethmale, apparaît
-- dans le canton de Castillon dès 1870 — `11_scission.sql` a fait son travail —
-- mais **n'a aucune circonscription avant 1928**.
--
-- La cause est le garde-fou 4 de `11`, qui refuse de franchir une interruption
-- de l'unité d'accueil. Il a été écrit pour les cantons, et il y est juste :
-- TRF-GIS réutilise les codes de canton de part et d'autre de 1871 en
-- Alsace-Moselle, si bien qu'une interruption peut cacher deux cantons
-- différents sous une même clé.
--
-- **Mais une interruption de circonscription n'est pas une interruption de
-- territoire.** Elle signale l'alternance du mode de scrutin. `U0903@1876` —
-- uninominal, segment ouvert en 1876 — n'a pas de membres entre 1885 et 1889
-- parce que l'Ariège votait alors au scrutin de liste, sous `L0901@1870`. Le
-- territoire, lui, n'a jamais cessé d'appartenir à une circonscription.
--
-- Le garde-fou, juste pour les cantons, se trompe de cible sur les circos.
--
-- L'ampleur, mesurée avant d'écrire
-- ---------------------------------
--   462 atomes ont leur premier rattachement circo après 1870
--   356 d'entre eux voient leur prolongement bloqué avant 1870
--   9 500 années-communes de trou résiduel dans la couche circo
--
-- Ce que la première version laissait passer (20 août 2026)
-- ---------------------------------------------------------
-- Villeneuve-la-Garenne, vue sur la carte sans circonscription de 1893 à 1928,
-- a montré que ce fichier ne comblait qu'une part du trou qu'il annonçait
-- traiter. Recompté sur toute la série, atome par atome et année par année :
--
--   trou de tête, voisins unanimes      17 340 années-communes   270 atomes
--   trou intérieur, voisins unanimes       265 années-communes    12 atomes
--   aucun voisin renseigné               4 325 années-communes    77 atomes
--   voisins partagés                        21 années-communes     3 atomes
--
-- Les deux premières lignes sont posables sans rien inventer ; les deux
-- dernières restent des limites connues, et doivent le rester. La version
-- d'origine n'en posait que 967 lignes sur 308 atomes : elle ne voyait ni les
-- atomes dépourvus de toute circonscription, ni les trous de milieu de
-- chronologie. Voir le § 2 pour le détail des deux angles morts.
--
-- Les blocages tombent exactement sur les bascules de régime — 1889 (104
-- atomes), 1876 (86), 1919 (59), 1928 (43), 1885 (19). La signature ne laisse
-- aucun doute sur la cause.
--
-- La règle retenue, et pourquoi elle est sûre
-- -------------------------------------------
-- On ne cherche PAS la commune mère : `11` ne connaît pas la filiation, et la
-- reconstruire par la géométrie serait un chantier à part. On passe par un
-- pont déjà construit — **le canton**, que `11` a correctement prolongé.
--
--   « À une date donnée, l'atome reçoit la circonscription de ses VOISINS DE
--     CANTON, si et seulement si ceux-ci sont unanimes. »
--
-- Mesuré sur 15 dates quinquennales et 2 561 cas atome-date :
--
--   unanime          87,7 %   -> on pose
--   canton partagé    0,0 %   -> jamais rencontré
--   aucun voisin     12,3 %   -> on s'abstient
--
-- Ce « jamais rencontré » était un artefact de l'échantillon : 15 dates
-- quinquennales sur les seuls atomes alors candidats. Le recomptage exhaustif
-- de 2026-08-20 trouve **21 années-communes sur 3 atomes** où le canton est
-- partagé entre deux circonscriptions. C'est rare, mais ce n'est pas nul, et
-- le garde-fou qui s'abstient dans ce cas n'était donc pas décoratif.
--
-- **Zéro cas ambigu.** La règle ne tranche jamais un conflit, elle constate un
-- accord ou se tait. Les 12,3 % d'abstention sont les cantons dont aucun membre
-- n'a de circonscription à cette date — l'Alsace-Moselle entre 1871 et 1919,
-- qui doit rester non couverte.
--
-- Ce que la règle suppose, et qu'il faut assumer
-- ----------------------------------------------
-- Qu'une commune née d'une scission reste dans la circonscription de son
-- canton. C'est l'exacte transposition de l'hypothèse de `11` — « une commune
-- nouvelle reste dans le canton de sa mère » — d'un niveau à l'autre, et elle
-- est plus solide ici : le canton est une brique de la circonscription pendant
-- toute la période, alors que la mère n'est qu'une voisine.
--
-- Elle est fausse dans un cas : une commune coupée entre deux circonscriptions.
-- Le garde-fou 3 l'écarte.
--
-- Pourquoi une découpe ANNUELLE
-- -----------------------------
-- Toutes les dates de `membership` tombent au 1er janvier — vérifié, sans
-- exception. Un traitement année par année est donc EXACT et non approché, et
-- il rend le fichier lisible là où une algèbre d'intervalles ne le serait pas.
--
-- Réversible : tout est tracé dans `scission_circo_trace`, et la section 5
-- donne la commande pour retirer le passage.
-- Rejouable : le script retire ses propres lignes avant de recommencer.
-- Prérequis : `11_scission.sql` doit avoir été joué — c'est lui qui fournit le
-- canton prolongé sur lequel tout repose.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.scission_trace') IS NULL THEN
        RAISE EXCEPTION '11_scission.sql doit être joué avant : le canton '
                        'prolongé est le pont de ce correctif.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scission_circo_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    debut_reel    date,            -- première circo réelle de l'atome, ou NULL
    voisins       int  NOT NULL,   -- combien de voisins de canton l'ont dicté
    pose_le       timestamptz NOT NULL DEFAULT now()
);

-- `debut_reel` était NOT NULL tant que le fichier ne traitait que les atomes
-- ayant DÉJÀ une circonscription. Depuis qu'il traite aussi ceux qui n'en ont
-- aucune, la colonne doit accepter NULL — c'est justement ce vide qu'elle
-- documente. Sur une base existante, la contrainte se relâche ici.
ALTER TABLE scission_circo_trace ALTER COLUMN debut_reel DROP NOT NULL;

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM scission_circo_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE scission_circo_trace;

-- ---------------------------------------------------------------------------
-- 1. Le calendrier des années couvertes par la base
-- ---------------------------------------------------------------------------
-- ÉCHANTILLONNÉ AU 1er DÉCEMBRE, et non au 1er janvier. Changé le 20 août 2026.
--
-- Deux bornes de la couche circo tombent en cours d'année : le 24 novembre 1986
-- et le 10 juin 2012. Au 1er janvier, ce fichier les manquait toutes les deux —
-- il interrogeait les voisins sur l'ancien découpage puis posait l'année
-- entière, débordant sur le nouveau.
--
-- C'est la même date de référence que `MOIS_JOUR` dans `cartes/export_web.py`.
-- **Les deux doivent rester d'accord** : si la carte échantillonne l'année à
-- une date et ce correctif à une autre, il comble un trou que la carte ne voit
-- pas, et laisse un trou qu'elle montre.
DROP TABLE IF EXISTS sc_annee;
CREATE TEMP TABLE sc_annee AS
SELECT an, make_date(an, 12, 1) AS d
  FROM generate_series(
           -- Niveau CANTON, et non tous niveaux : depuis `54`, `min(valid_from)`
           -- sur tout `membership` vaut 1815 (Paris), et la serie balayait
           -- cinquante-cinq annees ou aucun atome n'a de canton — donc aucune
           -- candidate possible. Provablement vide, mais coûteux et trompeur.
           -- Aligné le 6 septembre 2026 sur `42` et `46`, où le même
           -- glissement changeait, lui, le RÉSULTAT.
           extract(year FROM (SELECT min(valid_from) FROM membership
                               WHERE niveau = 'canton'))::int,
           extract(year FROM (SELECT max(valid_to)   FROM membership))::int - 1
       ) AS an;

-- ---------------------------------------------------------------------------
-- 2. Les candidats : TOUTE année où l'atome a un canton et pas de circo
--
-- Cette définition a remplacé le 20 août 2026 une sélection qui avait deux
-- angles morts, mesurés :
--
--   « SELECT atom_id, min(valid_from) FROM membership WHERE niveau='circo'
--     GROUP BY atom_id HAVING min(valid_from) > (début de la base) »
--
--   1. Un atome SANS AUCUNE circonscription n'apparaît pas dans ce GROUP BY.
--      Il n'était donc jamais candidat — alors que c'est le cas le plus grave.
--      **270 atomes, 17 340 années-communes**, dont les voisins de canton sont
--      pourtant unanimes.
--   2. La dictée ne portait que sur les années ANTÉRIEURES au premier
--      rattachement (`WHERE an < debut`). Un trou de MILIEU de chronologie
--      restait invisible : **12 atomes, 265 années-communes**. Villeneuve-la-
--      Garenne, née en 1929 de Gennevilliers, en est le témoin — 1893 à 1927
--      sans circonscription alors que sa mère a une chaîne continue.
--
-- Le second angle mort était le plus instructif : l'en-tête de ce fichier
-- reproche au garde-fou 1 de `11_scission.sql` de ne prolonger que le premier
-- rattachement, et **reproduisait exactement le même défaut**. Une critique
-- juste ne protège pas de la faute qu'elle nomme.
--
-- Effet de bord réparé au passage : l'ancienne sélection dépendait de l'ORDRE
-- de la chaîne. Si `46_creation_serie.sql` passait avant, il donnait à l'atome
-- une circo dès 1870 ; `min(valid_from) > début` devenait faux et l'atome
-- sortait des candidats, trou intérieur compris. La définition par le trou est
-- insensible à l'ordre : elle décrit un état, pas une histoire.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_trou;
CREATE TEMP TABLE sc_trou AS
SELECT mc.atom_id,
       a.an,
       a.d,
       mc.unit_id AS canton
  FROM sc_annee a
  JOIN membership mc ON mc.niveau = 'canton' AND mc.periode @> a.d
 WHERE NOT EXISTS (SELECT 1 FROM membership mx
                    WHERE mx.atom_id = mc.atom_id
                      AND mx.niveau  = 'circo'
                      AND mx.periode @> a.d);

-- Garde-fou 3 : on écarte les atomes-fraction. Une commune coupée entre deux
-- circonscriptions ne peut pas hériter d'une circo unique, et c'est justement
-- le cas où l'unanimité des voisins ne prouverait rien.
DELETE FROM sc_trou t
 USING atom a
 WHERE a.atom_id = t.atom_id AND a.fraction;

CREATE INDEX sc_trou_canton_idx ON sc_trou (canton, d);
ANALYZE sc_trou;

-- Première circonscription réelle de l'atome, pour la trace seulement. NULL
-- quand l'atome n'en a aucune — cas que l'ancienne sélection ne voyait pas.
DROP TABLE IF EXISTS sc_debut;
CREATE TEMP TABLE sc_debut AS
SELECT atom_id, min(valid_from) AS debut
  FROM membership WHERE niveau = 'circo' GROUP BY atom_id;

-- ---------------------------------------------------------------------------
-- 3. Ce que les voisins de canton disent, année par année
--
-- On ne retient une année que si les voisins sont UNANIMES. Le `count(DISTINCT
-- unit_id) = 1` est tout le correctif : il pose quand la donnée est d'accord
-- avec elle-même, et se tait sinon.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_dicte;
CREATE TEMP TABLE sc_dicte AS
WITH voisin AS (
    -- ce que portent les AUTRES membres du canton, cette année-là
    SELECT t.atom_id, t.an, t.d, mv.unit_id AS circo
      FROM sc_trou t
      JOIN membership mk ON mk.niveau  = 'canton'
                        AND mk.unit_id = t.canton
                        AND mk.atom_id <> t.atom_id
                        AND mk.periode @> t.d
      JOIN membership mv ON mv.atom_id = mk.atom_id
                        AND mv.niveau  = 'circo'
                        AND mv.periode @> t.d
)
SELECT v.atom_id, b.debut, v.an, v.d,
       min(v.circo)              AS circo,
       count(*)                  AS voisins
  FROM voisin v
  LEFT JOIN sc_debut b ON b.atom_id = v.atom_id
 GROUP BY v.atom_id, b.debut, v.an, v.d
HAVING count(DISTINCT v.circo) = 1;

-- ---------------------------------------------------------------------------
-- 4. Recoller les années consécutives en périodes
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_periode;
CREATE TEMP TABLE sc_periode AS
WITH marque AS (
    SELECT *,
           an - row_number() OVER (PARTITION BY atom_id, circo ORDER BY an)
               AS groupe
      FROM sc_dicte
)
SELECT atom_id, circo, debut,
       make_date(min(an), 1, 1)     AS valid_from,
       make_date(max(an) + 1, 1, 1) AS valid_to,
       round(avg(voisins))::int     AS voisins
  FROM marque
 GROUP BY atom_id, circo, debut, groupe;

-- Garde-fou 5 : ne jamais emprunter une unité en dehors de sa propre vie.
--
-- Les périodes sont recollées par années CIVILES, mais deux découpages
-- électoraux commencent en cours d'année. Une année dictée au 1er décembre
-- 2012 produisait ainsi la période [2012-01-01, 2013-01-01) sur une unité
-- `@2009` qui n'existe que depuis le 10 juin — et, symétriquement, l'ancienne
-- version posait `55-02@1986` jusqu'en 2013 sur les villages détruits de la
-- Meuse, alors que ce découpage s'arrête en juin 2012.
--
-- On borne donc chaque période à l'intervalle où l'unité a RÉELLEMENT des
-- membres ailleurs. C'est une mesure, pas une convention : si personne d'autre
-- ne relève de cette circonscription à cette date, elle n'existe pas.
DROP TABLE IF EXISTS sc_vie;
CREATE TEMP TABLE sc_vie AS
SELECT unit_id, min(valid_from) AS debut, max(valid_to) AS fin
  FROM membership WHERE niveau = 'circo' GROUP BY unit_id;

UPDATE sc_periode p
   SET valid_from = greatest(p.valid_from, v.debut),
       valid_to   = least(p.valid_to,   v.fin)
  FROM sc_vie v
 WHERE v.unit_id = p.circo;

DELETE FROM sc_periode WHERE valid_from >= valid_to;

-- Et refermer la couture que le bornage vient d'ouvrir.
--
-- Reculer le début de l'îlot suivant laisse un trou derrière lui : les
-- villages détruits de la Meuse sortaient avec `55-02@1986` jusqu'au
-- 1er janvier 2012 puis `55-02@2009` à partir du 10 juin, et rien entre les
-- deux — alors qu'ils relevaient bien de l'ancienne circonscription jusqu'au
-- 9 juin.
--
-- On referme donc chaque période sur la suivante, **à la stricte condition que
-- le trou tienne dans une seule année civile**. C'est ce qui distingue une
-- couture d'un vrai vide : le trou d'Alsace-Moselle, de 1871 à 1919, traverse
-- quarante-huit ans et ne doit jamais être refermé. La condition sur l'année
-- est le garde-fou, et elle est vérifiable d'un coup d'œil.
UPDATE sc_periode p
   SET valid_to = least(s.suivant, v.fin)
  FROM (SELECT atom_id, circo, valid_from,
               lead(valid_from) OVER (PARTITION BY atom_id ORDER BY valid_from)
                   AS suivant
          FROM sc_periode) s,
       sc_vie v
 WHERE s.atom_id = p.atom_id AND s.circo = p.circo
   AND s.valid_from = p.valid_from
   AND v.unit_id = p.circo
   AND s.suivant IS NOT NULL
   AND s.suivant > p.valid_to
   AND date_trunc('year', s.suivant) = date_trunc('year', p.valid_to);

-- Garde-fou 4 : ne jamais chevaucher un rattachement déjà présent. La
-- contrainte EXCLUDE le refuserait de toute façon, mais autant ne pas lui
-- faire annuler la transaction entière.
DELETE FROM sc_periode p
 WHERE EXISTS (
    SELECT 1 FROM membership m
     WHERE m.atom_id = p.atom_id AND m.niveau = 'circo'
       AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

\echo ''
\echo '=== 1. Ce qui va être posé ==='
SELECT count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM sc_periode;

-- ---------------------------------------------------------------------------
-- 5. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, circo, 'circo', valid_from, valid_to
      FROM sc_periode
    RETURNING membership_id, atom_id, unit_id, valid_from, valid_to
)
INSERT INTO scission_circo_trace (membership_id, atom_id, unit_id,
                                  valid_from, valid_to, debut_reel, voisins)
SELECT i.membership_id, i.atom_id, i.unit_id, i.valid_from, i.valid_to,
       p.debut, p.voisins
  FROM ins i
  JOIN sc_periode p ON p.atom_id = i.atom_id
                   AND p.circo   = i.unit_id
                   AND p.valid_from = i.valid_from;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Posé, par décennie d''apparition réelle ==='
SELECT coalesce(((extract(year FROM debut_reel)::int / 10) * 10)::text,
                'aucune circo native') AS decennie,
       count(DISTINCT atom_id) AS atomes, count(*) AS periodes
  FROM scission_circo_trace GROUP BY 1 ORDER BY 1;
-- La ligne « aucune circo native » est le premier angle mort réparé : ces
-- atomes n'avaient AUCUNE circonscription, à aucune date, et l'ancienne
-- sélection ne pouvait pas les voir. Attendu de l'ordre de 270 atomes.

\echo ''
\echo '=== 2bis. Villeneuve-la-Garenne, témoin du trou INTÉRIEUR ==='
SELECT m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 40' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  LEFT JOIN scission_circo_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '92078' AND m.niveau = 'circo'
 ORDER BY m.valid_from;
-- Née en 1929 par détachement de Gennevilliers (Wikipédia, fiche Cassini
-- 40353). Attendu : plus aucune interruption entre 1870 et 1941. Le bloc
-- 1893-1928 doit porter « posé par 40 » ; sa mère, elle, a toujours eu la
-- chaîne complète — ce n'était donc pas un manque de source.

\echo ''
\echo '=== 3. Arrien-en-Bethmale, le cas qui a révélé le défaut ==='
SELECT m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 40' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  LEFT JOIN scission_circo_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '09017' AND m.niveau = 'circo'
 ORDER BY m.valid_from;
-- Attendu : une chaîne continue depuis 1870, alternant L0901@1870 et
-- U0903@1876 au rythme des changements de mode de scrutin, puis la ligne
-- native de 1931.

\echo ''
\echo '=== 4. Aucun atome dans deux circos à la même date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode
          FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0.

\echo ''
\echo '=== 5. Trou résiduel : atomes sans circo alors qu''ils ont un canton ==='
SELECT (extract(year FROM d)::int) AS annee,
       count(*) AS atomes_sans_circo
  FROM (VALUES ('1870-06-01'::date), ('1890-06-01'), ('1910-06-01'),
               ('1930-06-01')) v(d)
  JOIN membership mc ON mc.niveau = 'canton' AND mc.periode @> v.d
 WHERE NOT EXISTS (SELECT 1 FROM membership mi
                    WHERE mi.atom_id = mc.atom_id AND mi.niveau = 'circo'
                      AND mi.periode @> v.d)
 GROUP BY 1 ORDER BY 1;
-- Ce qui reste doit être l'Alsace-Moselle et les cantons dont aucun membre
-- n'avait de circonscription. À comparer au même chiffre AVANT le passage.

\echo ''
\echo '=== 6. Avant / après : ce que le correctif a comblé ==='
-- Le trou d'AVANT ne se mesure plus directement, le correctif étant posé. Mais
-- la trace le reconstitue : il suffit d'ajouter au trou résiduel le nombre
-- d'atomes que 40 couvre à cette date.
WITH dates(d) AS (
    VALUES ('1870-06-01'::date), ('1890-06-01'), ('1910-06-01'), ('1930-06-01')
),
reste AS (
    SELECT d, count(*) AS apres
      FROM dates
      JOIN membership mc ON mc.niveau = 'canton' AND mc.periode @> d
     WHERE NOT EXISTS (SELECT 1 FROM membership mi
                        WHERE mi.atom_id = mc.atom_id AND mi.niveau = 'circo'
                          AND mi.periode @> d)
     GROUP BY d
),
comble AS (
    SELECT d, count(DISTINCT t.atom_id) AS pose
      FROM dates
      JOIN scission_circo_trace t
        ON daterange(t.valid_from, t.valid_to, '[)') @> d
     GROUP BY d
)
SELECT extract(year FROM r.d)::int          AS annee,
       r.apres + coalesce(c.pose, 0)        AS trou_avant,
       coalesce(c.pose, 0)                  AS comble_par_40,
       r.apres                              AS trou_apres,
       round(100.0 * coalesce(c.pose, 0)
             / nullif(r.apres + coalesce(c.pose, 0), 0), 1) AS pct_comble
  FROM reste r LEFT JOIN comble c USING (d)
 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 7. Pour défaire
--
--   DELETE FROM membership m USING scission_circo_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE scission_circo_trace;
-- ---------------------------------------------------------------------------

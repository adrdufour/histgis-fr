-- ============================================================================
-- 47_circo_mere.sql — la circonscription de la MÈRE, quand les voisins se taisent
--
--   psql -d histgis -f sql/47_circo_mere.sql        # depuis la RACINE
--
-- Ce qu'il complète
-- -----------------
-- `40_scission_circo.sql` comble les trous de la couche circo par l'unanimité
-- des VOISINS DE CANTON. C'est une réponse par procuration, et elle est muette
-- dans un cas : quand aucun autre membre du canton n'a lui-même de
-- circonscription à cette date.
--
-- Le cas pur, trouvé le 20 août 2026 sur la carte
-- -----------------------------------------------
-- **Port-Saint-Louis-du-Rhône**, née en 1904 par détachement d'Arles, n'a
-- aucune circonscription de 1870 à 1901. Son canton 1304 ne compte alors que
-- deux membres : elle, et une FRACTION d'Arles — laquelle n'a pas de
-- circonscription précisément parce que le garde-fou 3 de `40` écarte les
-- fractions. Le voisin unique est muet par construction : la circularité est
-- parfaite, et aucun élargissement de `40` ne l'ouvrirait.
--
-- Pourtant la réponse est à côté. L'atome PLEIN d'Arles, `1256`, porte une
-- chaîne continue de 1870 à 1941. Le territoire de Port-Saint-Louis étant
-- arlésien jusqu'en 1904, il relevait de ces circonscriptions-là.
--
-- La règle
-- --------
--   « Quand un atome plein n'a pas de circonscription, que ses voisins de
--     canton n'en ont pas non plus, et que la mère nommée par HAC en a une
--     seule à cette date, l'atome reçoit celle de sa mère. »
--
-- C'est le principe de `46_creation_serie.sql` — la filiation répond mieux que
-- la procuration — porté sur la couche électorale.
--
-- Pourquoi une règle et non un cas nommé
-- --------------------------------------
-- `48_diag_mere_muette.sql` a mesuré la classe AVANT que ce fichier soit
-- écrit : **32 années-communes, un seul atome**. Il aurait donc été tentant
-- d'inscrire Port-Saint-Louis en dur, comme `44_absorption_ancienne.sql` le
-- fait pour Cherré. Deux raisons de ne pas le faire.
--
-- La première est que la classe n'est petite qu'AUJOURD'HUI. Elle est tenue
-- basse par le garde-fou 3 de `40`, qui prive 243 fractions de
-- circonscription ; le jour où celles-ci en recevront une — après
-- ANR-COMMUNES — d'autres communes cesseront d'avoir des voisins muets, mais
-- d'autres encore apparaîtront. Une règle s'adapte, une liste non.
--
-- La seconde est qu'une règle mesurée se réfute. Si elle se met un jour à
-- poser des dizaines de cas douteux, la recette 2 le montrera. Un cas écrit en
-- dur ne dit jamais qu'il a cessé d'être vrai.
--
-- Six garde-fous
-- --------------
--   1. Atomes PLEINS seulement. Les fractions restent hors jeu tant qu'elles
--      partagent le polygone de leur mère — 14 281 km² seraient dessinés deux
--      fois. Décision du 20 août 2026, à rouvrir le 1er septembre.
--   2. Les voisins de canton doivent être MUETS. Là où `40` sait répondre, il
--      répond ; ce fichier ne le contredit jamais, il ramasse derrière lui.
--   3. La filiation vient de HAC, résolue de façon UNIQUE (`voie = 'unique'`).
--   4. La mère est retrouvée par son `cassini`, jamais par son nom.
--   5. La mère doit avoir UNE SEULE circonscription à cette date. Une mère
--      partagée entre deux circos ne dit pas laquelle vaut pour la fille.
--   6. Rien n'est posé sur une période déjà occupée.
--
-- Et un contrôle gratuit, en recette 3
-- ------------------------------------
-- Port-Saint-Louis porte NATIVEMENT `U1303@1902` à partir de 1902. La chaîne
-- de sa mère s'arrête sur `U1303@1889`, qui court jusqu'en 1902. Les deux se
-- raccordent donc sans rupture ni chevauchement, sur la même circonscription
-- de Bouches-du-Rhône. **La donnée confirme la filiation d'elle-même**, sans
-- que HAC ni Wikipédia aient à être crus sur parole. C'est le contraire du
-- piège de Cherré, où le témoin était resté muet.
--
-- Réversible : `circo_mere_trace`, section 5.
-- Rejouable : retire son propre passage avant de recommencer.
-- Prérequis : `40` et `46` joués — `hac_filiation` est créée par `46`.
-- Place dans la chaîne : APRÈS `46`, AVANT `40`. Une réponse directe passe
-- toujours avant une réponse par procuration.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.hac_filiation') IS NULL THEN
        RAISE EXCEPTION 'hac_filiation absente : jouer 46_creation_serie.sql '
                        'avant (c''est lui qui charge la filiation HAC).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS circo_mere_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    cassini_mere  text NOT NULL,
    nom_mere_hac  text,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_mere_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE circo_mere_trace;

-- ---------------------------------------------------------------------------
-- 1. Les années où la couche circo existe
--
-- Bornée par la donnée et non par une constante : entre 1941 et 1986 il n'y a
-- AUCUNE circonscription dans la base, et l'absence n'y est pas un trou. Sans
-- ce filtre, chaque atome serait candidat sur quarante-cinq ans.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_annee;
-- Échantillonné au 1er décembre, comme `40_scission_circo` et comme
-- `MOIS_JOUR` dans `cartes/export_web.py` : deux bornes de la couche circo
-- tombent en cours d'année (24 novembre 1986, 10 juin 2012), et les trois
-- doivent regarder l'année à la même date.
CREATE TEMP TABLE cm_annee AS
SELECT y, make_date(y, 12, 1) AS d
  FROM generate_series(
           extract(year FROM (SELECT min(valid_from) FROM membership))::int,
           extract(year FROM (SELECT max(valid_to)   FROM membership))::int - 1
       ) y
 WHERE EXISTS (SELECT 1 FROM membership mx
                WHERE mx.niveau = 'circo'
                  AND mx.periode @> make_date(y, 12, 1));

-- ---------------------------------------------------------------------------
-- 2. Garde-fous 1 et 2 : atome plein, sans circo, dont les voisins se taisent
-- ---------------------------------------------------------------------------
-- EN DEUX TEMPS, et ce n'est pas une coquetterie.
--
-- La première version fondait les deux conditions dans une seule requête. Le
-- planificateur appliquait alors le test des voisins — corrélé sur le canton,
-- donc coûteux — à l'ensemble du produit années × atomes, soit des millions de
-- lignes. Le fichier a tourné vingt minutes sans rendre la main, pour poser
-- quatre lignes. `48_diag_mere_muette.sql`, qui fait le même calcul en deux
-- temps, répond en quelques secondes.
--
-- Réduire d'abord, tester ensuite : la table des trous est petite (quelques
-- dizaines de milliers de lignes), et c'est à elle seule qu'on demande ce que
-- disent les voisins.
-- PARTIR DE LA FILIATION, et non des années.
--
-- Ce fichier ne peut poser que là où HAC nomme une mère de façon unique :
-- `hac_filiation` compte 444 lignes, quand le produit années × atomes en
-- compte 3,6 millions. Conduire la requête par la table la plus sélective
-- réduit le problème d'un facteur mille.
--
-- La première version balayait tous les couples année × atome avant de
-- confronter à la filiation. Elle a tourné six minutes sans finir, le
-- 20 août 2026 — la deuxième fois dans la même soirée que je place le filtre
-- coûteux avant le filtre sélectif. **L'ordre des jointures n'est pas un
-- détail d'optimisation : c'est la différence entre une requête et une attente.**
DROP TABLE IF EXISTS cm_trou;
CREATE TEMP TABLE cm_trou AS
SELECT mc.atom_id, a.cassini, y.y, y.d, mc.unit_id AS canton
  FROM hac_filiation f
  JOIN atom a ON a.cassini = f.cassini_fille AND NOT a.fraction
  JOIN membership mc ON mc.atom_id = a.atom_id AND mc.niveau = 'canton'
  JOIN cm_annee y ON mc.periode @> y.d
 WHERE f.voie = 'unique'
   AND NOT EXISTS (SELECT 1 FROM membership mx
                    WHERE mx.atom_id = mc.atom_id AND mx.niveau = 'circo'
                      AND mx.periode @> y.d);

CREATE INDEX cm_trou_idx ON cm_trou (canton, d);
ANALYZE cm_trou;

DROP TABLE IF EXISTS cm_muet;
CREATE TEMP TABLE cm_muet AS
SELECT t.*
  FROM cm_trou t
 WHERE NOT EXISTS (
       SELECT 1 FROM membership mk
         JOIN membership mv ON mv.atom_id = mk.atom_id AND mv.niveau = 'circo'
                           AND mv.periode @> t.d
        WHERE mk.niveau = 'canton' AND mk.unit_id = t.canton
          AND mk.atom_id <> t.atom_id AND mk.periode @> t.d);

ANALYZE cm_muet;

-- ---------------------------------------------------------------------------
-- 3. Garde-fous 3, 4 et 5 : ce que dit la mère, si elle dit une seule chose
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_dicte;
CREATE TEMP TABLE cm_dicte AS
SELECT m.atom_id, m.y, f.cassini_mere, f.nom_mere_hac,
       min(mv.unit_id) AS circo
  FROM cm_muet m
  JOIN hac_filiation f ON f.cassini_fille = m.cassini AND f.voie = 'unique'
  JOIN atom am ON am.cassini = f.cassini_mere AND NOT am.fraction
  JOIN membership mv ON mv.atom_id = am.atom_id AND mv.niveau = 'circo'
                    AND mv.periode @> m.d
 GROUP BY m.atom_id, m.y, f.cassini_mere, f.nom_mere_hac
HAVING count(DISTINCT mv.unit_id) = 1;

-- ---------------------------------------------------------------------------
-- 4. Recoller les années consécutives en périodes
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cm_periode;
CREATE TEMP TABLE cm_periode AS
WITH marque AS (
    SELECT *,
           y - row_number() OVER (PARTITION BY atom_id, circo ORDER BY y)
               AS groupe
      FROM cm_dicte
)
SELECT atom_id, circo, cassini_mere, nom_mere_hac,
       make_date(min(y), 1, 1)     AS valid_from,
       make_date(max(y) + 1, 1, 1) AS valid_to
  FROM marque
 GROUP BY atom_id, circo, cassini_mere, nom_mere_hac, groupe;

-- Garde-fou 7 : ne jamais emprunter une unité en dehors de sa propre vie.
-- Les périodes sont recollées par années civiles, mais deux découpages
-- électoraux commencent en cours d'année. Même raisonnement et même remède
-- qu'au garde-fou 5 de `40_scission_circo.sql`.
DROP TABLE IF EXISTS cm_vie;
CREATE TEMP TABLE cm_vie AS
SELECT unit_id, min(valid_from) AS debut, max(valid_to) AS fin
  FROM membership WHERE niveau = 'circo' GROUP BY unit_id;

UPDATE cm_periode p
   SET valid_from = greatest(p.valid_from, v.debut),
       valid_to   = least(p.valid_to,   v.fin)
  FROM cm_vie v
 WHERE v.unit_id = p.circo;

DELETE FROM cm_periode WHERE valid_from >= valid_to;

-- Refermer la couture ouverte par le bornage, uniquement si le trou tient dans
-- une seule année civile. Même raisonnement qu'en `40_scission_circo.sql` :
-- une couture se referme, un vide de quarante-huit ans ne se referme pas.
UPDATE cm_periode p
   SET valid_to = least(s.suivant, v.fin)
  FROM (SELECT atom_id, circo, valid_from,
               lead(valid_from) OVER (PARTITION BY atom_id ORDER BY valid_from)
                   AS suivant
          FROM cm_periode) s,
       cm_vie v
 WHERE s.atom_id = p.atom_id AND s.circo = p.circo
   AND s.valid_from = p.valid_from
   AND v.unit_id = p.circo
   AND s.suivant IS NOT NULL
   AND s.suivant > p.valid_to
   AND date_trunc('year', s.suivant) = date_trunc('year', p.valid_to);

-- Garde-fou 6 : ne jamais chevaucher un rattachement déjà présent. La
-- contrainte EXCLUDE le refuserait, mais autant ne pas lui faire annuler la
-- transaction entière.
DELETE FROM cm_periode p
 WHERE EXISTS (
    SELECT 1 FROM membership m
     WHERE m.atom_id = p.atom_id AND m.niveau = 'circo'
       AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

\echo ''
\echo '=== 1. Ce qui va etre pose ==='
SELECT count(*) AS periodes, count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM cm_periode;
-- Mesure du 20 aout 2026, avant ecriture : 4 periodes, 1 atome, 1870 -> 1902.

-- ---------------------------------------------------------------------------
-- 5. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, circo, 'circo', valid_from, valid_to
      FROM cm_periode
    RETURNING membership_id, atom_id, unit_id, valid_from, valid_to
)
INSERT INTO circo_mere_trace (membership_id, atom_id, unit_id,
                              valid_from, valid_to, cassini_mere, nom_mere_hac)
SELECT i.membership_id, i.atom_id, i.unit_id, i.valid_from, i.valid_to,
       p.cassini_mere, p.nom_mere_hac
  FROM ins i
  JOIN cm_periode p ON p.atom_id = i.atom_id
                   AND p.circo   = i.unit_id
                   AND p.valid_from = i.valid_from;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 6. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 2. Qui a recu quoi, et de quelle mere ==='
SELECT coalesce(n.nom, '?') AS commune, coalesce(n.dep, '?') AS dep,
       t.nom_mere_hac AS mere, count(*) AS periodes,
       min(t.valid_from) AS de, max(t.valid_to) AS a
  FROM circo_mere_trace t
  JOIN atom a ON a.atom_id = t.atom_id
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
 GROUP BY 1, 2, 3 ORDER BY periodes DESC, 2, 1;
-- Si cette liste s'allonge un jour au-dela de quelques communes, la relire
-- avant de la croire : la regle vaut par sa rarete autant que par sa logique.

\echo ''
\echo '=== 3. Port-Saint-Louis-du-Rhone : la jonction avec la chaine native ==='
SELECT m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NOT NULL THEN 'pose par 47 (mere Arles)'
            WHEN s.membership_id IS NOT NULL THEN 'pose par 40 (voisins)'
            ELSE '' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  LEFT JOIN circo_mere_trace   t ON t.membership_id = m.membership_id
  LEFT JOIN scission_circo_trace s ON s.membership_id = m.membership_id
 WHERE a.insee_geofla = '13078' AND m.niveau = 'circo'
 ORDER BY m.valid_from;
-- CONTROLE : la derniere ligne posee par 47 doit etre U1303@1889, se fermant
-- exactement ou s'ouvre la ligne NATIVE U1303@1902. Meme circonscription, pas
-- de trou, pas de chevauchement. La donnee confirme la filiation d'elle-meme.
-- Si la jonction ne se fait pas, la filiation est a rouvrir — pas a forcer.

\echo ''
\echo '=== 4. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode
          FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;
-- Attendu : 0.

\echo ''
\echo '=== 5. Pour tout defaire ==='
\echo '    DELETE FROM membership m USING circo_mere_trace t'
\echo '     WHERE t.membership_id = m.membership_id;'
\echo '    TRUNCATE circo_mere_trace;'

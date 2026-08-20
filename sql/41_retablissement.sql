-- ============================================================================
-- 41_retablissement.sql — les communes rétablies après 1999
--
--   psql -d histgis -f sql/41_retablissement.sql
--
-- Le défaut, trouvé le 17 août 2026 par Ouézy
-- -------------------------------------------
-- Ouézy (14482), dans le Calvados, est absente de la base entre 1999 et 2006.
-- Ce n'est pas une erreur : **elle n'existait pas**. `insee_mvt` le dit sans
-- ambiguïté :
--
--   1972-01-01  mod 33  14482 Ouézy -> 14149 Cesny-aux-Vignes-Ouézy
--   2006-01-01  mod 21  14149 Cesny-aux-Vignes-Ouézy -> 14482 Ouézy
--
-- Fusionnée-associée en 1972 sous la loi Marcellin, rétablie en 2006. Le COG de
-- 1999 ne connaît que 14149, et la base le suit fidèlement.
--
-- **Mais son polygone, lui, existe.** GEOFLA 2011 porte 14482 séparément,
-- puisque le rétablissement est antérieur au millésime. Entre 1999 et 2006, ce
-- polygone n'a donc aucun rattachement : un trou de couverture de la taille de
-- la commune, dans la couche moderne.
--
-- C'est le MIROIR exact du défaut d'Arrien-en-Bethmale, corrigé par
-- `40_scission_circo.sql`. Là, une commune née après le début de la série
-- laissait un trou en amont ; ici, une commune disparue puis rétablie laisse un
-- trou en aval. `11_scission.sql` prolonge vers l'arrière ; rien ne prolongeait
-- vers l'avant.
--
-- L'ampleur, mesurée avant d'écrire
-- ---------------------------------
--   66 communes de GEOFLA 2011 sont absentes du COG 1999
--   21 d'entre elles sont des RÉTABLISSEMENTS datés (mod 21), de 2000 à 2008
--
-- Bercenay-le-Hayer et Trancault (2000), Ousse, Sendets, Ruffiac, Plottes,
-- Draillant (2001), Mauvezin-sur-Gupie (2003), Brabant et Brocourt-en-Argonne
-- (2004), Trémilly (2005), Ouézy et Cuislès (2006), Bosselshausen (2007),
-- Liéoux, Saint-Symphorien, Verquigneul, Rosoy (2008) — la queue des fusions
-- Marcellin de 1971-72, défaites une à une.
--
-- Les 45 autres ne sont pas des rétablissements et ne sont pas traitées ici :
-- elles relèvent d'autres mécanismes, à examiner séparément.
--
-- La faute du premier jet, et sa réparation
-- -----------------------------------------
-- Le commentaire ci-dessus annonçait 21 cas ; **la requête en a sorti 38, parce
-- qu'elle ne croisait jamais la liste des communes absentes du COG 1999**. Elle
-- prenait tout `mod = '21'` postérieur à 1999, y compris des communes bien
-- vivantes en 1999, fusionnées bien plus tard et rétablies ensuite : Bihorel
-- (fusionnée en 2012), 14114 (2017), Sannerville, Villotran, L'Oie, les quatre
-- du Cantal. Pour celles-là la fenêtre `[1999, rétablissement)` couvre des
-- années où la commune existait de plein droit.
--
-- Le garde-fou 3 en a écarté douze sur quatorze — mais **parce que la période
-- était occupée, pas parce que la fenêtre était fausse**. Il a donc laissé
-- passer exactement les cas où la commune existait ET avait un trou : cinq
-- lignes, trois pour 14114 et deux pour Bihorel.
--
-- D'où le garde-fou 5 : la fenêtre ne commence pas au début de la couche
-- moderne, elle commence **à la date où la commune a réellement disparu**, lue
-- dans `insee_mvt` et plafonnée par ce début. Pour la queue Marcellin — les 21
-- cas visés — l'absorption date de 1972-74 et rien ne change. Pour les autres
-- la fenêtre se réduit à la vraie parenthèse de fusion, souvent vide.
--
-- Règle générale, portée dans `METHODE.md` : **un garde-fou qui rattrape une
-- règle fausse donne un résultat juste et une méthode fausse.** Il faut réparer
-- la règle, sans quoi le prochain cas qui échappe au garde-fou passe.
--
-- La règle, et pourquoi elle est plus sûre que celle de 40
-- -------------------------------------------------------
--   « Entre le début de la couche moderne et sa date de rétablissement, la
--     commune reçoit les rattachements de la commune qui l'absorbait. »
--
-- Ici **la filiation est donnée par la source**, elle n'est pas déduite.
-- `insee_mvt` nomme explicitement la commune absorbante (`com_av`) et la date
-- (`date_eff`). Là où `40` devait passer par les voisins de canton et se
-- contenter d'une unanimité, `41` lit un fait.
--
-- Ce qu'on suppose quand même : que le territoire de la commune associée
-- suivait le rattachement de la commune absorbante. C'est vrai par
-- construction — une commune associée n'a pas de rattachement propre, elle est
-- une fraction de l'absorbante — donc l'hypothèse est ici plus faible que
-- partout ailleurs dans la chaîne.
--
-- Cinq garde-fous
-- ---------------
--   1. Seuls les mouvements `mod = '21'` (rétablissement) postérieurs à 1999.
--   2. `com_av <> com_ap` : `insee_mvt` écrit aussi une ligne où la commune
--      rétablie figure des deux côtés, et la prendre ferait hériter la commune
--      d'elle-même.
--   3. On ne pose rien sur une période déjà occupée. La contrainte EXCLUDE le
--      refuserait, mais autant ne pas lui faire annuler la transaction.
--   4. On ne pose que si l'absorbante a effectivement un rattachement sur la
--      période. Sans quoi il n'y a rien à hériter, et on se tait.
--   5. La fenêtre commence à la date d'ABSORPTION, pas au début de la couche
--      moderne. Et si `insee_mvt` n'atteste aucune absorption de la commune par
--      cette mère avant le rétablissement, **le cas est abandonné** : la
--      filiation n'est alors pas établie dans le sens supposé, et tout le
--      fichier repose sur le fait qu'elle le soit.
--   6. Le polygone doit être ORPHELIN. Si l'empreinte géométrique de l'atome
--      est déjà portée par un autre atome rattaché sur la fenêtre, il n'y a pas
--      de trou : le remplir ferait compter le territoire deux fois.
--
-- Le garde-fou 6, et pourquoi la recette 5 ne suffisait pas
-- ---------------------------------------------------------
-- Sept communes rétablies en 2012 ou après — 52033, 52124, 52266, 52278, 52465,
-- 55138, 76601 — sont absentes de GEOFLA 2011, puisque le millésime précède
-- leur rétablissement. Leur atome existe quand même, par la route `successeur`,
-- **et il porte le polygone de la commune absorbante** : mesuré, leur aire est
-- exactement celle de la mère (93,1 km² contre 93,1 pour Val-de-Meuse, 23,2
-- contre 23,2 pour Terre-Natale, et ainsi des cinq autres).
--
-- Il n'y avait donc rien d'orphelin à raccrocher. Leur poser les rattachements
-- de la mère faisait réclamer le même polygone par deux atomes rattachés au même
-- canton — trois pour Val-de-Meuse, que 52033 et 52465 portent tous deux.
--
-- **La recette 5 ne pouvait pas le voir** : elle compare des unités, et il n'y a
-- aucun conflit d'unité — les atomes sont dans le MÊME canton. C'est un double
-- comptage de surface, pas une contradiction d'attribution. La limite n° 7 de
-- `METHODE.md` décrivait déjà ces atomes doublons comme du poids mort
-- inoffensif ; ce fichier les rendait nuisibles.
--
-- Le test se fait sur `md5(ST_AsEWKB(geom))`, l'empreinte du polygone — la même
-- clé que `14_cle_partage.sql`, et la seule qui ne suppose rien. Grouper par un
-- code aurait manqué le cas, puisque les codes diffèrent.
--
-- Deux voies ajoutées le 20 août 2026, après Ousse et Sendets
-- -----------------------------------------------------------
-- Adrien : « dans les Basses-Pyrénées, Ousse et Sendets disparaissent de 2000
-- à 2002 ». Les deux figuraient bien dans les cas retenus, et rien n'était
-- posé pour elles. Deux causes distinctes, mesurées avant d'écrire.
--
-- **A. La mère est coupée entre plusieurs cantons.** Idron, qui absorbait les
-- deux, est rangée par le COG de 1999 à 2001 dans DEUX cantons — Morlaàs et
-- Pau-Ouest — si bien que `24` lui a créé deux atomes-fractions. Toute son
-- attribution vit donc sur ces fractions, et la clause `NOT am.fraction`
-- ci-dessous ne voyait rien. **La réponse était là où le garde-fou refusait de
-- regarder.**
--
-- Or cette coupure n'est pas un obstacle : c'est l'INFORMATION. Le COG coupait
-- Idron parce qu'elle contenait deux anciennes communes de cantons différents.
-- Et le rapprochement est dicté par la source des deux côtés :
--
--   « La fille hérite de la fraction de sa mère dont l'unité est celle que la
--     fille porte elle-même une fois rétablie. »
--
-- Ousse porte Pau-Ouest en 2002, une fraction d'Idron porte Pau-Ouest en
-- 1999-2001 ; Sendets porte Morlaàs, l'autre fraction porte Morlaàs. Mesuré sur
-- les six cas concernés — Carolles, Ousse, Sendets, Mauvezin-sur-Gupie,
-- Verquigneul, Rosoy — **la correspondance est unique six fois sur six**, y
-- compris quand la mère est coupée en TROIS (Béthune, Sens). La règle ne
-- tranche donc aucun conflit : elle constate un accord, comme celle des voisins
-- de canton dans `40`. Sans correspondance unique, on s'abstient.
--
-- **B. L'acte ne tombe pas un 1er janvier.** La couche moderne est bâtie sur
-- les millésimes annuels du COG, mais `insee_mvt` date le rétablissement au
-- jour près. Entre les deux il reste un vide : Ousse est rétablie le 11 mars
-- 2001 et son canton ne commence qu'au 1er janvier 2002.
--
--   « Le premier rattachement moderne d'une commune rétablie commence à la
--     date de l'acte, non au 1er janvier du millésime qui l'enregistre. »
--
-- On n'invente aucune unité : on reporte en arrière celle que la commune porte
-- elle-même, jusqu'au jour où la source dit qu'elle a reparu. Sept communes de
-- plus — Liéoux, Draillant, Cuislès, Plottes, Ruffiac, Plévenon, et
-- Paroy-en-Othe dont le trou dure **un jour**, rétablie le 31 décembre 2003.
--
-- La colonne `provenance` de la trace dit par quelle voie chaque ligne est
-- venue : `mere`, `fraction` ou `raccord`.
--
-- Réversible : tout est tracé dans `retablissement_trace`, section 6.
-- Rejouable : le script retire ses propres lignes avant de recommencer.
-- Prérequis : la couche moderne chargée (`20`, `21`, `24`) et `insee_mvt` (06).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

DO $$
BEGIN
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE EXCEPTION 'insee_mvt absente : jouer 06_insee_mvt.sql avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 0. Trace, et retrait d'un éventuel passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS retablissement_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    unit_id       text NOT NULL,
    niveau        text NOT NULL,
    valid_from    date NOT NULL,
    valid_to      date NOT NULL,
    insee         char(5) NOT NULL,   -- la commune rétablie
    insee_mere    char(5) NOT NULL,   -- celle qui l'absorbait
    absorbee_le   date,               -- quand elle a disparu (garde-fou 5)
    retablie_le   date NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

-- Ajoutées après coup : les traces d'un passage antérieur ne les portent pas.
ALTER TABLE retablissement_trace ADD COLUMN IF NOT EXISTS absorbee_le date;
ALTER TABLE retablissement_trace ADD COLUMN IF NOT EXISTS provenance  text;

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM retablissement_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE retablissement_trace;

-- ---------------------------------------------------------------------------
-- 1. Les rétablissements, leur commune absorbante, et la DATE D'ABSORPTION
--
-- Une commune peut avoir été rétablie en plusieurs temps ; on retient le
-- PREMIER rétablissement postérieur au début de la couche moderne, celui qui
-- ferme la fenêtre à combler.
--
-- La fenêtre s'ouvre à l'absorption (garde-fou 5). `insee_mvt` la donne : le
-- dernier mouvement, antérieur au rétablissement, où la commune passe sous
-- cette mère-là. Le `greatest` la ramène au début de la couche moderne quand
-- l'absorption lui est antérieure — le cas Marcellin, qui est la cible.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ret_cas;
CREATE TEMP TABLE ret_cas AS
WITH debut AS (
    -- le début de la couche moderne, lu et non supposé
    SELECT min(m.valid_from) AS d0
      FROM membership m
      JOIN atom a USING (atom_id)
     WHERE m.valid_from >= DATE '1990-01-01'
),
brut AS (
    SELECT v.com_ap                       AS insee,
           v.com_av                       AS insee_mere,
           v.date_eff                     AS retablie_le,
           row_number() OVER (PARTITION BY v.com_ap ORDER BY v.date_eff) AS rang
      FROM insee_mvt v, debut
     WHERE v.mod = '21'                          -- rétablissement
       AND v.com_av <> v.com_ap                  -- garde-fou 2
       AND v.date_eff > debut.d0
),
absorbee AS (
    SELECT b.insee, b.insee_mere, b.retablie_le,
           (SELECT max(v.date_eff)
              FROM insee_mvt v
             WHERE v.com_av = b.insee            -- la commune y disparaît…
               AND v.com_ap = b.insee_mere       -- …au profit de CETTE mère
               AND v.date_eff < b.retablie_le) AS absorbee_le
      FROM brut b
     WHERE b.rang = 1
)
SELECT a.insee, a.insee_mere, a.retablie_le, a.absorbee_le,
       greatest(d.d0, a.absorbee_le) AS depuis
  FROM absorbee a, debut d
 -- garde-fou 5 : pas d'absorption attestée, pas de filiation, pas de cas.
 WHERE a.absorbee_le IS NOT NULL
   -- et une fenêtre vide ne se comble pas : la commune existait déjà.
   AND greatest(d.d0, a.absorbee_le) < a.retablie_le;

\echo ''
\echo '=== 1. Les cas retenus ==='
SELECT c.insee, coalesce(n.nom, '?') AS commune,
       c.insee_mere, coalesce(nm.nom, '?') AS mere,
       c.absorbee_le, c.depuis, c.retablie_le
  FROM ret_cas c
  LEFT JOIN noms_geofla n  ON n.insee  = c.insee
  LEFT JOIN noms_geofla nm ON nm.insee = c.insee_mere
 ORDER BY c.retablie_le, c.insee;
-- `depuis` > `absorbee_le` signale une fusion POSTÉRIEURE à 1999 : la fenêtre
-- ne couvre alors que la parenthèse de fusion, et non toute la couche moderne.

-- ---------------------------------------------------------------------------
-- 2. Ce que l'absorbante portait sur la fenêtre, découpé à la fenêtre
--
-- `*` intersecte deux `daterange` : le rattachement de la mère et la fenêtre
-- [début de la couche moderne, rétablissement). On ne prend donc jamais plus
-- que ce que la mère avait, ni plus que la fenêtre.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ret_periode;
CREATE TEMP TABLE ret_periode AS
SELECT af.atom_id                                   AS atom_id,
       mm.unit_id,
       mm.niveau,
       lower(mm.periode * daterange(c.depuis, c.retablie_le, '[)')) AS valid_from,
       upper(mm.periode * daterange(c.depuis, c.retablie_le, '[)')) AS valid_to,
       c.insee, c.insee_mere, c.absorbee_le, c.retablie_le,
       'mere'::text AS provenance
  FROM ret_cas c
  -- l'atome de la commune RÉTABLIE, celui qui porte le polygone orphelin
  JOIN atom af ON af.insee_geofla = c.insee AND NOT af.fraction
  -- l'atome de la commune ABSORBANTE, et ses rattachements sur la fenêtre
  JOIN atom am ON am.insee_geofla = c.insee_mere AND NOT am.fraction
  JOIN membership mm ON mm.atom_id = am.atom_id
                    AND mm.periode && daterange(c.depuis, c.retablie_le, '[)')
 WHERE NOT isempty(mm.periode * daterange(c.depuis, c.retablie_le, '[)'));

-- ---------------------------------------------------------------------------
-- 2 bis. Voie A : la mère n'a son unité que sur des atomes-FRACTIONS
--
-- On ne retient qu'une fraction, celle dont l'unité est exactement celle que la
-- fille porte elle-même une fois rétablie. Le rapprochement vient de la source
-- des deux côtés : la coupure est celle du COG, l'unité de la fille aussi.
--
-- La condition `NOT EXISTS (atome plein…)` réserve cette voie aux cas que la
-- section 2 n'a pas su traiter : là où la mère a un atome plein, il fait foi.
-- ---------------------------------------------------------------------------
INSERT INTO ret_periode
SELECT af.atom_id, mm.unit_id, mm.niveau,
       lower(mm.periode * daterange(c.depuis, c.retablie_le, '[)')),
       upper(mm.periode * daterange(c.depuis, c.retablie_le, '[)')),
       c.insee, c.insee_mere, c.absorbee_le, c.retablie_le,
       'fraction'
  FROM ret_cas c
  JOIN atom af ON af.insee_geofla = c.insee      AND NOT af.fraction
  JOIN atom am ON am.insee_geofla = c.insee_mere AND     am.fraction
  JOIN membership mm ON mm.atom_id = am.atom_id
                    AND mm.periode && daterange(c.depuis, c.retablie_le, '[)')
 WHERE NOT isempty(mm.periode * daterange(c.depuis, c.retablie_le, '[)'))
   -- l'unité que la fille porte elle-même après son rétablissement
   AND mm.unit_id = (SELECT m2.unit_id FROM membership m2
                      WHERE m2.atom_id = af.atom_id
                        AND m2.niveau  = mm.niveau
                        AND m2.valid_from >= c.retablie_le
                      ORDER BY m2.valid_from LIMIT 1)
   -- et seulement si l'atome plein de la mère ne dit rien à ce niveau
   AND NOT EXISTS (SELECT 1
                     FROM atom ap
                     JOIN membership mp ON mp.atom_id = ap.atom_id
                    WHERE ap.insee_geofla = c.insee_mere AND NOT ap.fraction
                      AND mp.niveau = mm.niveau
                      AND mp.periode && daterange(c.depuis, c.retablie_le, '[)'));

-- ---------------------------------------------------------------------------
-- 2 ter. Voie B : raccorder l'acte au premier millésime
--
-- La couche moderne commence au 1er janvier du millésime qui enregistre la
-- commune ; l'acte, lui, est daté au jour près. On reporte en arrière l'unité
-- que la commune porte ELLE-MÊME, jusqu'au jour de sa réapparition. Aucune
-- unité n'est inventée.
--
-- `DISTINCT ON (atome, niveau)` : le premier rattachement propre à chaque
-- niveau, et lui seul.
-- ---------------------------------------------------------------------------
INSERT INTO ret_periode
SELECT DISTINCT ON (af.atom_id, m.niveau)
       af.atom_id, m.unit_id, m.niveau,
       c.retablie_le, m.valid_from,
       c.insee, c.insee_mere, c.absorbee_le, c.retablie_le,
       'raccord'
  FROM ret_cas c
  JOIN atom af ON af.insee_geofla = c.insee AND NOT af.fraction
  JOIN membership m ON m.atom_id = af.atom_id
                   AND m.valid_from > c.retablie_le
                   -- Le raccord ne va QUE jusqu'au premier 1er janvier suivant
                   -- l'acte : c'est le millésime qui enregistre la commune, et
                   -- c'est tout ce que la règle prétend expliquer.
                   --
                   -- Sans cette borne, la voie `raccord` reporterait en arrière
                   -- n'importe quel rattachement ultérieur. Ouézy, rétablie en
                   -- 2006, aurait reçu la circonscription de 2009 dès 2006 —
                   -- une unité qui n'existait pas encore, sur une période libre
                   -- que le garde-fou 3 laisse passer.
                   --
                   -- Vérifié sur les sept cas : le premier millésime tombe
                   -- exactement au 1er janvier suivant, sans exception.
                   AND m.valid_from = date_trunc(
                           'year', c.retablie_le + interval '1 year')::date
 ORDER BY af.atom_id, m.niveau, m.valid_from;

-- Garde-fou 3 : ne rien poser sur une période déjà occupée.
DELETE FROM ret_periode p
 WHERE EXISTS (
    SELECT 1 FROM membership m
     WHERE m.atom_id = p.atom_id AND m.niveau = p.niveau
       AND m.periode && daterange(p.valid_from, p.valid_to, '[)'));

-- ---------------------------------------------------------------------------
-- Garde-fou 6 : le polygone doit être orphelin.
--
-- On calcule l'empreinte des atomes candidats, puis on cherche tout AUTRE atome
-- de même empreinte déjà rattaché sur la fenêtre. S'il en existe un, le
-- territoire est déjà couvert et il n'y a pas de trou.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ret_empreinte;
CREATE TEMP TABLE ret_empreinte AS
SELECT DISTINCT p.atom_id, md5(ST_AsEWKB(g.geom)) AS empreinte
  FROM ret_periode p
  JOIN atom_geom g ON g.atom_id = p.atom_id;

DROP TABLE IF EXISTS ret_jumeau;
CREATE TEMP TABLE ret_jumeau AS
SELECT e.atom_id, g.atom_id AS jumeau
  FROM ret_empreinte e
  JOIN atom_geom g ON md5(ST_AsEWKB(g.geom)) = e.empreinte
                  AND g.atom_id <> e.atom_id;

\echo ''
\echo '=== 2 bis. Écartés par le garde-fou 6 : polygone déjà porté ==='
SELECT DISTINCT p.insee, coalesce(n.nom, '?') AS commune,
       p.insee_mere, j.jumeau AS atome_qui_porte_deja,
       round((ST_Area(g.geom) / 1e6)::numeric, 1) AS km2
  FROM ret_periode p
  JOIN ret_jumeau j ON j.atom_id = p.atom_id
  JOIN atom_geom g  ON g.atom_id = p.atom_id
  LEFT JOIN noms_geofla n ON n.insee = p.insee
 WHERE EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = j.jumeau AND m.niveau = p.niveau
                  AND m.periode && daterange(p.valid_from, p.valid_to, '[)'))
 ORDER BY 1;
-- Mesuré le 17 août 2026 : les sept communes de la route `successeur`.

DELETE FROM ret_periode p
 WHERE EXISTS (
    SELECT 1
      FROM ret_jumeau j
      JOIN membership m ON m.atom_id = j.jumeau
                       AND m.niveau  = p.niveau
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
     WHERE j.atom_id = p.atom_id);

-- Un atome rétabli peut correspondre à plusieurs atomes-mères (communes
-- absorbées puis refondues) : on ne garde qu'une ligne par (atome, niveau,
-- période), sans quoi la contrainte EXCLUDE ferait échouer la transaction.
DELETE FROM ret_periode a
 USING ret_periode b
 WHERE a.atom_id = b.atom_id AND a.niveau = b.niveau
   AND a.valid_from = b.valid_from
   AND a.unit_id > b.unit_id;

\echo ''
\echo '=== 2. Ce qui va être posé ==='
SELECT provenance, niveau, count(*) AS periodes,
       count(DISTINCT atom_id) AS atomes,
       min(valid_from) AS depuis, max(valid_to) AS jusqu_a
  FROM ret_periode GROUP BY 1, 2 ORDER BY 1, 2;
-- `mere`     : l'atome plein de l'absorbante, le cas ordinaire.
-- `fraction` : la mère était coupée entre plusieurs unités — six communes.
-- `raccord`  : entre l'acte et le premier millésime — sept communes.

-- ---------------------------------------------------------------------------
-- 3. Pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to
      FROM ret_periode
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO retablissement_trace (membership_id, atom_id, unit_id, niveau,
                                  valid_from, valid_to, insee, insee_mere,
                                  absorbee_le, retablie_le, provenance)
SELECT i.membership_id, i.atom_id, i.unit_id, i.niveau,
       i.valid_from, i.valid_to, p.insee, p.insee_mere,
       p.absorbee_le, p.retablie_le, p.provenance
  FROM ins i
  JOIN ret_periode p ON p.atom_id = i.atom_id
                    AND p.niveau  = i.niveau
                    AND p.valid_from = i.valid_from
                    AND p.unit_id = i.unit_id;

ANALYZE membership;

-- ---------------------------------------------------------------------------
-- 4. Recettes
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Posé, par commune ==='
SELECT t.insee, coalesce(n.nom, '?') AS commune, t.insee_mere,
       t.retablie_le, count(*) AS lignes,
       string_agg(DISTINCT t.niveau, ', ')     AS niveaux,
       string_agg(DISTINCT t.provenance, ', ') AS voies
  FROM retablissement_trace t
  LEFT JOIN noms_geofla n ON n.insee = t.insee
 GROUP BY 1, 2, 3, 4 ORDER BY t.retablie_le, t.insee;

\echo ''
\echo '=== 4. Ouézy, le cas qui a révélé le défaut ==='
SELECT m.niveau, m.unit_id, u.nom, m.valid_from, m.valid_to,
       CASE WHEN t.membership_id IS NULL THEN '' ELSE 'posé par 41' END AS origine
  FROM membership m
  JOIN atom a USING (atom_id)
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN retablissement_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla = '14482' AND m.valid_from >= DATE '1990-01-01'
 ORDER BY m.niveau, m.valid_from;
-- Attendu : une chaîne continue de 1999 à 2013, sans trou entre 1999 et 2006.

\echo ''
\echo '=== 5. Aucun atome dans deux unités du même niveau à la même date ==='
SELECT niveau, count(*) AS atomes_a_double
  FROM (SELECT atom_id, niveau, periode
          FROM membership GROUP BY 1, 2, 3
        HAVING count(DISTINCT unit_id) > 1) x
 GROUP BY niveau;
-- Attendu : aucune ligne, ou seulement les villes coupées déjà connues.

\echo ''
\echo '=== 6. Aucune ligne posée sur une année où la commune existait ==='
SELECT t.insee, t.niveau, t.valid_from, t.absorbee_le
  FROM retablissement_trace t
 WHERE t.valid_from < t.absorbee_le
 ORDER BY 1, 2, 3;
-- Attendu : aucune ligne. C'est la recette du garde-fou 5, et elle est la
-- seule qui distingue une règle juste d'un garde-fou chanceux.
--
-- Avant le garde-fou 5, mesuré le 17 août 2026 : cinq lignes fautives, trois
-- pour 14114 (absorbée en 2017, donc vivante de 1999 à 2017) et deux pour
-- Bihorel 76095 (absorbée en 2012). Les 36 autres étaient justes — absorptions
-- de 1972 à 1974, la queue Marcellin, entièrement sous la fenêtre.

\echo ''
\echo '=== 7. Aucun polygone réclamé deux fois — recette GÉOMÉTRIQUE ==='
SELECT t.insee, t.niveau, t.valid_from, t.atom_id, j.jumeau
  FROM retablissement_trace t
  JOIN ret_jumeau j ON j.atom_id = t.atom_id
 WHERE EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = j.jumeau AND m.niveau = t.niveau
                  AND m.periode && daterange(t.valid_from, t.valid_to, '[)'))
 ORDER BY 1, 2, 3;
-- Attendu : aucune ligne.
--
-- **Cette recette est indispensable et la recette 5 ne la remplace pas.** La 5
-- compare des unités : deux atomes portant le même polygone dans le MÊME canton
-- ne lui paraissent pas contradictoires, et pourtant le canton compte alors ce
-- territoire deux fois. Une recette d'attribution ne voit pas une erreur de
-- surface — il faut interroger la géométrie pour la voir.

\echo ''
\echo '=== 8. Ousse et Sendets, le cas qui a révélé les deux voies ==='
SELECT a.insee_geofla, coalesce(n.nom, '?') AS commune,
       m.unit_id, u.nom AS canton, m.valid_from, m.valid_to,
       coalesce(t.provenance, '') AS origine
  FROM atom a
  JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                   AND m.valid_to > DATE '1998-01-01'
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
  LEFT JOIN retablissement_trace t ON t.membership_id = m.membership_id
 WHERE a.insee_geofla IN ('64439', '64518') AND NOT a.fraction
 ORDER BY a.insee_geofla, m.valid_from;
-- Attendu : chaîne continue de 1999 à 2013 pour chacune. Ousse dans Pau-Ouest
-- (6431), Sendets dans Morlaàs (6423), les deux depuis 1999 — par la voie
-- `fraction` jusqu'au 11 mars 2001, par `raccord` jusqu'au 1er janvier 2002,
-- puis par la couche moderne.

\echo ''
\echo '=== 9. Trous restants entre 1999 et 2013 chez les communes traitées ==='
WITH lignes AS (
    SELECT DISTINCT t.insee, m.valid_from, m.valid_to
      FROM retablissement_trace t
      JOIN atom aa ON aa.insee_geofla = t.insee AND NOT aa.fraction
      JOIN membership m ON m.atom_id = aa.atom_id AND m.niveau = 'canton'
                       AND m.valid_to > DATE '1999-01-01'
),
trous AS (
    SELECT insee, valid_to AS de,
           lead(valid_from) OVER (PARTITION BY insee ORDER BY valid_from) AS a
      FROM lignes
    UNION ALL
    SELECT insee, DATE '1999-01-01', min(valid_from) FROM lignes GROUP BY insee
)
SELECT x.insee, coalesce(n.nom, '?') AS commune, x.de, x.a, x.a - x.de AS jours
  FROM trous x LEFT JOIN noms_geofla n ON n.insee = x.insee
 WHERE x.a IS NOT NULL AND x.a > x.de
 ORDER BY 5 DESC;
-- Attendu : aucune ligne.
--
-- Cette recette ne vaut QUE pour les communes que le fichier a traitées. Les
-- cinq de Haute-Marne écartées par le garde-fou 6 y montreraient un trou de
-- 1999 à 2012 qui n'en est pas un : leur atome porte le polygone de la mère,
-- déjà rattachée. C'est la règle de `METHODE.md` — interroger un atome ne
-- renseigne pas sur un territoire — et c'est pourquoi la jointure part de la
-- trace et non de la liste des communes.

-- ---------------------------------------------------------------------------
-- 5. Ce que ce fichier NE traite PAS
--
-- Les 45 autres communes de GEOFLA 2011 absentes du COG 1999 ne sont pas des
-- rétablissements. Elles peuvent être des créations postérieures, des
-- changements de code, ou des écarts de millésime entre GEOFLA et le COG. Les
-- traiter par la même règle serait leur appliquer une filiation que la source
-- ne donne pas.
--
-- Pour les lister :
--
--   SELECT n.insee, n.nom FROM noms_geofla n
--    WHERE NOT EXISTS (SELECT 1 FROM commune_moderne c
--                       WHERE c.code = n.insee AND c.valid_from <= '1999-06-01'
--                         AND c.valid_to > '1999-06-01')
--      AND NOT EXISTS (SELECT 1 FROM retablissement_trace t
--                       WHERE t.insee = n.insee);
--
-- ---------------------------------------------------------------------------
-- 6. Pour défaire
--
--   DELETE FROM membership m USING retablissement_trace t
--    WHERE t.membership_id = m.membership_id;
--   TRUNCATE retablissement_trace;
-- ---------------------------------------------------------------------------

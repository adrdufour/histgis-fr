-- ============================================================================
-- 92_meurthe_circo.sql — la Meurthe rend son numéro à l'étage circo aussi
--
--   psql -d histgis -f sql/92_meurthe_circo.sql
--
-- SANS `-1` : ce fichier ouvre et ferme sa propre transaction, comme `38` et
-- `39`.
--
-- CE QUE FAIT CE FICHIER, ET POURQUOI IL EXISTE
-- ---------------------------------------------
-- `39_meurthe_1870.sql` a rendu le numéro 54 aux 29 cantons de la Meurthe,
-- que TRF-GIS range sous un département « 99 » qui n'a jamais existé. Il a été
-- joué, tracé, déclaré clos le 2 septembre 2026 — et il l'est.
--
-- Mais sa clause `WHERE` porte `u.niveau = 'canton'`. Il reste donc **une
-- unité** en `99`, à l'étage des circonscriptions : `L9901@1870`, la Meurthe
-- au scrutin de liste, 714 rattachements sur [1870-01-01, 1871-01-01).
--
-- Cette unité seule suffisait à faire vivre un 99ᵉ département dans tout ce
-- qui énumère `SELECT DISTINCT dep FROM unit` — l'export web en premier, qui
-- lui fabriquait un dossier `donnees/dep/99/`.
--
-- **Et la conséquence n'était pas seulement un département de trop.** Elle se
-- lit dans les deux index de l'export du 6 septembre 2026 :
--
--     dep/99/index.json : {"annees": {"1870": {"c": "", "x": "eaf16c2a…"}}}
--     dep/54/index.json : {"annees": {"1870": {"c": "ed54effb…", "x": ""}}}
--
-- La Meurthe de 1870 était **coupée en deux** : ses cantons dans le 54, sa
-- circonscription dans un 99 sans cantons. Aucune des deux planches n'était
-- fausse ; c'est leur séparation qui l'était, et elle était invisible tant
-- qu'on ne les regardait pas ensemble.
--
-- *Un correctif qui vise un niveau laisse l'autre niveau derrière lui, et rien
-- ne le signale : la recette de `39` comptait les cantons, elle ne pouvait pas
-- voir ce qu'elle n'avait pas demandé.*
--
-- LA CIBLE EST L'IDENTIFIANT, PAS LE DÉPARTEMENT
-- -----------------------------------------------
-- Même raison qu'au § du même nom dans `39`, et elle vaut d'être répétée parce
-- qu'elle décide de ce que la trace dit. `unit_id` ne bouge jamais : viser
-- `dep = '99'` donnerait une trace VIDE sur une base où le travail est déjà
-- fait, c'est-à-dire exactement la fausse alarme « joué puis défait ? » que
-- `diag_passages.sql` cherche à supprimer. On vise donc le motif d'identifiant
-- `^[LU]99[0-9]{2}@`, et `avant` dit lequel des deux cas on était.
--
-- CE QUE CE FICHIER NE FAIT PAS
-- ------------------------------
-- **`unit_id` et `code` ne changent pas.** L'unité reste `L9901@1870`, de code
-- `9901`. La renuméroter en `5401` entrerait en collision avec `L5401@1871`,
-- la Meurthe-et-Moselle du même étage — et un identifiant est opaque. Le
-- département est un attribut, pas un préfixe : c'est la règle que `39` a
-- posée, ce fichier ne fait que l'appliquer une fois de plus.
--
-- **Il ne fusionne rien.** Les deux unités restent deux, et c'est le fait
-- historique : la Meurthe (1870-1871) et la Meurthe-et-Moselle (1871-1876) ne
-- couvrent ni le même territoire ni la même période. Leurs périodes sont
-- disjointes — `[1870-01-01, 1871-01-01)` et `[1871-01-01, 1876-01-01)` —,
-- donc une requête à date donnée reste sans ambiguïté, et la contrainte
-- `EXCLUDE` sur `membership` n'est pas sollicitée : on ne touche pas à
-- `membership`.
--
-- CE QU'IL FAUT SAVOIR AVANT DE LIRE LA CARTE
-- --------------------------------------------
-- Le département 54 change de territoire au 1er janvier 1871 sans changer de
-- numéro (voir `39`, § « Ce que cela implique »). Après ce fichier, ce fait
-- devient visible **aux deux étages au lieu d'un** : une planche du 54 en 1870
-- montrera 29 cantons et 1 circonscription sur l'emprise de la Meurthe, une
-- planche de 1871 montrera 32 cantons et 1 circonscription sur celle de la
-- Meurthe-et-Moselle. Deux emprises sous un même numéro, et c'est l'histoire,
-- pas un défaut.
--
-- CE QUI RESTE OUVERT
-- --------------------
-- Rien de neuf ici : le doublon `99`/`57` sur neuf noms de cantons annexés
-- (Albestroff, Château-Salins, Delme, Dieuze, Fénétrange, Lorquin, Phalsbourg,
-- Sarrebourg, Vic-sur-Seille) est signalé par `39` et n'est pas touché. Il
-- porte sur les cantons, pas sur la circonscription unique de cet étage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. DÉFAIRE LE PASSAGE PRÉCÉDENT
--
-- Une mise à jour ne se défait pas par un DELETE : `avant` garde le
-- département d'origine, et c'est lui qu'on restaure. Sur une base où ce
-- fichier n'est jamais passé, la table est vide et le geste est nul.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p92_trace (
    quoi  text NOT NULL,          -- 'unit_dep'
    cle   text NOT NULL,          -- unit_id, stable : jamais renuméroté
    avant text,                   -- le département d'avant le passage
    pose  timestamptz NOT NULL DEFAULT now()
);

UPDATE unit u
   SET dep = t.avant::char(2)
  FROM p92_trace t
 WHERE t.quoi = 'unit_dep' AND t.cle = u.unit_id;

TRUNCATE p92_trace;

\echo ''
\echo '-- 1 bis. état avant écriture (circo en 99 / en 54, toutes dates)'
SELECT count(*) FILTER (WHERE dep = '99') AS circos_en_99_avant,
       count(*) FILTER (WHERE dep = '54') AS circos_en_54_avant
  FROM unit WHERE niveau = 'circo';

-- ---------------------------------------------------------------------------
-- 2. LE DÉPARTEMENT RENDU, ET SA TRACE DANS LA MÊME INSTRUCTION
--
-- `avant` vaut `99` en dur, et non le département lu avant la mise à jour :
-- c'est ce que la source TRF-GIS avait posé, et donc ce à quoi un retrait doit
-- revenir. Même convention qu'en `39`, où elle est justifiée en toutes lettres.
-- ---------------------------------------------------------------------------
WITH maj AS (
    UPDATE unit u
       SET dep = '54'
     WHERE u.niveau = 'circo'
       AND (u.dep = '99' OR u.unit_id ~ '^[LU]99[0-9]{2}@')
    RETURNING u.unit_id
)
INSERT INTO p92_trace (quoi, cle, avant)
SELECT 'unit_dep', unit_id, '99' FROM maj;

COMMIT;

-- ===========================================================================
-- RECETTE
--
-- Les attendus ci-dessous sont datés du 6 septembre 2026 et tirés de
-- `build/unit_circo.csv` et `build/membership_circo.csv`, c'est-à-dire de ce
-- que le chargement pose. Un fichier joué depuis sur la couche circo les
-- déplacerait : c'est la leçon de la recette de `39`, dont l'attendu « 57 -> 51 »
-- a vieilli le jour où `60_canton_forbach2.sql` a créé un canton.
-- ===========================================================================
\echo ''
\echo '-- 3 a. la trace : 1 unité attendue (L9901@1870)'
SELECT count(*) AS unites_tracees, string_agg(cle, ', ') AS unites, min(pose) AS pose
  FROM p92_trace WHERE quoi = 'unit_dep';

\echo ''
\echo '-- 3 b. plus AUCUNE unité en 99, tous niveaux confondus (attendu : 0)'
SELECT niveau, count(*) AS unites
  FROM unit
 WHERE dep = '99'
 GROUP BY niveau
 ORDER BY niveau;
-- Attendu : zéro ligne. C'est ce contrôle-là qui décide de la disparition du
-- département 99 de l'export web, dont la liste vient de
-- `SELECT DISTINCT dep FROM unit`.

\echo ''
\echo '-- 3 c. la Meurthe au 1er juin 1870 : ses deux étages, dans le même 54'
SELECT u.niveau,
       count(DISTINCT u.unit_id) AS unites,
       count(*)                  AS rattachements
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
 WHERE u.dep = '54'
   AND m.periode @> DATE '1870-06-01'
 GROUP BY u.niveau
 ORDER BY u.niveau;
-- Attendu, mesuré sur `build/` le 6 septembre 2026 :
--   canton -> 29 unités ;
--   circo  ->  1 unité, 714 rattachements.
-- Avant ce fichier, la ligne `circo` était absente : c'est le trou que la
-- planche de 1870 montrait sans le dire.

\echo ''
\echo '-- 3 d. la bascule de 1871 : deux unités, deux périodes disjointes'
SELECT u.unit_id, u.nom, u.regime,
       min(m.valid_from) AS depuis, max(m.valid_to) AS jusqua,
       count(*)          AS rattachements
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
 WHERE u.dep = '54' AND u.niveau = 'circo'
   AND m.valid_from < DATE '1876-01-01'
 GROUP BY u.unit_id, u.nom, u.regime
 ORDER BY depuis;
-- Attendu : L9901@1870 « Meurthe » sur [1870-01-01, 1871-01-01), puis
-- L5401@1871 « Meurthe-et-Moselle » sur [1871-01-01, 1876-01-01). Les deux
-- bornes se touchent sans se recouvrir — c'est ce qui rend la date sans
-- ambiguïté malgré le numéro partagé.

\echo ''
\echo '-- 3 e. aucun atome dans deux circos du 54 à la même date (attendu : 0)'
SELECT count(*) AS atomes_a_double_dans_le_54
  FROM (SELECT m.atom_id, m.periode
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.niveau = 'circo' AND u.dep = '54'
         GROUP BY 1, 2
        HAVING count(DISTINCT m.unit_id) > 1) x;
-- Ce contrôle est en principe garanti par la contrainte `EXCLUDE USING gist`
-- de `membership`, qui ne regarde pas le département : on ne touche pas à
-- `membership`, donc il ne peut pas régresser. Il est ici parce qu'une
-- garantie qu'on ne mesure jamais finit par n'être qu'une croyance — et parce
-- qu'il coûte une seconde.

\echo ''
\echo '-- 3 f. le fait que la carte doit montrer : deux emprises sous le n° 54'
SELECT extract(year FROM d)::int AS annee,
       count(DISTINCT m.atom_id) AS atomes_du_54
  FROM (VALUES (DATE '1870-06-01'), (DATE '1871-06-01')) v(d)
  CROSS JOIN LATERAL (
       SELECT m.atom_id
         FROM membership m
         JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE u.dep = '54' AND m.niveau = 'canton' AND m.periode @> v.d
  ) m
 GROUP BY 1
 ORDER BY 1;
-- Ce n'est pas une alarme : le nombre DOIT changer. La Meurthe perd sa partie
-- est et gagne l'arrondissement de Briey au 1er janvier 1871. Un chiffre
-- identique d'une année à l'autre serait, lui, le signe que quelque chose
-- n'est pas passé.

-- ============================================================================
-- histgis — 101_paris_fractions_quartier.sql : les quartiers de Paris coupés
--                                              entre deux circonscriptions
--
--   psql -d histgis -f sql/101_paris_fractions_quartier.sql          (à blanc)
--   psql -d histgis -1 -v appliquer=1 -f sql/101_paris_fractions_quartier.sql
--
-- À JOUER APRÈS `52`-`57` (atomes `PQ01`…`PQ80`, unités de circonscription) ET
-- AVANT `98` : les ancres de `98` référencent les fractions posées ici.
--
-- CE QUE CE FICHIER COMBLE
-- ========================
-- `52`, `55` et `56` posent les quartiers ENTIERS et se contentent de nommer
-- ceux qu'une circonscription coupe (« Quartiers coupés, non posés ») : un
-- quartier cité dans deux circonscriptions n'a aucun rattachement pendant ce
-- régime, et manque à la carte. L'atlas donne pourtant les rues de partage.
--
-- Décision d'Adrien, 3 octobre 2026 : des FRACTIONS DE QUARTIER, découpées par
-- `98` comme les villes multicantonales. Ce fichier pose donc, pour chaque
-- côté d'une ligne de partage :
--
--   * un atome-fraction `PQnn#<côté>` — `cassini` = `PQnn`, le quartier-mère ;
--     `insee_geofla` = l'arrondissement, comme la mère ;
--   * sa géométrie : celle du quartier ENTIER, `partagee = true`. Comme pour
--     les villes, aucun polygone de fraction n'est stocké : la ligne est dans
--     `cartes/coupes_ville.csv` (clé `PQnn`), et `carte_coupe_ville()` découpe
--     au tirage ;
--   * ses rattachements de niveau `circo`, un par division électorale.
--
-- UNE FRACTION EST UN SOL, PAS UN RÉGIME. Le boulevard Voltaire coupe le 11e
-- de 1889 à 1919 puis de 1928 à 1940 : les deux côtés gardent le même atome
-- sur sept divisions, seul le rattachement change. Deux lignes différentes
-- dans le même quartier (la Muette en 1958 et en 1986) font quatre fractions.
--
-- LA VÉRITÉ EST DANS `circo/paris_fractions_quartier.csv`
-- =======================================================
--   atom_id, quartier, unit_id, valid_from, valid_to
-- Les unités existent déjà (`52`, `55`, `56`) ; ce fichier n'en crée aucune et
-- refuse une unité inconnue.
--
-- CE QUE CE FICHIER NE FAIT PAS
-- =============================
--   * il ne corrige pas les numéros de circonscription que le plan de l'atlas
--     contredit (11e : XI2 et XI3 y sont nommées 1/11 et 2/11 ; 7e en 1928) :
--     les fractions vont aux unités de la transcription, voir
--     `cartes/a_inscrire_en_base.md`, section Paris ;
--   * il ne pose pas les quartiers dont le partage n'est pas établi : Javel et
--     Grandes-Carrières en 1986, Grenelle et Javel en 1928-1940, Épinettes en
--     1958-1986 (entier dans la 24e selon le plan, cité deux fois par la
--     transcription).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' 101 — Paris : les fractions de quartier'
\echo '============================================================'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM atom WHERE atom_id = 'PQ01') THEN
        RAISE EXCEPTION 'PRÉREQUIS : atomes PQ01…PQ80 absents — jouer sql/52_paris_circo_1986.sql.';
    END IF;
END $$;

CREATE TEMP TABLE csv_fq (atom_id text, quartier int, unit_id text,
                          valid_from date, valid_to date);
\copy csv_fq FROM 'circo/paris_fractions_quartier.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo '-- 1. Ce que le CSV demande'
SELECT count(DISTINCT atom_id) fractions, count(DISTINCT quartier) quartiers,
       count(*) appartenances, min(valid_from) du, max(valid_to) au
  FROM csv_fq;

\echo ''
\echo '-- 2. Refus : unité inconnue, fraction mal nommée (attendu : 0 ligne)'
SELECT f.atom_id, f.unit_id,
       CASE WHEN u.unit_id IS NULL THEN 'unité de circonscription inconnue'
            ELSE 'atom_id ne commence pas par le quartier' END motif
  FROM csv_fq f
  LEFT JOIN unit u ON u.unit_id = f.unit_id AND u.niveau = 'circo'
 WHERE u.unit_id IS NULL
    OR split_part(f.atom_id, '#', 1) <> 'PQ' || lpad(f.quartier::text, 2, '0');

\echo ''
\echo '-- 3. Le quartier-mère a-t-il déjà une circonscription pendant la période ?'
\echo '--    (attendu : 0 ligne — sinon la mère et ses fractions se superposent)'
SELECT DISTINCT f.atom_id, m.atom_id mere, m.unit_id, m.valid_from, m.valid_to
  FROM csv_fq f
  JOIN membership m ON m.atom_id = 'PQ' || lpad(f.quartier::text, 2, '0')
                   AND m.niveau = 'circo'
                   AND m.periode && daterange(f.valid_from, f.valid_to, '[)')
 ORDER BY 1, 4;

\if :{?appliquer}

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM csv_fq f
                 LEFT JOIN unit u ON u.unit_id = f.unit_id AND u.niveau = 'circo'
                WHERE u.unit_id IS NULL
                   OR split_part(f.atom_id, '#', 1) <> 'PQ' || lpad(f.quartier::text, 2, '0')) THEN
        RAISE EXCEPTION 'REFUS : voir la recette 2.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Défaire le passage précédent. Retirer l'atome emporte sa géométrie, ses
--    rattachements et ses ancres (ON DELETE CASCADE) : rejouer `98` ensuite.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p101_trace (
    quoi text NOT NULL,           -- 'atom'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);
DELETE FROM atom a USING p101_trace t WHERE t.quoi = 'atom' AND t.cle = a.atom_id;
DELETE FROM p101_trace WHERE quoi = 'atom';

-- ---------------------------------------------------------------------------
-- 5. Poser : atomes, géométrie partagée, rattachements
-- ---------------------------------------------------------------------------
INSERT INTO atom (atom_id, cassini, fraction, insee_geofla)
SELECT DISTINCT f.atom_id, m.atom_id, true, m.insee_geofla
  FROM csv_fq f JOIN atom m ON m.atom_id = 'PQ' || lpad(f.quartier::text, 2, '0');
INSERT INTO p101_trace (quoi, cle) SELECT DISTINCT 'atom', atom_id FROM csv_fq;

INSERT INTO atom_geom (atom_id, geom, source, partagee)
SELECT DISTINCT ON (f.atom_id) f.atom_id, g.geom, g.source, true
  FROM csv_fq f JOIN atom_geom g ON g.atom_id = 'PQ' || lpad(f.quartier::text, 2, '0');

INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM csv_fq;

ANALYZE atom; ANALYZE atom_geom; ANALYZE membership;

\echo ''
\echo '-- 6. Posé'
SELECT count(*) FILTER (WHERE true) atomes,
       (SELECT count(*) FROM membership m JOIN p101_trace t ON t.cle = m.atom_id) appartenances
  FROM p101_trace WHERE quoi = 'atom';

\echo ''
\echo '=== 101 appliqué. Rejouer 98 (les ancres des fractions sont tombées avec elles). ==='
\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif

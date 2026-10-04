-- ============================================================================
-- 51_circo_1986_correctif.sql — corriger le découpage de 1986 là où le tableau
--                                du ministère est faux
--
--   psql -d histgis -v correctif=circo/circo_1986_correctifs.csv \
--        -f sql/51_circo_1986_correctif.sql          -- diagnostic
--   psql -d histgis -1 -v appliquer=1 \
--        -v correctif=circo/circo_1986_correctifs.csv \
--        -f sql/51_circo_1986_correctif.sql
--
-- Ce qui a été trouvé, le 21 août 2026
-- ------------------------------------
-- La carte des circonscriptions de l'Ain entre 1987 et 2012 sortait **en
-- miettes** : quatre circonscriptions pour vingt-trois morceaux disjoints. Or
-- l'article L. 125 du code électoral impose un territoire continu.
--
-- Mesuré sur les 95 départements, c'est un cas isolé. Les 25 autres
-- départements « fragmentés » de la couche 1986 le sont autant en 2009 : ce
-- sont les départements à ÎLES — Morbihan, Finistère, Charente-Maritime, Var,
-- Vendée, Côtes-d'Armor. Belle-Île n'est pas un défaut. L'Ain, lui, n'a pas
-- d'île, et sort d'un seul tenant en 2009.
--
-- La cause : la colonne « Circ. législative 1986 » de
-- `correspondance_2012.xls` est brouillée pour ce département. **Trente
-- cantons sur quarante-trois** y portent la mauvaise circonscription. La
-- colonne 2012 du même fichier, elle, est juste — c'est ce qui rend le défaut
-- invisible à toute recette interne.
--
-- La source qui fait foi
-- ----------------------
-- Loi n° 86-1197 du 24 novembre 1986 (JO du 25 novembre 1986, p. 14171), et
-- **Gaudillère, Atlas historique des circonscriptions électorales françaises,
-- p. 89**. Composition reprise par Wikipédia, article « Liste des
-- circonscriptions législatives de l'Ain », vérifiable par URL publique.
--
-- Le contrôle interne du correctif : les quatre listes totalisent **43
-- cantons, chacun une fois exactement** — ni oubli, ni doublon. C'est la
-- source elle-même qui se recoupe, avant toute confrontation à notre base.
--
-- Ce que cela oblige à réviser
-- ----------------------------
-- **`circo/note_bourg_1986.md` est faux.** Sa thèse — Bourg-en-Bresse coupée
-- entre trois circonscriptions — vient tout entière de la colonne corrompue.
-- Les trois cantons de Bourg (Est, Nord-Centre, Sud) sont dans la SEULE 1re
-- circonscription. Le décret de 1982 que la note cite reste juste pour les
-- cantons ; c'est leur affectation aux circonscriptions qui était fausse.
--
-- **`circo/circo_1986_ain.csv` est dérivé du même tableau**, donc faux aussi.
-- Il avait servi de « contrôle » et rendu zéro désaccord — comparer une source
-- à sa propre copie donne toujours zéro désaccord.
--
-- Pourquoi un fichier générique
-- -----------------------------
-- La table `circo_1986_correctifs.csv` porte `dep, canton, canton_nom, circo,
-- source`. Rien n'y est propre à l'Ain : si un autre département se révèle
-- brouillé, il s'ajoute au CSV sans toucher au SQL. La colonne `source` est
-- obligatoire et doit nommer un texte, pas un raisonnement.
--
-- Réversible : `circo_correctif_trace`, section 4.
-- Prérequis : `28` joué. Sans `-v appliquer=1`, ne fait que mesurer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?correctif}
\else
  \set correctif 'circo/circo_1986_correctifs.csv'
\endif

\set date_canton '2012-06-01'

DO $$
BEGIN
    IF to_regclass('histgis.circo1986_trace') IS NULL THEN
        RAISE EXCEPTION '28_circo_1986.sql doit être joué avant.';
    END IF;
END $$;

DROP TABLE IF EXISTS circo_correctif_src;
CREATE TABLE circo_correctif_src (
    dep text, canton text, canton_nom text, circo text, source text
);
\set cmd '\\copy circo_correctif_src FROM ' :'correctif' ' WITH (FORMAT csv, HEADER true)'
:cmd

\echo ''
\echo '=== 1. Le correctif ==='
SELECT dep, count(*) AS cantons, count(DISTINCT circo) AS circos,
       min(source) AS source
  FROM circo_correctif_src GROUP BY dep ORDER BY dep;

-- ---------------------------------------------------------------------------
-- Ce qu'il faut changer : tout rattachement de la couche 1986 porté par un
-- atome dont le CANTON figure au correctif, et dont la circonscription diffère.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS cc_cible;
CREATE TEMP TABLE cc_cible AS
SELECT m.membership_id, m.atom_id, m.unit_id AS avant,
       c.circo || '@1986' AS apres, c.canton, c.canton_nom, c.dep
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo'
  JOIN membership mc ON mc.atom_id = m.atom_id AND mc.niveau = 'canton'
                    AND mc.periode @> :'date_canton'::date
  JOIN circo_correctif_src c ON c.canton = mc.unit_id
 WHERE m.niveau = 'circo'
   AND m.unit_id LIKE '%@1986'
   AND m.unit_id <> c.circo || '@1986';

\echo ''
\echo '=== 2. Rattachements a corriger ==='
SELECT dep, avant, apres, count(*) AS communes
  FROM cc_cible GROUP BY dep, avant, apres ORDER BY dep, avant, apres;

\echo ''
\echo '=== 3. Atomes du departement SANS canton a la date de reference ==='
-- Ceux-la ne peuvent pas etre corriges par cette voie : leur circonscription
-- restera celle du ministere. A nommer plutot qu'a ignorer.
SELECT DISTINCT a.atom_id, a.insee_geofla, coalesce(n.nom, '?') AS nom
  FROM membership m
  JOIN atom a ON a.atom_id = m.atom_id
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
 WHERE m.niveau = 'circo' AND m.unit_id LIKE '%@1986'
   AND left(a.insee_geofla, 2) IN (SELECT DISTINCT dep FROM circo_correctif_src)
   AND NOT EXISTS (SELECT 1 FROM membership mc
                    WHERE mc.atom_id = a.atom_id AND mc.niveau = 'canton'
                      AND mc.periode @> :'date_canton'::date)
 ORDER BY 2;

\if :{?appliquer}

CREATE TABLE IF NOT EXISTS circo_correctif_trace (
    membership_id bigint PRIMARY KEY,
    atom_id       text NOT NULL,
    avant         text NOT NULL,
    apres         text NOT NULL,
    canton        text NOT NULL,
    dep           text NOT NULL,
    pose_le       timestamptz NOT NULL DEFAULT now()
);

INSERT INTO circo_correctif_trace (membership_id, atom_id, avant, apres, canton, dep)
SELECT membership_id, atom_id, avant, apres, canton, dep FROM cc_cible
ON CONFLICT (membership_id) DO NOTHING;

UPDATE membership m SET unit_id = c.apres
  FROM cc_cible c WHERE c.membership_id = m.membership_id;

ANALYZE membership;

\echo ''
\echo '=== 4. Apres correction ==='
SELECT u.dep, m.unit_id, count(*) AS communes
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'circo'
 WHERE m.niveau = 'circo' AND m.unit_id LIKE '%@1986'
   AND u.dep IN (SELECT DISTINCT dep FROM circo_correctif_src)
 GROUP BY 1, 2 ORDER BY 1, 2;
-- Attendu pour l'Ain : 01-01 puis 01-02, 01-03, 01-04, sans commune orpheline.

\echo ''
\echo '=== 5. Aucun atome dans deux circos a la meme date ==='
SELECT count(*) AS atomes_a_double
  FROM (SELECT atom_id, periode FROM membership WHERE niveau = 'circo'
         GROUP BY 1, 2 HAVING count(DISTINCT unit_id) > 1) x;

\echo ''
\echo '=== 6. Pour tout defaire ==='
\echo '    UPDATE membership m SET unit_id = t.avant'
\echo '      FROM circo_correctif_trace t WHERE t.membership_id = m.membership_id;'
\echo '    TRUNCATE circo_correctif_trace;'

\else
\echo ''
\echo '=== Tourne a blanc — relancer avec -v appliquer=1 ==='
\endif

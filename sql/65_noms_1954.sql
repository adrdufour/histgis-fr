-- ============================================================================
-- histgis — 65_noms_1954.sql : les noms des communes vivantes en 1954
--
--   cd ~/Téléchargements/projet_carte        <-- le \copy résout depuis ICI
--   psql -d histgis -f sql/65_noms_1954.sql
--
-- LECTURE SEULE. Produit `cog1954/noms_1954.csv`.
--
-- POURQUOI CE FICHIER EXISTE
-- ==========================
-- `essai_troisieme_1954.py` comptait comme « bruit » tout nom lu qui ne
-- s'apparie pas à `build/noms_geofla.csv` — la trame de 2011.
--
-- **C'est faux, et de beaucoup.** Une commune vivante en 1954 puis absorbée
-- depuis n'est pas dans la trame 2011 : elle était donc comptée comme du bruit
-- alors qu'elle est exactement ce que le dépouillement cherche. Le témoin
-- lui-même — la lecture EN SERVICE — affichait 82 bruits sur l'Ariège pour 123
-- justes. Un tel taux sur une chaîne éprouvée n'est pas crédible : c'est le
-- référentiel qui était faux, pas la lecture.
--
-- *C'est la deuxième fois dans la journée qu'un compteur, et non un
-- échantillon, fausse une conclusion.*
--
-- OÙ SONT LES NOMS DE 1954
-- ========================
-- `cm_commune` donne les CODES vivants à une date, sans nom. Deux sources se
-- complètent pour les noms :
--
--   * `geofla_commune` / `noms_geofla` — les communes encore là en 2011 ;
--   * `insee_mvt.libelle_av` — le libellé AVANT mouvement, donc le nom que
--     portait une commune au moment où elle a disparu. C'est le dispositif que
--     `archives/remplaces/composition_decrets.py` utilise déjà, et que `note_1954.md`
--     signale comme « à reprendre tel quel pour 1954 ».
--
-- CE QUE CE RÉFÉRENTIEL NE RÈGLE PAS
-- ==================================
-- Le nom de 1954 n'est pas toujours celui du mouvement : une commune peut avoir
-- changé de nom (mod 10) entre 1954 et sa disparition. On prend le libellé le
-- PLUS ANCIEN connu, qui en est le plus proche — et l'on garde tous les
-- libellés rencontrés plutôt qu'un seul, pour que l'appariement puisse essayer
-- chacun.
--
-- Prérequis : `06_insee_mvt.sql` et `20_commune_moderne.sql`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Le recensement de 1954 a été effectué le 10 mai 1954.
\set date_1954 '1954-05-10'

\echo ''
\echo '============================================================'
\echo ' Communes vivantes au 10 mai 1954 — codes et noms'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.cm_commune') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20_commune_moderne.sql.';
    END IF;
    IF to_regclass('histgis.insee_mvt') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/06_insee_mvt.sql.';
    END IF;
END $$;

DROP TABLE IF EXISTS n54_commune;
CREATE TABLE n54_commune AS
WITH vivantes AS (
    SELECT DISTINCT code
    FROM   cm_commune
    WHERE  daterange(valid_from, valid_to, '[)') @> :'date_1954'::date
),
-- `noms_geofla` est un CSV du dépôt, pas une table en base : les noms des
-- communes SURVIVANTES seront joints côté Python. Ici on ne cherche que les
-- noms que la base est seule à connaître — ceux des communes disparues.
survivantes AS (
    SELECT v.code,
           coalesce(
             (SELECT m.libelle_ap FROM insee_mvt m
               WHERE m.com_ap = v.code AND m.libelle_ap IS NOT NULL
               ORDER BY m.date_eff LIMIT 1),
             NULL)                              AS nom_apres,
           (SELECT m.libelle_av FROM insee_mvt m
             WHERE m.com_av = v.code AND m.libelle_av IS NOT NULL
             ORDER BY m.date_eff LIMIT 1)       AS nom_avant
    FROM   vivantes v
)
SELECT s.code,
       -- Le libellé AVANT mouvement est le plus proche de 1954 : c'est le nom
       -- que la commune portait quand elle a cessé d'exister, ou d'être citée.
       coalesce(s.nom_avant, s.nom_apres)       AS nom,
       CASE WHEN s.nom_avant IS NOT NULL THEN 'libelle_av'
            WHEN s.nom_apres IS NOT NULL THEN 'libelle_ap'
            ELSE 'sans nom' END                 AS voie
FROM   survivantes s;

CREATE INDEX n54_code_idx ON n54_commune (code);

\echo ''
\echo '-- 1. ce que le référentiel contient'
SELECT count(*)                                    AS communes_1954,
       count(*) FILTER (WHERE nom IS NOT NULL)     AS avec_un_nom,
       count(*) FILTER (WHERE nom IS NULL)         AS sans_nom
FROM   n54_commune;

\echo ''
\echo '-- 2. par voie'
SELECT voie, count(*) FROM n54_commune GROUP BY voie ORDER BY count(*) DESC;

\echo ''
\echo '   Les « sans nom » sont les communes que les mouvements INSEE ne'
\echo '   nomment jamais — celles qui n''ont pas bougé depuis 1943. Leur nom'
\echo '   est dans la trame 2011, que le script Python joindra de son côté.'

\copy (SELECT code, coalesce(nom, '') AS nom, voie FROM n54_commune ORDER BY code) TO 'cog1954/noms_1954.csv' WITH (FORMAT csv, HEADER true)

\echo ''
\echo 'cog1954/noms_1954.csv écrit.'
\echo ''
\echo 'Relancer ensuite le banc :'
\echo '   python3 archives/essais/essai_troisieme_1954.py --dep 09 --dep 34 --dep 90'
\echo 'Le `bruit` y deviendra interprétable — aujourd''hui il compte comme'
\echo 'fautives les communes disparues entre 1954 et 2011.'

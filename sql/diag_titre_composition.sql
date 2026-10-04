-- ============================================================================
-- histgis — diag_titre_composition.sql : le titre juge le découpage du JO
--
--   psql -d histgis -f sql/diag_titre_composition.sql
--
-- LECTURE SEULE. Ne crée que des tables `dtc_*` de diagnostic, n'écrit rien
-- dans `membership` ni dans le registre.
--
-- POURQUOI CE CONTRÔLE EXISTE
-- ===========================
-- Le 28 août 2026, le § 9 de `75` a refusé « Evreux-Ouest » pour
-- « département incompatible » : lu sous le département 25, cinq communes
-- toutes situées dans le 27. Le garde-fou visait le piège corse ; il a trouvé
-- autre chose.
--
-- Ce n'était pas un département mal lu. Le décret n° 82-55 est celui du DOUBS
-- (Besançon, Audincourt, Valentigney, Pont-de-Roide) ; le n° 82-56 est celui
-- de l'EURE, et son titre nomme EVREUX-OUEST. Les deux se suivent dans le JO
-- du 22 janvier 1982, et **la coupure entre eux est tombée un bloc trop loin**.
-- Le compte le confirme des deux côtés : 82-56 a sept cantons à son titre et
-- six dans l'extraction ; 82-55 en a un de trop.
--
-- LE CONTRÔLE, ET POURQUOI IL EST INDÉPENDANT
-- ===========================================
-- `acte_cantonal.cantons_titre` vient de l'INDEX de Légifrance ;
-- `acte_composition.canton` vient du TEXTE OCRisé du JO. Les deux n'ont pas la
-- même origine, et l'un peut donc juger l'autre. La colonne était sur le
-- disque depuis le moissonnage du 28 août au matin, et n'avait jamais servi.
--
-- CE QUI EST DÉCISIF ET CE QUI NE L'EST PAS
-- =========================================
-- Un titre ne nomme PAS tous les cantons touchés : un décret modifie souvent
-- des cantons voisins sans les citer. « Absent du titre » n'est donc pas une
-- faute, et le § 3 le compte à part.
--
-- Ce qui est décisif, c'est le § 4 : un canton absent du titre de SON décret
-- et présent dans le titre d'un AUTRE. Là, le titre ne dit pas seulement que
-- la lecture est douteuse — il dit où le bloc aurait dû aller.
--
-- LA NORMALISATION
-- ================
-- Les titres sont en capitales sans accents (« BESANCON-NORD-EST »), les
-- lectures accentuées et espacées (« Sochaux - Grand-Charmont »). On ramène
-- les deux à la même graphie : minuscules, sans accents, espaces resserrées
-- autour des traits d'union. Rien de plus — on ne rapproche pas deux noms
-- voisins, on reconnaît le même nom écrit deux fois.
--
-- Prérequis : `72_registre_actes.sql`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' LES TITRES CONTRE LES COMPOSITIONS — découpage du JO'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql d''abord.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. La graphie commune
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dtc_norme(t text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
    SELECT trim(regexp_replace(
             regexp_replace(
               translate(lower(replace(replace(coalesce(t, ''), 'œ', 'oe'), 'æ', 'ae')),
                         'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ',
                         'aaaaaaeeeeiiiiooooouuuuyycn'),
               '\s*-\s*', '-', 'g'),
             '\s+', ' ', 'g'));
$$;

-- ---------------------------------------------------------------------------
-- 2. Ce que chaque titre annonce, un canton par ligne
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dtc_titre;
CREATE TABLE dtc_titre AS
SELECT a.legifrance_id,
       a.url,
       a.dep,
       a.date_signature,
       dtc_norme(t.canton) AS canton_norme
FROM   acte_cantonal a,
       LATERAL unnest(string_to_array(a.cantons_titre, ',')) AS t(canton)
WHERE  a.cantons_titre IS NOT NULL
  AND  trim(t.canton) <> '';

CREATE INDEX dtc_titre_c_idx ON dtc_titre (canton_norme);
CREATE INDEX dtc_titre_u_idx ON dtc_titre (url);

\echo ''
\echo '-- 1. cantons annoncés par les titres'
SELECT count(*)                          AS lignes,
       count(DISTINCT url)               AS actes,
       count(DISTINCT canton_norme)      AS cantons
FROM   dtc_titre;

-- ---------------------------------------------------------------------------
-- 3. Ce que chaque décret a rendu, confronté à son propre titre
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dtc_lu;
CREATE TABLE dtc_lu AS
SELECT c.url,
       c.decret,
       c.date_acte,
       c.dep                              AS dep_lu,
       dtc_norme(c.canton)                AS canton_norme,
       min(c.canton)                      AS canton_lu,
       count(*)                           AS communes,
       count(DISTINCT c.dep_insee) FILTER (WHERE c.dep_insee <> '') AS n_dep_insee,
       min(c.dep_insee) FILTER (WHERE c.dep_insee <> '')            AS dep_insee,
       min(c.jo)                          AS jo
FROM   acte_composition c
GROUP  BY 1,2,3,4,5;

CREATE INDEX dtc_lu_c_idx ON dtc_lu (canton_norme);

ALTER TABLE dtc_lu ADD COLUMN au_titre boolean;
UPDATE dtc_lu l
   SET au_titre = EXISTS (SELECT 1 FROM dtc_titre t
                           WHERE t.url = l.url AND t.canton_norme = l.canton_norme);

\echo ''
\echo '-- 2. chaque canton lu figure-t-il au titre de SON décret ?'
\echo '   (« non » n''est pas une faute : un décret modifie souvent des cantons'
\echo '    voisins sans les citer au titre.)'
SELECT au_titre, count(*) AS cantons, sum(communes) AS communes
FROM   dtc_lu GROUP BY 1 ORDER BY 1 DESC;

-- ---------------------------------------------------------------------------
-- 4. LE CAS DÉCISIF — le titre d'un autre décret réclame ce canton
--
-- On exige que l'autre décret soit du MÊME JOURNAL OFFICIEL : c'est là que la
-- coupure se fait, et deux décrets homonymes à trente ans d'écart ne
-- prouveraient rien. On exige aussi que le canton ne soit au titre d'aucun
-- autre acte du même JO à égalité — un seul réclamant, sinon on ne conclut pas.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dtc_egare;
CREATE TABLE dtc_egare AS
WITH candidat AS (
    SELECT l.url            AS url_lu,
           l.decret         AS decret_lu,
           l.jo,
           l.canton_lu,
           l.canton_norme,
           l.communes,
           l.dep_lu,
           l.dep_insee,
           t.url            AS url_titre,
           t.dep            AS dep_titre,
           (SELECT a.decret FROM acte_cantonal a WHERE a.url = t.url) AS decret_titre
    FROM   dtc_lu l
    JOIN   dtc_titre t ON t.canton_norme = l.canton_norme AND t.url <> l.url
    WHERE  l.au_titre IS NOT TRUE
      AND  EXISTS (SELECT 1 FROM acte_composition c
                    WHERE c.url = t.url AND c.jo = l.jo)   -- même Journal officiel
)
SELECT * FROM candidat c
WHERE  (SELECT count(DISTINCT url_titre) FROM candidat k
         WHERE k.url_lu = c.url_lu AND k.canton_norme = c.canton_norme) = 1;

\echo ''
\echo '-- 3. CANTONS ÉGARÉS : lus sous un décret, réclamés par le titre d''un'
\echo '   autre décret du MÊME Journal officiel. C''est une coupure mal placée,'
\echo '   et le titre dit où le bloc aurait dû aller.'
SELECT decret_lu, decret_titre, canton_lu, communes,
       dep_lu, dep_insee, dep_titre, jo
FROM   dtc_egare ORDER BY jo, decret_lu, canton_lu;

\echo ''
\echo '   le département lu confirme-t-il le décret d''origine ou celui du titre ?'
SELECT CASE
         WHEN dep_insee IS NULL              THEN 'c - pas de code INSEE pour trancher'
         WHEN dep_insee = dep_titre          THEN 'a - les communes donnent raison au TITRE'
         WHEN dep_insee = dep_lu             THEN 'b - les communes donnent raison à la LECTURE'
         ELSE                                     'd - ni l''un ni l''autre'
       END      AS verdict,
       count(*) AS cantons
FROM   dtc_egare GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 5. Le compte par décret — un titre trop court d'un côté, trop long de l'autre
--
-- La signature d'une coupure mal placée n'est pas seulement le canton égaré :
-- c'est que son décret d'origine a un canton de MOINS que son titre, et le
-- voisin un de PLUS. Les deux écarts se répondent.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS dtc_compte;
CREATE TABLE dtc_compte AS
SELECT a.legifrance_id, a.decret, a.dep, a.date_signature, a.url,
       (SELECT count(*) FROM dtc_titre t WHERE t.url = a.url)              AS au_titre,
       (SELECT count(*) FROM dtc_lu    l WHERE l.url = a.url)              AS lus,
       (SELECT count(*) FROM dtc_lu    l WHERE l.url = a.url AND l.au_titre) AS lus_au_titre
FROM   acte_cantonal a
WHERE  a.cantons_titre IS NOT NULL AND a.cantons_titre <> ''
  AND  EXISTS (SELECT 1 FROM acte_composition c WHERE c.url = a.url);

\echo ''
\echo '-- 4. décrets dont le titre annonce plus de cantons qu''on n''en a lus'
\echo '   (les dix plus gros écarts — c''est la mesure du rappel de'
\echo '    l''extraction, décret par décret)'
SELECT decret, dep, date_signature, au_titre, lus, lus_au_titre,
       au_titre - lus_au_titre AS manquants
FROM   dtc_compte
WHERE  au_titre > lus_au_titre
ORDER  BY au_titre - lus_au_titre DESC, decret
LIMIT  10;

\echo ''
\echo '   vue d''ensemble'
SELECT count(*)                                              AS decrets,
       sum(au_titre)                                         AS cantons_annonces,
       sum(lus_au_titre)                                     AS retrouves,
       round(100.0 * sum(lus_au_titre) / nullif(sum(au_titre), 0), 1) AS pct,
       count(*) FILTER (WHERE lus_au_titre = au_titre)       AS decrets_complets
FROM   dtc_compte;

\echo ''
\echo '============================================================'
\echo ' Diagnostic terminé. Rien n''a été modifié : les corrections'
\echo ' se font dans cantons/composition_jo.py, à la coupure, pas'
\echo ' en aval — et chacune doit être adossée à son titre.'
\echo '============================================================'

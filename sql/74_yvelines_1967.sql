-- ============================================================================
-- histgis — 74_yvelines_1967.sql : le décret comble le fascicule manquant
--
--   psql -d histgis -1 -f sql/74_yvelines_1967.sql
--
-- POURQUOI CE FICHIER EXISTE
-- ==========================
-- `RESTE_A_FAIRE.md` note que neuf fascicules du COG 1968 sont introuvables sur
-- BnSP — les départements 61 et 71 à 78, soit 3 593 communes hors du jalon.
--
-- La recette `73` l'a rendu visible sans le chercher : sur les 14 cantons
-- d'Yvelines créés par le décret n° 67-594, **aucun** n'a la moindre commune
-- retrouvée en 1968. Pas une lecture douteuse, pas un canton contesté : rien du
-- tout. Le 78 est l'un des neuf fascicules manquants.
--
-- Or le décret dit précisément ce que le fascicule aurait dit. Et il le dit
-- pour une date qui n'est pas une convention :
--
--   * les Yvelines naissent le 1er janvier 1968, par démembrement de la
--     Seine-et-Oise ;
--   * le décret n° 67-594 du 20 juillet 1967 crée leurs cantons, avec effet à
--     cette naissance.
--
-- `valid_from = 1968-01-01` est donc un FAIT JURIDIQUE, pas un choix. C'est ce
-- qui distingue ce fichier des compositions de 1973, 1982 et 1985, qui attendent
-- toujours qu'on tranche leur date d'effet (cf. `cantons/note_entree_en_base.md`
-- § 4). Ici il n'y a rien à trancher.
--
-- LA BORNE HAUTE, ET LE CHOIX QU'ELLE ENGAGE
-- ==========================================
-- Par défaut `1969-01-01`, exactement comme le jalon de 1968 posé par `59`.
-- Le raisonnement de `59` s'applique tel quel : on pose un ÉTAT à une DATE.
--
-- Un décret n'est pourtant pas un recensement — c'est un acte, et un acte vaut
-- jusqu'au suivant. Le premier acte connu pour le 78 après 1968 est du
-- 15 janvier 1976. Étendre jusque-là serait défendable, MAIS suppose que la
-- liste des actes est complète sur l'intervalle, ce qui n'est pas démontré
-- (cf. `72` § 5). Le choix reste ouvert et explicite :
--
--     \set borne_haute '1969-01-01'   -- l'état à la date, homogène avec 59
--     \set borne_haute '1976-01-15'   -- l'acte vaut jusqu'au suivant
--
-- Changer cette ligne est une décision de méthode. Elle doit être prise en
-- connaissance, pas héritée d'un défaut.
--
-- L'IDENTITÉ DES CANTONS
-- ======================
-- Le décret nomme les cantons, il ne les code pas — et le fascicule qui les
-- aurait codés est justement celui qui manque. On passe donc par la
-- composition : le canton retenu est celui de 1999 (posé par `24`) qui partage
-- au moins 80 % des communes de la liste du décret, sur au moins trois
-- communes entières.
--
-- C'est cohérent avec la décision de `24` § 1 — un canton garde le même
-- `unit_id` de 1870 à 2012, la filiation de la nomenclature étant celle de
-- l'Insee. Ce qui est affirmé ici est l'IDENTITÉ du canton, pas la constance de
-- sa composition entre 1968 et 1999.
--
-- ON REFUSE PLUTÔT QUE DE DEVINER
-- ===============================
-- Un canton qui ne résout pas — trop court, accord partiel, désaccord — n'est
-- PAS posé. Il est listé au § 5 avec son motif. C'est la règle de `60` :
-- mieux vaut un canton absent qu'un canton faux, puisqu'aucune recette interne
-- ne saurait distinguer le second d'un vrai.
--
-- Attendu d'après la mesure hors base : 11 cantons posés, 3 écartés
-- (Chevreuse et Conflans-Sainte-Honorine en accord partiel, Trappes en
-- désaccord — une ville nouvelle, redécoupée depuis), 6 trop courts.
--
-- REJOUABLE
-- =========
-- Tout ce qui est écrit est tracé dans `y67_trace`, et la section 1 défait le
-- passage précédent AVANT de juger quoi que ce soit.
--
-- Prérequis : `72_registre_actes.sql`, `24_canton_moderne.sql`, et le jalon de
--             1968 (`58` + `59`) pour que le § 3 puisse vérifier que la place
--             est libre.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set decret       '67-594'
\set dep          '78'
\set borne_basse  '1968-01-01'
\set borne_haute  '1969-01-01'
\set jalon_1999   '1999-06-01'
\set mini         3
\set seuil        0.8

\echo ''
\echo '============================================================'
\echo ' YVELINES 1967 — le décret à la place du fascicule manquant'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 0. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.acte_composition') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/72_registre_actes.sql d''abord.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> DATE '1999-06-01') THEN
        RAISE EXCEPTION 'PRÉREQUIS : les cantons de 1999 ne sont pas en base (sql/24).';
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS y67_trace (
    quoi text NOT NULL,          -- 'membership'
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent — AVANT tout jugement
-- ---------------------------------------------------------------------------
DELETE FROM membership m
 USING y67_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE y67_trace;

\echo ''
\echo '-- 1. passage précédent défait (s''il y en avait un)'

-- ---------------------------------------------------------------------------
-- 2. Le fascicule manquant, vérifié et non supposé
--
-- Si le 78 était présent dans le jalon de 1968, ce fichier n'aurait pas lieu
-- d'être — il écraserait une lecture directe par une déduction. On le vérifie
-- plutôt que de le croire.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 2. le département est-il vraiment absent du jalon de 1968 ?'
SELECT count(*) AS rattachements_1968_dans_le_dep
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton'
  AND  u.dep = :'dep'
  AND  m.periode @> DATE '1968-06-01';

\echo '   (0 attendu : le fascicule 78 est l''un des neuf introuvables)'

-- ---------------------------------------------------------------------------
-- 3. Résolution : quel canton de 1999 porte chaque canton du décret ?
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS y67_dit;
CREATE TABLE y67_dit AS
SELECT c.canton, c.atome
FROM   acte_composition c
WHERE  c.decret = :'decret'
  AND  c.dep    = :'dep'
  AND  c.atome IS NOT NULL
GROUP  BY 1, 2;

DROP TABLE IF EXISTS y67_lien;
CREATE TABLE y67_lien AS
WITH taille AS (
    SELECT canton, count(*) AS communes FROM y67_dit GROUP BY canton
),
base99 AS (
    SELECT split_part(m.atom_id, '#', 1) AS atome, m.unit_id
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
    WHERE  m.niveau = 'canton'
      AND  u.dep = :'dep'
      AND  m.periode @> :'jalon_1999'::date
    GROUP  BY 1, 2
),
votes AS (
    SELECT d.canton, b.unit_id, count(*) AS n
    FROM   y67_dit d JOIN base99 b ON b.atome = d.atome
    GROUP  BY 1, 2
),
meilleur AS (
    SELECT DISTINCT ON (canton) canton, unit_id, n
    FROM   votes ORDER BY canton, n DESC, unit_id
)
SELECT t.canton, t.communes, m.unit_id, coalesce(m.n, 0) AS partagees,
       CASE WHEN t.communes > 0
            THEN round(100.0 * coalesce(m.n, 0) / t.communes, 0) END AS taux,
       CASE
         WHEN t.communes < :mini                            THEN 'trop court'
         WHEN m.unit_id IS NULL                             THEN 'aucun canton de 1999 en commun'
         WHEN m.n::numeric / t.communes >= :seuil           THEN 'resolu'
         WHEN m.n::numeric / t.communes >= 0.5              THEN 'accord partiel'
         ELSE                                                    'desaccord'
       END                                                       AS verdict
FROM   taille t LEFT JOIN meilleur m USING (canton);

\echo ''
\echo '-- 3. résolution des cantons du décret vers la nomenclature'
SELECT verdict, count(*) AS cantons, sum(communes) AS communes
FROM   y67_lien GROUP BY verdict ORDER BY cantons DESC;

\echo ''
SELECT canton, communes, unit_id, partagees, taux, verdict
FROM   y67_lien ORDER BY verdict, canton;

-- ---------------------------------------------------------------------------
-- 4. Ce qui va être posé — et la vérification que la place est libre
--
-- `membership_non_chevauchant` refuserait un atome déjà rattaché sur la
-- période. Plutôt que de laisser la contrainte lever une erreur au milieu de
-- l'écriture, on écarte ces atomes ici et on les compte.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS y67_pose;
CREATE TABLE y67_pose AS
SELECT d.canton, l.unit_id, d.atome
FROM   y67_dit d
JOIN   y67_lien l USING (canton)
WHERE  l.verdict = 'resolu'
  AND  NOT EXISTS (
         SELECT 1 FROM membership m
          WHERE m.atom_id = d.atome AND m.niveau = 'canton'
            AND m.periode && daterange(:'borne_basse'::date,
                                       :'borne_haute'::date, '[)'));

\echo ''
\echo '-- 4. à poser'
SELECT count(*)                    AS rattachements,
       count(DISTINCT unit_id)     AS cantons,
       count(DISTINCT atome)       AS atomes
FROM   y67_pose;

\echo ''
\echo '   atomes écartés parce que la place n''était pas libre :'
SELECT count(*) AS atomes_occupes
FROM   y67_dit d
JOIN   y67_lien l USING (canton)
WHERE  l.verdict = 'resolu'
  AND  EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = d.atome AND m.niveau = 'canton'
                  AND m.periode && daterange(:'borne_basse'::date,
                                             :'borne_haute'::date, '[)'));

-- un même atome ne peut pas être posé deux fois : ce serait une commune
-- revendiquée par deux cantons du même décret, donc une erreur de lecture
\echo ''
\echo '   atomes réclamés par deux cantons du décret (doit valoir 0) :'
SELECT count(*) AS atomes_en_double
FROM   (SELECT atome FROM y67_pose GROUP BY atome HAVING count(*) > 1) q;

DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
      FROM (SELECT atome FROM y67_pose GROUP BY atome HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION
          'REFUS : % atome(s) réclamé(s) par deux cantons du même décret. '
          'Rien n''est posé — la lecture est à reprendre.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 5. La pose
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atome, unit_id, 'canton',
           :'borne_basse'::date, :'borne_haute'::date
    FROM   y67_pose
    RETURNING membership_id
)
INSERT INTO y67_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '-- 5. posé'
SELECT count(*) AS rattachements FROM y67_trace WHERE quoi = 'membership';

\echo ''
\echo '   ce qui n''a PAS été posé, et pourquoi'
SELECT verdict, canton, communes, taux
FROM   y67_lien WHERE verdict <> 'resolu' ORDER BY verdict, canton;

\echo ''
\echo '   Ces cantons-là restent absents du jalon. C''est la règle de `60` :'
\echo '   mieux vaut un canton absent qu''un canton faux, puisqu''aucune recette'
\echo '   interne ne saurait distinguer le second d''un vrai.'

-- ---------------------------------------------------------------------------
-- 6. Recette
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. recette : le département répond-il maintenant au 1er juin 1968 ?'
SELECT count(DISTINCT m.unit_id) AS cantons,
       count(*)                  AS rattachements
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton' AND u.dep = :'dep'
  AND  m.periode @> DATE '1968-06-01';

\echo ''
\echo '   aucun chevauchement introduit (la contrainte l''aurait refusé, mais'
\echo '   on le redit ici pour que la recette soit lisible sans la connaître) :'
SELECT count(*) AS chevauchements
FROM   membership a JOIN membership b
       ON a.atom_id = b.atom_id AND a.niveau = b.niveau
      AND a.membership_id < b.membership_id
      AND a.periode && b.periode
WHERE  a.niveau = 'canton';

\echo ''
\echo '============================================================'
\echo ' Fait. Les Yvelines de 1968 viennent du décret de 1967,'
\echo ' faute de fascicule — et la date d''effet, elle, est un fait.'
\echo '============================================================'

-- ============================================================================
-- histgis — 60_canton_forbach2.sql : un canton que la nomenclature ignore
--
--   psql -d histgis -1 -f sql/60_canton_forbach2.sql
--
-- LE CAS
-- ======
-- Le recensement de 1968 rattache seize communes de Moselle à un canton `5740`
-- que `unit` ne connaît pas. Ce n'était pas une erreur de lecture.
--
--   Décret du 8 août 1967 — dédoublement du canton de Forbach en Forbach-I et
--   Forbach-II. Le même décret crée Florange, Freyming, Montigny-lès-Metz,
--   Rombas, Woippy et Basse-Yutz : la Moselle passe de 36 à 42 cantons.
--
--   Décret du 24 décembre 1984 — Forbach-I et Forbach-II DISPARAISSENT,
--   redivisés en Forbach, Stiring-Wendel et Behren-lès-Forbach.
--
-- Forbach-II n'existe donc ni en 1940 (TRF-GIS) ni en 1999 (COG) : les deux
-- seules sources dont `unit` est faite. **Il est invisible par construction**,
-- et le serait resté sans le recensement.
--
-- LA VÉRIFICATION, ET CE QU'ELLE VAUT
-- ===================================
-- Wikipédia donne la composition de Forbach-II : Alsting, Bousbach, Cocheren,
-- Diebling, Etzling, Farschviller, Folkling, Kerbach, Merlebach, Metzing,
-- Morsbach, Nousseviller-Saint-Nabor, Rosbruck, Spicheren, Théding, Tenteling.
-- **Seize communes, et notre lecture porte exactement les seize.**
--
--   <https://fr.wikipedia.org/wiki/Canton_de_Forbach-II>   (CC BY-SA)
--   <https://fr.wikipedia.org/wiki/Liste_des_cantons_de_la_Moselle>
--
-- C'est une concordance avec une source INDÉPENDANTE de notre chaîne — ni
-- TRF-GIS, ni le COG, ni l'OCR. La section 3 la rejoue et ÉCHOUE si la
-- composition lue s'écarte de celle-ci : le contrôle n'est pas dans un
-- commentaire, il est dans le fichier.
--
-- POURQUOI CE CANTON ET PAS LES TROIS AUTRES
-- ==========================================
-- `59` signalait quatre cantons inconnus cités au moins cinq fois. Les trois
-- autres sont des erreurs de lecture du chiffre des DIZAINES, conformes à la
-- table de confusion mesurée le 22 août (« 5 lu pour 3 » 350 fois, « 8 lu pour
-- 3 » 175 fois) :
--
--     1454 -> 1434 Troarn            Amfreville, Escoville, Vimont, Giberville
--                                    s'imbriquent dans Bavent, Bréville, Argences
--     8051 -> 8031 Nouvion           Agenvillers, Gapennes voisines de Domvast
--     5181 -> 5131 Ville-en-Tardenois  Faverolles-et-Coëmy voisine de Branscourt
--
-- Deux preuves les distinguent de Forbach-II :
--   * l'annexe VII de Gaudillère ne signale AUCUNE création dans le Calvados
--     rural, la Somme ou la Marne entre 1954 et 1968 — seulement Caen-N. et
--     Caen-S., qui sont urbains ;
--   * `5181` répartit ses cinq communes sur TROIS arrondissements. Un canton
--     ne chevauche pas trois arrondissements.
--
-- Un test que j'avais cru décisif ne l'était pas : mesurer le chevauchement
-- entre le canton fantôme et son voisin par substitution. Il est nul dans les
-- deux hypothèses — une commune mal lue quitte le vrai canton pour le faux —
-- et ne pouvait donc rien départager. C'est la géographie qui tranche.
--
-- Prérequis : sql/59_cog1968_membership.sql.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut '1968-01-01'
\set jalon_fin   '1969-01-01'
\set canton      '5740'

\echo ''
\echo '============================================================'
\echo ' Canton 5740 — Forbach-II (D. 8.8.1967 - D. 24.12.1984)'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.c68_lien') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/58 puis sql/59.';
    END IF;

    -- LE GARDE-FOU SYMÉTRIQUE. `59` déclare 5740 dans `c68_delegue` et ne le
    -- pose donc pas. Si cette déclaration disparaissait — refonte de `59`,
    -- copie d'une ancienne version — les DEUX fichiers poseraient le canton et
    -- `membership_non_chevauchant` refuserait, sur un message qui ne dirait pas
    -- pourquoi.
    --
    -- Une délégation n'existe que si les deux côtés la connaissent. On vérifie
    -- donc ici que l'autre côté la connaît toujours.
    IF to_regclass('histgis.c68_delegue') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM c68_delegue WHERE canton_id = '5740') THEN
        RAISE EXCEPTION
          'INCOHÉRENCE : le canton 5740 n''est pas déclaré dans `c68_delegue`. '
          '`59` va donc le poser lui-même, et ce fichier ferait doublon. '
          'Rétablir la ligne dans sql/59_cog1968_membership.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent, avant tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS c60_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m USING c60_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;
DELETE FROM unit u USING c60_trace t
 WHERE t.quoi = 'unit' AND t.cle = u.unit_id;
TRUNCATE c60_trace;

-- ---------------------------------------------------------------------------
-- 2. La composition lue
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c60_forbach2;
CREATE TABLE c60_forbach2 AS
SELECT l.insee, l.nom, l.atome, l.accord, l.n_atomes
FROM   c68_lien l
WHERE  l.canton_id = :'canton'
  AND  l.commune_vivante
  AND  l.atome IS NOT NULL;

\echo ''
\echo '-- 2. composition lue par le recensement'
SELECT insee, nom, accord FROM c60_forbach2 ORDER BY insee;

-- ---------------------------------------------------------------------------
-- 3. LE CONTRÔLE — la composition de Wikipédia, écrite ici et confrontée
--
-- On compare sur le CODE INSEE, pas sur le nom : le nom vient de l'OCR et
-- comparer l'OCR à lui-même ne prouverait rien.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c60_attendu;
CREATE TABLE c60_attendu (insee char(5) PRIMARY KEY, nom text);
INSERT INTO c60_attendu (insee, nom) VALUES
  ('57013', 'Alsting'),      ('57101', 'Bousbach'),
  ('57144', 'Cocheren'),     ('57176', 'Diebling'),
  ('57202', 'Etzling'),      ('57208', 'Farschviller'),
  ('57222', 'Folkling'),     ('57360', 'Kerbach'),
  ('57458', 'Merlebach'),    ('57466', 'Metzing'),
  ('57484', 'Morsbach'),     ('57514', 'Nousseviller-Saint-Nabor'),
  ('57596', 'Rosbruck'),     ('57659', 'Spicheren'),
  ('57665', 'Tenteling'),    ('57669', 'Théding');

\echo ''
\echo '-- 3. confrontation à la composition publiée (Wikipédia, CC BY-SA)'
SELECT
  (SELECT count(*) FROM c60_attendu)                              AS attendu,
  (SELECT count(*) FROM c60_forbach2)                             AS lu,
  (SELECT count(*) FROM c60_attendu a
     JOIN c68_lien l ON l.insee = a.insee AND l.canton_id = :'canton')
                                                                  AS concordants,
  (SELECT count(*) FROM c60_attendu a
    WHERE NOT EXISTS (SELECT 1 FROM c68_lien l
                       WHERE l.insee = a.insee AND l.canton_id = :'canton'))
                                                                  AS manquants;

DO $$
DECLARE n_att bigint; n_ok bigint; n_sup bigint;
BEGIN
    SELECT count(*) INTO n_att FROM c60_attendu;
    SELECT count(*) INTO n_ok FROM c60_attendu a
      JOIN c68_lien l ON l.insee = a.insee AND l.canton_id = '5740';
    SELECT count(*) INTO n_sup FROM c68_lien l
     WHERE l.canton_id = '5740'
       AND NOT EXISTS (SELECT 1 FROM c60_attendu a WHERE a.insee = l.insee);

    -- Le contrôle EST le garde-fou. Si la lecture s'écarte de la source
    -- publiée, on n'écrit rien : un canton posé sur une composition qui ne
    -- correspond à aucune source vaut moins que pas de canton du tout.
    IF n_ok <> n_att OR n_sup > 0 THEN
        RAISE EXCEPTION 'CONTRÔLE : % / % communes concordent, % en trop. '
                        'La lecture s''écarte de la composition publiée — '
                        'rien n''est posé.', n_ok, n_att, n_sup;
    END IF;
    RAISE NOTICE 'Contrôle : % communes sur %, aucune en trop.', n_ok, n_att;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Les atomes déjà pris
--
-- `cm_atome` fait passer une commune disparue par son successeur. MERLEBACH
-- (57458) a fusionné avec Freyming en 1971 : elle se résout donc à l'atome de
-- Freyming-Merlebach — que `59` a peut-être déjà rattaché au canton 5741
-- (Freyming) pour la commune 57240.
--
-- `membership_non_chevauchant` refuserait le second rattachement. On repère le
-- cas AVANT d'insérer, et on l'écarte en le nommant : poser Merlebach en
-- écrasant Freyming donnerait un canton faux à un territoire réel.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c60_atome_pris;
CREATE TABLE c60_atome_pris AS
SELECT f.insee, f.nom, f.atome, m.unit_id AS deja_rattache_a
FROM   c60_forbach2 f
JOIN   membership m ON m.atom_id = f.atome AND m.niveau = 'canton'
                   AND daterange(m.valid_from, m.valid_to, '[)')
                       @> :'jalon_debut'::date;

\echo ''
\echo '-- 4. communes dont l''atome est déjà rattaché à cette date'
SELECT * FROM c60_atome_pris;

-- ---------------------------------------------------------------------------
-- 5. L'unité, puis les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    VALUES (:'canton', 'canton', '57', :'canton', NULL, NULL,
            'Forbach-II', false)
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO c60_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT f.atome, :'canton', 'canton',
           :'jalon_debut'::date, :'jalon_fin'::date
    FROM   c60_forbach2 f
    WHERE  f.n_atomes = 1
      AND  NOT EXISTS (SELECT 1 FROM c60_atome_pris p WHERE p.insee = f.insee)
    RETURNING membership_id
)
INSERT INTO c60_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 5. posé'
SELECT quoi, count(*) FROM c60_trace GROUP BY quoi ORDER BY quoi;

-- ---------------------------------------------------------------------------
-- 6. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. recette'
SELECT u.unit_id, u.nom, u.dep,
       (SELECT count(*) FROM membership m
         WHERE m.unit_id = u.unit_id
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> :'jalon_debut'::date)                AS communes_1968
FROM   unit u WHERE u.unit_id = :'canton';

\echo ''
\echo '   le canton ne doit exister QU''en 1968 (bornes du jalon) :'
SELECT min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   membership WHERE unit_id = :'canton';

\echo ''
\echo '============================================================'
\echo ' Forbach-II posé. Le décret du 8.8.1967 en a créé sept autres'
\echo ' en Moselle, et l''annexe VII compte 30 créations 1954-1968 —'
\echo ' surtout urbaines, et souvent disparues avant 1999. Voir 61.'
\echo '============================================================'

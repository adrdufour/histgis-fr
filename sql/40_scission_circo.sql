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
    debut_reel    date NOT NULL,   -- première circo réelle de l'atome
    voisins       int  NOT NULL,   -- combien de voisins de canton l'ont dicté
    pose_le       timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM scission_circo_trace t
                WHERE t.membership_id = m.membership_id);
TRUNCATE scission_circo_trace;

-- ---------------------------------------------------------------------------
-- 1. Le calendrier des années couvertes par la base
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_annee;
CREATE TEMP TABLE sc_annee AS
SELECT generate_series(
           extract(year FROM (SELECT min(valid_from) FROM membership))::int,
           extract(year FROM (SELECT max(valid_to)   FROM membership))::int - 1
       ) AS an;

-- ---------------------------------------------------------------------------
-- 2. Les candidats : premier rattachement circo postérieur au début de la base
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_candidat;
CREATE TEMP TABLE sc_candidat AS
SELECT m.atom_id, min(m.valid_from) AS debut
  FROM membership m
 WHERE m.niveau = 'circo'
 GROUP BY 1
HAVING min(m.valid_from) > (SELECT min(valid_from) FROM membership);

-- Garde-fou 3 : on écarte les atomes-fraction. Une commune coupée entre deux
-- circonscriptions ne peut pas hériter d'une circo unique, et c'est justement
-- le cas où l'unanimité des voisins ne prouverait rien.
DELETE FROM sc_candidat c
 USING atom a
 WHERE a.atom_id = c.atom_id AND a.fraction;

-- ---------------------------------------------------------------------------
-- 3. Ce que les voisins de canton disent, année par année
--
-- On ne retient une année que si les voisins sont UNANIMES. Le `count(DISTINCT
-- unit_id) = 1` est tout le correctif : il pose quand la donnée est d'accord
-- avec elle-même, et se tait sinon.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS sc_dicte;
CREATE TEMP TABLE sc_dicte AS
WITH jour AS (
    SELECT c.atom_id, c.debut, a.an, make_date(a.an, 1, 1) AS d
      FROM sc_candidat c
      CROSS JOIN sc_annee a
     WHERE make_date(a.an, 1, 1) < c.debut
),
-- le canton de l'atome cette année-là, prolongé par 11
canton AS (
    SELECT j.atom_id, j.debut, j.an, j.d, mc.unit_id AS canton
      FROM jour j
      JOIN membership mc ON mc.atom_id = j.atom_id
                        AND mc.niveau  = 'canton'
                        AND mc.periode @> j.d
),
-- ce que portent les AUTRES membres de ce canton
voisin AS (
    SELECT k.atom_id, k.debut, k.an, k.d, k.canton,
           mv.unit_id AS circo
      FROM canton k
      JOIN membership mk ON mk.niveau = 'canton'
                        AND mk.unit_id = k.canton
                        AND mk.atom_id <> k.atom_id
                        AND mk.periode @> k.d
      JOIN membership mv ON mv.atom_id = mk.atom_id
                        AND mv.niveau  = 'circo'
                        AND mv.periode @> k.d
)
SELECT atom_id, debut, an, d,
       min(circo)                AS circo,
       count(*)                  AS voisins
  FROM voisin
 GROUP BY 1, 2, 3, 4
HAVING count(DISTINCT circo) = 1;

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
SELECT (extract(year FROM debut_reel)::int / 10) * 10 AS decennie,
       count(DISTINCT atom_id) AS atomes, count(*) AS periodes
  FROM scission_circo_trace GROUP BY 1 ORDER BY 1;

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

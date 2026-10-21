-- ============================================================================
-- histgis — 122_circo_1945_1958.sql : le scrutin de liste départemental de
--                                     la Quatrième République
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/122_circo_1945_1958.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/122_circo_1945_1958.sql
--   psql -d histgis -1 -v defaire=1 -f sql/122_circo_1945_1958.sql    -- tout retirer
--   (-v dep=01 pour un seul département)
--
-- CE QUE CE FICHIER EST
-- =====================
-- La base n'avait, entre 1945 et 1958, que les six circonscriptions de la
-- Seine (`55`, `88`) : partout ailleurs la carte des circonscriptions était
-- blanche. Les législatives de 1945, 1946 (juin et novembre), 1951 et 1956 se
-- sont tenues à la représentation proportionnelle, au scrutin de liste dans le
-- cadre du DÉPARTEMENT (correction d'Adrien, 21 octobre 2026). Ce fichier pose,
-- pour chaque département hors de la Seine, une unité `L<dep>01@1945`, régime
-- `liste`, sur [1945-01-01, 1958-01-01) — les bornes de la Seine déjà en
-- base —, et y rattache tout atome qui a un canton du département dans la
-- fenêtre, sur la durée de ce canton.
--
-- CE QU'IL N'AFFIRME PAS
-- ======================
--   * 1941-1945 reste vide : il n'y a pas eu d'élection législative entre
--     juillet 1940 et le 21 octobre 1945. C'est `ABSENCES_CIRCO` de
--     `cartes/export_web.py`, qui l'annonce sur la page.
--   * Les quelques départements très peuplés divisés en plusieurs
--     circonscriptions sous la Quatrième République (la Seine, déjà en base ;
--     probablement Seine-et-Oise, Nord, Pas-de-Calais, Seine-Inférieure,
--     Gironde, Bouches-du-Rhône, Rhône) ne sont PAS confrontés à
--     l'ordonnance du 17 août 1945 ni à la loi du 5 octobre 1946 : ils sont
--     posés d'un seul tenant. `-v sauf="'59','62'"` les écarte, le jour où la
--     division sera transcrite.
--   * Un atome qui a déjà une circonscription dans la fenêtre n'est pas
--     touché (garde-fou 3) : ce fichier COMBLE, il ne remplace pas.
--
-- NOMS — le nom du département en 1945, et le nouveau à son changement :
-- Loire-Inférieure → Loire-Atlantique (9 mars 1957), Seine-Inférieure →
-- Seine-Maritime (18 janvier 1955).
--
-- Réversible : `circo_1945_trace`. Le fichier retire sa trace avant de
-- reposer, et se rejoue sans risque. Il LIT les cantons : il passe après tout
-- ce qui en pose ou en corrige, à côté de `113`.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set du '1945-01-01'
\set au '1958-01-01'

CREATE TABLE IF NOT EXISTS circo_1945_trace (
    dep  text NOT NULL, quoi text NOT NULL, cle text NOT NULL,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

-- La trace est retirée AVANT le calcul : la pose se compare à la base sans
-- elle, sans quoi un second passage se verrait lui-même au garde-fou 3.
\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM circo_1945_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM circo_1945_trace t
                WHERE t.quoi = 'unit' AND t.cle = v.unit_id);
DELETE FROM unit u
 WHERE EXISTS (SELECT 1 FROM circo_1945_trace t
                WHERE t.quoi = 'unit' AND t.cle = u.unit_id);
DELETE FROM circo_1945_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

DROP TABLE IF EXISTS t122_nom;
CREATE TEMP TABLE t122_nom (dep text, nom text, du date, au date);
INSERT INTO t122_nom (dep, nom) VALUES
('01','Ain'), ('02','Aisne'), ('03','Allier'), ('04','Basses-Alpes'),
('05','Hautes-Alpes'), ('06','Alpes-Maritimes'), ('07','Ardèche'),
('08','Ardennes'), ('09','Ariège'), ('10','Aube'), ('11','Aude'),
('12','Aveyron'), ('13','Bouches-du-Rhône'), ('14','Calvados'),
('15','Cantal'), ('16','Charente'), ('17','Charente-Maritime'),
('18','Cher'), ('19','Corrèze'), ('20','Corse'), ('21','Côte-d''Or'),
('22','Côtes-du-Nord'), ('23','Creuse'), ('24','Dordogne'), ('25','Doubs'),
('26','Drôme'), ('27','Eure'), ('28','Eure-et-Loir'), ('29','Finistère'),
('30','Gard'), ('31','Haute-Garonne'), ('32','Gers'), ('33','Gironde'),
('34','Hérault'), ('35','Ille-et-Vilaine'), ('36','Indre'),
('37','Indre-et-Loire'), ('38','Isère'), ('39','Jura'), ('40','Landes'),
('41','Loir-et-Cher'), ('42','Loire'), ('43','Haute-Loire'),
('44','Loire-Inférieure'), ('45','Loiret'), ('46','Lot'),
('47','Lot-et-Garonne'), ('48','Lozère'), ('49','Maine-et-Loire'),
('50','Manche'), ('51','Marne'), ('52','Haute-Marne'), ('53','Mayenne'),
('54','Meurthe-et-Moselle'), ('55','Meuse'), ('56','Morbihan'),
('57','Moselle'), ('58','Nièvre'), ('59','Nord'), ('60','Oise'),
('61','Orne'), ('62','Pas-de-Calais'), ('63','Puy-de-Dôme'),
('64','Basses-Pyrénées'), ('65','Hautes-Pyrénées'),
('66','Pyrénées-Orientales'), ('67','Bas-Rhin'), ('68','Haut-Rhin'),
('69','Rhône'), ('70','Haute-Saône'), ('71','Saône-et-Loire'),
('72','Sarthe'), ('73','Savoie'), ('74','Haute-Savoie'),
('76','Seine-Inférieure'), ('77','Seine-et-Marne'), ('78','Seine-et-Oise'),
('79','Deux-Sèvres'), ('80','Somme'), ('81','Tarn'),
('82','Tarn-et-Garonne'), ('83','Var'), ('84','Vaucluse'), ('85','Vendée'),
('86','Vienne'), ('87','Haute-Vienne'), ('88','Vosges'), ('89','Yonne'),
('90','Territoire de Belfort');
UPDATE t122_nom SET du = :'du', au = :'au';
-- les deux changements de nom de la période
UPDATE t122_nom SET au = '1957-03-09' WHERE dep = '44';
UPDATE t122_nom SET au = '1955-01-18' WHERE dep = '76';
INSERT INTO t122_nom VALUES
('44', 'Loire-Atlantique', '1957-03-09', :'au'),
('76', 'Seine-Maritime',   '1955-01-18', :'au');

-- l'atome et sa vie cantonale dans le département, sur la fenêtre
DROP TABLE IF EXISTS t122_pose;
CREATE TEMP TABLE t122_pose AS
SELECT m.atom_id, u.dep::text AS dep,
       'L' || u.dep || '01@1945' AS unit_id,
       greatest(min(m.valid_from), :'du'::date) AS valid_from,
       least(max(m.valid_to), :'au'::date)      AS valid_to,
       count(*) AS periodes
  FROM membership m
  JOIN unit u ON u.unit_id = m.unit_id
 WHERE m.niveau = 'canton'
   AND m.periode && daterange(:'du', :'au', '[)')
   AND u.dep::text IN (SELECT dep FROM t122_nom)
\if :{?dep}
   AND u.dep = :'dep'
\endif
\if :{?sauf}
   AND u.dep::text NOT IN (:sauf)
\endif
 GROUP BY 1, 2, 3;

\echo ''
\echo '=== 1. Ce que chaque département recevra ==='
SELECT count(DISTINCT dep) AS departements, count(*) AS rattachements,
       count(*) FILTER (WHERE valid_from > :'du'::date) AS nes_apres,
       count(*) FILTER (WHERE valid_to < :'au'::date)   AS morts_avant
  FROM t122_pose;

\echo ''
\echo '=== 2. Garde-fou : un atome dans deux départements (attendu : zéro) ==='
-- Une vie cantonale prise d'un bloc (min, max) suppose un département : un
-- atome qui en change dans la fenêtre aurait deux périodes qui se recouvrent.
SELECT a.atom_id, a.dep, a.valid_from, a.valid_to, b.dep AS autre,
       b.valid_from AS du2, b.valid_to AS au2
  FROM t122_pose a JOIN t122_pose b
    ON b.atom_id = a.atom_id AND b.dep > a.dep
   AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);

\echo ''
\echo '=== 2 bis. Atomes à trou cantonal dans la fenêtre (posés sur toute leur vie) ==='
SELECT p.dep, count(*) AS atomes
  FROM t122_pose p
 WHERE (SELECT sum(least(m.valid_to, p.valid_to) - greatest(m.valid_from, p.valid_from))
          FROM membership m JOIN unit u ON u.unit_id = m.unit_id
         WHERE m.atom_id = p.atom_id AND m.niveau = 'canton' AND u.dep::text = p.dep
           AND m.periode && daterange(p.valid_from, p.valid_to))
       < p.valid_to - p.valid_from
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 3. Garde-fou : ces périodes sont-elles libres ? (attendu : zéro) ==='
DROP TABLE IF EXISTS t122_pris;
CREATE TEMP TABLE t122_pris AS
SELECT p.dep, p.atom_id, m.unit_id
  FROM t122_pose p
  JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = 'circo'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)');
SELECT dep, count(*) AS deja_pris, left(string_agg(DISTINCT unit_id, ', '), 80)
  FROM t122_pris GROUP BY 1 ORDER BY 1;

\if :{?appliquer}
DO $$
DECLARE n bigint;
BEGIN
    SELECT count(*) INTO n FROM t122_pose;
    IF n = 0 THEN RAISE EXCEPTION 'Rien à poser.'; END IF;
    SELECT count(*) INTO n
      FROM t122_pose a JOIN t122_pose b
        ON b.atom_id = a.atom_id AND b.dep > a.dep
       AND daterange(a.valid_from, a.valid_to) && daterange(b.valid_from, b.valid_to);
    IF n > 0 THEN
        RAISE EXCEPTION '% atome(s) dans deux départements. Voir la recette 2.', n;
    END IF;
    SELECT count(*) INTO n FROM t122_pris;
    IF n > 0 THEN
        RAISE EXCEPTION '% rattachement(s) existent déjà. Ce fichier COMBLE, '
            'il ne remplace pas. Voir la recette 3.', n;
    END IF;
    SELECT count(*) INTO n
      FROM (SELECT DISTINCT unit_id FROM t122_pose) d JOIN unit u USING (unit_id);
    IF n > 0 THEN
        RAISE EXCEPTION '% unité(s) de ce fichier existent déjà en base, hors '
            'de sa trace.', n;
    END IF;
END $$;

WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    SELECT DISTINCT p.unit_id, 'circo', p.dep, split_part(p.unit_id, '@', 1),
           'liste', 1945,
           n.nom || ' — scrutin de liste départemental', false
      FROM t122_pose p JOIN t122_nom n ON n.dep = p.dep AND n.du = :'du'::date
    RETURNING unit_id, dep
)
INSERT INTO circo_1945_trace (dep, quoi, cle)
SELECT dep, 'unit', unit_id FROM ins;

INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT DISTINCT p.unit_id, n.nom || ' — scrutin de liste départemental',
       n.du, n.au
  FROM t122_pose p JOIN t122_nom n ON n.dep = p.dep;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'circo', valid_from, valid_to FROM t122_pose
    RETURNING membership_id, unit_id
)
INSERT INTO circo_1945_trace (dep, quoi, cle)
SELECT substr(unit_id, 2, 2), 'membership', membership_id::text FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 4. Pose ==='
SELECT quoi, count(*), count(DISTINCT dep) AS departements
  FROM circo_1945_trace GROUP BY quoi ORDER BY quoi;

\echo ''
\echo '=== 5. Atomes à canton et sans circonscription, date par date ==='
SELECT v.d AS a_la_date,
       count(DISTINCT c.atom_id) AS atomes_canton,
       count(DISTINCT c.atom_id) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership i WHERE i.atom_id = c.atom_id
              AND i.niveau = 'circo' AND i.periode @> v.d)) AS sans_circo
  FROM (VALUES ('1946-06-01'::date), ('1951-06-17'), ('1956-01-02'),
               ('1957-12-31')) v(d)
  JOIN membership c ON c.niveau = 'canton' AND c.periode @> v.d
 GROUP BY v.d ORDER BY v.d;
\else
\echo ''
\echo '=== Tourne à blanc — relancer avec -1 -v appliquer=1 ==='
\endif
\endif

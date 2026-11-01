-- ============================================================================
-- histgis — 140_blois_1973_1992.sql : Blois (Loir-et-Cher), quatre puis cinq
--           cantons de 1973 à 1992
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/140_blois_1973_1992.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/140_blois_1973_1992.sql
--   psql -d histgis -1 -v defaire=1 -f sql/140_blois_1973_1992.sql
--
-- Relevé le 1er novembre 2026, à la demande d'Adrien, en découpant Blois
-- (`cartes/a_inscrire_en_base.md`, n° 153). Dans la base, la ville n'a que
-- deux fractions, 4549#4101 et #4102, de 1815 à 1992 ; #4125, #4126 et #4127
-- ne commencent qu'au COG de 1992.
--
-- 1. Décret n° 73-661 du 13 juillet 1973 (JO du 17 juillet 1973,
--    `jorf_txt/JORF_19730717_164_col.txt`, l. 1805 et suiv. ;
--    `cantons/composition_jo.csv`) : Blois-Est et Blois-Ouest remplacés par
--    Blois-I à IV. III est la ville seule, IV a Fossé, Marolles,
--    Saint-Bohaire, Saint-Lubin-en-Vergonnois et Saint-Sulpice. La base met
--    déjà ces cinq communes à 4127 dès 1973 : l'ancien IV y est l'unité 4127,
--    que `cantons/controle_composition_jo.csv` apparie à 41-27 par ses
--    communes. On garde cette convention : fraction de IV = #4127.
--
-- 2. Décret n° 82-60 du 20 janvier 1982 (JO du 22 janvier 1982, p. 339-340,
--    `jorf_txt/JORF_19820122_18_col.txt`, l. 1014-1039) : Blois-IV divisé en
--    IV, la ville seule, et V, qui garde les cinq communes. V reste 4127
--    (« Blois 5e canton » en 1999, avec les mêmes communes), le nouveau IV
--    est 4126.
--
-- 3. Saint-Claude-de-Diray (30975) et Vineuil (40761) : la base les laisse à
--    Blois-I (4101) de 1973 à 1985. Le décret 73-661 les met à Blois-II
--    (« Montlivault, Saint-Claude-de-Diray, Vineuil, Saint-Gervais-la-Forêt,
--    Chailles et Cellettes »), et le décret n° 84-1228 crée Vineuil « par
--    division de Blois-II » (annexe VII, l. 405) avec elles et Montlivault,
--    que la base met déjà à 4102. Les deux lignes 4101 sont RETIRÉES (gardées
--    dans la trace) et reposées à 4102.
--
-- Circonscriptions : toute la ville est dans la 1re (41-01@1958) jusqu'au
-- 1986-11-24, comme #4101 et #4102 ; les trois fractions la prennent de leur
-- début à cette date. Après, elles ont déjà 41-01@1986.
--
-- Noms (`unit_version`, vide de 1941 à 1999 pour ces cinq unités) : Blois-I,
-- II et III de 1973 à 1999, 4127 « Blois-IV » de 1973 à 1982 puis
-- « Blois-V », 4126 « Blois-IV » de 1982 à 1999.
--
-- Hors base, déjà posé : les lignes 41018-1973-* et 41018-1982-* de
-- `cartes/coupes_ville.csv`, avec des ancres datées pour chaque fraction. Après
-- application : `98` sous `appliquer`, le tableau, l'export du 41.
--
-- Réversible : `p140_trace`. Rejouable. Après `139`.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p140_trace (
    quoi text NOT NULL, cle text NOT NULL,
    atom_id text, unit_id text, niveau text,
    ancien_from date, ancien_to date,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM p140_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
DELETE FROM unit_version v
 WHERE EXISTS (SELECT 1 FROM p140_trace t
                WHERE t.quoi = 'unit_version' AND t.cle = v.unit_version_id::text);
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT cle::bigint, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p140_trace WHERE quoi = 'retire';
DELETE FROM p140_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- Lignes à retirer : Saint-Claude-de-Diray et Vineuil à Blois-I, 1973-1985
DROP TABLE IF EXISTS t140_retire;
CREATE TEMP TABLE t140_retire AS
SELECT membership_id, atom_id, unit_id, niveau, valid_from, valid_to
  FROM membership
 WHERE atom_id IN ('30975', '40761') AND niveau = 'canton' AND unit_id = '4101'
   AND valid_from = '1973-09-23' AND valid_to = '1985-03-10';

DROP TABLE IF EXISTS t140_lu;
CREATE TEMP TABLE t140_lu (atom_id text, niveau text, unit_id text, du date, au date, fonde text);
INSERT INTO t140_lu VALUES
('4549#4125','canton','4125','1973-09-23','1992-03-22','Blois-III, ville seule (73-661)'),
('4549#4127','canton','4127','1973-09-23','1992-03-22','Blois-IV (73-661) puis Blois-V (82-60), avec ses cinq communes'),
('4549#4126','canton','4126','1982-03-14','1992-03-22','Blois-IV, ville seule (82-60)'),
('4549#4125','circo','41-01@1958','1973-09-23','1986-11-24','1re circonscription, comme #4101 et #4102'),
('4549#4127','circo','41-01@1958','1973-09-23','1986-11-24','1re circonscription, comme #4101 et #4102'),
('4549#4126','circo','41-01@1958','1982-03-14','1986-11-24','1re circonscription, comme #4101 et #4102'),
('30975','canton','4102','1973-09-23','1985-03-10','Saint-Claude-de-Diray : Blois-II (73-661), puis Vineuil (84-1228)'),
('40761','canton','4102','1973-09-23','1985-03-10','Vineuil : Blois-II (73-661), puis Vineuil (84-1228)');

DROP TABLE IF EXISTS t140_nom;
CREATE TEMP TABLE t140_nom (unit_id text, nom text, du date, au date);
INSERT INTO t140_nom VALUES
('4101','Blois-I',  '1973-09-23','1999-01-01'),
('4102','Blois-II', '1973-09-23','1999-01-01'),
('4125','Blois-III','1973-09-23','1999-01-01'),
('4127','Blois-IV', '1973-09-23','1982-03-14'),
('4127','Blois-V',  '1982-03-14','1999-01-01'),
('4126','Blois-IV', '1982-03-14','1999-01-01');

\echo ''
\echo '=== 1. Retirés (attendu : 2, Saint-Claude-de-Diray et Vineuil à 4101, 1973-1985) ==='
SELECT * FROM t140_retire ORDER BY atom_id;

\echo ''
\echo '=== 2. À poser (attendu : 8 lignes, aucune collision) ==='
SELECT l.atom_id, l.niveau, l.unit_id, l.du, l.au,
       (SELECT string_agg(m.unit_id||' '||m.valid_from||'→'||m.valid_to, ', ')
          FROM membership m WHERE m.atom_id = l.atom_id AND m.niveau = l.niveau
           AND m.periode && daterange(l.du, l.au, '[)')
           AND m.membership_id NOT IN (SELECT membership_id FROM t140_retire)) AS collision
  FROM t140_lu l ORDER BY 2, 1, 4;

\echo ''
\echo '=== 3. Noms à poser (attendu : 6, aucune collision) ==='
SELECT n.*, (SELECT string_agg(v.nom||' '||v.valid_from||'→'||v.valid_to, ', ')
               FROM unit_version v WHERE v.unit_id = n.unit_id
                AND v.periode && daterange(n.du, n.au, '[)')) AS collision
  FROM t140_nom n ORDER BY 1, 3;

\if :{?appliquer}
DO $$
BEGIN
    IF (SELECT count(*) FROM t140_retire) <> 2 THEN
        RAISE EXCEPTION 'La base a bougé : les deux lignes 4101 de Saint-Claude et Vineuil sont introuvables (recette 1).';
    END IF;
    IF EXISTS (SELECT 1 FROM t140_lu l JOIN membership m
                 ON m.atom_id = l.atom_id AND m.niveau = l.niveau
                AND m.periode && daterange(l.du, l.au, '[)')
              WHERE m.membership_id NOT IN (SELECT membership_id FROM t140_retire)) THEN
        RAISE EXCEPTION 'La base a bougé : une période à poser est déjà occupée (recette 2).';
    END IF;
    IF EXISTS (SELECT 1 FROM t140_nom n JOIN unit_version v
                 ON v.unit_id = n.unit_id AND v.periode && daterange(n.du, n.au, '[)')) THEN
        RAISE EXCEPTION 'La base a bougé : un nom à poser est déjà occupé (recette 3).';
    END IF;
END $$;

INSERT INTO p140_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to
  FROM t140_retire;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t140_retire);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, du, au FROM t140_lu
  RETURNING membership_id)
INSERT INTO p140_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

WITH ins AS (
  INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
  SELECT unit_id, nom, du, au FROM t140_nom
  RETURNING unit_version_id)
INSERT INTO p140_trace (quoi, cle) SELECT 'unit_version', unit_version_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p140_trace GROUP BY 1 ORDER BY 1;
\endif

\echo ''
\echo '=== 4. Cantons de Blois à quatre dates : communes et fractions ==='
SELECT d, m.unit_id,
       string_agg(coalesce(a.insee_geofla, '')||CASE WHEN a.fraction THEN '#'||split_part(a.atom_id, '#', 2) ELSE '' END,
                  ' ' ORDER BY a.insee_geofla, a.atom_id) AS composition
  FROM (VALUES ('1970-06-01'::date), ('1980-06-01'), ('1984-06-01'), ('1990-06-01')) v(d)
  JOIN membership m ON m.niveau = 'canton' AND m.unit_id IN ('4101','4102','4125','4126','4127') AND m.periode @> d
  JOIN atom a ON a.atom_id = m.atom_id
 GROUP BY d, m.unit_id ORDER BY d, m.unit_id;
\endif

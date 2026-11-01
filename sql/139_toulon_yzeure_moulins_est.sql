-- ============================================================================
-- histgis — 139_toulon_yzeure_moulins_est.sql : Toulon-sur-Allier et Yzeure
--           (Allier) rendues à Moulins-Est de 1941 à 1973
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/139_toulon_yzeure_moulins_est.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/139_toulon_yzeure_moulins_est.sql
--   psql -d histgis -1 -v defaire=1 -f sql/139_toulon_yzeure_moulins_est.sql
--
-- Relevé le 31 octobre 2026, à la demande d'Adrien. Dans la base, les deux
-- communes étaient à Moulins-Est (0323) jusqu'en 1941, puis sans canton de
-- 1941 à 1968, puis à Neuilly-le-Réal (0325) de 1968 à 1973 ; Toulon était
-- encore sans canton de 1973 à 1985.
--
-- 1. 1941-1968. Le recensement de 1954 les lit au canton 23, Moulins-Est
--    (`cog1954/ocr_brut/p0114.txt`, l. 56, et `p0115.txt`, l. 38), mais le
--    dépouillement ne les a pas retenues : elles manquent dans
--    `cog1954/communes_1954.csv`, et le trou est resté.
--
-- 2. 1968-1973. Le jalon de 1968 (`59`, puis `81`) les mettait au canton
--    « 25 », Neuilly-le-Réal (`cog1968/communes_1968_fusion.csv`). C'est une
--    erreur d'OCR : le fascicule de l'Allier
--    (https://www.bnsp.insee.fr/ark:/12148/bd6t5358311n, f. 15 et 16, p. 11 et
--    12 imprimées) porte « 2 23 286 Toulon-sur-Allier » et « 2 23 321 Yzeure »,
--    soit le canton 23 comme Bressolles et Gennetines. L'annexe VII le confirme
--    (`cantons/annexe_vii.csv`, l. 36) : Moulins-Sud et Yzeure sont créés en
--    1973 par « division Moulins-E., qui disparaît ». Les quatre lignes 0325
--    de 1968-1973 sont RETIRÉES (gardées dans la trace).
--
-- 3. Toulon-sur-Allier, 1973-1985. Le décret n° 73-713 du 23 juillet 1973
--    (`jorf_txt/JORF_19730725_171_col.txt`, l. 729-731), art. 2 : « Canton de
--    Moulins-Sud, comprenant les communes de Bressoles et Toulon-sur-Allier,
--    ainsi que la portion de territoire de la ville de Moulins… ». Moulins-Sud
--    est l'unité 0323, où la base met déjà Bressolles de 1973 à 1985, et
--    Toulon dès 1985. Yzeure est déjà au canton d'Yzeure (0333) depuis 1973.
--    Toulon est donc posée à 0323 sans interruption de 1941 à 1985.
--
-- Circonscriptions : de 1945 à 1968 les deux atomes n'en avaient aucune
-- (l'ombre du trou cantonal). Celles de Bressolles, Gennetines et
-- Saint-Ennemond, de Moulins-Est comme elles : liste départementale
-- (L0301@1945) de 1945 à 1958, puis 1re circonscription (03-01@1958), qu'elles
-- ont déjà à partir de 1968. Rien n'est changé après 1968 : Neuilly-le-Réal
-- était aussi dans la 1re.
--
-- Non traité : 0323 n'a pas de nom (`unit_version`) de 1941 à 1999, et 0333
-- pas avant 1999. Les noms affichés retombent sur « Moulins-Est » et
-- « Yzeure ».
--
-- Réversible : `p139_trace`. Rejouable. Après `138` : il retire quatre lignes du
-- jalon de 1968 (`59`, `81`). Rejouer l'un de ceux-là demande de défaire
-- celui-ci d'abord.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p139_trace (
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
 WHERE EXISTS (SELECT 1 FROM p139_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p139_trace WHERE quoi = 'retire';
DELETE FROM p139_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- Lignes à retirer : Neuilly-le-Réal 1968-1973 (jalon de 1968 mal lu)
DROP TABLE IF EXISTS t139_retire;
CREATE TEMP TABLE t139_retire AS
SELECT membership_id, atom_id, unit_id, niveau, valid_from, valid_to
  FROM membership
 WHERE atom_id IN ('37813', '17696') AND niveau = 'canton' AND unit_id = '0325'
   AND valid_from >= '1968-01-01' AND valid_to <= '1973-09-23';

DROP TABLE IF EXISTS t139_lu;
CREATE TEMP TABLE t139_lu (atom_id text, niveau text, unit_id text, du date, au date, fonde text);
INSERT INTO t139_lu VALUES
('37813','canton','0323','1941-01-01','1985-03-10','Toulon-sur-Allier : Moulins-Est (1954 et 1968 : canton 23), puis Moulins-Sud (73-713)'),
('37813','circo','L0301@1945','1945-01-01','1958-01-01','liste départementale'),
('37813','circo','03-01@1958','1958-01-01','1968-01-01','1958 : canton de Moulins-Est'),
('17696','canton','0323','1941-01-01','1973-09-23','Yzeure : Moulins-Est (1954 et 1968 : canton 23) ; annexe VII'),
('17696','circo','L0301@1945','1945-01-01','1958-01-01','liste départementale'),
('17696','circo','03-01@1958','1958-01-01','1968-01-01','1958 : canton de Moulins-Est');

\echo ''
\echo '=== 1. Retirés (attendu : 4, Neuilly-le-Réal 1968-1973) ==='
SELECT * FROM t139_retire ORDER BY atom_id, valid_from;

\echo ''
\echo '=== 2. À poser (attendu : 6 lignes, aucune collision) ==='
SELECT l.atom_id, l.niveau, l.unit_id, l.du, l.au,
       (SELECT string_agg(m.unit_id||' '||m.valid_from||'→'||m.valid_to, ', ')
          FROM membership m WHERE m.atom_id = l.atom_id AND m.niveau = l.niveau
           AND m.periode && daterange(l.du, l.au, '[)')
           AND m.membership_id NOT IN (SELECT membership_id FROM t139_retire)) AS collision
  FROM t139_lu l ORDER BY 1, 2, 4;

\if :{?appliquer}
DO $$
BEGIN
    IF (SELECT count(*) FROM t139_retire) <> 4 THEN
        RAISE EXCEPTION 'La base a bougé : les quatre lignes de Neuilly-le-Réal sont introuvables (recette 1).';
    END IF;
    IF EXISTS (SELECT 1 FROM t139_lu l JOIN membership m
                 ON m.atom_id = l.atom_id AND m.niveau = l.niveau
                AND m.periode && daterange(l.du, l.au, '[)')
              WHERE m.membership_id NOT IN (SELECT membership_id FROM t139_retire)) THEN
        RAISE EXCEPTION 'La base a bougé : un trou à combler est déjà occupé (recette 2).';
    END IF;
END $$;

INSERT INTO p139_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to
  FROM t139_retire;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t139_retire);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, du, au FROM t139_lu
  RETURNING membership_id)
INSERT INTO p139_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p139_trace GROUP BY 1 ORDER BY 1;
\endif

\echo ''
\echo '=== 3. Moulins-Est / Moulins-Sud (0323) : composition à trois dates ==='
SELECT d, string_agg(a.insee_geofla, ' ' ORDER BY a.insee_geofla) AS communes
  FROM (VALUES ('1950-06-01'::date), ('1970-06-01'), ('1980-06-01')) v(d)
  JOIN membership m ON m.niveau = 'canton' AND m.unit_id = '0323' AND m.periode @> d
  JOIN atom a ON a.atom_id = m.atom_id
 GROUP BY d ORDER BY d;
\endif
